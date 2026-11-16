# Napoleon at War: dal terreno estratto (terreno.py) alla mappa del gioco, con le correzioni a mano.
import sys,json,math,os
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
DEST='/home/claude/napoleon-last-battles/assets/naw'
DXN=73.78   # passo delle colonne nella mappa di Last Battles: stessa scala per le pedine
CORR={
 'marengo':{
   'ponti':['0205-0106','0407-0508','0607-0708','0906-1006','1211-1312','1116-1216'],
   'no_strada':['1010-1011','0913-0914','0505-0506'],
   'no_acqua_box':[[4150,100,4650,600]],
 },
 'wagram':{
   'ponti':['0311-0411','0115-0116','0317-0417','2416-2517','2120-2220','1925-2025','1627-1628','1133-1134','1133-1233'],
   'no_acqua_box':[[100,4300,650,4750]],
 },
 'nazioni':{
   'ponti':['1118-1119','1318-1319','1420-1521','1918-2018','2117-2217','2916-2917','0921-1021','0607-0708','1204-1205','1004-1105'],
   'strade':['1319-1320','1320-1420'],
   'palude':['1219','1319','1320','1419','1420','1519','1520','1620','1720','1820'],
   'no_acqua_box':[[2780,2900,3300,3420]],
 },
 'jena':{
   'ponti':['1523-1524','2023-2024','2024-2025'],
   'no_acqua_box':[[3000,3780,3400,4180]],
 },
}
def vicini(k):
  c,r=int(k[:2]),int(k[2:])
  d=[[0,-1],[1,-1],[1,0],[0,1],[-1,0],[-1,-1]] if c%2==1 else [[0,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
  return ['%02d%02d'%(c+a,r+b) for a,b in d]
def chiave(a,b): return a+'-'+b if a<b else b+'-'+a
m=sys.argv[1]; T=json.load(open(f'/tmp/nawm/terreno_{m}.json')); C=CORR.get(m,{})
es=T['esagoni']; lati=T['lati']; DX=T['dx']
f=DXN/DX
def mezzo(k):
  a,b=k.split('-'); return ((es[a]['x']+es[b]['x'])/2,(es[a]['y']+es[b]['y'])/2)
# acqua finta (rose dei venti)
for k in list(lati):
  x,y=mezzo(k)
  if any(x0<=x<=x1 and y0<=y<=y1 for x0,y0,x1,y1 in C.get('no_acqua_box',[])):
    lati[k]=lati[k].replace('F','').replace('T','').replace('p','')
# fiume o ruscello: la maggioranza dei lati d'acqua vicini (che toccano lo stesso vertice) decide
for it in range(2):
  nuovi={}
  acq=[k for k,v in lati.items() if v[:1] in ('F','T')]
  for k in acq:
    x,y=mezzo(k)
    vv=[lati[j][0] for j in acq if j!=k and math.hypot(*(p-q for p,q in zip(mezzo(j),(x,y))))<DX*0.75]
    if len(vv)>=2 and all(v!=lati[k][0] for v in vv): nuovi[k]=vv[0]+lati[k][1:]
  lati.update(nuovi)
for k in C.get('no_strada',[]): lati[chiave(*k.split('-'))]=lati.get(chiave(*k.split('-')),'').replace('r','')
for k in C.get('strade',[]):
  kk=chiave(*k.split('-'))
  if 'r' not in lati.get(kk,''): lati[kk]=lati.get(kk,'')+'r'
for k in C.get('ponti',[]):
  kk=chiave(*k.split('-')); v=lati.get(kk,'')
  if v[:1] not in ('F','T'):
    x,y=mezzo(kk)
    vv=[lati[j][0] for j in lati if lati[j][:1] in ('F','T') and math.hypot(mezzo(j)[0]-x,mezzo(j)[1]-y)<DX*0.8]
    t='F' if vv.count('F')>vv.count('T') else ('T' if vv else '?')
    print('ponte: acqua dai vicini',kk,v,t,vv)
    v=(t if t!='?' else 'T')+v
  if 'p' not in v: v=v[0]+'p'+v[1:]
  lati[kk]=v
for h in C.get('palude',[]): es[h]['t']='palude'
if m!='wagram':
  for e in es.values():
    if e['t']=='lago': e['t']='aperto'
if m=='nazioni':
  for k in lati: lati[k]=lati[k].replace('ca','').replace('cb','')
if m=='marengo':
  for k in lati: lati[k]=lati[k].replace('r','s')
# pendii: lato 'c' + quale dei due esagoni è in basso ('a' il primo, 'b' il secondo della chiave)
lati={k:v for k,v in lati.items() if v}
os.makedirs(f'{DEST}/{m}',exist_ok=True)
im=Image.open(f'/tmp/nawm/{m}_o.png').convert('RGB')
W,H=round(im.width*f),round(im.height*f)
im=im.resize((W,H),Image.LANCZOS)
tw,th=(W+1)//2,(H+1)//2
for j in range(2):
  for i in range(2):
    im.crop((i*tw,j*th,min(W,(i+1)*tw),min(H,(j+1)*th))).save(f'{DEST}/{m}/mappa_{j}{i}.webp',quality=86)
out={'larg':W,'alt':H,'DX':DXN,'DY':T['dy']*f,'tasselli':[tw,th],
 'esagoni':{k:{'t':e['t'],'m':'','l':k,'x':round(e['x']*f,1),'y':round(e['y']*f,1)} for k,e in sorted(es.items())},
 'lati':dict(sorted(lati.items()))}
json.dump(out,open(f'{DEST}/{m}/mappa.json','w'),separators=(',',':'))
import collections
print(m,W,H,len(es),collections.Counter(e['t'] for e in es.values()),collections.Counter(lati.values()).most_common(12))
