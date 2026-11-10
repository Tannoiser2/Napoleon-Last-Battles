import json,math
G=json.load(open('/home/claude/src/est/griglia.json'))
OFF=float(json.load(open('/home/claude/src/est/off.json'))) if __import__('os').path.exists('/home/claude/src/est/off.json') else 45
def centro(m,c,r,off=None):
  g=G[m]; rr=r+(0.5 if c%2==0 else 0)
  return g['ax']+c*g['dx']+rr*g.get('sx',0), g['ay']+rr*g['dy']+c*g.get('sy',0)+(OFF if off is None else off)
def vertici(m,c,r,off=None):
  x,y=centro(m,c,r,off); g=G[m]; R=g['dx']/1.5; h=g['dy']/2
  return [(x+R,y),(x+R/2,y+h),(x-R/2,y+h),(x-R,y),(x-R/2,y-h),(x+R/2,y-h)]
