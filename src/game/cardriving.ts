/**
 * Car physics for the driving movie (05). Re-implementation of CarDriving + Wheels.
 * All positions are kept ×100 (decimalPrec) in integers, like the original, so behaviour matches.
 */
import { Point } from "../engine/lingo.ts";
import { G } from "./runtime.ts";

export const DEC = 100;
export const NDIR = 16;
const idiv = (a: number, b: number) => Math.trunc(a / b);
const P = (x: number, y: number) => new Point(x, y);
const add = (a: Point, b: Point) => P(a.x + b.x, a.y + b.y);
const sub = (a: Point, b: Point) => P(a.x - b.x, a.y - b.y);
const mul = (a: Point, k: number) => P(a.x * k, a.y * k);
const div = (a: Point, k: number) => P(idiv(a.x, k), idiv(a.y, k));

/** Direction 1..16 → unit vector ×100 (1 = slightly right of north, clockwise). */
export const DIRS: Point[] = Array.from({ length: NDIR }, (_, i) => {
  const a = (Math.PI * 2 * (i + 1)) / NDIR;
  return P(Math.round(DEC * Math.sin(a)), -Math.round(DEC * Math.cos(a)));
});
export const dirVec = (d: number) => DIRS[d - 1];
export function correctDirection(d: number) { return d > NDIR ? d - NDIR : d < 1 ? d + NDIR : d; }

/** Direction (1..16) from one point towards another, plus distance. */
export function calcDirection(from: Point, to: Point): [number, number] {
  const dx = to.x - from.x; let dy = from.y - to.y;
  const hypo = Math.sqrt(dx * dx + dy * dy);
  if (dy === 0) dy = 0.1;
  let a = Math.atan(dx / dy);
  if (dx > 0) { if (dy <= 0) a += Math.PI; }
  else a += dy > 0 ? 2 * Math.PI : Math.PI;
  let d = Math.round(((a / Math.PI) * NDIR) / 2);
  if (d === 0) d = NDIR;
  return [d, hypo];
}

/** Terrain info at the front wheels: [frontType, middleType, frontAlt, middleAlt] or 0 if blocked. */
type TerrainInfo = [number, number, number, number] | 0;

/** Wheels: samples the 316×198 topology grid (half resolution of the 640×396 map). */
export class Wheels {
  topology: Uint8Array = new Uint8Array(0);
  coordinate = P(0, 0);
  readonly wheelPos = DIRS.map(v => div(mul(v, 5), DEC));
  private readonly mapOffset = P(4, 4);

  toGrid(c: Point) { return div(sub(div(c, DEC), this.mapOffset), 2); }
  fromGrid(g: Point) { return mul(add(mul(g, 2), this.mapOffset), DEC); }
  setCoordinate(c: Point) { this.coordinate = this.toGrid(c); }
  private at(h: number, v: number) { const i = h - 1 + (v - 1) * 316; return i >= 0 && i < this.topology.length ? this.topology[i] : 0; }

  checkBorders(dir: number, forward: number): Point | 0 {
    let h = this.coordinate.x, v = this.coordinate.y;
    if (forward === 1) { const w = this.wheelPos[Math.abs(dir) - 1]; h += w.x; v += w.y; }
    const m = 2;
    if (h < 1 + m) return P(-1, 0);
    if (h > 316 - m) return P(1, 0);
    if (v < 1 + m) return P(0, -1);
    if (v > 198 - m) return P(0, 1);
    return 0;
  }

  quickCheck(coord: Point | 0, dir: number, forward: number): TerrainInfo;
  quickCheck(coord: Point | 0): 0 | 1;
  quickCheck(coord: Point | 0, dir?: number, forward = 0): TerrainInfo | 0 | 1 {
    const c = coord || this.coordinate;
    if (dir && dir >= 1 && dir <= NDIR) {
      const middle = this.at(c.x, c.y);
      const w = this.wheelPos[dir - 1];
      let front = this.at(c.x + w.x, c.y + w.y);
      if (forward >= 0 && front >= 240) return 0;
      if (forward < 0 && middle >= 240) return 0;
      let mid = middle;
      if (front >= 240) front = mid; else if (mid >= 240) mid = front;
      return [idiv(front, 16), idiv(mid, 16), front % 16, mid % 16];
    }
    return this.at(c.x, c.y) >= 240 ? 0 : 1;
  }

  /** Try sliding past an obstacle; returns a new ×100 coordinate or 0. */
  moveAtLeastAStep(dir: number, how: "normal" | "Tangent", option: number, optCoord: Point): Point | 0 {
    if (how === "normal") { dir = correctDirection(dir + 4 * option); option = 2 * DEC; }
    let step = dirVec(dir);
    const max = Math.max(Math.abs(step.x), Math.abs(step.y));
    if (how === "Tangent") { const sign = option < 0 ? -1 : 1; if (Math.abs(option) * max >= DEC) option = sign * DEC; }
    step = div(mul(step, option), max);
    const thisCoord = optCoord;
    let tempCoord: Point, realCoord = thisCoord;
    if (how === "normal") {
      tempCoord = add(thisCoord, div(add(step, div(step, 3)), DEC));
      realCoord = add(thisCoord, div(div(step, 2), DEC));
    } else tempCoord = add(thisCoord, div(step, DEC));
    if (this.quickCheck(tempCoord) !== 0) return this.fromGrid(how === "normal" ? realCoord : tempCoord);
    return 0;
  }

  checkHit(last: Point, tryC: Point, speed: number, dir: number, sideStepLimit: number): [Point, string] | 0 {
    if (Math.abs(speed) <= 2 * DEC) {
      let lastG = this.toGrid(last);
      if (speed > 0) lastG = add(lastG, this.wheelPos[dir - 1]);
      let r = this.moveAtLeastAStep(dir, "Tangent", speed, lastG);
      if (r) { if (speed > 0) r = sub(r, mul(this.wheelPos[dir - 1], DEC * 2)); return [r, "Rounding"]; }
      return 0;
    }
    if (speed > sideStepLimit) {
      const t = add(this.toGrid(tryC), this.wheelPos[dir - 1]);
      for (const side of [1, -1]) {
        const r = this.moveAtLeastAStep(dir, "normal", side, t);
        if (r) return [sub(r, mul(this.wheelPos[dir - 1], DEC * 2)), "sideStep"];
      }
    }
    return 0;
  }

  whichSideIsFree(coord: Point, speed: number, dir: number) {
    const c = this.toGrid(coord);
    let n = 1, leftRight = 1;
    outer: for (n = 1; n <= 5; n++) {
      for (let m = 1; m <= 2; m++) {
        leftRight = n === 2 ? -1 : 1;
        const d = correctDirection(dir + leftRight * n);
        const diff = div(mul(dirVec(d), idiv(speed, DEC)), DEC);
        const base = speed > 0 ? add(c, this.wheelPos[d - 1]) : c;
        if (this.quickCheck(add(base, div(diff, 2)))) break outer;
      }
    }
    return Math.min(n, 5) * leftRight;
  }
}

export interface CarDriveHost {
  /** Move to an adjacent map (relative); returns false when there is none. */
  changeMap(rel: Point): boolean;
  hasMap(rel: Point): boolean;
  onMedal(id: number): void;
  onOutOfFuel(which: 1 | 2): void;
  onFuelSwitch(sound: string, what: "NoGas" | "NoElectricity"): void;
  onPedalsOnly(): void;
}

/** CarDriving: speed, steering, terrain response and fuel for Mulle's car. */
export class CarDriving {
  speed = 0; direction = 1; internalDirection = DEC; steering = 0; acceleration = 0;
  coordinate = P(0, 0); lastCoordinate = P(0, 0);
  fuel: [number, number] = [0, 0];
  keySteer = 1; userSteer = true; directionLock = false; shouldCheckGround = true;
  forwardBackward = 0; altitude = 0; inclination = 0; inTerrain = 0;
  stopTimer = 0; reachForSpeed = 0; reachForDirection = 0;
  cursorDirection = 1; thisHit: number | string = 0;
  previousData: [Point, number, number | string][] = Array.from({ length: 10 }, () => [P(0, 0), 1, 0]);
  rememberThis: [Point, number, number | string] | 0 = 0;
  q: Record<string, number> = {};       // converted car properties (quickCarProps)
  maxAcc = 0;
  criteria = { MudGrip: 0, HolesDurability: 0, BigHill: 0, SmallHill: 0 };
  gotElectricEngine = false;
  hornSound = "05e050v0";
  wheels = new Wheels();
  private sndId = 0;

  /** show = the attract-mode car in the key demo: fixed good properties, no terrain. */
  constructor(private host: CarDriveHost, readonly show = false) {
    const car = G.mulle.user!.car;
    car.updateProperties();
    // Like the original: a car without any engine strength is replaced by a ready-made one (dev fallback).
    if (!show && car.prop("Strength") === 0) makeCar("Good");
    const horns = ["05e050v0", "05e049v0", "05e044v0", "05e042v0", "05d013v0"];
    const h = car.prop("HornType");
    this.hornSound = h > 0 && h <= horns.length ? horns[h - 1] : horns[0];
  }

  convertCarProps() {
    const car = G.mulle.user!.car, q = this.q;
    this.gotElectricEngine = !this.show && car.parts.some(id => (G.mulle.parts.get(id)?.prop("ElectricConsumption") ?? 0) > 0);
    if (this.gotElectricEngine) { if (q.ElectricConsumption < 0) q.ElectricConsumption = 0; } else q.ElectricVolume = 0;
    if (!q.FuelConsumption) q.FuelVolume = 0;
    q.speed = q.speed === 5 ? idiv(q.speed * DEC * 27, 10) : idiv(q.speed * DEC * 20, 10);
    q.break = idiv(q.break * DEC * 3, 10);
    if (!this.show && !q.acceleration) q.acceleration = 1;
    q.acceleration = idiv(q.acceleration * DEC * 2, 10);
    q.Steering = idiv((q.Steering + 3) * DEC * 2, 20);
    q.FuelVolume = q.FuelVolume * DEC * 12;
    q.ElectricVolume = q.ElectricVolume * DEC * 15;
    this.maxAcc = Math.max(q.break, q.acceleration);
    this.criteria = { MudGrip: q.Grip > 8 ? 1 : 0, HolesDurability: q.Durability > 3 ? 1 : 0, BigHill: q.Strength > 3 ? 1 : 0, SmallHill: q.Strength > 2 ? 1 : 0 };
  }

  private loadProps() {
    const car = G.mulle.user!.car;
    car.updateProperties();
    if (this.show) {
      this.q = { break: 3, Grip: 8, Steering: 4, acceleration: 4, speed: 3, FuelConsumption: 3, FuelVolume: 3, ElectricConsumption: 2,
        ElectricVolume: 5, Strength: 5, Durability: 4, HornType: 5, EngineType: car.prop("EngineType") || 3, Pedals: 0 };
    } else this.q = { ...car.props };
    this.convertCarProps();
  }

  start(info: { coordinate: Point; direction: number; fuel: [number, number] | "Full" }) {
    this.speed = 0; this.steering = 0;
    this.coordinate = mul(info.coordinate, DEC);
    this.direction = info.direction; this.internalDirection = DEC * this.direction;
    if (Array.isArray(info.fuel)) { this.fuel = [...info.fuel] as [number, number]; this.loadProps(); }
    else this.fillErUp();
    this.wheels.setCoordinate(this.coordinate);
  }

  /** Full tank (+ an extra tank if the car has earned one). Returns the extra percentage. */
  fillErUp() {
    this.loadProps();
    const extraProp = G.mulle.user!.car.getCacheProp("ExtraTank");
    const extra = typeof extraProp === "number" ? extraProp : 0;
    const gas = idiv((extra + 100) * this.q.FuelVolume, 100);
    this.fuel = [gas, this.gotElectricEngine ? this.q.ElectricVolume : 0];
    return extra;
  }

  getCoordinate() { return div(this.coordinate, DEC); }
  setCoordinate(c: Point, adjustTopo = false) {
    this.coordinate = mul(c, DEC);
    if (adjustTopo) { this.checkTerrain(); this.coordinate = add(this.coordinate, P(0, 3 * this.altitude * DEC)); }
  }
  getShowCoordinate() { const c = div(this.coordinate, DEC); return P(c.x, c.y - 3 * this.altitude); }
  getSpeed() { return idiv(this.speed, DEC); }
  setTopology(t: Uint8Array) { this.wheels.topology = t; }

  saveData(before: number | "none" | undefined) {
    if (typeof before === "number") { const d = this.previousData[this.previousData.length - 1 - before]; this.rememberThis = [d[0].clone(), d[1], d[2]]; }
    else if (before === "none") this.rememberThis = 0;
    else this.rememberThis = [this.coordinate.clone(), this.direction, this.thisHit];
  }
  restoreData() {
    const r = this.rememberThis; if (!r) return;
    this.coordinate = r[0].clone(); this.direction = r[1]; this.thisHit = r[2];
    this.previousData = this.previousData.map(() => [r[0].clone(), r[1], r[2]]);
  }
  steer(d: number) { if (!this.directionLock) { this.steering = d; this.reachForDirection = 0; } }
  lockDirection(yes: boolean) { this.directionLock = yes; this.steering = 0; }
  changeSpeed(upDown: number) { this.acceleration = upDown; this.reachForSpeed = 0; }
  stepback(n: number) {
    const t = this.previousData[this.previousData.length - n] ?? this.previousData[0];
    this.coordinate = t[0].clone(); this.direction = t[1];
  }
  setSpeed(s: number) {
    this.reachForSpeed = 0; this.acceleration = 0;
    this.speed = s * DEC;
    this.forwardBackward = Math.sign(this.speed);
  }
  setDirection(d: number) { this.direction = correctDirection(d); this.internalDirection = this.direction * DEC; }
  programControl(on: boolean, noCheck = false) { this.userSteer = !on; this.shouldCheckGround = !noCheck; }

  step(mouse: Point) {
    if (this.userSteer && !this.keySteer && !this.directionLock && !this.show) this.mouseSteer(mouse);
    this.calculateSpeed();
    if (this.reachForSpeed) {
      if (this.acceleration === 1 ? this.speed >= this.reachForSpeed : this.speed <= this.reachForSpeed) { this.speed = this.reachForSpeed; this.reachForSpeed = 0; }
    }
    if (this.steering) {
      this.internalDirection += this.steering * this.q.Steering;
      if (this.internalDirection > NDIR * DEC) this.internalDirection -= NDIR * DEC;
      else if (this.internalDirection <= 0) this.internalDirection += NDIR * DEC;
      this.direction = idiv(this.internalDirection, DEC);
      if (this.direction > NDIR) this.direction = 1; else if (this.direction < 1) this.direction = NDIR;
      if (this.speed === 0 && this.shouldCheckGround && !this.show) this.checkTerrain();
    }
    if (this.reachForDirection) { this.reachForDirection = 0; this.steering = 0; }
    if (this.speed) {
      this.lastCoordinate = this.coordinate.clone();
      let tryC = add(this.coordinate, div(mul(dirVec(this.direction), this.speed), DEC));
      if (this.show) { this.coordinate = tryC; return; }
      this.wheels.setCoordinate(tryC);
      if (this.shouldCheckGround) {
        let info = this.wheels.quickCheck(0, this.direction, this.forwardBackward);
        if (info === 0) {
          tryC = this.makeTheBestOfHit(tryC);
          this.wheels.setCoordinate(tryC);
          info = this.wheels.quickCheck(0, this.direction, this.forwardBackward);
        }
        if (this.checkTerrain(info)) this.coordinate = tryC;
      } else this.coordinate = tryC;
      this.wheels.setCoordinate(this.coordinate);
      const border = this.wheels.checkBorders(this.direction, this.forwardBackward);
      if (border) {
        if (this.host.hasMap(border)) {
          if (border.x === -1) this.coordinate = P((640 - 8 - 1) * DEC, this.coordinate.y);
          else if (border.x === 1) this.coordinate = P((4 + 8) * DEC, this.coordinate.y);
          else if (border.y === -1) this.coordinate = P(this.coordinate.x, (396 - 1) * DEC);
          else if (border.y === 1) this.coordinate = P(this.coordinate.x, (4 + 8) * DEC);
          this.host.changeMap(border);
          this.wheels.setCoordinate(this.coordinate);
        } else { this.stepback(1); this.setSpeed(0); }
      }
    }
    if (this.show) return;
    this.useFuel();
    if (this.userSteer) {
      this.previousData.push([this.coordinate.clone(), this.direction, this.thisHit]);
      this.previousData.shift();
      this.thisHit = 0;
    }
  }

  private useFuel() {
    let noFuel: 0 | 1 | 2 = 0;
    const burn = (i: 0 | 1, cons: number, other: number, sound: string, what: "NoGas" | "NoElectricity") => {
      if (this.fuel[i] <= 0) return;
      const left = this.fuel[i] - idiv(Math.abs(this.speed) * cons, DEC);
      if (left > 0) { this.fuel[i] = left; return; }
      this.fuel[i] = 0;
      if (this.fuel[other as 0 | 1] === 0) noFuel = (i + 1) as 1 | 2;
      else this.host.onFuelSwitch(sound, what);
      this.loadProps();
    };
    burn(0, this.q.FuelConsumption, 1, "05d015v0", "NoGas");
    burn(1, this.q.ElectricConsumption, 0, "05d016v0", "NoElectricity");
    if (!noFuel) return;
    if (!this.q.Pedals) {
      this.q.speed = DEC;
      this.programControl(true);
      this.setSpeed(0);
      this.host.onOutOfFuel(noFuel);
    } else this.host.onPedalsOnly();
  }

  private mouseSteer(mouse: Point) {
    const last = this.previousData[this.previousData.length - 2][2];
    if (last === "stop" || last === "Turn") { this.steering = 0; this.reachForDirection = 0; return; }
    const [d] = calcDirection(this.getShowCoordinate(), mouse);
    this.cursorDirection = d;
    this.reachForDirection = 1;
    let diff = d - this.direction;
    if (Math.abs(diff) >= NDIR / 2) diff = -diff;
    this.steering = Math.sign(diff);
  }

  private calculateSpeed() {
    if (this.stopTimer > 0) this.stopTimer--;
    if (!this.acceleration) return;
    if (this.stopTimer === 0) {
      let acc: number;
      if (this.forwardBackward === 0 || this.forwardBackward === this.acceleration) acc = this.acceleration * this.q.acceleration;
      else {
        acc = this.acceleration * this.q.break;
        if (Math.abs(this.speed) <= this.maxAcc) { this.speed = 0; this.stopTimer = 5; acc = 0; }
      }
      const max = idiv(this.q.speed * (this.keySteer * 25 + 75), 100);
      if (this.speed <= max && this.speed >= -idiv(max, 2)) this.speed += acc;
      if (this.speed > max) this.speed = max; else if (this.speed < -idiv(max, 4)) this.speed = -idiv(max, 4);
    }
    this.forwardBackward = Math.sign(this.speed);
  }

  private makeTheBestOfHit(tryC: Point): Point {
    const limit = DEC * (this.keySteer ? 4 : 3);
    const hit = this.wheels.checkHit(this.coordinate, tryC, this.speed, this.direction, limit);
    if (hit) {
      if (hit[1] === "sideStep") { this.thisHit = hit[1]; this.speed = idiv(7 * this.speed, 8); }
      return hit[0];
    }
    let howBad = this.wheels.whichSideIsFree(this.coordinate, this.speed, this.direction);
    const leftRight = howBad < 0 ? -1 : 1;
    howBad = Math.abs(howBad);
    const turn = this.previousData[this.previousData.length - 1][2] === "stop" ? 1 : 0;
    if (howBad > 2 || (this.speed < 3 * DEC && turn === 0)) {
      this.speed = 0; this.forwardBackward = 0; this.thisHit = "stop";
      this.setDirection(this.direction + leftRight);
      return this.coordinate; // findEdge: stay put
    }
    this.speed = idiv(3 * this.speed, 4);
    this.setDirection(this.direction + leftRight * (this.keySteer ? 1 : 2));
    this.thisHit = "Turn";
    if (Math.abs(this.speed) < this.maxAcc) { this.speed = 0; this.forwardBackward = 0; }
    return tryC;
  }

  /** React to slopes, mud and holes. Returns false if the car can't go there. */
  checkTerrain(info?: TerrainInfo): boolean {
    if (info === undefined) info = this.wheels.quickCheck(0, this.direction, this.forwardBackward);
    if (info === 0) return true;
    const car = G.mulle.user!.car;
    this.inclination = info[2] - info[3];
    if (this.inclination > 0) {
      this.speed = idiv((100 - this.forwardBackward * 10) * this.speed, 100);
      if (this.inclination > 2) {
        this.inclination = 2;
        // the original compares strength with the converted 0/1 criterion (quirk kept on purpose)
        if (this.q.Strength <= this.criteria.BigHill) { this.setSpeed(0); this.stepback(1); return false; }
        if (!car.hasMedal(1)) { this.playSound("Strength"); this.host.onMedal(1); car.addMedal(1); }
      } else if (this.inclination > 1 && this.q.Strength <= this.criteria.SmallHill) { this.setSpeed(0); this.stepback(1); return false; }
    } else if (this.inclination < 0) {
      this.speed = idiv((100 + this.forwardBackward * 10) * this.speed, 100);
      if (this.inclination < -2) this.inclination = -2;
    }
    this.altitude = idiv(info[2] + info[3], 2);
    const [front, middle] = info;
    if (front || middle) {
      if (front && middle) {
        if (front === 1) {
          if (!this.criteria.HolesDurability) { this.playSound("Durability"); this.speed = 0; return false; }
          this.speed = idiv(80 * this.speed, 100);
          if (!this.inTerrain) this.inTerrain = front;
        } else if (front === 2) {
          if (!this.criteria.MudGrip) { this.playSound("Grip"); this.speed = 0; return false; }
          this.speed = idiv(80 * this.speed, 100);
          if (!this.inTerrain) {
            if (!car.hasMedal(3)) { this.host.onMedal(3); car.addMedal(3); }
            this.inTerrain = front;
          }
        }
      } else {
        const t = this.speed > 0 ? front : middle;
        if (t === 1 && !this.criteria.HolesDurability) { this.playSound("Durability"); this.speed = 0; return false; }
        if (t === 2 && !this.criteria.MudGrip) { this.playSound("Grip"); this.speed = 0; return false; }
      }
    } else this.inTerrain = 0;
    return true;
  }

  playSound(what: "Durability" | "Grip" | "Strength") {
    const table = { Durability: ["05d002v0"], Grip: ["05d003v0"], Strength: ["05d004v0", "05d005v0"] };
    const list = table[what];
    if (G.sound.finished(this.sndId)) this.sndId = G.sound.play(list[Math.floor(Math.random() * list.length)], "EFFECT");
  }
  stopSound() { G.sound.stop(this.sndId); }
}

/** Cheats.makeCar – ready-made test cars (the original developers' shortcut). */
export function makeCar(which: "Good" | "Ok" = "Good") {
  const u = G.mulle.user!;
  const parts = which === "Good" ? [82, 238, 149, 91, 272, 102, 129, 54, 264, 65] : [82, 241, 188, 133, 39, 144, 224, 122, 92, 184, 13, 89];
  u.trashCar();
  for (const id of parts) u.car.addPart(id);
  u.car.updateProperties();
}
