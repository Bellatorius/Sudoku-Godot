"""Unattended pack pipeline, run by .github/workflows/pipeline.yml every 20 minutes.

State lives in pipeline/state.json. Each stage waits for its GitHub runs; when they are all complete it
merges their artifacts into the packs, commits, starts the next runs and moves on:

  levels -> top -> final -> done

  levels: beginner-hard of the picture + Mini variants, old expert/master runs, the Ten Lines / Double
          Arrow picture table.  Then: grades, expert + master for those variants, beginner-hard for Ten Lines
          and Double Arrow.
  top:    those runs.  Then: grades for Ten Lines / Double Arrow, their expert + master, the daily calendar.
  final:  those runs.  Then: daily.json, examples.json, a report; the pipeline switches itself off.

Run locally with GH_TOKEN set and GODOT pointing at a Godot binary:  python tools/pipeline.py
"""
import glob, json, os, shutil, subprocess, sys, time, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, "pipeline", "state.json")
PARTS = os.path.join(ROOT, "puzzles", "_parts")
DL = os.path.join(ROOT, "_dl")
GODOT = os.environ.get("GODOT", os.path.join(ROOT, "godot"))
REPO = os.environ.get("GITHUB_REPOSITORY", "Bellatorius/Sudoku-Godot")
LEVELS4 = ["hard", "medium", "easy", "beginner"]


def sh(*cmd, check=True, capture=False):
    print("+", " ".join(cmd), flush=True)
    r = subprocess.run(cmd, cwd=ROOT, check=check, text=True, capture_output=capture)
    return r.stdout if capture else r.returncode


def gh_json(*args):
    return json.loads(sh("gh", *args, capture=True))


def load():
    with open(STATE, encoding="utf-8") as f:
        return json.load(f)


def save(st):
    with open(STATE, "w", encoding="utf-8") as f:
        json.dump(st, f, indent=1)


def log(st, msg):
    stamp = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M")
    st.setdefault("log", []).append("%s  %s" % (stamp, msg))
    print(msg, flush=True)


def all_done(ids):
    for i in ids:
        r = gh_json("run", "view", str(i), "--repo", REPO, "--json", "status,conclusion")
        if r["status"] != "completed":
            print("waiting for run", i, r["status"], flush=True)
            return False
    return True


def download(run_id, skip_prefixes=()):
    """All artifacts of a run into puzzles/_parts/ (flattened), except files starting with skip_prefixes."""
    dest = os.path.join(DL, str(run_id))
    shutil.rmtree(dest, ignore_errors=True)
    sh("gh", "run", "download", str(run_id), "--repo", REPO, "-D", dest, check=False)
    os.makedirs(PARTS, exist_ok=True)
    n = 0
    for f in glob.glob(os.path.join(dest, "**", "*.json"), recursive=True):
        name = os.path.basename(f)
        if any(name.startswith(p) for p in skip_prefixes):
            continue
        shutil.copy(f, os.path.join(PARTS, name))
        n += 1
    print("run", run_id, ":", n, "files", flush=True)
    return n


def godot(*args):
    if not os.path.exists(GODOT):
        sh("bash", "-c", "curl -sL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/"
           "Godot_v4.7.2-stable_linux.x86_64.zip && unzip -q -o godot.zip && mv Godot_v4.7.2-stable_linux.x86_64 godot "
           "&& chmod +x godot && rm godot.zip")
        sh("bash", "-c", "timeout 300 ./godot --headless --path . --import || true")
    sh(GODOT, "--headless", "--path", ".", *args)


def drop_packs(variants):
    """Remove the old packs of variants that are rebuilt from scratch (merge then starts empty)."""
    for v in variants:
        p = os.path.join(ROOT, "puzzles", v + ".json")
        if os.path.exists(p):
            os.remove(p)


def merge_picture_table(types):
    table_path = os.path.join(ROOT, "puzzles", "pictures.json")
    with open(table_path, encoding="utf-8") as f:
        table = json.load(f)
    for t in types:
        names = []
        for fn in glob.glob(os.path.join(PARTS, "pictures_%s_s*.json" % t)):
            with open(fn, encoding="utf-8") as f:
                d = json.load(f)
            for n, lst in d.items():
                table.setdefault(n, {}).setdefault(t, [])
                for name in lst:
                    if name not in table[n][t]:
                        table[n][t].append(name)
            os.remove(fn)
    with open(table_path, "w", encoding="utf-8") as f:
        json.dump(table, f, indent=1)


def dispatch_packs(level, variants, tag, shards=5):
    """500 puzzles per variant, split into `shards` jobs (more shards for slow variants: jobs stop at 6 h)."""
    sh("gh", "workflow", "run", "build_packs.yml", "--repo", REPO, "-f", "level=" + level,
       "-f", "per_shard=%d" % (500 // shards), "-f", "shards=" + json.dumps(list(range(shards))),
       "-f", "variants=" + json.dumps(variants, separators=(",", ":")), "-f", "tag=" + tag)
    return find_run("build_packs.yml", "packs %s %s" % (level, tag))


def find_run(workflow, title):
    for _ in range(30):
        time.sleep(10)
        runs = gh_json("run", "list", "--repo", REPO, "--workflow", workflow, "--limit", "30",
                       "--json", "databaseId,displayTitle,createdAt")
        for r in runs:   # newest first
            if r["displayTitle"].strip() == title.strip():
                return r["databaseId"]
    raise RuntimeError("dispatched run not found: " + title)


def commit(msg):
    sh("git", "config", "user.name", "Bellatorius")
    sh("git", "config", "user.email", "145453306+Bellatorius@users.noreply.github.com")
    sh("git", "add", "-A", "puzzles", "pipeline")
    if sh("git", "diff", "--cached", "--quiet", check=False) == 0:
        return
    sh("git", "commit", "-q", "-m", msg)
    for _ in range(5):
        if sh("git", "push", "-q", "origin", "HEAD:main", check=False) == 0:
            return
        sh("git", "pull", "--rebase", "-q", "origin", "main", check=False)
    raise RuntimeError("push failed")


def counts_report(variants):
    lines = []
    for v in variants:
        p = os.path.join(ROOT, "puzzles", v + ".json")
        if not os.path.exists(p):
            lines.append("%s: MISSING" % v)
            continue
        with open(p, encoding="utf-8") as f:
            d = json.load(f)
        c = {}
        for q in d["puzzles"]:
            c[q["difficulty"]] = c.get(q["difficulty"], 0) + 1
        lines.append("%s: %s" % (v, " ".join("%s %d" % (k, c.get(k, 0)) for k in
                                              ["beginner", "easy", "medium", "hard", "expert", "master"])))
    return lines


def main():
    """Keeps checking every 5 minutes (GitHub's 20-minute schedule is unreliable when busy). Before the 6-hour
    job limit it starts a fresh Pipeline run of itself, so the chain never depends on the schedule."""
    start = time.time()
    while True:
        step()
        if load()["stage"] == "done":
            return
        if time.time() - start > 320 * 60:
            sh("gh", "workflow", "run", "pipeline.yml", "--repo", REPO, check=False)
            print("handing over to a new Pipeline run", flush=True)
            return
        time.sleep(300)


def step():
    st = load()
    stage = st["stage"]
    print("stage:", stage, flush=True)
    pic = st["pic_variants"]
    tn = st["tn_variants"]

    if stage == "levels":
        if not all_done(st["level_runs"] + st["old_runs"] + st["table_runs"]):
            return
        for r in st["old_runs"]:   # old expert/master: keep all but the variants that are rebuilt as pictures
            download(r, tuple(v + "_" for v in st["old_skip"]))
        for r in st["level_runs"]:
            download(r)
        drop_packs(pic)
        godot("-s", "tools/build_packs.gd", "--", "merge")
        for r in st["table_runs"]:
            download(r)
        merge_picture_table(["tn", "da"])
        godot("-s", "tools/build_grades.gd", "--", *pic)
        log(st, "levels merged (picture + Mini beginner-hard, old expert/master), grades for %d variants" % len(pic))
        st["top_runs"] = [dispatch_packs("expert", pic, "pic"), dispatch_packs("master", pic, "pic")]
        st["top_runs"] += [dispatch_packs(lv, tn, "tn") for lv in LEVELS4]
        st["stage"] = "top"
        log(st, "started expert/master for picture + Mini, beginner-hard for Ten Lines / Double Arrow: %s" % st["top_runs"])
        save(st)
        commit("Packs: picture and Mini puzzles (beginner to hard), grades; pipeline step 1")
        return

    if stage == "top":
        if not all_done(st["top_runs"]):
            return
        drop_packs(tn)
        for r in st["top_runs"]:
            download(r)
        godot("-s", "tools/build_packs.gd", "--", "merge")
        godot("-s", "tools/build_grades.gd", "--", *tn)
        log(st, "expert/master for picture + Mini merged, Ten Lines / Double Arrow beginner-hard merged")
        # Ten Lines puzzles take ~1 min each and expert / master try several per puzzle: 20 jobs of 25
        st["final_runs"] = [dispatch_packs("expert", tn, "tn", 20), dispatch_packs("master", tn, "tn", 20)]
        sh("gh", "workflow", "run", "build_daily.yml", "--repo", REPO)
        st["final_runs"].append(find_run("build_daily.yml", "daily calendar"))
        st["stage"] = "final"
        log(st, "started expert/master for Ten Lines / Double Arrow and the daily calendar: %s" % st["final_runs"])
        save(st)
        commit("Packs: picture and Mini expert/master; pipeline step 2")
        return

    if stage == "final":
        if not all_done(st["final_runs"]):
            return
        for r in st["final_runs"]:
            download(r)
        godot("-s", "tools/build_packs.gd", "--", "merge")
        daily = os.path.join(ROOT, "puzzles", "daily.json")
        if glob.glob(os.path.join(PARTS, "daily_*.json")) and os.path.exists(daily):
            os.remove(daily)   # every day is rebuilt (pictures for the line variants)
        godot("-s", "tools/build_daily.gd", "--", "merge")
        godot("-s", "tools/build_examples.gd")
        report = counts_report(pic + tn)
        with open(os.path.join(ROOT, "pipeline", "report.txt"), "w", encoding="utf-8") as f:
            f.write("\n".join(report) + "\n")
        st["stage"] = "done"
        log(st, "all done: packs, daily calendar and examples merged; see pipeline/report.txt")
        save(st)
        commit("Packs: Ten Lines and Double Arrow expert/master, daily calendar, examples; pipeline done")
        sh("gh", "workflow", "disable", "pipeline.yml", "--repo", REPO, check=False)
        return

    print("pipeline finished; nothing to do", flush=True)


if __name__ == "__main__":
    main()
