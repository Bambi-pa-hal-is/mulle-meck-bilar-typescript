/**
 * Destinations 82–94: the places you drive to. Each movie decides on entry which branch to play
 * ("JustDoIt" = the car can help / you get something, "CantDoIt", "Done" = already visited) and
 * hands out parts, items, missions and medals. Clicking skips the scene (except while it matters).
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { PropList, Point, Sym, sym, type LValue } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir } from "../game/dir.ts";
import { G } from "../game/runtime.ts";
import { drawCar } from "../game/drawcar.ts";
import { loadObject, type ObjectData } from "../game/world.ts";
import { setCursor } from "./common.ts";

const S = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
const first = (v: LValue | undefined): LValue | undefined => Array.isArray(v) ? v[0] : v;

/** Data of the object we drove into (World.enteredObjectId), with Object.getOnePart. */
class Entered {
  constructor(readonly o: ObjectData) {}
  done(k: string) { return this.o.setWhenDone.get<LValue>(k); }
  check(k: string) { return this.o.checkFor.get<LValue>(k); }
  /** A part this place can still give: listed ones from #Destinations, or a random part. */
  onePart(): number {
    const raw = this.done("Parts");
    let vals = Array.isArray(raw) ? [...raw] : raw === undefined ? [] : [raw];
    const random = vals.some(v => S(v).toLowerCase() === "random");
    vals = vals.filter(v => typeof v === "number");
    const avail = G.mulle.getCurrentlyAvailable("Destinations");
    for (const v of vals) if (avail.includes(v as number)) return v as number;
    if (random) { const r = G.mulle.getCurrentlyAvailable("Random"); if (r.length) return r[0]; }
    return 0;
  }
}

type Rule = (d: DestDir, e: Entered | null) => void;

export class DestDir extends GameDir {
  testing = false;
  myMarker: string | number = "JustDoIt";
  partToGive = 0;
  carStart = 0;
  /** Exhibition (94): judges' rating 1..5 and whether a medal was won. */
  rating = 1; medal = false;
  /** Ferry office (86): which car sprite layer gets the ladder. */
  SPToChange = 0;
  constructor(m: Movie, carStart: number) {
    super(m);
    this.carStart = carStart;
    this.spriteList = carStart ? { CarStart: carStart } : {};
  }
  getPartToGive() { return this.partToGive; }
}
const dir = () => G.dir as DestDir;

// ------------------------------------------------------------------ the rules of each place
const u = () => G.mulle.user!;
const car = () => G.mulle.user!.car;
const noProp = (v: unknown) => v instanceof Sym && v === sym("NoProp");

const RULES: Record<string, { carStart: number; rule: Rule; skipAlways?: boolean; decideInStart?: boolean; noSkip?: boolean }> = {
  // 82 Stuck in the mud: strong cars (> 4) pull the other car out and get a part.
  "82": { carStart: 0, skipAlways: true, rule: (d, e) => {
    const cache = e?.done("Cache") as LValue[] | undefined;
    d.partToGive = e?.onePart() ?? 126;
    car().setCacheProp(S(cache?.[0] ?? sym("MudCar")));
    if (d.testing) return;
    if (car().prop("Strength") > 4) {
      u().addJunkPart("yard", d.partToGive); car().setCacheProp(S(cache?.[1] ?? sym("RescuedMudCar"))); d.myMarker = "JustDoIt";
    } else d.myMarker = "CantDoIt";
  } },
  // 83 Tree in the road: strong cars (> 3) push it away.
  "83": { carStart: 0, skipAlways: true, rule: (d, e) => {
    d.partToGive = e?.onePart() ?? 126;
    if (d.testing) return;
    if (car().prop("Strength") > 3) { u().addJunkPart("yard", d.partToGive); car().setCacheProp(S(first(e?.done("Cache")) ?? sym("TreeInRoad"))); d.myMarker = "JustDoIt"; }
    else d.myMarker = "CantDoIt";
  } },
  // 84 Grunka – something lying by the road: always a part.
  "84": { carStart: 20, skipAlways: true, rule: (d, e) => {
    d.partToGive = e?.onePart() ?? 126;
    if (!d.testing) { u().addJunkPart("yard", d.partToGive); car().setCacheProp(S(first(e?.done("Cache")) ?? sym("RoadThing1"))); }
  } },
  // 85 Salka the dog jumps in.
  "85": { carStart: 20, skipAlways: true, rule: (d, e) => {
    if (d.testing) return;
    const cache = e?.done("Cache"); for (const c of Array.isArray(cache) ? cache : [cache]) if (c) car().setCacheProp(S(c));
  } },
  // 86 Mia Minardi (ferry ticket): needs a ladder part (173) on the car.
  "86": { carStart: 35, decideInStart: true, rule: (d, e) => {
    const stuff = S(first(e?.done("UserStuff")) ?? sym("FerryTicket"));
    const mission = (first(e?.done("Missions")) as number) ?? 5;
    const needed = 173;
    if (d.testing) return;
    if (!noProp(u().getUserProp(stuff))) { d.myMarker = "Done"; return; }
    if (car().findPart(needed)) {
      const p = G.mulle.parts.get(needed);
      if (p && Array.isArray(p.requires)) d.SPToChange = car().snapInfo(p.requires[0])?.[0][0] ?? 0;
      u().setUserProp(stuff); u().addCompletedMission(mission); d.myMarker = "JustDoIt";
    } else d.myMarker = "CantDoIt";
  } },
  // 87 Gaston Garcon (lemonade): needs part 172 (a pump) on the car.
  "87": { carStart: 35, rule: (d, e) => {
    const stuff = S(first(e?.done("Cache")) ?? sym("Lemonade"));
    const needed = (first(e?.check("Parts")) as number) ?? 172;
    const mission = (first(e?.check("Missions")) as number) ?? 1;
    if (d.testing) return;
    if (!noProp(car().getCacheProp(stuff)) || u().isMissionCompleted(mission)) d.myMarker = "Done";
    else if (car().findPart(needed)) { car().setCacheProp(stuff); d.myMarker = "JustDoIt"; }
    else d.myMarker = "CantDoIt";
  } },
  // 88 Sture Stortand: wants lemonade, gives a part.
  "88": { carStart: 35, rule: (d, e) => {
    const need = S(first(e?.check("Cache")) ?? sym("Lemonade"));
    d.partToGive = (first(e?.done("Parts")) as number) ?? 121;
    const mission = (first(e?.done("Missions")) as number) ?? 3;
    if (d.testing) return;
    if (u().isMissionCompleted(mission) || u().findPart(d.partToGive)) d.myMarker = "Done";
    else if (!noProp(car().getCacheProp(need))) { u().addJunkPart("yard", d.partToGive); u().addCompletedMission(mission); d.myMarker = "JustDoIt"; }
    else { d.myMarker = "CantDoIt"; const bg = d.movie.sprite(1); d.movie.setMemberByName(bg, "88b002v0"); bg.puppet = true; }
  } },
  // 89 Viola Vallmark, 90 Doris Digital, 91 Ludde Labb: a part (once) and a mission.
  ...Object.fromEntries(([["89", 7], ["90", 4], ["91", 6]] as const).map(([id, mission]) => [id, { carStart: 35, rule: ((d, e) => {
    d.partToGive = e?.onePart() ?? 126;
    u().addCompletedMission((first(e?.done("Missions")) as number) ?? mission);
    if (d.testing) return;
    if (d.partToGive) { u().addJunkPart("yard", d.partToGive); d.myMarker = "JustDoIt"; } else d.myMarker = "Done";
  }) as Rule }])),
  // 92 Figge Ferrum: bring him the dog → extra fuel tank.
  "92": { carStart: 35, rule: (d, e) => {
    const set = S(first(e?.done("Cache")) ?? sym("ExtraTank"));
    const need = S(first(e?.check("Cache")) ?? sym("Dog"));
    const mission = (first(e?.done("Missions")) as number) ?? 1;
    if (d.testing) return;
    if (!noProp(car().getCacheProp(need))) {
      d.myMarker = "JustDoIt";
      u().addCompletedMission(mission);
      car().deleteCacheProp(need);
      car().setCacheProp(set, 20);
      const di = u().drivingInfo; if (di instanceof PropList) di.set("fuel", sym("Full"));
    } else d.myMarker = u().isMissionCompleted(mission) ? "Done" : "CantDoIt";
  } },
  // 93 Road's end: a part if there is one left.
  "93": { carStart: 35, rule: (d, e) => {
    d.partToGive = e?.onePart() ?? 126;
    if (d.testing) return;
    if (d.partToGive) { u().addJunkPart("yard", d.partToGive); d.myMarker = "JustDoIt"; } else d.myMarker = "Done";
  } },
  // 94 Exhibition: judges rate the car's funny factor; > 8 gives the medal.
  "94": { carStart: 0, noSkip: true, rule: (d, e) => {
    const medalId = (first(e?.done("Medals")) as number) ?? 4;
    car().setCacheProp(S(first(e?.done("Cache")) ?? sym("Exhibition")));
    u().addCompletedMission((first(e?.done("Missions")) as number) ?? 2);
    const f = car().prop("FunnyFactor");
    d.rating = f < 2 ? 1 : f < 3 ? 2 : f < 5 ? 3 : f < 7 ? 4 : 5;
    if (f > 8 && !car().hasMedal(medalId)) { d.medal = true; car().addMedal(medalId); } else d.medal = false;
    if (d.testing) { d.rating = 1; d.medal = true; }
    d.myMarker = "";
  } },
};

function destinationMovie(id: string): () => MovieScript {
  const def = RULES[id];
  return () => ({
    prepareMovie(m) { G.dir = new DestDir(m, def.carStart); },
    startMovie(m) {
      const d = dir();
      const objId = G.mulle.world?.enteredObjectId ?? 0;
      const data = objId ? loadObject(objId) : null;
      d.testing = !data;
      d.myMarker = m.frame;
      car().updateProperties();
      if (d.carStart) {
        // DrawCar with useChassisLoc: parts are placed relative to the chassis sprite's score position
        const ch = m.sprite(d.carStart + car().chassisSPOffset);
        drawCar(m, d.carStart, new Point(ch.locH, ch.locV), car());
      }
      def.rule(d, data ? new Entered(data) : null);
      G.mulle.save();
      setCursor("C_Standard");
      const marker = d.myMarker as string | number; // the rule may have changed it
      if (marker !== "" && marker !== m.frame) m.goFrame(marker);
    },
    // the exhibition (94) has no click handler in the original – the judging always plays to the end
    mouseUp(m) { if (def.noSkip) return; if (def.skipAlways || dir().myMarker !== "JustDoIt") m.goFrame("Leave"); },
  });
}

// ------------------------------------------------------------------ frame scripts & behaviors
class Hold extends Behavior { exitFrame() { this.movie.goFrame(this.movie.frame); } }
class HoldWhileSound extends Behavior { exitFrame() { if (this.movie.engine.sound.busy(1)) this.movie.goFrame(this.movie.frame); } }
class NextMarker extends Behavior { exitFrame() { this.movie.goNextMarker(); } }
class BackToDriving extends Behavior {
  exitFrame() { if (dir()?.testing) this.movie.goFrame("start"); else void G.engine.goMovie("05", 1); }
}
/** DestToEndBH (00): the scene is over. */
class DestToEndBH extends Behavior { exitFrame() { this.movie.goFrame(dir()?.testing ? "start" : "Leave"); } }
/** DestFinalBH (00): engine starts, back to the map. */
class DestFinalBH extends Behavior {
  exitFrame() {
    const engines = ["05e074v0", "05e067v0", "05e025v0", "05e004v0", "05e011v0", "05e053v0", "05e018v0", "05e060v0", "05e032v0"];
    const t = car().prop("EngineType");
    G.sound.play(engines[(t >= 1 && t <= 9 ? t : 4) - 1], "EFFECT");
    void G.engine.goMovie("05", 1);
  }
}
/** Exhibition: only continue to the medal frames if a medal was won. */
class ExhibitionEnd extends Behavior {
  exitFrame() { if (dir().medal) this.movie.goNextMarker(); else this.movie.goFrame(dir().testing ? "start" : "Leave"); }
}

/** BlinkThingBH (00): the gift (a part or an item) blinks, optionally with a sound, then continues. */
class BlinkThingBH extends Behavior {
  private counter = 0; private isOn = true; private active = true; private sndId = 0;
  private member = ""; private wait: number | "sound" = 9999;
  beginSprite() {
    const p = this.params;
    const w = p.get<string>("waitFrames") ?? "";
    this.wait = w.toLowerCase() === "sound" ? "sound" : (Number(w) || 9999);
    const snd = p.get<string>("soundName") ?? "";
    if (snd) this.sndId = G.sound.play(snd, "OPEFFECT");
    let id: LValue = p.get("id") ?? "Auto";
    let isPart = !!p.get("isPart");
    if (id === "Auto") { isPart = true; id = dir()?.getPartToGive() ?? 0; }
    if (isPart) id = G.mulle.parts.get(Number(id))?.junkView ?? "Dummy";
    this.member = String(id);
    const h = G.mulle.memberInfo(this.member)?.h ?? this.movie.member(this.member)?.info.h ?? 0;
    if (isPart) this.sprite.locV -= Math.trunc(h / 2);
    this.movie.setMemberByName(this.sprite, this.member); this.sprite.puppet = true;
  }
  exitFrame() {
    if (!this.active) return;
    this.counter++;
    const freq = this.p<number>("freq", 2);
    if (freq && this.counter % freq === 0) {
      if (this.isOn) { this.isOn = false; this.movie.setMemberByName(this.sprite, "Dummy"); }
      else {
        if (this.p("repeatSound", 0)) this.sndId = G.sound.play(this.p("soundName", ""), "OPEFFECT");
        this.isOn = true; this.movie.setMemberByName(this.sprite, this.member);
      }
    }
    if (this.wait === "sound" ? G.sound.finished(this.sndId) : this.counter === this.wait) {
      if (this.wait === "sound") this.movie.setMemberByName(this.sprite, "Dummy");
      this.active = false;
      const what = S(this.p("doWhat")).toLowerCase();
      if (what === "gonextframe") this.movie.goFrame(this.movie.frame + 1);
      else if (what === "gonextmarker") this.movie.goNextMarker();
    }
  }
}

/** WaitBH (00): wait N frames/seconds, then continue. */
class WaitBH extends Behavior {
  private counter = 0; private n = 1;
  beginSprite() { this.n = this.p<number>("waitNr", 1) * (S(this.p("unit", sym("Seconds"))).toLowerCase() === "seconds" ? this.movie.engine.tempo : 1); }
  exitFrame() {
    if (++this.counter < this.n) return;
    if (S(this.p("doWhat")).toLowerCase() === "gonextmarker") this.movie.goNextMarker(); else this.movie.goFrame(this.movie.frame + 1);
  }
}

/** LadderBH (86): the ladder appears on the car where the ladder part sits. */
class LadderBH extends Behavior {
  beginSprite() {
    const d = dir(), c = car();
    let layer = d.SPToChange; if (layer >= c.driverLayer) layer += 2;
    const s = this.movie.sprite(d.sp("CarStart") + layer);
    this.movie.setMemberByName(s, "Stege");
    const chassis = this.movie.sprite(d.sp("CarStart") + c.chassisSPOffset);
    s.setLoc(chassis.locH, chassis.locV); s.puppet = true;
  }
}

/** Exhibition: the points sign and the judge's verdict. */
class PointsBH extends Behavior {
  beginSprite() {
    const ref = this.movie.member("94n001v0"); if (!ref) return;
    this.movie.setMember(this.sprite, this.movie.memberInLib(ref, ref.info.num + dir().rating - 1)); this.sprite.puppet = true;
  }
}
class JudgeBH extends Behavior {
  type = "Judge";
  beginSprite() {
    const anim = this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as any;
    const snd = ["94d008v0", "94d007v0", "94d006v0", "94d005v0", "94d004v0"][dir().rating - 1];
    anim?.makeAnimSpeech(snd); anim?.setAnimAction("Talk");
  }
}

// ------------------------------------------------------------------ registration
/** Frame-script member numbers per movie (re/<NN>/*.ls). Unresolvable ones default to Hold. */
const FRAME_SCRIPTS: Record<string, [number, new () => Behavior][]> = {
  "82": [[6, Hold]],
  "83": [[6, Hold], [7, BackToDriving]],
  "84": [[1, Hold]],
  "85": [[1, Hold], [2, BackToDriving]],
  "86": [[13, Hold], [11, HoldWhileSound], [7, BackToDriving], [15, LadderBH]],
  "87": [[2, Hold], [1, HoldWhileSound], [3, NextMarker], [4, BackToDriving]],
  "88": [[3, Hold], [2, HoldWhileSound], [7, BackToDriving]],
  "89": [[6, Hold]], "90": [[6, Hold]], "91": [[6, Hold]],
  "92": [[6, Hold]],
  "93": [[6, Hold]],
  "94": [[3, Hold], [2, NextMarker], [4, ExhibitionEnd], [22, PointsBH], [29, JudgeBH]],
};

export function registerDestinations(engine: Engine) {
  for (const id of Object.keys(RULES)) {
    engine.registerMovie(id, destinationMovie(id));
    for (const [n, c] of FRAME_SCRIPTS[id] ?? []) registerBehavior(`${id}:${n}`, c);
  }
  registerBehavior("DestToEndBH", DestToEndBH);
  registerBehavior("DestFinalBH", DestFinalBH);
  registerBehavior("BlinkThingBH", BlinkThingBH);
  registerBehavior("WaitBH", WaitBH);
}
