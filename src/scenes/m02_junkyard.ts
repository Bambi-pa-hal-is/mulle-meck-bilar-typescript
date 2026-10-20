/**
 * Movie 02 – Skrothögen (the junkyard). Six junk piles in a ring; pick parts up, re-arrange them,
 * throw them onto the next pile via the signs, or carry them through the door to the workshop.
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, Sym, sym } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import type { MemberRef } from "../engine/assets.ts";
import { GameDir, inside, type Rectish } from "../game/dir.ts";
import { G, random, pick } from "../game/runtime.ts";
import { kickPartSound } from "../game/shared.ts";
import type { SpriteAnimBH } from "./common.ts";
import { setCursor } from "./common.ts";

const symName = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
const PILE_SP = 120;   // the PileBH sprite (scripts address it directly)

class JunkDir extends GameDir {
  /** Original switches to a low-memory mode when frames get slow; never needed in a browser. */
  goToLoad = false;
  overDoor = false;
  partsInShop: number;
  constructor(m: Movie) {
    super(m);
    this.spriteList = { drag: 105, JunkStart: 12, DoorStart: 10, fDialog: 114, Mulle: 102, Buffa: 103, leftSign: 83, rightSign: 82 };
    this.partsInShop = G.mulle.user!.getJunk("shopFloor").count;
  }
  /** activate(gDir, state) in this movie sends #activate (not #activateClick). */
  activate(state: boolean) { this.movie.sendAll("activate", state ? 1 : 0); }
}
const dir = () => G.dir as JunkDir;
const pileBH = (m: Movie) => m.sprite(PILE_SP).behaviors.find(b => b instanceof PileBH) as PileBH | undefined;

export const junkMovie = (): MovieScript & { cuePassed(m: Movie, ch: number, nr: number, name: string): void } => ({
  prepareMovie(m) { G.dir = new JunkDir(m); },
  startMovie() {
    G.sound.stopAllEffects(); G.sound.stopBG();
    if (G.mulle.loadIndicator === 0) G.sound.play("02e010v0", "BG");
    dir().activate(true);
  },
  cuePassed(_m, ch, nr, name) { dir()?.send("Mulle", "spritecuePassed", ch, nr, name); },
  // Movie-level handlers: a click on the door, or the release of a carried part.
  mouseDown() { dir().overDoor = !!dir().send("DoorStart", "isMouseOver"); },
  mouseUp(m) {
    if (dir().overDoor && m.frame <= 60) dir().send("DoorStart", "checkMyRect");
    else dir().send("drag", "forceLetGo");
  },
});

// ------------------------------------------------------------------ frame scripts
class JunkLoop extends Behavior { exitFrame() { dir()?.loop(); this.movie.goFrame(this.movie.frame); } }
const goMovie = (id: string) => class extends Behavior { exitFrame() { void G.engine.goMovie(id, 1); } };

// ------------------------------------------------------------------ the pile
/** PileBH – one per pile (sprite 120): lays out the parts and handles picking/dropping. */
class PileBH extends Behavior {
  whichPile = 1;
  releaseOk = 0;
  puttingBack = "";
  tmpId = 0;
  private tracking = false;
  private trackRect: Rectish = { left: 0, top: 0, right: 0, bottom: 0 };
  private partSprite = 0;
  private partId = 0;
  private topLayer = 0;
  private rects: Rectish[] = [];
  private tempNewPos = new Point(0, 0);
  private xDiff = 0; private yDiff = 0; private loopcount = 0;
  private readonly steps = 10;

  private get pileSym() { return sym("Pile" + this.whichPile); }
  private get pile() { return G.mulle.user!.getJunk(this.pileSym); }

  beginSprite() {
    this.whichPile = this.p("whichPile", 1);
    this.rects = G.mulle.junkPiles.rects["pile" + this.whichPile];
    this.distributeParts();
    this.checkNrofParts();
  }

  checkNrofParts() {
    const max = G.mulle.junkPiles.maxParts["pile" + this.whichPile];
    dir().send("Mulle", "addToSounList", max <= this.pile.count + 20 ? "Reject" : "Think");
  }

  distributeParts() {
    const start = dir().sp("JunkStart");
    const ids = (this.pile.keys() as number[]).filter(id => G.mulle.parts.get(id)); // hide parts of disabled extras
    ids.forEach((id, n) => this.movie.sprite(start + n).send("setPart", [id, this.pile.get(id)]));
    this.topLayer = start + ids.length - 1;
    const after = this.movie.sprite(start + ids.length);
    this.movie.setMemberByName(after, "Dummy"); after.puppet = true;
  }

  /** Never leave a part outside the screen: fall back to a free spot in the pile. */
  private safeSpot(p: Point) {
    return p.x < 0 || p.x > 640 || p.y < 0 || p.y > 480 ? G.mulle.junkPiles.setPartPosition(this.pileSym, this.partId) : p;
  }

  forcePartInPlace() {
    this.loopcount = 0; this.puttingBack = "";
    this.tempNewPos = this.safeSpot(this.tempNewPos);
    this.movie.sprite(this.topLayer).setLoc(this.tempNewPos.x, this.tempNewPos.y);
    const u = G.mulle.user!;
    if (this.pile.has(this.partId)) { u.removeJunkPart(this.pileSym, this.partId); u.addJunkPart(this.pileSym, this.partId, this.tempNewPos); }
  }

  exitFrame() {
    if (this.puttingBack !== "center") return;
    const s = this.movie.sprite(this.topLayer);
    if (this.loopcount < this.steps) {
      s.setLoc(s.locH + Math.trunc(this.xDiff / this.steps), s.locV + Math.trunc(this.yDiff / this.steps));
      this.loopcount++;
    } else {
      this.loopcount = 0; this.puttingBack = "";
      kickPartSound(this.partId, "InternalGround");
      const u = G.mulle.user!;
      const end = this.safeSpot(new Point(s.locH, s.locV)); s.setLoc(end.x, end.y);
      if (this.pile.has(this.partId)) { u.removeJunkPart(this.pileSym, this.partId); u.addJunkPart(this.pileSym, this.partId, end); }
    }
  }

  private changePile(delta: -1 | 1) {
    if (this.puttingBack === "center") this.forcePartInPlace();
    const buffa = this.movie.sprite(dir().sp("Buffa"));
    this.movie.setMemberByName(buffa, "Dummy"); buffa.puppet = true;
    const to = ((this.whichPile - 1 + delta + 6) % 6) + 1;
    G.mulle.user!.myLastPile = to;
    this.movie.goFrame("Pile" + to);
    dir().send("Buffa", "changePile", delta);
  }
  GoLeft() { this.changePile(-1); }
  GoRight() { this.changePile(1); }

  grabPart(id: number, spriteNum: number) {
    if (this.puttingBack === "center") this.forcePartInPlace();
    this.releaseOk = 1;
    this.partSprite = spriteNum; this.partId = id;
    const src = this.movie.sprite(spriteNum);
    dir().send("drag", "setPart", src.member);
    this.movie.sprite(dir().sp("drag")).setLoc(src.locH, src.locV);
    const { x, y } = this.movie.engine.mouse;
    this.trackRect = { left: x - 2, top: y - 2, right: x + 2, bottom: y + 2 };
    this.tracking = true;
  }

  /** Once the mouse moves, the part leaves the pile and follows the cursor. */
  prepareFrame() {
    if (!this.tracking) return;
    const { x, y } = this.movie.engine.mouse;
    if (!inside(x, y, this.trackRect)) {
      dir().send("drag", "drag");
      this.movie.setMemberByName(this.movie.sprite(this.partSprite), "Dummy");
    }
  }

  releasePart() {
    if (this.releaseOk !== 1) return;
    const m = this.movie, { x, y } = m.engine.mouse;
    let playedDescription = dir().send("Mulle", "getCurrentAction") !== "none";
    if (this.tracking && inside(x, y, this.trackRect) && this.partId !== this.tmpId) {
      // clicked without moving: Mulle tells what it is
      this.tmpId = this.partId; playedDescription = true;
      m.sprite(this.partSprite).send("PlayDescription");
    }
    this.tracking = false;
    const dragSp = m.sprite(dir().sp("drag"));
    m.setMember(m.sprite(this.partSprite), dragSp.member);
    m.setMemberByName(dragSp, "Dummy");
    const right = m.sprite(dir().sp("rightSign")).rect, left = m.sprite(dir().sp("leftSign")).rect;
    const part = m.sprite(this.partSprite);
    if (inside(x, y, right) || inside(x, y, left)) {
      const toRight = inside(x, y, right);
      const to = ((this.whichPile - 1 + (toRight ? 1 : -1) + 6) % 6) + 1;
      part.send("moveToDifferentPile", this.whichPile, to);
      setCursor(toRight ? "C_Right" : "c_Left");
      this.distributeParts();
    } else if (this.rects.some(r => inside(x, y, r))) {
      const res = checkPoint(new Point(x | 0, y | 0), this.partId, this.whichPile);
      if (res === true) { if (!playedDescription) kickPartSound(this.partId, "InternalGround"); this.putOnTop(); }
      else if (res === false) this.flowBack();
      else {
        this.loopcount = 0; this.tempNewPos = res;
        this.xDiff = res.x - x; this.yDiff = res.y - y;
        this.puttingBack = "center";
        this.putOnTop();
      }
    } else {
      const door = m.sprite(dir().sp("DoorStart")).behaviors.find(b => b instanceof JunkDoorBH) as JunkDoorBH | undefined;
      if (door && inside(x, y, door.trackRect)) {
        part.send("moveToShop", this.whichPile);
        kickPartSound(this.partId, "ExternalGround");
        setCursor("c_click");
        this.distributeParts();
      } else this.flowBack();
    }
    this.releaseOk = 0;
  }

  /** Dropped somewhere it can't stay: glide back to a free spot in the pile. */
  flowBack() {
    const { x, y } = this.movie.engine.mouse;
    this.tempNewPos = G.mulle.junkPiles.setPartPosition(this.pileSym, this.partId);
    this.xDiff = this.tempNewPos.x - x; this.yDiff = this.tempNewPos.y - y;
    this.loopcount = 0; this.puttingBack = "center";
    this.putOnTop();
  }

  /** Re-insert the part last in the pile list, so it is drawn on top. */
  putOnTop(at?: Point) {
    const u = G.mulle.user!, m = this.movie, { x, y } = m.engine.mouse;
    if (this.pile.has(this.partId)) u.removeJunkPart(this.pileSym, this.partId);
    let p = at;
    if (!p) {
      const s = m.sprite(this.partSprite);
      p = inside(x, y, this.trackRect) ? new Point(s.locH, s.locV) : new Point(x | 0, y | 0);
    }
    u.addJunkPart(this.pileSym, this.partId, p);
    this.distributeParts();
  }
}

/** junkPileHandlers.checkPoint: true = fine, Point = nudge up to here, false = not allowed (over the door). */
function checkPoint(p: Point, id: number, pile: number): true | false | Point {
  const jp = G.mulle.junkPiles;
  const part = G.mulle.parts.get(id);
  const info = part ? G.mulle.memberInfo(part.junkView) : undefined;
  const hw = (info?.w ?? 0) / 2, hh = (info?.h ?? 0) / 2;
  const rects = jp.rects["pile" + pile];
  const bottom = Math.max(...rects.map(r => r.bottom));
  let r = { left: p.x - hw, top: p.y - hh, right: p.x + hw, bottom: p.y + hh };
  let diff = 0;
  if (r.bottom > bottom) { diff = r.bottom - bottom; r = { ...r, top: r.top - diff, bottom: r.bottom - diff }; }
  const door = jp.rects.piledoors[pile - 1];
  const overlap = r.left < door.right && r.right > door.left && r.top < door.bottom && r.bottom > door.top;
  if (!overlap && r.bottom <= bottom) return diff === 0 ? true : new Point(p.x, p.y - diff);
  return false;
}

// ------------------------------------------------------------------ parts
/** PartBH – a part lying in the pile. */
class PartBH extends Behavior {
  partId = 0; position = new Point(0, 0); active = true;
  beginSprite() {
    this.sprite.pixelHit = true;
    this.partId = this.p("partId", 0);
    const pos = this.p("position"); if (pos instanceof Point) this.position = pos;
    if (this.partId) this.update();
  }
  activate(s: boolean | number) { this.active = !!s; }
  setPart([id, pos]: [number, Point]) { this.partId = id; this.position = pos instanceof Point ? pos : new Point(0, 0); this.update(); }
  private update() {
    if (!this.partId) return;
    const part = G.mulle.parts.get(this.partId); if (!part) return;
    this.movie.setMemberByName(this.sprite, part.junkView); this.sprite.puppet = true;
    this.sprite.setLoc(this.position.x, this.position.y);
  }
  mouseDown() {
    if (this.active && this.partId && this.sprite.member?.info.name.toLowerCase() !== "dummy") pileBH(this.movie)?.grabPart(this.partId, this.spriteNum);
  }
  PlayDescription() { dir().send("Mulle", "describepart", G.mulle.parts.get(this.partId)?.description ?? ""); }
  moveToShop(fromPile: number) {
    const u = G.mulle.user!, jp = G.mulle.junkPiles;
    if (jp.checkFull(sym("shopFloor"))) {
      const pb = pileBH(this.movie)!;
      pb.flowBack();
      dir().send("Mulle", "MakeMulleSpeak", "shopFull");
      return;
    }
    u.removeJunkPart(sym("pile" + fromPile), this.partId);
    u.addJunkPart("shopFloor", this.partId);
    dir().partsInShop++;
    kickPartSound(this.partId, "ExternalGround");
  }
  moveToDifferentPile(from: number, to: number) {
    const u = G.mulle.user!, jp = G.mulle.junkPiles;
    if (jp.maxParts["pile" + to] <= u.getJunk(sym("pile" + to)).count + 1) {
      pileBH(this.movie)?.flowBack();
      dir().send("Mulle", "MakeMulleSpeak", "pileFull");
      return;
    }
    kickPartSound(this.partId, "ExternalGround");
    u.removeJunkPart(sym("pile" + from), this.partId);
    u.addJunkPart(sym("pile" + to), this.partId);
    pileBH(this.movie)?.checkNrofParts();
  }
}

/** DragPartBH – the carried part. */
class JunkDragPartBH extends Behavior {
  dragging = false;
  beginSprite() { this.sprite.noHit = true; }
  isDragging() { return this.dragging; }
  isActive() { return this.dragging; }
  setPart(member: MemberRef | null) { this.movie.setMember(this.sprite, member); this.sprite.puppet = true; this.sprite.ink = 36; this.dragging = true; }
  mouseUp() { this.forceLetGo(); }
  forceLetGo() { if (this.dragging) { this.dragging = false; pileBH(this.movie)?.releasePart(); } }
  drag() { const { x, y } = this.movie.engine.mouse; this.sprite.setLoc(x | 0, y | 0); }
}

// ------------------------------------------------------------------ navigation
/** Sign – arrows to the neighbouring piles. */
class SignBH extends Behavior {
  active = true;
  activate(s: boolean | number) { this.active = !!s; }
  mouseEnter() {
    if (dir().goToLoad) return;
    if (this.sprite.member?.info.name.endsWith("0")) { this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true; }
    G.sound.play("02e011v0", "OPEFFECT");
  }
  mouseLeave() { if (this.sprite.member?.info.name.endsWith("1")) this.movie.offsetMember(this.sprite, -1); }
  mouseUp() {
    if (this.movie.sprite(dir().sp("drag")).send("isDragging") || !this.active) return;
    if (symName(this.p("direction")).toLowerCase() === "left") pileBH(this.movie)?.GoLeft();
    else pileBH(this.movie)?.GoRight();
  }
}

/** DoorBH – the door back to the workshop. */
class JunkDoorBH extends Behavior {
  tracking = false; active = true;
  trackRect: Rectish = { left: 0, top: 0, right: 0, bottom: 0 };
  beginSprite() { this.trackRect = this.sprite.rect; }
  activate(s: boolean | number) { this.active = !!s; }
  mouseEnter() {
    if (!this.active || this.tracking) return;
    this.tracking = true;
    this.trackRect = this.sprite.rect;
    setCursor(pileBH(this.movie)?.releaseOk ? "c_MoveIn" : "c_click");
    G.sound.play("02e016v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true;
  }
  isMouseOver() { const { x, y } = this.movie.engine.mouse; return inside(x, y, this.trackRect); }
  prepareFrame() {
    if (!this.tracking || this.isMouseOver()) return;
    G.sound.play("02e015v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, -1);
    this.tracking = false;
    setCursor(pileBH(this.movie)?.releaseOk ? "c_grab" : "C_Standard");
  }
  checkMyRect() {
    if (!this.active || !this.isMouseOver()) return;
    const pb = pileBH(this.movie);
    if (pb?.puttingBack === "center") pb.forcePartInPlace();
    G.mulle.whereFrom = "02";
    this.movie.goFrame(this.p<string>("mediaName", "movie03"));
  }
}

// ------------------------------------------------------------------ Mulle
/** MulleJunkBH – Mulle among the piles: muses, describes parts, complains when full. */
class MulleJunkBH extends Behavior {
  mode = "Wait"; currentAction = "none"; activeClick = true; chart = "MulleJunk";
  thoughtSounds = ["02d001v0", "02d002v0", "02d003v0", "02d004v0", "02d005v0"];
  sortSounds = ["02d006v0", "02d007v0", "02d008v0"];
  randomSounds = this.thoughtSounds;
  get anim() { return this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  beginSprite() { this.sprite.send("setAnimChart", "MulleJunk"); }
  getCurrentAction() { return this.currentAction; }
  activate(s: boolean | number) { this.activeClick = !!s; }
  private talk(snd: string) {
    if (random(2) === 1) { this.chart = "TalkToMeJunk"; this.sprite.send("setAnimChart", "TalkToMeJunk"); }
    this.anim.makeAnimSpeech(snd);
    this.mode = "Talk";
    this.sprite.send("setAnimAction", "Talk");
  }
  exitFrame() {
    if (!dir().goToLoad && this.activeClick && this.mode === "Wait" && this.anim?.getAnimWaitState() === "Still" && random(250) === 1)
      this.talk(pick(this.randomSounds));
  }
  addToSounList(what: string) { this.randomSounds = what === "Reject" ? this.sortSounds : this.thoughtSounds; }
  describepart(snd: string) { this.anim.playAnimSound(""); this.currentAction = "Describe"; this.talk(snd); }
  MakeMulleSpeak(action: string | Sym) {
    action = symName(action);
    this.currentAction = action;
    this.anim.playAnimSound("");
    const snd = action === "shopFull" ? pick(["02d009v0", "02d010v0", "02d011v0"])
      : action === "pileFull" ? pick(["02d013v0", "02d014v0", "02d015v0"]) : "";
    this.talk(snd);
  }
  Stopped() {
    if (this.mode === "Talk") {
      if (this.chart === "TalkToMeJunk") { this.sprite.send("setAnimChart", "MulleJunk"); this.chart = "MulleJunk"; }
      const pb = pileBH(this.movie); if (pb) pb.tmpId = 0;
      this.anim.setAnimNormal();
      this.currentAction = "none";
    }
    this.mode = "Wait";
    this.sprite.send("setAnimAction", "Wait");
  }
}

// ------------------------------------------------------------------ registration
export function registerJunkyard(engine: Engine) {
  engine.registerMovie("02", junkMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`02:${n}`, c);
  B(5, JunkLoop);
  for (const n of [13, 14, 15, 16, 17, 18]) B(n, Behavior); // preloadDoorN: preloading only
  B(9, goMovie("08")); B(35, goMovie("03")); B(6, goMovie("12"));
  B(50, PileBH); B(51, PartBH); B(52, JunkDragPartBH);
  B(57, SignBH); B(58, JunkDoorBH); B(59, MulleJunkBH);
}
