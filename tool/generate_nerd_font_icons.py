#!/usr/bin/env python3
"""Regenerates lib/src/theme/tokens/nerd_font_icons.dart from the bundled
Symbols Nerd Font.

Run from the package root:

    python3 tool/generate_nerd_font_icons.py

Requires fontTools (`pip install fonttools`). Reads the glyph names the
font itself carries (`fa-heart`, `oct-zap`, ...) and emits one IconData
constant per named codepoint, camel-cased with its set prefix kept
(`faHeart`, `octZap`). Codepoints whose glyphs have no semantic name
(`uniE0A0`-style) are skipped — a name that says nothing earns nothing.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "fonts" / "SymbolsNerdFontMono.ttf"
OUT = ROOT / "lib" / "src" / "theme" / "tokens" / "nerd_font_icons.dart"

UNNAMED = re.compile(r"^(uni|u)[0-9A-Fa-f]{4,6}$")

HEADER = """\
// GENERATED FILE — do not edit by hand.
// Regenerate with: python3 tool/generate_nerd_font_icons.py

import 'package:flutter/widgets.dart';

/// The Symbols Nerd Font, glyph by glyph.
///
/// Named the way the font names them, set prefix kept: `fa-heart` is
/// [faHeart], `oct-zap` is [octZap]. The font is bundled with the package,
/// so these work anywhere an [Icon] does.
class NerdFontIcons {
  const NerdFontIcons._();

"""

FOOTER = "}\n"


def identifier(glyph: str) -> str:
    words = [w for w in re.split(r"[^0-9A-Za-z]+", glyph) if w]
    name = words[0] + "".join(w[0].upper() + w[1:] for w in words[1:])
    # Set prefixes keep every name letter-first, but be certain.
    return name if name[0].isalpha() else "n" + name


def main() -> int:
    font = TTFont(FONT)
    cmap = font.getBestCmap()
    if not cmap:
        print(f"no usable cmap in {FONT}", file=sys.stderr)
        return 1

    seen: dict[str, int] = {}
    lines: list[str] = []
    skipped = 0
    for codepoint, glyph in sorted(cmap.items()):
        if UNNAMED.match(glyph):
            skipped += 1
            continue
        name = identifier(glyph)
        if name in seen:
            name = f"{name}U{codepoint:04X}"
        seen[name] = codepoint
        lines.append(
            f"  /// {glyph}\n"
            f"  static const IconData {name} = IconData(0x{codepoint:04X}, "
            f"fontFamily: 'SymbolsNerdFontMono', fontPackage: 'tomeui');\n"
        )

    OUT.write_text(HEADER + "\n".join(lines) + FOOTER)
    print(f"{len(lines)} icons written to {OUT.relative_to(ROOT)}; "
          f"{skipped} unnamed codepoints skipped")
    return 0


if __name__ == "__main__":
    sys.exit(main())
