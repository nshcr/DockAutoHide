#!/usr/bin/env python3
import base64
import os
import pathlib
import sys

output_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
if output_path is None:
    raise SystemExit("Usage: write_notary_key.py <output_path>")

payload = os.environ.get("APPLE_NOTARIZATION_PRIVATE_KEY", "")
if not payload:
    raise SystemExit("APPLE_NOTARIZATION_PRIVATE_KEY is not set")

if "BEGIN PRIVATE KEY" in payload:
    content = payload
else:
    try:
        content = base64.b64decode(payload).decode("utf-8")
    except Exception as exc:
        raise SystemExit(f"Failed to decode APPLE_NOTARIZATION_PRIVATE_KEY: {exc}")

if not content.endswith("\n"):
    content += "\n"

output_path.write_text(content)
