#!/usr/bin/env python3
"""Average of the frame log lines of tools/bench.sh runs, without the first three (loading).
usage: tools/benchsum.py build/bench/<name>.log ..."""
import re, sys
for path in sys.argv[1:]:
    rows = [l for l in open(path, errors="replace") if "frames in" in l][3:]
    if not rows:
        print(path, "no data"); continue
    fps = sum(float(re.search(r"\(([\d.]+) per second", l).group(1)) for l in rows) / len(rows)
    ms = {}
    for l in rows:
        for k, v in re.findall(r"(\w+) ([\d.]+)", l.split("ms:")[1]):
            ms[k] = ms.get(k, 0) + float(v) / len(rows)
    work = sum(v for k, v in ms.items() if k != "wait")
    print("%-24s %5.1f fps  work %5.2f ms: %s" % (path.split("/")[-1][:-4], fps, work, " ".join("%s %.2f" % kv for kv in ms.items() if kv[0] != "wait")))
