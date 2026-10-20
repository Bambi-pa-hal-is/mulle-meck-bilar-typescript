/**
 * Behaviors shared by many movies (from the "00" cast).
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { PropList, Point, Sym, sym, lingoValue, type LValue } from "../engine/lingo.ts";
import type { MemberRef } from "../engine/assets.ts";
import { G, random } from "../game/runtime.ts";

const name = (v: unknown) => v instanceof Sym ? v.name : typeof v === "string" ? v.replace(/^#/, "") : "";
const is = (v: unknown, s: string) => name(v).toLowerCase() === s.toLowerCase();

/**
 * SpriteAnimBH – data driven sprite animation.
 * Animation charts are text members "<Name>AnimChart": [#Actions: [#Talk: [frames...], ...], #Paths: [...]]
 * Frame numbers are offsets from `firstFrame` (the sprite's first member). Supports
 * [#RndHold, frame, min, max], [#RndFrame, [frames]], [#Sound, [names]] entries, lip sync through cue points.
 */
export class SpriteAnimBH extends Behavior {
  type = "SpriteAnim";
  active = true;
  private first: MemberRef | null = null;
  private frameList: number[] = [];
  private soundList: (string | 0)[] = [];
  private counter = 0;
  private actionActive = false;
  private allFrameLists = new PropList();
  private allPaths = new PropList();
  movement = "Still";
  waitState: "move" | "Still" = "move";
  repeatIt = false;
  syncTalk = false;
  waitForWhat = "none";
  doWhat = "gonextframe";
  autoSound = true;
  sndId = 0;
  myChannel = 0;
  private opSndId = 0;
  private myLoc = new Point(0, 0);
  private path: Point[] = [];
  private pathActive = false;
  private pathCounter = 0;

  beginSprite() {
    const p = this.params;
    this.active = p.has("active") ? !!p.get("active") : true;
    this.repeatIt = !!p.get("repeatIt");
    this.syncTalk = !!p.get("syncTalk");
    this.autoSound = p.has("autoSound") ? !!p.get("autoSound") : true;
    // Lingo symbols are case-insensitive: keep these lowercase
    this.waitForWhat = (name(p.get("waitForWhat")) || "none").toLowerCase();
    this.doWhat = (name(p.get("doWhat")) || "GoNextFrame").toLowerCase();
    this.movement = name(p.get("movement")) || "Still";
    if (this.active) this.init();
  }
  endSprite() { if (this.sndId) G.sound.stop(this.sndId); }

  activate(yes: boolean | number) { this.active = !!yes; }

  init() {
    const p = this.params, m = this.movie;
    const obj = name(p.get("object")) || "Standard";
    const chart = obj.toLowerCase() === "custom" ? (p.get<string>("frameListMember") ?? "") : obj;
    this.myLoc = new Point(this.sprite.locH, this.sprite.locV);
    if (is(this.movement, "Custom")) this.movement = name(p.get("customMovement"));
    const ff = p.get<string>("firstFrame");
    this.first = ff ? m.member(ff) : this.sprite.member;
    this.waitState = "move";
    this.setAnimChart(chart);
    // optional movement path
    let toLoc: LValue = p.get("toLoc") ?? "";
    if (typeof toLoc === "string" && toLoc) {
      const v = lingoValue(toLoc);
      if (Array.isArray(v)) toLoc = new Point(v[0] as number, v[1] as number);
      else if (v instanceof Point) toLoc = v;
      else { const [a, b] = toLoc.split(",").map(Number); toLoc = new Point(a, b); }
    }
    this.setAnimPath(p.get<string>("movePathName") ?? "", toLoc instanceof Point ? toLoc : null, Number(p.get("nrOfSteps") ?? 0));
    this.playAnimSound(p.get<string>("soundMember") ?? "");
    this.exitFrame();
  }

  setAnimChart(chartName: string) {
    const chart = lingoValue(this.movie.text(chartName + "AnimChart"));
    if (chart instanceof PropList) {
      // Some charts (StandardAnimChart) are a bare action list
      const acts = chart.get("Actions");
      this.allFrameLists = acts instanceof PropList ? acts : chart;
      const paths = chart.get("Paths"); this.allPaths = paths instanceof PropList ? paths : new PropList();
    }
    this.setAnimAction(this.movement);
    if (this.first && this.frameList.length) this.showFrame(this.frameList[0]);
  }

  private showFrame(f: number) {
    if (!this.first) return;
    this.movie.setMember(this.sprite, this.movie.memberInLib(this.first, this.first.info.num + f - 1));
  }

  playAnimSound(snd: string) {
    G.sound.stop(this.sndId);
    if (snd) { this.sndId = G.sound.play(snd, "EFFECT"); this.myChannel = G.sound.getChannel(this.sndId); }
    else { this.sndId = 0; this.myChannel = 0; }
  }
  makeAnimSpeech(snd: string) { this.repeatIt = true; this.syncTalk = true; this.playAnimSound(snd); this.waitForWhat = "sound"; }
  setAnimNormal() { this.repeatIt = false; this.syncTalk = false; this.waitForWhat = "anim"; this.doWhat = "sendspriteme"; }
  getAnimAction() { return this.movement; }
  getAnimWaitState() { return this.waitState; }

  setAnimAction(move: string | Sym) {
    move = name(move);
    if (is(move, "Still")) this.playAnimSound("");
    this.movement = move;
    let list: LValue[] = [];
    if (is(move, "Wait")) {
      const options = this.allFrameLists.get<LValue[]>("Wait") ?? [];
      if (this.waitState === "move") { list = [options[0]]; this.waitState = "Still"; }
      else {
        const choice = options[random(options.length - 1)];
        list = this.allFrameLists.get<LValue[]>(name(choice)) ?? [];
        this.waitState = "move";
      }
    } else list = this.allFrameLists.get<LValue[]>(move) ?? [];
    this.frameList = []; this.soundList = [];
    for (const e of list) {
      if (Array.isArray(e)) {
        const kind = name(e[0]).toLowerCase();
        if (kind === "rndhold") {
          const n = (e[2] as number) + random((e[3] as number) - (e[2] as number));
          for (let i = 0; i < n; i++) { this.frameList.push(e[1] as number); this.soundList.push(0); }
        } else if (kind === "rndframe") {
          const opts = e[1] as number[]; this.frameList.push(opts[random(opts.length) - 1]); this.soundList.push(0);
        } else if (kind === "sound") {
          // attaches to the previous/next frame slot like the original (sound list only)
          const opts = e[1] as LValue[]; const s = opts[random(opts.length) - 1];
          this.soundList.push(typeof s === "string" ? s : 0);
        }
      } else if (typeof e === "number") { this.frameList.push(e); this.soundList.push(0); }
      else if (e instanceof Sym) { /* nested action name inside #Wait handled above */ }
    }
    if (this.waitForWhat === "anim" && this.doWhat !== "sendspriteme" && !is(this.movement, "Wait")) { this.frameList.push(1); this.soundList.push(0); }
    this.counter = 0;
    this.actionActive = this.frameList.length > 0;
  }

  setAnimPath(pathName: string, toLoc: Point | null, steps: number) {
    this.pathActive = false; this.pathCounter = 0; this.path = [];
    const rel = this.params.has("pathRelative") ? !!this.params.get("pathRelative") : true;
    if (pathName) {
      const p = this.allPaths.get<Point[]>(pathName) ?? [];
      this.path = p.map(pt => rel ? new Point(pt.x + this.myLoc.x, pt.y + this.myLoc.y) : pt.clone());
      this.pathActive = this.path.length > 0;
    } else if (toLoc) {
      const n = steps || 1;
      const dx = rel ? toLoc.x : toLoc.x - this.myLoc.x, dy = rel ? toLoc.y : toLoc.y - this.myLoc.y;
      for (let i = 1; i <= n; i++) this.path.push(new Point(this.myLoc.x + Math.trunc(dx / n) * i, this.myLoc.y + Math.trunc(dy / n) * i));
      this.pathActive = true;
    }
  }

  setAnimLoc(loc: Point, relative: boolean | number) {
    if (relative) this.myLoc = new Point(this.myLoc.x + loc.x, this.myLoc.y + loc.y);
    else this.myLoc = new Point(loc.x === -4711 ? this.myLoc.x : loc.x, loc.y === -4711 ? this.myLoc.y : loc.y);
  }
  /** Buffa's "SetLoc" message is the same as setAnimLoc with absolute coordinates. */
  SetLoc(loc: Point, relative: boolean | number) { this.setAnimLoc(loc, relative); }

  spritecuePassed(channel: number, _nr: number, cueName: string) {
    if (!this.syncTalk || channel !== this.myChannel || G.sound.finished(this.sndId)) return;
    if (/^talk$/i.test(cueName)) this.setAnimAction("Talk");
    else if (/^silence$/i.test(cueName)) { this.waitState = "move"; this.setAnimAction("Wait"); }
  }

  exitFrame() {
    if (!this.active) return;
    if (this.pathActive) {
      this.pathCounter++;
      this.myLoc = this.path[this.pathCounter - 1] ?? this.myLoc;
      if (this.pathCounter >= this.path.length) {
        this.pathActive = false;
        if (this.waitForWhat === "path") { this.doTheWhat(); return; }
      }
    }
    this.sprite.setLoc(this.myLoc.x, this.myLoc.y);
    if (this.actionActive) {
      this.counter++;
      if (this.autoSound) {
        const s = this.soundList[this.counter - 1];
        if (typeof s === "string") { G.sound.stop(this.opSndId); this.opSndId = G.sound.play(s, "OPEFFECT"); }
      }
      this.showFrame(this.frameList[this.counter - 1]);
      if (this.counter >= this.frameList.length) {
        if (this.repeatIt || is(this.movement, "Wait")) this.setAnimAction(this.movement);
        else if (is(this.movement, "Still")) this.counter = 0;
        else { this.actionActive = false; if (this.waitForWhat === "anim") this.doTheWhat(); }
      }
    }
    if (this.sndId && this.waitForWhat === "sound" && G.sound.finished(this.sndId)) this.doTheWhat();
  }

  private doTheWhat() {
    switch (this.doWhat.toLowerCase()) {
      case "gonextframe": this.movie.goFrame(this.movie.frame + 1); break;
      case "gonextmarker": this.movie.goNextMarker(); break;
      case "sendspriteme": this.sprite.send("Stopped"); break;
    }
  }
}

/** ASoundBH – plays a sound while the sprite exists, optionally advancing when done. */
export class ASoundBH extends Behavior {
  sndId = 0;
  beginSprite() { this.sndId = G.sound.play(this.p("name", ""), (name(this.p("prio")) || "EFFECT").toUpperCase() as any); }
  endSprite() { G.sound.stop(this.sndId); }
  exitFrame() {
    const w = name(this.p("WaitForSound")).toLowerCase();
    if (w && w !== "none" && G.sound.finished(this.sndId)) {
      if (w === "gonextframe") this.movie.goFrame(this.movie.frame + 1);
      else if (w === "gonextmarker") this.movie.goNextMarker();
    }
  }
}

/** CursorSpriteBH – sprite 115 follows the mouse and swaps cursor graphics. */
export class CursorSpriteBH extends Behavior {
  beginSprite() { this.movie.engine.cursorSprite = this.spriteNum; this.C_Standard(); }
  exitFrame() { const m = this.movie.mouse; this.sprite.setLoc(m.x | 0, m.y | 0); }
  private set(n: string) { this.movie.setMemberByName(this.sprite, n); }
  C_Standard() { this.set("C_Standard"); }
  c_grab() { this.set("C_Grab"); }
  c_Left() { this.set("C_Left"); }
  c_MoveLeft() { this.set("C_MoveLeft"); }
  c_click() { this.set("C_Click"); }
  c_MoveIn() { this.set("C_MoveIn"); }
  C_Right() { this.set("C_Right"); }
  c_MoveRight() { this.set("C_MoveRight"); }
  C_Back() { this.set("C_Back"); }
}

/** Send a cursor message to the cursor sprite. */
export function setCursor(msg: string) { G.engine.movie?.sprite(G.engine.cursorSprite).send(msg); }

/** CursorBH – changes the cursor while the mouse is over this sprite. */
export class CursorBH extends Behavior {
  active = true;
  activate(s: boolean) { this.active = !!s; }
  activateClick(s: boolean) { this.active = !!s; }
  private dragging() {
    const d = G.dir?.sp("drag");
    return d ? !!this.movie.sprite(d).send("isDragging") : false;
  }
  mouseEnter() {
    if (!this.active) return;
    const kind = name(this.p("whichCustomCursor")).toLowerCase() || "standard";
    const down = this.movie.engine.mouse.down, drag = down && this.dragging();
    const map: Record<string, string> = {
      left: drag ? "c_MoveLeft" : "c_Left", right: drag ? "c_MoveRight" : "C_Right", click: drag ? "c_MoveIn" : "c_click",
      grab: "c_grab", back: "C_Back", standard: "C_Standard",
    };
    setCursor(map[kind] ?? "C_Standard");
  }
  mouseLeave() { setCursor(this.movie.engine.mouse.down && this.dragging() ? "c_grab" : "C_Standard"); }
}

/** "Go to Marker" library behavior. */
export class GoToMarker extends Behavior {
  mouseUp() { const m = this.p<string>("marker", ""); if (m) this.movie.goFrame(m); }
}

/**
 * BuffaBH (00 cast) – the dog wandering between borders, talking, lying down.
 * Frozen (static pose) when the game runs in low-memory "load" mode.
 */
export class BuffaBH extends Behavior {
  mode = "Wait"; frozen = false;
  leftBorder = 350; rightBorder = 550;
  beginSprite() {
    this.sprite.send("setAnimNormal");
    this.frozen = !!(G.dir as any)?.goToLoad;
    this.sprite.send("setAnimChart", this.frozen ? "BuffaFreeze" : "Buffa");
  }
  private act(m: string) { this.mode = m; this.sprite.send("setAnimAction", m); }
  exitFrame() { if (!this.frozen && this.mode === "Wait" && random(100) === 1) this.randomMove(4); }
  changePile(dir: number) {
    if (this.frozen) return;
    if (dir === -1) { this.sprite.send("setAnimLoc", new Point(640 - 140, -4711), 0); this.act("WalkLeftStart"); }
    else if (dir === 1) { this.sprite.send("setAnimLoc", new Point(140, -4711), 0); this.act("WalkRightStart"); }
  }
  randomMove(max: number) {
    for (let tries = 0; tries < 50; tries++) {
      const r = random(max);
      if (r === 1 && this.sprite.locH < this.rightBorder) return this.act("WalkRightStart");
      if (r === 2 && this.sprite.locH > this.leftBorder) { this.sprite.send("setAnimLoc", new Point(-330, 0), 1); return this.act("WalkLeftStart"); }
      if (r === 3) return this.act("Talk");
      if (r === 4) return this.act("GetDown");
    }
  }
  mouseUp() {
    if (this.frozen) return;
    if (this.mode === "Wait") this.randomMove(3);
    else if (this.mode === "Sleep") this.act("GetUp");
  }
  Stopped() {
    const L = this.sprite.locH;
    const next: Record<string, () => string> = {
      WalkRightStart: () => "WalkRight",
      WalkRight: () => random(2) > 1 || L >= this.rightBorder ? "WalkRightStop" : (this.sprite.send("setAnimLoc", new Point(80, 0), 1), "WalkRight"),
      WalkRightStop: () => { this.sprite.send("setAnimLoc", new Point(200, 0), 1); return "Wait"; },
      WalkLeftStart: () => "WalkLeft",
      WalkLeft: () => random(2) > 1 || L <= this.leftBorder ? "WalkLeftStop" : (this.sprite.send("setAnimLoc", new Point(-80, 0), 1), "WalkLeft"),
      WalkLeftStop: () => { this.sprite.send("setAnimLoc", new Point(140, 0), 1); return "Wait"; },
      GetDown: () => "Sleep",
      Sleep: () => random(30) === 1 ? "GetUp" : "Sleep",
    };
    this.act(next[this.mode]?.() ?? "Wait");
  }
}

/** ToolBoxBH – the toolbox in the bottom-right corner; slides out on hover, opens the menu dialog. */
export class ToolBoxBH extends Behavior {
  activeClick = true; mode: "in" | "Out" = "in"; counter = 0; checkForLeave = false;
  private startLocH = 0; private readonly max = 4; private readonly step = 11;
  private readonly trackRect = { left: 560, top: 400, right: 800, bottom: 650 };
  beginSprite() { this.startLocH = this.sprite.locH; }
  activateClick(s: boolean | number) { this.activeClick = !!s; }
  exitFrame() {
    const { x, y } = this.movie.engine.mouse;
    if (this.checkForLeave && !(x >= this.trackRect.left && x < this.trackRect.right && y >= this.trackRect.top && y < this.trackRect.bottom)) this.leave();
    if (this.counter) {
      this.counter--;
      this.sprite.locH = this.mode === "in" ? this.startLocH - this.counter * this.step : this.startLocH - (this.max - this.counter) * this.step;
      this.sprite.puppet = true;
    }
  }
  mouseEnter() {
    if (this.activeClick) {
      this.checkForLeave = true;
      if (this.mode === "in") { if (this.counter < 4) G.sound.play("00e040v0", "OPEFFECT"); this.mode = "Out"; this.counter = this.max - this.counter; }
    } else if (this.mode === "Out") { this.mode = "in"; this.counter = this.max - this.counter; }
  }
  private leave() { this.checkForLeave = false; if (this.mode === "Out") { this.mode = "in"; this.counter = this.max - this.counter; } }
  mouseUp() {
    if (!this.activeClick) return;
    if (this.movie.id === "02") G.dir?.send("drag", "forceLetGo");
    this.counter = 0; this.mode = "Out";
    this.sprite.locH = this.startLocH - this.max * this.step; this.sprite.puppet = true;
    G.dir?.send("fDialog", "functionDialogSwitch");
  }
}

/**
 * FDialogBH – the toolbox menu: 1 new car (scrap the current one), 2 diploma, 3 quit, 4 close.
 */
export class FDialogBH extends Behavior {
  active = false; cursorNumber = 0; private hoverSince = 0; private soundId = 0;
  private readonly rects = [
    { left: 161, top: 129, right: 247, bottom: 263 }, { left: 279, top: 136, right: 340, bottom: 263 },
    { left: 371, top: 135, right: 443, bottom: 263 }, { left: 465, top: 204, right: 521, bottom: 310 },
  ];
  private readonly sounds = ["09d001v0", "09d002v0", "09d003v0", "09d004v0"];
  functionDialogSwitch() { if (this.active) this.closeMeDown(); else this.startMeUp(); }
  startMeUp() {
    this.movie.setMemberByName(this.sprite, this.p("myCastMember", "09b001v0")); this.sprite.puppet = true;
    this.sprite.setLoc(320, 240);
    G.dir?.activate(false);
    this.active = true; this.cursorNumber = 0;
  }
  closeMeDown() {
    this.movie.setMemberByName(this.sprite, "Dummy");
    G.dir?.activate(true);
    this.active = false; this.cursorNumber = 0;
    G.sound.stop(this.soundId);
  }
  exitFrame() {
    if (!this.active) return;
    const { x, y } = this.movie.engine.mouse;
    const i = this.rects.findIndex(r => x >= r.left && x < r.right && y >= r.top && y < r.bottom) + 1;
    if (i !== this.cursorNumber) {
      this.cursorNumber = i; this.hoverSince = 0;
      G.sound.stop(this.soundId);
      setCursor(i ? "c_click" : "C_Standard");
    } else if (i && ++this.hoverSince === 10) this.soundId = G.sound.play(this.sounds[i - 1], "EFFECT");
  }
  mouseUp() {
    if (!this.active || !this.cursorNumber) return;
    G.sound.stop(this.soundId);
    G.sound.play("SndMouseClick", "EFFECT");
    const here = this.movie.id;
    switch (this.cursorNumber) {
      case 1: newCar(this); break;
      case 2: G.mulle.whereFrom = here; this.movie.goFrame("08"); break;
      case 3: this.movie.goFrame("12"); break;
      case 4: this.functionDialogSwitch(); break;
    }
  }
}

/** Scrap the current car; the first three cars start with a few parts already mounted. */
function newCar(dlg: FDialogBH) {
  const g = G.mulle, u = g.user!, m = dlg.movie;
  u.trashCar();
  const start = [[82, 133, 152], [82, 152], [82]][u.nrOfBuiltCars] ?? [];
  for (const id of start) { u.car.addPart(id); u.removeJunkPart(0, id); }
  g.save();
  if (m.id === "03") {
    G.dir?.send("JunkStart", "drawJunk");
    G.dir?.send("CarStart", "drawCar");
    G.dir?.send("Mulle", "MakeMulleSpeak", ["afterTrash0", "AfterTrash1", "AfterTrash2", "AfterTrash3"][start.length]);
    dlg.functionDialogSwitch();
  } else {
    g.whereFrom = m.id;
    dlg.functionDialogSwitch();
    void G.engine.goMovie("03", 1);
  }
}

export function registerCommon() {
  registerBehavior("ToolBoxBH", ToolBoxBH);
  registerBehavior("FDialogBH", FDialogBH);
  registerBehavior("BuffaBH", BuffaBH);
  registerBehavior("SpriteAnimBH", SpriteAnimBH);
  registerBehavior("ASoundBH", ASoundBH);
  registerBehavior("CursorSpriteBH", CursorSpriteBH);
  registerBehavior("CursorBH", CursorBH);
  registerBehavior("Go to Marker", GoToMarker);
}

export { sym };
