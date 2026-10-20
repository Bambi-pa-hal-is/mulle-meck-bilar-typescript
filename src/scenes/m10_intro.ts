/**
 * Movie 10 – the name screen ("Vem är du?") and the intro cartoon.
 * Type your name and click Mulle (or press Enter), or click a name in the list; double-click logs in,
 * drag a name onto the bin to delete that player. After login the intro plays; a click skips it.
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir } from "../game/dir.ts";
import { G, random } from "../game/runtime.ts";
import type { SpriteAnimBH } from "./common.ts";
import { setCursor } from "./common.ts";

const LINE_H = 22;
const MAX_USERS = 6;

class IntroDir extends GameDir {
  okToEnd = false;
  enterText = "";
  constructor(m: Movie) {
    super(m);
    this.spriteList = { EnterField: 14, ScrollMain: 22, MulleBody: 4, MulleHead: 5, Buffa: 8, Loading: 114, Cover: 113, Trash: 15, Dragger: 25 };
  }

  /** The typed name: trimmed; an existing name logs in, a new one creates the player. */
  tryToLeave() {
    const name = this.enterText.replace(/[\r\n]/g, "").trim();
    if (name) this.send("ScrollMain", "AddLine", name);
  }

  resultsFromScroller(type: "ChoseLine" | "NewLine" | "DeletedLine", name: string) {
    const g = G.mulle;
    if (type === "DeletedLine") { g.deleteUser(name); return; }
    if (g.login(name) !== "ok") { if (type === "NewLine") this.send("ScrollMain", "deleteLine", name); return; }
    g.save();
    this.movie.engine.editField(null);
    this.movie.goFrame("IntroStart");
    this.okToEnd = true;
  }

  /** Name entry: a DOM input laid over the EnterField sprite. */
  editName(value = this.enterText) {
    this.enterText = value;
    this.movie.setText("EnterField", value);
    this.movie.engine.editField(this.sp("EnterField"), value, v => { this.enterText = v; this.movie.setText("EnterField", v); }, 16);
  }
}
const dir = () => G.dir as IntroDir;

export const introMovie = (): MovieScript => ({
  prepareMovie(m) { G.dir = new IntroDir(m); },
  startMovie(m) {
    G.mulle.whereFrom = "10";
    setCursor("C_Standard");
    m.goNextMarker();
    dir().send("ScrollMain", "setText", [...G.mulle.users]);
    m.setMemberByName(m.sprite(dir().sp("Cover")), "Dummy");
    // Enter in the name field = click on Mulle
    m.engine.keyDownScript = e => { if (e.key === "Enter") dir()?.tryToLeave(); };
  },
  // on the name screen typing always goes to the name sign, wherever you clicked
  mouseDown() { if (!dir()?.okToEnd) G.engine.focusInput(); },
  // a click anywhere skips the intro once logged in
  mouseUp() {
    if (!dir()?.okToEnd) { G.engine.focusInput(); return; }
    const s = G.engine.sound; s.stop(1); s.stop(2); s.stop(3);
    void G.engine.goMovie("03", 1);
  },
});

// ------------------------------------------------------------------ frame scripts
class Hold extends Behavior { exitFrame() { this.movie.goFrame(this.movie.frame); } }
const holdWhileSound = (ch: number) => class extends Behavior { exitFrame() { if (this.movie.engine.sound.busy(ch)) this.movie.goFrame(this.movie.frame); } };
/** Hold until the score sound reaches the named cue point, then continue. */
const holdUntilCue = (cue: string) => class extends Behavior {
  exitFrame() { this.movie.goFrame(this.movie.frame); }
  // Lingo string comparison is case-insensitive ("Cykla" matches the cue "cykla")
  CuePassed(ch: number, _nr: number, name: string) { if (ch === 1 && name.toLowerCase() === cue.toLowerCase()) this.movie.goFrame(this.movie.frame + 1); }
};
class ToWorkshop extends Behavior { exitFrame() { void G.engine.goMovie("03", 1); } }
class StandardCursor extends Behavior { exitFrame() { setCursor("C_Standard"); } }

// ------------------------------------------------------------------ name list
/** ScrollFieldBH – the list of players (one per line). */
class ScrollFieldBH extends Behavior {
  lines: string[] = [];
  private downOn = 0; private wait = 0; private lastUp = 0; private lastUpLine = 0;
  beginSprite() { this.setText([...G.mulle.users]); this.sprite.pixelHit = false; }
  endSprite() { this.movie.setText("ScrollField", " "); }
  setText(list: string[]) {
    this.lines = [...list].sort((a, b) => a.localeCompare(b, "sv"));
    this.movie.setText("ScrollField", this.lines.join("\n") || " ");
  }
  private lineAt(y: number) {
    const lh = this.sprite.member?.info.font?.lineHeight || LINE_H;   // textHeight of the field
    return Math.min(Math.max(1, 1 + Math.trunc((y - this.sprite.rect.top) / lh)), this.lines.length);
  }
  AddLine(name: string) {
    if (this.lines.some(l => l.toLowerCase() === name.toLowerCase())) { dir().resultsFromScroller("ChoseLine", this.lines.find(l => l.toLowerCase() === name.toLowerCase())!); return; }
    if (this.lines.length >= MAX_USERS) { dir().send("MulleHead", "fullAlert"); return; }
    this.setText([...this.lines, name]);
    dir().resultsFromScroller("NewLine", name);
  }
  deleteLine(name: string) {
    if (!this.lines.includes(name)) return;
    this.setText(this.lines.filter(l => l !== name));
    dir().resultsFromScroller("DeletedLine", name);
  }
  mouseDown() {
    if (!this.lines.length) return;
    this.downOn = this.lineAt(this.movie.engine.mouse.y);
    this.wait = 3;
    const drag = dir().sp("Dragger");
    this.movie.setText(this.movie.sprite(drag).member?.info.name ?? "Tjohoo", this.lines[this.downOn - 1]);
    dir().send("Trash", "startDrag");
  }
  mouseUp() {
    if (!this.lines.length) return;
    dir().send("Trash", "endDrag");
    const line = this.lineAt(this.movie.engine.mouse.y);
    const now = performance.now();
    if (line === this.downOn) {
      if (line === this.lastUpLine && now - this.lastUp < 450) dir().resultsFromScroller("ChoseLine", this.lines[line - 1]);
      else dir().editName(this.lines[line - 1]);
    }
    this.lastUp = now; this.lastUpLine = line;
    this.hideDragger();
    this.downOn = 0;
  }
  mouseUpOutside() {
    if (this.downOn) dir().send("Trash", "scrollThrowHere", this.spriteNum, this.lines[this.downOn - 1]);
    this.hideDragger();
    this.downOn = 0;
  }
  private hideDragger() { this.movie.sprite(dir().sp("Dragger")).locH = -4711; }
  exitFrame() {
    if (!this.downOn) return;
    if (this.wait) { this.wait--; return; }
    const s = this.movie.sprite(dir().sp("Dragger")), { x, y } = this.movie.engine.mouse;
    s.setLoc((x | 0) - 52, (y | 0) - 25); s.puppet = true;
  }
}

/** TrashBH – drop a name here to delete that player. */
class TrashBH extends Behavior {
  private inside = false; private dragging = false; private first = 0;
  beginSprite() { this.first = this.sprite.member?.info.num ?? 0; }
  private show(n: number) { const ref = this.sprite.member; if (ref) { this.movie.setMember(this.sprite, this.movie.memberInLib(ref, this.first + n)); this.sprite.puppet = true; } }
  startDrag() { this.dragging = true; }
  endDrag() { this.dragging = false; }
  mouseEnter() {
    if (this.dragging) { G.sound.play("11e001v0", "OPEFFECT"); dir().send("MulleHead", "WarnOfThrowing"); this.show(1); }
    this.inside = true;
  }
  mouseLeave() { this.show(0); this.inside = false; }
  scrollThrowHere(from: number, name: string) {
    this.dragging = false;
    const { x, y } = this.movie.engine.mouse;
    if (from === dir().sp("ScrollMain") && (this.inside || this.sprite.hitTest(x, y))) {
      G.sound.play("11e002v0", "OPEFFECT");
      dir().send("ScrollMain", "deleteLine", name);
      this.show(1);
    }
  }
}

/** EnterField – the typed name (ScrollEnterDeleteBH). */
class EnterFieldBH extends Behavior {
  beginSprite() { dir()?.editName(""); }
  endSprite() { this.movie.engine.editField(null); this.movie.setText("EnterField", " "); }
}

/** ClickMulle – clicking Mulle sends the typed name. */
class ClickMulle extends Behavior { mouseUp() { dir().tryToLeave(); G.engine.focusInput(); } }

/** SendBH – tells Mulle's head which label (Still/Talk/Wait) we're on. */
class SendBH extends Behavior { beginSprite() { dir().send("MulleHead", "BeginFrame", this.movie.frameLabel); } }

// ------------------------------------------------------------------ Mulle
/** MulleLogBH – Mulle's head on the name screen: talks, blinks, scratches, warns about the bin. */
class MulleLogBH extends Behavior {
  mode = "Still"; whichFrame = ""; private lastSound = 0;
  private readonly sounds = ["11d002v0", "11d003v0", "11d004v0", "11d005v0", "11d006v0"];
  private get anim() { return this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  private get body() { return this.movie.sprite(dir().sp("MulleBody")).behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  beginSprite() { this.anim?.setAnimNormal(); this.body?.setAnimNormal(); }
  exitFrame() { if (this.whichFrame === "wait" && this.mode === "Still" && random(50) === 1) this.randomMove(); }
  private randomMove() {
    const r = random(8);
    if (r === 1) { this.mode = "Kli"; this.body.setAnimAction("Kli"); this.anim.activate(false); this.movie.setMemberByName(this.sprite, "Dummy"); }
    else if (r <= 4) { this.mode = "Blink"; this.anim.setAnimAction("Blink"); }
    else {
      this.mode = "Talk";
      let n = 0; do { n = random(this.sounds.length); } while (n === this.lastSound && this.sounds.length > 1);
      this.lastSound = n;
      this.anim.makeAnimSpeech(this.sounds[n - 1]); this.anim.setAnimAction("Talk");
    }
  }
  BeginFrame(label: string) {
    this.whichFrame = label.toLowerCase();
    if (this.whichFrame === "still") this.mode = "VeryStill";
    else if (this.whichFrame === "talk") { this.mode = "Talk"; this.anim.makeAnimSpeech("11d001v0"); this.anim.setAnimAction("Talk"); }
    else if (this.whichFrame === "wait") this.mode = "Still";
  }
  private say(snd: string) {
    if (this.whichFrame !== "talk") this.movie.goFrame("Wait");
    this.mode = "Talk";
    this.body.setAnimAction("Still");
    this.anim.activate(true);
    this.anim.makeAnimSpeech(snd); this.anim.setAnimAction("Talk");
  }
  WarnOfThrowing() { this.say("11d007v0"); }
  fullAlert() { this.say("11d008v0"); }
  Stopped() {
    if (this.mode === "TalkPek") { this.mode = "Talk"; return; }
    if (this.mode === "Kli" || this.mode === "Pek") { this.anim.setAnimNormal(); this.anim.activate(true); }
    else if (this.mode === "Talk") { this.anim.setAnimNormal(); if (this.whichFrame === "talk") this.movie.goFrame("Wait"); }
    this.mode = "Still";
    this.anim.setAnimAction("Still");
  }
  spritecuePassed(ch: number, _nr: number, name: string) {
    if (name.toLowerCase() === "point" && ch === this.anim.myChannel) { this.mode = "TalkPek"; this.body.setAnimAction("Pek"); }
  }
}
/** MulleLogBodyBH – forwards the body's animation end to the head. */
class MulleLogBodyBH extends Behavior { Stopped() { dir().send("MulleHead", "Stopped"); } }

// ------------------------------------------------------------------ registration
export function registerIntro(engine: Engine) {
  engine.registerMovie("10", introMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`10:${n}`, c);
  B(9, holdWhileSound(1)); B(10, holdWhileSound(2)); B(24, Hold);
  B(7, holdUntilCue("Mulle")); B(8, holdUntilCue("Cykla"));
  B(3, Behavior); B(55, StandardCursor); B(77, ToWorkshop);
  B(63, ScrollFieldBH); B(68, TrashBH); B(66, EnterFieldBH); B(78, ClickMulle); B(73, SendBH);
  B(71, MulleLogBH); B(72, MulleLogBodyBH);
}
