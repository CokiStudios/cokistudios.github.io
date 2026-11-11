#!/usr/bin/env python3
"""
Coki Studios — Complete MRM UI Engine for Redmi 5A (riva)
Integrates cleanly with the verified recovery GUI pipeline:
- Preserves full twres/ui.xml includes so XML parsing succeeds without crashing
- Replaces main.xml, navbar, and filemanagerlist with the full-screen Stitch MRM page
- Forces backlight/brightness to 100% and screen timeout to 0 (no blackouts)
- Embeds the full-resolution 1080x1920 OLED MRM graphic
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


def get_splash_1080(out_dir: Path) -> Path:
    target = out_dir / "mrm_splash_1080.png"
    if target.exists() and target.stat().st_size > 10000:
        return target
    screens_dir = Path.home() / ".gemini/antigravity/brain/2aa04867-d798-4e5b-b203-1c5ada0e3bb2/scratch/stitch_mrm/live_screens"
    src_p = screens_dir / "screen2_uic_idle.png"
    with src_p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    raw = base64.b64decode(data.get("dataString", ""))
    tmp_raw = out_dir / "tmp_raw.png"
    tmp_raw.write_bytes(raw)
    subprocess.run(["sips", "-z", "1920", "1080", str(tmp_raw), "--out", str(target)], check=True)
    return target


def build_clean_mrm_recovery(out_dir: Path = DEFAULT_OUT_DIR) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    splash_1080 = get_splash_1080(out_dir)

    donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR11.0_N2" / "recovery.img"
    if not donor_path.is_file():
        donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR10.1_O1" / "recovery.img"

    with donor_path.open("rb") as f:
        donor_hdr = bytearray(f.read(RIVA_PAGE_SIZE))
        k_sz = struct.unpack("<I", donor_hdr[8:12])[0]
        k_pages = (k_sz + RIVA_PAGE_SIZE - 1) // RIVA_PAGE_SIZE
        kernel_bytes = f.read(k_pages * RIVA_PAGE_SIZE)[:k_sz]

    stage_dir = out_dir / "mrm_clean_stage"
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    unpacked_rd = out_dir / "unpacked_donor" / "ramdisk.cpio.gz"
    gunzip_proc = subprocess.Popen(["gzip", "-dc", str(unpacked_rd)], stdout=subprocess.PIPE)
    subprocess.run(["cpio", "-id", "--quiet"], cwd=stage_dir, stdin=gunzip_proc.stdout, check=True)
    gunzip_proc.wait()

    # 1. Copiar imagen de fondo en twres/images/Default/FullscreenIcons/mrm_screen.png
    mrm_img_target = stage_dir / "twres" / "images" / "Default" / "FullscreenIcons" / "mrm_screen.png"
    shutil.copy2(splash_1080, mrm_img_target)

    # 2. Registrar el recurso de imagen en twres/resources/images.xml
    img_xml = stage_dir / "twres" / "resources" / "images.xml"
    content_img_xml = img_xml.read_text(encoding="utf-8")
    if "mrm_fullscreen_img" not in content_img_xml:
        needle = "<resources>"
        inject = '<resources>\n\t\t<image name="mrm_fullscreen_img" filename="Default/FullscreenIcons/mrm_screen" retainaspect="1"/>'
        content_img_xml = content_img_xml.replace(needle, inject, 1)
        img_xml.write_text(content_img_xml, encoding="utf-8")

    # 3. Reemplazar twres/pages/main.xml para que muestre la imagen y redirija cualquier intento de navegación a MRM
    mrm_page_xml = (
        '<?xml version="1.0"?>\n'
        '<recovery>\n'
        '    <pages>\n'
        '        <page name="main">\n'
        '            <background color="#000000"/>\n'
        '            <action>\n'
        '                <action function="set">tw_screen_timeout_secs=0</action>\n'
        '                <action function="set">tw_brightness_pct=100</action>\n'
        '                <action function="set">tw_no_screen_timeout=1</action>\n'
        '            </action>\n'
        '            <image>\n'
        '                <image resource="mrm_fullscreen_img"/>\n'
        '                <placement x="0" y="0" placement="1"/>\n'
        '            </image>\n'
        '        </page>\n'
        '        <page name="navbar">\n'
        '            <action><action function="page">main</action></action>\n'
        '        </page>\n'
        '        <page name="filemanagerlist">\n'
        '            <action><action function="page">main</action></action>\n'
        '        </page>\n'
        '        <page name="welcome">\n'
        '            <action><action function="page">main</action></action>\n'
        '        </page>\n'
        '    </pages>\n'
        '</recovery>\n'
    )
    (stage_dir / "twres" / "pages" / "main.xml").write_text(mrm_page_xml, encoding="utf-8")

    # 4. Asegurar que el splash también use la imagen de Stitch
    splash_bg = stage_dir / "twres" / "images" / "Splash" / "original.png"
    shutil.copy2(splash_1080, splash_bg)
    empty_png = stage_dir / "twres" / "images" / "Splash" / "empty.png"
    for logo in ("logo_w.png", "logo_o.png", "logo_d.png"):
        shutil.copy2(empty_png, stage_dir / "twres" / "images" / "Splash" / logo)

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

    # 5. Modificar foxstart.sh para forzar brillo alto al arrancar y no sobrescribir la UI
    foxstart_sh = stage_dir / "sbin" / "foxstart.sh"
    fox_code = (
        "#!/sbin/sh\n"
        "for p in /sys/class/leds/lcd-backlight/brightness /sys/class/backlight/*/brightness; do\n"
        "    [ -e \"$p\" ] && echo 255 > \"$p\"\n"
        "done\n"
        "echo '[CS MRM] Brightness initialized' > /dev/kmsg\n"
        "exit 0\n"
    )
    foxstart_sh.write_text(fox_code, encoding="utf-8")
    os.chmod(foxstart_sh, 0o755)

    # Inyectar particiones protegidas
    (stage_dir / "ns").mkdir(parents=True, exist_ok=True)
    (stage_dir / "ps").mkdir(parents=True, exist_ok=True)

    # Reempaquetar
    out_rd_gz = out_dir / "mrm_clean_ramdisk.cpio.gz"
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

    print(f"✔ Recovery MRM con brillo activo generado: {out_img} ({out_img.stat().st_size} bytes)")
    return out_img


if __name__ == "__main__":
    build_clean_mrm_recovery()
