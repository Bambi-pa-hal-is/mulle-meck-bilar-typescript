import { Reader } from "./stream.ts";

export interface Pcm { rate: number; channels: number; bits: number; data: Buffer; /* little-endian, unsigned for 8-bit */ }

/** Decode a Mac 'snd ' resource (format 1 or 2, standard or extended header). */
export function decodeMacSnd(buf: Buffer): Pcm | null {
  const r = new Reader(buf, false);
  const format = r.u16();
  if (format === 1) {
    const nfmt = r.u16();
    r.skip(nfmt * 6);
  } else if (format === 2) r.u16();
  else return null;
  const ncmd = r.u16();
  let hdr = -1;
  for (let i = 0; i < ncmd; i++) {
    const cmd = r.u16() & 0x7fff; r.u16(); const p2 = r.u32();
    if (cmd === 0x51 || cmd === 0x50) hdr = p2; // bufferCmd / soundCmd
  }
  if (hdr < 0) return null;
  r.seek(hdr);
  r.u32();
  const lenOrCh = r.u32();
  const rate = Math.round(r.u32() / 65536);
  r.u32(); r.u32();
  const encode = r.u8(); r.u8();
  if (encode === 0) {
    return { rate, channels: 1, bits: 8, data: Buffer.from(r.bytes(Math.min(lenOrCh, buf.length - r.pos))) };
  }
  if (encode === 0xff) {
    const channels = lenOrCh;
    const frames = r.u32();
    r.skip(10 + 4 + 4 + 4);
    const bits = r.u16();
    r.skip(14);
    const n = Math.min(frames * channels * (bits / 8), buf.length - r.pos);
    const data = Buffer.from(r.bytes(n));
    if (bits === 16) for (let i = 0; i + 1 < data.length; i += 2) { const a = data[i]; data[i] = data[i + 1]; data[i + 1] = a; }
    return { rate, channels, bits, data };
  }
  return null; // compressed (MACE/IMA) – not expected here
}

export function toWav(p: Pcm): Buffer {
  const h = Buffer.alloc(44);
  const block = p.channels * p.bits / 8;
  h.write("RIFF", 0); h.writeUInt32LE(36 + p.data.length, 4); h.write("WAVE", 8);
  h.write("fmt ", 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(p.channels, 22);
  h.writeUInt32LE(p.rate, 24); h.writeUInt32LE(p.rate * block, 28); h.writeUInt16LE(block, 32); h.writeUInt16LE(p.bits, 34);
  h.write("data", 36); h.writeUInt32LE(p.data.length, 40);
  return Buffer.concat([h, p.data]);
}
