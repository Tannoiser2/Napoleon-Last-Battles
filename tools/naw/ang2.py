import sys,json
from PIL import Image,ImageDraw,ImageFont
m=sys.argv[1]; C=json.load(open(f'/tmp/nawm/centri_{m}.json'))
im=Image.open(f'/tmp/nawm/{m}_o.png'); d=ImageDraw.Draw(im)
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',26)
R=C['dx']/1.5; h=C['dy']/2
for k,(x,y) in C['centri'].items():
  d.polygon([(x+R,y),(x+R/2,y+h),(x-R/2,y+h),(x-R,y),(x-R/2,y-h),(x+R/2,y-h)],outline='red',width=3)
  d.text((x-32,y+8),k,fill='red',font=f)
pts=[tuple(map(int,p.split(','))) for p in sys.argv[2:]]
S=600; out=Image.new('RGB',(S*2,S*((len(pts)+1)//2)))
for i,(x,y) in enumerate(pts):
  out.paste(im.crop((x-S//2,y-S//2,x+S//2,y+S//2)),((i%2)*S,(i//2)*S))
out.save(f'/tmp/nawm/ang_{m}.jpg')
