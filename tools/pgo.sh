#!/bin/sh
# Profile guided optimisation: build the game with counters, run the
# benchmark's scenes with it on a MiSTer (tools/bench.sh), fetch the counts
# into build/pgo and build the game again with them (build.sh, PGO=use).
# Run it again when the game has changed much: a function whose code is no
# longer what was counted is optimised as without a profile.
# usage: MISTER=root@<address> tools/pgo.sh
set -e
cd "$(dirname "$0")/.."
HOST=${MISTER:?set MISTER=root@<address of the MiSTer>}
PGO=generate ./build.sh mister > build/pgo-generate.log 2>&1 || { tail -30 build/pgo-generate.log; exit 1; }
mkdir -p build/bench
cp build/mister/yquake2 build/bench/pgo-generate.bin
ssh "$HOST" 'rm -rf /tmp/yquake2-pgo' 2>/dev/null
# the counts are written when the game quits (bench.sh ends it with SIGTERM,
# on which Quake II quits); the scenes add up. The game library is counted
# too: it is copied over the one on the MiSTer for the time of the runs.
G=/media/fat/games/YQuake2
ssh "$HOST" "cp $G/baseq2/game.so /tmp/yquake2-game.so" 2>/dev/null
scp -q build/mister/baseq2/game.so "$HOST:$G/baseq2/game.so" 2>/dev/null
export BENCH_BIN=build/bench/pgo-generate.bin BENCH_NOPROFILE=1
tools/bench.sh pgo-replay 60 +map q2demo1.dm2 > /dev/null 2>&1
BENCH_ENV=MISTER_HYBRID_HEIGHT=240 tools/bench.sh pgo-replay240 60 +map q2demo1.dm2 > /dev/null 2>&1
tools/bench.sh pgo-demo1 40 +map demo1 > /dev/null 2>&1
tools/bench.sh pgo-demo3 40 +map demo3 > /dev/null 2>&1
ssh "$HOST" "cp /tmp/yquake2-game.so $G/baseq2/game.so" 2>/dev/null
rm -rf build/pgo
mkdir -p build/pgo
ssh "$HOST" 'cd /tmp/yquake2-pgo && tar cf - .' 2>/dev/null | tar xf - -C build/pgo
ssh "$HOST" 'rm -rf /tmp/yquake2-pgo' 2>/dev/null
[ -n "$(find build/pgo -name '*.gcda' | head -1)" ] || { echo "no counts came back" >&2; exit 1; }
echo "$(find build/pgo -name '*.gcda' | wc -l) count files"
PGO=use ./build.sh mister > build/pgo-use.log 2>&1 || { tail -30 build/pgo-use.log; exit 1; }
grep -c "warning:" build/pgo-use.log || true
