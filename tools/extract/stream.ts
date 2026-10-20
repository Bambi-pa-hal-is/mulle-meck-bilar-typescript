/** Binary reader with switchable endianness. */
export class Reader {
  pos = 0;
  constructor(public buf: Buffer, public little = false) {}

  get length() { return this.buf.length; }
  get eof() { return this.pos >= this.buf.length; }
  seek(p: number) { this.pos = p; return this; }
  skip(n: number) { this.pos += n; return this; }

  u8() { return this.buf.readUInt8(this.pos++); }
  i8() { return this.buf.readInt8(this.pos++); }
  u16() { const v = this.little ? this.buf.readUInt16LE(this.pos) : this.buf.readUInt16BE(this.pos); this.pos += 2; return v; }
  i16() { const v = this.little ? this.buf.readInt16LE(this.pos) : this.buf.readInt16BE(this.pos); this.pos += 2; return v; }
  u32() { const v = this.little ? this.buf.readUInt32LE(this.pos) : this.buf.readUInt32BE(this.pos); this.pos += 4; return v; }
  i32() { const v = this.little ? this.buf.readInt32LE(this.pos) : this.buf.readInt32BE(this.pos); this.pos += 4; return v; }
  f64() { const v = this.little ? this.buf.readDoubleLE(this.pos) : this.buf.readDoubleBE(this.pos); this.pos += 8; return v; }
  bytes(n: number) { const b = this.buf.subarray(this.pos, this.pos + n); this.pos += n; return b; }

  /** FourCC – stored reversed in little-endian (XFIR) files. */
  fourcc() {
    const b = this.bytes(4);
    const s = String.fromCharCode(b[0], b[1], b[2], b[3]);
    return this.little ? s.split("").reverse().join("") : s;
  }

  pstr() { const n = this.u8(); return decodeText(this.bytes(n)); }
  sub(n: number, little = this.little) { return new Reader(this.bytes(n), little); }
}

// Windows-1252 decoder (game was authored for Windows; Swedish å ä ö)
const td = new TextDecoder("windows-1252");
export function decodeText(b: Uint8Array) { return td.decode(b).replace(/\r\n?/g, "\n"); }
