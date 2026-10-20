import { PropList, Point, lingoValue, sym, type LValue, type Sym } from "../engine/lingo.ts";
import type { CastLib } from "../engine/assets.ts";

/** A car part as defined by the "part<N>DB" text members in CDDATA. */
export class Part {
  id = 0;
  master = 0;
  /** Morph variants (ids) – a "morph part" is shown as one of these depending on the car. */
  morphsTo: number[] | 0 = 0;
  description = "";
  junkView = "";
  useView = "";
  useView2 = "";
  offset = new Point(0, 0);
  props = new PropList();
  /** Snap points this part attaches to (#a1 ...), or 0 for the chassis. */
  requires: Sym[] | 0 = 0;
  covers: Sym[] = [];
  /** New snap points this part provides: [snap, [layer1, layer2], [offX, offY]] */
  newPoints: [Sym, number[], number[]][] = [];

  static fromDB(text: string): Part | null {
    const l = lingoValue(text);
    if (!(l instanceof PropList)) return null;
    const p = new Part();
    p.id = l.get("partId");
    p.master = l.get("master") || 0;
    const m = l.get("MorphsTo"); p.morphsTo = Array.isArray(m) ? m as number[] : 0;
    p.description = l.get("description") ?? "";
    p.junkView = l.get("junkView") ?? "";
    p.useView = l.get("UseView") ?? "";
    p.useView2 = l.get("UseView2") ?? "";
    const off = l.get<LValue>("offset");
    if (Array.isArray(off)) p.offset = new Point(off[0] as number, off[1] as number);
    else if (off instanceof Point) p.offset = off;
    const props = l.get("Properties"); if (props instanceof PropList) p.props = props;
    const req = l.get("Requires"); p.requires = Array.isArray(req) ? req as Sym[] : 0;
    const cov = l.get("Covers"); p.covers = Array.isArray(cov) ? cov as Sym[] : [];
    const nw = l.get("new"); p.newPoints = Array.isArray(nw) ? nw as any : [];
    return p;
  }

  isMaster() { return this.master !== 0; }
  isMorphPart() { return Array.isArray(this.morphsTo); }
  isNormalPart() { return this.master === 0 && !this.isMorphPart(); }
  /** Numeric property (#Weight, #Speed ...); missing = 0 like Lingo VOID arithmetic. */
  prop(name: string): number { const v = this.props.get(name); return typeof v === "number" ? v : 0; }
}

export class PartsDB {
  parts = new Map<number, Part>();
  get(id: number) { return this.parts.get(id); }

  load(ids: number[], libs: CastLib[]) {
    for (const id of ids) {
      for (const lib of libs) {
        const info = lib.byName.get(`part${id}db`);
        if (info?.text) { const p = Part.fromDB(info.text); if (p) this.parts.set(id, p); break; }
      }
      if (!this.parts.has(id)) console.warn(`Part${id}DB not found`);
    }
  }
}

export const S = sym;
