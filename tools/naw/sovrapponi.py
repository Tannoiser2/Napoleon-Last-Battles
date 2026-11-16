import sys,json
from PIL import Image,ImageDraw,ImageFont
m=sys.argv[1]; G=json.load(open('/tmp/nawm/griglia.json'))[m]
im=Image.open(f'/tmp/nawm/{m}_o.png'); d=ImageDraw.Draw(im)
gx,gy=G['gx'],G['gy']; OFF=float(sys.argv[2]) if len(sys.argv)>2 else 36
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30)
for c in range(1,45):
  for r in range(1,45):
    rr=r+(0.5 if c%2==0 else 0)
    x=gx[0]+gx[1]*c+gx[2]*rr; y=gy[0]+gy[1]*c+gy[2]*rr+OFF
    if 0<x<im.width and 0<y<im.height:
      R=gx[1]/1.5; h=gy[2]/2
      d.polygon([(x+R,y),(x+R/2,y+h),(x-R/2,y+h),(x-R,y),(x-R/2,y-h),(x+R/2,y-h)],outline='red',width=4)
      d.text((x-35,y+5),f'{c:02d}{r:02d}',fill='red',font=f)
im.resize((im.width//3,im.height//3)).save(f'/tmp/nawm/ov_{m}.jpg')
if len(sys.argv)>3:
  x0,y0,x1,y1=map(int,sys.argv[3].split(',')); im.crop((x0,y0,x1,y1)).save(f'/tmp/nawm/ovc_{m}.jpg')
