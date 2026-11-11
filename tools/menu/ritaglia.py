"""Ritaglia la tavola del menu (quattro battaglie 2x2 e medaglione della campagna) nelle immagini usate dal gioco."""
import sys
from PIL import Image, ImageDraw
src = Image.open(sys.argv[1] if len(sys.argv) > 1 else "tools/menu/tavola_menu.png").convert("RGB")
W = src.size[0]
k = W / 1254.0
schede = {"bellealliance": (9, 9, 620, 620), "wavre": (633, 9, 1245, 620),
          "quatrebras": (9, 632, 620, 1245), "ligny": (633, 632, 1245, 1245)}
for n, b in schede.items():
    src.crop(tuple(round(x * k) for x in b)).save(f"assets/ui/menu_{n}.webp", quality=90)
cx, cy, r = 620 * k, 614 * k, 262 * k
box = (round(cx - r), round(cy - r), round(cx + r), round(cy + r))
med = src.crop(box).convert("RGBA")
s = 4
mask = Image.new("L", (med.size[0] * s, med.size[1] * s), 0)
ImageDraw.Draw(mask).ellipse((0, 0, mask.size[0] - 1, mask.size[1] - 1), fill=255)
med.putalpha(mask.resize(med.size, Image.LANCZOS))
med.save("assets/ui/menu_campagna.webp", quality=92)
print("ok", med.size)
