#!/usr/bin/env python3
"""Correzioni dei terreni trovate confrontando i dati estratti dalle scansioni con le mappe ridisegnate:
titoli, rose dei venti, nomi e simboli di schieramento stampati in blu erano stati letti come paesi o
corsi d'acqua. Il terreno vero di quegli esagoni viene dalla mappa nuova (lago, bosco o aperto).
Seconda revisione (confronto esagono per esagono con le scansioni originali): le pedine di schieramento
stampate in blu sulla mappa di La Belle Alliance erano state lette come paesi (82 esagoni), mentre 33 paesi
veri (St-Amand, Ligny, Fleurus, Tilly, Mellet, Wavre...) erano rimasti terreno aperto.
Uso: correggi_terreni.py mappa.json correzioni.json"""
import json, sys
mj = json.load(open(sys.argv[1]))
cor = json.load(open(sys.argv[2]))
for k, t in cor['esagoni'].items():
    mj['esagoni'][k]['t'] = t
for k in cor['lati_senza_acqua']:
    v = mj['lati'].get(k, '')
    v = v.lstrip('FT').lstrip('p')
    if v:
        mj['lati'][k] = v
    else:
        mj['lati'].pop(k, None)
json.dump(mj, open(sys.argv[1], 'w'), separators=(',', ':'))
print('esagoni corretti', len(cor['esagoni']), 'lati senza acqua', len(cor['lati_senza_acqua']))
