# Ritratti degli dèi di Duat, disegnati in SVG alla maniera delle pitture egizie
# (profilo verso destra, occhio intero con il kohl, contorno scuro, collare usekh).
# Uso: python3 tools/portraits/make_portraits.py  -> scrive tools/portraits/svg/*.svg
# Poi tools/portraits/render.js li trasforma in assets/portraits/*.png (256x256).
import os
OUT = os.path.join(os.path.dirname(__file__), "svg")
os.makedirs(OUT, exist_ok=True)

INK = "#1b1209"
GOLD = "url(#gold)"
LAPIS = "#1f3f9a"
TURQ = "#2aa198"
CARN = "#b8432c"

DEFS = """
<defs>
 <linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#fff1b0"/><stop offset="0.45" stop-color="#f0b84d"/><stop offset="1" stop-color="#9a6a1c"/>
 </linearGradient>
 <linearGradient id="lapis" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#3a63c9"/><stop offset="1" stop-color="#16296b"/>
 </linearGradient>
 <radialGradient id="shade" cx="0.35" cy="0.3" r="0.8">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0.35"/><stop offset="0.6" stop-color="#ffffff" stop-opacity="0"/>
  <stop offset="1" stop-color="#000000" stop-opacity="0.35"/>
 </radialGradient>
 <linearGradient id="sun" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#ffd36a"/><stop offset="0.5" stop-color="#f2702a"/><stop offset="1" stop-color="#b3261a"/>
 </linearGradient>
 <linearGradient id="moon" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#c9d4ee"/>
 </linearGradient>
 <filter id="drop" x="-20%" y="-20%" width="140%" height="140%">
  <feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="#000" flood-opacity="0.45"/>
 </filter>
</defs>
"""

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            + DEFS + '<g transform="translate(14 24) scale(0.89)"><g filter="url(#drop)" stroke="%s" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round">' % INK
            + body + '</g></g></svg>')

def grad(id_, top, bottom):
    return ('<defs><linearGradient id="%s" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="%s"/>'
            '<stop offset="1" stop-color="%s"/></linearGradient></defs>' % (id_, top, bottom))

def shoulders(skin="#b5743f"):
    # spalle e petto nudo, poi il collare usekh a bande con le gocce
    s = '<path d="M28 256 C34 206 70 186 128 182 C186 186 222 206 228 256 Z" fill="%s"/>' % skin
    s += '<path d="M28 256 C34 206 70 186 128 182 C186 186 222 206 228 256 Z" fill="url(#shade)" stroke="none"/>'
    bands = [(GOLD, 5), (LAPIS, 7), (GOLD, 3), (TURQ, 7), (GOLD, 3), (CARN, 7), (GOLD, 5)]
    r = 46.0
    for col, w in bands:
        s += '<path d="M%.1f 186 A%.1f %.1f 0 0 0 %.1f 186" fill="none" stroke="%s" stroke-width="%.1f"/>' % (128 - r, r, r * 0.72, 128 + r, col, w + 1.6)
        s += '<path d="M%.1f 186 A%.1f %.1f 0 0 0 %.1f 186" fill="none" stroke="%s" stroke-width="%.1f"/>' % (128 - r, r, r * 0.72, 128 + r, col, w) if False else ""
        r += w + 1.5
    # gocce sul bordo esterno
    import math
    for i in range(15):
        a = math.pi * (0.06 + 0.88 * i / 14.0)
        x = 128 - math.cos(a) * (r + 2)
        y = 186 + math.sin(a) * (r + 2) * 0.72
        s += '<ellipse cx="%.1f" cy="%.1f" rx="3.2" ry="5" fill="%s" stroke-width="1.2" transform="rotate(%.1f %.1f %.1f)"/>' % (x, y, GOLD if i % 2 else CARN, math.degrees(a) - 90, x, y)
    return s

def neck(skin):
    return '<path d="M112 120 L114 186 L150 186 L146 118 Z" fill="%s"/>' % skin

def wig(color="url(#lapis)", stripes="#e9c46a", front=True):
    # parrucca tripartita: dietro la testa e la ciocca che scende davanti alla spalla
    s = '<path d="M86 64 C76 110 82 150 96 190 L128 192 C124 160 120 130 122 100 Z" fill="%s"/>' % color
    for i in range(7):
        y = 92 + i * 14
        s += '<path d="M%d %d L%d %d" stroke="%s" stroke-width="2.4"/>' % (84 + i, y, 122 + (i > 3) * 2, y + 2, stripes)
    s += '<path d="M96 186 L128 188" stroke="%s" stroke-width="4"/>' % stripes
    return s

def eye(x, y, iris="#1b1209", white="#f6efe0", glow=None, size=1.0):
    # occhio egizio: mandorla intera, pupilla, linea di kohl che va verso la tempia
    w, h = 13 * size, 6 * size
    s = '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f Q%.1f %.1f %.1f %.1f Z" fill="%s" stroke-width="1.8"/>' % (
        x - w, y, x, y - h * 1.6, x + w, y, x, y + h * 1.3, x - w, y, white)
    s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="none"/>' % (x + 1.5 * size, y, 4.2 * size, glow or iris)
    s += '<circle cx="%.1f" cy="%.1f" r="1.3" fill="#fff" stroke="none"/>' % (x + 2.8 * size, y - 1.6 * size)
    s += '<path d="M%.1f %.1f L%.1f %.1f" stroke-width="3"/>' % (x - w, y, x - w - 16 * size, y + 2)
    s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" fill="none" stroke-width="2.6"/>' % (x - w + 2, y - h * 2.0, x, y - h * 3.0, x + w, y - h * 1.9)
    return s

def uraeus(x, y, s=1.0):
    # il cobra reale sulla fronte
    return ('<path d="M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f Z" fill="%s"/>' % (
        x, y, x + 4 * s, y - 14 * s, x + 12 * s, y - 16 * s, x + 10 * s, y - 4 * s, x + 9 * s, y + 2 * s, x + 4 * s, y + 4 * s, x, y, GOLD)
        + '<circle cx="%.1f" cy="%.1f" r="1.6" fill="%s" stroke="none"/>' % (x + 8 * s, y - 10 * s, CARN))

def sun_disk(cx, cy, r):
    return ('<circle cx="%d" cy="%d" r="%d" fill="url(#sun)"/>' % (cx, cy, r)
            + '<circle cx="%d" cy="%d" r="%d" fill="url(#shade)" stroke="none"/>' % (cx, cy, r))

P = {}

# ---------------- Anubi: lo sciacallo nero, con le orecchie alte e l'oro
skin = "#7a4a26"
P["anubi"] = svg(shoulders(skin) + neck("#141016") + wig()
    + '<path d="M104 64 L104 6 L126 60 Z" fill="#141016"/><path d="M108 58 L108 22 L120 56 Z" fill="url(#gold)" stroke-width="1"/>'
    + '<path d="M122 62 L132 4 L146 64 Z" fill="#1b1720"/><path d="M127 58 L132 20 L140 58 Z" fill="#c0392b" stroke-width="1"/>'
    + '<path d="M96 96 C96 64 118 52 140 56 C156 58 166 68 172 78 L214 94 C220 96 220 106 214 108 L176 118 C160 124 140 130 120 128 C104 126 96 114 96 96 Z" fill="#141016"/>'
    + '<path d="M96 96 C96 64 118 52 140 56 C156 58 166 68 172 78 L214 94 C220 96 220 106 214 108 L176 118 C160 124 140 130 120 128 C104 126 96 114 96 96 Z" fill="url(#shade)" stroke="none"/>'
    + '<circle cx="213" cy="99" r="4" fill="#000"/>'
    + '<path d="M176 114 Q190 114 206 108" fill="none" stroke="#3a2f3a" stroke-width="1.6"/>'
    + eye(150, 84, glow="#f0b84d")
    + '<path d="M112 128 Q130 140 150 128" fill="none" stroke="url(#gold)" stroke-width="5"/>')

# ---------------- Horus: il falco con la doppia corona
feath = "#6b4a2b"
P["horus"] = svg(shoulders("#b5743f") + neck(feath) + wig("#3b2a1c", "#c9a36a")
    # doppia corona: rossa (Basso Egitto) con il ricciolo, bianca (Alto Egitto) che sale
    + '<path d="M116 44 C112 18 120 -6 134 -8 C150 -6 156 14 150 44 Z" fill="#f4efe2"/>'
    + '<path d="M128 -6 C130 10 130 26 128 42" fill="none" stroke="#cfc6b0" stroke-width="1.4"/>'
    + '<path d="M92 66 L92 8 L108 8 L110 42 L162 44 L168 66 Z" fill="#c0392b"/>'
    + '<path d="M92 66 L92 8 L108 8 L110 42 L162 44 L168 66 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M150 46 C164 40 168 28 160 22 C154 18 148 24 154 28" fill="none" stroke="url(#gold)" stroke-width="3"/>'
    + '<path d="M96 100 C94 72 112 60 136 60 C160 60 176 74 178 92 C176 100 172 108 168 112 C160 128 140 134 122 132 C104 128 96 116 96 100 Z" fill="%s"/>' % feath
    + '<path d="M96 100 C94 72 112 60 136 60 C160 60 176 74 178 92 C176 100 172 108 168 112 C160 128 140 134 122 132 C104 128 96 116 96 100 Z" fill="url(#shade)" stroke="none"/>'
    # becco adunco
    + '<path d="M168 84 C180 80 194 86 198 98 C200 106 196 114 190 118 C190 110 186 104 176 104 L168 104 Z" fill="#2b2016"/>'
    + '<path d="M176 104 C184 104 189 108 190 116" fill="none" stroke="#000" stroke-width="1.2"/>'
    + '<path d="M136 96 C140 108 150 114 166 108 C162 120 146 126 132 120 Z" fill="#c9a77a" stroke="none" opacity="0.8"/>'
    + '<path d="M148 94 C146 104 142 114 134 122" fill="none" stroke-width="4.5"/>'
    + eye(154, 88, glow="#f0b84d")
    + uraeus(160, 64, 0.8))

# ---------------- Ra: il falco d'oro sotto il disco solare
P["ra"] = svg(shoulders("#b5743f") + neck("#8a5a26") + wig("url(#lapis)", "#f0b84d")
    + sun_disk(132, 30, 30) + uraeus(150, 58, 1.0)
    + '<path d="M96 100 C94 72 112 60 136 60 C160 60 176 74 178 92 C176 100 172 108 168 112 C160 128 140 134 122 132 C104 128 96 116 96 100 Z" fill="#a8732f"/>'
    + '<path d="M96 100 C94 72 112 60 136 60 C160 60 176 74 178 92 C176 100 172 108 168 112 C160 128 140 134 122 132 C104 128 96 116 96 100 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M168 84 C180 80 194 86 198 98 C200 106 196 114 190 118 C190 110 186 104 176 104 L168 104 Z" fill="#3a2a14"/>'
    + '<path d="M176 104 C184 104 189 108 190 116" fill="none" stroke="#000" stroke-width="1.2"/>'
    + '<path d="M136 96 C140 108 150 114 166 108 C162 120 146 126 132 120 Z" fill="#e2b866" stroke="none" opacity="0.8"/>'
    + '<path d="M148 94 C146 104 142 114 134 122" fill="none" stroke-width="4.5"/>'
    + eye(154, 88, glow="#ff8a2a"))

# ---------------- Sekhmet: la leonessa con il disco e il cobra
fur = "#c98a3c"
P["sekhmet"] = svg(shoulders("#b5743f") + neck(fur)
    # criniera
    + '<path d="M84 70 C70 110 78 160 100 190 L134 190 C126 160 126 130 130 104 Z" fill="#8f5a24"/>'
    + ''.join('<path d="M%d %d q8 6 0 14" fill="none" stroke="#5c3612" stroke-width="2"/>' % (90 + (i % 3) * 8, 96 + i * 12) for i in range(7))
    + sun_disk(124, 34, 24) + uraeus(142, 56, 0.9)
    + '<path d="M96 96 C96 66 118 56 142 58 C160 60 172 72 176 86 L196 96 C202 100 202 112 196 116 L178 124 C166 132 140 136 120 132 C104 128 96 114 96 96 Z" fill="%s"/>' % fur
    + '<path d="M96 96 C96 66 118 56 142 58 C160 60 172 72 176 86 L196 96 C202 100 202 112 196 116 L178 124 C166 132 140 136 120 132 C104 128 96 114 96 96 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M110 66 L106 48 L124 60 Z" fill="%s"/>' % fur
    + '<path d="M190 100 C194 102 196 106 194 110" fill="none" stroke-width="2"/>'
    + '<circle cx="197" cy="102" r="3" fill="#3a1f0e"/>'
    + '<path d="M178 122 L172 128 L166 122" fill="#fff" stroke-width="1.4"/>'
    + ''.join('<path d="M%d %d l10 -2" stroke="#7a4b1c" stroke-width="1.4"/>' % (176, 110 + i * 4) for i in range(3))
    + eye(154, 86, glow="#e0a020"))

# ---------------- Bastet: la gatta nera con l'orecchino d'oro
cat = "#2a2430"
P["bastet"] = svg(shoulders("#b5743f") + neck(cat) + wig("url(#lapis)", "#f0b84d")
    + '<path d="M108 70 L104 22 L134 58 Z" fill="%s"/><path d="M112 62 L110 36 L126 56 Z" fill="#d98a7a" stroke-width="1"/>' % cat
    + '<path d="M136 60 L150 18 L162 66 Z" fill="%s"/><path d="M142 58 L150 32 L156 62 Z" fill="#d98a7a" stroke-width="1"/>' % cat
    + '<path d="M98 100 C98 72 120 60 144 62 C166 64 178 78 182 94 C194 98 198 108 192 116 C186 124 174 126 168 122 C156 132 138 134 122 130 C106 126 98 114 98 100 Z" fill="%s"/>' % cat
    + '<path d="M98 100 C98 72 120 60 144 62 C166 64 178 78 182 94 C194 98 198 108 192 116 C186 124 174 126 168 122 C156 132 138 134 122 130 C106 126 98 114 98 100 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M188 104 L196 104" stroke-width="2"/><circle cx="194" cy="101" r="2.6" fill="#d98a7a"/>'
    + ''.join('<path d="M180 %d l22 %d" stroke="#d9d2c2" stroke-width="1"/>' % (110 + i * 3, -4 + i * 4) for i in range(3))
    + '<circle cx="124" cy="116" r="7" fill="none" stroke="url(#gold)" stroke-width="3.5"/>'
    + '<path d="M122 66 C130 60 140 60 150 64" fill="none" stroke="url(#gold)" stroke-width="3"/>'
    + eye(156, 90, iris="#1b1209", white="#9be36b", glow="#0c3a12"))

# ---------------- Thoth: l'ibis con la luna
P["thoth"] = svg(shoulders("#b5743f") + neck("#e9e3d6") + wig("url(#lapis)", "#f0b84d")
    + '<path d="M104 30 C106 58 158 58 160 30 C150 48 114 48 104 30 Z" fill="url(#moon)"/>'
    + '<circle cx="132" cy="26" r="17" fill="url(#moon)"/>'
    + '<circle cx="132" cy="26" r="17" fill="url(#shade)" stroke="none"/>'
    + '<path d="M102 98 C100 72 118 62 138 62 C156 62 168 74 168 92 C166 112 150 128 126 128 C110 128 102 114 102 98 Z" fill="#efe9dc"/>'
    + '<path d="M102 98 C100 72 118 62 138 62 C156 62 168 74 168 92 C166 112 150 128 126 128 C110 128 102 114 102 98 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M104 82 C112 70 126 66 140 70 C130 76 116 84 104 96 Z" fill="#1b1209" stroke-width="1"/>'
    # il lungo becco ricurvo
    + '<path d="M164 88 C190 92 214 112 226 146 C228 152 222 154 220 148 C208 120 188 104 162 102 Z" fill="#1d1a20"/>'
    + '<path d="M168 92 C190 98 206 114 218 140" fill="none" stroke="#5a5560" stroke-width="1.2"/>'
    + eye(146, 86, glow="#2d6fd6"))

# ---------------- Sobek: il coccodrillo con le piume e il disco
croc = "#4f6b2c"
P["sobek"] = svg(shoulders("#b5743f") + neck(croc) + wig("url(#lapis)", "#f0b84d")
    + '<path d="M112 52 L118 0 L128 52 Z" fill="#f4efe2"/><path d="M128 52 L136 -2 L146 52 Z" fill="#f4efe2"/>'
    + '<path d="M118 4 L120 50 M136 0 L137 50" stroke="#b9b09a" stroke-width="1.2"/>'
    + sun_disk(128, 48, 13)
    + '<path d="M92 56 C110 46 150 46 170 58" fill="none" stroke="url(#gold)" stroke-width="5"/>'
    + '<path d="M98 98 C98 72 118 62 140 64 C156 66 166 74 172 82 L222 96 C230 98 230 110 222 112 L172 124 C160 130 140 132 122 130 C106 128 98 114 98 98 Z" fill="%s"/>' % croc
    + '<path d="M98 98 C98 72 118 62 140 64 C156 66 166 74 172 82 L222 96 C230 98 230 110 222 112 L172 124 C160 130 140 132 122 130 C106 128 98 114 98 98 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M172 110 L224 104" fill="none" stroke-width="1.6"/>'
    + ''.join('<path d="M%d 110 l3 5 l3 -5" fill="#fffbe8" stroke-width="1"/>' % (178 + i * 8) for i in range(6))
    + ''.join('<circle cx="%d" cy="%d" r="2.2" fill="#3a5220" stroke="none"/>' % (120 + (i % 4) * 12, 74 + (i // 4) * 12) for i in range(8))
    + '<path d="M146 74 C152 68 162 70 166 76" fill="%s"/>' % croc
    + eye(152, 82, white="#e8d36a", glow="#2b1a05", size=0.9))

# ---------------- Iside: la dea con il trono sul capo
skin_i = "#c98a56"
P["iside"] = svg(shoulders(skin_i) + neck(skin_i)
    # parrucca nera lunga con la fascia
    + '<path d="M90 70 C84 116 88 156 100 192 L134 192 C128 160 124 130 126 104 C126 88 124 70 118 60 Z" fill="#14121a"/>'
    + ''.join('<path d="M%d %d L%d %d" stroke="#2c2836" stroke-width="2"/>' % (92 + i * 5, 80, 96 + i * 5, 186) for i in range(6))
    # il trono, geroglifico del suo nome
    + '<path d="M112 46 L112 10 L130 10 L130 28 L152 28 L152 46 Z" fill="url(#gold)"/>'
    + '<path d="M116 40 L148 40 M116 34 L126 34" stroke="#8a5a14" stroke-width="2"/>'
    + '<path d="M104 58 C104 50 150 48 156 58" fill="none" stroke="url(#gold)" stroke-width="5"/>'
    # viso di profilo
    + '<path d="M106 96 C104 70 122 56 144 58 C158 60 166 70 166 84 C166 88 172 94 176 100 C178 104 174 106 170 106 C172 110 170 112 168 114 C170 118 166 122 162 122 C162 128 156 134 146 134 C132 136 118 132 112 124 C106 116 106 106 106 96 Z" fill="%s"/>' % skin_i
    + '<path d="M106 96 C104 70 122 56 144 58 C158 60 166 70 166 84 C166 88 172 94 176 100 C178 104 174 106 170 106 C172 110 170 112 168 114 C170 118 166 122 162 122 C162 128 156 134 146 134 C132 136 118 132 112 124 C106 116 106 106 106 96 Z" fill="url(#shade)" stroke="none"/>'
    + '<path d="M162 116 Q166 118 168 116" fill="none" stroke="#9a3a2a" stroke-width="2.4"/>'
    + '<path d="M96 66 C110 58 130 56 150 60 L148 74 C130 70 112 74 100 82 Z" fill="#14121a"/>'
    + '<circle cx="122" cy="118" r="6" fill="none" stroke="url(#gold)" stroke-width="3"/>'
    + eye(150, 88, glow="#2b1a10", size=0.85))

# ---------------- Set: il suo animale, muso ricurvo e orecchie squadrate
red = "#8e2f22"
P["set"] = svg(shoulders("#a8653a") + neck(red) + wig("#3a1410", "#c0392b")
    + '<path d="M108 64 L104 12 L112 10 L120 62 Z" fill="%s"/><path d="M98 14 L118 10 L118 2 L100 4 Z" fill="%s"/>' % (red, red)
    + '<path d="M126 62 L126 8 L134 8 L138 62 Z" fill="#a33a2b"/><path d="M120 10 L140 8 L140 0 L122 2 Z" fill="#a33a2b"/>'
    + '<path d="M98 98 C98 70 118 60 140 62 C156 64 166 72 172 82 C190 82 206 92 214 108 C216 114 210 118 204 114 C196 108 186 108 176 116 C162 128 140 132 122 130 C106 128 98 114 98 98 Z" fill="%s"/>' % red
    + '<path d="M98 98 C98 70 118 60 140 62 C156 64 166 72 172 82 C190 82 206 92 214 108 C216 114 210 118 204 114 C196 108 186 108 176 116 C162 128 140 132 122 130 C106 128 98 114 98 98 Z" fill="url(#shade)" stroke="none"/>'
    + '<circle cx="208" cy="108" r="2.6" fill="#1b1209"/>'
    + eye(150, 86, glow="#ff5a3a"))

for k, v in P.items():
    with open(os.path.join(OUT, k + ".svg"), "w") as f:
        f.write(v)
print("ok", len(P))
