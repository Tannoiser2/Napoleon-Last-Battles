#!/usr/bin/env python3
"""Catalogo delle pedine (immagini webp dal modulo TTS) e scenari (schieramenti dei Folio dalle posizioni
del modulo TTS, campagna dall'elenco NLB_Campaign_Setup.pdf e dalle tracce dei turni stampate sulle mappe).
Uso: costruisci_dati.py <cartella di lavoro con uniq.json e tts_pos.json> <cartella immagini TTS>"""
import json, sys, os
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from catalogo_src import U, L
EST, IMG = sys.argv[1], sys.argv[2]
R = os.path.join(os.path.dirname(__file__), '..', '..')
UQ = json.load(open(f'{EST}/uniq.json'))
POS = json.load(open(f'{EST}/tts_pos.json'))
OFF = {'B': (0, 0), 'W': (28, 0), 'Q': (0, 33), 'L': (28, 33)}
DUP = {101: 92, 102: 90, 103: 98, 104: 97, 105: 37, 106: 36, 107: 34, 108: 35, 109: 30, 110: 54, 111: 52, 112: 53,
       113: 46, 114: 42, 115: 41, 116: 49, 117: 47, 118: 32, 119: 29, 120: 23, 122: 38, 183: 154}
ESERCITO = {'FR': 'FR', 'PR': 'PR'}
os.makedirs(f'{R}/assets/pedine', exist_ok=True)

def salva(src, dst, lato=128, box=None):
    im = Image.open(f'{IMG}/{src}').convert('RGB')
    if box:
        im = im.crop(box)
    im.resize((lato, lato), Image.LANCZOS).save(f'{R}/assets/pedine/{dst}.webp', quality=88)

def corpo(naz, des):
    if naz == 'FR':
        d = des.split('/')[-1]
        return 'Gd' if d == 'Gd' else d
    if naz == 'PR':
        return des.split('/')[-1]
    return des

cat = {'unita': {}, 'capi': {}}
for riga in U.strip().splitlines():
    i, nome, naz, tipo, f, r, ma, des = riga.split('|')
    i = int(i)
    uid = f'u{i}'
    salva(UQ[i][0], uid)
    if int(r) > 0:
        salva(UQ[i][1], uid + 'r')
    cat['unita'][uid] = {'n': nome, 'naz': naz, 'es': ESERCITO.get(naz, 'AA'), 't': tipo, 'f': int(f), 'r': int(r),
                         'ma': int(ma), 'des': des, 'c': corpo(naz, des)}
for riga in L.strip().splitlines():
    i, nome, es, cap, des = riga.split('|')
    i = int(i)
    lid = f'c{i}'
    salva(UQ[i][0], lid)
    cat['capi'][lid] = {'n': nome, 'es': es, 'cap': int(cap), 'des': des}
# pedina per lo schermo del titolo e segnalino di turno
salva(UQ[0][0], 'seg_turno')

def g(m, h):
    oc, orr = OFF[m]
    return f'{int(h[:2]) + oc:02d}{int(h[2:]) + orr:02d}'

def da_tts(m, opzionali=()):
    out = []
    visti = set()
    for p in POS:
        if p['m'] != m or p['trt']:
            continue
        i = DUP.get(p['u'], p['u'])
        uid = f'u{i}'
        if uid not in cat['unita'] or uid in visti:
            continue
        visti.add(uid)
        e = {'u': uid, 'h': g(m, p['hex'])}
        if p['rid']:
            e['rid'] = 1
        if cat['unita'][uid]['c'] in opzionali and cat['unita'][uid]['naz'] == 'FR':
            e['opz'] = 1
        out.append(e)
    return out

def rinf(turno, ids, entrata, opz=False):
    return [{'t': turno, 'u': f'u{i}' if isinstance(i, int) else i, 'e': entrata, **({'opz': 1} if opz else {})} for i in ids]

def G(m, h):
    return g(m, h)

S = {}
S['ligny'] = {'titolo': 'Ligny', 'sotto': 'La vittoria incompleta', 'data': '16 giugno 1815', 'mappa': 'L',
              'turni': ['1400', '1500', '1600', '1700', '1800', '1900', '2000', 'N2100'], 'giorno': 16,
              'unita': da_tts('L'), 'rinforzi': []}
S['quatrebras'] = {'titolo': 'Quatre Bras', 'sotto': 'Stallo sulla strada di Bruxelles', 'data': '16 giugno 1815', 'mappa': 'Q',
                   'turni': ['1400', '1500', '1600', '1700', '1800', '1900', '2000', 'N2100'], 'giorno': 16,
                   'unita': da_tts('Q', opzionali=('I',)),
                   'rinforzi': rinf(0, [53, 30, 52, 54, 34, 35, 37, 36], G('Q', '1601')) +
                               rinf(0, [98, 97, 90, 92], G('Q', '1134'), True) +
                               rinf(2, [47, 32, 49], G('Q', '0103')) + rinf(3, [41, 42, 46], G('Q', '0103'))}
S['wavre'] = {'titolo': 'Wavre', 'sotto': "L'occasione perduta", 'data': '18 giugno 1815', 'mappa': 'W',
              'turni': ['1200', '1300', '1400', '1500', '1600', '1700', '1800', '1900'], 'giorno': 18,
              'unita': da_tts('W'), 'rinforzi': []}
S['bellealliance'] = {'titolo': 'La Belle Alliance', 'sotto': 'La battaglia di Waterloo', 'data': '18 giugno 1815', 'mappa': 'B',
                      'turni': ['1200', '1300', '1400', '1500', '1600', '1700', '1800', '1900'], 'giorno': 18,
                      'unita': da_tts('B'),
                      'rinforzi': rinf(1, [4, 6, 5], '2912|2914') + rinf(2, [8, 9, 12, 13, 14, 17], '2912|2914') +
                                  rinf(3, [7, 10, 11, 18, 19, 16, 15], '2912|2914')}
# ---------- campagna
camp_unita = da_tts('L') + [e for e in da_tts('Q') if True]
for e in camp_unita:
    e.pop('opz', None)
extra = {53: 'B1633', 52: 'B1532', 30: 'B1632', 54: 'B1531', 34: 'B1430', 35: 'B1429', 37: 'B1328', 36: 'B1329'}
for i, h in extra.items():
    camp_unita.append({'u': f'u{i}', 'h': G(h[0], h[1:])})
# French I Corps reinforcements of the first turn come in at Q1134; the rest is already on the map
capi = {'c215': 'L0728', 'c216': 'L0927', 'c217': 'Q1718', 'c218': 'Q1333', 'c219': 'Q1719', 'c220': 'L0226',
        'c221': 'L1224', 'c222': 'L0630', 'c226': 'L1728', 'c224': 'Q1323', 'c223': 'L1427', 'c225': 'L0830',
        'c210': 'L0719', 'c211': 'L0622', 'c212': 'L0817', 'c213': 'L1619',
        'c202': 'Q1910', 'c205': 'Q1608', 'c206': 'Q1611', 'c198': 'B1633', 'c209': 'B1430'}
camp_capi = [{'c': k, 'h': G(v[0], v[1:])} for k, v in capi.items()]
Q0103 = G('Q', '0103'); B0120 = G('B', '0120'); B0114 = G('B', '0114'); B0605 = G('B', '0605'); W2512 = G('W', '2512')
due = B0120 + '|' + Q0103
TURNI = [(16, t) for t in ['1400', '1500', '1600', '1700', '1800', '1900', '2000', 'N2100', 'N2400']] + \
        [(17, t) for t in ['N0300', 'N0600', '0900', '1000', '1100', '1200', '1300', '1400', 'R1500', 'R1700', 'R1900', 'N2100', 'N2400']] + \
        [(18, t) for t in ['N0300', 'N0600', 'R0900', '1100', '1200', '1300', '1400', '1500', '1600', '1700', '1800', '1900', '2000', 'N2100']]
def T(g, t):
    return TURNI.index((g, t))
cr = []
cr += rinf(T(16, '1400'), [98, 97, 90, 92], G('Q', '1134'))
cr += rinf(T(16, '1600'), [47, 32, 49, 'c203'], Q0103)
cr += rinf(T(16, '1700'), [41, 42, 46, 'c197'], Q0103)
cr += rinf(T(16, '2000'), [135, 136, 80, 81, 82, 83, 70, 'c227'], G('L', '0334'))
cr += rinf(T(16, 'N2400'), [28], B0605)
cr += rinf(T(17, 'N0600'), [50, 51, 56, 55, 27, 48, 57, 26, 33, 'c204'], B0114)
cr += rinf(T(17, 'N0600'), [40, 39, 'c208', 21, 22, 20, 'c207'], due)
cr += rinf(T(17, '0900'), [24, 44, 'c200'], due)
cr += rinf(T(17, '1000'), [43, 31, 25, 45, 'c199'], due)
cr += rinf(T(17, 'N2100'), [6, 5, 4, 'c214'], W2512)
cr += rinf(T(17, 'N2400'), [9, 12, 13, 8, 17, 14], W2512)
cr += rinf(T(18, 'N0300'), [7, 11, 16, 15, 10, 18, 19], W2512)
cr += rinf(T(18, 'N0600'), ['c201'], B0605)
cr += rinf(T(18, 'R0900'), [3], B0605)
cr += rinf(T(18, '1100'), [1, 2], B0605)
S['campagna'] = {'titolo': 'La campagna', 'sotto': 'Le quattro battaglie unite, 16-18 giugno 1815', 'data': '16-18 giugno 1815', 'mappa': '',
                 'turni': [t for g, t in TURNI], 'giorni': [g for g, t in TURNI],
                 'unita': camp_unita, 'capi': camp_capi, 'rinforzi': cr}
# entrate sul bordo: se l'esagono di bordo è solo mezzo esagono si usa il più vicino della mappa
MJ = json.load(open(f'{R}/assets/mappa/mappa.json'))['esagoni']
def vicino(h):
    if h in MJ: return h
    c, r = int(h[:2]), int(h[2:])
    return min(MJ, key=lambda k: (int(k[:2]) - c) ** 2 * 1.3 + (int(k[2:]) - r) ** 2)
for s_ in S.values():
    for r_ in s_['rinforzi']:
        r_['e'] = '|'.join(vicino(h) for h in r_['e'].split('|'))
# controlli
for k, s in S.items():
    ids = [e['u'] for e in s['unita']]
    rid = [e['u'] for e in s['rinforzi'] if e['u'].startswith('u')]
    dup = set(x for x in ids + rid if (ids + rid).count(x) > 1)
    print(k, len(ids), 'unità,', len(rid), 'rinforzi', 'DOPPIE ' + str(dup) if dup else '')
os.makedirs(f'{R}/assets/dati', exist_ok=True)
json.dump(cat, open(f'{R}/assets/dati/catalogo.json', 'w'), ensure_ascii=False, indent=0)
json.dump(S, open(f'{R}/assets/dati/scenari.json', 'w'), ensure_ascii=False, indent=0)
manca = set(cat['unita']) - set(e['u'] for e in S['campagna']['unita']) - set(e['u'] for e in S['campagna']['rinforzi'])
print('fuori dalla campagna:', sorted(manca, key=lambda x: int(x[1:])), [cat['unita'][x]['n'] for x in sorted(manca, key=lambda x: int(x[1:]))])
