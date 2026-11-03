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
                # Monochrome sprayer pictogram: tank, boom, chassis and wheels.
                r, g, b = 25, 34, 39
                tank = -0.34 < nx < 0.12 and -0.48 < ny < 0.05
                boom = abs(ny - 0.12) < 0.035 and -0.76 < nx < 0.76
                chassis = abs(ny - 0.34) < 0.035 and -0.48 < nx < 0.52
                wl = (nx + 0.30) ** 2 + (ny - 0.48) ** 2
                wr = (nx - 0.35) ** 2 + (ny - 0.48) ** 2
                wheel = (0.09 < wl < 0.16) or (0.09 < wr < 0.16)
                tractor = -0.52 < nx < -0.32 and -0.20 < ny < 0.12
                if tank or boom or chassis or wheel or tractor:
                    r, g, b = 238, 242, 232
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
            gui_tree = ET.parse(gui_file)
            if mod_root.name == "Spray_Hygiene" and gui_file.name == "AgriSystemsSprayHygieneMenuPage.xml":
                for button in gui_tree.getroot().iter("Button"):
                    profile = button.get("profile")
                    if profile != "buttonActivate":
                        raise RuntimeError(
                            f"Spray Hygiene menu Button must use the FS25 ButtonElement profile "
                            f"'buttonActivate', found {profile!r} in {gui_file}"
                        )

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
        runtime_version = re.search(r'\bMod\.VERSION\s*=\s*"([^"]+)"', runtime_text)
        if runtime_version and version and runtime_version.group(1) != version:
            raise RuntimeError(
                f"Lua version {runtime_version.group(1)} does not match modDesc version {version}: {runtime_script}"
            )

    if mod_root.name == "Spray_Hygiene":
        registration_script = mod_root / "scripts" / "register" / "AgriSystemsSprayerRegistration.lua"
        if not registration_script.is_file():
            raise RuntimeError(f"Missing explicit sprayer registration script: {registration_script}")
        registration_text = registration_script.read_text(encoding="utf-8")
        required_registration = (
            'g_specializationManager:addSpecialization(',
            'modName .. ".agriSystemsSprayer"',
            'SpecializationUtil.hasSpecialization(Sprayer, typeEntry.specializations)',
            'TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, injectIntoVehicleTypes)',
        )
        missing_registration = [marker for marker in required_registration if marker not in registration_text]
        if missing_registration:
            raise RuntimeError("Explicit sprayer registration is incomplete: " + "; ".join(missing_registration))
        if desc.findall("./vehicleTypeExtensions/vehicleTypeExtension"):
            raise RuntimeError("Spray & Hygiene must not use passive vehicleTypeExtensions for sprayer registration")
        if not any(node.get("filename") == "scripts/register/AgriSystemsSprayerRegistration.lua"
                   for node in desc.findall("./extraSourceFiles/sourceFile")):
            raise RuntimeError("modDesc does not load the explicit sprayer registration script")
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
        menu_script = mod_root / "scripts" / "gui" / "AgriSystemsSprayHygieneMenuPage.lua"
        if not menu_script.is_file():
            raise RuntimeError(f"Missing sprayer menu page script: {menu_script}")
        menu_text = menu_script.read_text(encoding="utf-8")
        required_menu_markers = (
            'type(player.getCurrentVehicle)',
            'self._lastControlledVehicle ~= controlledVehicle',
            'spec_" .. (g_currentModName or "FS25_AgriSystems_SprayHygiene")',
        )
        missing_menu_markers = [marker for marker in required_menu_markers if marker not in menu_text]
        if missing_menu_markers:
            raise RuntimeError("Current controlled sprayer selection is incomplete: " + "; ".join(missing_menu_markers))
        if "findMissionSprayer" in menu_text or "mission.vehicleSystem.vehicles" in menu_text:
            raise RuntimeError("Menu must not fall back to a mission-wide sprayer search")

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
