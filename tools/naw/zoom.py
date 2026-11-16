# zoom.py mappa nx ny j,i,x,y ... -> riquadri 300x300 dalla sovrapposizione
import sys
from PIL import Image
m=sys.argv[1]; nx,ny=int(sys.argv[2]),int(sys.argv[3])
im=Image.open(f'/tmp/nawt/ter_{m}.jpg'); W,H=im.size
pts=[tuple(map(int,p.split(','))) for p in sys.argv[4:]]
out=Image.new('RGB',(900,300*((len(pts)+2)//3)))
for n,(j,i,x,y) in enumerate(pts):
  X=i*W//nx-40+x*2; Y=j*H//ny-40+y*2
  out.paste(im.crop((X-150,Y-150,X+150,Y+150)),((n%3)*300,(n//3)*300))
out.save('/tmp/nawt/z.jpg')
