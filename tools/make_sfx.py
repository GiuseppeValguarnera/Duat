"""Genera gli effetti sonori provvisori di Duat (file .wav in assets/sfx).
Sono suoni sintetizzati, quindi liberi da qualsiasi licenza: si sostituiscono
con suoni veri più avanti. Uso: python tools/make_sfx.py"""
import math, random, struct, wave, os

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.85 * 32767)) for s in samples))


def env(i, n, attack=0.01, release=0.6):
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = 1.0 if t < 1 - release else max(0.0, (1 - t) / release)
    return a * r


def sweep(f0, f1, dur, shape="sine", attack=0.01, release=0.7, vib=0.0):
    n = int(RATE * dur)
    out, ph = [], 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        f *= 1.0 + vib * math.sin(i / RATE * 2 * math.pi * 18)
        ph += 2 * math.pi * f / RATE
        if shape == "sine":
            v = math.sin(ph)
        elif shape == "square":
            v = 1.0 if math.sin(ph) > 0 else -1.0
        else:
            v = 2.0 * ((ph / (2 * math.pi)) % 1.0) - 1.0
        out.append(v * env(i, n, attack, release))
    return out


def noise(dur, cutoff=0.3, attack=0.01, release=0.8, rising=False):
    n = int(RATE * dur)
    out, y = [], 0.0
    for i in range(n):
        t = i / n
        c = cutoff * (0.3 + 1.4 * t) if rising else cutoff
        y += min(1.0, c) * (random.uniform(-1, 1) - y)
        out.append(y * env(i, n, attack, release))
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def gain(p, g):
    return [s * g for s in p]


random.seed(7)
save("swing", noise(0.12, 0.25, 0.25, 0.7, rising=True))
save("hit", mix(sweep(170, 60, 0.09, attack=0.001), gain(noise(0.03, 0.9, 0.001, 0.9), 0.5)))
save("crit", mix(sweep(170, 60, 0.09, attack=0.001), gain(sweep(1400, 1200, 0.25, attack=0.001, release=0.9), 0.4)))
save("kill", mix(gain(noise(0.2, 0.12, 0.001, 0.9), 0.9), gain(sweep(300, 90, 0.2, attack=0.001), 0.6)))
save("dash", noise(0.16, 0.35, 0.05, 0.8, rising=True))
save("eye", gain(sweep(600, 1400, 0.22, attack=0.02, release=0.6, vib=0.03), 0.6))
save("hurt", mix(sweep(260, 110, 0.18, "square", 0.001, 0.8), gain(noise(0.08, 0.6, 0.001, 0.9), 0.4)))
save("death", sweep(320, 50, 0.9, "saw", 0.01, 0.6))
save("pickup", sweep(660, 660, 0.09, attack=0.005) + sweep(990, 990, 0.16, attack=0.005))
save("boon", mix(sweep(523, 523, 0.5, attack=0.01), [0.0] * 2000 + sweep(659, 659, 0.45, attack=0.01), [0.0] * 4000 + sweep(784, 784, 0.4, attack=0.01, vib=0.004)))
save("door", gain(noise(0.45, 0.04, 0.05, 0.7), 1.0))
save("spikes", mix(gain(noise(0.09, 0.95, 0.001, 0.9), 0.7), gain(sweep(2400, 1800, 0.08, attack=0.001), 0.25)))
save("dart", gain(sweep(1900, 1200, 0.12, attack=0.002, release=0.9), 0.5))
save("roar", mix(sweep(95, 70, 0.8, "saw", 0.05, 0.5), gain(noise(0.8, 0.05, 0.05, 0.5), 0.8)))
save("charge", gain(noise(0.35, 0.06, 0.02, 0.6), 1.0))
save("bite", mix(gain(noise(0.1, 0.7, 0.001, 0.9), 0.8), sweep(140, 70, 0.1, "square", 0.001, 0.9)))
save("ui", gain(sweep(1000, 1000, 0.04, attack=0.001), 0.5))
save("divine", mix(sweep(220, 440, 0.6, "saw", 0.02, 0.5), gain(sweep(660, 880, 0.6, attack=0.02, vib=0.01), 0.6)))
print("ok")
