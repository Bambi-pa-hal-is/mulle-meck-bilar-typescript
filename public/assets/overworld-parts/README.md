# Generated overworld car parts

These transparent sprites were generated individually with the built-in `image_gen` tool.
`prompts.json` records the complete prompt for every design. Original workshop artwork
and cast manifests are unchanged.

`manifest.json` maps the original part's `UseView` name to the generated sprite and
its mounting category. Shared morph artwork is reused for front/rear variants; the
renderer reads the mounted variant's snap points to choose its axle or body position.

The new artwork covers the chassis, body fronts, cabins, cargo bodies, wheels/tracks,
seats and bumpers, including optional designs. Engines, horns, controls, tanks,
exhausts and small roof fittings are intentionally omitted.

The game composes the mounted parts at runtime and caches each of the 16 headings
and five terrain inclinations. Headings rotate overhead artwork; these are not
separately painted perspective animation frames. One composite remains on the
original car sprite channel, preserving foreground/background map ordering.

To repack new generated originals (requires Pillow):

    python tools/build-overworld-assets.py path/to/generated-sources.json

The source list contains `{ "id": 1, "path": "path/to/original.png", "prompt": "..." }`
for each design in `tools/overworld-part-catalog.json`. Packing crops transparent margins
and downsizes to a maximum of 192 pixels, preserving the alpha channel.

