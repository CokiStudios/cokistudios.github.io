#!/usr/bin/env python3
"""
Coki Studios — MRM (Multi Recovery Mode) & UIC Real Backend Engine.

Implements the real hardware-security model defined in SHINE_OS_HARDWARE_ARCHITECTURE:
- QLC Mem partitions: NS (Normal Storage) vs PS (Protected Storage).
- Phone states: NORMAL_SUI, MRM_DISCONNECT, MRM_UIC_IDLE, MRM_WORKING.
- Security gates ("Be careful"):
  1. mrm_protect enabled in Settings
  2. Trust PC HMAC-SHA256 challenge-response pairing
  3. SHA-256 + HMAC signed .c2pkg verification before touching PS
- Local Unix socket RPC bus for live Phone <-> PC UIC experimentation, real
  ADB/Fastboot hardware probing, and Redmi 5A (`riva`) recovery ramdisk packing.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import io
import json
import os
import secrets
import shutil
import socket
import socketserver
import subprocess
import sys
import threading
import time
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SANDBOX_DIR = REPO_ROOT / "build" / "mrm_sandbox"
DEFAULT_C2_SOURCE = REPO_ROOT / "c2-modules" / "feather_lite_hiui.c2"

STATE_NORMAL_SUI = "NORMAL_SUI"
STATE_DISCONNECT = "MRM_DISCONNECT"
STATE_UIC_IDLE = "MRM_UIC_IDLE"
STATE_WORKING = "MRM_WORKING"

VALID_MRM_STATES = (STATE_DISCONNECT, STATE_UIC_IDLE, STATE_WORKING)
OS_SLOTS = ("ShineOS-hiUI (Primary)", "Recovery-Lab (Experimental)")


class MRMError(RuntimeError):
    """Structured protocol or security gate failure from MRM / PS."""

    def __init__(self, code: str, message: str):
        super().__init__(f"{code}: {message}")
        self.code = code
        self.message = message


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _canonical_json(obj: Any) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def _atomic_write_json(path: Path, obj: Any) -> None:
    raw = (json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode("utf-8")
    _atomic_write_bytes(path, raw)


def _read_json(path: Path, default: Any = None) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def find_platform_tool(name: str) -> Optional[str]:
    """Locate adb or fastboot across PATH, Homebrew, and configured Android SDKs."""
    found = shutil.which(name)
    if found:
        return found
    candidates = [
        Path("/opt/homebrew/bin") / name,
        Path("/usr/local/bin") / name,
        Path("/Volumes/Support HD/Android/sdk/platform-tools") / name,
        Path.home() / "Library/Android/sdk/platform-tools" / name,
    ]
    for cand in candidates:
        if cand.is_file() and os.access(cand, os.X_OK):
            return str(cand)
    return None


def probe_real_hardware() -> Dict[str, Any]:
    """Query connected physical Android devices over real ADB and Fastboot."""
    adb_bin = find_platform_tool("adb")
    fastboot_bin = find_platform_tool("fastboot")
    adb_devices: List[Dict[str, str]] = []
    fastboot_devices: List[Dict[str, str]] = []
    errors: List[str] = []

    if adb_bin:
        try:
            res = subprocess.run(
                [adb_bin, "devices", "-l"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=4,
            )
            if res.returncode == 0:
                for line in res.stdout.splitlines()[1:]:
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        adb_devices.append({
                            "serial": parts[0],
                            "mode": parts[1],
                            "detail": " ".join(parts[2:]),
                        })
            elif res.stderr.strip():
                errors.append(res.stderr.strip())
        except Exception as exc:
            errors.append(f"adb: {exc}")

    if fastboot_bin:
        try:
            res = subprocess.run(
                [fastboot_bin, "devices"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=4,
            )
            if res.returncode == 0:
                for line in res.stdout.splitlines():
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        fastboot_devices.append({"serial": parts[0], "mode": parts[1]})
            elif res.stderr.strip():
                errors.append(res.stderr.strip())
        except Exception as exc:
            errors.append(f"fastboot: {exc}")

    return {
        "adb_path": adb_bin,
        "fastboot_path": fastboot_bin,
        "adb_devices": adb_devices,
        "fastboot_devices": fastboot_devices,
        "errors": errors,
    }


@dataclass
class UICHostIdentity:
    """Persistent PC host keypair identity used for Trust PC and .c2 signing."""

    pc_id: str
    secret_hex: str

    @property
    def fingerprint(self) -> str:
        return _sha256_bytes(bytes.fromhex(self.secret_hex))[:16]

    def sign_bytes(self, data: bytes) -> str:
        return hmac.new(bytes.fromhex(self.secret_hex), data, hashlib.sha256).hexdigest()

    @classmethod
    def load_or_create(cls, host_dir: Path) -> "UICHostIdentity":
        key_file = host_dir / "identity.json"
        existing = _read_json(key_file)
        if existing and "pc_id" in existing and "secret_hex" in existing:
            return cls(pc_id=existing["pc_id"], secret_hex=existing["secret_hex"])
        pc_id = f"UIC-{socket.gethostname().split('.')[0]}-{secrets.token_hex(2)}".lower()
        secret_hex = secrets.token_hex(32)
        ident = cls(pc_id=pc_id, secret_hex=secret_hex)
        _atomic_write_json(key_file, {"pc_id": ident.pc_id, "secret_hex": ident.secret_hex})
        return ident


def transfork_bowl_to_c2(bowl_data: Dict[str, Any]) -> str:
    """Convert a declarative Rice .bowl JSON definition into a .c2 component."""
    name = bowl_data.get("component", "HiUIBowlWidget")
    target = bowl_data.get("target", "hiui")
    primary = bowl_data.get("primary", "#06b6d4")
    accent = bowl_data.get("accent", "#164e63")
    title = bowl_data.get("title", "hi!UI Rice Bowl")
    pill = bowl_data.get("status_pill", "● HI!UI • TRANSFORKED FROM RICE")
    dock = json.dumps(bowl_data.get("dock", ["phone", "messages", "settings"]))
    return (
        f'# Transforked by UIC.transfork (Rice Bowl -> .c2)\n'
        f'component "{name}" target "{target}" {{\n'
        f'    family: "{target}"\n'
        f'    fps: {int(bowl_data.get("fps", 60))}\n'
        f'    primary: "{primary}"\n'
        f'    accent: "{accent}"\n'
        f'    background: "#080d12"\n'
        f'    draw status_pill at (center, top) with text "{pill}" and glow false\n'
        f'    draw card at (20, 80) with title "{title}":\n'
        f'        text "Compilado desde Rice Bowl para Redmi 5A (riva)"\n'
        f'    draw dock at bottom with apps {dock}\n'
        f'    fn on_mount() {{\n'
        f'        print "[C2 {target.upper()}] {name} montado en PS"\n'
        f'    }}\n'
        f'}}\n'
    )


def sign_c2_package(source_path: Path, out_pkg_path: Path, identity: UICHostIdentity) -> Dict[str, Any]:
    """Bundle and cryptographically sign a .c2 (or .bowl) into a .c2pkg ZIP."""
    raw_text = source_path.read_text(encoding="utf-8")
    source_type = "bowl" if source_path.suffix == ".bowl" else "c2"
    if source_type == "bowl":
        c2_text = transfork_bowl_to_c2(json.loads(raw_text))
        c2_name = source_path.with_suffix(".c2").name
    else:
        c2_text = raw_text
        c2_name = source_path.name

    payload_bytes = c2_text.encode("utf-8")
    manifest = {
        "format": "cs.c2pkg.v1",
        "filename": c2_name,
        "source_type": source_type,
        "payload_sha256": _sha256_bytes(payload_bytes),
        "payload_size": len(payload_bytes),
        "signer_pc_id": identity.pc_id,
        "signer_fingerprint": identity.fingerprint,
        "signed_at": int(time.time()),
    }
    signature_hex = identity.sign_bytes(_canonical_json(manifest))

    out_pkg_path.parent.mkdir(parents=True, exist_ok=True)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("payload.c2", payload_bytes)
        zf.writestr("manifest.json", json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        zf.writestr("signature.hmac", signature_hex + "\n")
    _atomic_write_bytes(out_pkg_path, buf.getvalue())
    return {"package": str(out_pkg_path), "manifest": manifest, "signature": signature_hex}


def verify_c2_package_bytes(pkg_bytes: bytes, trusted_pcs: Dict[str, Dict[str, str]]) -> Tuple[Dict[str, Any], bytes]:
    """Verify .c2pkg ZIP integrity, SHA-256 payload digest, and Trust PC HMAC signature."""
    try:
        zf = zipfile.ZipFile(io.BytesIO(pkg_bytes), "r")
    except zipfile.BadZipFile as exc:
        raise MRMError("ERR_CORRUPT_PACKAGE", f"Invalid .c2pkg archive: {exc}") from exc

    with zf:
        names = set(zf.namelist())
        if not {"payload.c2", "manifest.json", "signature.hmac"}.issubset(names):
            raise MRMError("ERR_CORRUPT_PACKAGE", "Missing payload.c2, manifest.json, or signature.hmac")
        payload_bytes = zf.read("payload.c2")
        manifest = json.loads(zf.read("manifest.json").decode("utf-8"))
        sig_hex = zf.read("signature.hmac").decode("utf-8").strip()

    actual_sha = _sha256_bytes(payload_bytes)
    if actual_sha != manifest.get("payload_sha256"):
        raise MRMError(
            "ERR_PAYLOAD_TAMPERED",
            f"SHA-256 mismatch: expected {manifest.get('payload_sha256', '')[:12]}..., got {actual_sha[:12]}...",
        )

    signer_id = manifest.get("signer_pc_id", "")
    trusted = trusted_pcs.get(signer_id)
    if not trusted:
        raise MRMError("ERR_UNTRUSTED_SIGNER", f"Signer '{signer_id}' is not in PS/nec_pair trusted PCs")

    expected_sig = hmac.new(
        bytes.fromhex(trusted["secret_hex"]),
        _canonical_json(manifest),
        hashlib.sha256,
    ).hexdigest()
    if not hmac.compare_digest(sig_hex, expected_sig):
        raise MRMError("ERR_INVALID_C2_SIGNATURE", "HMAC signature mismatch inside .c2pkg")

    return manifest, payload_bytes


class QLCSandbox:
    """
    On-disk simulation of CS NAND (QLC Mem) with real NS/PS separation.

    PS (Protected Storage) enforces hardware-equivalent security gates: writes
    are rejected unless the device is in MRM_UIC_IDLE, mrm_protect is enabled,
    and an authenticated UIC session is active.
    """

    def __init__(self, root: Path = DEFAULT_SANDBOX_DIR):
        self.root = Path(root)
        self.ns_dir = self.root / "nand" / "NS"
        self.ps_dir = self.root / "nand" / "PS"
        self.snapshot_dir = self.root / "factory_snapshot" / "sui_system"
        self.host_dir = self.root / "uic_host"
        self.state_path = self.root / "device_state.json"
        self.audit_log_path = self.root / "mrm_audit.log"
        self._lock = threading.RLock()
        self.initialize()

    def initialize(self) -> None:
        with self._lock:
            (self.ns_dir / "userdata").mkdir(parents=True, exist_ok=True)
            for sub in ("sui_system", "rice_layer", "c2_layer", "nec_pair"):
                (self.ps_dir / sub).mkdir(parents=True, exist_ok=True)
            self.snapshot_dir.mkdir(parents=True, exist_ok=True)

            notes = self.ns_dir / "userdata" / "notes.txt"
            if not notes.exists():
                _atomic_write_bytes(notes, "Mis notas en NS (Normal Storage) — sobreviven Restore SUI.\n".encode("utf-8"))

            bowl = self.ps_dir / "rice_layer" / "hiui_core.bowl"
            if not bowl.exists():
                _atomic_write_json(bowl, {
                    "component": "HiUIRiceCore",
                    "target": "hiui",
                    "title": "hi!UI Minimal Shell",
                    "primary": "#06b6d4",
                    "accent": "#164e63",
                    "fps": 60,
                    "dock": ["phone", "messages", "settings"],
                })

            self._ensure_baseline_sui()

            if not (self.ps_dir / "nec_pair" / "trusted_pcs.json").exists():
                _atomic_write_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})

            if not (self.ps_dir / "os_slot.json").exists():
                _atomic_write_json(self.ps_dir / "os_slot.json", {
                    "active_os": OS_SLOTS[0],
                    "device_target": "xiaomi-riva (Redmi 5A)",
                    "mrm_version": "1.1",
                })

            if not self.state_path.exists():
                _atomic_write_json(self.state_path, {
                    "phone_mode": STATE_DISCONNECT,
                    "mrm_protect": True,
                    "active_session_token": None,
                    "active_pc_id": None,
                    "last_action": "Booted directly into MRM Lab (Disconnect)",
                })

    def _baseline_sui_files(self) -> Dict[str, bytes]:
        build_prop = (
            "ro.cs.os=ShineOS\n"
            "ro.cs.ui=hi!UI\n"
            "ro.cs.device=riva\n"
            "ro.cs.nand.ps=protected\n"
            "ro.cs.mrm.version=1.1\n"
        ).encode("utf-8")
        hiui_shell = json.dumps({
            "shell": "hi!UI",
            "version": "1.0-alpha",
            "target_device": "Redmi 5A (riva)",
            "renderer": "Skia/SurfaceFlinger Lite",
            "fps_target": 60,
        }, indent=2).encode("utf-8")
        checksums = {
            "build.prop": _sha256_bytes(build_prop),
            "hiui_shell.json": _sha256_bytes(hiui_shell),
        }
        manifest = json.dumps({"files": checksums}, indent=2, sort_keys=True).encode("utf-8")
        return {
            "build.prop": build_prop,
            "hiui_shell.json": hiui_shell,
            "manifest.json": manifest,
        }

    def _ensure_baseline_sui(self) -> None:
        baseline = self._baseline_sui_files()
        for rel, data in baseline.items():
            snap_file = self.snapshot_dir / rel
            if not snap_file.exists():
                _atomic_write_bytes(snap_file, data)
            ps_file = self.ps_dir / "sui_system" / rel
            if not ps_file.exists():
                _atomic_write_bytes(ps_file, data)

    def _append_audit(self, event: str) -> None:
        ts = time.strftime("%H:%M:%S")
        with self.audit_log_path.open("a", encoding="utf-8") as fh:
            fh.write(f"[{ts}] {event}\n")

    def get_state(self) -> Dict[str, Any]:
        with self._lock:
            state = _read_json(self.state_path, {})
            trusted = _read_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})
            os_slot = _read_json(self.ps_dir / "os_slot.json", {})
            c2_files = sorted(p.name for p in (self.ps_dir / "c2_layer").glob("*.c2"))
            sui_health = self.check_sui_integrity()
            return {
                **state,
                "trusted_pc_ids": sorted(trusted.keys()),
                "active_os": os_slot.get("active_os", OS_SLOTS[0]),
                "installed_c2": c2_files,
                "sui_health": sui_health,
            }

    def _save_state(self, state: Dict[str, Any]) -> None:
        _atomic_write_json(self.state_path, state)

    def set_phone_mode(self, mode: str, reason: str = "") -> Dict[str, Any]:
        with self._lock:
            state = _read_json(self.state_path)
            state["phone_mode"] = mode
            if mode in (STATE_NORMAL_SUI, STATE_DISCONNECT):
                state["active_session_token"] = None
                state["active_pc_id"] = None
            if reason:
                state["last_action"] = reason
            self._save_state(state)
            self._append_audit(f"MODE -> {mode} ({reason})")
            return self.get_state()

    def set_mrm_protect(self, enabled: bool) -> Dict[str, Any]:
        with self._lock:
            state = _read_json(self.state_path)
            state["mrm_protect"] = bool(enabled)
            state["last_action"] = f"Settings: MRM Protect {'ON' if enabled else 'OFF'}"
            self._save_state(state)
            self._append_audit(state["last_action"])
            return self.get_state()

    def authorize_trust_pc(self, identity: UICHostIdentity) -> Dict[str, Any]:
        with self._lock:
            trusted = _read_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})
            trusted[identity.pc_id] = {
                "fingerprint": identity.fingerprint,
                "secret_hex": identity.secret_hex,
                "added_at": int(time.time()),
            }
            _atomic_write_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", trusted)
            state = _read_json(self.state_path)
            state["last_action"] = f"Settings: Trusted PC '{identity.pc_id}'"
            self._save_state(state)
            self._append_audit(state["last_action"])
            return self.get_state()

    def revoke_trust_pc(self, pc_id: str) -> Dict[str, Any]:
        with self._lock:
            trusted = _read_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})
            trusted.pop(pc_id, None)
            _atomic_write_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", trusted)
            state = _read_json(self.state_path)
            if state.get("active_pc_id") == pc_id:
                state["active_session_token"] = None
                state["active_pc_id"] = None
                if state["phone_mode"] in (STATE_UIC_IDLE, STATE_WORKING):
                    state["phone_mode"] = STATE_DISCONNECT
            state["last_action"] = f"Settings: Revoked Trust PC '{pc_id}'"
            self._save_state(state)
            self._append_audit(state["last_action"])
            return self.get_state()

    def write_ns_note(self, filename: str, content: str) -> Path:
        """NS (Normal Storage) is always writable even outside MRM."""
        safe_name = Path(filename).name
        target = self.ns_dir / "userdata" / safe_name
        _atomic_write_bytes(target, content.encode("utf-8"))
        self._append_audit(f"NS write: userdata/{safe_name}")
        return target

    def attempt_direct_ps_write(self, rel_path: str, content: str) -> None:
        """Demonstrate PS hardware lock: direct writes outside authenticated MRM fail."""
        with self._lock:
            state = _read_json(self.state_path)
            mode = state["phone_mode"]
            if mode == STATE_NORMAL_SUI:
                self._append_audit(f"BLOCKED direct PS write ({rel_path}) in NORMAL_SUI")
                raise MRMError(
                    "PS_LOCKED_NORMAL_SUI",
                    "Protected Storage (PS) está bloqueado en Normal SUI. Entra en MRM (Vol+ + Vol- + Power).",
                )
            if mode == STATE_DISCONNECT or not state.get("active_session_token"):
                self._append_audit(f"BLOCKED direct PS write ({rel_path}) without UIC link")
                raise MRMError(
                    "PS_LOCKED_DISCONNECT",
                    "PS requiere conexión USB autenticada con UIC (estado Uic idle).",
                )
            raise MRMError(
                "PS_RAW_WRITE_DENIED",
                "PS solo acepta operaciones firmadas vía protocolo UIC (Inject .c2 / Repair / Restore).",
            )

    def _require_ps_unlocked(self, session_token: Optional[str]) -> Dict[str, Any]:
        state = _read_json(self.state_path)
        mode = state["phone_mode"]
        if mode == STATE_NORMAL_SUI:
            raise MRMError("PS_LOCKED_NORMAL_SUI", "El dispositivo está en Normal SUI. Reinicia a MRM primero.")
        if mode == STATE_DISCONNECT or not state.get("active_session_token"):
            raise MRMError("PS_LOCKED_DISCONNECT", "Cable desconectado o PC no autenticado (Uic idle requerido).")
        if mode == STATE_WORKING:
            raise MRMError("ERR_DEVICE_BUSY", "MRM ya está ejecutando una escritura en PS (Working).")
        if not hmac.compare_digest(str(session_token or ""), str(state.get("active_session_token") or "")):
            raise MRMError("ERR_INVALID_SESSION", "Token de sesión UIC inválido.")
        if not state.get("mrm_protect", False):
            raise MRMError(
                "ERR_MRM_PROTECT_DISABLED",
                "Gate 'Be careful': activa 'Enable MRM Protect on Settings' antes de escribir en PS.",
            )
        return state

    def verify_hmac_handshake(self, pc_id: str, nonce_hex: str, response_hex: str) -> str:
        with self._lock:
            state = _read_json(self.state_path)
            if state["phone_mode"] == STATE_NORMAL_SUI:
                raise MRMError("ERR_NOT_IN_MRM", "El teléfono no está en modo MRM.")
            trusted = _read_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})
            entry = trusted.get(pc_id)
            if not entry:
                self._append_audit(f"HANDSHAKE DENIED for untrusted PC '{pc_id}'")
                raise MRMError("ERR_PC_NOT_TRUSTED", f"PC '{pc_id}' no tiene 'Trust PC' activo en Settings.")
            expected = hmac.new(bytes.fromhex(entry["secret_hex"]), nonce_hex.encode("ascii"), hashlib.sha256).hexdigest()
            if not hmac.compare_digest(expected, response_hex):
                raise MRMError("ERR_HANDSHAKE_FAILED", "Challenge-response HMAC incorrecto.")

            token = secrets.token_hex(16)
            state["phone_mode"] = STATE_UIC_IDLE
            state["active_session_token"] = token
            state["active_pc_id"] = pc_id
            state["last_action"] = f"UIC authenticated ({pc_id}) -> Uic idle"
            self._save_state(state)
            self._append_audit(state["last_action"])
            return token

    def _run_in_working_state(
        self,
        session_token: Optional[str],
        label: str,
        step_delay: float,
        work_fn: Callable[[], Dict[str, Any]],
    ) -> Dict[str, Any]:
        with self._lock:
            state = self._require_ps_unlocked(session_token)
            state["phone_mode"] = STATE_WORKING
            state["last_action"] = label
            self._save_state(state)
            self._append_audit(f"WORKING: {label}")

        try:
            if step_delay > 0:
                time.sleep(step_delay)
            result = work_fn()
        except Exception:
            with self._lock:
                st = _read_json(self.state_path)
                st["phone_mode"] = STATE_UIC_IDLE if st.get("active_session_token") else STATE_DISCONNECT
                st["last_action"] = f"Aborted -> {st['phone_mode']}"
                self._save_state(st)
            raise

        with self._lock:
            st = _read_json(self.state_path)
            st["phone_mode"] = STATE_UIC_IDLE
            st["last_action"] = f"OK: {label}"
            self._save_state(st)
            self._append_audit(st["last_action"])
        return result

    def check_sui_integrity(self) -> Dict[str, Any]:
        baseline_manifest = _read_json(self.snapshot_dir / "manifest.json", {"files": {}})
        expected_hashes: Dict[str, str] = baseline_manifest.get("files", {})
        corrupted: List[str] = []
        missing: List[str] = []
        for rel, exp_hash in expected_hashes.items():
            target = self.ps_dir / "sui_system" / rel
            if not target.exists():
                missing.append(rel)
            elif _sha256_bytes(target.read_bytes()) != exp_hash:
                corrupted.append(rel)
        return {
            "healthy": not corrupted and not missing,
            "corrupted": corrupted,
            "missing": missing,
        }

    def corrupt_sui_for_test(self) -> None:
        """Intentionally corrupt PS/sui_system/hiui_shell.json so user can test Repair SUI."""
        with self._lock:
            target = self.ps_dir / "sui_system" / "hiui_shell.json"
            _atomic_write_bytes(target, b'{"corrupted": true, "boot": "KERNEL_PANIC_TEST"}\n')
            self._append_audit("EXPERIMENT: Simulated corruption in PS/sui_system/hiui_shell.json")

    def repair_sui(self, session_token: Optional[str], step_delay: float = 0.0) -> Dict[str, Any]:
        def _do() -> Dict[str, Any]:
            health_before = self.check_sui_integrity()
            repaired: List[str] = []
            for rel in [*health_before["missing"], *health_before["corrupted"], "manifest.json"]:
                src = self.snapshot_dir / rel
                dst = self.ps_dir / "sui_system" / rel
                if src.exists():
                    _atomic_write_bytes(dst, src.read_bytes())
                    if rel != "manifest.json":
                        repaired.append(rel)
            return {"repaired_files": sorted(set(repaired)), "sui_health": self.check_sui_integrity()}

        return self._run_in_working_state(session_token, "Repair SUI on PS", step_delay, _do)

    def restore_sui(self, session_token: Optional[str], step_delay: float = 0.0) -> Dict[str, Any]:
        def _do() -> Dict[str, Any]:
            sui_dir = self.ps_dir / "sui_system"
            c2_dir = self.ps_dir / "c2_layer"
            for f in sui_dir.glob("*"):
                if f.is_file():
                    f.unlink()
            for f in self.snapshot_dir.glob("*"):
                if f.is_file():
                    _atomic_write_bytes(sui_dir / f.name, f.read_bytes())
            removed_c2: List[str] = []
            for f in c2_dir.glob("*"):
                if f.is_file():
                    removed_c2.append(f.name)
                    f.unlink()
            return {"removed_c2": removed_c2, "ns_preserved": True, "sui_health": self.check_sui_integrity()}

        return self._run_in_working_state(session_token, "Restore SUI (PS clean, NS kept)", step_delay, _do)

    def inject_signed_c2(self, session_token: Optional[str], pkg_bytes: bytes, step_delay: float = 0.0) -> Dict[str, Any]:
        def _do() -> Dict[str, Any]:
            trusted = _read_json(self.ps_dir / "nec_pair" / "trusted_pcs.json", {})
            manifest, payload_bytes = verify_c2_package_bytes(pkg_bytes, trusted)
            safe_name = Path(manifest["filename"]).name
            if not safe_name.endswith(".c2"):
                safe_name += ".c2"
            dst = self.ps_dir / "c2_layer" / safe_name
            _atomic_write_bytes(dst, payload_bytes)
            _atomic_write_json(self.ps_dir / "c2_layer" / f"{safe_name}.receipt.json", manifest)
            return {"installed_file": str(dst), "manifest": manifest}

        return self._run_in_working_state(session_token, "Inject signed .c2 on PS", step_delay, _do)

    def change_os_slot(self, session_token: Optional[str], slot_name: str, step_delay: float = 0.0) -> Dict[str, Any]:
        if slot_name not in OS_SLOTS:
            raise MRMError("ERR_UNKNOWN_OS_SLOT", f"Slot desconocido '{slot_name}'. Opciones: {OS_SLOTS}")

        def _do() -> Dict[str, Any]:
            data = _read_json(self.ps_dir / "os_slot.json", {})
            prev = data.get("active_os")
            data["active_os"] = slot_name
            data["switched_at"] = int(time.time())
            _atomic_write_json(self.ps_dir / "os_slot.json", data)
            return {"previous_os": prev, "active_os": slot_name}

        return self._run_in_working_state(session_token, f"Change OS -> {slot_name}", step_delay, _do)

    def read_audit_tail(self, limit: int = 25) -> List[str]:
        if not self.audit_log_path.exists():
            return []
        lines = self.audit_log_path.read_text(encoding="utf-8").splitlines()
        return lines[-limit:]


class _UnixProtocolHandler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        server: MRMDeviceServer = self.server  # type: ignore[assignment]
        while True:
            raw_line = self.rfile.readline()
            if not raw_line:
                break
            try:
                req = json.loads(raw_line.decode("utf-8"))
                resp = server.dispatch(req)
            except MRMError as exc:
                resp = {"ok": False, "code": exc.code, "error": exc.message, "state": server.sandbox.get_state()}
            except Exception as exc:
                resp = {"ok": False, "code": "ERR_INTERNAL", "error": str(exc), "state": server.sandbox.get_state()}
            self.wfile.write((json.dumps(resp) + "\n").encode("utf-8"))
            self.wfile.flush()


class MRMDeviceServer(socketserver.ThreadingUnixStreamServer):
    """Live local Unix-socket daemon representing the Phone in MRM."""

    daemon_threads = True

    def __init__(self, sandbox: QLCSandbox, sock_path: Optional[Path] = None, step_delay: float = 0.0):
        self.sandbox = sandbox
        self.sock_path = Path(sock_path) if sock_path else (sandbox.root / "mrm.sock")
        self.step_delay = step_delay
        self._nonces: Dict[str, str] = {}
        if self.sock_path.exists():
            self.sock_path.unlink()
        self.sock_path.parent.mkdir(parents=True, exist_ok=True)
        super().__init__(str(self.sock_path), _UnixProtocolHandler)

    def server_close(self) -> None:
        super().server_close()
        if self.sock_path.exists():
            try:
                self.sock_path.unlink()
            except OSError:
                pass

    def dispatch(self, req: Dict[str, Any]) -> Dict[str, Any]:
        op = req.get("op")
        if op == "PING":
            return {"ok": True, "state": self.sandbox.get_state()}
        if op == "HELLO_CHALLENGE":
            pc_id = str(req.get("pc_id", ""))
            nonce = secrets.token_hex(16)
            self._nonces[pc_id] = nonce
            return {"ok": True, "nonce": nonce, "state": self.sandbox.get_state()}
        if op == "AUTH_RESPONSE":
            pc_id = str(req.get("pc_id", ""))
            nonce = self._nonces.pop(pc_id, "")
            if not nonce:
                raise MRMError("ERR_NO_CHALLENGE", "Solicita HELLO_CHALLENGE primero.")
            token = self.sandbox.verify_hmac_handshake(pc_id, nonce, str(req.get("hmac", "")))
            return {"ok": True, "session_token": token, "state": self.sandbox.get_state()}
        if op == "DISCONNECT":
            st = self.sandbox.get_state()
            if st["phone_mode"] in (STATE_UIC_IDLE, STATE_WORKING):
                self.sandbox.set_phone_mode(STATE_DISCONNECT, "USB cable unplugged from UIC")
            return {"ok": True, "state": self.sandbox.get_state()}

        token = req.get("session_token")
        if op == "REPAIR_SUI":
            res = self.sandbox.repair_sui(token, step_delay=self.step_delay)
            return {"ok": True, "result": res, "state": self.sandbox.get_state()}
        if op == "RESTORE_SUI":
            res = self.sandbox.restore_sui(token, step_delay=self.step_delay)
            return {"ok": True, "result": res, "state": self.sandbox.get_state()}
        if op == "INJECT_C2":
            pkg_b64 = req.get("pkg_b64", "")
            pkg_bytes = base64.b64decode(pkg_b64.encode("ascii"))
            res = self.sandbox.inject_signed_c2(token, pkg_bytes, step_delay=self.step_delay)
            return {"ok": True, "result": res, "state": self.sandbox.get_state()}
        if op == "CHANGE_OS":
            res = self.sandbox.change_os_slot(token, str(req.get("slot", "")), step_delay=self.step_delay)
            return {"ok": True, "result": res, "state": self.sandbox.get_state()}

        raise MRMError("ERR_UNKNOWN_OP", f"Operación desconocida: {op}")


class UICClient:
    """PC-side UI Connect client communicating over the real MRM Unix socket."""

    def __init__(self, sock_path: Path, identity: UICHostIdentity):
        self.sock_path = Path(sock_path)
        self.identity = identity
        self.session_token: Optional[str] = None

    def _request(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        if not self.sock_path.exists():
            raise MRMError("ERR_NO_DEVICE_SOCKET", f"No hay demonio MRM escuchando en {self.sock_path}")
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(10.0)
            try:
                sock.connect(str(self.sock_path))
            except OSError as exc:
                raise MRMError("ERR_NO_DEVICE_SOCKET", f"Socket MRM no responde en {self.sock_path}: {exc}") from exc
            sock.sendall((json.dumps(payload) + "\n").encode("utf-8"))
            buf = bytearray()
            while True:
                chunk = sock.recv(65536)
                if not chunk:
                    break
                buf.extend(chunk)
                if b"\n" in chunk:
                    break
        resp = json.loads(buf.decode("utf-8").splitlines()[0])
        if not resp.get("ok"):
            raise MRMError(resp.get("code", "ERR_REMOTE"), resp.get("error", "Unknown MRM error"))
        return resp

    def ping(self) -> Dict[str, Any]:
        return self._request({"op": "PING"})

    def connect(self) -> Dict[str, Any]:
        chal = self._request({"op": "HELLO_CHALLENGE", "pc_id": self.identity.pc_id})
        sig = self.identity.sign_bytes(chal["nonce"].encode("ascii"))
        auth = self._request({"op": "AUTH_RESPONSE", "pc_id": self.identity.pc_id, "hmac": sig})
        self.session_token = auth["session_token"]
        return auth

    def disconnect(self) -> Dict[str, Any]:
        self.session_token = None
        return self._request({"op": "DISCONNECT"})

    def repair_sui(self) -> Dict[str, Any]:
        return self._request({"op": "REPAIR_SUI", "session_token": self.session_token})

    def restore_sui(self) -> Dict[str, Any]:
        return self._request({"op": "RESTORE_SUI", "session_token": self.session_token})

    def inject_c2_package(self, pkg_path: Path) -> Dict[str, Any]:
        pkg_b64 = base64.b64encode(pkg_path.read_bytes()).decode("ascii")
        return self._request({"op": "INJECT_C2", "session_token": self.session_token, "pkg_b64": pkg_b64})

    def change_os(self, slot_name: str) -> Dict[str, Any]:
        return self._request({"op": "CHANGE_OS", "session_token": self.session_token, "slot": slot_name})


def build_riva_recovery_ramdisk(sandbox_dir: Path = DEFAULT_SANDBOX_DIR) -> Dict[str, Any]:
    """
    Assemble a real gzipped newc cpio Android recovery ramdisk skeleton for Redmi 5A (riva).

    Includes init.mrm.rc, sbin/mrm_protocol.sh, and res/mrm_manifest.json ready to combine
    with a real riva kernel zImage + DTB via mkbootimg.
    """
    stage = sandbox_dir / "ramdisk_stage"
    if stage.exists():
        shutil.rmtree(stage)

    for rel in ("dev", "proc", "sys", "sbin", "res", "etc", "ns", "ps", "tmp"):
        (stage / rel).mkdir(parents=True, exist_ok=True)

    init_rc = (
        "# Coki Studios — Multi Recovery Mode (MRM) Init Script for xiaomi-riva\n"
        "on early-init\n"
        "    start ueventd\n\n"
        "on fs\n"
        "    mkdir /ns 0755 root root\n"
        "    mkdir /ps 0700 root root\n"
        "    write /sys/class/android_usb/android0/enable 0\n"
        "    write /sys/class/android_usb/android0/idVendor 18d1\n"
        "    write /sys/class/android_usb/android0/idProduct d001\n"
        "    write /sys/class/android_usb/android0/functions adb\n"
        "    write /sys/class/android_usb/android0/enable 1\n\n"
        "service mrmd /sbin/mrm_protocol.sh\n"
        "    class main\n"
        "    seclabel u:r:recovery:s0\n"
    )
    (stage / "init.mrm.rc").write_text(init_rc, encoding="utf-8")

    mrm_sh = (
        "#!/sbin/sh\n"
        "# Minimal MRM USB/ADB state announcer for recovery ramdisk\n"
        "MRM_STATE='DISCONNECT'\n"
        "echo \"[MRM] Device: xiaomi-riva | State: $MRM_STATE\"\n"
    )
    mrm_sh_path = stage / "sbin" / "mrm_protocol.sh"
    mrm_sh_path.write_text(mrm_sh, encoding="utf-8")
    os.chmod(mrm_sh_path, 0o755)

    manifest = {
        "device": "xiaomi-riva",
        "model": "Redmi 5A",
        "recovery": "CS MRM Recovery",
        "ui": "hi!UI",
        "states": ["Disconnect", "Uic idle", "Working"],
        "requires_kernel_zimage_for_boot_img": True,
    }
    _atomic_write_json(stage / "res" / "mrm_manifest.json", manifest)

    cpio_bin = shutil.which("cpio") or "/usr/bin/cpio"
    gzip_bin = shutil.which("gzip") or "/usr/bin/gzip"
    out_cpio_gz = sandbox_dir / "mrm_recovery_ramdisk.cpio.gz"

    rel_entries = "\n".join(sorted(str(p.relative_to(stage)) for p in stage.rglob("*"))) + "\n"
    cpio_proc = subprocess.run(
        [cpio_bin, "-o", "--format", "newc", "--quiet"],
        cwd=stage,
        input=rel_entries.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    gzip_proc = subprocess.run(
        [gzip_bin, "-n", "-9"],
        input=cpio_proc.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    _atomic_write_bytes(out_cpio_gz, gzip_proc.stdout)

    # Verify the generated archive by listing its actual entries via gzip + cpio -it.
    gunzip_proc = subprocess.run(
        [gzip_bin, "-dc", str(out_cpio_gz)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    list_proc = subprocess.run(
        [cpio_bin, "-it", "--quiet"],
        input=gunzip_proc.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    verified_entries = [line.strip() for line in list_proc.stdout.decode("utf-8").splitlines() if line.strip()]
    return {
        "ramdisk_path": str(out_cpio_gz),
        "size_bytes": out_cpio_gz.stat().st_size,
        "entries": verified_entries,
    }
