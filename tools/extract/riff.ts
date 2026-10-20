import { readFileSync } from "node:fs";
import { Reader, decodeText } from "./stream.ts";

export interface ChunkEntry { id: number; fourcc: string; len: number; offset: number; }

export const MemberType: Record<number, string> = {
  0: "null", 1: "bitmap", 2: "filmLoop", 3: "text", 4: "palette", 5: "picture",
  6: "sound", 7: "button", 8: "shape", 9: "movie", 10: "digitalVideo",
  11: "script", 12: "richText", 13: "ole", 14: "transition", 15: "xtra",
};

export interface CastMember {
  id: number;              // member number within its cast
  sectionId: number;
  type: string;
  name: string;
  scriptText: string;
  /** Member flags from the info header (sounds: bit 0x10 set = do not loop). */
  infoFlags: number;
  specific: Buffer;
  children: Map<string, number[]>; // fourcc -> section ids (BITD, STXT, snd ...)
}

export interface Cast {
  name: string;
  minMember: number;
  members: CastMember[];
}

/** A Director 5/6 RIFX (big-endian) or XFIR (little-endian) file. */
export class DirectorFile {
  r: Reader;
  little: boolean;
  kind: string;
  chunks: ChunkEntry[] = [];
  /** child sectionId -> {parent, fourcc} */
  keys: { child: number; parent: number; fourcc: string }[] = [];
  casts: Cast[] = [];
  /** Cast libraries in castLib-number order (from MCsL). */
  castLibs: { name: string; path: string; min: number; id: number }[] = [];

  constructor(public path: string) {
    const buf = readFileSync(path);
    const magic = buf.toString("latin1", 0, 4);
    this.little = magic === "XFIR";
    if (magic !== "RIFX" && magic !== "XFIR") throw new Error(`${path}: not a Director file (${magic})`);
    this.r = new Reader(buf, this.little);
    this.r.seek(8);
    this.kind = this.r.fourcc();
    this.readMap();
    this.readKeys();
    this.readCasts();
  }

  private readMap() {
    const r = this.r;
    if (r.fourcc() !== "imap") throw new Error("no imap");
    r.u32(); r.u32();
    const mmapOff = r.u32();
    r.seek(mmapOff);
    if (r.fourcc() !== "mmap") throw new Error("no mmap");
    r.u32();
    const headerLen = r.u16(), entryLen = r.u16();
    r.i32(); const used = r.i32();
    r.seek(mmapOff + 8 + headerLen);
    for (let i = 0; i < used; i++) {
      const p = r.pos;
      const fourcc = r.fourcc(), len = r.u32(), offset = r.u32();
      this.chunks.push({ id: i, fourcc, len, offset });
      r.seek(p + entryLen);
    }
  }

  /** Raw chunk payload (excluding 8-byte header). */
  data(id: number): Buffer {
    const c = this.chunks[id];
    return this.r.buf.subarray(c.offset + 8, c.offset + 8 + c.len);
  }

  reader(id: number, little = this.little) { return new Reader(this.data(id), little); }

  findAll(fourcc: string) { return this.chunks.filter(c => c.fourcc === fourcc); }
  first(fourcc: string) { return this.chunks.find(c => c.fourcc === fourcc); }

  private readKeys() {
    const k = this.first("KEY*");
    if (!k) return;
    const r = this.reader(k.id);
    r.u16(); r.u16(); r.u32(); const used = r.u32();
    for (let i = 0; i < used; i++) {
      const child = r.i32(), parent = r.i32(), fourcc = r.fourcc();
      this.keys.push({ child, parent, fourcc });
    }
  }

  childrenOf(parent: number) {
    const m = new Map<string, number[]>();
    for (const k of this.keys) if (k.parent === parent) {
      if (!m.has(k.fourcc)) m.set(k.fourcc, []);
      m.get(k.fourcc)!.push(k.child);
    }
    return m;
  }

  private readCasts() {
    // Cast list (MCsL) gives names / member ranges for multi-cast movies.
    const castNames: { name: string; path: string; min: number; id: number }[] = [];
    this.castLibs = castNames;
    const mcsl = this.first("MCsL");
    if (mcsl) {
      const r = this.reader(mcsl.id, false);
      const dataOffset = r.u32(); r.u16(); const castCount = r.u16(); const itemsPerCast = r.u16(); r.u16();
      r.seek(dataOffset);
      const offTableLen = r.u16();
      const offs: number[] = []; for (let i = 0; i < offTableLen; i++) offs.push(r.u32());
      const itemsLen = r.u32(); const base = r.pos;
      const item = (i: number) => {
        const s = base + offs[i], e = i + 1 < offs.length ? base + offs[i + 1] : base + itemsLen;
        return r.buf.subarray(s, e);
      };
      for (let c = 0; c < castCount; c++) {
        const nameB = item(c * itemsPerCast + 1);
        const name = nameB.length ? decodeText(nameB.subarray(1, 1 + nameB[0])) : "";
        const pathB = item(c * itemsPerCast + 2);
        const path = pathB.length ? decodeText(pathB.subarray(1, 1 + pathB[0])) : "";
        const rng = item(c * itemsPerCast + 3);
        const min = rng.length >= 4 ? rng.readUInt16BE(0) : 1;
        const id = rng.length >= 12 ? rng.readUInt32BE(8) : 1024 + c;
        castNames.push({ name, path, min, id });
      }
    }
    // Every CAS* chunk is a member table; owner (KEY*) is the cast id.
    for (const cas of this.findAll("CAS*")) {
      const owner = this.keys.find(k => k.child === cas.id && k.fourcc === "CAS*")?.parent ?? 1024;
      const info = castNames.find(c => c.id === owner);
      let min = this.kind === "MC95" ? 1 : info?.min ?? 1; // external casts are always numbered from 1
      // the internal cast's first member number comes from the movie config (MCsL has no range for it)
      if ((!info || owner === 1024) && this.kind !== "MC95") {
        const drcf = this.first("DRCF") ?? this.first("VWCF");
        // config: [len u16][fileVersion u16][movie rect 8][castArrayStart i16][castArrayEnd i16]
        if (drcf) { const d = this.reader(drcf.id, false); d.seek(12); min = d.i16() || 1; }
      }
      const r = this.reader(cas.id, false);
      const cast: Cast = { name: info?.name ?? "Internal", minMember: min, members: [] };
      for (let i = 0; i < cas.len / 4; i++) {
        const sid = r.i32();
        if (sid <= 0) continue;
        const m = this.readMember(sid, min + i);
        if (m) cast.members.push(m);
      }
      this.casts.push(cast);
    }
  }

  private readMember(sectionId: number, id: number): CastMember | null {
    const c = this.chunks[sectionId];
    if (!c || c.fourcc !== "CASt") return null;
    const r = this.reader(sectionId, false); // CASt is always big-endian
    const type = r.u32(), infoLen = r.u32(), specLen = r.u32();
    const info = r.bytes(infoLen);
    const specific = r.bytes(specLen);
    let name = "", scriptText = "", infoFlags = 0;
    if (infoLen >= 20) {
      const ir = new Reader(info, false);
      const dataOffset = ir.u32();
      ir.seek(12); infoFlags = ir.u32();
      ir.seek(dataOffset);
      const n = ir.u16();
      const offs: number[] = []; for (let i = 0; i < n; i++) offs.push(ir.u32());
      const itemsLen = ir.u32(); const base = ir.pos;
      const item = (i: number) => i < n ? info.subarray(base + offs[i], i + 1 < n ? base + offs[i + 1] : base + itemsLen) : Buffer.alloc(0);
      scriptText = decodeText(item(0));
      const nb = item(1);
      if (nb.length) name = decodeText(nb.subarray(1, 1 + nb[0]));
    }
    return { id, sectionId, type: MemberType[type] ?? `type${type}`, name, scriptText, infoFlags, specific, children: this.childrenOf(sectionId) };
  }
}
