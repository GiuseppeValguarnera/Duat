# Converte i suoni CC0 di Kenney nei file di assets/sfx: sceglie i file, applica filtri
# (per esempio rallentare un colpo di metallo per farne il ruggito di Ammit) e li normalizza
# allo stesso volume percepito. Uso: python3 tools/convert_sfx.py <cartella con i pacchetti> assets/sfx
import subprocess, re, os, glob, sys
SRC = sys.argv[1]; OUT = sys.argv[2]
I, U, R = SRC + "/Audio impact/", SRC + "/Audio interfaccia/", SRC + "/Audio rpg/"
def g(pat): return sorted(glob.glob(pat))
# nome -> (file sorgenti, filtro ffmpeg extra, rms obiettivo dB)
MAP = {
  "swing":  (g(R+"knifeSlice*.ogg"), "", -20),
  "hit":    (g(I+"impactPunch_medium_*.ogg"), "", -18),
  "crit":   (g(I+"impactPunch_heavy_*.ogg"), "", -16),
  "eye":    (g(U+"glass_00*.ogg")[:4], "", -20),
  "divine": (g(I+"impactBell_heavy_00[0-1].ogg"), "", -17),
  "dash":   (g(R+"cloth[1-4].ogg"), "atempo=1.3", -21),
  "hurt":   (g(I+"impactSoft_heavy_*.ogg"), "", -16),
  "death":  (g(I+"impactBell_heavy_002.ogg"), "asetrate=44100*0.6,aresample=44100", -16),
  "kill":   (g(I+"impactMining_*.ogg"), "", -19),
  "bite":   (g(R+"chop.ogg"), "asetrate=44100*0.8,aresample=44100", -16),
  "roar":   (g(I+"impactMetal_heavy_00[0-1].ogg"), "asetrate=44100*0.4,aresample=44100,aecho=0.8:0.7:60|120:0.5|0.3,lowpass=f=1800", -15),
  "charge": (g(I+"impactWood_heavy_*.ogg")[:3], "asetrate=44100*0.7,aresample=44100", -17),
  "spikes": (g(I+"impactMetal_light_*.ogg"), "", -21),
  "dart":   (g(R+"drawKnife*.ogg"), "atempo=1.4", -21),
  "pickup": (g(R+"handleCoins*.ogg"), "", -19),
  "boon":   (g(U+"confirmation_*.ogg"), "", -18),
  "door":   (g(R+"doorOpen_*.ogg"), "", -19),
  "ui":     (g(U+"tick_*.ogg"), "", -22),
  "scarab_step":  (g(U+"scratch_00[1-3].ogg"), "asetrate=44100*1.3,aresample=44100", -24),
  "mummy_step":   (g(I+"footstep_carpet_00[0-4].ogg"), "asetrate=44100*0.7,aresample=44100", -24),
  "mummy_windup": (g(R+"creak[13].ogg"), "asetrate=44100*0.85,aresample=44100", -20),
  "mummy_lunge":  (g(R+"clothBelt*.ogg"), "atempo=1.6", -19),
  "priest_cast":  (g(U+"maximize_00[1-3].ogg"), "asetrate=44100*0.6,aresample=44100,aecho=0.8:0.6:80|160:0.4|0.25", -20),
  "orb":          (g(U+"bong_001.ogg"), "asetrate=44100*0.5,aresample=44100,aecho=0.8:0.7:60|120:0.5|0.3", -19),
  "orb_pop":      (g(U+"minimize_00[1-2].ogg"), "asetrate=44100*0.8,aresample=44100", -24),
  "book":   (g(R+"bookOpen.ogg"), "", -19),
  "page":   (g(R+"bookFlip*.ogg"), "", -19),
}
def stats(path, flt):
    a = ["ffmpeg","-hide_banner","-i",path,"-af",(flt+"," if flt else "")+"volumedetect","-f","null","-"]
    e = subprocess.run(a, capture_output=True, text=True).stderr
    return float(re.search(r"mean_volume: (-?[\d.]+)", e).group(1)), float(re.search(r"max_volume: (-?[\d.]+)", e).group(1))
for name, (files, flt, target) in MAP.items():
    assert files, name
    for k, f in enumerate(files):
        mean, peak = stats(f, flt)
        gain = min(target - mean, -1.0 - peak)
        out = OUT + "/" + name + ("" if k == 0 else "_%d" % (k + 1)) + ".ogg"
        af = (flt + "," if flt else "") + "volume=%.1fdB,silenceremove=start_periods=1:start_threshold=-50dB" % gain
        subprocess.run(["ffmpeg","-y","-hide_banner","-loglevel","error","-i",f,"-af",af,"-ac","1","-c:a","libvorbis","-q:a","5",out], check=True)
        print(name, os.path.basename(f), "mean %.1f peak %.1f gain %.1f" % (mean, peak, gain))
