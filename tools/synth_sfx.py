# Suoni creati per Duat a partire dai pacchetti CC0 di Kenney e da rumore sintetico (ffmpeg).
# Uso: python3 tools/synth_sfx.py <cartella con i pacchetti Kenney> assets/sfx
# Ogni voce: nome -> lista di varianti; ogni variante è (ingressi, filter_complex, durata).
# Gli ingressi sono file Kenney o sorgenti lavfi ("lavfi:..."); il filtro finisce in [out].
import subprocess, re, sys, glob
SRC = sys.argv[1]; OUT = sys.argv[2]
I, U, R = SRC + "/Audio impact/", SRC + "/Audio interfaccia/", SRC + "/Audio rpg/"
SR = 44100

def noise(color, dur, amp=0.8):
    return "lavfi:anoisesrc=color=%s:duration=%.2f:amplitude=%.2f:sample_rate=%d" % (color, dur, amp, SR)

def sine(f, dur):
    return "lavfi:sine=frequency=%.1f:duration=%.2f:sample_rate=%d" % (f, dur, SR)

def env(dur, attack, release):
    # inviluppo: sale in `attack` secondi, scende negli ultimi `release`
    return "afade=t=in:d=%.3f,afade=t=out:st=%.3f:d=%.3f" % (attack, max(0.0, dur - release), release)

V = {}

# Spuntoni: la lastra che scatta (tonfo di pietra) + le lame che escono (stridio metallico breve).
# Niente bassi profondi: sugli altoparlanti del telefono non si sentirebbero.
V["spikes"] = []
for k, (pitch, hp) in enumerate([(1.0, 2600), (1.12, 3000), (0.9, 2300)]):
    V["spikes"].append(([I + "impactWood_light_00%d.ogg" % k, R + "drawKnife%d.ogg" % (k + 1), noise("white", 0.12)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*0.9,aresample=%d,volume=1.2[thud];"
        "[1:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*%.2f,aresample=%d,atempo=1.8,atrim=0:0.22,afade=t=out:st=0.08:d=0.14,highpass=f=1500,lowpass=f=7000,volume=1.0,adelay=20[blade];"
        "[2:a]highpass=f=%d,lowpass=f=7000,%s,volume=0.25,adelay=15[hiss];"
        "[thud][blade][hiss]amix=inputs=3:normalize=0,atrim=0:0.34" % (SR, SR, SR, SR, SR, pitch, SR, hp, env(0.12, 0.005, 0.1)), -19))

# Mummie: niente cigolii. Bende secche che sfregano e un rantolo raschiato prima dell'affondo.
V["mummy_windup"] = []
for k, f0 in enumerate([150, 132]):
    V["mummy_windup"].append(([R + "cloth%d.ogg" % (k + 1), noise("pink", 0.7), sine(f0, 0.7), sine(f0 * 2, 0.7), sine(f0 * 3, 0.7)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*0.8,aresample=%d,lowpass=f=4000,volume=1.3[cloth];"
        "[1:a]highpass=f=300,lowpass=f=1800,%s,volume=0.9[breath];"
        "[2:a][3:a][4:a]amix=inputs=3:normalize=0,tremolo=f=13:d=0.8,%s,volume=0.22[groan];"
        "[cloth][breath][groan]amix=inputs=3:normalize=0,atrim=0:0.75" % (SR, SR, SR, env(0.7, 0.25, 0.3), env(0.7, 0.2, 0.35)), -18))
V["mummy_step"] = []
for k in range(4):
    V["mummy_step"].append(([I + "footstep_carpet_00%d.ogg" % k, noise("pink", 0.18)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*0.75,aresample=%d,lowpass=f=2500[s];"
        "[1:a]highpass=f=300,lowpass=f=1500,%s,volume=0.5[drag];[s][drag]amix=inputs=2:normalize=0" % (SR, SR, SR, env(0.18, 0.03, 0.12)), -23))

# Scorpioni di Serket: zampette di chitina, la coda che si carica (raspa), il pungiglione
V["scorpion_step"] = []
for k in range(3):
    V["scorpion_step"].append(([U + "tick_00%d.ogg" % [1, 2, 4][k]],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*%.2f,aresample=%d,highpass=f=1500,aecho=0.6:0.5:18:0.4" % (SR, SR, 1.5 + 0.15 * k, SR), -28))
V["scorpion_windup"] = []
for k in range(2):
    V["scorpion_windup"].append(([U + "scratch_00%d.ogg" % (k + 1), U + "scratch_00%d.ogg" % (k + 2)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*1.6,aresample=%d[a];"
        "[1:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*1.9,aresample=%d,adelay=90[b];"
        "[a][b]amix=inputs=2:normalize=0,highpass=f=900,aecho=0.7:0.5:40|80:0.5|0.3" % (SR, SR, SR, SR, SR, SR), -22))
V["scorpion_sting"] = []
for k in range(2):
    V["scorpion_sting"].append(([R + "knifeSlice%s.ogg" % ("" if k == 0 else "2"), R + "chop.ogg"],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*1.3,aresample=%d[w];"
        "[1:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*1.4,aresample=%d,adelay=70,volume=0.8[c];"
        "[w][c]amix=inputs=2:normalize=0" % (SR, SR, SR, SR, SR, SR), -19))

# Cobra: il soffio (sibilo che cresce) e lo sputo di veleno
V["cobra_hiss"] = []
for k, (lo, dur) in enumerate([(2800, 0.7), (3400, 0.55)]):
    V["cobra_hiss"].append(([noise("pink", dur)],
        "[0:a]highpass=f=%d,lowpass=f=9000,%s,tremolo=f=28:d=0.25" % (lo, env(dur, 0.25, 0.3)), -24))
V["cobra_spit"] = []
for k in range(2):
    V["cobra_spit"].append(([noise("white", 0.16), U + "bong_001.ogg"],
        "[0:a]highpass=f=%d,%s,volume=0.8[p];"
        "[1:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*%.2f,aresample=%d,atrim=0:0.25,lowpass=f=1800,volume=0.5,adelay=30[w];"
        "[p][w]amix=inputs=2:normalize=0" % (1800 + 600 * k, env(0.16, 0.004, 0.12), SR, SR, 1.3 + 0.2 * k, SR), -21))

# Il Serpente della Porta: soffio enorme, affondo che fende l'aria, si inabissa (sabbia), riemerge
V["serpent_hiss"] = []
for k, lo in enumerate([1400, 1800]):
    V["serpent_hiss"].append(([noise("pink", 1.0), noise("brown", 1.0)],
        "[0:a]highpass=f=%d,lowpass=f=7000,%s,tremolo=f=22:d=0.3[h];"
        "[1:a]lowpass=f=260,%s,volume=0.7[r];[h][r]amix=inputs=2:normalize=0" % (lo, env(1.0, 0.35, 0.45), env(1.0, 0.3, 0.5)), -20))
V["serpent_strike"] = [([R + "cloth%d.ogg" % (k + 2), noise("pink", 0.3)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,atempo=1.7,lowpass=f=2500[w];"
        "[1:a]highpass=f=2200,%s,volume=0.5[h];[w][h]amix=inputs=2:normalize=0" % (SR, env(0.3, 0.02, 0.25)), -18) for k in range(2)]
V["serpent_burrow"] = [([noise("brown", 1.1), I + "footstep_snow_00%d.ogg" % k],
        "[0:a]lowpass=f=320,%s,volume=1.2[r];"
        "[1:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*0.6,aresample=%d,aecho=0.6:0.5:120|240:0.5|0.3[s];"
        "[r][s]amix=inputs=2:normalize=0" % (env(1.1, 0.2, 0.6), SR, SR, SR), -19) for k in range(2)]
V["serpent_erupt"] = [([I + "impactPlate_heavy_00%d.ogg" % (k + 1), noise("brown", 0.9)],
        "[0:a]aformat=sample_rates=%d:channel_layouts=mono,asetrate=%d*0.45,aresample=%d,lowpass=f=1500[i];"
        "[1:a]lowpass=f=380,%s[r];[i][r]amix=inputs=2:normalize=0" % (SR, SR, SR, env(0.9, 0.01, 0.7)), -16) for k in range(2)]

def stats(path):
    e = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True).stderr
    return float(re.search(r"mean_volume: (-?[\d.]+)", e).group(1)), float(re.search(r"max_volume: (-?[\d.]+)", e).group(1))

tmp = OUT + "/_tmp.wav"
for name, variants in V.items():
    for k, (inputs, flt, target) in enumerate(variants):
        args = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"]
        for src in inputs:
            if src.startswith("lavfi:"):
                args += ["-f", "lavfi", "-i", src[6:]]
            else:
                assert glob.glob(src), src
                args += ["-i", src]
        # via i bassi sotto i 150 Hz: il telefono non li riproduce e falserebbero il volume
        fc = flt + ",highpass=f=150[out]"
        args += ["-filter_complex", fc, "-map", "[out]", "-ac", "1", "-ar", str(SR), tmp]
        subprocess.run(args, check=True)
        mean, peak = stats(tmp)
        gain = min(target - mean, -1.0 - peak)
        out = OUT + "/" + name + ("" if k == 0 else "_%d" % (k + 1)) + ".ogg"
        subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", tmp, "-af",
                        "volume=%.1fdB,silenceremove=start_periods=1:start_threshold=-50dB" % gain,
                        "-c:a", "libvorbis", "-q:a", "5", out], check=True)
        print(name, k + 1, "mean %.1f peak %.1f gain %.1f" % (mean, peak, gain))
subprocess.run(["rm", "-f", tmp])
