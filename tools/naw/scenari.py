# Napoleon at War: scenari per il motore (assets/dati/naw.json) dagli ordini di battaglia (dati.py) e dalle mappe
import json
R='/home/claude/napoleon-last-battles'
O=json.load(open('/tmp/nawm/oob.json'))
U=O['unita']; P=O['per_gioco']
def mappa(g): return json.load(open(f'{R}/assets/naw/{g}/mappa.json'))
def vicini(k):
  c,r=int(k[:2]),int(k[2:])
  d=[[0,-1],[1,-1],[1,0],[0,1],[-1,0],[-1,-1]] if c%2==1 else [[0,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
  return ['%02d%02d'%(c+a,r+b) for a,b in d]
def lato(M,a,b): return M['lati'].get(a+'-'+b if a<b else b+'-'+a,'')
def flood(M,start,ok):
  vis={start}; q=[start]
  while q:
    h=q.pop()
    for v in vicini(h):
      if v in M['esagoni'] and v not in vis and ok(h,v): vis.add(v); q.append(v)
  return sorted(vis)
SC={}
# ---------------- Marengo
M=mappa('marengo')
un=[];ri=[]
for id,p in P['marengo']:
  if isinstance(p,str): un.append({'u':id,'h':p})
  else: ri.append({'u':id,'t':p[1]-1,'e':p[2]})
SC['naw_marengo']={'sistema':'naw','gioco':'marengo','mappa':'marengo','titolo':'Marengo','sotto':'Napoleone in Italia','data':'14 giugno 1800',
 'lati':['Francesi','Austriaci'],'eserciti':{'FR':'Armée de Réserve','AU':'Esercito austriaco'},'primo':1,
 'turni':[str(i) for i in range(1,15)],'ore':['%d:00'%(7+i) for i in range(1,15)],'giorni':['14 giugno']*14,
 'unita':un,'rinforzi':ri,'marengo':'1412','pietrabuona':'1111'}
# ---------------- Wagram
M=mappa('wagram')
lobau=['0110','0111','0112','0113','0114','0115','0210','0211','0212','0213','0214','0215','0311','0312','0313','0314','0315','0413','0414','0415']
print('Lobau',len(lobau),lobau)
# Russbach: gli esagoni sopra il pendio, dal lato est della Russbach
CMIN={16:27,17:26,18:26,19:25,20:24,21:24,22:23,23:23,24:22,25:22,26:22,27:23,28:24,29:25,30:25,31:26,32:27,33:28,34:29}
alture=sorted(k for k in M['esagoni'] if int(k[2:]) in CMIN and int(k[:2])>=CMIN[int(k[2:])])
print('alture',len(alture))
un=[];ri=[];zone=[]
ovest='|'.join(k for k in M['esagoni'] if k[:2]=='01')
giov='|'.join(k for k in M['esagoni'] if k[2:]=='34' and 11<=int(k[:2])<=29)
for id,p in P['wagram']:
  if isinstance(p,str): un.append({'u':id,'h':p})
  elif p[0]=='Z': zone.append({'u':id,'centro':p[1],'raggio':p[2]})
  elif p[2]=='ovest': ri.append({'u':id,'t':p[1]-1,'e':ovest})
  else: ri.append({'u':id,'t':-2,'e':giov,'giovanni':True})
SC['naw_wagram']={'sistema':'naw','gioco':'wagram','mappa':'wagram','titolo':'Wagram','sotto':'La pace di Vienna','data':'5-6 luglio 1809',
 'lati':['Francesi','Austriaci'],'eserciti':{'FR':'Armée d\'Allemagne','AU':'Esercito imperiale asburgico'},'primo':0,
 'turni':['1','2','3','4','N5','N6']+[str(i) for i in range(7,15)],
 'ore':['15:00','16:00','17:00','18:00','notte','notte','5:00','6:00','7:00','8:00','9:00','10:00','11:00','12:00'],
 'giorni':['5 luglio']*5+['6 luglio']*9,'unita':un,'rinforzi':ri,'zone':zone,'lobau':lobau,'alture':alture,
 'aspern':['0809','0810'],'essling':['0714','0813','0814'],'enzersdorf':['0516','0517','0616']}
# ---------------- Battle of Nations: tre scenari
M=mappa('nazioni')
turni=[str(i) for i in range(1,21)]
for i in (6,12,18): turni[i-1]='N%d'%i
giorni=['16 ottobre']*6+['17 ottobre']*6+['18 ottobre']*6+['19 ottobre']*2
ore=[]
for i in range(1,21):
  if i in (6,12,18): ore.append('notte')
  else:
    k=(i-1)%6; ore.append(['8:00','10:00','12:00','14:00','16:00'][k] if k<5 else '')
base={'sistema':'naw','gioco':'nazioni','mappa':'nazioni','titolo':'La battaglia delle Nazioni','data':'16-19 ottobre 1813',
 'lati':['Francesi','Alleati'],'eserciti':{'FR':'Grande Armée','PR':'Esercito prussiano','AU':'Esercito austriaco','RU':'Esercito russo','SV':'Esercito svedese'},
 'primo':0,'linea':'2131'}
for k,sotto,t0,t1,giorno3 in [('naw_nazioni1','Primo giorno: Wachau e Möckern',0,5,False),('naw_nazioni3','Terzo giorno: l\'accerchiamento',12,20,True),('naw_nazioni','La grande battaglia: quattro giorni',0,20,False)]:
  un=[];ri=[];distrutte=[]
  for e in P['nazioni']:
    id,p1,p3=e
    if giorno3:
      if p3=='x': distrutte.append(id)
      else: un.append({'u':id,'h':p3})
    else:
      if isinstance(p1,str): un.append({'u':id,'h':p1})
      elif p1[1]-1<t1: ri.append({'u':id,'t':p1[1]-1-t0,'e':p1[2]})
  SC[k]=dict(base,sotto=sotto,turni=turni[t0:t1],ore=ore[t0:t1],giorni=giorni[t0:t1],turno0=t0,unita=un,rinforzi=ri,distrutte=distrutte)
# ---------------- Jena-Auerstadt
M=mappa('jena')
un=[];ri=[]
for id,p in P['jena']:
  if isinstance(p,str): un.append({'u':id,'h':p}); continue
  k,t=p[0],p[1]
  if k=='T': ri.append({'u':id,'t':t-1,'e':p[2]})
  elif k=='O':  # opzione A: 1622 al turno t; opzione B: 2320 un turno prima
    ri.append({'u':id,'t':t-1,'e':'1622','opz':'A'}); ri.append({'u':id,'t':t-2,'e':'2320','opz':'B'})
  elif k=='L':
    ri.append({'u':id,'t':2,'e':'1622','opz':'AL'}); ri.append({'u':id,'t':1,'e':'2320','opz':'BL'})
  elif k=='D':  # Davout: 0128 con l'opzione A; con la B cinque turni dopo dal bordo nord di Jena
    ri.append({'u':id,'t':t-1,'e':'0128','opz':'A'}); ri.append({'u':id,'t':t-1+5,'e':'nordjena','opz':'B'})
  elif k=='B':
    ri.append({'u':id,'t':t-1,'e':p[2],'bern':True})
nord='|'.join(k for k in M['esagoni'] if int(k[2:])==20)
SC['naw_jena']={'sistema':'naw','gioco':'jena','mappa':'jena','titolo':'Jena-Auerstadt','sotto':'La battaglia per la Prussia','data':'14 ottobre 1806',
 'lati':['Francesi','Prussiani'],'eserciti':{'FR':'Grande Armée','PR':'Esercito prussiano e sassone'},'primo':0,
 'turni':['N1','N2','N3','F4','F5','6','7','8','9','10','11','12'],
 'ore':['3:00','4:00','5:00','6:00 (nebbia)','7:00 (nebbia)','8:00','9:00','10:00','11:00','12:00','13:00','14:00'],
 'giorni':['14 ottobre']*12,'unita':un,'rinforzi':ri,'nordjena':nord}
for k,v in SC.items():
  for e in v['unita']+v.get('rinforzi',[]):
    if e.get('e')=='nordjena': e['e']=nord
cat={id:{k2:v2 for k2,v2 in u.items()} for id,u in U.items()}
json.dump({'unita':cat,'scenari':SC},open(f'{R}/assets/dati/naw.json','w'),ensure_ascii=False,separators=(',',':'))
print({k:(len(v['unita']),len(v['rinforzi'])) for k,v in SC.items()})
