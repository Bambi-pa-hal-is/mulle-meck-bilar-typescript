import type { Engine } from "../engine/engine.ts";
import { GSound } from "./gsound.ts";
import { gMulle } from "./globals.ts";
import type { GameDir } from "./dir.ts";

/** The original's Lingo globals: gSound, gMulleGlobals, gDir. */
export const G = {
  engine: null as unknown as Engine,
  sound: null as unknown as GSound,
  mulle: gMulle,
  dir: null as GameDir | null,
};

export function initRuntime(engine: Engine) {
  G.engine = engine;
  G.sound = new GSound(engine);
  // Cue points (lip sync) -> spritecuePassed to all sprites + movie CuePassed handler
  engine.onFrame = m => G.sound.update((ch, nr, name) => {
    m.sendAll("spritecuePassed", ch, nr, name);
    for (const b of m.allBehaviors()) if (!b.sprite) (b as any).CuePassed?.(ch, nr, name); // frame scripts
    (m.script as any).cuePassed?.(m, ch, nr, name);
  });
  engine.onMovieChange = () => {
    G.dir?.kill(); G.dir = null;
    gMulle.save();
  };
}

/** Lingo random(n) -> 1..n */
export const random = (n: number) => n < 1 ? 1 : 1 + Math.floor(Math.random() * n);
export const pick = <T>(a: T[]) => a[random(a.length) - 1];
