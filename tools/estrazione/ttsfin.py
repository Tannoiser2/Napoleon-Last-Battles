import json,sys;sys.path.insert(0,'.')
from dove import dove
from hexgeo import centro
R=json.load(open('tts_map.json'));tiles=json.load(open('tiles.json'));O=json.load(open('ocrc.json'))
U=json.load(open('uniq.json')); idx={tuple(u):i for i,u in enumerate(U)}
SH={'B':(2,-1),'L':(-2,-1),'Q':(2,0),'W':(-2,-2)}
EX=json.load(open('escludi.json'))
T={m:json.load(open(f'terreno_{m}.json'))['hexes'] for m in 'BQWL'}
out=[]
for m in 'BQWL':
  Rm=R[m];dc,dr=SH[m]
  for t in tiles:
    px=1856+Rm['ox']+(t['z']-Rm['z0'])*Rm['k']; py=2396+Rm['oy']+(t['x']-Rm['x0'])*Rm['k']
    if not(-150<px<3862 and -150<py<4942): continue
    i=idx[(t['front'],t['back'])]; c,r=dove(m,px,py); c+=dc; r+=dr
    # posizione corretta in pixel = centro esagono, e verifica se fuori mappa
    hx=f'{c:02d}{r:02d}'
    on= hx in T[m]
    # pixel reale (spostato)
    cx,cy=centro(m,c,r)
    out.append(dict(m=m,u=i,rid=t['flip']==180,hex=hx if on else None,px=round(cx if on else px+(centro(m,c,r)[0]-centro(m,c-dc,r-dr)[0])),py=round(cy if on else py+(centro(m,c,r)[1]-centro(m,c-dc,r-dr)[1])),nome=O[i]['name']))
json.dump(out,open('tts_pos.json','w'),indent=0)
for m in 'BQWL':
  off=[o for o in out if o['m']==m and not o['hex']]
  print(m,len(off),[(o['nome'],o['px'],o['py']) for o in off])
