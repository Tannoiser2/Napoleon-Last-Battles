import numpy as np
from scipy import ndimage
def maschere(A):
  r,g,b=A[...,0],A[...,1],A[...,2]
  M={}
  M['acqua']=(b>r+40)&(b>120)
  M['casa']=(b>r+6)&(r<180)&(r>60)&~M['acqua']&(abs(g-r)<30)
  M['nero']=(r+g+b<210)
  M['verde']=(g>b+35)&(g>r-20)&(r<175)&(g<190)&~((r>g+25))
  M['ocra']=(r>g+30)&(b<90)&(r>120)
  M['grigio']=(abs(r-g)<18)&(abs(g-b)<30)&(r<165)&(r>90)&(b>80)
  M['beige']=(r>190)&(g>170)&(b>120)
  return M
