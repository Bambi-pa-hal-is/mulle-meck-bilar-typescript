# Mulle Meck bygger bilar – TypeScript/browser rebuild

A from-scratch TypeScript re-implementation of the classic Swedish children's game
**Mulle Meck bygger bilar** (originally a Macromedia Director 6 game), playable in a
modern browser on a 640×480 canvas.

It consists of two parts:

- **Extractor** (`tools/extract`) – a Node/TypeScript parser for Director `.dir`/`.cst`
  files. It dumps bitmaps (PNG, with registration points), sounds (WAV + cue points),
  texts, frame labels, score data and Lingo scripts into `public/assets/` and `re/`.
- **Game** (`src`) – a small Director-like engine (movie/score playback, sprites, inks,
  behaviors, sound channels, cursor) plus the game logic and one module per original
  movie/scene (yard, workshop, junkyard, driving, destinations, album, …).

## Getting started

Requires [Node.js](https://nodejs.org/) (a recent LTS).

```sh
npm install
npm run dev
```

Open http://localhost:5173/ and click to start. The start screen also lets you enable
the extra material (Figge's scrapyard world and extra car parts).

### Regenerating assets

`public/assets/` and `re/` are generated from the original game files. To regenerate
them you need your own copy of the game, decompiled to `../Decompiled DXR CXT`
(relative to this folder), then run:

```sh
npm run extract
```

## Scripts

| Command | What it does |
|---|---|
| `npm run dev` | Start the Vite dev server |
| `npm run build` | Typecheck and build a static site into `dist/` |
| `npx vite preview` | Serve the built `dist/` folder |
| `npm run extract` | Regenerate `public/assets/` and `re/` from the original game files |
| `npm run typecheck` | Run the TypeScript compiler without emitting |

## Development tips

- Jump straight to a scene with URL parameters, e.g. `?movie=04` (yard), `?movie=03`
  (workshop), optionally `&frame=<label>` and `&user=<name>`.
- In the browser console, `engine` exposes the current movie/sprites/frame and `G` the
  game state (`G.mulle.user`).
- Saves are stored in `localStorage` under `mullebil.*`; clear them to start fresh.

## Project layout

```
tools/extract/   Director file parser -> public/assets, re/
public/assets/   Extracted assets, one folder per movie/cast (manifest.json, PNG, WAV)
re/              Lingo source dumped from the original movies (reference only)
src/engine/      Stage, sprites, cast loader, audio, input, scene manager, saves
src/game/        Shared game state: parts, cars, user, missions, driving world
src/scenes/      One module per original movie (m02_junkyard, m03_garage, m04_yard, ...)
```

See [PLAN.md](PLAN.md) for the architecture and phases, and
[NEXT_STEPS.md](NEXT_STEPS.md) for current status and remaining work.

## Disclaimer

This is an unofficial fan project for preservation and learning. *Mulle Meck* and the
original game's graphics, sounds and texts belong to their respective rights holders.
