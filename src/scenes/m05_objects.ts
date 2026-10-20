/**
 * Objects on the driving maps (object<N>DB): destinations and the custom objects
 * (cows, goats, ferry, petrol station, racing track, bridges, hills, stops, sounds, teleports ...).
 */
import { PropList, Point, Sym, type LValue } from "../engine/lingo.ts";
import type { Sprite } from "../engine/sprite.ts";
import { G, random } from "../game/runtime.ts";
import { calcDirection, DEC } from "../game/cardriving.ts";
import type { ObjectData } from "../game/world.ts";
import type { DriveDir } from "./m05_driving.ts";

const S = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
const hypot = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.y - b.y);
type RadiusEvent = "EnterInnerRadius" | "ExitInnerRadius" | "enterOuterRadius" | "ExitOuterRadius" | "EnterBoth" | "ExitBoth" | 0;

/** One placed object instance on the current map. */
export class WorldObject {
  canEnter = true;
  inner: number; outer: number;
  frameList: string[] | PropList | null = null;
  insideInner = false; insideOuter = false;
  handler!: ObjectHandler;
  constructor(public d: DriveDir, public data: ObjectData, public loc: Point, public optional: PropList, public spOver: number, public spUnder: number) {
    this.inner = data.inner; this.outer = data.outer;
  }
  get id() { return this.data.id; }
  get sounds() { return this.data.sounds; }
  sprite(which: "Under" | "Over" = "Under", n = 0): Sprite { return this.d.movie.sprite((which === "Under" ? this.spUnder : this.spOver) + n); }
  frames(kind: string): string[] { const f = this.data.frameList.get<LValue>(kind); return Array.isArray(f) ? f as string[] : []; }
  setWhenDone(k: string) { return this.data.setWhenDone.get<LValue>(k); }

  /** Object.init: apply direction variant, hide/lock when already done, set radii; false = don't show. */
  init(carLoc: Point): boolean {
    const dirIdx = this.optional.get<number>("direction") ?? 1;
    const byDir = this.data.frameList.get<LValue>(dirIdx);
    if (byDir instanceof PropList) this.data = { ...this.data, frameList: byDir };
    if (this.data.ifFound && this.data.ifFound.toLowerCase() !== "none" && this.alreadyDone()) {
      if (this.data.ifFound.toLowerCase() === "nodisplay") return false;
      if (this.data.ifFound.toLowerCase() === "noenter") this.canEnter = false;
    }
    if (typeof this.optional.get("InnerRadius") === "number") this.inner = this.optional.get("InnerRadius");
    if (typeof this.optional.get("OuterRadius") === "number") this.outer = this.optional.get("OuterRadius");
    this.handler.init(carLoc);
    return true;
  }

  private alreadyDone(): boolean {
    const u = G.mulle.user!, car = u.car;
    for (const [k, raw] of this.data.checkFor.entries) {
      const vals = Array.isArray(raw) ? raw : [raw];
      switch (S(k).toLowerCase()) {
        case "cache": if (vals.some(v => !(car.getCacheProp(S(v)) instanceof Sym))) return true; break;
        case "medals": if (vals.some(v => car.hasMedal(v as number))) return true; break;
        case "userstuff": if (vals.some(v => !(u.getUserProp(S(v)) instanceof Sym))) return true; break;
        case "missions": if (vals.some(v => u.isMissionCompleted(v as number))) return true; break;
        case "parts": if (!this.getOnePart("checkFor")) return true; break;
      }
    }
    return false;
  }

  /** A part this destination can still give (from #Destinations, or a random one). */
  getOnePart(where: "setWhenDone" | "checkFor"): number {
    const raw = (where === "setWhenDone" ? this.data.setWhenDone : this.data.checkFor).get<LValue>("Parts");
    let vals = Array.isArray(raw) ? [...raw] : raw === undefined ? [] : [raw];
    const wantRandom = vals.some(v => S(v).toLowerCase() === "random");
    vals = vals.filter(v => typeof v === "number");
    const avail = G.mulle.getCurrentlyAvailable("Destinations");
    for (const v of vals) if (avail.includes(v as number)) return v as number;
    if (wantRandom) { const r = G.mulle.getCurrentlyAvailable("Random"); if (r.length) return r[0]; }
    return 0;
  }

  /** Track entering/leaving the inner and outer radius (DrivingHandlers.checkRadius). */
  checkRadius(car: Point, option: "both" | "Inner" | "Outer" = "both", at = this.loc): RadiusEvent {
    const h = hypot(car, at);
    if (option === "both") {
      if (h <= this.outer) {
        if (h <= this.inner) {
          if (!this.insideInner) { this.insideInner = true; if (this.insideOuter) return "EnterInnerRadius"; this.insideOuter = true; return "EnterBoth"; }
        } else {
          if (!this.insideOuter) { this.insideOuter = true; return "enterOuterRadius"; }
          if (this.insideInner) { this.insideInner = false; return "ExitInnerRadius"; }
        }
      } else if (this.insideOuter) {
        this.insideOuter = false;
        if (this.insideInner) { this.insideInner = false; return "ExitBoth"; }
        return "ExitOuterRadius";
      }
    } else if (option === "Inner") {
      if (h <= this.inner) { if (!this.insideInner) { this.insideInner = true; return "EnterInnerRadius"; } }
      else if (this.insideInner) { this.insideInner = false; return "ExitInnerRadius"; }
    } else {
      if (h <= this.outer) { if (!this.insideOuter) { this.insideOuter = true; return "enterOuterRadius"; } }
      else if (this.insideOuter) { this.insideOuter = false; return "ExitOuterRadius"; }
    }
    return 0;
  }

  /** Dispatch a radius event to the handler's enter/exit methods. */
  dispatch(ev: RadiusEvent) {
    const h = this.handler as any;
    switch (ev) {
      case "EnterBoth": h.enterOuter?.(); h.enterInner?.(); break;
      case "ExitBoth": h.exitInner?.(); h.exitOuter?.(); break;
      case "EnterInnerRadius": h.enterInner?.(); break;
      case "ExitInnerRadius": h.exitInner?.(); break;
      case "enterOuterRadius": h.enterOuter?.(); break;
      case "ExitOuterRadius": h.exitOuter?.(); break;
    }
  }
}

export abstract class ObjectHandler {
  constructor(public o: WorldObject) {}
  get d() { return this.o.d; }
  get car() { return this.o.d.car!; }
  abstract init(carLoc: Point): void;
  abstract step(carLoc: Point): void;
  protected show(frame: string, which: "Under" | "Over" = "Under", loc = this.o.loc) {
    const s = this.o.sprite(which); this.d.movie.setMemberByName(s, frame); s.setLoc(loc.x, loc.y); s.puppet = true;
  }
}

// ------------------------------------------------------------------ destinations
/** Destination: drive into its inner circle to visit the place (leaves to movie DirResource). */
class Destination extends ObjectHandler {
  sndId = 0; counter = 0; frames: string[] = []; readyToGo = true; externalSoundFinished = false;
  init(carLoc: Point) {
    const h = hypot(carLoc, this.o.loc);
    if (h <= this.o.outer) { this.o.insideOuter = true; this.readyToGo = false; }
    if (h <= this.o.inner) this.o.insideInner = true;
    this.frames = this.o.frames("normal"); this.counter = 0;
    if (this.frames.length) this.show(this.frames[0]);
  }
  step(carLoc: Point) {
    this.o.dispatch(this.o.checkRadius(carLoc));
    if (this.externalSoundFinished) {
      if (this.readyToGo && this.o.insideInner && this.o.canEnter && G.sound.finished(this.sndId)) {
        G.mulle.world!.enteredObjectId = this.o.id;
        this.d.prepareToLeave(this.o.data.dirResource);
        return;
      }
    } else if (this.readyToGo && this.o.insideOuter) {
      this.externalSoundFinished = this.d.medalSoundFinished();
      if (this.externalSoundFinished) this.playSound();
    }
    if (!this.frames.length) return;
    this.counter++;
    this.show(this.frames[this.counter - 1] ?? this.frames[0]);
    if (this.counter >= this.frames.length) this.counter = 0;
  }
  enterOuter() {
    const outer = this.o.frames("Outer");
    if (outer.length) { this.frames = outer; this.counter = 0; }
    this.externalSoundFinished = this.d.medalSoundFinished();
    if (this.externalSoundFinished) this.playSound();
  }
  private playSound() {
    const s = this.o.sounds;
    const snd = this.o.canEnter ? s[0] : s[1];
    if (snd && G.sound.finished(this.sndId)) this.sndId = G.sound.play(snd, "EFFECT");
  }
  exitOuter() { this.frames = this.o.frames("normal"); this.counter = 0; this.readyToGo = true; }
  enterInner() {
    if (!this.readyToGo || !this.o.canEnter) return;
    this.car.programControl(true);
    G.mulle.user!.setUserProp("Visited" + this.o.data.dirResource);
    this.car.setSpeed(0); this.car.steer(0);
  }
}

/** Cows / goats on the road: honk to make them part (goats need the right horn). */
class Herd extends ObjectHandler {
  allowed = false; frames: string[] = []; counter = 0; mode = ""; sndId = 0; opSndId = 0;
  constructor(o: WorldObject, private goats: boolean) { super(o); }
  init() {
    const horn = G.mulle.user!.car.prop("HornType");
    this.allowed = this.goats ? horn === 5 : horn !== 0;
    this.setFrames("normal");
  }
  private setFrames(mode: string) {
    this.mode = mode; this.frames = this.o.frames(mode); this.counter = 1;
    if (this.frames.length) this.show(this.frames[0]);
  }
  step(carLoc: Point) {
    this.counter++;
    if (this.counter > this.frames.length) {
      if (this.mode === "Parting") this.setFrames("Outer");
      else if (this.mode === "Gathering") this.setFrames("normal");
      else this.counter = 1;
    }
    if (this.frames.length) this.show(this.frames[this.counter - 1]);
    this.o.dispatch(this.o.checkRadius(carLoc));
  }
  enterOuter() { this.opSndId = G.sound.play(this.o.sounds[1], "OPEFFECT"); }
  exitOuter() { G.sound.stop(this.opSndId); }
  enterInner() {
    if (this.allowed) { this.setFrames("Parting"); this.sndId = G.sound.play(this.car.hornSound, "EFFECT"); return; }
    if (this.goats) this.d.stopSound();
    if (G.sound.finished(this.sndId)) this.sndId = G.sound.play(this.o.sounds[0], "EFFECT");
    this.car.setSpeed(0); this.car.stepback(2);
    this.o.insideInner = false;
  }
  exitInner() { if (this.allowed) this.setFrames("Gathering"); }
}

/** Petrol station: stop, fill up. */
class Gas extends ObjectHandler {
  sndId = 0; ok = false;
  init() { this.ok = this.car.q.FuelConsumption > 0 || this.car.gotElectricEngine; }
  step(carLoc: Point) {
    if (this.sndId) { if (G.sound.finished(this.sndId)) { this.sndId = 0; this.car.programControl(false); } return; }
    const inside = hypot(carLoc, this.o.loc) < this.o.inner;
    if (inside && !this.o.insideInner) {
      if (this.ok) {
        this.sndId = G.sound.play(this.o.sounds[0], "OPEFFECT");
        this.car.setSpeed(0); this.car.steer(0); this.car.programControl(true);
        this.d.fillErUp();
      }
      this.o.insideInner = true;
    } else if (!inside) this.o.insideInner = false;
  }
}

/** Hill: needs a strong engine; the big hill gives a medal. */
class Hill extends ObjectHandler {
  ok = false; type = "SmallHill"; sndId = 0;
  init() {
    this.type = S(this.o.optional.get("hillType")).toLowerCase() === "bighill" ? "BigHill" : "SmallHill";
    this.ok = (this.car.criteria as any)[this.type] === 1;
  }
  step(carLoc: Point) { this.o.dispatch(this.o.checkRadius(carLoc)); }
  enterOuter() { this.car.saveData(1); }
  exitOuter() { this.car.saveData("none"); }
  enterInner() {
    if (!this.ok) {
      if (G.sound.finished(this.sndId)) this.sndId = G.sound.play(this.o.sounds[this.type === "BigHill" ? 0 : 1], "EFFECT");
      this.car.restoreData(); this.car.setSpeed(0);
    } else if (this.type === "BigHill") this.d.giveMedal(1);
  }
}

/** Invisible stop: the car can't pass. */
class Stop extends ObjectHandler {
  init() { const f = this.o.data.frameList.values()[0]; if (typeof f === "string") this.show(f); }
  step(carLoc: Point) { if (this.o.checkRadius(carLoc, "Inner") === "EnterInnerRadius") { this.car.setSpeed(0); this.car.stepback(2); } }
}

/** Plays a sound once when driven over. */
class SoundSpot extends ObjectHandler {
  snd = ""; done = false;
  init() { this.snd = this.o.optional.get<string>("sound") ?? ""; }
  step(carLoc: Point) {
    if (this.o.checkRadius(carLoc, "Inner") === "EnterInnerRadius" && !this.done) { this.done = true; G.sound.play(this.snd, "EFFECT"); }
  }
}

/** Teleport at a map edge (leads into another world/map). */
class Teleport extends ObjectHandler {
  toMap: Point | null = null; toLoc: Point | null = null; toWorld = ""; vertical = false; downRight = false; border = 0;
  init() {
    const o = this.o.optional, x = 25;
    this.toLoc = o.get("toLoc") ?? null; this.toMap = o.get("toMap") ?? null; this.toWorld = o.get("toWorld") ?? "";
    const b = o.get<number>("whichBorder");
    if (b === 3) { this.vertical = false; this.downRight = false; this.border = 4 + x; }
    else if (b === 1) { this.vertical = false; this.downRight = true; this.border = 636 - x; }
    else if (b === 4) { this.vertical = true; this.downRight = false; this.border = 4 + x; }
    else if (b === 2) { this.vertical = true; this.downRight = true; this.border = 400 - x; }
  }
  step(carLoc: Point) {
    this.o.checkRadius(carLoc, "Inner");
    if (!this.o.insideInner || !this.toMap || !this.toLoc) return;
    const v = this.vertical ? carLoc.y : carLoc.x;
    if (this.downRight ? v > this.border : v < this.border) this.d.teleport(this.toWorld, this.toMap, this.toLoc);
  }
}

/** Animated picture (decoration). */
class Picture extends ObjectHandler {
  frames: string[] = []; counter = 1; which: "Over" | "Under" = "Over";
  init() {
    const f = this.o.optional.get<LValue>("FrameList");
    this.frames = Array.isArray(f) ? f as string[] : this.o.frames("normal");
    this.which = this.o.spOver ? "Over" : "Under";
    this.step();
  }
  step() {
    if (!this.frames.length) return;
    this.show(this.frames[this.counter - 1], this.which);
    if (++this.counter > this.frames.length) this.counter = 1;
  }
}

/** "Far away" spot: reaching it gives a medal. */
class FarAway extends ObjectHandler {
  enterOK = true;
  init() {}
  step(carLoc: Point) {
    if (this.enterOK && this.o.checkRadius(carLoc, "Outer") === "enterOuterRadius") {
      this.enterOK = false;
      const m = this.o.setWhenDone("Medals"); this.d.giveMedal(Array.isArray(m) ? m[0] as number : 2);
    }
  }
}

/** Correct: marks a spot where the car is put back after a map change (handled by the dir). */
class Correct extends ObjectHandler { init() {} step() {} }

/** Swing bridge: opens and closes; the car must wait. */
class CBridge extends ObjectHandler {
  frames: string[] = []; counter = 1; opening = 1; wait = 0;
  init() { this.frames = this.o.frames("normal"); if (this.frames.length) this.show(this.frames[0]); }
  step(carLoc: Point) {
    if (this.o.insideInner && !(this.wait && this.opening === 1)) { this.car.restoreData(); this.car.setSpeed(0); }
    if (this.wait) this.wait--;
    else {
      this.counter += this.opening;
      if (this.counter === 0) {
        if (this.o.insideOuter) G.sound.play(this.o.sounds[0], "OPEFFECT");
        this.wait = 17; this.counter = 1; this.opening = 1;
      } else if (this.counter === this.frames.length) { this.wait = 10; this.opening = -1; }
      if (this.frames.length) this.show(this.frames[this.counter - 1]);
    }
    this.o.dispatch(this.o.checkRadius(carLoc));
  }
  enterInner() { this.car.saveData(1); }
  exitInner() { this.car.saveData("none"); }
}

/** Wooden bridge: too heavy a car falls through (splash), light cars earn a medal. */
class WBridge extends ObjectHandler {
  canDoIt = false; exists = true; frames: string[] = []; counter = 0; sndId = 0; wasSoundOn = true;
  init() {
    this.canDoIt = G.mulle.user!.car.prop("Weight") < 20;
    this.frames = this.o.frames("normal"); this.counter = 0;
    if (this.frames.length) this.show(this.frames[0]);
  }
  step(carLoc: Point) {
    this.counter++;
    if (this.o.insideInner && !this.canDoIt) {
      if (this.counter === 9) this.d.showCar(false);
      else if (this.counter > this.frames.length) {
        G.sound.play(this.o.sounds[1], "EFFECT");
        this.car.restoreData();
        carLoc = this.car.getShowCoordinate();
        this.frames = this.o.frames("Gone"); this.counter = 1;
        if (this.wasSoundOn) this.d.setEngineSound(true);
      }
    } else if (this.counter > this.frames.length) this.counter = 1;
    if (this.frames.length) this.show(this.frames[Math.max(0, this.counter - 1)] ?? this.frames[0]);
    this.o.dispatch(this.o.checkRadius(carLoc));
  }
  enterOuter() { this.car.saveData(1); if (!this.exists) { this.car.setSpeed(0); this.car.restoreData(); } }
  exitOuter() { this.car.saveData("none"); }
  enterInner() {
    if (this.canDoIt) { this.d.giveMedal(6); return; }
    this.exists = false;
    this.car.programControl(true);
    this.sndId = G.sound.play(this.o.sounds[0], "EFFECT");
    this.car.setSpeed(0);
    // the splash animation shows each frame several times
    const splash = this.o.frames("Splash"), doubled: string[] = [];
    splash.forEach((f, i) => { doubled.push(f); if (i % 2 === 0) for (let k = 0; k < 6; k++) doubled.push(f); });
    this.frames = doubled; this.counter = 1;
    this.wasSoundOn = this.d.engineSoundOn();
    this.d.setEngineSound(false);
  }
  exitInner() { this.car.programControl(false); this.d.showCar(true); }
}

/** Ferry: shuttles across the water; with a ticket the car can drive aboard. */
class Ferry extends ObjectHandler {
  counter = 0; back = -1; wait = 0; carOnBoard = false; carLeaving = 0; carCounter = 0;
  ends: Point[] = []; dirs: number[] = []; myLoc = new Point(0, 0); stepV = new Point(0, 0); max = 0;
  endLoc = new Point(0, 0); atStart = 1; carOrg = new Point(0, 0); carStep = new Point(0, 0);
  active = false; carWasntOnBoard = true; sndId = 0;
  init() {
    const f = this.o.frames("normal"); if (f.length) this.show(f[0]);
    const end = this.o.optional.get<Point>("endLoc") ?? new Point(0, 0);
    this.ends = [this.o.loc, end];
    this.dirs = [calcDirection(this.ends[0], this.ends[1])[0], calcDirection(this.ends[1], this.ends[0])[0]];
    const diff = new Point(end.x - this.o.loc.x, end.y - this.o.loc.y);
    const fact = Math.hypot(diff.x, diff.y) / 5;
    this.stepV = new Point(Math.round((DEC * diff.x) / fact), Math.round((DEC * diff.y) / fact));
    this.max = Math.round(fact);
    this.counter = random(this.max - 2) + 1;
    this.back = random(2) === 1 ? -1 : 1;
    this.myLoc = new Point(this.o.loc.x * DEC + this.counter * this.stepV.x, this.o.loc.y * DEC + this.counter * this.stepV.y);
    this.place();
    if (this.back === 1) { this.atStart = -1; this.endLoc = this.ends[1]; } else { this.atStart = 1; this.endLoc = this.ends[0]; }
    const ticket = this.o.data.checkFor.get<LValue[]>("UserStuff")?.[0];
    this.active = !(G.mulle.user!.getUserProp(S(ticket)) instanceof Sym);
  }
  private place() { this.show(this.o.sprite().member?.info.name ?? "", "Under", new Point(Math.trunc(this.myLoc.x / DEC), Math.trunc(this.myLoc.y / DEC))); }
  private carClose(carLoc: Point) {
    const h = hypot(carLoc, new Point(this.myLoc.x / DEC, this.myLoc.y / DEC));
    if (this.active) return h < this.o.inner;
    if (G.sound.finished(this.sndId) && h < this.o.inner) this.sndId = G.sound.play(this.o.sounds[0], "EFFECT");
    return false;
  }
  private boardInit(leave: number) {
    if (!this.active) return;
    this.carLeaving = leave;
    this.carOrg = this.car.getCoordinate();
    if (leave === -1) {
      this.carWasntOnBoard = false; this.carOnBoard = true;
      this.car.setDirection(calcDirection(this.carOrg, this.endLoc)[0]);
      this.carStep = new Point(Math.trunc(((this.endLoc.x - this.carOrg.x) * DEC) / 10), Math.trunc(((this.endLoc.y - this.carOrg.y) * DEC) / 10));
    } else this.carStep = new Point(Math.trunc(-this.stepV.x / 2) * this.atStart, Math.trunc(-this.stepV.y / 2) * this.atStart);
  }
  private boarding() {
    if (!this.carLeaving) return;
    this.carCounter++;
    this.car.setCoordinate(new Point(this.carOrg.x + Math.trunc((this.carStep.x * this.carCounter) / DEC), this.carOrg.y + Math.trunc((this.carStep.y * this.carCounter) / DEC)));
    if (this.carCounter > 10) {
      if (this.carLeaving === 1) { G.sound.stop(this.sndId); this.car.programControl(false); this.carOnBoard = false; }
      else {
        G.sound.play(this.o.sounds[1], "EFFECT");
        this.sndId = G.sound.play(this.o.sounds[2], "EFFECT");
        this.car.programControl(true, true);
        this.car.setDirection(this.dirs[this.atStart === 1 ? 0 : 1]);
      }
      this.carCounter = 0; this.carLeaving = 0;
    }
  }
  step(carLoc: Point) {
    const atEnd = (dir: number) => {
      this.wait = 15; this.back = dir;
      if (this.carOnBoard) this.boardInit(1); else if (this.carClose(carLoc)) this.boardInit(-1);
    };
    if (this.counter > this.max) { this.counter = this.max; atEnd(-1); }
    else if (this.counter < 0) { this.counter = 0; atEnd(1); }
    else if (this.counter === Math.trunc(this.max / 2)) {
      if (this.back === 1) { this.endLoc = this.ends[1]; this.atStart = -1; } else { this.endLoc = this.ends[0]; this.atStart = 1; }
    }
    if (this.wait) {
      this.wait--;
      if (this.carOnBoard) this.boarding();
      else if (this.carWasntOnBoard && this.carClose(carLoc)) { this.boardInit(-1); this.wait = 15; }
      if (this.wait === 0 && !this.carOnBoard) this.carWasntOnBoard = true;
    } else {
      this.counter += this.back;
      this.myLoc = new Point(this.myLoc.x + this.stepV.x * this.back, this.myLoc.y + this.stepV.y * this.back);
      this.place();
      if (this.carOnBoard) this.car.setCoordinate(new Point(Math.trunc(this.myLoc.x / DEC), Math.trunc(this.myLoc.y / DEC)));
    }
  }
}

/** Racing track: drive through the goal twice; best times on the board. */
class Racing extends ObjectHandler {
  racing = false; counter = 0; delay = 0; passed = 0; enteredFrom = 0; mustEnterFrom = 1; thisTime = "";
  hiScores: [number, string][] = [];
  private readonly field = (n: number) => `CustomRacingField${n}`;
  init() {
    this.mustEnterFrom = this.o.optional.get<number>("EnterDir") ?? 1;
    const saved = localStorage.getItem("mullebil.racing");
    this.hiScores = saved ? JSON.parse(saved) : [[186, "MIA M"], [232, "FIGGE F"]];
    this.hiScores.sort((a, b) => a[0] - b[0]);
    const board = this.o.optional.get<Point>("Board") ?? new Point(0, 0);
    this.show(this.o.frames("Board")[0] ?? "Dummy", "Under", board);
    const goal = this.o.sprite("Under", 1); this.d.movie.setMemberByName(goal, this.o.frames("Goal")[0] ?? "Dummy"); goal.setLoc(this.o.loc.x, this.o.loc.y); goal.puppet = true;
    for (let n = 1; n <= 2; n++) {
      const s = this.o.sprite("Under", n + 1);
      this.d.movie.setMemberByName(s, this.field(n)); s.setLoc(board.x - 75, board.y - 25 + 30 * (n - 1)); s.width = 158; s.height = 20; s.puppet = true;
    }
    this.showTime();
  }
  private text(n: number, t: string) { this.d.movie.setText(this.field(n), t); }
  private fmt(tenths: number) { return `${Math.trunc(tenths / 10)}:${tenths % 10}0`; }
  private showTime() { this.hiScores.slice(0, 2).forEach(([t, name], i) => this.text(i + 1, `${this.fmt(t)} ${name.slice(0, 6)}`)); }
  step(carLoc: Point) {
    const ev = this.o.checkRadius(carLoc, "Inner");
    if (ev === "EnterInnerRadius") this.enter(carLoc); else if (ev === "ExitInnerRadius") this.exit(carLoc);
    const fps = G.engine.tempo;
    if (this.racing) {
      this.counter++;
      this.text(1, `${Math.trunc(this.counter / fps)}:${Math.trunc((10 * (this.counter % fps)) / fps)}0`);
    } else if (this.delay) {
      this.delay--;
      if (this.delay % 6 === 5) this.text(1, this.thisTime); else if (this.delay % 6 === 0) this.text(1, " ");
      if (!this.delay) this.showTime();
    }
  }
  private fromRightSide(carLoc: Point) {
    let diff = Math.abs(this.mustEnterFrom - calcDirection(carLoc, this.o.loc)[0]);
    if (diff > 8) diff = 16 - diff;
    return diff <= 3;
  }
  private enter(carLoc: Point) {
    if (!this.fromRightSide(carLoc)) { this.enteredFrom = -1; return; }
    this.enteredFrom = 1;
    if (!this.racing) {
      G.sound.play(this.o.sounds[0], "EFFECT");
      this.passed = 0; this.racing = true; this.counter = 0;
      this.text(1, " "); this.text(2, " ");
      return;
    }
    if (this.passed !== 1) return;
    const u = G.mulle.user!;
    G.sound.play(this.o.sounds[1], "EFFECT");
    const missions = this.o.setWhenDone("Missions"); if (Array.isArray(missions)) u.addCompletedMission(missions[0] as number);
    this.racing = false; this.delay = 24;
    const time = Math.trunc((10 * this.counter) / G.engine.tempo);
    const name = u.userId.toUpperCase().slice(0, 6);
    this.thisTime = `${this.fmt(time)} ${name}`;
    u.car.setCacheProp("racing", time);
    if (time < 150) { const m = this.o.setWhenDone("Medals"); this.d.giveMedal(Array.isArray(m) ? m[0] as number : 5); }
    if (this.hiScores[this.hiScores.length - 1][0] >= time) {
      this.hiScores[this.hiScores.length - 1] = [time, name];
      this.hiScores.sort((a, b) => a[0] - b[0]);
      localStorage.setItem("mullebil.racing", JSON.stringify(this.hiScores));
    }
  }
  private exit(carLoc: Point) {
    if (!this.racing) return;
    if (this.fromRightSide(carLoc)) { if (this.enteredFrom === -1) this.passed--; }
    else if (this.enteredFrom === 1) this.passed++;
  }
}

/** Create the handler for an object (Object.fromList: custom script or Destination). */
export function makeHandler(o: WorldObject): ObjectHandler {
  const t = o.data.type.toLowerCase();
  if (t === "correct") return new Correct(o);
  switch (o.data.custom.toLowerCase()) {
    case "cows": return new Herd(o, false);
    case "goats": return new Herd(o, true);
    case "ferry": return new Ferry(o);
    case "gas": return new Gas(o);
    case "racing": return new Racing(o);
    case "wbridge": return new WBridge(o);
    case "cbridge": return new CBridge(o);
    case "faraway": return new FarAway(o);
    case "picture": return new Picture(o);
    case "hill": return new Hill(o);
    case "stop": return new Stop(o);
    case "sound": return new SoundSpot(o);
    case "teleport": return new Teleport(o);
  }
  return new Destination(o);
}
