import { loadAudio, type MemberRef } from "./assets.ts";

interface Channel {
  src: AudioBufferSourceNode | null; member: MemberRef | null; startedAt: number; ends: number; token: number;
  cues: { time: number; name: string }[]; nextCue: number;
}

/** Seconds on the wall clock. Sound timing uses this rather than the AudioContext clock, so game logic
 * that waits for sounds keeps working even if the browser keeps audio suspended (no user gesture yet). */
const now = () => performance.now() / 1000;

/** Director-style numbered sound channels on top of Web Audio. */
export class SoundSystem {
  ctx = new AudioContext();
  master = this.ctx.createGain();
  private channels = new Map<number, Channel>();

  constructor() { this.master.connect(this.ctx.destination); }

  resume() { return this.ctx.resume(); }

  private ch(n: number): Channel {
    let c = this.channels.get(n);
    if (!c) { c = { src: null, member: null, startedAt: 0, ends: 0, token: 0, cues: [], nextCue: 0 }; this.channels.set(n, c); }
    return c;
  }

  /** puppetSound / sound playFile. Resolves when playback ends (or is stopped). */
  async play(channel: number, ref: MemberRef, loop = false): Promise<void> {
    const c = this.ch(channel);
    this.stop(channel);
    const token = ++c.token;
    c.member = ref;
    c.ends = Infinity; // busy while loading
    const buf = await loadAudio(this.ctx, ref);
    if (token !== c.token) return;
    const src = this.ctx.createBufferSource();
    src.buffer = buf; src.loop = loop; src.connect(this.master);
    c.src = src; c.startedAt = now(); c.ends = loop ? Infinity : now() + buf.duration;
    // speech/animation cue points (loop markers are ignored)
    c.cues = (ref.info.cues ?? []).filter(q => q.name && !/loop/i.test(q.name) && q.time <= buf.duration * 1000);
    c.nextCue = 0;
    src.start();
    return new Promise(res => { src.onended = () => { if (c.token === token) { c.src = null; c.member = null; c.ends = 0; } res(); }; });
  }

  stop(channel: number) {
    const c = this.channels.get(channel);
    if (!c) return;
    c.token++;
    if (c.src) { try { c.src.onended = null; c.src.stop(); } catch { /* already stopped */ } }
    c.src = null; c.member = null; c.ends = 0;
  }

  stopAll() { for (const n of this.channels.keys()) this.stop(n); }

  /** soundBusy(channel) */
  busy(channel: number) { const c = this.channels.get(channel); return !!c && c.ends > now(); }

  /** Elapsed milliseconds of the sound in a channel (for cue points / lip sync). */
  elapsedMs(channel: number) { const c = this.channels.get(channel); return c?.src ? (now() - c.startedAt) * 1000 : -1; }
  memberIn(channel: number) { return this.channels.get(channel)?.member ?? null; }

  /** Fire passed cue points: callback(channel, cueNumber, cueName). Call once per frame. */
  updateCues(onCue: (channel: number, nr: number, name: string) => void) {
    for (const [ch, c] of this.channels) {
      if (!c.src || !c.cues.length) continue;
      const t = (now() - c.startedAt) * 1000;
      while (c.nextCue < c.cues.length && c.cues[c.nextCue].time <= t) { const q = c.cues[c.nextCue++]; onCue(ch, c.nextCue, q.name); }
    }
  }

  /** First channel number >= from that is free. */
  freeChannel(from = 1, to = 8) { for (let i = from; i <= to; i++) if (!this.busy(i)) return i; return to; }
}
