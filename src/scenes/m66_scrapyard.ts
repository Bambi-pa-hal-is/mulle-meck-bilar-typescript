/**
 * Movie 66 – Figges skrot (plugin / extra material): a crane puzzle (Tower of Hanoi style).
 * Arrow keys: ← → move the crane between the three stacks, ↑ lifts the top can, ↓ sets it down.
 * A can may only be put on a bigger one. Clear the left stack and lift the prize to win an extra part.
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, lingoValue } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir } from "../game/dir.ts";
import { G, random } from "../game/runtime.ts";
import { setCursor, CursorSpriteBH } from "./common.ts";

const CAN1 = 61;                                   // the prize (bottom of the left stack)
const CAN_HEIGHTS = [1, 62, 48, 31, 35, 30];       // per sprite 61..66
const CRANE_SP = 68;
const CRANES = ["Kran1", "Kran2", "Kran3"];
const CRANE_LOCS = [new Point(125, 152), new Point(320, 155), new Point(486, 154)];

class CanStack {
  stack: number[] = [];
  currentV: number;
  constructor(public locH: number, public locV: number) { this.currentV = locV; }
  top() { return this.stack[this.stack.length - 1] ?? 0; }
  isEmpty() { return this.stack.length === 0; }
  push(m: Movie, can: number): boolean {
    const top = this.top();
    if (top >= can) return false;               // bigger sprite number = smaller can
    this.stack.push(can);
    const s = m.sprite(can); s.locV = this.currentV; s.locH = this.locH; s.puppet = true;
    this.currentV -= CAN_HEIGHTS[can - CAN1];
    if (top) m.sprite(top).send("killActive");
    m.sprite(can).send("setActive");
    return true;
  }
  pop(m: Movie): number {
    const top = this.top();
    if (!top) { puppetSound(m, "P36ef008"); return 0; }
    this.stack.pop();
    this.currentV += CAN_HEIGHTS[top - CAN1];
    const next = this.top();
    if (next && next !== CAN1) m.sprite(next).send("setActive");
    return top;
  }
}

/** puppetSound(name): play in sound channel 1. */
function puppetSound(m: Movie, name: string) { const r = m.member(name); if (r) void m.engine.sound.play(1, r); }

class ScrapDir extends GameDir {
  partToGive = 666; gotPart = false;
  stacks: CanStack[] = [];
  dragging = 0; dragLoc = new Point(0, 0);
  crane = 0;                 // 0 left, 1 centre, 2 right
  item = 0;                  // can hanging in the crane
  timerStart = 0;
  private prizes(): number[] { const v = lingoValue(this.movie.text("PluginGameDB")); return Array.isArray(v) ? v as number[] : []; }

  /** Pick a prize the player doesn't own yet (else part 666, a consolation). */
  init() {
    const u = G.mulle.user!;
    const list = this.prizes().filter(id => !u.findPart(id));
    if (G.mulle.world?.enteredObjectId && list.length) { this.partToGive = list[random(list.length) - 1]; this.gotPart = true; }
    else { this.partToGive = 666; this.gotPart = false; }
  }
  checkBeenHereBefore() { const u = G.mulle.user!; return this.prizes().some(id => !!u.findPart(id)); }
  getPartToGive() { return this.partToGive; }
  leave() { if (this.gotPart) G.mulle.user!.addJunkPart("yard", this.partToGive); G.mulle.save(); }

  startGame() {
    const m = this.movie;
    m.goFrame("Game");
    this.dragging = 0; this.crane = 0; this.item = 0;
    m.sprite(CAN1).visible = true;
    this.stacks = [new CanStack(133, 407), new CanStack(325, 407), new CanStack(500, 407)];
    for (let can = CAN1; can <= 66; can++) this.stacks[0].push(m, can);
    this.showCrane();
  }
  private showCrane() { const s = this.movie.sprite(CRANE_SP); this.movie.setMemberByName(s, CRANES[this.crane]); s.puppet = true; }
  private hangItem() {
    const p = CRANE_LOCS[this.crane], h = Math.trunc(CAN_HEIGHTS[this.item - CAN1] / 2);
    this.movie.sprite(this.item).setLoc(p.x + h, p.y + h);  // Lingo point + integer adds to both
  }
  moveCrane(dir: -1 | 1) {
    const to = this.crane + dir; if (to < 0 || to > 2) return;
    this.crane = to; this.showCrane();
    if (this.item) this.hangItem();
  }
  goUp() {
    const m = this.movie;
    if (this.item) { puppetSound(m, "P36ef008"); return; }
    const can = this.stacks[this.crane].top();
    if (!can) return;
    if (m.sprite(can).send("getItem") === "abort") return;   // the prize: game won
    if (m.frameLabel === "game") { this.item = can; this.hangItem(); }
  }
  goDown() {
    const m = this.movie;
    if (!this.item) { puppetSound(m, "P36ef008"); return; }
    m.sprite(this.item).send("dropItem");
    this.item = 0;
  }

  /** drag(can): the can leaves its place (only the top can is active). */
  drag(can: number) {
    const m = this.movie, b = m.sprite(can).behaviors.find(x => x instanceof CanBH) as CanBH | undefined;
    if (!b?.active) return;
    const s = m.sprite(can);
    this.dragLoc = new Point(s.locH, s.locV); this.dragging = can;
    puppetSound(m, "P36ef004");
  }
  /** drop(can): put it on the stack under it if the rules allow, else back where it came from. */
  drop(can: number) {
    const m = this.movie;
    if (this.dragging !== can) return;
    this.dragging = 0;
    const h = m.sprite(can).locH;
    const target = h > 100 && h < 300 ? 0 : h > 300 && h < 380 ? 1 : h > 380 && h < 620 ? 2 : -1;
    const st = target >= 0 ? this.stacks[target] : null;
    if (!st || st.top() >= can) { const s = m.sprite(can); s.setLoc(this.dragLoc.x, this.dragLoc.y); puppetSound(m, "P09ef001"); return; }
    puppetSound(m, st.isEmpty() ? "P09ef004" : "P09ef005");
    st.push(m, can);
    this.stacks.forEach((o, i) => { if (i !== target && o.top() === can) o.pop(m); });
    // no prize left to win: moving the biggest can away ends the game
    if (target > 0 && !this.gotPart && can === CAN1 + 1) m.goFrame("NoGive");
  }
}
const dir = () => G.dir as ScrapDir;

export const scrapyardMovie = (): MovieScript => ({
  prepareMovie(m) { G.dir = new ScrapDir(m); },
  startMovie(m) {
    dir().init();
    setCursor("C_Standard");
    m.engine.keyDownScript = e => {
      if (m.frameLabel !== "game") return;
      const d = dir();
      if (e.key === "ArrowLeft") d.moveCrane(-1);
      else if (e.key === "ArrowRight") d.moveCrane(1);
      else if (e.key === "ArrowDown") d.goDown();
      else if (e.key === "ArrowUp") d.goUp();
    };
  },
});

// ------------------------------------------------------------------ behaviors & frame scripts
class Hold extends Behavior { exitFrame() { this.movie.goFrame(this.movie.frame); } }
/** Skip the intro if the player has already won a part here. */
class SkipIfBeenHere extends Behavior { enterFrame() { if (dir().checkBeenHereBefore()) this.movie.goFrame("startGame"); } }
class StartTimer extends Behavior { exitFrame() { dir().timerStart = performance.now(); } }
/** "Synk Sound pilar": hold until the timer (in 1/60 s ticks) passes pTimerTime – syncs the intro to its sound. */
class SyncTimer extends Behavior {
  exitFrame() {
    const ticks = ((performance.now() - dir().timerStart) * 60) / 1000;
    this.movie.goFrame(ticks > this.p<number>("pTimerTime", 0) ? this.movie.frame + 1 : this.movie.frame);
  }
}
class StartGame extends Behavior { exitFrame() { dir().startGame(); } }
class GoLeave extends Behavior { mouseUp() { this.movie.goFrame("Leave"); } }
class GivePart extends Behavior { beginSprite() { dir().leave(); } }

/** A can: only the top can of a stack is active (can be lifted). */
class CanBH extends Behavior {
  active = false;
  setActive() { this.active = true; }
  killActive() { this.active = false; }
  getItem() { this.active = true; dir().drag(this.spriteNum); }
  dropItem() { this.active = true; dir().drop(this.spriteNum); }
}
/** The prize under the left stack: can be lifted only when all cans are moved away. */
class StuffToGetScript extends Behavior {
  getItem() {
    if (dir().stacks[0].top() !== CAN1) { puppetSound(this.movie, "P36ef008"); return; }
    this.sprite.setLoc(99, 457);
    this.movie.goNextMarker();
    return "abort";
  }
}

export function registerScrapyard(engine: Engine) {
  engine.registerMovie("66", scrapyardMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`66:${n}`, c);
  B(1, Hold); B(15, Hold); B(14, SkipIfBeenHere); B(9, StartTimer); B(10, SyncTimer); B(2, StartGame);
  B(46, GoLeave); B(7, GivePart); B(13, CanBH); B(26, StuffToGetScript);
  B(12, CursorSpriteBH); // the movie's own copy of the cursor behavior – same as the shared one
}
