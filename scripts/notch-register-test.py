#!/usr/bin/env python3
"""Register a Swift file in the DynamicIslandTests target.

The app target uses a folder-synced group, but DynamicIslandTests does not, so a
new test file needs four pbxproj entries. They are cloned from the ones for
MenuBarClearanceTests.swift, which every relevant section already contains.
"""
import hashlib
import pathlib
import re
import sys

PBX = pathlib.Path(__file__).resolve().parent.parent / "DynamicIsland.xcodeproj" / "project.pbxproj"
ANCHOR = "MenuBarClearanceTests.swift"


def make_id(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def main() -> int:
    if len(sys.argv) != 2 or not sys.argv[1].endswith(".swift"):
        print("usage: notch-register-test.py <FileName>.swift")
        return 2
    name = sys.argv[1]
    text = PBX.read_text()
    if f"/* {name} */" in text:
        print(f"{name}: already registered")
        return 0
    ref, build = make_id("ref:" + name), make_id("build:" + name)
    group_child = re.compile(r"^\s*[0-9A-F]{24} /\* " + re.escape(ANCHOR) + r" \*/,\s*$")
    out, inserted = [], 0
    for line in text.splitlines(keepends=True):
        out.append(line)
        if ANCHOR not in line:
            continue
        if "isa = PBXBuildFile" in line:
            out.append(f"\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};\n")
        elif "isa = PBXFileReference" in line:
            out.append(f'\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};\n')
        elif group_child.match(line):
            out.append(f"\t\t\t\t{ref} /* {name} */,\n")
        elif line.strip().endswith(f"/* {ANCHOR} in Sources */,"):
            out.append(f"\t\t\t\t{build} /* {name} in Sources */,\n")
        else:
            continue
        inserted += 1
    if inserted != 4:
        print(f"expected 4 insertions, made {inserted}; pbxproj NOT written")
        return 1
    PBX.write_text("".join(out))
    print(f"{name}: registered")
    return 0


if __name__ == "__main__":
    sys.exit(main())
