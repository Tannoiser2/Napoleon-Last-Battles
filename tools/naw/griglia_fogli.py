import numpy as np, json, sys
from PIL import Image, ImageDraw
from scipy.signal import find_peaks
def linee(L, asse, lo, hi, a0, a1):
  # forza di linea scura lungo un asse: pixel più scuri dei vicini a +-3
  if asse==0:  # linee verticali: profilo sulle colonne
    S=L[a0:a1, lo:hi]
    d=(np.roll(S,3,1)+np.roll(S,-3,1))/2 - S
    return d.clip(0,None).mean(0)
  S=L[lo:hi, a0:a1]
  d=(np.roll(S,3,0)+np.roll(S,-3,0))/2 - S
  return d.clip(0,None).mean(1)
def blocco(L,x0,x1,y0,y1,nc,nr):
  # cerca le linee vicino alle posizioni attese
  px=(x1-x0)/nc; py=(y1-y0)/nr
  pv=linee(L,0,x0-8,x1+8,y0+5,y1-5); ph=linee(L,1,y0-8,y1+8,x0+5,x1-5)
  xs=[]
  for i in range(nc+1):
    e=int(round(i*px))+8; w=pv[max(0,e-6):e+7]; xs.append(x0-8+max(0,e-6)+int(np.argmax(w)))
  ys=[]
  for j in range(nr+1):
    e=int(round(j*py))+8; w=ph[max(0,e-6):e+7]; ys.append(y0-8+max(0,e-6)+int(np.argmax(w)))
  return [(xs[i],ys[j],xs[i+1],ys[j+1],j,i) for j in range(nr) for i in range(nc)]
