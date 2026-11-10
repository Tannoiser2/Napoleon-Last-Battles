import json,sys,numpy as np
sys.path.insert(0,'.')
from hexgeo import *
from scipy.spatial import cKDTree
d=json.load(open('/home/claude/src/nlb/tts/Mods/Workshop/1470061199.json'))
maps={'B':(-22.42,-17.6),'Q':(19.81,-17.49),'W':(-22.51,15.29),'L':(20.02,15.43)}
tiles=np.array([(o['Transform']['posX'],o['Transform']['posZ']) for o in d['ObjectStates'] if o['Name']=='Custom_Tile'])
res={}
for m,(x0,z0) in maps.items():
  C=np.array([[*centro(m,c,r)] for c in range(1,30) for r in range(1,35)]); tr=cKDTree(C)
  def score(k,ox,oy):
    px=1856+ox+(tiles[:,1]-z0)*k; py=2396+oy+(tiles[:,0]-x0)*k
    ins=(px>200)&(px<3600)&(py>200)&(py<4700)
    if ins.sum()<5: return 99,0
    dd,_=tr.query(np.stack([px[ins],py[ins]],1)); return np.mean(np.minimum(dd,60)),ins.sum()
  best=(99,)
  for k in (113.25,):
    for ox in range(-300,301,4):
      for oy in range(-300,301,4):
        s,n=score(k,ox,oy)
        if s<best[0]: best=(s,k,ox,oy,n)
  s,k,ox,oy,n=best
  for k2 in np.arange(112.5,114.01,0.1):
    for ox2 in range(ox-6,ox+7):
      for oy2 in range(oy-6,oy+7):
        s,n=score(k2,ox2,oy2)
        if s<best[0]: best=(s,k2,ox2,oy2,n)
  print(m,best,flush=True); res[m]=dict(k=best[1],ox=best[2],oy=best[3],x0=x0,z0=z0)
json.dump(res,open('tts_map.json','w'))
