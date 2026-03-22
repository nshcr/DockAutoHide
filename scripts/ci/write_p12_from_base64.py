#!/usr/bin/env python3
import base64
import os
import pathlib
import sys

output_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
if output_path is None:
    raise SystemExit("Usage: write_p12_from_base64.py <output_path>")

payload = os.environ.get("MACOS_CERTIFICATE", "")
if not payload:
    raise SystemExit("MACOS_CERTIFICATE is not set")

try:
    data = base64.b64decode(payload)
except Exception as exc:
    raise SystemExit(f"Failed to decode MACOS_CERTIFICATE: {exc}")

output_path.write_bytes(data)
