# Centri degli esagoni: griglia affine per regione + correzione locale dai numeri letti (media pesata dei residui)
import sys,json,random,numpy as np
OFF=36
REGIONI={'jena':[(1,20),(21,40)]}
def rr(c,r): return r+(0.5 if c%2==0 else 0)
def fit(P):
  random.seed(3); best=[]
  for it in range(5000):
    a,b=random.sample(P,2)
    if a[0]==b[0] or rr(a[0],a[1])==rr(b[0],b[1]): continue
    dx=(b[2]-a[2])/(b[0]-a[0]); dy=(b[3]-a[3])/(rr(b[0],b[1])-rr(a[0],a[1]))
    if not (110<dx<128 and 128<dy<146): continue
    ax=a[2]-a[0]*dx; ay=a[3]-rr(a[0],a[1])*dy
    inl=[p for p in P if abs(p[2]-ax-p[0]*dx)<25 and abs(p[3]-ay-rr(p[0],p[1])*dy)<25]
    if len(inl)>len(best): best=inl
  X=np.array([[1,p[0],rr(p[0],p[1])] for p in best])
  gx=np.linalg.lstsq(X,np.array([p[2] for p in best]),rcond=None)[0]
  gy=np.linalg.lstsq(X,np.array([p[3] for p in best]),rcond=None)[0]
  return gx,gy
def centri(m,cmax=40,rmax=40):
  pts=json.load(open(f'/tmp/nawm/num_{m}.json'))
  P=[(int(t[:2]),int(t[2:]),x,y+OFF) for t,x,y in pts if 1<=int(t[:2])<=cmax and 1<=int(t[2:])<=rmax]
  out={}
  for (r0,r1) in REGIONI.get(m,[(1,rmax)]):
    Q=[p for p in P if r0<=p[1]<=r1]
    gx,gy=fit(Q)
    pr=lambda c,r:(gx@[1,c,rr(c,r)],gy@[1,c,rr(c,r)])
    # tieni solo i numeri coerenti con i vicini
    res=[(p[0],p[1],p[2]-pr(p[0],p[1])[0],p[3]-pr(p[0],p[1])[1]) for p in Q]
    res=[q for q in res if abs(q[2])<35 and abs(q[3])<35]
    buoni=[]
    for q in res:
      vic=[v for v in res if v is not q and abs(v[0]-q[0])<=4 and abs(v[1]-q[1])<=4]
      if vic:
        mx=np.median([v[2] for v in vic]); my=np.median([v[3] for v in vic])
        if abs(q[2]-mx)>12 or abs(q[3]-my)>12: continue
      buoni.append(q)
    print(m,(r0,r1),len(Q),len(buoni),gx.round(2),gy.round(2))
    for c in range(1,cmax+1):
      for r in range(r0,r1+1):
        x,y=pr(c,r)
        w=np.array([np.exp(-((q[0]-c)**2+(rr(q[0],q[1])-rr(c,r))**2)/6.0) for q in buoni])
        if w.sum()>1e-3:
          k=w.sum()/(w.sum()+0.3)
          x+=k*(w@[q[2] for q in buoni])/w.sum(); y+=k*(w@[q[3] for q in buoni])/w.sum()
        out['%02d%02d'%(c,r)]=(round(float(x),1),round(float(y),1))
  json.dump({'centri':out,'dx':float(gx[1]),'dy':float(gy[2])},open(f'/tmp/nawm/centri_{m}.json','w'))
for m in sys.argv[1:]: centri(m)
