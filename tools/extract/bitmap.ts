import { Reader } from "./stream.ts";

export type RGB = [number, number, number];

/** Mac OS system 8-bit palette (Director builtin -1). Index 0 = white, 255 = black. */
export function macSystemPalette(): RGB[] {
  const p: RGB[] = [];
  const steps = [0xff, 0xcc, 0x99, 0x66, 0x33, 0x00];
  for (const r of steps) for (const g of steps) for (const b of steps) p.push([r, g, b]);
  p.pop(); // black goes last
  const ramp = [0xee, 0xdd, 0xbb, 0xaa, 0x88, 0x77, 0x55, 0x44, 0x22, 0x11];
  for (const v of ramp) p.push([v, 0, 0]);
  for (const v of ramp) p.push([0, v, 0]);
  for (const v of ramp) p.push([0, 0, v]);
  for (const v of ramp) p.push([v, v, v]);
  p.push([0, 0, 0]);
  return p;
}

/** CLUT chunk: 6 bytes per entry (16-bit r,g,b big-endian). */
export function readClut(buf: Buffer): RGB[] {
  const p: RGB[] = [];
  for (let i = 0; i + 6 <= buf.length; i += 6) p.push([buf[i], buf[i + 2], buf[i + 4]]);
  return p;
}

export interface BitmapInfo {
  width: number; height: number; pitch: number;
  left: number; top: number;
  regX: number; regY: number; // relative to image top-left
  bpp: number; clutCastLib: number; clutId: number;
}

export function parseBitmapSpecific(spec: Buffer): BitmapInfo {
  const r = new Reader(spec, false);
  const pitch = r.u16() & 0x3fff;
  const top = r.i16(), left = r.i16(), bottom = r.i16(), right = r.i16();
  r.skip(8); // bounding rect / misc
  const regY = r.i16(), regX = r.i16();
  let bpp = 1, clutCastLib = -1, clutId = 0;
  if (spec.length >= 28) { r.u8(); bpp = r.u8(); clutCastLib = r.i16(); clutId = r.i16(); }
  return { width: right - left, height: bottom - top, pitch, left, top, regX: regX - left, regY: regY - top, bpp, clutCastLib, clutId };
}

/** Decode BITD to an RGBA buffer. Returns index buffer too for 8-bit images. */
export function decodeBitd(data: Buffer, info: BitmapInfo, palette: RGB[], transparentWhite = true): { rgba: Buffer; indices?: Uint8Array } {
  const { width: w, height: h, bpp } = info;
  // Rows are padded to even byte width (bits rounded to 16).
  const rowBytes = bpp === 32 ? w * 4 : Math.ceil((w * bpp) / 16) * 2;
  const total = rowBytes * h;
  let raw: Uint8Array;
  if (data.length >= total) raw = data;
  else {
    raw = new Uint8Array(total);
    let o = 0, i = 0;
    while (i < data.length && o < total) {
      const n = data[i++];
      if (n >= 0x80) { const v = data[i++]; for (let k = 0; k < 257 - n; k++) raw[o++] = v; }
      else { for (let k = 0; k <= n; k++) raw[o++] = data[i++]; }
    }
  }
  const rgba = Buffer.alloc(w * h * 4);
  let indices: Uint8Array | undefined;
  if (bpp === 8) indices = new Uint8Array(w * h);
  for (let y = 0; y < h; y++) {
    const row = y * rowBytes;
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 4;
      let c: RGB;
      if (bpp === 8) { const idx = raw[row + x]; indices![y * w + x] = idx; c = palette[idx] ?? [0, 0, 0]; }
      else if (bpp === 1) { const bit = (raw[row + (x >> 3)] >> (7 - (x & 7))) & 1; c = bit ? [0, 0, 0] : [255, 255, 255]; }
      else if (bpp === 4) { const v = (raw[row + (x >> 1)] >> (x & 1 ? 0 : 4)) & 15; c = palette[v] ?? [0, 0, 0]; }
      else if (bpp === 16) { // planar hi/lo bytes per row, 1-5-5-5
        const v = (raw[row + x] << 8) | raw[row + w + x];
        c = [((v >> 10) & 31) * 255 / 31 | 0, ((v >> 5) & 31) * 255 / 31 | 0, (v & 31) * 255 / 31 | 0];
      } else { // 32: planar A R G B
        c = [raw[row + w + x], raw[row + 2 * w + x], raw[row + 3 * w + x]];
      }
      const white = c[0] === 255 && c[1] === 255 && c[2] === 255;
      rgba[o] = c[0]; rgba[o + 1] = c[1]; rgba[o + 2] = c[2]; rgba[o + 3] = white && transparentWhite ? 0 : 255;
    }
  }
  return { rgba, indices };
}
