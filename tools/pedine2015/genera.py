#!/usr/bin/env python3
"""Pedine dell'edizione 2015 (Decision Games): ritaglia fronte e retro dai fogli e salva
assets/pedine2015/<id>.webp e <id>r.webp (retro = forza ridotta).
Uso: genera.py CARTELLA_FOGLI assets/pedine2015
I fogli: front1.png back1.png front2.png back2.png; celle.json ha la griglia di ogni foglio."""
import json, sys, os
from PIL import Image, ImageFilter
FOGLI, OUT = sys.argv[1], sys.argv[2]
QUI = os.path.dirname(os.path.abspath(__file__))
C = json.load(open(f'{QUI}/celle.json'))
LATO = int(sys.argv[3]) if len(sys.argv) > 3 else 160
os.makedirs(OUT, exist_ok=True)
img = {f: Image.open(f'{FOGLI}/{f}.png').convert('RGB') for f in C}
idx = {(f, c['meta'], c['riga'], c['col']): c for f in C for c in C[f]}
RETRO = {'front1': 'back1', 'front2': 'back2'}
def taglia(f, m, r, k):
    c = idx[(f, m, r, k)]
    x0, y0 = c['x'] + 1.5, c['y'] + 1.5
    x1, y1 = c['x'] + c['w'] - 1.5, c['y'] + c['h'] - 1.5
    t = img[f].resize((img[f].width * 4, img[f].height * 4), Image.LANCZOS, box=None) if False else None
    cr = img[f].crop((int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))))
    cr = cr.resize((LATO, LATO), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=1.4, percent=70, threshold=2))
    return cr
n = 0
for l in open(f'{QUI}/abbinamenti.txt'):
    l = l.split('#')[0].split()
    if not l:
        continue
    id_, f, m, r, k = l[0], l[1], int(l[2]), int(l[3]), int(l[4])
    taglia(f, m, r, k).save(f'{OUT}/{id_}.webp', quality=90)
    if id_.startswith('u'):
        taglia(RETRO[f], 1 - m, r, 9 - k).save(f'{OUT}/{id_}r.webp', quality=90)
    n += 1
print('pedine', n)
