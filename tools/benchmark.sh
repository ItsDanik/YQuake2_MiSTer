#!/bin/sh
# The standard set of scenes for tools/bench.sh, the frame log only. Prints the
# frames per second and the milliseconds per stage of each (tools/benchsum.py,
# without the first 15 seconds: loading).
# usage: MISTER=root@<address> tools/benchmark.sh <name> [<environment for the game>]
#   e.g. tools/benchmark.sh base
#        tools/benchmark.sh tall MISTER_HYBRID_HEIGHT=240
# Logs: build/bench/<name>-<scene>.log. The scenes are the demo version's (its pak0.pak):
#   replay   q2demo1.dm2, the recorded demo on map demo2: the same frames every run, 60 seconds
#   demo1    the start of map demo1, the player standing, 40 seconds
#   demo3    the start of map demo3, the player standing, 40 seconds
set -e
cd "$(dirname "$0")/.."
NAME=${1:?usage: tools/benchmark.sh <name> [<environment>]}
shift
export BENCH_NOPROFILE=1 BENCH_ENV="$*"
tools/bench.sh "$NAME-replay" 60 +map q2demo1.dm2 > /dev/null 2>&1
tools/bench.sh "$NAME-demo1" 40 +map demo1 > /dev/null 2>&1
tools/bench.sh "$NAME-demo3" 40 +map demo3 > /dev/null 2>&1
tools/benchsum.py "build/bench/$NAME-replay.log" "build/bench/$NAME-demo1.log" "build/bench/$NAME-demo3.log"
