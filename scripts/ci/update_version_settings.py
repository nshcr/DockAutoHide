#!/usr/bin/env python3
import os
import pathlib
import re

project_file = os.environ.get("PROJECT_FILE", "DockAutoHide.xcodeproj/project.pbxproj")
path = pathlib.Path(project_file)
if not path.exists():
    raise SystemExit(f"Project file not found: {path}")

build_number = os.environ.get("BUILD_NUMBER")
marketing_version = os.environ.get("MARKETING_VERSION")

if not build_number or not marketing_version:
    raise SystemExit("BUILD_NUMBER and MARKETING_VERSION must be set")

text = path.read_text()
text, n1 = re.subn(r"CURRENT_PROJECT_VERSION = [^;]+;", f"CURRENT_PROJECT_VERSION = {build_number};", text)
text, n2 = re.subn(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {marketing_version};", text)

if n1 == 0 or n2 == 0:
    raise SystemExit("Failed to update version settings in project.pbxproj")

path.write_text(text)
