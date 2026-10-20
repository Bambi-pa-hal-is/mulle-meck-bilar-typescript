import type { Movie } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";

export interface Rectish { left: number; top: number; right: number; bottom: number; }
export const inside = (x: number, y: number, r: Rectish) => x >= r.left && x < r.right && y >= r.top && y < r.bottom;

export type ScreenReport = "downOn" | "stillDown" | "clicked" | "UpOutside" | "over" | "NotOver";
export interface Reporter { report(obj: ScreenObject, what: ScreenReport): void; }

/** A rectangular click area that reports mouse activity to its owner (ScreenObject). */
export class ScreenObject {
  active = true;
  over = false;
  downOn = false;
  constructor(public dir: GameDir, public owner: Reporter, public rect: Rectish, public mouseOver: string | 0 = 0) {}

  checkDown(x: number, y: number) {
    if (!this.active || !inside(x, y, this.rect)) return false;
    this.downOn = true;
    this.owner.report(this, "downOn");
    this.dir.prioObject = this;
    return true;
  }
  checkUp(x: number, y: number) {
    if (!this.active) return false;
    if (this.downOn) {
      this.dir.prioObject = null;
      this.owner.report(this, "stillDown");
      this.downOn = false;
      if (inside(x, y, this.rect)) { this.owner.report(this, "clicked"); return true; }
      this.owner.report(this, "UpOutside");
    }
    return false;
  }
  checkBetween(x: number, y: number) {
    if (!this.active) return false;
    if (this.downOn) this.owner.report(this, "stillDown");
    const was = this.over;
    this.over = inside(x, y, this.rect);
    if (this.over && !was) this.owner.report(this, "over");
    if (!this.over && was) this.owner.report(this, "NotOver");
    return this.over;
  }
  moveBy(dx: number, dy: number) { this.rect = { left: this.rect.left + dx, top: this.rect.top + dy, right: this.rect.right + dx, bottom: this.rect.bottom + dy }; }
}

export interface LoopObject { loop(): void; }

/**
 * gDir – the per-movie "game master" (GeneralAncestor in the original).
 * Owns click areas (screen objects), per-frame loop objects and a sprite name table.
 */
export class GameDir {
  screenObjects: ScreenObject[] = [];
  private prio: number[] = [];
  prioObject: ScreenObject | null = null;
  private loopObjects: LoopObject[] = [];
  private addLoop: LoopObject[] = [];
  private delLoop: LoopObject[] = [];
  mouseButtonActive = true;
  screenClicked = false;
  ending = false;
  gameFrames = 0;
  /** Logical sprite names -> channel numbers. */
  spriteList: Record<string, number> = {};
  private mbDown = false;

  constructor(public movie: Movie) {
    const e: Engine = movie.engine;
    e.mouseDownScript = () => this.virtualMouseDown();
    e.mouseUpScript = () => this.virtualMouseUp();
  }

  sp(name: string) { return this.spriteList[name] ?? 0; }
  sprite(name: string) { return this.movie.sprite(this.sp(name)); }
  /** sendSprite(spriteList.name, msg, ...) */
  send(name: string, msg: string, ...args: unknown[]) { const n = this.sp(name); return n ? this.movie.sprite(n).send(msg, ...args) : undefined; }

  addScreenObject(o: ScreenObject, priority = 100) {
    // keep sorted by priority, stable for equal values
    let i = this.prio.findIndex(p => p > priority); if (i < 0) i = this.prio.length;
    this.screenObjects.splice(i, 0, o); this.prio.splice(i, 0, priority);
  }
  deleteScreenObject(o: ScreenObject) {
    o.active = false;
    const i = this.screenObjects.indexOf(o);
    if (i >= 0) { this.screenObjects.splice(i, 1); this.prio.splice(i, 1); }
  }
  addLoopObject(o: LoopObject) { this.addLoop.push(o); }
  deleteLoopObject(o: LoopObject) { this.delLoop.push(o); }

  /** Called from the movie's frame script every frame (loop(gDir)). */
  loop() {
    const { x, y } = this.movie.engine.mouse;
    if (this.mouseButtonActive) {
      this.prioObject?.checkBetween(x, y);
      for (const o of [...this.screenObjects]) { if (this.ending) break; o.checkBetween(x, y); }
    }
    this.loopObjects = this.loopObjects.filter(o => !this.delLoop.includes(o)).concat(this.addLoop);
    this.addLoop = []; this.delLoop = [];
    for (const o of [...this.loopObjects]) o.loop();
    this.gameFrames++;
  }

  virtualMouseDown() {
    if (!this.mouseButtonActive || this.mbDown) return;
    this.mbDown = true;
    const { x, y } = this.movie.engine.mouse;
    for (const o of [...this.screenObjects]) if (o.checkDown(x, y)) break;
  }
  virtualMouseUp() {
    if (!this.mouseButtonActive || !this.mbDown) return;
    this.mbDown = false;
    const { x, y } = this.movie.engine.mouse;
    let hit = false;
    for (const o of [...this.screenObjects]) if (o.checkUp(x, y)) { hit = true; break; }
    this.screenClicked = hit;
    this.mouseClick(hit);
  }
  /** Override in movie-specific dirs. */
  mouseClick(_onObject: boolean) {}

  /** activate(gDir, state): enable/disable all clickable things. */
  activate(state: boolean) {
    this.movie.sendAll("activateClick", state);
    this.mouseButtonActive = state;
  }

  kill() {
    this.ending = true;
    this.screenObjects = []; this.loopObjects = [];
    const e = this.movie.engine;
    e.mouseDownScript = e.mouseUpScript = null;
  }
}
