import sys
from PIL import Image
m=sys.argv[1]; nx,ny=int(sys.argv[2]),int(sys.argv[3]); sc=float(sys.argv[4]) if len(sys.argv)>4 else 0.5
im=Image.open(f'/tmp/nawt/ter_{m}.jpg'); W,H=im.size
for j in range(ny):
  for i in range(nx):
    x0=i*W//nx-60; y0=j*H//ny-60
    c=im.crop((max(0,x0),max(0,y0),min(W,(i+1)*W//nx+60),min(H,(j+1)*H//ny+60)))
    c.resize((int(c.width*sc),int(c.height*sc))).save(f'/tmp/nawt/t_{m}_{j}{i}.jpg',quality=80)
