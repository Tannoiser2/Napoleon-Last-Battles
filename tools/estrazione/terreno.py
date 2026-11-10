import json,sys,numpy as np
sys.path.insert(0,'/home/claude/src/est')
from hexgeo import *
from PIL import Image
from scipy import ndimage
m=sys.argv[1]
A=np.asarray(Image.open(f'map_{m}.jpg').convert('RGB')).astype(int)
H,W=A.shape[:2]
r,g,b=A[...,0],A[...,1],A[...,2]
road=(r-b>45)&(r<170)&(g<128)&(r>70)&(g<r-20)&(r+g+b<330)
crest=(r>165)&(g>115)&(g<200)&(b<125)&(r-b>75)
water=(b>r+50)&(b>140)
town=(b>r+12)&(g>r-5)&(b<225)&(r>60)&(r<200)&~water&~((b>r+50)&(b>140))
forest=(g>r+5)&(g>b+15)&(g>90)
margin=(r>150)&(r<215)&(g>110)&(g<178)&(b>75)&(b<145)&(r-b>45)&(r-b<100)&(g<r-20)
marsh=(g>=r-25)&(g>b+60)&(r>140)&(g>150)&~forest   # tratteggio verde chiaro
crest=ndimage.binary_opening(crest,structure=np.ones((5,5)))
crt=(r>220)&(g>170)&(b<90)
# componenti stradali: lunghe = strada, corte = tratti di sentiero
road_all=road.copy()
road=road&~ndimage.binary_dilation(crest,iterations=6)
roadc=ndimage.binary_closing(road,structure=np.ones((5,5)))
lab,n=ndimage.label(roadc,structure=np.ones((3,3)))
sizes=ndimage.sum(road,lab,range(n+1))
sl=ndimage.find_objects(lab)
ext=np.zeros(n+1)
for i,s in enumerate(sl,1):
  if s: ext[i]=max(s[0].stop-s[0].start,s[1].stop-s[1].start)
longc=np.zeros(n+1,bool); longc[1:]=ext[1:]>110
roadL=longc[lab]&roadc
roadLall2=ndimage.binary_closing(longc[lab]&road_all|longc[lab]&roadc,structure=np.ones((9,9)))
roadLall=ndimage.binary_dilation(roadL,iterations=2)|(ndimage.binary_dilation(roadL,iterations=40)&road_all)
dash=roadc&~roadL&(ext[lab]>12)&(ext[lab]<=110)
dashC=ndimage.binary_closing(dash,structure=np.ones((15,15)))
dashC2=ndimage.binary_closing(dash,structure=np.ones((31,31)))
EXCL=json.load(open('escludi.json')).get(m,[])
def escluso(x,y): return any(a<=x<=c and b2<=y<=d for a,b2,c,d in EXCL)
def disk(x,y,rad):
  x,y=int(x),int(y); yy,xx=np.ogrid[-rad:rad+1,-rad:rad+1]; mk=xx*xx+yy*yy<=rad*rad
  y0,y1,x0,x1=y-rad,y+rad+1,x-rad,x+rad+1
  if y0<0 or x0<0 or y1>H or x1>W: return None
  return (slice(y0,y1),slice(x0,x1)),mk
import os
RIV=np.load(f'fiume_{m}.npy') if os.path.exists(f'fiume_{m}.npy') else None
hexes={}
for c in range(1,30):
  for rr in range(1,35):
    x,y=centro(m,c,rr); d=disk(x,y,50)
    if d is None or escluso(x,y): continue
    s,mk=d
    f=lambda M: M[s][mk].mean()
    fm,ff,fw,ft,fma,fc=f(margin),f(forest),f(water),f(town),f(marsh),f(crt)
    if fm>0.45 or fc>0.25: continue
    t='aperto'
    if fw>0.45: t='lago'
    elif ff>0.40: t='bosco'
    elif ft>0.025: t='citta'
    elif fma>0.06: t='palude'
    hexes[f'{c:02d}{rr:02d}']=dict(t=t,f=[round(fm,2),round(ff,2),round(fw,2),round(ft,3),round(fma,3)])
def band(p,q,w):
  # pixel lungo il segmento p-q (parte centrale) entro w px
  p=np.array(p);q=np.array(q);pts=[]
  for t in np.linspace(0.15,0.85,15):
    pts.append(p+(q-p)*t)
  d=(q-p)/np.linalg.norm(q-p); nrm=np.array([-d[1],d[0]])
  res=[]
  for pt in pts:
    row=[]
    for o in range(-w,w+1,2):
      x,y=(pt+nrm*o).astype(int)
      row.append((y,x) if 0<=x<W and 0<=y<H else None)
    res.append(row)
  return res
def frac(M,bd,any_=True):
  vals=[]
  for row in bd:
    v=[M[y,x] for y,x in [p for p in row if p]]
    vals.append(any(v) if any_ else (np.mean(v) if v else 0))
  return float(np.mean(vals))
from skimage.morphology import skeletonize
# etichetta di esagono per ogni pixel (centro più vicino)
cen=[];keys=[]
for k in hexes:
  c,rr=int(k[:2]),int(k[2:]); cen.append(centro(m,c,rr)); keys.append(k)
from scipy.spatial import cKDTree
tr=cKDTree(np.array(cen))
def passaggi(M,minlen):
  sk=skeletonize(M)
  ys,xs=np.nonzero(sk)
  if len(xs)==0: return {}
  d,lab=tr.query(np.stack([xs,ys],1))
  lab=np.where(d<95,lab,-1)
  cnt=np.bincount(lab[lab>=0],minlength=len(keys))
  L=np.full(M.shape,-1,np.int32); L[ys,xs]=lab
  out={}
  Hh,Ww=L.shape
  for dy,dx in ((0,1),(1,0),(1,1),(1,-1)):
    if dx>=0:
      a=L[0:Hh-dy,0:Ww-dx]; b=L[dy:Hh,dx:Ww]
    else:
      a=L[0:Hh-dy,-dx:Ww]; b=L[dy:Hh,0:Ww+dx]
    msk=(a>=0)&(b>=0)&(a!=b)
    for p,q in zip(a[msk],b[msk]):
      if cnt[p]>=minlen and cnt[q]>=minlen:
        kk=tuple(sorted((keys[p],keys[q]))); out[kk]=out.get(kk,0)+1
  return out
PR=passaggi(roadLall2,18)
PT=passaggi(dashC2,14)
sk_=skeletonize(roadLall2);print('sk',sk_.sum(),'keys',len(keys));print('passaggi',len(PR),len(PT),roadLall2.sum(),dashC2.sum())
VIC={0:[(1,0),(1,1)],1:[(1,-1),(1,0)]}
lati={}
for k in hexes:
  c,rr=int(k[:2]),int(k[2:])
  # vicini: verso est e sud (per non duplicare): (c,r+1),(c+1,..)
  par=c%2
  nb=[(c,rr+1),(c+1,rr) if par==1 else (c+1,rr+1),(c+1,rr-1) if par==1 else (c+1,rr)]
  for c2,r2 in nb:
    k2=f'{c2:02d}{r2:02d}'
    if k2 not in hexes: continue
    p1=np.array(centro(m,c,rr));p2=np.array(centro(m,c2,r2))
    mid=(p1+p2)/2; d=p2-p1; L=np.linalg.norm(d); u=d/L; nrm=np.array([-u[1],u[0]])
    half=L/np.sqrt(3)/2  # meta' lato
    a=mid+nrm*half; bq=mid-nrm*half
    bd8=band(a,bq,8); bd4=band(a,bq,4); bd14=band(a,bq,14)
    wat=frac(water,bd8); watT=frac(water,bd14,False)
    cr=frac(crest,bd8)
    # attraversamento: punto sul lato con strada e strada su entrambi i lati (+-10 px)
    def cross(M,soglia):
      ok=0;n=0
      for t in np.linspace(0.08,0.92,24):
        pt=p1+(p2-p1)*t; n+=1
        hit=False
        for k in range(-16,17,2):
          x,y=(pt+nrm*k).astype(int)
          if 0<=x<W and 0<=y<H and M[y,x]: hit=True;break
        ok+=hit
      return ok/n>=soglia
    cr_here=cr>0.45
    kk=tuple(sorted((k,k2))); rd=kk in PR; tr=(not rd) and kk in PT
    e={}
    if wat>0.55:
      e['acqua']=round(watT,2)
      if RIV is not None and frac(RIV,bd8)>0.5: e['fiume']=1
    if cr>0.45: e['cresta']=1
    if rd: e['strada']=1
    elif tr: e['sentiero']=1
    if e: lati[k+'-'+k2]=e
json.dump(dict(hexes=hexes,lati=lati),open(f'terreno_{m}.json','w'))
import collections
print(m,len(hexes),collections.Counter(h['t'] for h in hexes.values()),len(lati),collections.Counter(tuple(sorted(e)) for e in lati.values()))
