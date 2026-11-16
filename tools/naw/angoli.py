import sys,json
from PIL import Image,ImageDraw,ImageFont
m=sys.argv[1]; G=json.load(open('/tmp/nawm/griglia.json'))[m]; OFF=36
im=Image.open(f'/tmp/nawm/{m}_o.png'); d=ImageDraw.Draw(im)
gx,gy=G['gx'],G['gy']
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',26)
for c in range(1,45):
  for r in range(1,45):
    rr=r+(0.5 if c%2==0 else 0)
    x=gx[0]+gx[1]*c+gx[2]*rr; y=gy[0]+gy[1]*c+gy[2]*rr+OFF
    R=gx[1]/1.5; h=gy[2]/2
    d.polygon([(x+R,y),(x+R/2,y+h),(x-R/2,y+h),(x-R,y),(x-R/2,y-h),(x+R/2,y-h)],outline='red',width=3)
    d.text((x-32,y+8),f'{c:02d}{r:02d}',fill='red',font=f)
pts=[tuple(map(int,p.split(','))) for p in sys.argv[2:]]
S=600; out=Image.new('RGB',(S*2,S*((len(pts)+1)//2)))
for i,(x,y) in enumerate(pts):
  out.paste(im.crop((x-S//2,y-S//2,x+S//2,y+S//2)),((i%2)*S,(i//2)*S))
out.save(f'/tmp/nawm/ang_{m}.jpg')
