# Napoleon at War Deluxe (Decision Games 2025): ritaglia le pedine dai due fogli fustellati e le abbina alle
# unità del gioco (assets/naw/pedine_dg/<id>.webp). Uso: pedine_deluxe.py foglio1.jpg foglio2.jpg
import sys, json, re, numpy as np
from PIL import Image, ImageFilter
sys.path.insert(0, sys.path[0])
from griglia_fogli import blocco
R = '/home/claude/napoleon-last-battles'
# trascrizione dei fogli, blocco per blocco, riga per riga: "sigla[:tipo c/a][:forza]"; "-" = segnalino da saltare
F1 = [
 # (x0, x1, y0, y1, colonne, righe, gioco, nazione, pedine)
 (27,427,38,195,5,2,'M','FR','9 19 24 22 28 59 69 70 72 96'),
 (444,764,38,195,4,2,'M','FR','30 40 43 44 101 CnGd Cham DuMo'),
 (780,1100,38,195,4,2,'W','FR','Colb Gera Grou LaSa IX:a 1/III 2/III 1/IV'),
 (1117,1517,38,195,5,2,'W','FR','Mont Pull Res:c Gd:c II 2/IV 2/Res 1/Res 3/Res Gd:a'),
 (27,427,215,372,5,2,'MJ','FR','M:DuVi M:Kell M:Mura M:Riva M:Gd:c M:Vict J:1/De J:2/De J:1/Dro J:2/Dro'),
 (444,764,215,372,4,2,'MJ','FR','M:AdGd M:Cav M:DeSa M:Res J:1/Fri J:2/Fri J:1/Gaz J:2/Gaz'),
 (780,1100,215,372,4,2,'N','FR','4 5 6 8 15 16 19:7 20'),
 (1117,1517,215,372,5,2,'N','FR','9 10 11 12 14 21 22 24 26 27'),
 (27,427,392,550,5,2,'J','FR','1/Gud 2/Gud 1/Hil 2/Hil 1/He 2/Lev 1/Mah 2/Mah 1/Mar 2/Mar'),
 (444,764,392,550,4,2,'J','FR','2/He 1/Leg 2/Leg 1/Lev 1/Mor 2/Mor 1/Riv 2/Riv'),
 (780,1100,392,550,4,2,'N','FR','31 32 35 36 Prov:6 Prov:4 1Gd 2Gd'),
 (1117,1517,392,550,5,2,'N','FR','38 39 51 52 53 1YGd 2YGd 3YGd 4YGd I'),
 (27,427,570,728,5,2,'J','FR','1/Suc 2/Suc Van Gd I:c VII:c Haut Kle Nan Sah'),
 (444,764,570,728,4,2,'J','FR','III:c IV:c V:c VI:c I:a IV:a V:a VI:a'),
 (780,1100,570,728,4,2,'N','FR','II III IV V Gd - - -'),
 (1117,1517,570,728,5,2,'M','AU','Bell DeBe Frim Gott Knes Lama Latt Pion Retz Rous'),
 (27,427,745,903,5,2,'JW','FR','J:VII:a J:Mor:a J:Gud:a J:Fri:a J:Gd:a W:Clap W:Demo W:DHil W:Dupa W:Fria'),
 (444,764,745,903,4,2,'W','FR','1/Ital 2/Ital Boud Brou Gran Gudi Lecc Legr'),
 (780,1100,745,903,4,2,'M','AU','Stic StJu Ulm Weie Sche Voge AdGd:a LCol'),
 (1117,1517,745,903,5,2,'MW','AU','M:AvGd:c M:Nimp M:Nobl M:ORei M:Pila M:Main M:RCol W:1/I W:2/I W:3/I'),
 (27,187,922,1163,2,3,'W','FR','Marm Mora Moli Pact Reyn Sax'),
 (215,375,922,1163,2,3,'W','FR','StCy Thar Wred OlGd YoGd IX:c'),
 (587,747,922,1163,2,3,'N','SV','- 1 - 2 - 3'),
 (795,955,922,1163,2,3,'W','AU','1/II 2/II 3/IV 1/VI 3/SR 1/Res'),
 (985,1145,922,1163,2,3,'W','AU','3/II 1/III 2/VI 3/VI 2/Res IV:c'),
 (1172,1332,922,1163,2,3,'W','AU','2/III 3/III 1/AG 2/AG VI:c 1/II:c'),
 (1357,1517,922,1163,2,3,'W','AU','1/IV 2/IV 1/SR 2/SR 1/AG:c 2/AG:c'),
]
F2 = [
 (16,351,32,166,5,2,'W','AU','1/Res:c 2/Res:c 3/Res:c SR:c I:a IV:a VI:a AG:a Res:a SR:a'),
 (366,633,32,166,4,2,'WN','AU','W:II:a W:III:a N:2/I N:3/I N:1/II N:2/II N:2/III N:3/III'),
 (16,351,181,315,5,2,'J','PR','1/1 2/1 1/2 2/2 1/3 2/3 1/1Res 2/1Res 1/2Res 2/2Res'),
 (366,633,181,315,4,2,'N','AU','2/IV 3/IV 1Gr 2Gr DioB Gren Res Pahl'),
 (16,351,329,463,5,2,'J','PR','1/Gra 2/Gra 1/Lou 2/Lou 1/Sax 2/Ruch Dhy Holz 1:c 2:c'),
 (366,633,329,463,4,2,'J','PR','2/Sax 1/Tau 2/Tau 1/Ruch 3:c 1Res:c 2Res:c Blu'),
 (16,351,477,611,5,2,'JN','PR','J:Gra:c J:Holz:c J:Lou:c J:Sax:c J:Tau:c J:Sax:a J:Tau:a N:1 N:2 N:3'),
 (366,633,477,611,4,2,'JN','PR','J:I:a J:Gra:a J:Lou:a J:Res:a N:4 N:5 N:6 N:7'),
 (16,351,625,760,5,2,'N','PR','8 9 10 11 RU:3 12 1Gd AvGd 1:c RU:4'),
 (16,150,773,975,2,3,'N','RU','5 6 13 14 24 25'),
 (172,306,773,975,2,3,'N','RU','7 8 15 16 26 27'),
 (328,462,773,975,2,3,'N','RU','9 10 17 18 1Gd 2Gd'),
 (484,618,773,975,2,3,'N','RU','11 12 21 22 Sack StPr'),
]
O = json.load(open(R + '/assets/dati/naw.json'))['unita']
def norm(s): return re.sub(r'[^A-Za-z0-9/]', '', s).lower()
# sigla stampata sulla pedina originale: la nostra 'des' (tools/naw/dati.py) + varianti
def candidati(g, naz, des, tp, f):
  out = []
  for id, u in O.items():
    if id[1] != g or u['naz'] != naz:
      continue
    d = norm(u['des'])
    if d != norm(des) and d.replace('res', 'r') != norm(des).replace('res', 'r') and d.split('/')[-1] != norm(des) and norm(des).replace('1', '', 1) != d:
      continue
    if tp and u['t'].lower() != {'c': 'c', 'a': 'a', 'i': 'i'}[tp]:
      continue
    if f and int(u['f']) != f:
      continue
    out.append(id)
  return out
assegnate = {}
problemi = []
def taglia(im, box):
  x0, y0, x1, y1 = box
  c = im.crop((x0 + 3, y0 + 3, x1 - 2, y1 - 2))
  c = c.resize((128, 128), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.2, 60, 2))
  return c
for foglio, tab in ((sys.argv[1], F1), (sys.argv[2], F2)):
  im = Image.open(foglio).convert('RGB'); L = np.asarray(im).astype(float).mean(2)
  for x0, x1, y0, y1, nc, nr, g, naz, txt in tab:
    caselle = blocco(L, x0, x1, y0, y1, nc, nr)
    voci = txt.split()
    assert len(voci) == len(caselle), (txt, len(caselle))
    for v, cs in zip(voci, caselle):
      if v == '-':
        continue
      p = v.split(':'); gg = g[0]; nn = naz
      if len(g) > 1:
        gg = p.pop(0)
      if p[0] in ('RU', 'PR', 'AU', 'FR', 'SV'):
        nn = p.pop(0)
      des = p[0]; tp = ''; f = 0
      for q in p[1:]:
        if q in ('c', 'a'): tp = q
        elif q.isdigit(): f = int(q)
      if not tp and len(p) == 1:
        tp = ''
      cand = [c for c in candidati(gg, nn, des, tp, f) if c not in assegnate]
      if not tp and len(cand) > 1:
        cand = [c for c in cand if O[c]['t'] == 'I'] or cand
      if len(cand) != 1:
        problemi.append((gg, nn, v, cand)); continue
      assegnate[cand[0]] = True
      taglia(im, cs[:4]).save(f'{R}/assets/naw/pedine_dg/{cand[0]}.webp', quality=92)
mancano = [id for id in O if id not in assegnate]
print('assegnate', len(assegnate), 'di', len(O))
print('problemi', problemi)
print('mancano', [(id, O[id]['des'], O[id]['f'], O[id]['ma'], O[id]['t']) for id in mancano])
