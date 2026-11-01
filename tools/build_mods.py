#!/usr/bin/env python3
"""Validate and package the two independent FS25 AgriSystems mods."""
from __future__ import annotations

import argparse
import re
import shutil
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODS = (
    ("Spray_Hygiene", "FS25_AgriSystems_SprayHygiene.zip"),
    ("Farm_Biosecurity", "FS25_AgriSystems_FarmBiosecurity.zip"),
)
RUNTIME_DIRS = ("scripts", "translations", "Config", "Assets", "store")


def validate(mod_root: Path) -> str:
    desc_path = mod_root / "modDesc.xml"
    if not desc_path.is_file():
        raise RuntimeError(f"Missing modDesc.xml: {desc_path}")
    tree = ET.parse(desc_path)
    desc = tree.getroot()
    version = desc.findtext("version")
    if not version:
        version = desc.findtext("version") or desc.findtext("./version")
    for node in desc.findall("./extraSourceFiles/sourceFile"):
        filename = node.get("filename")
        if not filename:
            raise RuntimeError(f"Empty sourceFile entry in {desc_path}")
        target = mod_root / filename
        if not target.is_file():
            raise RuntimeError(f"modDesc references missing source file: {target}")

    prefix = desc.find("./l10n")
    if prefix is not None:
        filename_prefix = prefix.get("filenamePrefix")
        if filename_prefix:
            for language in ("en", "de"):
                target = mod_root / f"{filename_prefix}_{language}.xml"
                if not target.is_file():
                    raise RuntimeError(f"Missing declared localization file: {target}")
                ET.parse(target)

    register = mod_root / "scripts" / "register.lua"
    if register.is_file():
        text = register.read_text(encoding="utf-8")
        for relative in re.findall(r'Utils\.getFilename\("([^"]+)"', text):
            target = mod_root / relative
            if not target.is_file():
                raise RuntimeError(f"Specialization registration references missing script: {target}")

    return version or "unknown"


def build(output: Path, clean: bool) -> list[Path]:
    output.mkdir(parents=True, exist_ok=True)
    stage_root = output / ".staging"
    if clean and stage_root.exists():
        shutil.rmtree(stage_root)
    stage_root.mkdir(parents=True, exist_ok=True)

    archives: list[Path] = []
    for folder, archive_name in MODS:
        mod_root = ROOT / folder
        version = validate(mod_root)
        stage = stage_root / folder
        if stage.exists():
            shutil.rmtree(stage)
        stage.mkdir(parents=True)

        shutil.copy2(mod_root / "modDesc.xml", stage / "modDesc.xml")
        for directory in RUNTIME_DIRS:
            source = mod_root / directory
            if source.is_dir():
                shutil.copytree(
                    source,
                    stage / directory,
                    ignore=shutil.ignore_patterns(".gitkeep", "__pycache__", "*.pyc"),
                )

        archive = output / archive_name
        if archive.exists():
            archive.unlink()
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
            for file in sorted(stage.rglob("*")):
                if file.is_file():
                    zf.write(file, file.relative_to(stage).as_posix())

        with zipfile.ZipFile(archive) as zf:
            names = zf.namelist()
            if "modDesc.xml" not in names or any(name.startswith(folder + "/") for name in names):
                raise RuntimeError(f"Invalid ZIP root layout: {archive}")
            bad = zf.testzip()
            if bad:
                raise RuntimeError(f"Corrupt ZIP member {bad} in {archive}")
        print(f"Built {archive.relative_to(ROOT)} (mod version {version}, {archive.stat().st_size} bytes)")
        archives.append(archive)

    return archives


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default="Releases")
    parser.add_argument("--clean", action="store_true")
    args = parser.parse_args()
    output = Path(args.output_dir)
    if not output.is_absolute():
        output = ROOT / output
    try:
        build(output, args.clean)
    except Exception as exc:
        print(f"BUILD FAILED: {exc}", file=sys.stderr)
        return 1
    print("Build finished. Only runtime files are included; no in-game certification is implied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
