import { PropList, Point, Rect, sym, deepClone, type Sym, type LValue } from "../engine/lingo.ts";
import { Car } from "./car.ts";
import type { MulleGlobals } from "./globals.ts";

const rnd = (n: number) => 1 + Math.floor(Math.random() * n); // Lingo random(n): 1..n

/** One player profile (the original saves these as "User<id>DB" text members). */
export class User {
  userId = "";
  car: Car;
  /** #Pile1..#Pile6, #shopFloor, #yard -> PropList(partId -> point) */
  junk = new PropList();
  nrOfBuiltCars = 0;
  /** Saved cars (album slots 1..12); 0 = empty slot, like the original Lingo list. */
  saves: (PropList | 0)[] = [];
  completedMissions: number[] = [];
  ownStuff = new PropList();
  myLastPile = 1;
  gifts: LValue[] = [[27, new Point(462, 179)]];
  toYardThroughDoor = 1;
  givenMissions: number[] = [];
  figgeIsComing = 0;
  missionIsComing = 0;
  drivingInfo: LValue = 0;

  constructor(private g: MulleGlobals) { this.car = new Car(g.parts, g.chassis, g.newCarName); }

  getJunk(place: Sym | string): PropList { const p = typeof place === "string" ? sym(place) : place; let j = this.junk.get<PropList>(p); if (!(j instanceof PropList)) { j = new PropList(); this.junk.set(p, j); } return j; }

  private masterOf(id: number) { const m = this.g.parts.get(id)?.master; return m && m > 0 ? m : id; }

  removeJunkPart(from: Sym | 0, partId: number) {
    partId = this.masterOf(partId);
    if (!from) {
      for (const pile of this.junk.values()) if (pile instanceof PropList && pile.delete(partId)) return;
      console.warn("(RemoveJunk/User) Part not found:", partId);
    } else this.getJunk(from).delete(partId);
  }

  addJunkPart(to: Sym | string, partId: number, extra?: LValue) {
    const toSym = typeof to === "string" ? sym(to) : to;
    const jp = this.g.junkPiles;
    if (extra === undefined && toSym === sym("yard")) return this.addYardPart(toSym, partId);
    if (extra !== undefined && extra !== null) { const j = this.getJunk(toSym); j.delete(partId); j.add(partId, extra); return; }
    let target: Sym | 0 = toSym;
    if (toSym === sym("RandomPile")) { target = jp.getRandomPile(); if (!target) { console.warn("All piles are full!"); return; } }
    if (jp.checkFull(target)) return;
    const j = this.getJunk(target); j.delete(partId);
    j.add(partId, jp.setPartPosition(target, partId));
  }

  private addYardPart(where: Sym, partId: number) {
    const jp = this.g.junkPiles;
    if (jp.checkFull(where)) {
      const first = this.getJunk(where).keys()[0] as number;
      this.removeJunkPart(where, first);
      this.addJunkPart("RandomPile", first);
    }
    const j = this.getJunk(where); j.delete(partId);
    j.add(partId, jp.setPartPosition(where, partId));
  }

  /** Repair saves damaged by earlier versions: duplicate parts and positions outside the screen. */
  repairJunk() {
    const jp = this.g.junkPiles;
    for (const [place, pile] of this.junk.entries) {
      if (!(pile instanceof PropList)) continue;
      const seen = new Set<unknown>();
      pile.entries = pile.entries.filter(([id]) => !seen.has(id) && !!seen.add(id));
      for (const e of pile.entries) {
        const p = e[1];
        if (p instanceof Point && (p.x < 0 || p.x > 640 || p.y < 0 || p.y > 480)) e[1] = jp.setPartPosition(place as Sym, e[0] as number);
      }
    }
  }

  getJunkPartProp(where: Sym, partId: number) { return this.getJunk(where).get(partId); }
  setJunkPartProp(where: Sym, partId: number, info: LValue) { this.getJunk(where).set(partId, info); }

  initJunk(initial: PropList) { this.junk = initial.clone(); }

  addCompletedMission(id: number) {
    if (!this.completedMissions.includes(id)) this.completedMissions.push(id);
    if (!this.givenMissions.includes(id)) this.givenMissions.push(id);
  }
  isMissionCompleted(id: number) { return this.completedMissions.includes(id); }

  getUserProp(k: string) { return this.ownStuff.has(k) ? this.ownStuff.get(k) : sym("NoProp"); }
  setUserProp(k: string, v: LValue = 0) { this.ownStuff.set(k, v); }

  saveCar(which: number) { if (which > 0) { while (this.saves.length < which) this.saves.push(0); this.saves[which - 1] = this.car.toList(); } }
  loadCar(which: number) { const s = this.saves[which - 1]; if (s) this.car.fromList(s); }
  getSavedCar(which: number): PropList | 0 { return this.saves[which - 1] || 0; }
  changeCarName(which: number, name: string) { const s = this.saves[which - 1]; if (s) s.set("name", name); }

  /** Car.trash: every part except the chassis goes back to a random junk pile; a new empty car. */
  trashCar() {
    const g = this.g;
    for (const id of this.car.parts) {
      const master = g.parts.get(id)?.master;
      const pid = master && master > 0 ? master : id;
      if (pid !== g.chassis) this.addJunkPart("RandomPile", pid);
    }
    this.car.fromList(new PropList().set("parts", [g.chassis]).set("name", this.car.newCarName).set("medals", []));
  }

  /** Where is this part? -> pile symbol, #car, #Gift or 0 */
  findPart(id: number): Sym | 0 {
    for (const [k, pile] of this.junk.entries) if (pile instanceof PropList && pile.has(id)) return k as Sym;
    if (this.car.findPart(id)) return sym("car");
    for (const g of this.gifts) if (Array.isArray(g) && g[0] === id) return sym("Gift");
    return 0;
  }

  toList(): PropList {
    return new PropList()
      .set("userId", this.userId).set("car", this.car.toList()).set("junk", this.junk.clone())
      .set("nrOfBuiltCars", this.nrOfBuiltCars).set("saves", this.saves.map(s => s ? s.clone() : 0))
      .set("completedMissions", [...this.completedMissions]).set("ownStuff", this.ownStuff.clone())
      .set("myLastPile", this.myLastPile).set("gifts", deepClone(this.gifts))
      .set("toYardThroughDoor", this.toYardThroughDoor).set("givenMissions", [...this.givenMissions])
      .set("figgeIsComing", this.figgeIsComing).set("missionIsComing", this.missionIsComing);
  }

  fromList(l: PropList) {
    this.userId = l.get("userId") ?? "";
    const c = l.get("car"); if (c instanceof PropList) this.car.fromList(c);
    const j = l.get("junk"); this.junk = j instanceof PropList ? j.clone() : new PropList();
    this.nrOfBuiltCars = l.get("nrOfBuiltCars") ?? 0;
    this.saves = (l.get<unknown[]>("saves") ?? []).map(s => s instanceof PropList ? s.clone() : 0);
    this.completedMissions = [...(l.get<number[]>("completedMissions") ?? [])];
    const o = l.get("ownStuff"); this.ownStuff = o instanceof PropList ? o.clone() : new PropList();
    this.myLastPile = l.get("myLastPile") ?? 1;
    this.gifts = deepClone(l.get<LValue[]>("gifts") ?? []);
    this.toYardThroughDoor = l.get("toYardThroughDoor") ?? 1;
    this.givenMissions = [...(l.get<number[]>("givenMissions") ?? [])];
    this.figgeIsComing = l.get("figgeIsComing") ?? 0;
    this.missionIsComing = l.get("missionIsComing") ?? 0;
  }
}

const R = (a: number, b: number, c: number, d: number) => new Rect(a, b, c, d);

/** Junk pile geometry & placement (junkPileHandlers). */
export class JunkPiles {
  nrOfPiles = 6;
  figgeBeenHere = 0;
  maxParts: Record<string, number> = { pile1: 50, pile2: 50, pile3: 50, pile4: 50, pile5: 50, pile6: 50, shopfloor: 15, yard: 20 };
  rects: Record<string, Rect[]> = {
    pile1: [R(193, 260, 637, 400), R(291, 193, 637, 263), R(361, 153, 636, 194)],
    pile2: [R(210, 252, 654, 380), R(256, 174, 651, 262), R(365, 120, 667, 188)],
    pile3: [R(150, 281, 639, 380), R(127, 162, 643, 291), R(183, 100, 639, 164)],
    pile4: [R(0, 324, 425, 404), R(3, 174, 425, 325), R(3, 90, 425, 182)],
    pile5: [R(6, 268, 450, 412), R(5, 180, 411, 275), R(0, 100, 303, 189)],
    pile6: [R(0, 275, 400, 390), R(1, 201, 368, 283), R(4, 135, 270, 203)],
    shopfloor: [R(20, 400, 600, 460)],
    yard: [R(290, 400, 580, 445)],
    piledoors: [R(8, 106, 56, 323), R(44, 84, 115, 224), R(111, 41, 151, 103), R(463, 47, 503, 107), R(512, 69, 592, 208), R(572, 94, 637, 312)],
  };

  constructor(private g: MulleGlobals) {}

  getRandomPile(): Sym | 0 {
    const order = Array.from({ length: this.nrOfPiles }, (_, i) => i + 1).sort(() => Math.random() - 0.5);
    for (const n of order) { const s = sym("Pile" + n); if (!this.checkFull(s)) return s; }
    return 0;
  }

  checkFull(which: Sym | 0) {
    if (!which) return true;
    const max = this.maxParts[which.name.toLowerCase()] ?? 50;
    return this.g.user!.getJunk(which).count >= max;
  }

  private partSize(id: number) {
    const p = this.g.parts.get(id);
    const info = p ? this.g.memberInfo(p.junkView) : undefined;
    return { hw: (info?.w ?? 0) / 2, hh: (info?.h ?? 0) / 2 };
  }

  /** Random free spot in a pile, avoiding the pile's door area. */
  setPartPosition(which: Sym, partId: number): Point {
    const key = which.name.toLowerCase();
    const rects = this.rects[key] ?? this.rects.pile1;
    const { hw, hh } = this.partSize(partId);
    const bottom = Math.max(...rects.map(r => r.bottom));
    const pick = () => {
      const r = rects[rnd(rects.length) - 1];
      return { r, x: rnd(r.right - r.left), y: rnd(r.bottom - r.top) };
    };
    if (key === "shopfloor" || key === "yard") { const { r, x, y } = pick(); return new Point(x + r.left, y + r.top); }
    const door = this.rects.piledoors[parseInt(key.slice(-1)) - 1];
    for (let tries = 0; tries < 500; tries++) {
      const { r, x } = pick(); let y = rnd(r.bottom - r.top);
      let p = new Point(x + r.left, y + r.top);
      if (p.y + hh >= bottom) { y -= p.y + hh - bottom; p = new Point(x + r.left, y + r.top); }
      const overlaps = door && p.x + hw > door.left && p.x - hw < door.right && p.y + hh > door.top && p.y - hh < door.bottom;
      if (!overlaps) return p;
    }
    return new Point(rects[0].left + 50, rects[0].top + 30);
  }
}
