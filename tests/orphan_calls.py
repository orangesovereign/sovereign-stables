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
    lines = src.splitlines()

    # strip comments + strings so we never flag prose or a name inside a message
    def strip(line):
        line = re.sub(r"--\[\[.*?\]\]", "", line)
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

    fields = set(re.findall(r"\bfunction\s+[A-Za-z_]\w*[.:]([A-Za-z_]\w*)", body))

    suspects = fields - locals_
    if not suspects:
        continue
    for i, line in enumerate(code, 1):
        for name in suspects:
            # a bare call: not preceded by a dot/colon (that'd be T.name(...))
            if re.search(r"(?<![\w.:])" + re.escape(name) + r"\s*\(", line):
                problems.append((path, i, name, lines[i - 1].strip()))

rel = lambda p: os.path.relpath(p, ROOT).replace("\\", "/")
for path, i, name, text in problems:
    print("%s:%d  bare call to '%s' (only exists as a table field)\n    %s"
          % (rel(path), i, name, text))
print("\n%d suspect call site(s)" % len(problems))
sys.exit(1 if problems else 0)
