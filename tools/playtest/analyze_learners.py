#!/usr/bin/env python3
"""Analisi del playtest lungo (learners.py). Uso: python3 analyze_learners.py CARTELLA [uscita.json]"""
import json, os, sys, glob, statistics as st, collections

D = sys.argv[1]
OUTJ = sys.argv[2] if len(sys.argv) > 2 else None
testers = {t["id"]: t for t in json.load(open(os.path.join(D, "testers.json")))}
runs = collections.defaultdict(list)
for f in glob.glob(os.path.join(D, "runs", "*.jsonl")):
    for line in open(f):
        r = json.loads(line)
        runs[r["tester"]].append(r)
for k in runs:
    runs[k].sort(key=lambda r: int(r.get("run_n", 0)))
quits = {}
for f in glob.glob(os.path.join(D, "quit", "*")):
    q = json.load(open(f))
    quits[q["tester"]] = q

def reached(r):
    return r["room"] + (1 if r["result"] == "win" else 0)

def passed_serpent(r):
    return r["room"] >= 6 or r["result"] == "win"

res = {"n_testers": len(runs), "n_runs": sum(len(v) for v in runs.values())}
arch = collections.defaultdict(list)
for tid, rs in runs.items():
    arch[testers[tid]["arch"]].append(tid)

# ---- per archetipo
table = {}
for a, tids in sorted(arch.items()):
    first_serp, first_win, quit_after, best = [], [], [], []
    for tid in tids:
        rs = runs[tid]
        fs = next((i + 1 for i, r in enumerate(rs) if passed_serpent(r)), None)
        fw = next((i + 1 for i, r in enumerate(rs) if r["result"] == "win"), None)
        first_serp.append(fs)
        first_win.append(fw)
        best.append(max(reached(r) for r in rs))
        if tid in quits:
            quit_after.append(quits[tid]["after_runs"])
    n = len(tids)
    def med(xs):
        xs = [x for x in xs if x is not None]
        return st.median(xs) if xs else None
    table[a] = {
        "tester": n,
        "battono_serpente_%": round(100 * sum(x is not None for x in first_serp) / n),
        "discese_per_serpente": med(first_serp),
        "battono_ammit_%": round(100 * sum(x is not None for x in first_win) / n),
        "discese_per_ammit": med(first_win),
        "abbandonano_%": round(100 * len(quit_after) / n),
        "abbandono_dopo": med(quit_after),
    }
res["archetipi"] = table

# ---- curva di apprendimento: stanza media raggiunta alla discesa i
curve = collections.defaultdict(list)
win_curve = collections.defaultdict(list)
for tid, rs in runs.items():
    for i, r in enumerate(rs):
        if r["result"] == "crash":
            continue
        curve[i].append(reached(r))
        win_curve[i].append(1 if r["result"] == "win" else 0)
res["curva"] = [{"discesa": i + 1, "stanza_media": round(st.mean(curve[i]), 2), "vittorie_%": round(100 * st.mean(win_curve[i]), 1), "tester_ancora": len(curve[i])} for i in sorted(curve)]

# ---- morti: chi e dove
killers = collections.Counter()
death_room = collections.Counter()
results = collections.Counter()
times = []
for rs in runs.values():
    for r in rs:
        results[r["result"]] += 1
        if r["result"] == "death":
            killers[r.get("killer") or "?"] += 1
            death_room[r["room"]] += 1
        if r.get("time"):
            times.append(r["time"])
res["esiti"] = dict(results)
res["uccisori"] = killers.most_common()
res["morti_per_stanza"] = sorted(death_room.items())
res["durata_media_discesa_s"] = round(st.mean(times), 1) if times else None
wins_t = [r["time"] for rs in runs.values() for r in rs if r["result"] == "win"]
res["durata_media_vittoria_s"] = round(st.mean(wins_t), 1) if wins_t else None

# ---- doni: quanto vengono presi e quanto "vincono"
taken = collections.Counter()
in_win = collections.Counter()
reach_with = collections.defaultdict(list)
for rs in runs.values():
    for r in rs:
        for b in r.get("boons", {}):
            taken[b] += 1
            reach_with[b].append(reached(r))
            if r["result"] == "win":
                in_win[b] += 1
all_reach = [reached(r) for rs in runs.values() for r in rs if r["result"] != "crash"]
avg_reach = st.mean(all_reach) if all_reach else 0
boons = []
for b, n in taken.items():
    boons.append({"dono": b, "preso": n, "vittorie_%": round(100 * in_win[b] / n, 1), "stanza_media": round(st.mean(reach_with[b]), 2)})
boons.sort(key=lambda x: -x["stanza_media"])
res["doni"] = boons
res["stanza_media_generale"] = round(avg_reach, 2)

# ---- Set, Traghettatore, economia
pacts = [len(r.get("blessings", [])) for rs in runs.values() for r in rs if r["result"] != "crash"]
res["patti_set_per_discesa"] = round(st.mean(pacts), 2) if pacts else 0
with_p = [reached(r) for rs in runs.values() for r in rs if r.get("blessings")]
without_p = [reached(r) for rs in runs.values() for r in rs if r["result"] != "crash" and not r.get("blessings")]
res["stanza_con_patti"] = round(st.mean(with_p), 2) if with_p else None
res["stanza_senza_patti"] = round(st.mean(without_p), 2) if without_p else None
shop = collections.Counter(k for rs in runs.values() for r in rs for k in r.get("shop", []))
res["acquisti_traghettatore"] = dict(shop)
# Ka custodito e Libro nel tempo
ka_curve = collections.defaultdict(list)
book_curve = collections.defaultdict(list)
for rs in runs.values():
    for i, r in enumerate(rs):
        m = r.get("meta")
        if not m:
            continue
        ka_curve[i].append(m["ka_bank"])
        book_curve[i].append(sum(m["chapters"].values()) if m["chapters"] else 0)
res["libro"] = [{"discesa": i + 1, "ka_custodito_medio": round(st.mean(ka_curve[i])), "livelli_capitoli_medi": round(st.mean(book_curve[i]), 1)} for i in sorted(ka_curve)]
ka_run = [r["ka"] for rs in runs.values() for r in rs if r.get("ka") is not None and r["result"] != "crash"]
res["ka_raccolto_medio_per_discesa"] = round(st.mean(ka_run), 1) if ka_run else None
# danni subiti per fonte
dmg = collections.Counter()
for rs in runs.values():
    for r in rs:
        for k, v in r.get("dmg_taken", {}).items():
            dmg[k.split("_")[0]] += v
res["danni_subiti_per_fonte"] = [(k, round(v)) for k, v in dmg.most_common()]
# tempo per stanza
room_t = collections.defaultdict(list)
for rs in runs.values():
    for r in rs:
        for x in r.get("rooms", []):
            room_t[x["room"]].append(x["time"])
res["secondi_per_stanza"] = [(k, round(st.mean(v), 1)) for k, v in sorted(room_t.items())]

if OUTJ:
    json.dump(res, open(OUTJ, "w"), indent=1, ensure_ascii=False)
for k in ["n_testers", "n_runs", "esiti", "durata_media_discesa_s", "stanza_media_generale", "patti_set_per_discesa", "stanza_con_patti", "stanza_senza_patti", "ka_raccolto_medio_per_discesa"]:
    print(k, res[k])
print("\nARCHETIPI")
for a, v in res["archetipi"].items():
    print(a, v)
print("\nCURVA", [(c["discesa"], c["stanza_media"], c["vittorie_%"], c["tester_ancora"]) for c in res["curva"]])
print("\nUCCISORI", res["uccisori"][:10])
print("MORTI PER STANZA", res["morti_per_stanza"])
print("\nDONI migliori", [(b["dono"], b["preso"], b["stanza_media"]) for b in res["doni"][:8]])
print("DONI peggiori", [(b["dono"], b["preso"], b["stanza_media"]) for b in res["doni"][-8:]])
print("\nLIBRO", [(x["discesa"], x["ka_custodito_medio"], x["livelli_capitoli_medi"]) for x in res["libro"][::3]])
print("TRAGHETTATORE", res["acquisti_traghettatore"])
print("DANNI", res["danni_subiti_per_fonte"][:10])
print("SECONDI PER STANZA", res["secondi_per_stanza"])
