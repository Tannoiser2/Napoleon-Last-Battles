import sys;sys.path.insert(0,'/home/claude/src/est')
from hexgeo import *
def dove(m,x,y):
  return min(((c,r) for c in range(1,30) for r in range(1,35)),key=lambda h:(centro(m,*h)[0]-x)**2+(centro(m,*h)[1]-y)**2)
if __name__=='__main__':
  m=sys.argv[1]
  for p in sys.argv[2:]:
    x,y=map(float,p.split(','));c,r=dove(m,x,y);print(p,f'{c:02d}{r:02d}')
