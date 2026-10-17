#!/bin/sh
# Build Quake II for the MiSTer in the toolchain container: static SDL2 with the
# hybrid core drivers first (once), then the game.
# usage: ./build.sh [mister|host] [Release|RelWithDebInfo|Debug]
#   mister  ARM binary for the MiSTer     -> build/mister/yquake2
#   host    same code for this PC, to run against hybrid/tools/fakecore
# The game library goes to build/<target>/baseq2/game.so.
set -e
cd "$(dirname "$0")"
TARGET=${1:-mister}
TYPE=${2:-Release}
ROOT=$PWD
PREFIX=$ROOT/build/sdl/$TARGET/prefix

hybrid/docker.sh hybrid/sdl2/build.sh "$TARGET" build/sdl

CROSS=
if [ "$TARGET" = mister ]; then
    CROSS="-DCMAKE_TOOLCHAIN_FILE=$ROOT/hybrid/toolchain/mister.cmake -DCMAKE_FIND_ROOT_PATH=$PREFIX"
    # Profile guided optimisation of the game (tools/pgo.sh): PGO=generate
    # builds a binary that counts what runs on the MiSTer, PGO=use (the
    # default when build/pgo is there, PGO=off without) builds with the
    # counts. Partial training: what the runs did not reach is optimised as
    # without a profile, and so is a function whose code has changed since
    # (-Wno-coverage-mismatch, else an error). Not the mission packs.
    if [ -z "$PGO" ] && [ -d build/pgo ]; then PGO=use; fi
    PGOFLAGS=
    PGOLINK=
    case "$PGO" in
    generate)
        PGOFLAGS="-fprofile-generate=/tmp/yquake2-pgo -fprofile-update=atomic"
        PGOLINK="$PGOFLAGS" ;;
    use)
        [ -d build/pgo ] || { echo "build/pgo: run tools/pgo.sh first" >&2; exit 1; }
        PGOFLAGS="-fprofile-use=$ROOT/build/pgo -fprofile-partial-training -fprofile-correction -Wno-missing-profile -Wno-coverage-mismatch" ;;
    esac
    FLAGS="-mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -fno-pie -marm"
    PACKCROSS="$CROSS -DCMAKE_C_FLAGS='$FLAGS -DMISTER_HYBRID'"
    # ARM instructions, not Thumb: a few percent faster (the Xash3D core).
    # Replaces the toolchain file's flags, so they are repeated.
    CROSS="$CROSS -DCMAKE_C_FLAGS='$FLAGS $PGOFLAGS'"
    # the compiler's runtime is linked in, the binary only needs the MiSTer's glibc
    CROSS="$CROSS -DCMAKE_EXE_LINKER_FLAGS='-no-pie -static-libstdc++ -static-libgcc $PGOLINK'"
    CROSS="$CROSS -DCMAKE_MODULE_LINKER_FLAGS='$PGOLINK'"
else
    PACKCROSS="-DCMAKE_C_FLAGS=-DMISTER_HYBRID"
fi

# GAME: Yamagi Quake II with MISTER_HYBRID is one binary with the software
# renderer in it, and the game library baseq2/game.so
hybrid/docker.sh sh -c "
  cmake -S yquake2 -B build/$TARGET/cmake -DCMAKE_BUILD_TYPE=$TYPE $CROSS \
    -DCMAKE_PREFIX_PATH=$PREFIX -DMISTER_HYBRID=ON > build/$TARGET-configure.log &&
  cmake --build build/$TARGET/cmake -j\$(nproc)"
mkdir -p "build/$TARGET/baseq2"
cp "build/$TARGET/cmake/release/quake2" "build/$TARGET/yquake2"
cp "build/$TARGET/cmake/release/baseq2/game.so" "build/$TARGET/baseq2/game.so"

# GAME: the mission packs' game libraries, from their own repositories:
# The Reckoning (xatrix/) and Ground Zero (rogue/)
for PACK in xatrix rogue; do
    hybrid/docker.sh sh -c "
      cmake -S $PACK -B build/$TARGET/$PACK-cmake -DCMAKE_BUILD_TYPE=Release $PACKCROSS \
        > build/$TARGET-$PACK.log &&
      cmake --build build/$TARGET/$PACK-cmake -j\$(nproc) >> build/$TARGET-$PACK.log" ||
        { tail -30 "build/$TARGET-$PACK.log"; exit 1; }
    mkdir -p "build/$TARGET/$PACK"
    cp "build/$TARGET/$PACK-cmake/Release/game.so" "build/$TARGET/$PACK/game.so"
done
ls -la "build/$TARGET/yquake2" build/$TARGET/*/game.so

# The launch script's messages on the core's picture (hybrid/tools/mh_message.c)
if [ "$TARGET" = mister ]; then
    hybrid/docker.sh arm-linux-gnueabihf-gcc -O2 -static -Ihybrid/hps -o build/mister/mh_message \
        hybrid/tools/mh_message.c hybrid/hps/*.c -lpthread -lm
fi
