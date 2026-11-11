#!/usr/bin/env python3
"""Toglie dalla mappa ridisegnata (Reborn) le case dipinte negli esagoni che nell'originale sono terreno aperto:
il ridisegno aveva trasformato in villaggi le pedine di schieramento stampate sulla mappa SPI.
Per ogni esagono così si copre il gruppo di case con il prato di un esagono vicino libero (stesso
allineamento, bordi sfumati), lasciando strade, fiumi e bordi dell'esagono come sono.
Uso: ritocca_case.py mappa.json mappa_intera.png uscita.png [maschera.png]"""
import json, sys, math
import numpy as np, cv2
d = json.load(open(sys.argv[1])); e = d['esagoni']
img = cv2.imread(sys.argv[2]); H, W = img.shape[:2]
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV).astype(int)
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
erba = (h >= 17) & (h <= 48) & (s > 70)
blu = (h >= 90) & (h <= 130) & (s > 60)
nonerba = ((~erba) & (~blu)).astype(np.uint8)
casa = cv2.morphologyEx(nonerba, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
sottile = cv2.dilate(nonerba & (1 - cv2.dilate(casa, np.ones((5, 5), np.uint8))), np.ones((3, 3), np.uint8))   # strade, sentieri, ponti
tetto = (((h <= 10) | (h >= 160)) & (s > 50) & (v > 90)).astype(np.uint8)
strada = ((v > 140) & (s < 125) & (h >= 10) & (h <= 30)).astype(np.uint8)   # terra battuta chiara
n, lab, st, _ = cv2.connectedComponentsWithStats(casa, 8)
conta = np.bincount(lab.ravel(), weights=tetto.ravel(), minlength=n)
buoni = np.zeros(n, bool)
for i in range(1, n):
    a = st[i, cv2.CC_STAT_AREA]
    buoni[i] = a < 2500 and conta[i] >= 5 and conta[i] >= 0.05 * a
case = buoni[lab].astype(np.uint8)
sottile = sottile & (1 - cv2.dilate(case, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))))
R = d['DY'] / math.sqrt(3)
deco = set(d['nuova']['decorativi'])
def esa(x, y, f):
    m = np.zeros((H, W), np.uint8)
    pts = np.array([(x + R * f * math.cos(math.radians(60 * q)), y + R * f * math.sin(math.radians(60 * q))) for q in range(6)], np.int32)
    cv2.fillPoly(m, [pts], 1)
    return m
def box(x, y):
    return int(x - R) - 2, int(y - R) - 2, int(x + R) + 3, int(y + R) + 3
# quanto è "pieno" ogni esagono (per scegliere i donatori: solo prato)
pieno = {}
for k, x in e.items():
    x0, y0, x1, y1 = box(x['x'], x['y'])
    if x0 < 0 or y0 < 0 or x1 > W or y1 > H:
        continue
    r = (nonerba[y0:y1, x0:x1] | blu[y0:y1, x0:x1]).mean()
    pieno[k] = r
out = img.astype(np.float32)
M = np.zeros((H, W), np.uint8)
fatti = []
for k, x in e.items():
    if x['t'] in ('citta', 'castello') or k in deco or k not in pieno:
        continue
    x0, y0, x1, y1 = box(x['x'], x['y'])
    dentro = esa(x['x'], x['y'], 0.93)[y0:y1, x0:x1]
    c = case[y0:y1, x0:x1] & dentro
    if c.sum() < 25:
        continue
    m = cv2.morphologyEx(c, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)))
    m = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (31, 31))) & dentro
    m = m & (1 - sottile[y0:y1, x0:x1])
    # strade e sentieri che attraversano il gruppo di case: tratti non verdi senza tetti che escono dalla maschera
    lin = strada[y0:y1, x0:x1] & (1 - cv2.dilate(tetto[y0:y1, x0:x1], np.ones((9, 9), np.uint8)))
    nl, ll, sl, _ = cv2.connectedComponentsWithStats(lin, 8)
    fuori = np.bincount(ll.ravel(), weights=(m == 0).ravel(), minlength=nl)
    tieni = np.zeros(nl, bool)
    for i in range(1, nl):
        tieni[i] = fuori[i] >= 10 and sl[i, cv2.CC_STAT_AREA] >= 40
    m = m & (1 - cv2.dilate(tieni[ll].astype(np.uint8), np.ones((3, 3), np.uint8)))
    # donatore: l'esagono di prato più vicino
    best, bd = None, 1e9
    for k2, x2 in e.items():
        if k2 == k or k2 not in pieno or x2['t'] != 'aperto' or k2 in deco or d['nuova']['quote'].get(k2):
            continue
        dd = math.hypot(x2['x'] - x['x'], x2['y'] - x['y'])
        if dd > 6 * d['DX']:
            continue
        sc = dd / d['DX'] + 40 * pieno[k2]
        if sc < bd:
            bd, best = sc, k2
    if best is None:
        continue
    b0, c0, b1, c1 = box(e[best]['x'], e[best]['y'])
    dono = img[c0:c0 + (y1 - y0), b0:b0 + (x1 - x0)].astype(np.float32)
    if dono.shape[:2] != m.shape:
        continue
    # stessa luminosità media del prato attorno alle case
    intorno = (dentro > 0) & (m == 0) & (erba[y0:y1, x0:x1])
    if intorno.sum() > 200:
        dono = dono * np.clip(img[y0:y1, x0:x1][intorno].mean(0) / np.maximum(dono[intorno].mean(0), 1), 0.9, 1.1)
    a = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 3)[..., None]
    a = np.minimum(a * 1.3, 1)
    out[y0:y1, x0:x1] = out[y0:y1, x0:x1] * (1 - a) + dono * a
    M[y0:y1, x0:x1] |= m
    fatti.append(k)
cv2.imwrite(sys.argv[3], np.clip(out, 0, 255).astype(np.uint8))
if len(sys.argv) > 4:
    cv2.imwrite(sys.argv[4], M * 255)
print('esagoni ritoccati', len(fatti))
