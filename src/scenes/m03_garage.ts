/**
 * Movie 03 – Verkstaden (the workshop). Build the car: drag parts from the floor onto the car,
 * snap them to free attachment points, take them off again, drop them out to the junkyard.
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, Sym, sym } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir, ScreenObject, inside, type Rectish, type ScreenReport } from "../game/dir.ts";
import { G, random, pick } from "../game/runtime.ts";
import { kickPartSound, performMission } from "../game/shared.ts";
import type { SpriteAnimBH } from "./common.ts";
import { setCursor } from "./common.ts";

const symName = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
const car = () => G.mulle.user!.car;

// ------------------------------------------------------------------ gDir
class GarageDir extends GameDir {
  mouseOverCar = 0;
  mouseOverMulle = 0;
  enterShopEvent = false;
  stopSpeak = false;
  parts!: GaragePartsCommon;
  constructor(m: Movie) {
    super(m);
    this.spriteList = { CarStart: 10, drag: 100, JunkStart: 46, DoorStart: 3, garage: 4, DoorToYard: 5, fDialog: 114,
      cheatStart: 102, fButton: 101, Mulle: 6, Buffa: 7, Figge: 8, TeleSmall: 2, TeleBig: 109, Mikro: 13, HighLight: 9,
      FiggeInterup: 120 };
  }
  activate(state: boolean) {
    super.activate(state);
    if (state) this.send("CarStart", "drawCar");
  }
}
const dir = () => G.dir as GarageDir;

export const garageMovie = (): MovieScript & { cuePassed(m: Movie, ch: number, nr: number, name: string): void } => ({
  prepareMovie(m) { G.dir = new GarageDir(m); },
  startMovie(m) {
    const d = dir(), g = G.mulle, u = g.user!;
    m.sprite(d.sp("fDialog")).setLoc(320, 240);
    m.sprite(d.sp("HighLight")).setLoc(320, 240);
    d.parts = new GaragePartsCommon(d);
    G.sound.stopAllEffects(); G.sound.stopBG();
    m.sprite(d.sp("FiggeInterup")).setLoc(700, 500);
    d.send("JunkStart", "drawJunk");
    d.send("CarStart", "drawCar");
    d.send("Mulle", "checkEquipment", "none");
    g.checkMissions();
    if (g.currentMission && u.missionIsComing === 1 && !(u.nrOfBuiltCars % 3 === 0 && u.figgeIsComing === 1)
      && symName(g.currentMission.type).toLowerCase() === "telephone") {
      d.enterShopEvent = true; d.stopSpeak = true;
      performMission(m);
    }
    if (!d.enterShopEvent) checkFigge(d);
    if (!d.stopSpeak) {
      if (g.justStarted && car().parts.join() === "1,82,133,152") { d.send("Mulle", "MakeMulleSpeak", "yourTurn"); g.justStarted = 0; }
      else if (random(6) === 1) d.send("Mulle", "MakeMulleSpeak", "InspireYou");
    }
  },
  cuePassed(_m, ch, nr, name) { dir()?.send("Mulle", "spritecuePassed", ch, nr, name); },
});

/** Figge Ferrum drops by with junk every third built car (after you've visited him, destination 92). */
function checkFigge(d: GarageDir) {
  const g = G.mulle, u = g.user!;
  if (u.getUserProp("Visited92") instanceof Sym) return; // never met him
  g.calcCurrentlyAvailable("JunkMan");
  if (g.getCurrentlyAvailable("JunkMan").length > 0 && u.nrOfBuiltCars % 3 === 0 && u.figgeIsComing === 1) {
    d.stopSpeak = true;
    d.send("Figge", "doFigge");
    u.figgeIsComing = 0;
    g.junkPiles.figgeBeenHere = 1;
  }
}

// ------------------------------------------------------------------ frame scripts
class GarageLoop extends Behavior { exitFrame() { dir()?.loop(); this.movie.goFrame(this.movie.frame); } }
const goMovie = (id: string, frame: number | string = 1) => class extends Behavior { exitFrame() { void G.engine.goMovie(id, frame); } };
class ToJunkyard extends Behavior { exitFrame() { void G.engine.goMovie("02", "j" + G.mulle.user!.myLastPile); } }
let transitionSound = 0;
class LeaveSound extends Behavior { exitFrame() { transitionSound = G.sound.play(pick(["03d009v0", "03d010v0"]), "EFFECT"); } }
class LeaveWait extends Behavior {
  exitFrame() { if (G.sound.finished(transitionSound)) void G.engine.goMovie("04", 1); else this.movie.goFrame(this.movie.frame); }
}

// ------------------------------------------------------------------ doors
/** DoorBH – to the junkyard (02) and back to the yard (04). */
class GarageDoorBH extends Behavior {
  doortracking = false; activeClick = true; overPart = false;
  trackRect: Rectish = { left: 0, top: 0, right: 0, bottom: 0 };
  get mediaName() { return this.p<string>("mediaName", ""); }
  beginSprite() {
    this.trackRect = this.sprite.rect;
    dir().addScreenObject(new ScreenObject(dir(), this, this.trackRect, 0));
  }
  activateClick(s: boolean) { this.activeClick = !!s; }
  mouseEnter() {
    if (!this.activeClick || dir().mouseOverCar || this.doortracking) return;
    this.doortracking = true;
    dir().send("Figge", "activateClick", 0);
    G.sound.play("02e016v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true;
    if (this.mediaName === "04") { if (!dir().mouseOverMulle && !this.movie.engine.mouse.down) setCursor("c_Left"); }
    else setCursor(dir().parts.tracking ? "c_MoveIn" : "c_click");
  }
  prepareFrame() {
    if (!this.doortracking) return;
    const { x, y } = this.movie.engine.mouse;
    if (inside(x, y, this.trackRect)) return;
    dir().send("Figge", "activateClick", 1);
    G.sound.play("02e015v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, -1);
    if (this.movie.sprite(dir().sp("drag")).send("isActive")) setCursor("c_grab");
    else if (!this.overPart) setCursor("C_Standard");
    this.doortracking = false;
  }
  /** While the mouse is over Mulle the yard door's area shrinks so it doesn't steal hovering. */
  resizeRect(small: boolean | number) {
    this.trackRect = small ? { left: 70, top: 25, right: 45, bottom: 100 } : this.sprite.rect;
  }
  CheckMouse() { const { x, y } = this.movie.engine.mouse; return inside(x, y, this.trackRect); }
  report(_o: ScreenObject, what: ScreenReport) {
    if (what !== "clicked" || dir().mouseOverCar) return;
    const { x, y } = this.movie.engine.mouse;
    if (!inside(x, y, this.trackRect)) return;
    const u = G.mulle.user!;
    u.car.updateProperties();
    u.toYardThroughDoor = 1;
    G.mulle.whereFrom = "03";
    this.movie.goFrame(this.mediaName);
  }
}

/** GaragePortBH – drive the finished car out to the yard (needs wheels and a seat). */
class GaragePortBH extends Behavior {
  doortracking = false; activeClick = true;
  trackRect: Rectish = { left: 0, top: 0, right: 0, bottom: 0 };
  beginSprite() {
    this.trackRect = this.sprite.rect;
    dir().addScreenObject(new ScreenObject(dir(), this, this.trackRect, 0));
  }
  activateClick(s: boolean) { this.activeClick = !!s; }
  mouseEnter() {
    if (!this.activeClick || dir().mouseOverCar || this.doortracking) return;
    this.doortracking = true;
    dir().send("Figge", "activateClick", 0);
    G.sound.play("02e016v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true;
    if (!this.movie.engine.mouse.down) setCursor("c_Left");
  }
  prepareFrame() {
    if (!this.doortracking) return;
    const { x, y } = this.movie.engine.mouse;
    if (inside(x, y, this.trackRect)) return;
    dir().send("Figge", "activateClick", 1);
    G.sound.play("02e015v0", "OPEFFECT");
    this.movie.offsetMember(this.sprite, -1);
    if (!this.movie.engine.mouse.down) setCursor("C_Standard");
    this.doortracking = false;
  }
  report(_o: ScreenObject, what: ScreenReport) {
    if (!this.activeClick || what !== "clicked") return;
    if (dir().send("Mulle", "checkEquipment", "wheels")) { dir().send("Mulle", "MakeMulleSpeak", "noWheels"); return; }
    if (dir().send("Mulle", "checkEquipment", "Seat")) { dir().send("Mulle", "MakeMulleSpeak", "noSeat"); return; }
    this.activeClick = false;
    const u = G.mulle.user!;
    u.car.updateProperties();
    u.toYardThroughDoor = 0;
    G.mulle.whereFrom = "03";
    G.sound.stopAllEffects();
    this.movie.goFrame("garage");
  }
}

/** Save / fetch car shelf buttons – lead to the car album (06). */
const shelfButton = (marker: string, highlight: string) => class extends Behavior {
  activeClick = true; enterMouseDown = false;
  activateClick(s: boolean) { this.activeClick = !!s; }
  mouseUp() { if (this.activeClick && !this.enterMouseDown) this.movie.goFrame(marker); }
  mouseEnter() {
    if (!this.activeClick) return;
    if (this.movie.engine.mouse.down) { this.enterMouseDown = true; return; }
    const hl = this.movie.sprite(dir().sp("HighLight"));
    this.movie.setMemberByName(hl, highlight); hl.setLoc(320, 240); hl.puppet = true;
    setCursor("c_click");
    G.sound.play("02e011v0", "EFFECT");
  }
  mouseLeave() {
    if (!this.activeClick) return;
    if (!this.movie.engine.mouse.down) { this.movie.setMemberByName(this.movie.sprite(dir().sp("HighLight")), "Dummy"); setCursor("C_Standard"); }
    this.enterMouseDown = false;
  }
};

// ------------------------------------------------------------------ car parts on the car
/** CarPartBH – one of the sprites showing a mounted part; free parts can be pulled off. */
class CarPartBH extends Behavior {
  partId = 0; active = false;
  beginSprite() { this.sprite.pixelHit = true; }
  isActive() { return this.active; }
  activateClick(s: boolean) { this.active = !!s; }
  activate(yes: boolean | number) { this.active = !!yes; }
  setPart(id: number) { this.partId = id; this.active = id !== 0; }
  mouseDown() {
    if (!this.active || !this.partId) return;
    const id = this.partId;
    dir().parts.grabbedPart(id, "car");
    dir().parts.showUseView(id, false);
  }
}

/** MouseCheck – tracks whether the mouse is over the car (blocks the doors). */
class MouseCheck extends Behavior {
  mouseEnter() {
    dir().mouseOverCar++;
    const door = this.movie.sprite(dir().sp("DoorStart")).behaviors.find(b => b instanceof GarageDoorBH) as GarageDoorBH | undefined;
    if (door) door.overPart = true;
    if (this.sprite.send("isActive")) setCursor("c_grab");
  }
  mouseLeave() {
    dir().mouseOverCar = Math.max(0, dir().mouseOverCar - 1);
    const door = this.movie.sprite(dir().sp("DoorStart")).behaviors.find(b => b instanceof GarageDoorBH) as GarageDoorBH | undefined;
    if (door) door.overPart = false;
    if (this.movie.sprite(dir().sp("drag")).send("isActive")) {
      const over = dir().send("DoorStart", "CheckMouse");
      setCursor(over && this.movie.engine.mouse.down ? "c_MoveIn" : "c_grab");
    } else setCursor("C_Standard");
  }
}

// ------------------------------------------------------------------ PartsCommon
type SnapRects = [number, Rectish][];

/** The workshop's PartsCommon: snapping logic for building the car. */
class GaragePartsCommon {
  carOffset: Point;
  mulleLayer: number;
  tracking = false;
  waitin = 0;
  playedDescription = 0;
  tmpId = 0;
  dragFrom: "car" | "Floor" = "Floor";
  private trackRect: Rectish = { left: 0, top: 0, right: 0, bottom: 0 };
  constructor(private d: GarageDir) {
    const c = car();
    const chassis = d.movie.sprite(d.sp("CarStart") + c.chassisSPOffset);
    this.carOffset = new Point(chassis.locH, chassis.locV);
    this.mulleLayer = c.driverLayer;
  }

  grabbedPart(id: number, from: "car" | "Floor") {
    const d = this.d, m = d.movie;
    d.send("fButton", "activateClick", 0);
    this.dragFrom = from;
    if (from === "car") {
      car().clear();
      car().removePart(id);
      car().rebuild();
      const master = G.mulle.parts.get(id)?.master; if (master) id = master;
      kickPartSound(id, "car");
    } else G.mulle.user!.removeJunkPart(sym("shopFloor"), id);
    const rects = this.generateSnapRects(id);
    const { x, y } = m.engine.mouse;
    if (from === "car") {
      // shrink the rect we just pulled out of so the part doesn't snap straight back
      for (const e of rects) if (inside(x, y, e[1])) e[1] = { left: e[1].left + 25, top: e[1].top - 25, right: e[1].right - 25, bottom: e[1].bottom - 25 };
    }
    d.send("JunkStart", "drawJunk");
    d.send("drag", "startDrag", id, from, rects);
    this.trackRect = { left: x - 2, top: y - 2, right: x + 2, bottom: y + 2 };
    this.tracking = true;
  }

  /** Target rectangles where each (morph variant of the) part could snap onto the car. */
  generateSnapRects(id: number): SnapRects {
    const parts = G.mulle.parts;
    let part = parts.get(id)!;
    if (part.master) part = parts.get(part.master) ?? part;
    const variants = part.isMorphPart() && (part.morphsTo as number[]).length ? part.morphsTo as number[] : [part.id];
    const rects: SnapRects = [];
    const size = 40;
    for (const vid of variants) {
      const v = parts.get(vid); if (!v || !Array.isArray(v.requires)) continue;
      if (!car().areTheseFree(v.requires)) continue;
      const snapOff = car().snapInfo(v.requires[0])?.[1] ?? [0, 0];
      for (const memberName of [v.useView, v.useView2].filter(Boolean)) {
        const info = G.mulle.memberInfo(memberName); if (!info?.w) continue;
        const mx = info.w / 2 - (info.regX ?? 0) + this.carOffset.x + v.offset.x + snapOff[0];
        const my = info.h! / 2 - (info.regY ?? 0) + this.carOffset.y + v.offset.y + snapOff[1];
        rects.push([vid, { left: mx - size, top: my - size, right: mx + size, bottom: my + size }]);
      }
    }
    if (this.d.send("Mulle", "getCurrentTalk") === "noPoints") this.d.send("Mulle", "waitForProtest", 0, "Cut");
    if (!rects.length && this.waitin === 0) { this.waitin = 1; this.d.send("Mulle", "waitForProtest", 1); }
    return rects;
  }

  /** Show (or hide) a part on the car while it hovers over its snap rect. */
  showUseView(id: number, show: boolean) {
    const m = this.d.movie, part = G.mulle.parts.get(id);
    if (!part || !Array.isArray(part.requires)) return;
    const info = car().snapInfo(part.requires[0]); if (!info) return;
    const [layers, snapOff] = info;
    const members = show ? [part.useView, part.useView2] : ["Dummy", "Dummy"];
    const off = show ? part.offset : new Point(0, 0);
    layers.forEach((layer, n) => {
      if (layer < -1 || !members[n]) return;
      if (layer > this.mulleLayer - 1) layer += 2;
      const s = m.sprite(this.d.sp("CarStart") + layer);
      m.setMemberByName(s, members[n]); s.puppet = true;
      s.setLoc(this.carOffset.x + off.x + snapOff[0], this.carOffset.y + off.y + snapOff[1]);
      s.send("setPart", show ? id : 0);
    });
  }

  letGoOfPart(id: number, where: "car" | Sym | Point) {
    const d = this.d, u = G.mulle.user!, m = d.movie;
    this.playedDescription = 0;
    // a click without moving on a floor part: Mulle describes it
    if (this.dragFrom === "Floor" && this.tracking && inside(m.engine.mouse.x, m.engine.mouse.y, this.trackRect)) {
      if (d.send("Mulle", "getCurrentTalk") !== "noPoints" && id !== this.tmpId) {
        this.tmpId = id;
        d.send("Mulle", "MakeMulleSpeak", "Describe", G.mulle.parts.get(id)?.description ?? "");
      }
      this.playedDescription = 1;
    }
    this.tracking = false;
    d.send("fButton", "activateClick", 1);
    if (this.waitin === 1) { this.waitin = 0; d.send("Mulle", "waitForProtest", 0, "noCut"); }
    let checkFree = true, isFalling = false;
    if (where === "car") {
      car().clear();
      car().addPart(id);
    } else if (where instanceof Sym) {
      // out through the junkyard door
      kickPartSound(id, "ExternalGround");
      setCursor("c_click");
      u.addJunkPart(sym("pile" + u.myLastPile), id);
    } else {
      if (this.dragFrom === "Floor") checkFree = false;
      const [pos, falling] = correctPosition(id, where);
      isFalling = falling;
      if (!falling) kickPartSound(id, "InternalGround");
      u.addJunkPart("shopFloor", id, pos);
    }
    d.send("JunkStart", "drawJunk", isFalling, where instanceof Point ? where : undefined);
    d.send("Mulle", "checkEquipment", "none");
    d.send("CarStart", "drawCar");
    if (checkFree) this.freeOrBindParts();
  }

  /** Parts that have other parts mounted on them are locked (can't be picked off). */
  freeOrBindParts() {
    const d = this.d, c = car(), parts = G.mulle.parts;
    for (const id of c.parts.slice(1)) {
      const part = parts.get(id); if (!part || !Array.isArray(part.requires)) continue;
      const provides = part.newPoints.map(p => p[0]);
      const free = !provides.length || c.areTheseFree(provides);
      const layers = c.snapInfo(part.requires[0])?.[0] ?? [];
      for (let layer of layers.slice(0, 2)) {
        if (layer > this.mulleLayer - 1) layer += 2;
        if (layer > -1) d.movie.sprite(d.sp("CarStart") + layer).send("activate", free ? 1 : 0);
      }
    }
  }
}

/** Where a part dropped on the workshop floor ends up (junkPileHandlers.correctPosition). */
function correctPosition(id: number, loc: Point): [Point, boolean] {
  const floor = G.mulle.junkPiles.rects.shopfloor[0];
  const part = G.mulle.parts.get(id);
  const h = (part && G.mulle.memberInfo(part.junkView)?.h) ?? 0;
  const x = Math.min(Math.max(loc.x, floor.left), floor.right);
  if (loc.y < floor.bottom) return [new Point(x, floor.bottom), true];
  return [new Point(x, floor.bottom + (Math.trunc(h / 2) - (35 + random(10)))), false];
}

// ------------------------------------------------------------------ drag & floor
/** DragPartBH – the part under the mouse; shows it on the car when over a snap rect. */
class GarageDragPartBH extends Behavior {
  active = false; dragging = false; partId = 0; justStarted = false;
  showingUseView = 0; myMember = ""; snapRects: SnapRects = [];
  private screenObject: ScreenObject | null = null;
  isActive() { return this.active; }
  isDragging() { return this.dragging; }
  beginSprite() { this.sprite.noHit = true; }
  startDrag(id: number, _from: string, rects: SnapRects) {
    this.dragging = true; this.snapRects = rects; this.partId = id;
    this.myMember = G.mulle.parts.get(id)!.junkView;
    this.movie.setMemberByName(this.sprite, this.myMember); this.sprite.puppet = true;
    this.justStarted = true; this.active = true; this.showingUseView = 0;
    const d = dir();
    this.screenObject = new ScreenObject(d, this, { left: -1000, top: -1000, right: 2000, bottom: 2000 }, "ClosedHand");
    d.addScreenObject(this.screenObject, 1);
    this.screenObject.checkDown(320, 240);
    this.exitFrame();
  }
  exitFrame() {
    if (!this.active) return;
    const { x, y } = this.movie.engine.mouse;
    this.sprite.setLoc(x | 0, y | 0);
    this.checkSnapRects(x, y);
  }
  private checkSnapRects(x: number, y: number) {
    const parts = dir().parts;
    const hit = this.snapRects.find(([, r]) => inside(x, y, r));
    if (hit) {
      const id = hit[0];
      if (this.showingUseView !== id && !this.justStarted) {
        if (this.showingUseView) parts.showUseView(this.showingUseView, false);
        this.showingUseView = id;
        kickPartSound(this.partId, "car");
        parts.showUseView(id, true);
        this.movie.setMemberByName(this.sprite, "Dummy");
      }
      return;
    }
    this.justStarted = false;
    if (this.showingUseView) {
      parts.showUseView(this.showingUseView, false);
      kickPartSound(this.partId, "car");
      this.showingUseView = 0;
      this.movie.setMemberByName(this.sprite, this.myMember);
    }
  }
  mouseUp() { this.dragging = false; }
  report(_o: ScreenObject, what: ScreenReport) {
    if (what !== "clicked" || !this.active) return;
    this.dragging = false;
    const m = this.movie.engine.mouse;
    const mx = Math.min(630, Math.max(10, m.x | 0));
    this.active = false;
    if (this.screenObject) { dir().deleteScreenObject(this.screenObject); this.screenObject = null; }
    this.movie.setMemberByName(this.sprite, "Dummy");
    // dropped on the junkyard door?
    let toJunk = false;
    const first = dir().sp("DoorStart");
    for (let n = 0; n < 3; n++) {
      const b = this.movie.sprite(first + n).behaviors[0] as any;
      if (b?.doortracking && b.mediaName === "02") toJunk = true;
    }
    const parts = dir().parts;
    if (this.showingUseView) parts.letGoOfPart(this.showingUseView, "car");
    else if (toJunk && !dir().mouseOverCar) {
      const u = G.mulle.user!;
      if (G.mulle.junkPiles.checkFull(sym("pile" + u.myLastPile))) {
        parts.letGoOfPart(this.partId, new Point(mx, m.y | 0));
        dir().send("Mulle", "MakeMulleSpeak", "fullPile");
      } else parts.letGoOfPart(this.partId, sym("ToJunkPile"));
    } else parts.letGoOfPart(this.partId, new Point(mx, m.y | 0));
  }
}

/** DrawJunkBH – parts lying on the workshop floor (up to 35, sprites 46..). */
class GarageDrawJunkBH extends Behavior {
  drawJunk(isFalling?: boolean, from?: Point) {
    const first = this.spriteNum - 1;
    const floor = G.mulle.user!.getJunk("shopFloor");
    const ids = (floor.keys() as number[]).filter(id => G.mulle.parts.get(id)); // hide parts of disabled extras
    for (let n = 1; n <= 35; n++) {
      const s = this.movie.sprite(first + n);
      if (n <= ids.length) s.send("setPart", ids[n - 1], floor.get(ids[n - 1]), n === ids.length ? !!isFalling : false, from);
      else { s.send("setPart", 0); this.movie.setMember(s, null); s.setLoc(-200, -200); }
    }
  }
}

class GarageFloorPartBH extends Behavior {
  partId = 0; isFalling = false; floorLocV = 0; velV = 0; activeClick = true;
  beginSprite() { this.sprite.pixelHit = true; }
  activateClick(s: boolean) { this.activeClick = !!s; }
  setPart(id: number, loc?: Point, falling?: boolean, from?: Point) {
    const s = this.sprite; s.puppet = true;
    this.isFalling = !!falling;
    if (!id) { this.partId = 0; this.isFalling = false; this.movie.setMemberByName(s, "Dummy"); return; }
    const p = loc instanceof Point ? loc : new Point(300, 430);
    if (this.isFalling && from) { s.setLoc(from.x, from.y); this.velV = 0; this.floorLocV = p.y; }
    else s.setLoc(p.x, p.y);
    this.partId = id;
    this.movie.setMemberByName(s, G.mulle.parts.get(id)!.junkView);
  }
  mouseDown() { if (this.activeClick && this.partId && this.sprite.member?.info.name.toLowerCase() !== "dummy") dir().parts.grabbedPart(this.partId, "Floor"); }
  exitFrame() {
    if (!this.isFalling) return;
    const s = this.sprite;
    if (s.locV === this.floorLocV) {
      const hmax = G.mulle.junkPiles.rects.shopfloor[0].right;
      if (s.locH > hmax) s.locH = hmax;
      this.isFalling = false;
      if (!dir().parts.playedDescription) kickPartSound(this.partId, "InternalGround");
      G.mulle.user!.setJunkPartProp(sym("shopFloor"), this.partId, new Point(s.locH, this.floorLocV));
    } else {
      if (this.velV < 60) this.velV += 8;
      s.locV = Math.min(s.locV + this.velV, this.floorLocV);
    }
  }
}

// ------------------------------------------------------------------ characters
/** MulleShopBH – Mulle in the workshop: comments on the car, describes parts, protests. */
class MulleShopBH extends Behavior {
  mode = "Wait"; currentTalk = "Silence"; activeClick = true; makeHimLeave = false;
  frozenAction = ""; frozenExtra = ""; currentSound: number | "start" | "nothing" = "start"; loopcount = 0;
  startSounds = ["03d027v0", "03d060v0", "03d062v0"];
  okSounds = ["03d034v0", "03d035v0", "03d036v0", "03d061v0"];
  greatSounds = ["03d037v0", "03d038v0"];
  randomSounds = this.startSounds;
  leadSounds: string[] = [];
  currentAnimChart = "Verkstad";
  get anim() { return this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  getCurrentTalk() { return this.currentTalk; }
  activateClick(s: boolean) { this.activeClick = !!s; }
  private act(m: string) { this.mode = m; this.sprite.send("setAnimAction", m); }
  private talkChart() { if (random(2) === 2) { this.currentAnimChart = "TalkToMe"; this.sprite.send("setAnimChart", "TalkToMe"); } }

  exitFrame() {
    if (this.currentTalk === "Silence" && this.activeClick && this.mode === "Wait" && this.anim?.getAnimWaitState() === "Still" && random(250) === 1)
      this.randomMove();
  }
  removeLoop() { dir().deleteLoopObject(this); }
  waitForProtest(yes: number, extra?: string) {
    if (yes === 1) { this.currentSound = "nothing"; this.activeClick = false; dir().addLoopObject(this); this.loopcount = 0; return; }
    this.activeClick = true; dir().deleteLoopObject(this); this.loopcount = 0;
    if (extra === "Cut" && this.mode === "Talk") {
      dir().parts.waitin = 0;
      dir().send("Figge", "activateClick", 1);
      this.act("Wait");
      G.sound.stopAllEffects();
    }
  }
  loop() {
    if (this.currentSound === "nothing") {
      // the player has held a part that fits nowhere for a while: Mulle protests
      if (this.loopcount === 14) {
        this.activeClick = true; dir().deleteLoopObject(this); this.loopcount = 0;
        if (this.mode === "Talk" || this.mode === "Wait") this.MakeMulleSpeak("noPoints");
      } else this.loopcount++;
    } else if (this.currentSound === "start") {
      if (this.movie.frame === 2) { dir().deleteLoopObject(this); this.MakeMulleSpeak(this.frozenAction, this.frozenExtra); }
    } else if (G.sound.finished(this.currentSound) && this.mode === "Wait") {
      this.act("Wait");
      dir().deleteLoopObject(this);
    }
  }
  MakeMulleSpeak(action: string | Sym, extra?: string) {
    action = symName(action);
    this.currentTalk = action;
    if (this.movie.frame === 1) { this.frozenAction = action; this.frozenExtra = extra ?? ""; dir().addLoopObject(this); return; }
    if (typeof this.currentSound === "number" && !G.sound.finished(this.currentSound)) return;
    this.anim.playAnimSound("");
    const table: Record<string, () => string> = {
      noWheels: () => "03d011v0", noSeat: () => "03d039v0", yourTurn: () => "03d028v0", fullPile: () => "03d033v0",
      greetFigge: () => { this.makeHimLeave = true; return "03d045v0"; },
      noPoints: () => pick(["03d040v0", "03d041v0", "03d042v0"]),
      InspireYou: () => pick(["03d052v0", "03d053v0", "03d054v0", "03d055v0", "03d056v0"]),
      Describe: () => extra ?? "",
      afterTrash0: () => "03d031v0", AfterTrash1: () => "03d030v0", AfterTrash2: () => "03d029v0", AfterTrash3: () => "03d028v0",
    };
    const snd = table[action]?.() ?? "";
    if (this.mode === "Wait" || this.mode === "Talk") {
      this.anim.makeAnimSpeech(snd);
      if (action === "noPoints") { this.currentAnimChart = "TalkToMe"; this.sprite.send("setAnimChart", "TalkToMe"); }
      else if (action !== "greetFigge") this.talkChart();
      this.act("Talk");
      this.currentSound = 0;
    } else if (this.mode !== "LookUnderCar") {
      dir().deleteLoopObject(this);
      this.currentSound = G.sound.play(snd, "EFFECT");
      dir().addLoopObject(this);
    }
    return this.currentSound;
  }
  randomMove() {
    if (this.mode !== "Wait" || !this.randomSounds.length) return;
    this.sprite.send("setAnimFirstFrame", "00a001v0");
    dir().send("Figge", "activateClick", 0);
    this.talkChart();
    this.anim.makeAnimSpeech(pick(this.randomSounds));
    this.act("Talk");
  }
  /** Mulle's opinion about what the car lacks (and whether it can go out). */
  checkEquipment(what: string | Sym) {
    what = symName(what);
    const c = car();
    const wheelsMissing = c.areTheseFree([sym("a1")]) || c.areTheseFree([sym("a13")]);
    if (what === "wheels") return wheelsMissing ? 1 : 0;
    if (what === "Seat") return c.prop("Comfort") === 0 ? 1 : 0;
    c.updateProperties();
    const n = c.parts.length;
    this.randomSounds = n >= 12 ? this.greatSounds : n >= 8 ? this.okSounds : this.startSounds;
    const lead: string[] = wheelsMissing ? ["03d011v0", "03d012v0"] : ["03d005v0", "03d006v0", "03d007v0"];
    const missing: [string, string][] = [["break", "03d018v0"], ["FuelConsumption", "03d013v0"], ["ElectricVolume", "03d014v0"],
      ["FuelVolume", "03d015v0"], ["acceleration", "03d016v0"], ["Steering", "03d017v0"], ["Horn", "03d019v0"],
      ["ExhaustPipe", "03d020v0"], ["Lamps", "03d021v0"]];
    for (const [p, s] of missing) if (c.prop(p) === 0) lead.push(s);
    this.leadSounds = lead;
  }
  mouseUp() {
    if (!this.activeClick || this.mode !== "Wait") return;
    dir().send("Figge", "activateClick", 0);
    this.talkChart();
    this.anim.makeAnimSpeech(pick(this.leadSounds));
    this.act("Talk");
  }
  mouseEnter() { dir().mouseOverMulle = 1; dir().send("DoorToYard", "resizeRect", 1); }
  mouseLeave() { dir().mouseOverMulle = 0; dir().send("DoorToYard", "resizeRect", 0); }
  Stopped() {
    let next = "Wait";
    switch (this.mode) {
      case "GoTable": next = "Work"; break;
      case "Work": next = random(8) === 1 ? "GoBack" : "Work"; break;
      case "Talk":
        if (this.makeHimLeave) { dir().send("Figge", "FiggeLeave"); this.makeHimLeave = false; }
        if (this.currentAnimChart === "TalkToMe") { this.sprite.send("setAnimChart", "Verkstad"); this.currentAnimChart = "Verkstad"; }
        this.anim.setAnimNormal();
        this.currentTalk = "Silence";
        dir().parts.waitin = 0; dir().parts.tmpId = 0;
        break;
      case "LookUnderCar": break;
      default: this.sprite.send("setAnimFirstFrame", "00a001v0");
    }
    dir().send("Figge", "activateClick", 1);
    this.act(next);
  }
}

/** BuffaShopBH – Buffa lying around in the workshop. */
class BuffaShopBH extends Behavior {
  mode = "Wait";
  beginSprite() { this.sprite.send("setAnimNormal"); }
  private act(m: string) { this.mode = m; this.sprite.send("setAnimAction", m); }
  exitFrame() { if (this.mode === "Wait" && random(100) === 1) this.act("GetDown"); }
  mouseUp() { if (this.mode === "Wait") this.act("GetDown"); else if (this.mode === "Sleep") this.act("GetUp"); }
  Stopped() {
    this.act(this.mode === "GetDown" ? "Sleep" : this.mode === "Sleep" ? (random(30) === 1 ? "GetUp" : "Sleep") : "Wait");
  }
}

/** FiggeShopBH – Figge Ferrum knocks, comes in, leaves junk in the yard and goes again. */
class FiggeShopBH extends Behavior {
  type = "Figge"; mode = "Still"; activeClick = true; currentSound: unknown = 0; exitLoopAction = 0;
  get anim() { return this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  beginSprite() { this.anim?.setAnimNormal(); this.sprite.visible = false; }
  activateClick(s: boolean) { this.activeClick = !!s; }
  private act(m: string) { this.mode = m; this.sprite.send("setAnimAction", m); }
  loop() {
    if (typeof this.currentSound === "number" && !G.sound.finished(this.currentSound)) return;
    switch (this.exitLoopAction) {
      case 1: this.currentSound = G.sound.play("03d043v0", "EFFECT"); this.exitLoopAction = 2; break;
      case 2: this.finishFigge(); this.exitLoopAction = 3; dir().deleteLoopObject(this); break;
      case 4: this.act("Talk"); dir().deleteLoopObject(this); break;
    }
  }
  doFigge() {
    if (!this.activeClick) return;
    dir().activate(false);
    this.currentSound = G.sound.play("03e009v0", "EFFECT");
    dir().addLoopObject(this);
    this.exitLoopAction = 1;
  }
  private finishFigge() {
    if (this.mode !== "Still") return;
    G.sound.play("02e016v0", "EFFECT");
    this.movie.offsetMember(dir().sp("DoorStart"), +1);
    this.leaveStuff();
    this.sprite.visible = true;
    this.act("ComeIn");
  }
  private leaveStuff() {
    const g = G.mulle; g.calcCurrentlyAvailable("JunkMan");
    for (const id of g.getCurrentlyAvailable("JunkMan").slice(0, 3)) g.user!.addJunkPart("yard", id);
    this.movie.sprite(dir().sp("FiggeInterup")).setLoc(0, 0);
  }
  Interupt() {
    if (this.exitLoopAction === 3) {
      const mulle = this.movie.sprite(dir().sp("Mulle")).behaviors.find(b => b instanceof MulleShopBH) as MulleShopBH | undefined;
      if (mulle) mulle.makeHimLeave = false;
      dir().send("Mulle", "Stopped");
    }
    this.exitLoopAction = 4;
    G.sound.stopAllEffects();
  }
  FiggeLeave() {
    this.anim.makeAnimSpeech("03d046v0");
    dir().addLoopObject(this);
    this.act("Talk");
    this.exitLoopAction = 4;
  }
  Stopped() {
    let next = this.mode;
    switch (this.mode) {
      case "ComeIn": this.anim.makeAnimSpeech("03d044v0"); next = "Talk"; break;
      case "Talk":
        if (this.exitLoopAction === 3) {
          this.currentSound = dir().send("Mulle", "MakeMulleSpeak", "greetFigge");
          dir().addLoopObject(this); next = "Freeze";
        } else { this.anim.setAnimNormal(); next = "GoOut"; this.exitLoopAction = 0; }
        break;
      case "GoOut":
        next = "Still";
        this.sprite.visible = false;
        G.sound.play("02e015v0", "EFFECT");
        this.movie.offsetMember(dir().sp("DoorStart"), -1);
        G.sound.play("03e010v0", "EFFECT");
        this.movie.sprite(dir().sp("FiggeInterup")).setLoc(700, 500);
        dir().activate(true);
        break;
    }
    this.act(next);
  }
}

/** Clicking anywhere while Figge talks interrupts him. */
class InteruptFiggeBH extends Behavior { mouseUp() { dir().send("Figge", "Interupt"); } }

// ------------------------------------------------------------------ registration
export function registerGarage(engine: Engine) {
  engine.registerMovie("03", garageMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`03:${n}`, c);
  B(3, GarageLoop);
  B(5, ToJunkyard);              // marker "02"
  B(6, goMovie("04"));           // marker "04"
  B(8, goMovie("06", "load"));   // marker "07" – fetch a saved car
  B(11, goMovie("06", "save"));  // marker "06" – save the car
  B(15, goMovie("08"));          // diploma
  B(18, goMovie("12"));          // quit
  B(30, LeaveSound); B(32, LeaveWait);
  B(20, GarageDoorBH); B(21, GaragePortBH);
  B(19, shelfButton("06", "03b006v0")); B(16, shelfButton("07", "03b004v0"));
  B(14, CarPartBH); B(12, MouseCheck);
  B(13, GarageDragPartBH); B(9, GarageDrawJunkBH); B(10, GarageFloorPartBH);
  B(23, MulleShopBH); B(94, BuffaShopBH); B(80, FiggeShopBH); B(45, InteruptFiggeBH);
  B(26, Behavior); // Highlight_BH: empty
}
