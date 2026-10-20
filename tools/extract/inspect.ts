// Usage: npx tsx tools/extract/inspect.ts <file> [--members]
import { DirectorFile } from "./riff.ts";

const f = new DirectorFile(process.argv[2]);
const counts: Record<string, number> = {};
for (const c of f.chunks) counts[c.fourcc] = (counts[c.fourcc] ?? 0) + 1;
console.log(f.kind, f.little ? "LE" : "BE", counts);
for (const cast of f.casts) {
  const types: Record<string, number> = {};
  for (const m of cast.members) types[m.type] = (types[m.type] ?? 0) + 1;
  console.log(`cast "${cast.name}" min=${cast.minMember} members=${cast.members.length}`, types);
  if (process.argv.includes("--members"))
    for (const m of cast.members)
      console.log(`  #${m.id} ${m.type} "${m.name}" spec=${m.specific.toString("hex")} children=${[...m.children].map(([k, v]) => k + ":" + v).join(",")}${m.scriptText ? " script=" + m.scriptText.length : ""}`);
}
