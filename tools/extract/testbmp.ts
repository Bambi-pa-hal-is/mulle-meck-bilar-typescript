// Decode a named bitmap and compare with a reference PNG. Usage: testbmp.ts <file> <memberName> [ref.png]
import { writeFileSync, readFileSync } from "node:fs";
import { PNG } from "pngjs";
import { DirectorFile } from "./riff.ts";
import { parseBitmapSpecific, decodeBitd, macSystemPalette } from "./bitmap.ts";

const [file, name, ref] = process.argv.slice(2);
const f = new DirectorFile(file);
const m = f.casts.flatMap(c => c.members).find(m => m.name === name)!;
const info = parseBitmapSpecific(m.specific);
console.log(info);
const bitd = f.data(m.children.get("BITD")![0]);
const { rgba } = decodeBitd(bitd, info, macSystemPalette());
const png = new PNG({ width: info.width, height: info.height });
rgba.copy(png.data);
writeFileSync(process.env.OUT ?? "out.png", PNG.sync.write(png));
if (ref) {
  const r = PNG.sync.read(readFileSync(ref));
  console.log("ref", r.width, r.height);
  let diff = 0;
  for (let i = 0; i < Math.min(r.data.length, rgba.length); i += 4)
    if (r.data[i] !== rgba[i] || r.data[i + 1] !== rgba[i + 1] || r.data[i + 2] !== rgba[i + 2]) diff++;
  console.log("diff pixels", diff, "of", rgba.length / 4);
  for (const i of [0, 1000, 50000]) console.log(i, [...r.data.subarray(i * 4, i * 4 + 4)], [...rgba.subarray(i * 4, i * 4 + 4)]);
}
