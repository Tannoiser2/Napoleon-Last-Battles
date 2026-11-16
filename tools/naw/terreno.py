# Napoleon at War: terreno degli esagoni e dei lati dalle immagini delle mappe
import sys,json,math,numpy as np
from PIL import Image
from scipy import ndimage
from maschere import maschere
m=sys.argv[1]
C=json.load(open(f'/tmp/nawm/centri_{m}.json')); CE=C['centri']; DX=C['dx']; DY=C['dy']
A=np.asarray(Image.open(f'/tmp/nawm/{m}_o.png').convert('RGB')).astype(int)
H,W=A.shape[:2]
M=maschere(A)
acqua=ndimage.binary_opening(M['acqua'],iterations=1)
nero=M['nero']&~ndimage.binary_dilation(acqua,iterations=7)
nero=ndimage.binary_opening(nero,iterations=1)
ocra=M['ocra']
solido=ndimage.binary_opening(ocra,structure=np.ones((31,31))) if m in ('marengo','nazioni') else np.zeros_like(ocra)   # terreno accidentato (macchie piene)
linea=ndimage.binary_opening(ocra&~ndimage.binary_dilation(solido,iterations=4),structure=np.ones((7,7)))  # linea del pendio
punti=ocra&~ndimage.binary_dilation(linea,iterations=3)&~ndimage.binary_dilation(solido,iterations=3)
verde=ndimage.binary_opening(M['verde'],iterations=1)
casa=M['casa']|(M['grigio']&ndimage.binary_dilation(M['casa'],iterations=6))
grigio=M['grigio']
nero=nero&~ndimage.binary_dilation(verde,iterations=4)
strada_px=nero&~ndimage.binary_dilation(acqua,iterations=10)
if m!='marengo':
  lb,nn=ndimage.label(ndimage.binary_closing(strada_px,iterations=2),structure=np.ones((3,3)))
  sl=ndimage.find_objects(lb); ok=np.zeros(nn+1,bool)
  for i,q in enumerate(sl,1):
    if q and max(q[0].stop-q[0].start,q[1].stop-q[1].start)>90: ok[i]=True
  strada_px=strada_px&ok[lb]
nero_d=ndimage.binary_dilation(strada_px,iterations=2)
acqua_d=ndimage.binary_dilation(acqua,iterations=9)
nero_stretto=(A.sum(2)<140)&((A.max(2)-A.min(2))<30)
bordo=ndimage.binary_dilation(acqua,iterations=7)&~ndimage.binary_dilation(acqua,iterations=1)
rap=ndimage.uniform_filter((nero_stretto&bordo).astype(np.float32),71)/np.maximum(ndimage.uniform_filter(bordo.astype(np.float32),71),1e-3)
fiume_px=acqua&(rap>0.35)
def disco(x,y,rad):
  yy,xx=np.ogrid[-rad:rad+1,-rad:rad+1]; mk=xx*xx+yy*yy<=rad*rad
  x,y=int(x),int(y)
  if x-rad<0 or y-rad<0 or x+rad+1>W or y+rad+1>H: return None
  return (slice(y-rad,y+rad+1),slice(x-rad,x+rad+1)),mk
def frazione(mask,x,y,rad):
  d=disco(x,y,rad)
  if d is None: return 0.0
  s,mk=d; return float(mask[s][mk].mean())
def vicini(k):
  c,r=int(k[:2]),int(k[2:])
  d=[[0,-1],[1,-1],[1,0],[0,1],[-1,0],[-1,-1]] if c%2==1 else [[0,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
  return ['%02d%02d'%(c+a,r+b) for a,b in d]
ESCL=json.load(open('/home/claude/napoleon-last-battles/tools/naw/escludi.json')).get(m,[])
def escluso(x,y): return any(a<=x<=c and b<=y<=d for a,b,c,d in ESCL)
es={}
R=int(DY*0.36)
for k,(x,y) in CE.items():
  if not (0<x<W and 0<y<H) or escluso(x,y): continue
  g=frazione(grigio&~casa,x,y,R); b=frazione(M['beige']|verde|ocra|acqua|casa,x,y,R)
  if g>0.45 or b<0.35: continue
  t='aperto'
  fa=frazione(acqua,x,y,R); fv=frazione(verde,x,y,R); fs=frazione(solido,x,y,R); fc=frazione(casa,x,y,R)
  if fa>0.55: t='lago'
  elif fc>0.10: t='citta'
  elif fv>0.30: t='bosco'
  elif fs>0.30: t='accidentato'
  es[k]={'t':t,'x':round(x,1),'y':round(y,1),'f':[round(fa,2),round(fc,2),round(fv,2),round(fs,2)]}
linea_d=ndimage.binary_dilation(linea,iterations=14)
ndimage_solido_d=ndimage.binary_dilation(solido,iterations=14)
ndimage_fiume_d=ndimage.binary_dilation(fiume_px,iterations=9)
strada_lunga=M['nero']&~ndimage.binary_dilation(acqua,iterations=4)&~ndimage.binary_dilation(verde,iterations=4)
lb2,nn2=ndimage.label(ndimage.binary_closing(strada_lunga,iterations=3 if m!='marengo' else 6),structure=np.ones((3,3)))
sl2=ndimage.find_objects(lb2); ok2=np.zeros(nn2+1,bool)
for i,q in enumerate(sl2,1):
  if q and max(q[0].stop-q[0].start,q[1].stop-q[1].start)>(110 if m!='marengo' else 60): ok2[i]=True
strada_lunga=strada_lunga&ok2[lb2]
nero_raw_d=ndimage.binary_dilation(M['nero']&~ndimage.binary_dilation(verde,iterations=4),iterations=14)
lati={}
nbs=[]
sl=[]
SOGLIA_TRATT=float(sys.argv[2]) if len(sys.argv)>2 else 0.004
def frac_pts(mask,pts): return float(np.mean([mask[min(H-1,max(0,int(yy))),min(W-1,max(0,int(xx)))] for xx,yy in pts]))
for k in es:
  for v in vicini(k):
    if v not in es or k>v: continue
    (x1,y1),(x2,y2)=CE[k],CE[v]
    mx,my=(x1+x2)/2,(y1+y2)/2
    vx,vy=x2-x1,y2-y1; L=math.hypot(vx,vy); px,py=-vy/L,vx/L; half=DX/1.5/2
    lungo=[(mx+px*half*t,my+py*half*t) for t in np.linspace(-0.8,0.8,17)]
    cod=''
    if frac_pts(acqua_d,lungo)>0.6:
      cod='F' if frac_pts(ndimage_fiume_d,lungo)>0.5 else 'T'
    mezzo=[(mx+px*half*t,my+py*half*t) for t in np.linspace(-0.7,0.7,29)]
    cc=[(x1+vx*t,y1+vy*t) for t in np.linspace(0.1,0.9,25)]
    if frac_pts(nero_d,mezzo)>0 and frazione(strada_px,x1,y1,int(R*0.9))>0.004 and frazione(strada_px,x2,y2,int(R*0.9))>0.004:
      if cod: cod+='p'
      cod+='r'
    if frac_pts(linea_d,lungo)>0.5 and frac_pts(ndimage_solido_d,lungo)<0.3:
      pa=frazione(punti,x1+vx*0.28,y1+vy*0.28,int(R*0.55)); pb=frazione(punti,x1+vx*0.72,y1+vy*0.72,int(R*0.55))
      sl.append((k,v,round(pa,3),round(pb,3)))
      if max(pa,pb)>=SOGLIA_TRATT: cod+='ca' if pa>=pb else 'cb'
    if cod: lati[k+'-'+v]=cod
json.dump(sl,open(f'/tmp/nawm/pendii_{m}.json','w'))
json.dump({'esagoni':es,'lati':lati,'dx':DX,'dy':DY,'larg':W,'alt':H},open(f'/tmp/nawm/terreno_{m}.json','w'))
import collections
print(m,len(es),collections.Counter(e['t'] for e in es.values()),collections.Counter(lati.values()))
# immagine di controllo
from PIL import ImageDraw
im=Image.open(f'/tmp/nawm/{m}_o.png').convert('RGB'); d=ImageDraw.Draw(im)
COL={'aperto':None,'citta':(255,0,255),'bosco':(0,160,0),'accidentato':(160,80,0),'lago':(0,0,255)}
for k,e in es.items():
  x,y=e['x'],e['y']
  if COL[e['t']]: d.ellipse([x-22,y-22,x+22,y+22],fill=COL[e['t']])
  else: d.ellipse([x-6,y-6,x+6,y+6],fill=(255,0,0))
for kk,cod in lati.items():
  a,b=kk.split('-'); (x1,y1),(x2,y2)=CE[a],CE[b]; mx,my=(x1+x2)/2,(y1+y2)/2
  if 'r' in cod: d.line([x1,y1,x2,y2],fill=(255,0,0),width=7)
  vx,vy=x2-x1,y2-y1; L=math.hypot(vx,vy); px,py=-vy/L,vx/L; h=DX/3
  if 'F' in cod: d.line([mx-px*h,my-py*h,mx+px*h,my+py*h],fill=(150,0,150),width=16)
  elif 'T' in cod: d.line([mx-px*h,my-py*h,mx+px*h,my+py*h],fill=(255,215,0),width=12)
  if 'p' in cod: d.ellipse([mx-16,my-16,mx+16,my+16],fill=(255,255,255),outline=(0,0,0),width=4)
  if 'c' in cod:
    d.line([mx-px*h,my-py*h,mx+px*h,my+py*h],fill=(255,120,0),width=10)
    lo=(x1,y1) if 'ca' in cod else (x2,y2)
    d.line([mx,my,mx+(lo[0]-mx)*0.4,my+(lo[1]-my)*0.4],fill=(255,120,0),width=8)
im.save(f'/tmp/nawt/ter_{m}.jpg',quality=85)
im.resize((W//3,H//3)).save(f'/tmp/nawt/ter_{m}_s.jpg')
