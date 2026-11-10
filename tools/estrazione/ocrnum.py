import sys,json,re,pytesseract,numpy as np
from PIL import Image
m=sys.argv[1]
im=Image.open(f'map_{m}.jpg').convert('L')
W,H=im.size
out=[]
# tile the image for tesseract
T=900
for y0 in range(0,H,T-100):
  for x0 in range(0,W,T-100):
    c=im.crop((x0,y0,min(W,x0+T),min(H,y0+T))).resize((min(W,x0+T)-x0)*2 and ((min(W,x0+T)-x0)*2,(min(H,y0+T)-y0)*2))
    c=c.point(lambda v:0 if v<int(sys.argv[2]) else 255)
    d=pytesseract.image_to_data(c,config='--psm 11 --oem 1 -c tessedit_char_whitelist=0123456789',output_type=pytesseract.Output.DICT)
    for i,t in enumerate(d['text']):
      t=t.strip()
      if re.fullmatch(r'\d{4}',t) and int(d['conf'][i])>40:
        cx=x0+(d['left'][i]+d['width'][i]/2)/2; cy=y0+(d['top'][i]+d['height'][i]/2)/2
        out.append((t,cx,cy,int(d['conf'][i])))
json.dump(out,open(f'num_{m}_{sys.argv[2]}.json','w'))
print(m,len(out))
