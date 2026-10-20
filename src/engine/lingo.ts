/**
 * Lingo value model + literal parser/serializer.
 * The original game stores all of its databases and save data as Lingo list literals, e.g.
 *   [#partId: 1, #offset: [0, 0], #Properties: [#Weight: 4]]
 */

/** Lingo symbol (#name). Interned and case-insensitive like Lingo. */
export class Sym {
  private static table = new Map<string, Sym>();
  private constructor(public readonly name: string) {}
  static of(name: string): Sym {
    const k = name.toLowerCase();
    let s = Sym.table.get(k);
    if (!s) { s = new Sym(name); Sym.table.set(k, s); }
    return s;
  }
  toString() { return "#" + this.name; }
}
export const sym = Sym.of;

export class Point { constructor(public x: number, public y: number) {} clone() { return new Point(this.x, this.y); } }
export class Rect { constructor(public left: number, public top: number, public right: number, public bottom: number) {} }

export type LValue = number | string | Sym | Point | Rect | LValue[] | PropList | null;
type Key = Sym | number | string;

/** Ordered property list ([#a: 1, 5: point(1, 2)]). */
export class PropList {
  entries: [Key, LValue][] = [];
  private idx(k: Key | string) {
    if (typeof k === "string") k = sym(k);
    return this.entries.findIndex(e => e[0] === k);
  }
  /** Get by symbol name ("partId"), Sym or number key. Missing -> undefined (VOID). */
  get<T = any>(k: Key | string): T { const i = this.idx(k); return (i < 0 ? undefined : this.entries[i][1]) as T; }
  has(k: Key | string) { return this.idx(k) >= 0; }
  set(k: Key | string, v: LValue) {
    const i = this.idx(k);
    if (i < 0) this.entries.push([typeof k === "string" ? sym(k) : k, v]); else this.entries[i][1] = v;
    return this;
  }
  add(k: Key | string, v: LValue) { this.entries.push([typeof k === "string" ? sym(k) : k, v]); return this; }
  delete(k: Key | string) { const i = this.idx(k); if (i >= 0) { this.entries.splice(i, 1); return true; } return false; }
  get count() { return this.entries.length; }
  keys() { return this.entries.map(e => e[0]); }
  values() { return this.entries.map(e => e[1]); }
  clone(): PropList { const p = new PropList(); p.entries = this.entries.map(([k, v]) => [k, deepClone(v)]); return p; }
}

export function deepClone<T extends LValue>(v: T): T {
  if (Array.isArray(v)) return v.map(deepClone) as T;
  if (v instanceof PropList) return v.clone() as T;
  if (v instanceof Point) return v.clone() as T;
  if (v instanceof Rect) return new Rect(v.left, v.top, v.right, v.bottom) as T;
  return v;
}

// ---------------------------------------------------------------- parser
export function parseLingo(src: string): LValue {
  let p = 0;
  const ws = () => { while (p < src.length && /\s/.test(src[p])) p++; };
  const err = (m: string) => new Error(`Lingo parse: ${m} at ${p}: ${src.slice(p, p + 30)}`);

  function value(): LValue {
    ws();
    const c = src[p];
    if (c === "[") return list();
    if (c === '"') { const e = src.indexOf('"', p + 1); const s = src.slice(p + 1, e); p = e + 1; return s; }
    if (c === "#") { p++; const m = /^[\w]+/.exec(src.slice(p))!; p += m[0].length; return sym(m[0]); }
    const num = /^-?(\d+\.?\d*|\.\d+)(e-?\d+)?/i.exec(src.slice(p));
    if (num) { p += num[0].length; return Number(num[0]); }
    const id = /^\w+/.exec(src.slice(p));
    if (id) {
      p += id[0].length;
      const w = id[0].toLowerCase();
      if (w === "void") return null;
      if (w === "true") return 1;
      if (w === "false") return 0;
      if (w === "empty") return "";
      if (w === "point" || w === "rect") {
        ws(); if (src[p] !== "(") throw err("expected (");
        p++; const args: number[] = [];
        for (;;) { ws(); if (src[p] === ")") { p++; break; } args.push(value() as number); ws(); if (src[p] === ",") p++; }
        return w === "point" ? new Point(args[0], args[1]) : new Rect(args[0], args[1], args[2], args[3]);
      }
      return sym(id[0]); // bare identifier – treat as symbol
    }
    throw err("unexpected");
  }

  function list(): LValue {
    p++; ws();
    if (src[p] === ":") { p++; ws(); p++; return new PropList(); } // [:]
    if (src[p] === "]") { p++; return []; }
    let arr: LValue[] | null = null; let pl: PropList | null = null;
    for (;;) {
      const v = value(); ws();
      if (src[p] === ":") {
        p++; const val = value();
        pl ??= new PropList(); pl.add(v as Key, val);
      } else { arr ??= []; arr.push(v); }
      ws();
      if (src[p] === ",") { p++; continue; }
      if (src[p] === "]") { p++; break; }
      throw err("expected , or ]");
    }
    return pl ?? arr ?? [];
  }

  const v = value();
  return v;
}

/** Safe wrapper used where the original used value(the text of member ...). */
export function lingoValue(src: string | undefined): LValue {
  if (!src || !src.trim()) return null;
  try { return parseLingo(src); } catch (e) { console.warn(e); return null; }
}

// ---------------------------------------------------------------- serializer
export function toLingo(v: LValue | undefined): string {
  if (v === null || v === undefined) return "VOID";
  if (typeof v === "number") return String(v);
  if (typeof v === "string") return JSON.stringify(v).replace(/\\"/g, "'");
  if (v instanceof Sym) return "#" + v.name;
  if (v instanceof Point) return `point(${v.x}, ${v.y})`;
  if (v instanceof Rect) return `rect(${v.left}, ${v.top}, ${v.right}, ${v.bottom})`;
  if (Array.isArray(v)) return "[" + v.map(toLingo).join(", ") + "]";
  if (v instanceof PropList) {
    if (!v.count) return "[:]";
    return "[" + v.entries.map(([k, x]) => `${typeof k === "string" ? JSON.stringify(k) : toLingo(k as LValue)}: ${toLingo(x)}`).join(", ") + "]";
  }
  return "VOID";
}

/** Lingo truthiness helper: lists/strings are not "true", numbers != 0 are. */
export const truthy = (v: unknown) => typeof v === "number" ? v !== 0 : !!v;
export const isList = (v: unknown): v is LValue[] | PropList => Array.isArray(v) || v instanceof PropList;
