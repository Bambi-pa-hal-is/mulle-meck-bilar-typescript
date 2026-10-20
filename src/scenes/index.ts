import type { Engine } from "../engine/engine.ts";
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { registerCommon } from "./common.ts";
import { registerYard } from "./m04_yard.ts";
import { registerGarage } from "./m03_garage.ts";
import { registerJunkyard } from "./m02_junkyard.ts";
import { registerAlbum } from "./m06_album.ts";
import { registerDriving } from "./m05_driving.ts";
import { registerDestinations } from "./m8x_destinations.ts";
import { registerIntro } from "./m10_intro.ts";
import { registerMisc } from "./m_misc.ts";
import { registerScrapyard } from "./m66_scrapyard.ts";

/** Registers all re-implemented movies and scripts. */
export function registerAll(engine: Engine) {
  registerCommon();
  registerYard(engine);
  registerGarage(engine);
  registerJunkyard(engine);
  registerAlbum(engine);
  registerDriving(engine);
  registerDestinations(engine);
  registerIntro(engine);
  registerMisc(engine);
  registerScrapyard(engine);
  // Not yet ported (00 cast) – inert placeholders so the score loads cleanly.
  for (const n of ["MemoryControlBH"]) registerBehavior(n, class extends Behavior {});
}
