/**
 * The driving world: a grid of map tiles ("worldDa HoodDB"), each map with an image, a topology
 * grid and a list of objects ("map<N>DB", "object<N>DB" in CDDATA).
 */
import { PropList, Point, Sym, sym, type LValue } from "../engine/lingo.ts";
import { gMulle } from "./globals.ts";

const S = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
const pt = (v: LValue | undefined) => v instanceof Point ? v : Array.isArray(v) ? new Point(v[0] as number, v[1] as number) : new Point(0, 0);

export interface MapData { id: number; objects: [number, Point, PropList][]; image: string; topology: string; }

export interface ObjectData {
  id: number; type: string; inner: number; outer: number; custom: string; dirResource: string;
  sounds: string[]; frameList: PropList; setWhenDone: PropList; checkFor: PropList; ifFound: string;
  spriteInfo: PropList;
}

export class World {
  id = "";
  map: number[][] = [];
  startMap = new Point(1, 1);
  currentMap = new Point(1, 1);
  startCoordinate = new Point(0, 0);
  startDirection = 1;
  /** Random destinations: object id -> the map coordinate it appears on this time. */
  rDests = new Map<number, Point>();
  allRDests = new Map<number, Point[]>();
  enteredObjectId = 0;

  load(worldId: string) {
    const l = gMulle.dbValue(`world${worldId}DB`);
    if (!(l instanceof PropList)) throw new Error(`World ${worldId} not found`);
    this.id = l.get("WorldId");
    this.map = l.get("map");
    this.startMap = pt(l.get("StartMap"));
    this.currentMap = this.startMap.clone();
    this.startCoordinate = pt(l.get("StartCoordinate"));
    this.startDirection = l.get("StartDirection");
  }

  startInfo() {
    return new PropList().set("map", this.startMap.clone()).set("coordinate", this.startCoordinate.clone())
      .set("direction", this.startDirection).set("fuel", sym("Full"));
  }

  mapIdAt(p: Point) { return this.map[p.y - 1]?.[p.x - 1]; }
  currentMapId() { return this.mapIdAt(this.currentMap); }

  /** getNewMapId: map id at (relative/absolute) grid position; moves there unless justCheck. */
  newMapId(p: Point, mode: "Relational" | "Absolute", justCheck = false): number | null {
    const target = mode === "Relational" ? new Point(p.x + this.currentMap.x, p.y + this.currentMap.y) : p;
    const id = this.mapIdAt(target);
    if (id === undefined) return null;
    if (!justCheck) this.currentMap = target;
    return id;
  }

  /** Find on which maps each random destination may appear. */
  calcRandomDestinations() {
    this.allRDests.clear();
    this.map.forEach((row, y) => row.forEach((mapId, x) => {
      for (const [objId] of loadMap(mapId)?.objects ?? []) {
        if (loadObject(objId)?.type.toLowerCase() !== "rdest") continue;
        const list = this.allRDests.get(objId) ?? [];
        list.push(new Point(x + 1, y + 1));
        this.allRDests.set(objId, list);
      }
    }));
  }
  randomizeDestinations() {
    this.rDests.clear();
    for (const [id, maps] of this.allRDests) this.rDests.set(id, maps[Math.floor(Math.random() * maps.length)]);
  }
}

const mapCache = new Map<number, MapData | null>();
export function loadMap(id: number): MapData | null {
  if (mapCache.has(id)) return mapCache.get(id)!;
  const l = gMulle.dbValue(`map${id}DB`);
  let m: MapData | null = null;
  if (l instanceof PropList) {
    const objs = (l.get<LValue[]>("objects") ?? []).map(o => {
      const a = o as LValue[];
      return [a[0] as number, pt(a[1]), a[2] instanceof PropList ? a[2] : new PropList()] as [number, Point, PropList];
    });
    m = { id, objects: objs, image: l.get("MapImage") ?? "", topology: l.get("Topology") ?? "" };
  }
  mapCache.set(id, m);
  return m;
}

const objCache = new Map<number, ObjectData | null>();
export function loadObject(id: number): ObjectData | null {
  if (objCache.has(id)) return objCache.get(id)!;
  const l = gMulle.dbValue(`object${id}DB`);
  let o: ObjectData | null = null;
  if (l instanceof PropList) {
    const pl = (v: unknown) => v instanceof PropList ? v : new PropList();
    const si = l.get("SpriteInfo");
    o = {
      id, type: S(l.get("type")), inner: l.get("InnerRadius") ?? 0, outer: l.get("OuterRadius") ?? 0,
      custom: l.get("CustomObject") || "", dirResource: l.get("DirResource") || "",
      sounds: (l.get<string[]>("Sounds") ?? []).filter(s => typeof s === "string"),
      frameList: pl(l.get("FrameList")), setWhenDone: pl(l.get("SetWhenDone")), checkFor: pl(l.get("CheckFor")),
      ifFound: S(l.get("IfFound")) || "None",
      spriteInfo: si instanceof PropList ? si : new PropList().set("Under", 1),
    };
  }
  objCache.set(id, o);
  return o;
}

/** Topology grid of a map: 316 x 198 bytes. >= 240 blocked; high nibble = terrain, low = altitude. */
export function loadTopology(name: string): Uint8Array {
  const a = gMulle.memberInfo(name)?.base64, b = gMulle.memberInfo(name + "-2")?.base64;
  const bin = (s?: string) => s ? Uint8Array.from(atob(s), c => c.charCodeAt(0)) : new Uint8Array(0);
  const p1 = bin(a), p2 = bin(b);
  const out = new Uint8Array(p1.length + p2.length); out.set(p1); out.set(p2, p1.length);
  return out;
}

export { pt, S };
