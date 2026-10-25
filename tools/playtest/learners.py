#!/usr/bin/env python3
"""Playtest lungo con tester che imparano.

Ogni tester ha un profilo realistico (stile, riflessi, mira, pazienza, velocità di apprendimento),
un suo salvataggio del gioco (Ka, Libro dei Morti, Lacrime, vittorie) e una "memoria" (bot.gd,
DUAT_BRAIN) che cresce discesa dopo discesa. Gioca fino a RUNS discese, oppure smette prima se
si frustra (troppe discese di fila senza migliorare): anche questo è un dato.

Uso: python3 tools/playtest/learners.py GODOT CARTELLA_LAVORO [tester] [discese] [processi]
"""
import json, os, random, shutil, subprocess, sys
from multiprocessing import Pool

GODOT = sys.argv[1]
OUT = os.path.abspath(sys.argv[2])
N_TESTERS = int(sys.argv[3]) if len(sys.argv) > 3 else 100
RUNS = int(sys.argv[4]) if len(sys.argv) > 4 else 30
PROCS = int(sys.argv[5]) if len(sys.argv) > 5 else 2
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Archetipi: (peso nel campione, stile di base del bot, ritocchi)
ARCH = {
    "mai_giocato":     (8,  "novizio",  {"reaction": 0.42, "dodge": 0.08, "aim_err": 28, "eye": 0.15, "learn": 0.7, "patience": 4, "skill": 0.0, "dodge_cap": 0.6, "skill_cap": 0.5, "reaction_floor": 0.16}),
    "casual_telefono": (18, "casual",   {"reaction": 0.28, "dodge": 0.3, "aim_err": 16, "eye": 0.35, "learn": 0.9, "patience": 5, "dodge_cap": 0.75, "skill_cap": 0.7, "reaction_floor": 0.12}),
    "casual_pc":       (14, "casual",   {"reaction": 0.22, "dodge": 0.4, "aim_err": 12, "learn": 1.0, "patience": 6, "dodge_cap": 0.8, "skill_cap": 0.8, "reaction_floor": 0.1}),
    "medio":           (18, "casual",   {"reaction": 0.17, "dodge": 0.5, "aim_err": 9, "eye": 0.6, "learn": 1.1, "patience": 7, "skill": 0.5, "dodge_cap": 0.85, "reaction_floor": 0.09}),
    "fan_hades":       (14, "veterano", {"learn": 1.3, "patience": 10, "challenge": 1.0, "dodge_cap": 0.92}),
    "speedrunner":     (5,  "speedrunner", {"learn": 1.4, "patience": 12, "challenge": 1.5}),
    "minmaxer":        (6,  "minmaxer", {"learn": 1.3, "patience": 12, "challenge": 1.2}),
    "prudente":        (7,  "prudente", {"learn": 1.0, "patience": 8, "challenge": 0.3}),
    "cecchino":        (5,  "cecchino", {"learn": 1.1, "patience": 8}),
    "frettoloso":      (5,  "casual",   {"reaction": 0.2, "dodge": 0.25, "heal": 0.1, "set": 0.8, "heavy": 1.0, "learn": 0.8, "patience": 3, "panic": 0.2}),
}
CHAPTER_PREF = {
    "novizio": ["c17", "c30", "c154", "c151", "c6", "c99", "c125", "c89", "c56", "c110", "c42", "c94", "c72"],
    "casual": ["c17", "c30", "c6", "c151", "c125", "c99", "c89", "c56", "c154", "c110", "c42", "c94", "c72"],
    "veterano": ["c125", "c17", "c89", "c42", "c56", "c30", "c6", "c99", "c151", "c110", "c94", "c72", "c154"],
    "speedrunner": ["c125", "c56", "c89", "c42", "c17", "c99", "c6", "c30", "c72", "c110", "c94", "c151", "c154"],
    "minmaxer": ["c99", "c125", "c110", "c94", "c42", "c89", "c17", "c56", "c6", "c30", "c72", "c151", "c154"],
    "prudente": ["c17", "c30", "c151", "c154", "c6", "c89", "c125", "c99", "c56", "c110", "c42", "c94", "c72"],
    "cecchino": ["c89", "c42", "c17", "c125", "c30", "c56", "c6", "c99", "c151", "c110", "c94", "c72", "c154"],
}


def make_testers(n):
    rng = random.Random(2026)
    names = list(ARCH)
    weights = [ARCH[k][0] for k in names]
    testers = []
    for i in range(n):
        arch = rng.choices(names, weights)[0]
        _, base, extra = ARCH[arch]
        cfg = dict(extra)
        # ognuno è un po' diverso dagli altri del suo tipo
        for k in ("reaction", "dodge", "aim_err", "eye", "learn"):
            if k in cfg:
                cfg[k] = round(cfg[k] * rng.uniform(0.85, 1.15), 3)
        cfg["patience"] = max(2, int(cfg.get("patience", 6) + rng.randint(-2, 2)))
        cfg["chapters"] = CHAPTER_PREF.get(base, CHAPTER_PREF["casual"])
        testers.append({"id": "t%03d" % i, "arch": arch, "persona": base, "cfg": cfg})
    return testers


def play(t):
    tid = t["id"]
    home = os.path.join(OUT, "homes", tid)
    brain = os.path.join(OUT, "brains", tid + ".json")
    out = os.path.join(OUT, "runs", tid + ".jsonl")
    ud = os.path.join(home, ".local/share/godot/app_userdata/Duat")
    os.makedirs(ud, exist_ok=True)
    os.makedirs(os.path.dirname(brain), exist_ok=True)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    done = 0
    if os.path.exists(out):
        done = sum(1 for _ in open(out))       # si può riprendere da dove si era fermato
    best = -1
    stale = 0
    for line in (open(out) if os.path.exists(out) else []):
        r = json.loads(line)
        reached = r["room"] + (1 if r["result"] == "win" else 0)
        if reached > best:
            best, stale = reached, 0
        else:
            stale += 1
    quit_file = os.path.join(OUT, "quit", tid)
    if os.path.exists(quit_file):
        return tid
    for run in range(done, RUNS):
        try:
            os.remove(os.path.join(ud, "duat_discesa.cfg"))   # niente discese a metà tra una prova e l'altra
        except FileNotFoundError:
            pass
        env = dict(os.environ, HOME=home, DUAT_PERSONA=t["persona"], DUAT_CFG=json.dumps(t["cfg"]),
                   DUAT_BRAIN=brain, DUAT_SEED=str(int(tid[1:]) * 1000 + run), DUAT_TESTER=tid,
                   DUAT_RUN=str(run), DUAT_OUT=out, DUAT_EXP=t["arch"])
        before = sum(1 for _ in open(out)) if os.path.exists(out) else 0
        try:
            subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", os.path.join(OUT, "game"), "res://scenes/game.tscn"],
                           env=env, stdout=subprocess.DEVNULL, stderr=open(os.path.join(OUT, "logs", tid + ".err"), "a"), timeout=240)
        except subprocess.TimeoutExpired:
            pass
        after = sum(1 for _ in open(out)) if os.path.exists(out) else 0
        if after == before:
            with open(out, "a") as f:            # il gioco si è bloccato o chiuso male: lo segniamo
                f.write(json.dumps({"tester": tid, "run_n": str(run), "exp": t["arch"], "persona": t["persona"], "result": "crash", "room": 0}) + "\n")
            continue
        r = json.loads(open(out).read().strip().split("\n")[-1])
        reached = r["room"] + (1 if r["result"] == "win" else 0)
        if reached > best:
            best, stale = reached, 0
        else:
            stale += 1
        # frustrazione: troppe discese senza fare meglio, e non ha ancora mai battuto Ammit
        if stale >= t["cfg"]["patience"] and r.get("meta", {}).get("wins", 0) == 0:
            os.makedirs(os.path.join(OUT, "quit"), exist_ok=True)
            with open(quit_file, "w") as f:
                f.write(json.dumps({"tester": tid, "after_runs": run + 1, "best_room": best}))
            break
    return tid


if __name__ == "__main__":
    os.makedirs(os.path.join(OUT, "logs"), exist_ok=True)
    game = os.path.join(OUT, "game")
    if not os.path.exists(game):
        shutil.copytree(ROOT, game, ignore=shutil.ignore_patterns(".git", "build", "i18n", "override.cfg"))
        shutil.copy(os.path.join(ROOT, "tools/playtest/bot.gd"), os.path.join(game, "bot.gd"))
        shutil.rmtree(os.path.join(game, "tools"))
        pg = os.path.join(game, "project.godot")
        txt = open(pg).read().replace('Touch="*res://scripts/touch_controls.gd"', 'Touch="*res://scripts/touch_controls.gd"\nAutoTest="*res://bot.gd"')
        open(pg, "w").write(txt)
        subprocess.run([GODOT, "--headless", "--path", game, "--import"], env=dict(os.environ, HOME=os.path.join(OUT, "homes", "_import")),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=300)
    testers = make_testers(N_TESTERS)
    json.dump(testers, open(os.path.join(OUT, "testers.json"), "w"), indent=1)
    with Pool(PROCS) as pool:
        for tid in pool.imap_unordered(play, testers):
            print("finito", tid, flush=True)
    print("TUTTO FINITO", flush=True)
