import type { Sprite } from "./sprite.ts";
import type { Movie } from "./movie.ts";
import { PropList } from "./lingo.ts";

/**
 * Base class for re-implemented Lingo behaviors / frame scripts.
 * Event methods mirror Director: beginSprite, endSprite, prepareFrame, enterFrame,
 * exitFrame, mouseDown, mouseUp, mouseUpOutside, mouseEnter, mouseLeave, mouseWithin.
 */
export class Behavior {
  sprite!: Sprite;       // undefined for frame scripts
  movie!: Movie;
  params = new PropList();
  get spriteNum() { return this.sprite?.num ?? 0; }
  /** Behavior property from score params (#name: value). */
  p<T = any>(name: string, fallback?: T): T { const v = this.params.get(name); return (v === undefined ? fallback : v) as T; }

  beginSprite?(): void;
  endSprite?(): void;
  prepareFrame?(): void;
  enterFrame?(): void;
  exitFrame?(): void;
  mouseDown?(): void;
  mouseUp?(): void;
  mouseUpOutside?(): void;
  mouseEnter?(): void;
  mouseLeave?(): void;
  mouseWithin?(): void;
}

export type BehaviorCtor = new () => Behavior;

/** Script registry: key = script member name (case-insensitive), or "<movie>:<memberNum>" for unnamed scripts. */
const registry = new Map<string, BehaviorCtor>();

export function registerBehavior(key: string, ctor: BehaviorCtor) { registry.set(key.toLowerCase(), ctor); }
export function findBehavior(movieId: string, memberNum: number, name: string, libId: string): BehaviorCtor | undefined {
  return registry.get(`${libId}:${memberNum}`.toLowerCase())
    ?? registry.get(`${movieId}:${memberNum}`.toLowerCase())
    ?? (name ? registry.get(name.toLowerCase()) : undefined);
}

// ---- Common frame scripts used all over the original movies -------------

/** exitFrame: go to the frame (hold on current frame). */
export class HoldFrame extends Behavior { exitFrame() { this.movie.goFrame(this.movie.frame); } }

/** Errors seen in behavior handlers (shown in the console once per handler; the game keeps running). */
export const scriptErrors: string[] = [];
const reported = new Set<string>();
/** Run a behavior handler; an error is logged instead of stopping the game loop. */
export function safeCall(b: object, msg: string, ...args: unknown[]): unknown {
  const fn = (b as any)[msg];
  if (typeof fn !== "function") return undefined;
  try { return fn.apply(b, args); }
  catch (e) {
    const key = `${(b as any).movie?.id ?? "?"}:${b.constructor.name}.${msg}`;
    if (!reported.has(key)) { reported.add(key); scriptErrors.push(`${key}: ${e}`); console.error(`Script error in ${key}`, e); }
    return undefined;
  }
}
