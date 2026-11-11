#!/usr/bin/env python3
"""
Coki Studios — Hybrid MRM Recovery Builder for Redmi 5A (riva)
Uses the donor's native ARM64 init, drivers, and Qualcomm services,
overlaying CS MRM UI (Stitch screens) and MRM protocol daemon.
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
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_OUT_DIR = REPO_ROOT / "build" / "riva_firmware"
RIVA_PAGE_SIZE = 4096


def build_hybrid_recovery(out_dir: Path = DEFAULT_OUT_DIR) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR11.0_N2" / "recovery.img"
    if not donor_path.is_file():
        donor_path = Path.home() / "Downloads" / "OrangeFox-riva-stableR10.1_O1" / "recovery.img"
    if not donor_path.is_file():
        raise FileNotFoundError("No se encontró el recovery de OrangeFox de riva en Downloads.")

    # 1. Leer cabecera exacta de 4096 bytes del donor
    with donor_path.open("rb") as f:
        donor_hdr = bytearray(f.read(RIVA_PAGE_SIZE))
        k_sz = struct.unpack("<I", donor_hdr[8:12])[0]
        k_pages = (k_sz + RIVA_PAGE_SIZE - 1) // RIVA_PAGE_SIZE
        kernel_bytes = f.read(k_pages * RIVA_PAGE_SIZE)[:k_sz]

    # 2. Descomprimir ramdisk completo del donor en carpeta de trabajo
    stage_dir = out_dir / "hybrid_stage"
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True, exist_ok=True)

    unpacked_rd = out_dir / "unpacked_donor" / "ramdisk.cpio.gz"
    if not unpacked_rd.exists():
        raise FileNotFoundError(f"Falta {unpacked_rd}")

    # Extraer usando cpio nativo conservando symlinks y permisos
    gunzip_proc = subprocess.Popen(["gzip", "-dc", str(unpacked_rd)], stdout=subprocess.PIPE)
    subprocess.run(["cpio", "-id", "--quiet"], cwd=stage_dir, stdin=gunzip_proc.stdout, check=True)
    gunzip_proc.wait()

    # 3. Inyectar carpetas de almacenamiento protegido y pantallas de Stitch
    (stage_dir / "ns").mkdir(parents=True, exist_ok=True)
    (stage_dir / "ps").mkdir(parents=True, exist_ok=True)
    (stage_dir / "res" / "mrm").mkdir(parents=True, exist_ok=True)

    screens_src = Path.home() / ".gemini/antigravity/brain/2aa04867-d798-4e5b-b203-1c5ada0e3bb2/scratch/stitch_mrm/live_screens"
    if screens_src.exists():
        for scr in screens_src.glob("*.png"):
            shutil.copy2(scr, stage_dir / "res" / "mrm" / scr.name)

    # 4. Modificar init.rc o init.recovery.service.rc para activar banner MRM
    mrm_banner_sh = (
        "#!/sbin/sh\n"
        "echo '====================================' > /dev/kmsg\n"
        "echo ' [CS] MRM (Multi Recovery Mode) Riva' > /dev/kmsg\n"
        "echo ' [CS] hi!UI Engine v1.1 Active'       > /dev/kmsg\n"
        "echo '====================================' > /dev/kmsg\n"
        "setprop ro.cs.mrm.state uic_idle\n"
    )
    mrm_sh_path = stage_dir / "sbin" / "mrm_banner.sh"
    mrm_sh_path.write_text(mrm_banner_sh, encoding="utf-8")
    os.chmod(mrm_sh_path, 0o755)

    svc_rc = stage_dir / "init.recovery.service.rc"
    if svc_rc.exists():
        extra_rc = "\nservice cs_mrm /sbin/mrm_banner.sh\n    oneshot\n    seclabel u:r:recovery:s0\n"
        svc_rc.write_text(svc_rc.read_text(encoding="utf-8") + extra_rc, encoding="utf-8")

    # 5. Reempaquetar ramdisk a cpio.gz
    out_rd_gz = out_dir / "hybrid_ramdisk.cpio.gz"
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

    # 6. Actualizar tamaño y SHA en la cabecera original
    struct.pack_into("<I", donor_hdr, 16, r_sz)
    sha = hashlib.sha1(kernel_bytes + ramdisk_bytes).digest()
    donor_hdr[64 + 512 : 64 + 512 + len(sha)] = sha

    def _pad(data: bytes, ps: int) -> bytes:
        rem = len(data) % ps
        return data if rem == 0 else data + (b"\x00" * (ps - rem))

    # 7. Escribir imagen final completa
    out_img = out_dir / "cs_mrm_recovery_riva.img"
    with out_img.open("wb") as f:
        f.write(donor_hdr)
        f.write(_pad(kernel_bytes, RIVA_PAGE_SIZE))
        f.write(_pad(ramdisk_bytes, RIVA_PAGE_SIZE))

    print(f"✔ Hybrid MRM Recovery generado: {out_img} ({out_img.stat().st_size} bytes)")
    return out_img


if __name__ == "__main__":
    build_hybrid_recovery()

