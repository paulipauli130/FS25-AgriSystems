#!/usr/bin/env python3
"""Validate and package the two independent FS25 AgriSystems mods."""
from __future__ import annotations

import argparse
import math
import re
import shutil
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODS = (
    ("Spray_Hygiene", "FS25_AgriSystems_SprayHygiene.zip"),
    ("Farm_Biosecurity", "FS25_AgriSystems_FarmBiosecurity.zip"),
)
RUNTIME_DIRS = ("scripts", "translations", "Config", "Assets", "store", "gui")
ICON_SIZE = 128


def make_icon(kind: str) -> bytes:
    """Create a small uncompressed BGRA DDS icon using only the Python standard library."""
    pixels = bytearray()
    for y in range(ICON_SIZE):
        for x in range(ICON_SIZE):
            nx = (x - 63.5) / 63.5
            ny = (y - 63.5) / 63.5
            radius = math.sqrt(nx * nx + ny * ny)
            if radius > 0.94:
                r, g, b = 22, 29, 36
            elif kind == "spray":
                r, g, b = 28, 105, 94
                if abs(ny + 0.12) < 0.075 and abs(nx) < 0.62:
                    r, g, b = 235, 244, 239
                if (nx - 0.25) ** 2 + (ny - 0.43) ** 2 < 0.055:
                    r, g, b = 110, 205, 239
                if (nx + 0.25) ** 2 + (ny - 0.43) ** 2 < 0.055:
                    r, g, b = 110, 205, 239
            else:
                r, g, b = 43, 112, 67
                shield = abs(nx) < 0.55 and -0.58 < ny < 0.35 + 0.25 * (1 - abs(nx) / 0.55)
                if shield:
                    r, g, b = 235, 242, 228
                if shield and (abs(nx) < 0.09 or abs(ny + 0.12) < 0.09):
                    r, g, b = 43, 112, 67
            pixels.extend((b, g, r, 255))

    flags = 0x00000001 | 0x00000002 | 0x00000004 | 0x00001000
    pf_flags = 0x00000040 | 0x00000001
    header = struct.pack(
        "<7I11I",
        124, flags, ICON_SIZE, ICON_SIZE, ICON_SIZE * 4, 0, 0,
        *([0] * 11),
    )
    pixel_format = struct.pack(
        "<8I", 32, pf_flags, 0, 32, 0x00FF0000, 0x0000FF00,
        0x000000FF, 0xFF000000,
    )
    caps = struct.pack("<5I", 0x00001000, 0, 0, 0, 0)
    return b"DDS " + header + pixel_format + caps + bytes(pixels)


def validate(mod_root: Path) -> str:
    desc_path = mod_root / "modDesc.xml"
    if not desc_path.is_file():
        raise RuntimeError(f"Missing modDesc.xml: {desc_path}")
    tree = ET.parse(desc_path)
    desc = tree.getroot()
    version = desc.findtext("version")
    if not version:
        version = desc.findtext("./version")
    icon_filename = desc.findtext("iconFilename")
    if icon_filename != "icon.dds":
        raise RuntimeError(f"modDesc must declare iconFilename=\"icon.dds\": {desc_path}")
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

    gui_root = mod_root / "gui"
    if gui_root.is_dir():
        for gui_file in gui_root.rglob("*.xml"):
            ET.parse(gui_file)

    register = mod_root / "scripts" / "register.lua"
    if register.is_file():
        text = register.read_text(encoding="utf-8")
        for relative in re.findall(r'Utils\.getFilename\("([^"]+)"', text):
            target = mod_root / relative
            if not target.is_file():
                raise RuntimeError(f"Specialization registration references missing script: {target}")

    # Keep the version reported by Lua in sync with the version shown by the game.
    for runtime_script in (mod_root / "scripts").glob("AgriSystems*.lua"):
        runtime_text = runtime_script.read_text(encoding="utf-8")
        runtime_version = re.search(r"\bMod\.VERSION\s*=\s*[\"']([^\"']+)[\"']", runtime_text)
        if runtime_version and version and runtime_version.group(1) != version:
            raise RuntimeError(
                f"Lua version {runtime_version.group(1)} does not match modDesc version {version}: {runtime_script}"
            )

    if mod_root.name == "Spray_Hygiene":
        expected_name = "FS25_AgriSystems_SprayHygiene.agriSystemsSprayer"
        extensions = desc.findall("./vehicleTypeExtensions/vehicleTypeExtension/specialization")
        if not extensions or any(node.get("name") != expected_name for node in extensions):
            raise RuntimeError(
                "Every Spray & Hygiene vehicleTypeExtension must use the mod-qualified "
                f"specialization name {expected_name}"
            )
        sprayer_script = mod_root / "scripts" / "vehicle" / "AgriSystemsSprayer.lua"
        if not sprayer_script.is_file():
            raise RuntimeError(f"Missing sprayer specialization script: {sprayer_script}")
        sprayer_text = sprayer_script.read_text(encoding="utf-8")
        required_markers = (
            'local ROOT_KEY = MOD_NAME .. ".agriSystemsSprayer"',
            'local SPEC_TABLE_NAME = "spec_" .. ROOT_KEY',
            'local base = "vehicles.vehicle(?)." .. ROOT_KEY',
            'local base = savegame.key .. "." .. ROOT_KEY',
            'self[SPEC_TABLE_NAME] = spec',
        )
        missing_markers = [marker for marker in required_markers if marker not in sprayer_text]
        if missing_markers:
            raise RuntimeError(
                "Sprayer specialization namespace/savegame schema regression: "
                + "; ".join(missing_markers)
            )
        if "self.spec_agriSystemsSprayer" in sprayer_text:
            raise RuntimeError("Sprayer specialization still uses the unqualified spec table")

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
        icon_kind = "spray" if folder == "Spray_Hygiene" else "biosecurity"
        (stage / "icon.dds").write_bytes(make_icon(icon_kind))

        archive = output / archive_name
        if archive.exists():
            archive.unlink()
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
            for file in sorted(stage.rglob("*")):
                if file.is_file():
                    zf.write(file, file.relative_to(stage).as_posix())

        with zipfile.ZipFile(archive) as zf:
            names = set(zf.namelist())
            if "modDesc.xml" not in names or any(name.startswith(folder + "/") for name in names):
                raise RuntimeError(f"Invalid ZIP root layout: {archive}")

            descriptor = ET.parse(stage / "modDesc.xml").getroot()
            required = {
                node.get("filename")
                for node in descriptor.findall("./extraSourceFiles/sourceFile")
            }
            l10n = descriptor.find("./l10n")
            if l10n is not None and l10n.get("filenamePrefix"):
                prefix = l10n.get("filenamePrefix")
                required.update(
                    f"{prefix}_{language}.xml" for language in ("en", "de")
                )
            required.add(descriptor.findtext("iconFilename"))
            missing = sorted(path for path in required if path not in names)
            if missing:
                raise RuntimeError(
                    f"Runtime files referenced by modDesc are missing from {archive}: "
                    + ", ".join(missing)
                )

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
