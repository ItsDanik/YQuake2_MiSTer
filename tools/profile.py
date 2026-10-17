#!/usr/bin/env python3
"""Read a profile written by the game (MISTER_HYBRID_PROFILE=<file>, see
mister_port.h in the game): where the game thread's CPU time went.
usage: tools/profile.py <profile> [<lines> [<stage>]]
Symbols come from build/bench/<name>.elf (or build/mister/yquake2) and build/mister/*/game.so."""
import bisect, collections, os, re, struct, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STAGES = ["other", "wait", "input", "server", "client", "render", "hud", "blit", "sound"]  # MISTER_T_* in mister_port.h
data = open(sys.argv[1], "rb").read()
top = int(sys.argv[2]) if len(sys.argv) > 2 else 40
m = re.search(rb"^samples (\d+)\n", data, re.M)
n = int(m.group(1))
pcs = struct.unpack_from("<%dI" % n, data, m.end())
what = data[m.end() + 4 * n : m.end() + 5 * n]

def symbols(path):
    out = subprocess.run(["nm", "-n", "--defined-only", "-C", path], capture_output=True, text=True).stdout
    table = []
    for line in out.splitlines():
        p = line.split(None, 2)
        if len(p) == 3 and p[1] in "tTwW" and not p[2].startswith("$"):
            table.append((int(p[0], 16) & ~1, p[2]))
    table.sort()
    return [a for a, _ in table], [s for _, s in table]

def symbols_dyn(path):
    out = subprocess.run(["nm", "-n", "-D", "--defined-only", path], capture_output=True, text=True).stdout
    table = sorted((int(p[0], 16) & ~1, p[2].split("@")[0]) for p in (l.split() for l in out.splitlines()) if len(p) == 3)
    return [a for a, _ in table], [s for _, s in table]

# executable mappings: (start, end, file offset, path)
maps = []
for line in data[: m.start()].decode(errors="replace").splitlines():
    p = line.split()
    if len(p) >= 6 and "x" in p[1]:
        a, b = (int(x, 16) for x in p[0].split("-"))
        maps.append((a, b, int(p[2], 16), p[5]))
local = {}
def table_for(path):
    if path not in local:
        name = os.path.basename(path)
        cand = None
        if name.startswith("YQuake2"):
            cand = sys.argv[1][:-5] + ".elf"  # tools/bench.sh keeps the binary of a run
            if not os.path.exists(cand):
                cand = os.path.join(ROOT, "build/mister/yquake2")
        elif name == "game.so":
            # baseq2, xatrix or rogue: the folder the library was loaded from
            cand = os.path.join(ROOT, "build/mister", os.path.basename(os.path.dirname(path)), name)
        if not cand and os.path.exists(os.path.join(ROOT, "build/bench/lib", name)):
            cand = os.path.join(ROOT, "build/bench/lib", name)  # copies of the MiSTer's libc and libm
            local[path] = (symbols_dyn(cand), False)
            return local[path]
        local[path] = (symbols(cand) if cand and os.path.exists(cand) else None, name.startswith("YQuake2"))
    return local[path]

flat = collections.Counter()
stage = collections.Counter()
per_stage = collections.defaultdict(collections.Counter)
for pc, w in zip(pcs, what):
    name = "?"
    for a, b, off, path in maps:
        if a <= pc < b:
            tab, exe = table_for(path)
            name = "[" + os.path.basename(path) + "]"
            if tab:
                addr = pc if exe else pc - a + off
                i = bisect.bisect_right(tab[0], addr) - 1
                if i >= 0:
                    name = tab[1][i] + ("" if exe else " " + name)
            break
    flat[name] += 1
    stage[w] += 1
    per_stage[w][name] += 1
print("%d samples (ms of CPU time of the game thread)" % n)
for w, c in stage.most_common():
    print("  %-7s %5.1f%%" % (STAGES[w], 100.0 * c / n))
print()
GROUPS = [
    ("world: spans (texture, z, surface cache)", r"^D_|^R_DrawSurface|^R_BuildLightMap|^R_AddDynamicLights|^R_DrawSurfaceBlock|^R_DrawSpanlet|^R_PolygonDrawSpans|^R_ClipAndDrawPoly|^R_DrawPoly|^R_DrawAlphaSurfaces|^TurbulentPow2|^NonTurbulentPow2|^R_DrawSky"),
    ("world: BSP, edges, clipping", r"^R_EmitEdge|^R_RecursiveClipBPoly|^R_GenerateSpans|^R_LeadingEdge|^R_TrailingEdge|^R_RenderFace|^R_ScanEdges|^R_RecursiveWorldNode|^R_ClipEdge|^R_RenderBmodelFace|^R_DrawSolidClipped|^R_InsertNewEdges|^R_StepActiveU|^R_RemoveEdges|^R_CleanupSpan|^R_EmitCachedEdge|^R_DrawSubmodel|^R_TransformFrustum|^R_BmodelCheckBBox|^R_EdgeDrawing|^R_MarkLeaves|^R_CullBox|^R_RenderWorld|^R_BeginEdgeFrame|^R_DrawBEntities|^R_FindTopnode|^R_SurfacePatch"),
    ("models, sprites, particles", r"^R_Alias|^R_Polyset|^R_DrawTriangle|^R_RasterizeAlias|^R_LightPoint|^R_RecursiveLightPoint|^R_DrawSprite|^R_DrawEntities|^R_DrawParticles|^R_DrawParticle|^R_DrawBeam|^R_PushDlights|^R_MarkLights|divsi3|udivsi3|^R_Draw[A-Z]*Alias|^R_PolysetDraw|^R_DrawNullModel"),
    ("2D: HUD, console, menus", r"^RE_Draw|^Draw_|^SCR_|^Con_|^M_|^Menu_"),
    ("copy to the core", r"^RE_FlushFrame|^RE_EndFrame|^memcpy|^SDL_|^MH_|^MISTER_|^fps_"),
    ("game logic (game.so)", r"game.so"),
    ("server, physics, network, client state", r"^SV_|^PM_|^Pmove|^MSG_|^CL_|^Netchan|^CM_|^Cvar|^Cmd_|^Com_|^Info_|^FS_"),
    ("sound mixing", r"^S_|^SDL_|^OGG_|^stb_vorbis"),
]
group = collections.Counter()
for name, c in flat.items():
    for g, rx in GROUPS:
        if re.search(rx, name):
            group[g] += c
            break
    else:
        group["everything else"] += c
for g, c in group.most_common():
    print("%5.1f%%  %s" % (100.0 * c / n, g))
if len(sys.argv) > 3:  # the functions of one stage: tools/profile.py <profile> <lines> <stage>
    w = STAGES.index(sys.argv[3])
    print("\n%s:" % sys.argv[3])
    for name, c in per_stage[w].most_common(top):
        print("%5.1f%%  %s" % (100.0 * c / n, name))
    sys.exit(0)
print()
for name, c in flat.most_common(top):
    print("%5.1f%%  %s" % (100.0 * c / n, name))
