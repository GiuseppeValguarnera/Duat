#!/usr/bin/env python3
"""Playtest automatico di Duat.

Fa giocare un bot (bot.gd) con diversi "stili" di giocatore, senza invulnerabilità,
e stampa le statistiche: vittorie, stanze raggiunte, danni subiti per fonte, tempi.

Uso:
    python3 tools/playtest/run_playtest.py --godot /percorso/Godot_v4.7.2 \
        --personas veterano,casual --seeds 16 --jobs 4

Esperimenti A/B (stesso bot, stesse partite, cambia una sola scelta):
    --env DUAT_SET=always        prende sempre i patti di Set (oppure never)
    --env DUAT_HEAVY=always      prende sempre i doni pesanti (oppure never)
    --env "DUAT_ANUBI=Cuore di Pietra"   forza un dono di Anubi (oppure nessuno)
    --env DUAT_GOD=ra            preferisce le porte di un dio
    --save salvataggio.cfg       parte da un salvataggio (capitoli, Sekhem, Peso del Cuore)

Stili disponibili: novizio, casual, veterano, speedrunner, minmaxer, prudente, cecchino.
Il bot gioca peggio di una persona: usalo per i confronti, non per la difficoltà assoluta.
"""
import argparse, collections, concurrent.futures, json, os, shutil, statistics, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))


def prepare(godot: str) -> str:
    work = tempfile.mkdtemp(prefix="duat_playtest_")
    shutil.copytree(PROJECT, work, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", ".godot", "tools", "override.cfg"))
    shutil.copy(os.path.join(HERE, "bot.gd"), os.path.join(work, "bot.gd"))
    cfg = open(os.path.join(work, "project.godot"), encoding="utf-8").read()
    cfg = cfg.replace('Run="*res://scripts/run.gd"', 'Run="*res://scripts/run.gd"\nAutoTest="*res://bot.gd"')
    open(os.path.join(work, "project.godot"), "w", encoding="utf-8").write(cfg)
    subprocess.run([godot, "--headless", "--path", work, "--import"], capture_output=True, timeout=300)
    return work


def play(godot, work, persona, seed, out, env_extra, save):
    home = tempfile.mkdtemp(prefix="duat_home_")
    data = os.path.join(home, ".local", "share", "godot", "app_userdata", "Duat")
    os.makedirs(data)
    if save:
        shutil.copy(save, os.path.join(data, "duat_save.cfg"))
    env = dict(os.environ, HOME=home, APPDATA=home, DUAT_PERSONA=persona, DUAT_SEED=str(seed), DUAT_OUT=out)
    env.update(env_extra)
    subprocess.run([godot, "--headless", "--fixed-fps", "60", "--path", work, "res://scenes/game.tscn"],
                   env=env, capture_output=True, timeout=900)
    shutil.rmtree(home, ignore_errors=True)


def report(out):
    rows = [json.loads(l) for l in open(out, encoding="utf-8")]
    by = collections.defaultdict(list)
    for r in rows:
        by[r["persona"]].append(r)
    for persona, runs in by.items():
        wins = sum(r["result"] == "win" for r in runs)
        boss = sum(r["room"] == 11 for r in runs)
        dmg = collections.Counter()
        for r in runs:
            for k, v in r["dmg_taken"].items():
                dmg[k.split("_")[0]] += v / len(runs)
        print(f"\n{persona}: {len(runs)} partite")
        print(f"  vittorie {wins}   arrivi da Ammit {boss}   stanza media {statistics.mean(r['room'] for r in runs):.1f}")
        print(f"  durata media {statistics.mean(r['time'] for r in runs):.0f}s   doni medi {statistics.mean(sum(r['boons'].values()) for r in runs):.1f}")
        print("  danni subiti per partita: " + ", ".join(f"{k} {v:.0f}" for k, v in dmg.most_common()))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", required=True)
    ap.add_argument("--personas", default="novizio,casual,veterano,speedrunner,minmaxer,prudente,cecchino")
    ap.add_argument("--seeds", type=int, default=8)
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    ap.add_argument("--env", action="append", default=[])
    ap.add_argument("--save")
    ap.add_argument("--out", default="playtest.jsonl")
    a = ap.parse_args()
    env_extra = dict(e.split("=", 1) for e in a.env)
    out = os.path.abspath(a.out)
    if os.path.exists(out):
        os.remove(out)
    print("Preparo una copia del progetto con il bot...")
    work = prepare(a.godot)
    jobs = [(p, s) for p in a.personas.split(",") for s in range(1, a.seeds + 1)]
    print(f"Gioco {len(jobs)} partite...")
    with concurrent.futures.ThreadPoolExecutor(a.jobs) as ex:
        list(ex.map(lambda j: play(a.godot, work, j[0], j[1], out, env_extra, a.save), jobs))
    shutil.rmtree(work, ignore_errors=True)
    report(out)


if __name__ == "__main__":
    sys.exit(main())
