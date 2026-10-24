"""Genera gli effetti sonori provvisori di Duat (file .wav in assets/sfx).
Sono suoni sintetizzati, quindi liberi da qualsiasi licenza. Per usare suoni veri
basta mettere in assets/sfx un file .wav o .ogg con lo stesso nome: ha la precedenza.
Uso: python tools/make_sfx.py"""
import math, random, struct, wave, os

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def save(name, s, gain=0.8):
    os.makedirs(OUT, exist_ok=True)
    s = lowpass(s, 7000)                       # niente fischi acuti
    peak = max(1e-6, max(abs(v) for v in s))
    fade = int(RATE * 0.004)
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = []
        for i, v in enumerate(s):
            if i >= len(s) - fade:
                v *= (len(s) - i) / fade
            frames.append(struct.pack("<h", int(v / peak * gain * 32767)))
        w.writeframes(b"".join(frames))


def lowpass(s, cutoff):
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    out, y = [], 0.0
    for v in s:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(s, cutoff):
    lp = lowpass(s, cutoff)
    return [v - l for v, l in zip(s, lp)]


def decay(n, attack, k):
    """Inviluppo: salita rapida e discesa esponenziale (k = velocità di spegnimento)."""
    out = []
    for i in range(n):
        t = i / RATE
        a = min(1.0, t / attack) if attack > 0 else 1.0
        out.append(a * math.exp(-k * t))
    return out


def tone(f0, f1, dur, attack=0.003, k=8.0, harm=(1.0,), vib=0.0):
    n = int(RATE * dur)
    e = decay(n, attack, k)
    out, ph = [], 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t                    # glissando esponenziale, più naturale
        f *= 1.0 + vib * math.sin(2 * math.pi * 6 * i / RATE)
        ph += 2 * math.pi * f / RATE
        v = sum(a * math.sin(ph * (h + 1)) for h, a in enumerate(harm))
        out.append(v * e[i])
    return out


def noise(dur, attack=0.002, k=10.0, color=0.5):
    n = int(RATE * dur)
    e = decay(n, attack, k)
    out, y = [], 0.0
    for i in range(n):
        y += color * (random.uniform(-1, 1) - y)
        out.append(y * e[i])
    return out


def swish(dur, f_lo, f_hi, peak=0.5):
    """Fruscio che sale e scende di tono: per fendenti e scatti."""
    n = int(RATE * dur)
    out, y = [], 0.0
    for i in range(n):
        t = i / n
        c = (f_lo + (f_hi - f_lo) * math.sin(math.pi * t)) / RATE
        y += min(1.0, c * 6.0) * (random.uniform(-1, 1) - y)
        env = math.sin(math.pi * min(1.0, t / peak) * 0.5) if t < peak else math.cos(math.pi * 0.5 * (t - peak) / (1 - peak))
        out.append(y * env)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] * g for p, g in parts if i < len(p)) for i in range(n)]


def delay(s, secs):
    return [0.0] * int(RATE * secs) + s


random.seed(11)
save("swing", highpass(swish(0.14, 600, 2600, 0.35), 300), 0.55)
save("hit", mix((tone(150, 70, 0.12, 0.001, 30, (1.0, 0.3)), 1.0), (lowpass(noise(0.05, 0.001, 60, 0.9), 2500), 0.5)))
save("crit", mix((tone(150, 70, 0.12, 0.001, 30, (1.0, 0.3)), 1.0), (lowpass(noise(0.05, 0.001, 60, 0.9), 2500), 0.5),
                 (tone(1320, 1320, 0.35, 0.001, 9, (1.0, 0.25, 0.1)), 0.35)))
save("kill", mix((lowpass(noise(0.25, 0.001, 14, 0.6), 1500), 0.9), (tone(260, 90, 0.22, 0.001, 14), 0.5)), 0.7)
save("dash", highpass(swish(0.17, 400, 1800, 0.3), 200), 0.5)
save("eye", mix((tone(520, 1040, 0.28, 0.01, 7, (1.0, 0.0, 0.3), 0.01), 0.7), (delay(tone(780, 1560, 0.22, 0.01, 9), 0.03), 0.3)), 0.55)
save("hurt", mix((tone(220, 130, 0.2, 0.001, 12, (1.0, 0.5, 0.25)), 1.0), (lowpass(noise(0.08, 0.001, 40, 0.8), 2000), 0.4)), 0.75)
save("death", mix((tone(300, 60, 1.0, 0.01, 3, (1.0, 0.4, 0.2)), 1.0), (lowpass(noise(0.8, 0.05, 3, 0.3), 600), 0.4)), 0.8)
save("pickup", mix((tone(784, 784, 0.18, 0.002, 14, (1.0, 0.2)), 1.0), (delay(tone(1175, 1175, 0.3, 0.002, 9, (1.0, 0.2)), 0.08), 1.0)), 0.5)
save("boon", mix((tone(523, 523, 0.9, 0.005, 3, (1.0, 0.3, 0.1)), 0.7), (delay(tone(659, 659, 0.8, 0.005, 3.5, (1.0, 0.3)), 0.09), 0.6),
                 (delay(tone(784, 784, 0.75, 0.005, 3.5, (1.0, 0.3)), 0.18), 0.6), (delay(tone(1047, 1047, 0.7, 0.005, 4, (1.0,), 0.004), 0.27), 0.5)), 0.55)
save("door", mix((lowpass(noise(0.6, 0.06, 4, 0.2), 400), 1.0), (tone(70, 55, 0.6, 0.05, 4), 0.6)), 0.7)
save("spikes", mix((highpass(noise(0.08, 0.001, 45, 0.95), 1500), 0.7), (tone(2100, 1900, 0.12, 0.001, 30, (1.0, 0.5)), 0.25)), 0.45)
save("dart", highpass(swish(0.13, 1200, 3500, 0.2), 800), 0.4)
save("roar", mix((lowpass(noise(1.0, 0.08, 2.5, 0.25), 700), 1.0), (tone(110, 70, 1.0, 0.08, 2.5, (1.0, 0.6, 0.4, 0.3)), 0.6)), 0.8)
save("charge", mix((lowpass(noise(0.4, 0.05, 5, 0.2), 500), 1.0), (tone(80, 60, 0.4, 0.04, 5), 0.5)), 0.65)
save("bite", mix((lowpass(noise(0.12, 0.001, 30, 0.8), 2200), 0.9), (tone(180, 90, 0.1, 0.001, 35, (1.0, 0.5)), 0.6)), 0.7)
save("ui", tone(1500, 1500, 0.05, 0.001, 70, (1.0, 0.2)), 0.35)
save("divine", mix((tone(220, 440, 0.9, 0.05, 2.5, (1.0, 0.5, 0.3), 0.006), 0.8), (delay(tone(330, 660, 0.8, 0.05, 3, (1.0, 0.3)), 0.1), 0.5),
                   (lowpass(noise(0.9, 0.1, 3, 0.3), 1200), 0.3)), 0.7)
print("ok")
