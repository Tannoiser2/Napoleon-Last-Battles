#!/usr/bin/env python3
"""Mappa ridisegnata: unisce le quattro mappe nuove (cartella NUOVE, una per Folio) in un'unica texture
allineata alla griglia del gioco e aggiunge a mappa.json le quote degli esagoni per la mappa 3D.

La griglia di ogni mappa nuova (griglia_nuova.json) è stata ricavata dalle linee degli esagoni e
verificata esagono per esagono contro quella delle scansioni originali (scarto medio 2-3 px su 35).
Le mappe nuove sono in alta risoluzione (stesse dimensioni delle scansioni): l'immagine finale ha la
scala delle coordinate del gioco ed è divisa in quattro tasselli.
Uso: costruisci_mappa_nuova.py NUOVE assets/mappa"""
import json, sys, os, numpy as np
from PIL import Image
NUOVE, OUT = sys.argv[1], sys.argv[2]
QUI = os.path.dirname(os.path.abspath(__file__))
G = json.load(open(f'{QUI}/griglia_nuova.json'))
FILE = {'B': '01-waterloo.png', 'Q': '02-quatrebras.png', 'W': '03-wavre.png', 'L': '04-ligny.png'}
MJ = json.load(open(f'{OUT}/mappa.json'))
E = MJ['esagoni']
OFF = {'B': (0, 0), 'W': (28, 0), 'Q': (0, 33), 'L': (28, 33)}
PRIO = ['W', 'B', 'L', 'Q']
DX, DY = MJ['DX'], MJ['DY']
X0, Y0 = 0.6 * DX, 0.4 * DY
K = 1.0                                   # scala della texture rispetto alle coordinate della mappa
W, H = int(MJ['larg'] * K), int(MJ['alt'] * K)
Image.MAX_IMAGE_PIXELS = None
IMG = {m: np.asarray(Image.open(f'{NUOVE}/{f}').convert('RGB')) for m, f in FILE.items()}

def centro_nuovo(m, c, r):
    g = G[m]; rr = r + (0.5 if c % 2 == 0 else 0)
    return g['ax'] + c * g['dx'] + rr * g['sx'], g['ay'] + rr * g['dy'] + c * g['sy'] + 45

# ---------- esagono globale di ogni pixel (griglia a colonne, le pari spostate di mezzo esagono)
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
gx, gy = xx / K, yy / K
cf = (gx - X0) / DX
best = np.full((H, W), 1e9, np.float32); bc = np.zeros((H, W), np.int16); br = np.zeros((H, W), np.int16)
for dc in (0, 1):
    C = np.floor(cf).astype(np.int16) + dc
    sh = np.where(C % 2 == 0, 0.5, 0.0)
    R = np.round((gy - Y0) / DY - sh).astype(np.int16)
    for dr in (-1, 0, 1):
        R2 = R + dr
        px = X0 + C * DX; py = Y0 + (R2 + np.where(C % 2 == 0, 0.5, 0.0)) * DY
        d = (gx - px) ** 2 + (gy - py) ** 2
        msk = d < best
        best = np.where(msk, d, best); bc = np.where(msk, C, bc); br = np.where(msk, R2, br)
# mappa proprietaria: quella dell'esagono di gioco, altrimenti la prima che lo contiene
owner = np.full((H, W), -1, np.int8)
for i, m in reversed(list(enumerate(PRIO))):
    oc, orr = OFF[m]
    c = bc - oc; r = br - orr
    owner[(c >= 1) & (c <= 29) & (r >= 1) & (r <= 34)] = i
chiavi = np.char.add(np.char.zfill(bc.astype(str), 2), np.char.zfill(br.astype(str), 2))
for k, v in E.items():
    pass
idx_m = {m: i for i, m in enumerate(PRIO)}
# gli esagoni di gioco usano la loro mappa
gioco = {}
for k, v in E.items():
    gioco[(int(k[:2]), int(k[2:]))] = idx_m[v['m']]
C_all, R_all = bc, br
for (C, R), i in gioco.items():
    pass
own2 = owner.copy()
mC = np.zeros((60, 70), np.int8) - 1
for (C, R), i in gioco.items():
    mC[C, R] = i
valido = (bc >= 0) & (bc < 60) & (br >= 0) & (br < 70)
og = np.where(valido, mC[np.clip(bc, 0, 59), np.clip(br, 0, 69)], -1)
own2 = np.where(og >= 0, og, owner)
canvas = np.zeros((H, W, 3), np.uint8); canvas[:] = (40, 46, 30)
for i, m in enumerate(PRIO):
    g = G[m]; oc, orr = OFF[m]
    sel = own2 == i
    if not sel.any():
        continue
    a = (gx[sel] - X0) / DX - oc
    b = (gy[sel] - Y0) / DY - orr
    sx = g['ax'] + g['dx'] * a + g['sx'] * b
    sy = g['ay'] + 45 + g['dy'] * b + g['sy'] * a
    img = IMG[m]
    xi = np.clip(sx, 0, img.shape[1] - 1.001); yi = np.clip(sy, 0, img.shape[0] - 1.001)
    x0 = np.floor(xi).astype(int); y0 = np.floor(yi).astype(int); fx = (xi - x0)[:, None]; fy = (yi - y0)[:, None]
    p = (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy) + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)
    canvas[sel] = p.astype(np.uint8)
# quattro tasselli con un margine (un esagono) per le tessere a cavallo dei bordi
img = Image.fromarray(canvas)
PAD = int(DX * 1.2)
TW, TH = (W + 1) // 2, (H + 1) // 2
tasselli = []
for j in range(2):
    for i in range(2):
        x0, y0 = max(0, i * TW - PAD), max(0, j * TH - PAD)
        x1, y1 = min(W, (i + 1) * TW + PAD), min(H, (j + 1) * TH + PAD)
        nome = f'mappa_nuova_{j}{i}.webp'
        img.crop((x0, y0, x1, y1)).save(f'{OUT}/{nome}', quality=86, method=6)
        # zona di competenza (centri degli esagoni) e riquadro reale della texture, in pixel della mappa
        tasselli.append({'file': nome, 'zona': [i * TW, j * TH, (i + 1) * TW, (j + 1) * TH], 'tex': [x0, y0, x1, y1]})
img.resize((W // 8, H // 8)).save('/tmp/anteprima_nuova.png')

# ---------- esagoni decorativi (disegnati nelle mappe nuove ma fuori dal gioco)
deco = []
for C in range(1, 58):
    for R in range(1, 68):
        k = f'{C:02d}{R:02d}'
        if k in E:
            continue
        for m in PRIO:
            oc, orr = OFF[m]
            c, r = C - oc, R - orr
            if 1 <= c <= 29 and 1 <= r <= 34:
                x, y = centro_nuovo(m, c, r)
                img = IMG[m]
                if 20 < x < img.shape[1] - 20 and 20 < y < img.shape[0] - 20:
                    deco.append(k)
                break

# ---------- quote: creste (l'esagono con più rilievo disegnato), paesi e fattorie
def frazione(m, c, r, maschera):
    x, y = centro_nuovo(m, c, r); rad = G[m]['dx'] * 0.6
    ys, xs = np.mgrid[-int(rad) - 1:int(rad) + 2, -int(rad) - 1:int(rad) + 2]
    dd = (xs ** 2 + ys ** 2) <= rad ** 2
    ys = int(round(y)) + ys[dd]; xs = int(round(x)) + xs[dd]
    ok = (ys >= 0) & (ys < maschera.shape[0]) & (xs >= 0) & (xs < maschera.shape[1])
    return float(maschera[ys[ok], xs[ok]].mean()) if ok.any() else 0.0
OCRA = {}
for m, img in IMG.items():
    a = img.astype(float); R_, G_, B_ = a[..., 0], a[..., 1], a[..., 2]
    OCRA[m] = (R_ > 140) & (G_ > 105) & (B_ < 80) & (R_ > G_) & (R_ - G_ < 55)
ocra = {k: frazione(v['m'], int(v['l'][:2]), int(v['l'][2:]), OCRA[v['m']]) for k, v in E.items()}
quote = {}
for k, v in MJ['lati'].items():
    if 'c' not in v:
        continue
    a, b = k.split('-')
    alto, basso = (a, b) if ocra[a] >= ocra[b] else (b, a)
    quote[alto] = 'c'
    if ocra[basso] > 0.25:
        quote[basso] = 'c'
for k, v in E.items():
    if v['t'] in ('citta', 'castello') and quote.get(k) != 'c':
        quote[k] = 'e' if v['t'] == 'citta' else 'f'
MJ['nuova'] = {'tasselli': tasselli, 'scala': K, 'quote': quote, 'decorativi': deco}
json.dump(MJ, open(f'{OUT}/mappa.json', 'w'), separators=(',', ':'))
import collections
print('texture', W, H, 'decorativi', len(deco), 'quote', collections.Counter(quote.values()))
