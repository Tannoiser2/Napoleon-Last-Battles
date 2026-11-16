# Napoleon at War: orienta le mappe del modulo TTS e adatta la griglia esagonale leggendo i numeri degli esagoni.
import sys,json,re,random,pytesseract,numpy as np
from PIL import Image
SRC='/tmp/nawm'
RUOTA={'marengo':True,'jena':True,'wagram':False,'nazioni':False}
SC=3
def ocr(im,soglia):
  g=im.convert('L'); W,H=g.size; out=[]; T=900
  for y0 in range(0,H,T-120):
    for x0 in range(0,W,T-120):
      x1,y1=min(W,x0+T),min(H,y0+T)
      c=g.crop((x0,y0,x1,y1)).resize(((x1-x0)*SC,(y1-y0)*SC)).point(lambda v:0 if v<soglia else 255)
      d=pytesseract.image_to_data(c,config='--psm 11 --oem 1 -c tessedit_char_whitelist=0123456789',output_type=pytesseract.Output.DICT)
      for i,t in enumerate(d['text']):
        t=t.strip()
        if re.fullmatch(r'\d{4}',t) and float(d['conf'][i])>40:
          out.append((t,x0+(d['left'][i]+d['width'][i]/2)/SC,y0+(d['top'][i]+d['height'][i]/2)/SC))
  return out
def rr(c,r): return r+(0.5 if c%2==0 else 0)
def fit(pts):
  P=[(int(t[:2]),int(t[2:]),x,y) for t,x,y in pts if 1<=int(t[:2])<=60 and 1<=int(t[2:])<=60]
  random.seed(2); best=[]
  for it in range(4000):
    a,b=random.sample(P,2)
    if a[0]==b[0] or rr(a[0],a[1])==rr(b[0],b[1]): continue
    dx=(b[2]-a[2])/(b[0]-a[0]); dy=(b[3]-a[3])/(rr(b[0],b[1])-rr(a[0],a[1]))
    if not (80<dx<160 and 100<dy<180): continue
    ax=a[2]-a[0]*dx; ay=a[3]-rr(a[0],a[1])*dy
    inl=[p for p in P if abs(p[2]-ax-p[0]*dx)<15 and abs(p[3]-ay-rr(p[0],p[1])*dy)<15]
    if len(inl)>len(best): best=inl
  X=np.array([[1,p[0],rr(p[0],p[1])] for p in best])
  gx=np.linalg.lstsq(X,np.array([p[2] for p in best]),rcond=None)[0]
  gy=np.linalg.lstsq(X,np.array([p[3] for p in best]),rcond=None)[0]
  res=np.abs(np.c_[X@gx-[p[2] for p in best],X@gy-[p[3] for p in best]])
  print(len(P),len(best),gx.round(3),gy.round(3),res.max(0).round(1),res.mean(0).round(2))
  return {'gx':list(gx),'gy':list(gy)}
G={}
for m in (sys.argv[1:] or RUOTA):
  im=Image.open(f'{SRC}/{m}.png').convert('RGB')
  if RUOTA[m]: im=im.rotate(-90,expand=True)
  im.save(f'{SRC}/{m}_o.png')
  pts=[]
  for sg in (135,165,190):
    for p in ocr(im,sg):
      if not any(q[0]==p[0] and abs(q[1]-p[1])<20 and abs(q[2]-p[2])<20 for q in pts): pts.append(p)
  json.dump(pts,open(f'{SRC}/num_{m}.json','w'))
  print(m,im.size,len(pts)); G[m]=fit(pts)
json.dump(G,open(f'{SRC}/griglia.json','w'),indent=1)
