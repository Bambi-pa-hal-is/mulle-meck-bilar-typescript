import type { Engine } from "../engine/engine.ts";
import type { MemberRef } from "../engine/assets.ts";

export type SoundPrio = "BG" | "TRANS" | "EFFECT" | "OPEFFECT";

interface Playing { id: number; ref: MemberRef; }

/**
 * gSound: the game's sound manager. Channel 1 = background, 2 and 3 = effects.
 * play() returns a sound id that can be checked with finished() / stopped with stop().
 */
export class GSound {
  private channels: (Playing | null)[] = [null, null, null, null];
  private newSnd = 1;
  /** Fallback member used by the original when a sound is missing. */
  missing = "20d163v0";

  constructor(private engine: Engine) {}

  private resolve(name: string): MemberRef | null {
    return this.engine.movie?.member(name) ?? null;
  }

  private purge() {
    for (let ch = 1; ch <= 3; ch++) if (this.channels[ch] && !this.engine.sound.busy(ch)) this.channels[ch] = null;
  }

  /** loop: force looping (the original set `the loop of member` from script for e.g. engine sounds). */
  play(name: string, what: SoundPrio = "EFFECT", loop = false): number {
    this.purge();
    let ref = name ? this.resolve(name) : null;
    if (!ref) { if (name) console.warn("Snd:", name); ref = this.resolve(this.missing); if (!ref) return 0; }
    let ch = 0;
    switch (String(what).toUpperCase()) {
      case "BG": ch = 1; break;
      case "TRANS": ch = 1; this.stopAllEffects(); break;
      case "EFFECT": ch = this.channels[3] ? 2 : 3; break;
      case "OPEFFECT": ch = !this.channels[2] ? 2 : !this.channels[3] ? 3 : 0; break;
    }
    if (!ch) return 0;
    const id = ++this.newSnd;
    this.channels[ch] = { id, ref };
    void this.engine.sound.play(ch, ref, loop || !!ref.info.loop);
    return id;
  }

  private chOf(id: number) { for (let ch = 1; ch <= 3; ch++) if (id && this.channels[ch]?.id === id) return ch; return 0; }

  /** Has sound `id` finished playing? */
  finished(id: number) { this.purge(); return !id || !this.chOf(id); }
  getChannel(id: number) { this.purge(); return this.chOf(id); }

  stop(id: number) {
    const ch = this.chOf(id);
    if (ch) { this.engine.sound.stop(ch); this.channels[ch] = null; }
    return 0;
  }
  stopBG() { this.engine.sound.stop(1); this.channels[1] = null; }
  stopAllEffects() { for (const ch of [2, 3]) { this.engine.sound.stop(ch); this.channels[ch] = null; } }

  /** Cue points are tracked by the engine's SoundSystem for all channels (incl. score sounds). */
  update(onCue: (channel: number, nr: number, name: string) => void) { this.engine.sound.updateCues(onCue); }
}
