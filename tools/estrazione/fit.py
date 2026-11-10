import json,sys,numpy as np
def fit(m):
  d=json.load(open(f'num_{m}.json'))
  pts=[(int(t[:2]),int(t[2:]),x,y) for t,x,y,c in d]
  best=None
  # RANSAC over pairs
  import itertools,random
  random.seed(1)
  for it in range(3000):
    a,b=random.sample(pts,2)
    if a[0]==b[0] or a[1]==b[1]: continue
    dx=(b[2]-a[2])/(b[0]-a[0])
    if not 110<dx<130: continue
    # y = ay + row*dy + (col%2==0)*dy/2
    ra=a[1]+(0.5 if a[0]%2==0 else 0); rb=b[1]+(0.5 if b[0]%2==0 else 0)
    if ra==rb: continue
    dy=(b[3]-a[3])/(rb-ra)
    if not 125<dy<150: continue
    ax=a[2]-a[0]*dx; ay=a[3]-ra*dy
    inl=[p for p in pts if abs(p[2]-(ax+p[0]*dx))<12 and abs(p[3]-(ay+(p[1]+(0.5 if p[0]%2==0 else 0))*dy))<12]
    if best is None or len(inl)>len(best[0]): best=(inl,)
  inl=best[0]
  A=[];bx=[];by=[]
  X=np.array([[1,p[0]] for p in inl]);ax,dx=np.linalg.lstsq(X,np.array([p[2] for p in inl]),rcond=None)[0]
  Y=np.array([[1,p[1]+(0.5 if p[0]%2==0 else 0)] for p in inl]);ay,dy=np.linalg.lstsq(Y,np.array([p[3] for p in inl]),rcond=None)[0]
  res=[(p[2]-(ax+p[0]*dx),p[3]-(ay+(p[1]+(0.5 if p[0]%2==0 else 0))*dy)) for p in inl]
  print(m,len(pts),len(inl),round(ax,1),round(dx,2),round(ay,1),round(dy,2),np.abs(np.array(res)).max(0))
  return dict(ax=ax,dx=dx,ay=ay,dy=dy)
G={m:fit(m) for m in 'BQWL'}
json.dump(G,open('griglia.json','w'),indent=1)
# affine refinement
def fit2(m,g):
  d=json.load(open(f'num_{m}.json'))
  pts=[(int(t[:2]),int(t[2:]),x,y) for t,x,y,c in d]
  def pr(p,g): 
    r=p[1]+(0.5 if p[0]%2==0 else 0)
    return g['ax']+p[0]*g['dx']+r*g.get('sx',0), g['ay']+r*g['dy']+p[0]*g.get('sy',0)
  inl=[p for p in pts if abs(pr(p,g)[0]-p[2])<15 and abs(pr(p,g)[1]-p[3])<15]
  X=np.array([[1,p[0],p[1]+(0.5 if p[0]%2==0 else 0)] for p in inl])
  ax,dx,sx=np.linalg.lstsq(X,np.array([p[2] for p in inl]),rcond=None)[0]
  X2=np.array([[1,p[1]+(0.5 if p[0]%2==0 else 0),p[0]] for p in inl])
  ay,dy,sy=np.linalg.lstsq(X2,np.array([p[3] for p in inl]),rcond=None)[0]
  g2=dict(ax=ax,dx=dx,sx=sx,ay=ay,dy=dy,sy=sy)
  res=np.array([[pr(p,g2)[0]-p[2],pr(p,g2)[1]-p[3]] for p in inl])
  print('affine',m,len(inl),{k:round(v,3) for k,v in g2.items()},np.abs(res).max(0),np.abs(res).mean(0))
  return g2
G={m:fit2(m,G[m]) for m in 'BQWL'}
json.dump(G,open('griglia.json','w'),indent=1)
