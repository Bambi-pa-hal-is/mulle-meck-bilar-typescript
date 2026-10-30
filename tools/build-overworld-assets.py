"""Crop transparent padding and pack generated sprites; never invent missing artwork.
Usage: python tools/build-overworld-assets.py path/to/generated-sources.json
Sources: [{"id": 1, "path": "...png", "prompt": "..."}, ...]
"""
import argparse
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'public/assets/overworld-parts'
# Nonstandard large parts keep their distinctive proportions instead of filling a body panel box.
SIZES = {
    17: (16, 22), 31: (18, 20), 36: (16, 20), 37: (16, 20),
    148: (18, 20), 157: (22, 19), 160: (22, 22), 168: (18, 18),
    172: (16, 17), 173: (9, 30), 227: (17, 21), 229: (27, 23), 264: (22, 20),
}


def kind_for(part):
    req = part.get('req', [])
    if part['id'] == 1:
        return 'chassis'
    if part['id'] == 149:
        return 'track'
    if 'b1' in req:
        return 'hood'
    if 'b2' in req:
        return 'cabin'
    if 'b4' in req:
        return 'cargo'
    if 'a11' in req:
        return 'seat'
    if 'a1' in req or 'a13' in req:
        return 'wheel'
    if 'a3' in req:
        return 'frontBumper'
    if 'a18' in req:
        return 'rearBumper'
    raise ValueError(f'Unclassified part: {part}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sources', type=Path)
    parser.add_argument('--partial', action='store_true', help='Pack finished assets for work-in-progress previews')
    args = parser.parse_args()
    sources = {p['id']: p for p in json.loads(args.sources.read_text(encoding='utf-8-sig'))}
    parts = json.loads((ROOT / 'tools/overworld-part-catalog.json').read_text(encoding='utf-8'))
    OUT.mkdir(parents=True, exist_ok=True)
    manifest, prompts = [], []
    for part in parts:
        source = sources.get(part['id'])
        if source is None:
            if args.partial:
                continue
            raise ValueError(f'Missing generated artwork for part {part["id"]}')
        image = Image.open(source['path']).convert('RGBA')
        alpha = image.getchannel('A')
        if alpha.getextrema()[0] == 255:
            raise ValueError(f'Part {part["id"]} is missing transparency')
        box = alpha.point(lambda v: 255 if v > 16 else 0).getbbox()
        if box is None:
            raise ValueError(f'Part {part["id"]} has no visible pixels')
        # Alpha is preserved; only transparent padding and export dimensions change.
        image = image.crop(box)
        image.thumbnail((192, 192), Image.Resampling.LANCZOS)
        name = f'part-{part["id"]}.png'
        image.save(OUT / name, optimize=True)
        manifest.append({'id': part['id'], 'view': part['view'], 'file': name, 'kind': kind_for(part)})
        if part['id'] in SIZES:
            manifest[-1]['width'], manifest[-1]['height'] = SIZES[part['id']]
        if part['id'] == 173:
            manifest[-1]['offsetY'] = 10
        prompts.append({'id': part['id'], 'prompt': source['prompt']})
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (OUT / 'prompts.json').write_text(json.dumps({'tool': 'built-in image_gen', 'transparent_background': True, 'assets': prompts}, indent=2) + '\n', encoding='utf-8')
    print(f'Packed {len(manifest)} transparent sprites ({sum((OUT / p["file"]).stat().st_size for p in manifest):,} bytes)')


if __name__ == '__main__':
    main()

