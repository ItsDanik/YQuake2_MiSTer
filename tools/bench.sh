#!/bin/sh
# Run the game on a MiSTer for a while with the frame log and the profiler on
# (MISTER_HYBRID_FPSLOG, MISTER_HYBRID_PROFILE: mister_port.h in the game)
# and fetch both. It runs in the folder and with the core of
# tools/test_on_mister.sh (/tmp/yquake2_test, the set name YQuake2_TEST), set
# up first if it is not there: nothing installed is touched, and the core is
# the one just built. A game that is running is stopped. The binary is
# build/mister/yquake2, copied as YQuake2.bench; "tools/test_on_mister.sh
# stop" removes all of it.
# Settings go to /tmp/yq2bench (HOME, without -portable): the player's
# config.cfg and saved games are not touched.
# usage: MISTER=root@<address> tools/bench.sh <name> <seconds> <game arguments>
#   e.g. tools/bench.sh replay 60 +map q2demo1.dm2   -> build/bench/replay.log, replay.prof
# Environment for the game: BENCH_ENV="MISTER_HYBRID_HEIGHT=240 ..."; BENCH_NOPROFILE=1: the frame log only
# BENCH_BIN=<binary>: another build (that of an earlier run: build/bench/<name>.elf)
set -e
cd "$(dirname "$0")/.."
HOST=${MISTER:?set MISTER=root@<address of the MiSTer>}
NAME=$1; SECS=$2; shift 2
mkdir -p build/bench
G=/tmp/yquake2_test
ssh "$HOST" "[ -d $G ]" 2>/dev/null || tools/test_on_mister.sh Q2 > /dev/null
BIN=${BENCH_BIN:-build/mister/yquake2}
hybrid/docker.sh arm-linux-gnueabihf-strip -o build/bench/YQuake2.bench "$BIN"
# the profile is read with the symbols of the binary that made it
[ "$BIN" = "build/bench/$NAME.elf" ] || cp "$BIN" "build/bench/$NAME.elf"
scp -q build/bench/YQuake2.bench "$HOST:$G/YQuake2.bench" 2>/dev/null
cat > build/bench/run.sh <<END
#!/bin/bash
exec > /tmp/bench.out 2>&1
[ -f $G.pid ] && kill \$(cat $G.pid) && rm -f $G.pid
for p in \$(ps | grep "[.]/YQuake2" | awk '{print \$1}'); do kill \$p; done
sleep 3
grep -q YQuake2_TEST /tmp/CORENAME || { echo "load_core $G.mgl" > /dev/MiSTer_cmd; sleep 8; }
cd $G
rm -rf /tmp/yq2bench; mkdir -p /tmp/yq2bench
export MISTER_HYBRID_CORE=YQuake2 HOME=/tmp/yq2bench
export MISTER_HYBRID_FPSLOG=1 $BENCH_ENV
[ -n "$BENCH_NOPROFILE" ] || export MISTER_HYBRID_PROFILE=/tmp/bench.prof
nice -n -20 taskset 0x03 ./YQuake2.bench $* > /tmp/bench.log 2>&1 < /dev/null &
P=\$!
sleep $SECS
kill \$P
wait \$P
echo done
END
scp -q build/bench/run.sh "$HOST:/tmp/bench.sh" 2>/dev/null
ssh "$HOST" 'chmod +x /tmp/bench.sh; rm -f /tmp/bench.out /tmp/bench.prof; setsid nohup /tmp/bench.sh > /dev/null 2>&1 < /dev/null &' 2>/dev/null
sleep $((SECS + 12))
until ssh "$HOST" 'grep -q done /tmp/bench.out' 2>/dev/null; do sleep 2; done
scp -q "$HOST:/tmp/bench.log" "build/bench/$NAME.log" 2>/dev/null
[ -n "$BENCH_NOPROFILE" ] || scp -q "$HOST:/tmp/bench.prof" "build/bench/$NAME.prof" 2>/dev/null
grep -a "mister:.*frames" "build/bench/$NAME.log" | sed 's/^mister: //'
