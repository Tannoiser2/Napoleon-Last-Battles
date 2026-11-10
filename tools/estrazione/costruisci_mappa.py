#!/usr/bin/env python3
"""Costruisce la mappa della campagna unendo le quattro mappe dei Folio (Ligny, Quatre Bras, Wavre,
La Belle Alliance) del modulo TTS: immagini raddrizzate sulla griglia esagonale comune (4 tasselli
webp) e dati dei terreni in assets/mappa/mappa.json.

Ingresso (cartella EST): map_X.jpg, griglia.json (affinità della griglia di ogni mappa, ricavata dai
numeri degli esagoni letti con l'OCR), terreno_X.json (terreni e lati riconosciuti dai colori).
"""
import json, sys, os, numpy as np
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
EST = sys.argv[1]
OUT = sys.argv[2]
S = 0.62                      # scala dell'immagine finale rispetto alle scansioni
DXo, DYo = 119.0, 137.2       # passo medio della griglia nelle scansioni
DX, DY = DXo * S, DYo * S
OFF = {'B': (0, 0), 'W': (28, 0), 'Q': (0, 33), 'L': (28, 33)}
PRIO = ['W', 'B', 'L', 'Q']
NC, NR = 57, 67
G = json.load(open(f'{EST}/griglia.json'))
T = {m: json.load(open(f'{EST}/terreno_{m}.json')) for m in 'BQWL'}
CHATEAU = {'B': ['1423', '0916', '0617'], 'Q': ['1314', '2422', '1522'], 'L': ['2616'], 'W': []}
X0, Y0 = 0.6 * DX, 0.4 * DY    # margine
W = int((NC + 1.2) * DX); H = int((NR + 1.3) * DY)

def gpix(C, R):
    return (X0 + C * DX - DX * 0.6 + DX * 0.6, Y0 + (R + (0.5 if C % 2 == 0 else 0)) * DY)

# ---------- esagoni globali
hexes = {}
for C in range(1, NC + 1):
    for R in range(1, NR + 1):
        for m in PRIO:
            oc, orr = OFF[m]
            c, r = C - oc, R - orr
            if not (1 <= c <= 29 and 1 <= r <= 34):
                continue
            k = f'{c:02d}{r:02d}'
            if k in T[m]['hexes']:
                t = T[m]['hexes'][k]['t']
                if k in CHATEAU[m]:
                    t = 'castello'
                x, y = gpix(C, R)
                hexes[f'{C:02d}{R:02d}'] = {'t': t, 'm': m, 'l': k, 'x': round(x, 1), 'y': round(y, 1)}
                break
# lati
def vicini(C, R):
    if C % 2 == 1:
        d = [(0, -1), (1, -1), (1, 0), (0, 1), (-1, 0), (-1, -1)]
    else:
        d = [(0, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0)]
    return [(C + a, R + b) for a, b in d]
lati = {}
for k, h in hexes.items():
    C, R = int(k[:2]), int(k[2:])
    for C2, R2 in vicini(C, R):
        k2 = f'{C2:02d}{R2:02d}'
        if k2 not in hexes or k2 < k:
            continue
        e = None
        for m in PRIO:
            oc, orr = OFF[m]
            a = f'{C - oc:02d}{R - orr:02d}'; b = f'{C2 - oc:02d}{R2 - orr:02d}'
            if a in T[m]['hexes'] and b in T[m]['hexes']:
                e = T[m]['lati'].get(f'{a}-{b}') or T[m]['lati'].get(f'{b}-{a}') or {}
                break
        if e:
            s = ''
            if 'acqua' in e:
                ponte = 'strada' in e or 'sentiero' in e
                s += ('F' if 'fiume' in e else 'T') + ('p' if ponte else '')
            if 'cresta' in e: s += 'c'
            if 'strada' in e: s += 'r'
            elif 'sentiero' in e: s += 's'
            lati[f'{k}-{k2}'] = s
# ---------- immagine
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
cf = (xx - X0) / DX
best_d = np.full((H, W), 1e9, np.float32); bc = np.zeros((H, W), np.int16); br = np.zeros((H, W), np.int16)
for dc in (0, 1):
    C = np.floor(cf).astype(np.int16) + dc
    sh = np.where(C % 2 == 0, 0.5, 0.0)
    R = np.round((yy - Y0) / DY - sh).astype(np.int16)
    for dr in (-1, 0, 1):
        R2 = R + dr
        px = X0 + C * DX; py = Y0 + (R2 + np.where(C % 2 == 0, 0.5, 0.0)) * DY
        d = (xx - px) ** 2 + (yy - py) ** 2
        msk = d < best_d
        best_d = np.where(msk, d, best_d); bc = np.where(msk, C, bc); br = np.where(msk, R2, br)
del best_d
owner = np.full((H, W), -1, np.int8)
for i, m in reversed(list(enumerate(PRIO))):
    oc, orr = OFF[m]
    c = bc - oc; r = br - orr
    inside = (c >= 1) & (c <= 29) & (r >= 1) & (r <= 34)
    owner[inside] = i
canvas = np.zeros((H, W, 3), np.uint8); canvas[:] = (58, 34, 22)
def margine(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 145) & (r < 220) & (g > 105) & (g < 180) & (b > 70) & (b < 150) & (r - b > 40) & (r - b < 102) & (g < r - 18)
fatto = np.zeros((H, W), bool)
warps = []
for i, m in enumerate(PRIO):
    g = G[m]; oc, orr = OFF[m]
    a1 = 1 / DX; a0 = -X0 / DX - oc
    b1 = 1 / DY; b0 = -Y0 / DY - orr
    A = g['dx'] * a1; Bc = g.get('sx', 0) * b1; Cc = g['ax'] + g['dx'] * a0 + g.get('sx', 0) * b0
    D = g.get('sy', 0) * a1; E = g['dy'] * b1; F = g['ay'] + 45 + g['dy'] * b0 + g.get('sy', 0) * a0
    src = Image.open(f'{EST}/map_{m}.jpg').convert('RGB')
    w = np.asarray(src.transform((W, H), Image.AFFINE, (A, Bc, Cc, D, E, F), resample=Image.BICUBIC, fillcolor=(1, 1, 1)))
    warps.append(w)
# prima il proprietario dell'esagono; se lì c'è solo il bordo della mappa, la mappa vicina
for i in range(len(PRIO)):
    msk = owner == i
    canvas[msk] = warps[i][msk]
bordo = margine(canvas) | (canvas.sum(2) < 10)
for i in range(len(PRIO)):
    w = warps[i]
    ok = bordo & ~margine(w) & (w.sum(2) > 10) & (owner >= 0)
    canvas[ok] = w[ok]
    bordo &= ~ok
del warps
img = Image.fromarray(canvas)
os.makedirs(OUT, exist_ok=True)
TW, TH = (W + 1) // 2, (H + 1) // 2
for j in range(2):
    for i in range(2):
        img.crop((i * TW, j * TH, min(W, (i + 1) * TW), min(H, (j + 1) * TH))).save(f'{OUT}/mappa_{j}{i}.webp', quality=86, method=5)
img.resize((W // 6, H // 6)).save(f'{EST}/mappa_anteprima.png')
json.dump({'larg': W, 'alt': H, 'DX': DX, 'DY': DY, 'tasselli': [TW, TH], 'esagoni': hexes, 'lati': lati,
           'mappe': OFF}, open(f'{OUT}/mappa.json', 'w'), separators=(',', ':'))
import collections
print(W, H, len(hexes), collections.Counter(h['t'] for h in hexes.values()), len(lati))
