#!/usr/bin/env python3
"""Fogli di contatto: python3 tools/dev/sheet.py CARTELLA [colonne righe] → CARTELLA/sheet_NN.jpg"""
import sys, glob, os
from PIL import Image, ImageDraw
d = sys.argv[1]; cols = int(sys.argv[2]) if len(sys.argv) > 2 else 3; rows = int(sys.argv[3]) if len(sys.argv) > 3 else 3
files = sorted(f for f in glob.glob(os.path.join(d, "*.png")))
tw = 1920 // cols
for i in range(0, len(files), cols * rows):
    batch = files[i:i + cols * rows]
    im0 = Image.open(batch[0]); th = int(tw * im0.height / im0.width)
    sheet = Image.new("RGB", (tw * cols, th * rows), (0, 0, 0))
    for k, f in enumerate(batch):
        im = Image.open(f).convert("RGB").resize((tw, th), Image.LANCZOS)
        ImageDraw.Draw(im).text((6, th - 16), os.path.basename(f)[:-4], fill=(255, 255, 0))
        sheet.paste(im, ((k % cols) * tw, (k // cols) * th))
    out = os.path.join(d, "sheet_%02d.jpg" % (i // (cols * rows)))
    sheet.save(out, quality=82)
    print(out)
