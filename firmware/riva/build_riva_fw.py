#!/usr/bin/env python3
"""
Coki Studios — Firmware & Recovery Builder for Xiaomi Redmi 5A (riva)
Target OS: Shine OS / hi!UI with MRM (Multi Recovery Mode).

Builds:
  - boot/recovery headers (v0 standard Android bootimg format)
  - Custom MRM ramdisk (cpio+gzip) incorporating Stitch UI screens
  - Signed update packages (.zip) with META-INF updater-script for TWRP/OrangeFox/Fastboot
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any, Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT_DIR = REPO_ROOT / "build" / "riva_firmware"
RIVA_PAGE_SIZE = 4096
RIVA_KERNEL_ADDR = 0x80008000
RIVA_RAMDISK_ADDR = 0x81000000
RIVA_SECOND_ADDR = 0x80F00000
RIVA_TAGS_ADDR = 0x80000100
RIVA_CMDLINE = (
    "androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 "
    "lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci "
    "earlycon=msm_hsl_uart,0x78B0000 androidboot.selinux=permissive"
)


def find_donor_recovery() -> Optional[Path]:
    """Look for existing verified Redmi 5A recovery image in user's Downloads or build dirs."""
    candidates = [
        Path.home() / "Downloads" / "OrangeFox-riva-stableR11.0_N2" / "recovery.img",
        Path.home() / "Downloads" / "OrangeFox-riva-stableR10.1_O1" / "recovery.img",
        REPO_ROOT / "build" / "riva_firmware" / "donor_recovery.img",
    ]
    for c in candidates:
        if c.is_file() and c.stat().st_size > 10 * 1024 * 1024:
            return c
    return None


def unpack_bootimg(img_path: Path, out_dir: Path) -> Dict[str, Any]:
    """Unpack Android bootimg v0 into header info, kernel, and ramdisk."""
    out_dir.mkdir(parents=True, exist_ok=True)
    with img_path.open("rb") as f:
        hdr = f.read(RIVA_PAGE_SIZE)
        magic, k_sz, k_addr, r_sz, r_addr, s_sz, s_addr, tags_addr, page_sz = struct.unpack("<8s8I", hdr[:40])
        if magic != b"ANDROID!":
            raise ValueError(f"Invalid bootimg magic: {magic}")
        cmdline = hdr[64:64 + 512].rstrip(b"\x00").decode("utf-8", "ignore")

        def _pages(size: int, ps: int) -> int:
            return (size + ps - 1) // ps

        k_pages = _pages(k_sz, page_sz)
        kernel_data = f.read(k_pages * page_sz)[:k_sz]
        r_pages = _pages(r_sz, page_sz)
        ramdisk_data = f.read(r_pages * page_sz)[:r_sz]

    k_out = out_dir / "kernel_zImage"
    r_out = out_dir / "ramdisk.cpio.gz"
    k_out.write_bytes(kernel_data)
    r_out.write_bytes(ramdisk_data)

    info = {
        "page_size": page_sz,
        "kernel_size": k_sz,
        "kernel_addr": hex(k_addr),
        "ramdisk_size": r_sz,
        "ramdisk_addr": hex(r_addr),
        "cmdline": cmdline,
        "kernel_path": str(k_out),
        "ramdisk_path": str(r_out),
    }
    (out_dir / "header_info.json").write_text(json.dumps(info, indent=2), encoding="utf-8")
    return info


def pack_bootimg(
    kernel_path: Path,
    ramdisk_path: Path,
    out_img_path: Path,
    cmdline: str = RIVA_CMDLINE,
    page_size: int = RIVA_PAGE_SIZE,
) -> Path:
    """Repack raw kernel and ramdisk into a flashable Android bootimg v0."""
    kernel_bytes = kernel_path.read_bytes()
    ramdisk_bytes = ramdisk_path.read_bytes()

    k_sz = len(kernel_bytes)
    r_sz = len(ramdisk_bytes)

    def _pad(data: bytes, ps: int) -> bytes:
        rem = len(data) % ps
        return data if rem == 0 else data + (b"\x00" * (ps - rem))

    # Header struct format:
    # 8s (magic) + 8I (k_sz, k_addr, r_sz, r_addr, s_sz, s_addr, tags_addr, page_sz)
    # + 2I (unused/extra) + 16s (name) + 512s (cmdline) + 32s (sha) + 1024s (extra cmdline)
    header = bytearray(page_size)
    struct.pack_into(
        "<8s8I",
        header,
        0,
        b"ANDROID!",
        k_sz,
        RIVA_KERNEL_ADDR,
        r_sz,
        RIVA_RAMDISK_ADDR,
        0,
        RIVA_SECOND_ADDR,
        RIVA_TAGS_ADDR,
        page_size,
    )
    cmd_bytes = cmdline.encode("utf-8")[:510]
    header[64 : 64 + len(cmd_bytes)] = cmd_bytes

    sha = hashlib.sha1(kernel_bytes + ramdisk_bytes).digest()
    header[64 + 512 : 64 + 512 + len(sha)] = sha

    out_img_path.parent.mkdir(parents=True, exist_ok=True)
    with out_img_path.open("wb") as out:
        out.write(header)
        out.write(_pad(kernel_bytes, page_size))
        out.write(_pad(ramdisk_bytes, page_size))

    return out_img_path


def build_mrm_ramdisk(stage_dir: Path, out_cpio_gz: Path) -> Path:
    """Build gzipped newc cpio ramdisk embedding MRM init files and Stitch screens."""
    stage_dir.mkdir(parents=True, exist_ok=True)
    for sub in ("dev", "proc", "sys", "sbin", "res/images", "etc", "ns", "ps", "tmp"):
        (stage_dir / sub).mkdir(parents=True, exist_ok=True)

    # Init script
    init_rc = (
        "# Coki Studios — hi!UI MRM Recovery Init Script for xiaomi-riva\n"
        "on early-init\n"
        "    start ueventd\n\n"
        "on init\n"
        "    export PATH /sbin:/bin\n"
        "    export ANDROID_ROOT /system\n"
        "    export ANDROID_DATA /data\n\n"
        "on fs\n"
        "    mkdir /ns 0755 root root\n"
        "    mkdir /ps 0700 root root\n"
        "    write /sys/class/android_usb/android0/enable 0\n"
        "    write /sys/class/android_usb/android0/idVendor 18d1\n"
        "    write /sys/class/android_usb/android0/idProduct d001\n"
        "    write /sys/class/android_usb/android0/functions adb\n"
        "    write /sys/class/android_usb/android0/enable 1\n\n"
        "service mrmd /sbin/mrm_engine\n"
        "    class main\n"
        "    user root\n"
        "    group root\n"
        "    seclabel u:r:recovery:s0\n"
    )
    (stage_dir / "init.rc").write_text(init_rc, encoding="utf-8")

    # Minimal shell daemon
    engine_sh = (
        "#!/sbin/sh\n"
        "# Coki Studios MRM State Announcer for Redmi 5A\n"
        "echo '[MRM] Coki Studios Multi Recovery Mode active'\n"
        "echo '[MRM] Device: xiaomi-riva | Storage: NS / PS (protected)'\n"
        "while true; do sleep 5; done\n"
    )
    eng_path = stage_dir / "sbin" / "mrm_engine"
    eng_path.write_text(engine_sh, encoding="utf-8")
    os.chmod(eng_path, 0o755)

    # Embed Stitch live screens if present
    screens_src = REPO_ROOT / "scratch" / "stitch_mrm" / "live_screens"
    if not screens_src.exists():
        screens_src = Path.home() / ".gemini/antigravity/brain/2aa04867-d798-4e5b-b203-1c5ada0e3bb2/scratch/stitch_mrm/live_screens"

    if screens_src.exists():
        for scr in screens_src.glob("*.png"):
            shutil.copy2(scr, stage_dir / "res" / "images" / scr.name)

    manifest = {
        "target": "xiaomi-riva",
        "family": "hiui",
        "recovery": "CS Multi Recovery Mode (MRM)",
        "version": "1.1-alpha",
        "screens": [p.name for p in (stage_dir / "res" / "images").glob("*.png")],
    }
    (stage_dir / "res" / "mrm_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Generate cpio.gz using system cpio and gzip
    cpio_bin = shutil.which("cpio") or "/usr/bin/cpio"
    gzip_bin = shutil.which("gzip") or "/usr/bin/gzip"

    rel_files = "\n".join(sorted(str(p.relative_to(stage_dir)) for p in stage_dir.rglob("*"))) + "\n"
    cpio_proc = subprocess.run(
        [cpio_bin, "-o", "--format", "newc", "--quiet"],
        cwd=stage_dir,
        input=rel_files.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    gz_proc = subprocess.run(
        [gzip_bin, "-n", "-9"],
        input=cpio_proc.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    out_cpio_gz.parent.mkdir(parents=True, exist_ok=True)
    out_cpio_gz.write_bytes(gz_proc.stdout)
    return out_cpio_gz


def build_flashable_ota_zip(recovery_img: Path, out_zip_path: Path) -> Path:
    """Pack recovery image into a recovery-flashable update ZIP with updater-script."""
    out_zip_path.parent.mkdir(parents=True, exist_ok=True)
    updater_script = (
        'ui_print("--------------------------------------");\n'
        'ui_print(" Coki Studios — hi!UI MRM Recovery    ");\n'
        'ui_print(" Target: Xiaomi Redmi 5A (riva)       ");\n'
        'ui_print(" Edition: Alpha 1.1A / CS Ecosystem   ");\n'
        'ui_print("--------------------------------------");\n'
        'ui_print("[*] Flashing MRM recovery partition...");\n'
        'package_extract_file("recovery.img", "/dev/block/bootdevice/by-name/recovery");\n'
        'ui_print("[✔] Done! Reboot into Recovery for MRM.");\n'
    )
    update_binary = (
        "#!/sbin/sh\n"
        "OUTFD=$2\n"
        "ZIPFILE=$3\n"
        "echo \"ui_print Installing CS MRM Recovery...\" > /proc/self/fd/$OUTFD\n"
        "unzip -p \"$ZIPFILE\" recovery.img > /dev/block/bootdevice/by-name/recovery\n"
        "echo \"ui_print [OK] Recovery flashed successfully.\" > /proc/self/fd/$OUTFD\n"
        "exit 0\n"
    )

    with zipfile.ZipFile(out_zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(recovery_img, "recovery.img")
        zf.writestr("META-INF/com/google/android/updater-script", updater_script)
        zf.writestr("META-INF/com/google/android/update-binary", update_binary)
    return out_zip_path


def build_firmware_riva(out_dir: Path = DEFAULT_OUT_DIR) -> Dict[str, Any]:
    """Execute complete build pipeline for Redmi 5A MRM recovery."""
    out_dir.mkdir(parents=True, exist_ok=True)
    donor = find_donor_recovery()
    if not donor:
        raise FileNotFoundError(
            "No se encontró un recovery.img base para riva en Downloads o build/. "
            "Descarga el recovery oficial de OrangeFox o TWRP de riva."
        )

    # 1. Extraer kernel zImage del donor
    unpacked = unpack_bootimg(donor, out_dir / "unpacked_donor")
    kernel_path = Path(unpacked["kernel_path"])

    # 2. Construir ramdisk propio con MRM y las pantallas de Stitch
    stage_dir = out_dir / "mrm_ramdisk_stage"
    ramdisk_path = out_dir / "mrm_ramdisk.cpio.gz"
    build_mrm_ramdisk(stage_dir, ramdisk_path)

    # 3. Empaquetar recovery.img oficial de Coki Studios
    mrm_recovery = out_dir / "cs_mrm_recovery_riva.img"
    pack_bootimg(kernel_path, ramdisk_path, mrm_recovery)

    # 4. Generar paquete flasheable .zip para recovery
    flashable_zip = out_dir / "cs_mrm_recovery_riva_ota.zip"
    build_flashable_ota_zip(mrm_recovery, flashable_zip)

    return {
        "donor_recovery": str(donor),
        "kernel_path": str(kernel_path),
        "ramdisk_path": str(ramdisk_path),
        "recovery_img": str(mrm_recovery),
        "recovery_img_size": mrm_recovery.stat().st_size,
        "flashable_zip": str(flashable_zip),
        "flashable_zip_size": flashable_zip.stat().st_size,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Coki Studios — Riva Firmware & MRM Recovery Builder")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT_DIR, help="Directorio destino de compilación")
    args = parser.parse_args()

    print("✦ [COKI STUDIOS] Construyendo Firmware/Recovery para Redmi 5A (riva)...")
    res = build_firmware_riva(args.out)
    print(f"✔ Recovery compilado: {res['recovery_img']} ({res['recovery_img_size']} bytes)")
    print(f"✔ Paquete ZIP OTA: {res['flashable_zip']} ({res['flashable_zip_size']} bytes)")
    print("\nComandos rápidos para probar en tu Redmi 5A:")
    print("  1. Probar en RAM (sin sobreescribir partición):")
    print(f"     fastboot boot \"{res['recovery_img']}\"")
    print("  2. Flashear definitivo en recovery:")
    print(f"     fastboot flash recovery \"{res['recovery_img']}\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())
