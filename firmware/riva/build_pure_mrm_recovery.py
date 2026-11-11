#!/usr/bin/env python3
"""
Coki Studios — Dedicated MRM Native Recovery Builder for Redmi 5A (riva)
Replaces OrangeFox branding and splash screens with clean Coki Studios MRM OLED UI.
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


def decode_and_resize_screens(out_dir: Path) -> Path:
    """Decode stitch base64 images and scale to 1080x1920."""
    screens_dir = Path.home() / ".gemini/antigravity/brain/2aa04867-d798-4e5b-b203-1c5ada0e3bb2/scratch/stitch_mrm/live_screens"
    target_splash = out_dir / "mrm_splash_1080.png"
    if target_splash.exists() and target_splash.stat().st_size > 10000:
        return target_splash

    src_p = screens_dir / "screen2_uic_idle.png"
    if not src_p.exists():
        src_p = screens_dir / "screen1_disconnect.png"

    with src_p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    raw = base64.b64decode(data.get("dataString", ""))
    tmp_raw = out_dir / "tmp_raw.png"
    tmp_raw.write_bytes(raw)
    subprocess.run(["sips", "-z", "1920", "1080", str(tmp_raw), "--out", str(target_splash)], check=True)
    return target_splash


def build_pure_mrm_recovery(out_dir: Path = DEFAULT_OUT_DIR) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    splash_1080 = decode_and_resize_screens(out_dir)

    donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR11.0_N2" / "recovery.img"
    if not donor_path.is_file():
        donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR10.1_O1" / "recovery.img"

    with donor_path.open("rb") as f:
        donor_hdr = bytearray(f.read(RIVA_PAGE_SIZE))
        k_sz = struct.unpack("<I", donor_hdr[8:12])[0]
        k_pages = (k_sz + RIVA_PAGE_SIZE - 1) // RIVA_PAGE_SIZE
        kernel_bytes = f.read(k_pages * RIVA_PAGE_SIZE)[:k_sz]

    stage_dir = out_dir / "mrm_pure_stage"
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    unpacked_rd = out_dir / "unpacked_donor" / "ramdisk.cpio.gz"
    gunzip_proc = subprocess.Popen(["gzip", "-dc", str(unpacked_rd)], stdout=subprocess.PIPE)
    subprocess.run(["cpio", "-id", "--quiet"], cwd=stage_dir, stdin=gunzip_proc.stdout, check=True)
    gunzip_proc.wait()

    # Reemplazar la imagen de fondo de Splash de OrangeFox por la pantalla completa de MRM
    splash_bg = stage_dir / "twres" / "images" / "Splash" / "original.png"
    shutil.copy2(splash_1080, splash_bg)

    # Dejar vacías las imágenes superpuestas del logo de OrangeFox (logo_w, logo_o, logo_d)
    empty_png = stage_dir / "twres" / "images" / "Splash" / "empty.png"
    for logo in ("logo_w.png", "logo_o.png", "logo_d.png"):
        shutil.copy2(empty_png, stage_dir / "twres" / "images" / "Splash" / logo)

    # Reescribir splash.xml para quitar textos, bordes naranjas y mostrar únicamente el fondo negro de Stitch
    clean_splash_xml = (
        '<?xml version="1.0"?>\n'
        '<recovery>\n'
        '    <details>\n'
        '        <resolution width="1080" />\n'
        '        <themeversion>3</themeversion>\n'
        '    </details>\n'
        '    <resources>\n'
        '        <image name="splash_bg" filename="Splash/original" retainaspect="1"/>\n'
        '    </resources>\n'
        '    <pages>\n'
        '        <page name="splash">\n'
        '            <background color="#000000"/>\n'
        '            <image>\n'
        '                <image resource="splash_bg"/>\n'
        '                <placement x="0" y="0" placement="1"/>\n'
        '            </image>\n'
        '        </page>\n'
        '    </pages>\n'
        '</recovery>\n'
    )
    (stage_dir / "twres" / "splash.xml").write_text(clean_splash_xml, encoding="utf-8")

    # Monturas de Protected Storage (PS) y Normal Storage (NS)
    (stage_dir / "ns").mkdir(parents=True, exist_ok=True)
    (stage_dir / "ps").mkdir(parents=True, exist_ok=True)

    # Reempaquetar
    out_rd_gz = out_dir / "pure_mrm_ramdisk.cpio.gz"
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

    print(f"✔ Pure MRM Recovery compilado: {out_img} ({out_img.stat().st_size} bytes)")
    return out_img


if __name__ == "__main__":
    build_pure_mrm_recovery()
