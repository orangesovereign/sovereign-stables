#!/usr/bin/env python3
"""
Find bare calls to a name that ONLY exists as a table field.

The bug this catches: you promote `local function atWater()` to
`function Metabolism.atWater()` so another file can use it, and miss an
internal call site. Lua does not complain until that line runs, which in a
5-second background thread means it runs in production, not in testing.

Per file: collect names bound as a LOCAL (local function f / local f =),
names bound as a table field (function T.f), then flag `f(` call sites whose
name is a table field here but never bound as a local anywhere in the file.
"""
import re, os, sys, glob

ROOT = r"F:\Sovereign County RP\sovereign_stables"
files = sorted(glob.glob(os.path.join(ROOT, "client", "*.lua")) +
               glob.glob(os.path.join(ROOT, "server", "*.lua")) +
               glob.glob(os.path.join(ROOT, "shared", "*.lua")))

problems = []
for path in files:
    src = open(path, encoding="utf-8").read()
    # Strip MULTI-LINE block comments first (--[[ ... ]]), replacing each with the
    # same number of newlines so line numbers still line up. Without this, prose
    # inside the file header (e.g. "remembered [WG9]") looks like a table index.
    src = re.sub(r"--\[\[.*?\]\]", lambda m: "\n" * m.group(0).count("\n"), src, flags=re.S)
    lines = src.splitlines()

    # then strip line comments + strings so we never flag prose or a name in a message
    def strip(line):
        line = re.sub(r"--.*$", "", line)
        line = re.sub(r"'[^']*'", "''", line)
        line = re.sub(r'"[^"]*"', '""', line)
        return line

    code = [strip(l) for l in lines]
    body = "\n".join(code)

    locals_ = set(re.findall(r"\blocal\s+function\s+([A-Za-z_]\w*)", body))
    locals_ |= set(re.findall(r"\blocal\s+([A-Za-z_]\w*)\s*=", body))
    for grp in re.findall(r"\blocal\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)+)", body):
        locals_ |= {n.strip() for n in grp.split(",")}
    # function params count as locals too
    for params in re.findall(r"function\s*[\w.:]*\s*\(([^)]*)\)", body):
        locals_ |= {p.strip() for p in params.split(",") if p.strip().isidentifier()}
    # for-loop variables are locals: `for a, b in ...` and `for i = ...`
    for grp in re.findall(r"\bfor\s+([A-Za-z_][\w\s,]*?)\s+in\b", body):
        locals_ |= {n.strip() for n in grp.split(",") if n.strip().isidentifier()}
    locals_ |= set(re.findall(r"\bfor\s+([A-Za-z_]\w*)\s*=", body))

    fields = set(re.findall(r"\bfunction\s+[A-Za-z_]\w*[.:]([A-Za-z_]\w*)", body))

    suspects = fields - locals_
    for i, line in enumerate(code, 1):
        for name in suspects:
            # a bare call: not preceded by a dot/colon (that'd be T.name(...))
            if re.search(r"(?<![\w.:])" + re.escape(name) + r"\s*\(", line):
                problems.append((path, i, name, lines[i - 1].strip(),
                                 "bare call to '%s' (only exists as a table field)" % name))

    # ── DELETED-LOCAL TABLE INDEX ────────────────────────────────────────────
    # The `lastWash[source] = nil` class: a `local X = {}` gets deleted but an
    # `X[...]` reference survives. Valid Lua (indexing a nil global), so the byte-
    # compile never catches it — it only blows up when that line RUNS, often in a
    # disconnect handler nobody exercises until production.
    #
    # Heuristic: real globals in this codebase are TitleCase modules (Config,
    # Metabolism, Events, Bridge, Util, Wagon, Horse, ...). A LOWERCASE name
    # indexed as a table but never declared `local` in its file is almost always a
    # deleted local. Flag those; allow the handful of lowercase Lua/FiveM globals.
    lua_globals = {
        "string", "table", "math", "os", "io", "coroutine", "debug", "utf8",
        "source", "exports", "vector2", "vector3", "vector4", "msgpack", "json",
        "promise", "args", "self",
    }
    indexed = set(re.findall(r"(?<![\w.:])([a-z_]\w*)\s*\[", body))
    for name in indexed:
        if name in locals_ or name in lua_globals:
            continue
        for i, line in enumerate(code, 1):
            if re.search(r"(?<![\w.:])" + re.escape(name) + r"\s*\[", line):
                problems.append((path, i, name, lines[i - 1].strip(),
                                 "index of undeclared '%s[...]' (deleted local?)" % name))
                break

rel = lambda p: os.path.relpath(p, ROOT).replace("\\", "/")
for path, i, name, text, msg in problems:
    print("%s:%d  %s\n    %s" % (rel(path), i, msg, text))
print("\n%d suspect site(s)" % len(problems))
sys.exit(1 if problems else 0)
