#!/usr/bin/env python3
"""Rename PNG attachments exported by xcresulttool to match the XCTAttachment
`name` we set in the UI test.

`xcrun xcresulttool export attachments` writes each attachment to a file
named after its internal id (`<uuid>.png`) plus a `manifest.json` that
maps ids back to the attachment metadata. This script reads the manifest
and copies each PNG to `<output>/<attachment-name>.png`.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

# xcresulttool decorates XCTAttachment.name with iteration + UUID metadata,
# producing names like "01-rf-hero_0_1E3FF4FA-68B7-4413-9F1C-E5BD8BE928F5.png".
# We want just the bit the UI test set ("01-rf-hero"). Falls through to the
# raw name when the suffix isn't decorated.
_DECORATION = re.compile(
    r"^(?P<base>.+?)_\d+_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-"
    r"[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.png$"
)


def clean_name(raw: str) -> str:
    m = _DECORATION.match(raw)
    if m:
        return m.group("base")
    return raw[:-4] if raw.lower().endswith(".png") else raw


def main(src: Path, dst: Path) -> int:
    manifest_path = src / "manifest.json"
    if not manifest_path.exists():
        print(f"manifest.json not found in {src}", file=sys.stderr)
        return 1

    manifest = json.loads(manifest_path.read_text())
    dst.mkdir(parents=True, exist_ok=True)

    written = 0
    for test in manifest:
        for att in test.get("attachments", []):
            raw = att.get("suggestedHumanReadableName") or att.get("exportedFileName")
            exported = att.get("exportedFileName")
            if not raw or not exported:
                continue
            src_path = src / exported
            if not src_path.exists():
                continue
            if src_path.suffix.lower() != ".png":
                continue
            target = dst / f"{clean_name(raw)}.png"
            shutil.copy2(src_path, target)
            written += 1

    print(f"copied {written} screenshots → {dst}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: rename_screenshots.py <attachments-dir> <output-dir>",
              file=sys.stderr)
        sys.exit(64)
    sys.exit(main(Path(sys.argv[1]), Path(sys.argv[2])))
