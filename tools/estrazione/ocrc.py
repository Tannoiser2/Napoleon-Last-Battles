import json,pytesseract,numpy as np
from PIL import Image,ImageOps
IM='/home/claude/src/nlb/tts/Mods/Images/'
U=json.load(open('uniq.json'))
def txt(im,cfg):
  im=ImageOps.grayscale(im); a=np.asarray(im)
  # dark text on any bg: threshold relative
  b=Image.fromarray(np.where(a<90,0,255).astype(np.uint8))
  b=b.resize((b.width*3,b.height*3))
  b=ImageOps.expand(b,20,255)
  return pytesseract.image_to_string(b,config=cfg).strip()
out=[]
for i,(f,bk) in enumerate(U):
  r={}
  for side,fn in (('f',f),('b',bk)):
    im=Image.open(IM+fn).convert('RGB')
    r[side+'_val']=txt(im.crop((20,55,180,110)),'--psm 7 -c tessedit_char_whitelist=0123456789-')
  im=Image.open(IM+f).convert('RGB')
  r['name']=txt(im.crop((0,0,42,125)).rotate(-90,expand=True),'--psm 7')
  r['des']=txt(im.crop((145,0,180,80)).rotate(-90,expand=True),'--psm 7')
  r['bg']=im.getpixel((100,172))
  r['bgb']=Image.open(IM+bk).convert('RGB').getpixel((100,5))
  out.append(r)
  print(i,r)
json.dump(out,open('ocrc.json','w'))
