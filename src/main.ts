import { Engine } from "./engine/engine.ts";
import { registerAll } from "./scenes/index.ts";
import { initRuntime, G } from "./game/runtime.ts";
import { makeCar } from "./game/cardriving.ts";
import { loadCast, preloadCast } from "./engine/assets.ts";

const canvas = document.getElementById("stage") as HTMLCanvasElement;
const engine = new Engine(canvas);
initRuntime(engine);
registerAll(engine);
(window as any).engine = engine; // debugging aid
(window as any).G = G;
(window as any).makeCar = makeCar; // console helper for testing: makeCar("Good")

// Start movie can be overridden with ?movie=04&frame=label&user=Name
const q = new URLSearchParams(location.search);
const start = document.getElementById("start")!;
const startText = document.getElementById("startText")!;

// Extra material (the original's Plugins folder) is optional – the player chooses on the start screen.
const EXTRAS_KEY = "mullebil.extras";
const extras = localStorage.getItem(EXTRAS_KEY) === "1";
const extrasBox = document.getElementById("extrasBox") as HTMLInputElement;
extrasBox.checked = extras;
document.getElementById("extras")!.addEventListener("click", e => e.stopPropagation());
extrasBox.addEventListener("change", () => {
  localStorage.setItem(EXTRAS_KEY, extrasBox.checked ? "1" : "0");
  location.reload(); // the databases are merged at load time
});

// Load the game data, then preload the shared casts (characters, parts, maps) so play is smooth.
startText.textContent = "Laddar… 0%";
const ready = (async () => {
  await G.mulle.load(extras);
  engine.extraLibs = G.mulle.pluginLibs;
  const libs = await Promise.all(["00", "CDDATA", ...(extras ? ["PLUGIN"] : [])].map(loadCast));
  const counts = libs.map(() => [0, 1]);
  const show = () => { const d = counts.reduce((a, c) => a + c[0], 0), t = counts.reduce((a, c) => a + c[1], 0); startText.textContent = `Laddar… ${Math.floor((100 * d) / t)}%`; };
  await Promise.all(libs.map((lib, i) => preloadCast(lib, (d, t) => { counts[i] = [d, t]; show(); })));
  startText.textContent = "Klicka för att starta";
})();

start.addEventListener("click", async () => {
  await ready;
  // Normally the game starts on the name screen (movie 10). For testing, ?movie=XX starts elsewhere
  // and logs in as ?user=Name (default "Spelare").
  // The original starts with the Levande Böcker logo (LBSTART), which leads to the name screen (10).
  const startMovie = q.get("movie") ?? "LBSTART";
  if (startMovie !== "10" && startMovie !== "LBSTART") G.mulle.login(q.get("user") ?? "Spelare");
  start.remove();
  void engine.sound.resume(); // never block on audio unlock (may stay pending without a user gesture)
  engine.run();
  await engine.goMovie(startMovie, q.get("frame") ?? 1);
}, { once: true });
