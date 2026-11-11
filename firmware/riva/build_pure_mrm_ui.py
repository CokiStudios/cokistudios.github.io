#!/usr/bin/env python3
"""
Coki Studios — Complete MRM UI Replacement for Redmi 5A (riva)
Replaces twres/ui.xml and twres/pages/main.xml with clean, pure Coki Studios MRM OLED UI.
Removes all OrangeFox file managers, menus, and buttons.
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT_DIR = REPO_ROOT / "build" / "riva_firmware"
RIVA_PAGE_SIZE = 4096


def prepare_mrm_screens(out_dir: Path) -> Path:
    splash_1080 = out_dir / "mrm_splash_1080.png"
    if splash_1080.exists() and splash_1080.stat().st_size > 10000:
        return splash_1080

    screens_dir = Path.home() / ".gemini/antigravity/brain/2aa04867-d798-4e5b-b203-1c5ada0e3bb2/scratch/stitch_mrm/live_screens"
    src_p = screens_dir / "screen2_uic_idle.png"
    with src_p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    raw = base64.b64decode(data.get("dataString", ""))
    tmp_raw = out_dir / "tmp_raw.png"
    tmp_raw.write_bytes(raw)
    subprocess.run(["sips", "-z", "1920", "1080", str(tmp_raw), "--out", str(splash_1080)], check=True)
    return splash_1080


def build_pure_mrm_ui(out_dir: Path = DEFAULT_OUT_DIR) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    splash_1080 = prepare_mrm_screens(out_dir)

    donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR11.0_N2" / "recovery.img"
    if not donor_path.is_file():
        donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR10.1_O1" / "recovery.img"

    with donor_path.open("rb") as f:
        donor_hdr = bytearray(f.read(RIVA_PAGE_SIZE))
        k_sz = struct.unpack("<I", donor_hdr[8:12])[0]
        k_pages = (k_sz + RIVA_PAGE_SIZE - 1) // RIVA_PAGE_SIZE
        kernel_bytes = f.read(k_pages * RIVA_PAGE_SIZE)[:k_sz]

    stage_dir = out_dir / "mrm_pure_ui_stage"
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    unpacked_rd = out_dir / "unpacked_donor" / "ramdisk.cpio.gz"
    gunzip_proc = subprocess.Popen(["gzip", "-dc", str(unpacked_rd)], stdout=subprocess.PIPE)
    subprocess.run(["cpio", "-id", "--quiet"], cwd=stage_dir, stdin=gunzip_proc.stdout, check=True)
    gunzip_proc.wait()

    # Copiar pantalla de Stitch como recurso principal de UI
    res_img = stage_dir / "twres" / "images" / "mrm_main.png"
    shutil.copy2(splash_1080, res_img)

    # Reemplazar completamente twres/ui.xml para que cargue SOLO la página de MRM y no los menús de OrangeFox
    pure_ui_xml = (
        '<?xml version="1.0"?>\n'
        '<recovery>\n'
        '    <details>\n'
        '        <resolution width="1080" height="1920" />\n'
        '        <themeversion>3</themeversion>\n'
        '    </details>\n'
        '    <resources>\n'
        '        <image name="mrm_bg" filename="mrm_main" retainaspect="1"/>\n'
        '        <font name="mrm_font" filename="Roboto-Medium.ttf" size="36"/>\n'
        '    </resources>\n'
        '    <pages>\n'
        '        <page name="main">\n'
        '            <background color="#000000"/>\n'
        '            <image>\n'
        '                <image resource="mrm_bg"/>\n'
        '                <placement x="0" y="0" placement="1"/>\n'
        '            </image>\n'
        '        </page>\n'
        '    </pages>\n'
        '</recovery>\n'
    )
    (stage_dir / "twres" / "ui.xml").write_text(pure_ui_xml, encoding="utf-8")
    (stage_dir / "twres" / "splash.xml").write_text(pure_ui_xml, encoding="utf-8")

    # Neutralizar foxstart.sh para que no ejecute temas ni reemplace twres en caliente
    foxstart_sh = stage_dir / "sbin" / "foxstart.sh"
    if foxstart_sh.exists():
        foxstart_sh.write_text("#!/sbin/sh\nexit 0\n", encoding="utf-8")
        os.chmod(foxstart_sh, 0o755)

    # Inyectar particiones protegidas
    (stage_dir / "ns").mkdir(parents=True, exist_ok=True)
    (stage_dir / "ps").mkdir(parents=True, exist_ok=True)

    # Reempaquetar ramdisk a cpio.gz
    out_rd_gz = out_dir / "pure_ui_ramdisk.cpio.gz"
    rel_files = "\n".join(sorted(str(p.relative_to(stage_dir)) for p in stage_dir.rglob("*"))) + "\n"
    cpio_proc = subprocess.run(
        ["cpio", "-o", "--format", "newc", "--quiet"],
        cwd=stage_dir,
        input=rel_files.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    gz_proc = subprocess.run(
        ["gzip", "-n", "-9"],
        input=cpio_proc.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    out_rd_gz.write_bytes(gz_proc.stdout)
    ramdisk_bytes = out_rd_gz.read_bytes()
    r_sz = len(ramdisk_bytes)

    struct.pack_into("<I", donor_hdr, 16, r_sz)
    sha = hashlib.sha1(kernel_bytes + ramdisk_bytes).digest()
    donor_hdr[64 + 512 : 64 + 512 + len(sha)] = sha

    def _pad(data: bytes, ps: int) -> bytes:
        rem = len(data) % ps
        return data if rem == 0 else data + (b"\x00" * (ps - rem))

    out_img = out_dir / "cs_mrm_recovery_riva.img"
    with out_img.open("wb") as f:
        f.write(donor_hdr)
        f.write(_pad(kernel_bytes, RIVA_PAGE_SIZE))
        f.write(_pad(ramdisk_bytes, RIVA_PAGE_SIZE))

    print(f"✔ Pure MRM UI Recovery compilado: {out_img} ({out_img.stat().st_size} bytes)")
    return out_img


if __name__ == "__main__":
    build_pure_mrm_ui()
