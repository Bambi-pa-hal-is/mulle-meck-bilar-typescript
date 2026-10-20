import { PropList, Point, sym, type Sym, type LValue } from "../engine/lingo.ts";
import type { PartsDB } from "./parts.ts";

export const CAR_PROPS = ["Weight", "break", "Durability", "Grip", "Steering", "acceleration", "speed", "Strength",
  "FuelConsumption", "FuelVolume", "ElectricConsumption", "ElectricVolume", "Comfort", "FunnyFactor", "Horn",
  "ExhaustPipe", "Lamps", "LoadCapacity", "EngineType", "HornType", "Pedals"] as const;
export type CarProp = typeof CAR_PROPS[number];

/** Mulle's car: list of mounted parts plus free snap points and derived properties. */
export class Car {
  parts: number[] = [];
  name = "";
  medals: number[] = [];
  cacheList = new PropList();
  props: Record<string, number> = {};
  /** Parts the car had when it last drove out of the yard (a changed car counts as a newly built one). */
  enterParts: number[] = [];
  /** Free snap points on the car. */
  snapPoints: Sym[] = [];
  /** snap -> [layers, offset] */
  snapOffsets = new Map<Sym, [number[], number[]]>();
  /** Sprite offsets inside the 35 reserved car sprites (DrawCar). */
  readonly chassisSPOffset = 7;
  readonly driverLayer = 18;

  constructor(private db: PartsDB, public chassis = 1, public newCarName = "Ny bil") { this.resetProps(); }

  private resetProps() { this.props = Object.fromEntries(CAR_PROPS.map(p => [p, 0])); }

  addPart(id: number) {
    this.parts.push(id);
    const part = this.db.get(id); if (!part) return;
    for (const c of part.covers) this.snapPoints = this.snapPoints.filter(s => s !== c);
    for (const [snap, layers, offset] of part.newPoints) {
      this.snapPoints.push(snap);
      this.snapOffsets.set(snap, [layers, offset]);
    }
  }

  removePart(id: number) {
    const i = this.parts.indexOf(id); if (i < 0) return;
    this.parts.splice(i, 1);
    const part = this.db.get(id); if (!part) return;
    for (const c of part.covers) this.snapPoints.push(c);
    for (const [snap] of part.newPoints) {
      this.snapPoints = this.snapPoints.filter(s => s !== snap);
      this.snapOffsets.delete(snap);
    }
  }

  /** All given snap points free on the car? */
  areTheseFree(list: Sym[]) { return list.length > 0 && list.every(s => this.snapPoints.includes(s)); }

  snapInfo(snap: Sym) { return this.snapOffsets.get(snap); }

  /** Is the part (or one of its morph variants) on the car? */
  findPart(id: number) {
    const part = this.db.get(id); if (!part) return false;
    const ids = part.isMorphPart() ? part.morphsTo as number[] : [id];
    return ids.some(x => this.parts.includes(x));
  }

  rebuild() { const p = [...this.parts]; this.parts = []; this.snapPoints = []; this.snapOffsets.clear(); for (const id of p) this.addPart(id); }

  clear() { this.cacheList = new PropList(); this.name = this.newCarName; this.medals = []; }

  addMedal(id: number) { if (!this.medals.includes(id)) this.medals.push(id); }
  hasMedal(id: number) { return this.medals.includes(id); }

  getCacheProp(k: string) { return this.cacheList.has(k) ? this.cacheList.get(k) : sym("NoProp"); }
  setCacheProp(k: string, v: LValue = 0) { this.cacheList.set(k, v); }
  deleteCacheProp(k: string) { this.cacheList.delete(k); }

  /** Recalculate car properties from all parts (sum / max / min rules from the original). */
  updateProperties() {
    this.resetProps();
    const P = this.props;
    for (const id of this.parts) {
      const part = this.db.get(id); if (!part) continue;
      const v = (k: string) => part.prop(k);
      for (const k of ["Weight", "break", "Grip", "Strength", "FuelConsumption", "FuelVolume", "ElectricConsumption",
        "ElectricVolume", "Comfort", "FunnyFactor", "LoadCapacity"]) P[k] += v(k);
      for (const k of ["Steering", "acceleration", "speed", "EngineType", "HornType"]) P[k] = Math.max(P[k], v(k));
      for (const k of ["Horn", "ExhaustPipe", "Lamps", "Pedals"]) if (v(k)) P[k] = 1;
      // Durability: the weakest non-zero part decides
      const d = part.props.get("Durability");
      if (typeof d === "number" && (d < P.Durability || (d !== 0 && P.Durability === 0))) P.Durability = d;
    }
  }
  prop(k: CarProp | string) { return this.props[k] ?? 0; }

  toList(): PropList {
    return new PropList().set("parts", [...this.parts]).set("name", this.name).set("medals", [...this.medals]).set("cacheList", this.cacheList.clone());
  }

  fromList(l: PropList) {
    let parts = (l.get<number[]>("parts") ?? []).slice();
    if (!parts.length || parts[0] === 0) parts = [this.chassis];
    this.name = l.get("name") ?? "";
    this.medals = (l.get<number[]>("medals") ?? []).slice();
    const c = l.get("cacheList"); this.cacheList = c instanceof PropList ? c.clone() : new PropList();
    this.parts = []; this.snapPoints = []; this.snapOffsets.clear();
    for (const id of parts) this.addPart(id);
    this.updateProperties();
  }
}

export const pt = (a: LValue): Point => a instanceof Point ? a : Array.isArray(a) ? new Point(a[0] as number, a[1] as number) : new Point(0, 0);
