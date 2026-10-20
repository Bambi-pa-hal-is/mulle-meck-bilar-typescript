/**
 * Movie 05 – Körning (driving around the world map).
 * Controls: arrow keys (or Shift/Ctrl) to accelerate/brake and steer; hold the mouse button to drive
 * towards the cursor, right button brakes. Toolbox → driving menu (steering mode, home, diploma, quit).
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, PropList, Sym, sym } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir } from "../game/dir.ts";
import { G, random, pick } from "../game/runtime.ts";
import { CarDriving, type CarDriveHost } from "../game/cardriving.ts";
import { World, loadMap, loadObject, loadTopology, pt, type MapData } from "../game/world.ts";
import { WorldObject, makeHandler } from "./m05_objects.ts";

const ENGINE_SOUNDS = [
  ["05e073v0", "05e079v0", "05e074v0", "05e075v0", "05e076v0", "05e077v0", "05e078v0"],
  ["05e067v0", "05e073v0", "05e068v0", "05e069v0", "05e070v0", "05e071v0", "05e072v0"],
  ["05e025v0", "05e031v0", "05e026v0", "05e027v0", "05e028v0", "05e029v0", "05e030v0"],
  ["05e004v0", "05e010v0", "05e005v0", "05e006v0", "05e007v0", "05e008v0", "05e009v0"],
  ["05e011v0", "05e017v0", "05e012v0", "05e013v0", "05e014v0", "05e015v0", "05e016v0"],
  ["05e053v0", "05e059v0", "05e054v0", "05e055v0", "05e056v0", "05e057v0", "05e058v0"],
  ["05e018v0", "05e024v0", "05e019v0", "05e020v0", "05e021v0", "05e022v0", "05e023v0"],
  ["05e060v0", "05e066v0", "05e061v0", "05e062v0", "05e063v0", "05e064v0", "05e065v0"],
  ["05e032v0", "05e038v0", "05e033v0", "05e034v0", "05e035v0", "05e036v0", "05e037v0"],
];

/** DisplayCar: draws the car sprite (direction × slope frames) and plays engine sound by speed. */
class DisplayCar {
  soundOn = true; visible = true; private lastSpeed = 0; private sndId = 0; private sndList: string[] = [];
  private firstFrame: number;
  constructor(private d: DriveDir, private car: CarDriving, private spName: "car", show: boolean) {
    this.firstFrame = show ? d.movie.memberNum("ShowCarPic") - 36 : d.movie.memberNum("CarPic");
    d.addLoopObject(this);
  }
  get sprite() { return this.d.movie.sprite(this.d.sp(this.spName)); }
  setEngine() {
    let e = this.car.q.EngineType;
    if (!(e > 0)) return;
    if (e < 1 || e > ENGINE_SOUNDS.length) e = 1;
    this.sndList = ENGINE_SOUNDS[e - 1];
    this.changeSound(); this.changeSound();
  }
  changeSound(on?: boolean) {
    this.soundOn = on === undefined ? !this.soundOn : on;
    if (this.soundOn) this.lastSpeed = -4711; else G.sound.stop(this.sndId);
  }
  show(yes: boolean) { this.visible = yes; if (!yes) this.d.movie.setMemberByName(this.sprite, "Dummy"); else this.display(); }
  stopEngine() { if (this.sndList.length) this.sndId = G.sound.play(this.sndList[1], "BG"); }
  kill() { this.d.deleteLoopObject(this); this.d.movie.setMemberByName(this.sprite, "Dummy"); G.sound.stop(this.sndId); }
  loop() { this.display(); }
  display() {
    if ((this.d.mode !== "Driving" && this.d.mode !== "Showing") || !this.visible) return;
    const m = this.d.movie, s = this.sprite;
    this.car.step(new Point(m.engine.mouse.x | 0, m.engine.mouse.y | 0));
    const loc = this.car.getShowCoordinate();
    s.setLoc(loc.x, loc.y);
    const ref = m.member("CarPic")!;
    m.setMember(s, m.memberInLib(ref, this.firstFrame + this.car.direction + (2 + this.car.inclination) * 16));
    s.width = s.height = 0; s.ink = 36; s.puppet = true;
    const max = Math.trunc(this.car.q.speed / 100) || 1;
    const percent = Math.trunc((100 * Math.abs(this.car.getSpeed())) / max);
    if (this.soundOn && this.sndList.length) {
      const pos = [10, 20, 40, 70].filter(l => l < percent).length + 1;
      if (pos !== this.lastSpeed) {
        this.lastSpeed = pos;
        G.sound.stop(this.sndId);
        this.sndId = G.sound.play(this.sndList[pos + 1], "BG"); // running sounds loop via their member flag
      }
    }
  }
}

// ------------------------------------------------------------------ gDir
export class DriveDir extends GameDir implements CarDriveHost {
  mode: "Preparing" | "Showing" | "Driving" | "Waiting" | "OutOfGas" = "Preparing";
  car: CarDriving | null = null;
  display: DisplayCar | null = null;
  map: MapData | null = null;
  mapCoordinate = new Point(1, 1);
  objects: WorldObject[] = [];
  nextDir = "";
  usedArrows = false;
  private acc = false; private brake = false; wasKeySteer = 1; private wasSoundOn = true;
  private readonly maxUnder = 15; private readonly maxOver = 10;

  constructor(m: Movie) {
    super(m);
    this.spriteList = { map: 1, ObjectsUnder: 5, ObjectsOver: 21, car: 20, medal: 64, KPH: 58, Petrol: 59, fDialog: 110, ShowCar: 55, RealCar: 20, ShowOff: 50 };
    this.loadWorld();
    this.spriteList.car = this.spriteList.ShowCar;
    this.mode = "Showing";
  }

  get world() { return G.mulle.world!; }

  private loadWorld() {
    const g = G.mulle;
    const want = g.activeWorld || g.worlds[0] || "Da Hood";
    if (!g.world || g.world.id !== want) {
      g.world = new World();
      g.world.load(want);
      g.world.calcRandomDestinations();
    }
    if (!g.user!.drivingInfo) g.world.randomizeDestinations();
    g.calcCurrentlyAvailable("Destinations");
    g.calcCurrentlyAvailable("Random");
  }

  private drivingInfo(): { map: Point; coordinate: Point; direction: number; fuel: [number, number] | "Full"; keySteer: number } {
    const info = G.mulle.user!.drivingInfo;
    if (info instanceof PropList) {
      const f = info.get("fuel");
      return { map: pt(info.get("map")), coordinate: pt(info.get("coordinate")), direction: info.get("direction"),
        fuel: Array.isArray(f) ? [f[0] as number, f[1] as number] : "Full", keySteer: info.get("keySteer") ?? 1 };
    }
    const w = this.world;
    return { map: w.startMap.clone(), coordinate: w.startCoordinate.clone(), direction: w.startDirection, fuel: "Full", keySteer: 1 };
  }

  /** Called from startMovie: show the map we start on (before the car exists). */
  init() {
    this.movie.sprite(this.sp("map")).setLoc(320, 202);
    this.changeMap(this.drivingInfo().map, "Absolute", false);
  }

  /** The demo is over (or skipped): create the real car and start driving. */
  startCar() {
    this.movie.setMemberByName(this.movie.sprite(this.sp("ShowCar")), "Dummy");
    const info = this.drivingInfo();
    if (!this.car) {
      this.car = new CarDriving(this);
      this.display = new DisplayCar(this, this.car, "car", false);
    }
    this.setKeySteer(info.keySteer);
    this.car.start({ coordinate: info.coordinate, direction: info.direction, fuel: info.fuel });
    this.display!.setEngine();
    this.changeMap(info.map, "Absolute");
    this.car.checkTerrain();
    this.send("Petrol", "init");
    this.mode = "Driving";
  }

  hasMap(rel: Point) { return this.world.newMapId(rel, "Relational", true) !== null; }

  changeMap(p: Point, mode: "Relational" | "Absolute" = "Relational", realInit = true): boolean {
    const id = this.world.newMapId(p, mode);
    if (id === null) return false;
    this.mapCoordinate = mode === "Relational" ? new Point(this.mapCoordinate.x + p.x, this.mapCoordinate.y + p.y) : p.clone();
    this.map = loadMap(id);
    if (!this.map) return false;
    const mapSprite = this.movie.sprite(this.sp("map"));
    this.movie.setMemberByName(mapSprite, this.map.image); mapSprite.ink = 0; mapSprite.puppet = true;
    if (realInit && this.car) {
      this.car.setTopology(loadTopology(this.map.topology));
      const corrected = this.goThroughObjects();
      if (corrected) this.car.setCoordinate(corrected, true);
    }
    return true;
  }

  /** Place the current map's objects into the "under" and "over" sprite ranges. */
  private goThroughObjects(): Point | null {
    const m = this.movie;
    this.objects = [];
    for (let n = 0; n < this.maxUnder; n++) m.setMemberByName(m.sprite(this.sp("ObjectsUnder") + n), "Dummy");
    for (let n = 0; n < this.maxOver; n++) m.setMemberByName(m.sprite(this.sp("ObjectsOver") + n), "Dummy");
    let under = 0, over = 0, corrected: Point | null = null;
    const carLoc = this.car!.getShowCoordinate();
    for (const [objId, loc, optional] of this.map!.objects) {
      const data = loadObject(objId); if (!data) continue;
      const type = data.type.toLowerCase();
      if (type === "rdest") {
        const at = this.world.rDests.get(objId);
        if (!at || at.x !== this.mapCoordinate.x || at.y !== this.mapCoordinate.y) continue;
      } else if (type === "correct") {
        const r = optional.get<number>("InnerRadius") ?? 80;
        if (Math.hypot(carLoc.x - loc.x, carLoc.y - loc.y) < r) corrected = loc;
        continue;
      }
      const o = new WorldObject(this, data, loc, optional, this.sp("ObjectsOver") + over, this.sp("ObjectsUnder") + under);
      o.handler = makeHandler(o);
      if (!o.init(carLoc)) continue;
      under += data.spriteInfo.get<number>("Under") ?? 0;
      over += data.spriteInfo.get<number>("Over") ?? 0;
      this.objects.push(o);
    }
    return corrected;
  }

  teleport(worldId: string, map: Point, loc: Point) {
    if (worldId && worldId !== this.world.id) { this.world.load(worldId); this.world.calcRandomDestinations(); }
    this.changeMap(map, "Absolute");
    this.car?.setCoordinate(loc);
  }

  /** Leave the map: home (03/04), diploma (08) or a destination movie. */
  prepareToLeave(toDir: string) {
    const u = G.mulle.user!;
    G.mulle.whereFrom = "05";
    this.display?.stopEngine();
    this.nextDir = toDir;
    if (toDir === "04" || toDir === "03") { u.drivingInfo = 0; this.movie.goFrame("GoHome"); return; }
    const c = this.car!;
    u.drivingInfo = new PropList().set("map", this.mapCoordinate.clone()).set("direction", c.direction)
      .set("coordinate", c.getCoordinate()).set("fuel", [...c.fuel]).set("keySteer", c.keySteer);
    G.mulle.save();
    this.movie.goFrame(toDir === "08" ? "08" : "Leave");
  }

  loop() {
    if (this.mode === "Driving" && this.car) {
      this.pollKeys();
      const carLoc = this.car.getShowCoordinate();
      for (const o of [...this.objects]) o.handler.step(carLoc);
    }
    super.loop();
  }

  // ---- controls (KeyHandlers + keyDown/keyUp movie script)
  setKeySteer(on: number | boolean = this.car?.keySteer ?? 1) {
    if (this.car) this.car.keySteer = on ? 1 : 0;
    this.movie.sprite(115).send("setMode", on ? "Keys" : "mouse");
  }
  /** Accelerate: Shift / mouse button / ↑; brake: Ctrl / right mouse / ↓ (polled every frame). */
  private pollKeys() {
    const e = this.movie.engine, k = e.keys;
    const acc = k.has("Shift") || e.mouse.down || k.has("ArrowUp");
    const brake = k.has("Control") || e.mouse.rightDown || k.has("ArrowDown");
    if (this.acc && !acc) { this.keyUp("up"); this.acc = false; }
    else if (!this.acc && acc) {
      if (e.mouse.down) { this.wasKeySteer = this.car!.keySteer; this.setKeySteer(0); } else this.setKeySteer(1);
      this.keyDown("up"); this.acc = true;
    }
    if (this.brake && !brake) { this.keyUp("down"); this.brake = false; }
    else if (!this.brake && brake) { this.setKeySteer(e.mouse.rightDown ? 0 : 1); this.keyDown("down"); this.brake = true; }
  }
  keyDown(which: "left" | "right" | "up" | "down") {
    const c = this.car;
    if (this.mode !== "Driving" || !c?.userSteer) return;
    if (which === "left") c.steer(-1); else if (which === "right") c.steer(1);
    else { this.usedArrows = false; c.changeSpeed(which === "up" ? 1 : -1); }
  }
  keyUp(which?: "up" | "down") {
    const c = this.car;
    if (this.mode !== "Driving" || !c?.userSteer) return;
    if (which) c.changeSpeed(0);
    else { if (this.usedArrows) c.changeSpeed(0); c.steer(0); }
  }

  activate(yes: boolean) {
    if (yes) {
      this.mode = "Driving";
      if (this.wasSoundOn) this.display?.changeSound(true);
    } else {
      G.sound.stopBG();
      if (this.mode !== "Showing" && this.display) { this.wasSoundOn = this.display.soundOn; this.setKeySteer(this.wasKeySteer); }
      this.mode = "Waiting";
    }
  }

  // ---- CarDriveHost callbacks
  onMedal(id: number) { this.send("medal", "Blink", id); }
  giveMedal(id: number) { const car = G.mulle.user!.car; if (!car.hasMedal(id)) { car.addMedal(id); this.onMedal(id); } }
  medalSoundFinished() { return this.send("medal", "FinishedSound") !== false; }
  onFuelSwitch(sound: string, what: "NoGas" | "NoElectricity") {
    G.sound.stopAllEffects(); this.send("medal", "stop"); G.sound.play(sound, "EFFECT"); updateEngine(what);
  }
  onPedalsOnly() { G.sound.stopAllEffects(); this.send("medal", "stop"); G.sound.play("05d017v0", "EFFECT"); }
  onOutOfFuel(which: 1 | 2) {
    updateEngine("NoFuel");
    this.display?.changeSound(false);
    this.mode = "OutOfGas";
    const snd = pick(which === 1 ? ["05d001v0", "05d011v0", "05d012v0"] : ["05d014v0"]);
    G.sound.stopAllEffects(); this.send("medal", "stop");
    const id = G.sound.play(snd, "EFFECT");
    const d = this;
    this.addLoopObject({ loop() { if (G.sound.finished(id)) { d.deleteLoopObject(this); d.prepareToLeave("03"); } } });
  }
  fillErUp() { const extra = this.car!.fillErUp(); this.send("Petrol", "fillErUp", extra); }
  showCar(yes: boolean) { this.display?.show(yes); }
  setEngineSound(on: boolean) { this.display?.changeSound(on); }
  engineSoundOn() { return this.display?.soundOn ?? false; }
  stopSound() { this.send("medal", "stopSound"); this.car?.stopSound(); }

  kill() { this.display?.kill(); super.kill(); }
}
const dir = () => G.dir as DriveDir;

/** DrivingHandlers.updateEngine: drop the engines that ran out of their energy source. */
function updateEngine(what: "NoGas" | "NoElectricity" | "NoFuel") {
  const car = G.mulle.user!.car;
  let speed = 0, strength = 0, engine = 0;
  for (const id of car.parts) {
    const p = G.mulle.parts.get(id); if (!p || p.prop("Strength") <= 0) continue;
    const elec = p.prop("ElectricConsumption"), gas = p.prop("FuelConsumption");
    if ((elec > 0 && what === "NoElectricity") || (gas > 0 && what === "NoGas") || ((gas > 0 || elec > 0) && what === "NoFuel")) continue;
    speed = Math.max(speed, p.prop("speed")); strength += p.prop("Strength"); engine = Math.max(engine, p.prop("EngineType"));
  }
  car.props.speed = speed; car.props.Strength = strength; car.props.EngineType = engine;
}

export const drivingMovie = (): MovieScript => ({
  prepareMovie(m) { G.dir = new DriveDir(m); },
  startMovie(m) {
    m.setMemberByName(m.sprite(118), "Dummy"); m.setMemberByName(m.sprite(119), "Dummy");
    G.sound.stopBG(); G.sound.stopAllEffects();
    m.sprite(115).send("MEnter", "00b023v0", 1);
    dir().init();
    // arrow keys steer while held
    m.engine.keyDownScript = e => {
      const d = dir(); if (!d) return;
      if (d.mode === "Driving") {
        if (e.key === "ArrowLeft") { d.setKeySteer(1); d.keyDown("left"); }
        else if (e.key === "ArrowRight") { d.setKeySteer(1); d.keyDown("right"); }
        else if (e.key.toLowerCase() === "s") d.display?.changeSound();
      } else if (d.mode === "Showing") d.send("ShowOff", "fakeMouse");
    };
    m.engine.keyUpScript = e => { if (e.key === "ArrowLeft" || e.key === "ArrowRight") dir()?.keyUp(); };
  },
  mouseUp() { if (dir()?.mode === "Showing") dir().send("ShowOff", "fakeMouse"); },
});

// ------------------------------------------------------------------ frame scripts
class DriveLoop extends Behavior { exitFrame() { dir()?.loop(); this.movie.goFrame(this.movie.frame); } }
class GoNextDir extends Behavior { exitFrame() { void G.engine.goMovie(dir()?.nextDir || "03", 1); } }
const goMovie = (id: string) => class extends Behavior { exitFrame() { void G.engine.goMovie(id, 1); } };

// ------------------------------------------------------------------ HUD & helpers
/** ShowOffScript – first few drives: a demo car with the arrow keys lit up; click/key to start. */
class ShowOffScript extends Behavior implements CarDriveHost {
  private active = true; private waitAndKill = false; private counter = 0;
  private demo: CarDriving | null = null; private demoDisplay: DisplayCar | null = null;
  private delay: (PropList | 0)[] = Array(9).fill(0);
  private readonly keys = { left: ["05b003v0", "05b004v0"], right: ["05b007v0", "05b008v0"], up: ["05b001v0", "05b002v0"], down: ["05b005v0", "05b006v0"] };
  private script: (PropList | 0)[] = [];
  beginSprite() {
    const u = G.mulle.user!;
    if ((G.mulle.whereFrom === "04" || G.mulle.whereFrom === "03") && u.nrOfBuiltCars < 4) {
      const d = dir(), m = this.movie, sp = this.spriteNum;
      this.demo = new CarDriving(this, true);
      this.demoDisplay = new DisplayCar(d, this.demo, "car", true);
      this.demo.start({ coordinate: new Point(290, 280), direction: 4, fuel: [1, 1] });
      this.demoDisplay.setEngine();
      const locs = [new Point(260, 240), new Point(380, 240), new Point(320, 190), new Point(320, 240)];
      const order: (keyof typeof this.keys)[] = ["left", "right", "up", "down"];
      order.forEach((k, i) => { const s = m.sprite(sp + i + 1); m.setMemberByName(s, this.keys[k][0]); s.setLoc(locs[i].x, locs[i].y); s.puppet = true; });
      const plate = m.sprite(sp); m.setMemberByName(plate, "Platta"); plate.setLoc(320, 220); plate.puppet = true;
      const A = (v: number) => new PropList().set("Accelerate", v), St = (v: number) => new PropList().set("steer", v);
      const seq: [number, PropList][] = [[4, A(1)], [9, A(0)], [14, A(-1)], [20, A(0)], [31, A(-1)], [47, A(0)], [57, A(1)], [62, A(0)],
        [63, new PropList().set("stop", 1)], [74, St(1)], [80, St(0)], [93, St(-1)], [99, St(0)]];
      this.script = Array(108).fill(0);
      for (const [i, a] of seq) this.script[i - 1] = a;
    } else this.waitAndKill = true;
  }
  // demo car never leaves the screen: host callbacks are no-ops
  changeMap() { return false; } hasMap() { return false; } onMedal() {} onOutOfFuel() {} onFuelSwitch() {} onPedalsOnly() {}
  mouseUp() { this.waitAndKill = true; }
  fakeMouse() { this.waitAndKill = true; }
  private kill() {
    const m = this.movie;
    if (this.demo) { for (let i = 0; i <= 4; i++) m.setMemberByName(m.sprite(this.spriteNum + i), "Dummy"); this.demoDisplay?.kill(); this.demo = null; }
    dir().spriteList.car = dir().spriteList.RealCar;
    dir().startCar();
    this.active = false;
  }
  exitFrame() {
    if (!this.active) return;
    if (this.waitAndKill) { this.kill(); return; }
    const act = this.script[this.counter++] ?? 0;
    if (act) { for (const [k, v] of act.entries) if (String((k as Sym).name ?? k).toLowerCase() !== "stop" && v) G.sound.play("P38ef005", "EFFECT"); }
    this.delay.push(act); this.delay.shift();
    this.apply(this.delay[0]);
    if (this.counter >= this.script.length) this.counter = 0;
  }
  private apply(act: PropList | 0) {
    if (!act || !this.demo) return;
    const m = this.movie, sp = this.spriteNum, set = (i: number, name: string) => m.setMemberByName(m.sprite(sp + i), name);
    for (const [k, v] of act.entries) {
      const key = (k as Sym).name, val = v as number;
      if (key === "stop") this.demo.setSpeed(0);
      else if (key === "steer") { this.demo.steer(val); set(2, this.keys.right[val === 1 ? 1 : 0]); set(1, this.keys.left[val === -1 ? 1 : 0]); }
      else if (key === "Accelerate") { this.demo.changeSpeed(val); set(3, this.keys.up[val === 1 ? 1 : 0]); set(4, this.keys.down[val === -1 ? 1 : 0]); }
    }
  }
}

/** PetrolBH – the fuel gauge. */
class PetrolBH extends Behavior {
  private first = 0; private readonly steps = 13; private maxFuel = 1; private elec = false; private comb = false;
  mode: "normal" | "Filling" = "normal"; private nr = 0; private fillMax = 0; private wait = 0;
  beginSprite() { this.first = this.movie.memberNum("01a001v0"); }
  private show(n: number) { const ref = this.movie.member("01a001v0")!; this.movie.setMember(this.sprite, this.movie.memberInLib(ref, this.first + n)); this.sprite.puppet = true; }
  init() { this.update(); dir().addLoopObject(this); this.mode = "normal"; }
  update() {
    const c = dir().car!;
    this.elec = c.gotElectricEngine; this.comb = c.q.FuelConsumption !== 0;
    this.maxFuel = (this.elec ? c.q.ElectricVolume : 0) + (this.comb ? c.q.FuelVolume : 0);
    if (!this.maxFuel) this.maxFuel = 1; else this.show(this.steps - 1);
  }
  loop() {
    if (dir().mode !== "Driving") return;
    const c = dir().car!;
    if (this.mode === "normal") {
      let pct = Math.trunc(((this.elec ? 100 * c.fuel[1] : 0) + (this.comb ? 100 * c.fuel[0] : 0)) / this.maxFuel);
      if (pct > 0) { if (pct >= 100) pct = 99; this.nr = Math.trunc((pct * this.steps) / 100); this.show(this.nr); }
      else this.show(0);
    } else if (this.wait) this.wait--;
    else {
      this.show(Math.min(Math.trunc(this.nr / 10), this.steps + this.fillMax));
      this.nr += 5;
      if (Math.trunc(this.nr / 10) > this.steps + this.fillMax) { this.mode = "normal"; this.update(); }
    }
  }
  fillErUp(extra: number) { this.mode = "Filling"; this.wait = 20; this.nr *= 10; this.fillMax = extra > 0 ? 3 : 0; }
}

/** KPHBH – the speedometer needle. */
class KPHBH extends Behavior {
  beginSprite() { dir().addLoopObject(this); }
  loop() {
    const c = dir().car;
    if (dir().mode !== "Driving" || !c) return;
    this.sprite.locH = 100 + Math.abs(Math.trunc((300 * c.speed) / 14 / 100)); this.sprite.puppet = true;
  }
}

/** MedalBH – a medal blinks with fanfare when earned. */
class MedalBH extends Behavior {
  private counter = 0; private sndId = 0; private sndStage = 0; private medal = ""; private medalId = 0; private readonly blink = 5;
  private readonly medals = ["00n004v0", "00n005v0", "00n006v0", "00n007v0", "00n010v0", "00n009v0"];
  private readonly sounds = ["05d008v0", "05d009v0", "05d007v0", "", "05d006v0", "05d010v0"];
  Blink(id: number) {
    this.medalId = id; this.sndId = G.sound.play("00e021v0", "OPEFFECT"); this.sndStage = 1; this.counter = 1;
    this.medal = this.medals[id - 1] ?? "";
  }
  FinishedSound() { return !this.counter || (this.sndStage === 2 && G.sound.finished(this.sndId)); }
  stopSound() { G.sound.stop(this.sndId); }
  stop() { this.movie.setMemberByName(this.sprite, "Dummy"); this.counter = 0; }
  exitFrame() {
    if (!this.counter) return;
    if (G.sound.finished(this.sndId)) {
      const next = this.sounds[this.medalId - 1];
      if (this.sndStage === 1 && next) { this.sndId = G.sound.play(next, "OPEFFECT"); this.sndStage = 2; }
      else { this.stop(); return; }
    }
    this.counter++;
    if ((this.counter + Math.trunc((3 * this.blink) / 2)) % (this.blink * 2) === 0) { this.movie.setMemberByName(this.sprite, this.medal); this.sprite.puppet = true; }
    else if (this.counter % (this.blink * 2) === 0) this.movie.setMemberByName(this.sprite, "Dummy");
  }
}

/** 05CursorBH – cursor sprite; shows a direction arrow while steering with the mouse. */
class DriveCursorBH extends Behavior {
  mode: "Keys" | "mouse" = "Keys";
  private cursors: [number, string][] = [];
  beginSprite() { this.movie.engine.cursorSprite = this.spriteNum; }
  private top() { return this.cursors.length ? this.cursors[this.cursors.length - 1][1] : "C_Standard"; }
  exitFrame() {
    const m = this.movie, { x, y } = m.engine.mouse;
    this.sprite.setLoc(x | 0, y | 0); this.sprite.puppet = true;
    const c = dir()?.car;
    if (this.mode === "mouse" && this.cursors.length === 1 && c) {
      const ref = m.member("05n002v0")!;
      m.setMember(this.sprite, m.memberInLib(ref, ref.info.num + 2 * c.cursorDirection - 2));
      this.sprite.ink = 8;
    }
  }
  setMode(mode: string) { this.mode = mode === "Keys" ? "Keys" : "mouse"; if (this.mode === "Keys") this.movie.setMemberByName(this.sprite, this.top()); }
  MEnter(cur: string, ch = 200) {
    this.cursors = this.cursors.filter(c => c[0] !== ch); this.cursors.push([ch, cur]); this.cursors.sort((a, b) => a[0] - b[0]);
    this.movie.setMemberByName(this.sprite, this.top());
  }
  MLeave(ch = 200) { this.cursors = this.cursors.filter(c => c[0] !== ch); this.movie.setMemberByName(this.sprite, this.top()); }
  C_Standard() { this.MEnter("C_Standard"); } c_grab() { this.MEnter("C_Grab"); } c_Left() { this.MEnter("C_Left"); }
  c_click() { this.MEnter("C_Click"); } C_Back() { this.MEnter("C_Back"); } C_Right() { this.MEnter("C_Right"); }
}

/** RollOverBH – show a given cursor while hovering. */
class RollOverBH extends Behavior {
  mouseEnter() { this.movie.sprite(115).send("MEnter", this.p("myMember", "C_Click"), this.spriteNum); }
  mouseLeave() { this.movie.sprite(115).send("MLeave", this.spriteNum); }
}

/** FDialogWorldBH – the driving menu: steering mode, home, diploma, quit, cancel. */
class FDialogWorldBH extends Behavior {
  active = false; private cursorNumber = 0; private oldType = ""; private counter = 0; private sndId = 0; private outside = true; private wasShowing = false;
  private readonly rects: [string, { left: number; top: number; right: number; bottom: number }][] = [
    ["Steering", { left: 116, top: 74, right: 197, bottom: 204 }], ["Home", { left: 216, top: 76, right: 281, bottom: 209 }],
    ["Diploma", { left: 316, top: 87, right: 368, bottom: 224 }], ["quit", { left: 390, top: 85, right: 460, bottom: 226 }],
    ["Cancel", { left: 470, top: 215, right: 528, bottom: 325 }],
  ];
  private readonly sounds: Record<string, string> = { Home: "09d006v0", Cancel: "09d004v0", Steering: "09d005v0", quit: "09d003v0", Diploma: "09d002v0" };
  beginSprite() { this.sprite.setLoc(320, 200); this.movie.sprite(this.spriteNum + 1).setLoc(320, 200); }
  private steerMode(change: boolean) {
    const c = dir().car; if (!c) return;
    let k = c.keySteer;
    if (change) { k = k ? 0 : 1; dir().setKeySteer(k); }
    const s = this.movie.sprite(this.spriteNum + 1); this.movie.setMemberByName(s, k ? "Dummy" : "09b005v0"); s.puppet = true;
  }
  startMeUp() {
    this.movie.setMemberByName(this.sprite, "19b001v0"); this.sprite.puppet = true;
    dir().activate(false); this.active = true; this.steerMode(false);
    this.movie.sprite(115).send("MEnter", "c_standard", 2);
  }
  closeMeDown() {
    this.movie.setMemberByName(this.sprite, "Dummy"); this.movie.setMemberByName(this.movie.sprite(this.spriteNum + 1), "Dummy");
    dir().activate(true); this.active = false;
    this.movie.sprite(115).send("MLeave", 2); this.movie.sprite(115).send("MLeave");
    G.sound.stop(this.sndId);
  }
  functionDialogSwitch() {
    if (this.active) { this.closeMeDown(); return; }
    this.wasShowing = dir().mode === "Showing";
    if (this.wasShowing) dir().send("ShowOff", "mouseUp");
    this.startMeUp();
  }
  exitFrame() {
    if (!this.active) return;
    if (this.wasShowing) { dir().activate(false); this.wasShowing = false; }
    if (this.counter && --this.counter === 0) { G.sound.stop(this.sndId); this.sndId = G.sound.play(this.sounds[this.oldType], "EFFECT"); }
    const { x, y } = this.movie.engine.mouse;
    const i = this.rects.findIndex(([, r]) => x >= r.left && x < r.right && y >= r.top && y < r.bottom);
    if (i >= 0) {
      this.movie.sprite(115).send("MEnter", "c_click");
      this.cursorNumber = i + 1;
      const t = this.rects[i][0];
      if (t !== this.oldType) { this.outside = false; G.sound.stop(this.sndId); this.counter = 10; this.oldType = t; }
      else if (G.sound.finished(this.sndId) && !this.counter && this.outside) { this.outside = false; this.counter = 10; }
    } else {
      if (G.sound.finished(this.sndId)) { this.outside = true; this.oldType = ""; }
      this.counter = 0; this.cursorNumber = 0;
      this.movie.sprite(115).send("MLeave");
    }
  }
  mouseUp() {
    if (!this.active || !this.cursorNumber) return;
    G.sound.play("SndMouseClick", "OPEFFECT");
    switch (this.cursorNumber) {
      case 1: this.steerMode(true); break;
      case 2: this.closeMeDown(); dir().prepareToLeave("03"); break;
      case 3: this.closeMeDown(); dir().prepareToLeave("08"); break;
      case 4: void G.engine.goMovie("12", 1); break;
      case 5: this.functionDialogSwitch(); break;
    }
  }
}

// ------------------------------------------------------------------ registration
export function registerDriving(engine: Engine) {
  engine.registerMovie("05", drivingMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`05:${n}`, c);
  B(9, DriveLoop); B(13, GoNextDir); B(17, goMovie("08")); B(1, goMovie("03"));
  B(61, ShowOffScript); B(43, PetrolBH); B(47, KPHBH); B(51, MedalBH);
  B(16, DriveCursorBH); B(20, RollOverBH); B(55, FDialogWorldBH);
  void sym; void random;
}
