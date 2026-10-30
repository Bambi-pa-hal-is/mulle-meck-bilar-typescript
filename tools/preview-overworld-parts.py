import json
from pathlib import Path
from PIL import Image,ImageDraw
base=Path('public/assets/overworld-parts')
parts=json.loads((base/'manifest.json').read_text())
w=960;cellw=120;cellh=126
im=Image.new('RGB',(w,((len(parts)+7)//8)*cellh),'#e4dfd2')
d=ImageDraw.Draw(im)
for i,p in enumerate(parts):
 src=Image.open(base/p['file']).convert('RGBA');src.thumbnail((108,98))
 x=i%8*cellw;y=i//8*cellh
 im.paste(src,(x+(cellw-src.width)//2,y+24+(98-src.height)//2),src)
 d.text((x+6,y+5),f'{p["id"]} - {p["kind"]}',fill='#343a32')
Path('docs').mkdir(exist_ok=True)
im.save('docs/overworld-parts.png')
print(f'Previewed {len(parts)} sprites')
