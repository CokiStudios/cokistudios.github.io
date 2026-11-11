#!/usr/bin/env python3
"""
Coki Studios — MRM (Multi Recovery Mode) Interactive Experiment Lab.

Modes:
  gui (default)   Split-screen interactive lab (Phone MRM + PC UIC over mrm.sock)
  device          Terminal live Phone MRM monitor daemon (for 2-terminal experiments)
  uic <action>    PC UIC CLI controller talking to the live MRM daemon or local bus
  test            Real end-to-end verification suite (security gates, HMAC, tamper, cpio)
"""

from __future__ import annotations

import argparse
import io
import json
import os
import select
import shutil
import subprocess
import sys
import tempfile
import termios
import threading
import time
import tty
import zipfile
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from UIConnect.mrm_core import (  # noqa: E402
    DEFAULT_C2_SOURCE,
    DEFAULT_SANDBOX_DIR,
    OS_SLOTS,
    STATE_DISCONNECT,
    STATE_NORMAL_SUI,
    STATE_UIC_IDLE,
    STATE_WORKING,
    MRMDeviceServer,
    MRMError,
    QLCSandbox,
    UICClient,
    UICHostIdentity,
    build_riva_recovery_ramdisk,
    probe_real_hardware,
    sign_c2_package,
)


ANSI_RESET = "\033[0m"
ANSI_CYAN = "\033[96m"
ANSI_GREEN = "\033[92m"
ANSI_YELLOW = "\033[93m"
ANSI_RED = "\033[91m"
ANSI_BOLD = "\033[1m"
ANSI_DIM = "\033[2m"


def _render_ascii_phone_screen(state: Dict[str, Any], host_id: str) -> str:
    mode = state["phone_mode"]
    protect = "ON" if state.get("mrm_protect") else "OFF"
    trusted = host_id in state.get("trusted_pc_ids", [])
    health = "OK" if state.get("sui_health", {}).get("healthy") else "CORRUPT!"
    os_name = state.get("active_os", OS_SLOTS[0])
    c2_list = ", ".join(state.get("installed_c2", [])) or "(ninguno)"

    if mode == STATE_NORMAL_SUI:
        screen = [
            "┌────────────────────── hi!UI (Normal SUI) ──────────────────────┐",
            "│  ● CS Mobile • Redmi 5A (riva)                                 │",
            f"│  OS: {os_name:<43} │",
            "│  PS (Protected Storage): [🔒 SELLADO FUERA DE MRM]             │",
            "│  NS (Normal Storage)   : [📂 Accesible]                        │",
        ]
    elif mode == STATE_DISCONNECT:
        screen = [
            "┌────────────────────── MRM: DISCONNECT ─────────────────────────┐",
            "│      [ PC ] !      ~~~~~~~~x~~~~~~~~      ⚡ [ PHONE MRM ]     │",
            "│      Cable suelto o PC no confiado aún                         │",
            f"│      Host actual ({host_id}): {'TRUSTED' if trusted else 'NO TRUSTED'}          │",
            "│      Esperando enlace USB autenticado con UI Connect...        │",
        ]
    elif mode == STATE_UIC_IDLE:
        screen = [
            "┌────────────────────── MRM: UIC IDLE ───────────────────────────┐",
            "│               CS  •  UIC      ( • • • )                        │",
            f"│      Enlace seguro activo con: {host_id:<31} │",
            "│      PS desbloqueado para operaciones firmadas                 │",
            "│      Listo para Repair / Restore / Inject .c2 / Change OS      │",
        ]
    else:
        screen = [
            "┌────────────────────── MRM: WORKING ────────────────────────────┐",
            "│      ⚙️  ESCRIBIENDO EN PS (PROTECTED STORAGE)...               │",
            "│      ⚠️  NO Disconnect / Not power off                         │",
            f"│      Tarea: {state.get('last_action', '')[:49]:<49} │",
            "│      Verificando firmas SHA-256 / HMAC                         │",
        ]

    footer = [
        "├────────────────────────────────────────────────────────────────┤",
        f"│  Gates -> MRM Protect: {protect:<3} | Trust PC: {str(trusted):<5} | SUI: {health:<8} │",
        f"│  PS/.c2_layer: {c2_list[:47]:<47} │",
        f"│  Último evento: {state.get('last_action', '')[:46]:<46} │",
        "└────────────────────────────────────────────────────────────────┘",
    ]
    return "\n".join(screen + footer)


def run_device_daemon(sandbox_dir: Path, step_delay: float = 0.4) -> None:
    """Run an interactive terminal Phone MRM monitor bound to mrm.sock."""
    sandbox = QLCSandbox(sandbox_dir)
    identity = UICHostIdentity.load_or_create(sandbox.host_dir)
    if sandbox.get_state()["phone_mode"] == STATE_NORMAL_SUI:
        sandbox.set_phone_mode(STATE_DISCONNECT, "Entered MRM Terminal Monitor")

    server = MRMDeviceServer(sandbox, step_delay=step_delay)
    srv_thread = threading.Thread(target=server.serve_forever, daemon=True)
    srv_thread.start()

    fd = sys.stdin.fileno() if sys.stdin.isatty() else None
    old_tty = None
    last_snapshot = ""

    print(f"{ANSI_CYAN}{ANSI_BOLD}[MRM DEVICE]{ANSI_RESET} Escuchando en socket: {server.sock_path}")
    print("Atajos: [m] Toggle Normal/MRM | [p] Toggle MRM Protect | [t] Trust/Revoke PC | [c] Corromper hi!UI | [q] Salir\n")

    try:
        if fd is not None:
            old_tty = termios.tcgetattr(fd)
            tty.setcbreak(fd)
        while True:
            st = sandbox.get_state()
            snap = json.dumps(st, sort_keys=True)
            if snap != last_snapshot:
                last_snapshot = snap
                if sys.stdout.isatty():
                    sys.stdout.write("\033[H\033[J")
                print(f"{ANSI_BOLD}CS MRM Phone Daemon (Socket: {server.sock_path.name}){ANSI_RESET}")
                print("Atajos: [m] Modo Normal/MRM | [p] MRM Protect | [t] Trust PC | [c] Simular Fallo SUI | [q] Salir\n")
                print(_render_ascii_phone_screen(st, identity.pc_id))
                print(f"\n{ANSI_DIM}En otra terminal ejecuta: ./bin/ui-connect --mrm uic connect{ANSI_RESET}")
                sys.stdout.flush()

            if fd is not None and select.select([fd], [], [], 0.2)[0]:
                ch = os.read(fd, 1).decode("utf-8", errors="ignore").lower()
                if ch == "q":
                    break
                if ch == "m":
                    nxt = STATE_NORMAL_SUI if st["phone_mode"] != STATE_NORMAL_SUI else STATE_DISCONNECT
                    sandbox.set_phone_mode(nxt, "Combo Hardware Vol+/Vol-/Power")
                elif ch == "p":
                    sandbox.set_mrm_protect(not st.get("mrm_protect"))
                elif ch == "t":
                    if identity.pc_id in st.get("trusted_pc_ids", []):
                        sandbox.revoke_trust_pc(identity.pc_id)
                    else:
                        sandbox.authorize_trust_pc(identity)
                elif ch == "c":
                    sandbox.corrupt_sui_for_test()
            else:
                time.sleep(0.2)
    except KeyboardInterrupt:
        pass
    finally:
        if old_tty is not None and fd is not None:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_tty)
        server.shutdown()
        server.server_close()
        print("\n[MRM DEVICE] Apagado limpio.")


def _corrupt_c2pkg_byte(pkg_path: Path, out_path: Path) -> Path:
    """Create a tampered copy of a signed .c2pkg by altering payload.c2 by 1 byte."""
    buf = io.BytesIO()
    with zipfile.ZipFile(pkg_path, "r") as zin, zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "payload.c2":
                data = data + b"\n# TAMPERED_BYTE\n"
            zout.writestr(item, data)
    out_path.write_bytes(buf.getvalue())
    return out_path


def run_uic_cli(args: argparse.Namespace) -> int:
    """Run one-shot UIC CLI commands against a live device daemon or local sandbox."""
    sandbox = QLCSandbox(args.sandbox)
    identity = UICHostIdentity.load_or_create(sandbox.host_dir)
    sock_path = sandbox.root / "mrm.sock"

    if args.uic_cmd == "probe-usb":
        hw = probe_real_hardware()
        print(json.dumps(hw, indent=2, ensure_ascii=False))
        return 0

    if args.uic_cmd == "ramdisk":
        res = build_riva_recovery_ramdisk(sandbox.root)
        print(f"{ANSI_GREEN}✔ Recovery ramdisk empaquetado:{ANSI_RESET} {res['ramdisk_path']} ({res['size_bytes']} bytes)")
        print("Entradas verificadas con cpio -it:")
        for entry in res["entries"]:
            print(f"  • {entry}")
        return 0

    if args.uic_cmd == "sign":
        src = Path(args.target) if args.target else DEFAULT_C2_SOURCE
        out_pkg = sandbox.host_dir / f"{src.stem}.c2pkg"
        res = sign_c2_package(src, out_pkg, identity)
        print(f"{ANSI_GREEN}✔ Firmado .c2pkg:{ANSI_RESET} {res['package']}")
        print(f"  SHA-256 payload: {res['manifest']['payload_sha256']}")
        print(f"  HMAC signature : {res['signature'][:24]}...")
        return 0

    if args.uic_cmd == "trust-pc":
        sandbox.authorize_trust_pc(identity)
        print(f"{ANSI_GREEN}✔ Trust PC autorizado en PS/nec_pair para {identity.pc_id}{ANSI_RESET}")
        return 0

    # Attach to a live daemon if responsive; otherwise purge stale socket and launch a transient one.
    client = UICClient(sock_path, identity)
    transient_srv: Optional[MRMDeviceServer] = None
    daemon_alive = False
    if sock_path.exists():
        try:
            client.ping()
            daemon_alive = True
        except MRMError:
            sock_path.unlink(missing_ok=True)

    if not daemon_alive:
        transient_srv = MRMDeviceServer(sandbox, sock_path=sock_path, step_delay=0.05)
        threading.Thread(target=transient_srv.serve_forever, daemon=True).start()

    try:
        if args.uic_cmd == "status":
            print(_render_ascii_phone_screen(client.ping()["state"], identity.pc_id))
            return 0

        if args.uic_cmd == "connect":
            res = client.connect()
            print(f"{ANSI_GREEN}✔ Uic idle activo.{ANSI_RESET} Session token: {res['session_token'][:12]}...")
            return 0
        if args.uic_cmd == "disconnect":
            client.disconnect()
            print("🔌 Desconectado -> MRM: DISCONNECT")
            return 0

        # Auto-authenticate if running one-shot command on active MRM
        client.connect()
        if args.uic_cmd == "repair":
            res = client.repair_sui()
            print(f"{ANSI_GREEN}✔ Repair SUI completado:{ANSI_RESET}", res["result"])
        elif args.uic_cmd == "restore":
            res = client.restore_sui()
            print(f"{ANSI_GREEN}✔ Restore SUI completado (NS intacto):{ANSI_RESET}", res["result"])
        elif args.uic_cmd == "change-os":
            slot = args.target if args.target in OS_SLOTS else OS_SLOTS[1]
            res = client.change_os(slot)
            print(f"{ANSI_GREEN}✔ Change OS aplicado:{ANSI_RESET}", res["result"])
        elif args.uic_cmd == "inject":
            src = Path(args.target) if args.target else DEFAULT_C2_SOURCE
            pkg_path = sandbox.host_dir / f"{src.stem}.c2pkg"
            sign_c2_package(src, pkg_path, identity)
            res = client.inject_c2_package(pkg_path)
            print(f"{ANSI_GREEN}✔ .c2 inyectado en PS:{ANSI_RESET}", res["result"]["installed_file"])
        elif args.uic_cmd == "tamper-test":
            pkg_path = sandbox.host_dir / "valid_tmp.c2pkg"
            bad_path = sandbox.host_dir / "tampered_tmp.c2pkg"
            sign_c2_package(DEFAULT_C2_SOURCE, pkg_path, identity)
            _corrupt_c2pkg_byte(pkg_path, bad_path)
            try:
                client.inject_c2_package(bad_path)
                print(f"{ANSI_RED}✖ ERROR: MRM aceptó paquete alterado!{ANSI_RESET}")
                return 1
            except MRMError as exc:
                print(f"{ANSI_GREEN}✔ MRM bloqueó ataque como se esperaba:{ANSI_RESET} {exc}")
                return 0
        return 0
    except MRMError as exc:
        print(f"{ANSI_RED}✖ [{exc.code}]{ANSI_RESET} {exc.message}")
        return 1
    finally:
        if transient_srv is not None:
            transient_srv.shutdown()
            transient_srv.server_close()


def run_e2e_verification(verbose: bool = True) -> int:
    """
    Real end-to-end verification suite for MRM protocol, security gates,
    HMAC challenge-response, .c2pkg tamper rejection, SUI healing, and cpio ramdisk.
    """
    tmp_root = Path(tempfile.mkdtemp(prefix="cs_mrm_e2e_", dir=str(REPO_ROOT / "build")))
    results: List[tuple[str, bool, str]] = []

    def check(name: str, fn: Callable[[], str]) -> None:
        try:
            detail = fn()
            results.append((name, True, detail))
            if verbose:
                print(f"  {ANSI_GREEN}✔ PASS{ANSI_RESET} {name} — {detail}")
        except Exception as exc:
            results.append((name, False, str(exc)))
            if verbose:
                print(f"  {ANSI_RED}✖ FAIL{ANSI_RESET} {name} — {exc}")

    sandbox = QLCSandbox(tmp_root)
    identity = UICHostIdentity.load_or_create(sandbox.host_dir)
    server = MRMDeviceServer(sandbox, sock_path=tmp_root / "mrm.sock", step_delay=0.01)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    client = UICClient(server.sock_path, identity)

    try:
        def t1() -> str:
            sandbox.set_phone_mode(STATE_NORMAL_SUI, "Test Normal SUI")
            try:
                sandbox.attempt_direct_ps_write("c2_layer/evil.c2", "hack")
            except MRMError as exc:
                assert exc.code == "PS_LOCKED_NORMAL_SUI", exc.code
                return exc.code
            raise AssertionError("PS write succeeded in NORMAL_SUI!")

        def t2() -> str:
            sandbox.set_phone_mode(STATE_DISCONNECT, "Boot to MRM Disconnect")
            try:
                client.connect()
            except MRMError as exc:
                assert exc.code == "ERR_PC_NOT_TRUSTED", exc.code
                assert sandbox.get_state()["phone_mode"] == STATE_DISCONNECT
                return f"{exc.code} (screen stayed DISCONNECT)"
            raise AssertionError("Untrusted PC was allowed!")

        def t3() -> str:
            sandbox.authorize_trust_pc(identity)
            auth = client.connect()
            assert sandbox.get_state()["phone_mode"] == STATE_UIC_IDLE
            return f"HMAC challenge verified -> {STATE_UIC_IDLE} (token {auth['session_token'][:8]}...)"

        def t4() -> str:
            pkg = tmp_root / "signed_hiui.c2pkg"
            sign_c2_package(DEFAULT_C2_SOURCE, pkg, identity)
            sandbox.set_mrm_protect(False)
            try:
                client.inject_c2_package(pkg)
            except MRMError as exc:
                assert exc.code == "ERR_MRM_PROTECT_DISABLED", exc.code
                sandbox.set_mrm_protect(True)
                return f"{exc.code} enforced"
            raise AssertionError("Write succeeded while MRM Protect was OFF!")

        def t5() -> str:
            pkg = tmp_root / "signed_hiui.c2pkg"
            res = client.inject_c2_package(pkg)
            installed = Path(res["result"]["installed_file"])
            assert installed.exists() and "FeatherLite" in installed.read_text(encoding="utf-8")
            return f"Injected -> PS/c2_layer/{installed.name}"

        def t6() -> str:
            bad = tmp_root / "tampered.c2pkg"
            _corrupt_c2pkg_byte(tmp_root / "signed_hiui.c2pkg", bad)
            try:
                client.inject_c2_package(bad)
            except MRMError as exc:
                assert exc.code == "ERR_PAYLOAD_TAMPERED", exc.code
                return f"Rejected corrupted .c2pkg ({exc.code})"
            raise AssertionError("Tampered .c2pkg was accepted!")

        def t7() -> str:
            sandbox.corrupt_sui_for_test()
            assert not sandbox.get_state()["sui_health"]["healthy"]
            rep = client.repair_sui()["result"]
            assert sandbox.get_state()["sui_health"]["healthy"]
            return f"Healed files: {rep['repaired_files']}"

        def t8() -> str:
            ns_file = sandbox.write_ns_note("user_keep.txt", "keep me safe")
            rst = client.restore_sui()["result"]
            assert ns_file.exists() and not rst["sui_health"]["corrupted"]
            assert not (sandbox.ps_dir / "c2_layer" / "feather_lite_hiui.c2").exists()
            return "PS reset cleanly while NS/userdata survived"

        def t9() -> str:
            rd = build_riva_recovery_ramdisk(tmp_root)
            entries = set(rd["entries"])
            assert {"init.mrm.rc", "sbin/mrm_protocol.sh", "res/mrm_manifest.json"}.issubset(entries)
            return f"{rd['size_bytes']} bytes, verified {len(entries)} cpio entries"

        if verbose:
            print(f"\n{ANSI_CYAN}{ANSI_BOLD}✦ Coki Studios MRM Lab — E2E Protocol & Hardware Security Suite ✦{ANSI_RESET}")
        for label, fn in [
            ("1. PS locked in Normal SUI", t1),
            ("2. Reject untrusted PC handshake", t2),
            ("3. Trust PC + HMAC handshake -> Uic idle", t3),
            ("4. Gate 'MRM Protect' enforced", t4),
            ("5. Sign & Inject feather_lite_hiui.c2 -> PS", t5),
            ("6. Reject tampered .c2pkg (SHA-256 check)", t6),
            ("7. Repair SUI heals corrupted hiui_shell.json", t7),
            ("8. Restore SUI resets PS & keeps NS intact", t8),
            ("9. Pack & verify Redmi 5A ramdisk (cpio+gzip)", t9),
        ]:
            check(label, fn)
    finally:
        server.shutdown()
        server.server_close()
        shutil.rmtree(tmp_root, ignore_errors=True)

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    if verbose:
        print(f"\nResultado: {passed}/{total} pruebas reales pasaron.\n")
    return 0 if passed == total else 1


class MRMLabGUI:
    """Interactive Dual-Node Tkinter Lab backed by live MRMDeviceServer & QLCSandbox."""

    def __init__(self, sandbox_dir: Path, autoclose_ms: int = 0):
        import tkinter as tk
        from tkinter import ttk

        self.tk = tk
        self.ttk = ttk
        self.sandbox = QLCSandbox(sandbox_dir)
        self.identity = UICHostIdentity.load_or_create(self.sandbox.host_dir)
        if self.sandbox.get_state()["phone_mode"] == STATE_WORKING:
            self.sandbox.set_phone_mode(STATE_DISCONNECT, "Recovered clean MRM idle")

        self.server = MRMDeviceServer(self.sandbox, step_delay=0.45)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.client = UICClient(self.server.sock_path, self.identity)
        self.last_pkg_path: Optional[Path] = None

        self.root = tk.Tk()
        self.root.title("✦ Coki Studios — MRM Live Experiment Lab (Real Socket + QLC Sandbox + USB Probe) ✦")
        self.root.geometry("1220x780")
        self.root.minsize(1020, 680)
        self.root.configure(bg="#090d16")

        self.var_mrm_protect = tk.BooleanVar(value=bool(self.sandbox.get_state().get("mrm_protect", True)))
        self.var_c2_source = tk.StringVar(value=str(DEFAULT_C2_SOURCE))
        self.var_os_slot = tk.StringVar(value=self.sandbox.get_state().get("active_os", OS_SLOTS[0]))
        self._busy = False

        self._build_ui()
        self._refresh_hardware_async()
        self._refresh_state_loop()

        if autoclose_ms > 0:
            self.root.after(autoclose_ms, self.close)
        self.root.protocol("WM_DELETE_WINDOW", self.close)

    def _build_ui(self) -> None:
        tk = self.tk
        ttk = self.ttk

        top = tk.Frame(self.root, bg="#0f172a", height=48)
        top.pack(fill="x", side="top")
        tk.Label(
            top,
            text="✦ MRM LIVE LAB • Redmi 5A (riva) / Shine OS — Protocolo Real sobre Socket + NAND QLC + cpio",
            bg="#0f172a",
            fg="#38bdf8",
            font=("Helvetica", 13, "bold"),
            padx=14,
            pady=10,
        ).pack(side="left")
        self.lbl_usb_hw = tk.Label(
            top,
            text="USB Real: comprobando adb/fastboot...",
            bg="#1e293b",
            fg="#cbd5e1",
            font=("Menlo", 10),
            padx=10,
            pady=4,
        )
        self.lbl_usb_hw.pack(side="right", padx=12, pady=8)

        body = tk.Frame(self.root, bg="#090d16")
        body.pack(fill="both", expand=True, padx=12, pady=10)
        body.columnconfigure(0, weight=5)
        body.columnconfigure(1, weight=7)
        body.rowconfigure(0, weight=1)

        # LEFT: Phone MRM Device
        left = tk.Frame(body, bg="#111827", highlightbackground="#1e293b", highlightthickness=1)
        left.grid(row=0, column=0, sticky="nsew", padx=(0, 8))
        tk.Label(
            left,
            text="📱 CELULAR EN VIVO (Daemon MRM)",
            bg="#111827",
            fg="#e2e8f0",
            font=("Helvetica", 12, "bold"),
            pady=8,
        ).pack()

        self.canvas_phone = tk.Canvas(left, bg="#050811", height=320, highlightthickness=1, highlightbackground="#334155")
        self.canvas_phone.pack(fill="x", padx=16, pady=(2, 10))

        phone_ctrl = tk.LabelFrame(left, text=" Controles del Celular / Settings ", bg="#111827", fg="#94a3b8", padx=10, pady=8)
        phone_ctrl.pack(fill="x", padx=16, pady=4)

        self._btn(phone_ctrl, "Combo Hardware: Alternar Normal SUI <-> MRM", "#1e3a8a", self._toggle_phone_boot_mode).pack(fill="x", pady=3)
        tk.Checkbutton(
            phone_ctrl,
            text="Settings: Enable MRM Protect",
            variable=self.var_mrm_protect,
            command=self._on_toggle_mrm_protect,
            bg="#111827",
            fg="#f8fafc",
            selectcolor="#0f172a",
            activebackground="#111827",
            activeforeground="#38bdf8",
        ).pack(anchor="w", pady=3)

        row_trust = tk.Frame(phone_ctrl, bg="#111827")
        row_trust.pack(fill="x", pady=3)
        self._btn(row_trust, "Settings: Add Trust PC", "#065f46", self._on_trust_pc).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(row_trust, "Revocar Trust", "#7f1d1d", self._on_revoke_pc).pack(side="left", expand=True, fill="x", padx=(4, 0))

        row_exp = tk.Frame(phone_ctrl, bg="#111827")
        row_exp.pack(fill="x", pady=3)
        self._btn(row_exp, "🔓 Probar escritura directa PS", "#78350f", self._test_direct_ps_write).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(row_exp, "💥 Corromper hi!UI", "#991b1b", self._corrupt_sui).pack(side="left", expand=True, fill="x", padx=(4, 0))

        self.lbl_nand_summary = tk.Label(left, text="", justify="left", anchor="nw", bg="#0b1120", fg="#94a3b8", font=("Menlo", 10), padx=10, pady=8)
        self.lbl_nand_summary.pack(fill="both", expand=True, padx=16, pady=(6, 12))

        # RIGHT: PC UIC + Operations + Log
        right = tk.Frame(body, bg="#111827", highlightbackground="#1e293b", highlightthickness=1)
        right.grid(row=0, column=1, sticky="nsew", padx=(8, 0))
        tk.Label(
            right,
            text=f"💻 PC UI CONNECT ({self.identity.pc_id})",
            bg="#111827",
            fg="#e2e8f0",
            font=("Helvetica", 12, "bold"),
            pady=8,
        ).pack()

        cable_box = tk.LabelFrame(right, text=" Enlace USB / Protocolo Socket HMAC ", bg="#111827", fg="#94a3b8", padx=10, pady=8)
        cable_box.pack(fill="x", padx=14, pady=4)
        c_row = tk.Frame(cable_box, bg="#111827")
        c_row.pack(fill="x")
        self._btn(c_row, "🔌 Conectar Cable (HMAC Handshake)", "#0284c7", self._uic_connect).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(c_row, "🔌 Desconectar Cable", "#334155", self._uic_disconnect).pack(side="left", expand=True, fill="x", padx=(4, 4))
        self._btn(c_row, "🔍 Probar USB Real", "#1e293b", self._refresh_hardware_async).pack(side="left", padx=(4, 0))

        c2_box = tk.LabelFrame(right, text=" Sign & Inject .c2 on PS (Be Careful) ", bg="#111827", fg="#94a3b8", padx=10, pady=8)
        c2_box.pack(fill="x", padx=14, pady=4)
        sources = [str(DEFAULT_C2_SOURCE), str(self.sandbox.ps_dir / "rice_layer" / "hiui_core.bowl")]
        ttk.Combobox(c2_box, textvariable=self.var_c2_source, values=sources, state="readonly").pack(fill="x", pady=(0, 6))

        c2_row = tk.Frame(c2_box, bg="#111827")
        c2_row.pack(fill="x")
        self._btn(c2_row, "🔏 1. Firmar .c2pkg", "#0f766e", self._sign_selected_c2).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(c2_row, "⚡ 2. Inject .c2 on PS", "#0369a1", self._inject_signed_c2).pack(side="left", expand=True, fill="x", padx=(4, 4))
        self._btn(c2_row, "🧪 Ataque .c2 Alterado", "#b91c1c", self._inject_tampered_c2).pack(side="left", expand=True, fill="x", padx=(4, 0))

        ops_box = tk.LabelFrame(right, text=" Operaciones MRM en PS + Recovery Ramdisk (Redmi 5A) ", bg="#111827", fg="#94a3b8", padx=10, pady=8)
        ops_box.pack(fill="x", padx=14, pady=4)
        o_row1 = tk.Frame(ops_box, bg="#111827")
        o_row1.pack(fill="x", pady=2)
        self._btn(o_row1, "🩺 Repair SUI", "#1d4ed8", self._op_repair_sui).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(o_row1, "♻️ Restore SUI (Limpia PS, guarda NS)", "#7c2d12", self._op_restore_sui).pack(side="left", expand=True, fill="x", padx=(4, 0))

        o_row2 = tk.Frame(ops_box, bg="#111827")
        o_row2.pack(fill="x", pady=4)
        ttk.Combobox(o_row2, textvariable=self.var_os_slot, values=list(OS_SLOTS), state="readonly", width=26).pack(side="left", padx=(0, 6))
        self._btn(o_row2, "🔄 Change OS", "#4338ca", self._op_change_os).pack(side="left", expand=True, fill="x", padx=(0, 4))
        self._btn(o_row2, "📦 Pack Redmi 5A Ramdisk (.cpio.gz)", "#4d7c0f", self._pack_ramdisk).pack(side="left", expand=True, fill="x", padx=(4, 0))

        log_box = tk.LabelFrame(right, text=" Telemetría Cryptográfica & Protocol Log ", bg="#111827", fg="#94a3b8", padx=8, pady=6)
        log_box.pack(fill="both", expand=True, padx=14, pady=(4, 12))
        self.txt_log = tk.Text(log_box, bg="#030712", fg="#e2e8f0", font=("Menlo", 10), height=14, wrap="word")
        self.txt_log.pack(fill="both", expand=True)
        self._log(f"Lab listo. Sandbox: {self.sandbox.root}")
        self._log(f"Socket Unix activo: {self.server.sock_path}")

    def _btn(self, parent: Any, text: str, color: str, cmd: Callable[[], Any]) -> Any:
        return self.tk.Button(
            parent,
            text=text,
            command=cmd,
            bg=color,
            fg="#f8fafc",
            activebackground=color,
            activeforeground="#ffffff",
            relief="flat",
            padx=8,
            pady=6,
            font=("Helvetica", 10, "bold"),
            cursor="hand2",
        )

    def _log(self, msg: str) -> None:
        ts = time.strftime("%H:%M:%S")
        self.txt_log.insert("end", f"[{ts}] {msg}\n")
        self.txt_log.see("end")

    def _run_async(self, label: str, fn: Callable[[], str]) -> None:
        if self._busy:
            self._log("⏳ Operación en curso, espera un instante...")
            return
        self._busy = True

        def _worker() -> None:
            try:
                out = fn()
                self.root.after(0, lambda: self._log(f"✔ {out}"))
            except MRMError as exc:
                self.root.after(0, lambda e=exc: self._log(f"🛡️ BLOQUEADO [{e.code}]: {e.message}"))
            except Exception as exc:
                self.root.after(0, lambda e=exc: self._log(f"✖ Error en {label}: {e}"))
            finally:
                def _done() -> None:
                    self._busy = False
                self.root.after(0, _done)

        threading.Thread(target=_worker, daemon=True).start()

    def _toggle_phone_boot_mode(self) -> None:
        st = self.sandbox.get_state()
        nxt = STATE_DISCONNECT if st["phone_mode"] == STATE_NORMAL_SUI else STATE_NORMAL_SUI
        self.client.session_token = None
        self.sandbox.set_phone_mode(nxt, "Combo Hardware Vol+ + Vol- + Power")
        self._log(f"📱 Modo cambiado a {nxt}")

    def _on_toggle_mrm_protect(self) -> None:
        val = self.var_mrm_protect.get()
        self.sandbox.set_mrm_protect(val)
        self._log(f"Settings -> Enable MRM Protect = {val}")

    def _on_trust_pc(self) -> None:
        self.sandbox.authorize_trust_pc(self.identity)
        self._log(f"🔑 Settings -> Add Trust PC ({self.identity.pc_id}, fp={self.identity.fingerprint})")

    def _on_revoke_pc(self) -> None:
        self.sandbox.revoke_trust_pc(self.identity.pc_id)
        self.client.session_token = None
        self._log(f"🚫 Settings -> Revocado Trust PC ({self.identity.pc_id})")

    def _test_direct_ps_write(self) -> None:
        try:
            self.sandbox.attempt_direct_ps_write("sui_system/hack.txt", "raw write")
        except MRMError as exc:
            self._log(f"🔒 Seguridad NAND PS [{exc.code}]: {exc.message}")

    def _corrupt_sui(self) -> None:
        self.sandbox.corrupt_sui_for_test()
        self._log("💥 Simulada corrupción en PS/sui_system/hiui_shell.json -> usa Repair SUI para sanar.")

    def _uic_connect(self) -> None:
        def _do() -> str:
            res = self.client.connect()
            return f"Handshake HMAC-SHA256 OK -> MRM: Uic idle (token {res['session_token'][:10]}...)"
        self._run_async("Connect", _do)

    def _uic_disconnect(self) -> None:
        def _do() -> str:
            self.client.disconnect()
            return "Cable desconectado -> MRM: Disconnect"
        self._run_async("Disconnect", _do)

    def _sign_selected_c2(self) -> None:
        src = Path(self.var_c2_source.get())
        out_pkg = self.sandbox.host_dir / f"{src.stem}.c2pkg"
        res = sign_c2_package(src, out_pkg, self.identity)
        self.last_pkg_path = out_pkg
        self._log(f"🔏 Firmado {out_pkg.name} | SHA-256: {res['manifest']['payload_sha256'][:16]}...")

    def _inject_signed_c2(self) -> None:
        if not self.last_pkg_path or not self.last_pkg_path.exists():
            self._sign_selected_c2()
        pkg = self.last_pkg_path
        assert pkg is not None

        def _do() -> str:
            res = self.client.inject_c2_package(pkg)
            return f"Inyectado en PS -> {Path(res['result']['installed_file']).name}"
        self._run_async("Inject .c2", _do)

    def _inject_tampered_c2(self) -> None:
        if not self.last_pkg_path or not self.last_pkg_path.exists():
            self._sign_selected_c2()
        pkg = self.last_pkg_path
        assert pkg is not None
        tampered = self.sandbox.host_dir / f"{pkg.stem}_tampered.c2pkg"
        _corrupt_c2pkg_byte(pkg, tampered)

        def _do() -> str:
            self.client.inject_c2_package(tampered)
            return "INESPERADO: paquete alterado aceptado"
        self._run_async("Tamper Test", _do)

    def _op_repair_sui(self) -> None:
        self._run_async("Repair SUI", lambda: f"Repair SUI -> reparados {self.client.repair_sui()['result']['repaired_files']}")

    def _op_restore_sui(self) -> None:
        self._run_async("Restore SUI", lambda: f"Restore SUI listo (NS intacto, .c2 removidos={self.client.restore_sui()['result']['removed_c2']})")

    def _op_change_os(self) -> None:
        slot = self.var_os_slot.get()
        self._run_async("Change OS", lambda: f"OS cambiado a: {self.client.change_os(slot)['result']['active_os']}")

    def _pack_ramdisk(self) -> None:
        res = build_riva_recovery_ramdisk(self.sandbox.root)
        self._log(f"📦 Ramdisk Redmi 5A ({res['size_bytes']} B): {res['ramdisk_path']}")
        self._log("   Entradas cpio: " + ", ".join(res["entries"][:8]) + (" ..." if len(res["entries"]) > 8 else ""))

    def _refresh_hardware_async(self) -> None:
        def _worker() -> None:
            hw = probe_real_hardware()
            adb_n = len(hw["adb_devices"])
            fb_n = len(hw["fastboot_devices"])
            if adb_n or fb_n:
                txt = f"USB Real: {adb_n} ADB / {fb_n} Fastboot conectado(s)!"
                fg = "#4ade80"
            else:
                txt = "USB Real: 0 conectados (Sandbox + Socket activos)"
                fg = "#cbd5e1"
            self.root.after(0, lambda: self.lbl_usb_hw.config(text=txt, fg=fg))
        threading.Thread(target=_worker, daemon=True).start()

    def _draw_phone_screen(self, state: Dict[str, Any]) -> None:
        c = self.canvas_phone
        c.delete("all")
        w = max(c.winfo_width(), 380)
        h = max(c.winfo_height(), 300)
        cx, cy = w // 2, h // 2
        mode = state["phone_mode"]

        if mode == STATE_NORMAL_SUI:
            c.create_rectangle(24, 18, w - 24, h - 18, fill="#082f49", outline="#06b6d4", width=2)
            c.create_text(cx, 52, text="● hi!UI — NORMAL SUI", fill="#22d3ee", font=("Helvetica", 15, "bold"))
            c.create_text(cx, 92, text=f"OS activo: {state.get('active_os')}", fill="#e2e8f0", font=("Helvetica", 11))
            c.create_text(cx, 130, text="🔒 Protected Storage (PS): BLOQUEADO", fill="#fbbf24", font=("Helvetica", 12, "bold"))
            c.create_text(cx, 165, text="Pulsa 'Combo Hardware' para reiniciar a MRM", fill="#94a3b8", font=("Helvetica", 10))
        elif mode == STATE_DISCONNECT:
            c.create_rectangle(24, 18, w - 24, h - 18, fill="#1c1108", outline="#f59e0b", width=2)
            c.create_text(cx, 52, text="MRM — DISCONNECT", fill="#fbbf24", font=("Helvetica", 16, "bold"))
            c.create_text(cx, 118, text="[ PC ]  !     x~~~x     ⚡  [ MRM ]", fill="#fcd34d", font=("Menlo", 15, "bold"))
            c.create_text(cx, 170, text="Requiere: Add Trust PC + Conectar Cable en UIC", fill="#fde68a", font=("Helvetica", 10))
        elif mode == STATE_UIC_IDLE:
            c.create_rectangle(24, 18, w - 24, h - 18, fill="#0f172a", outline="#38bdf8", width=2)
            c.create_text(cx, 52, text="MRM — UIC IDLE", fill="#38bdf8", font=("Helvetica", 16, "bold"))
            c.create_text(cx, 118, text="CS  •  UIC      •  •  •", fill="#e0f2fe", font=("Menlo", 18, "bold"))
            c.create_text(cx, 170, text=f"Autenticado vía HMAC ({state.get('active_pc_id')})", fill="#7dd3fc", font=("Helvetica", 10))
        else:
            c.create_rectangle(24, 18, w - 24, h - 18, fill="#280909", outline="#ef4444", width=3)
            c.create_text(cx, 52, text="⚙️ MRM — WORKING", fill="#f87171", font=("Helvetica", 17, "bold"))
            c.create_text(cx, 118, text="NO Disconnect / Not power off", fill="#fecaca", font=("Helvetica", 14, "bold"))
            c.create_text(cx, 168, text=state.get("last_action", ""), fill="#fca5a5", font=("Menlo", 10))

        trusted_ok = self.identity.pc_id in state.get("trusted_pc_ids", [])
        c.create_text(
            cx,
            h - 42,
            text=f"MRM Protect: {'ON' if state.get('mrm_protect') else 'OFF'}   |   Trust PC: {'SI' if trusted_ok else 'NO'}",
            fill="#cbd5e1",
            font=("Menlo", 10),
        )

    def _refresh_state_loop(self) -> None:
        st = self.sandbox.get_state()
        self.var_mrm_protect.set(bool(st.get("mrm_protect", True)))
        self._draw_phone_screen(st)
        health = "SALUDABLE" if st.get("sui_health", {}).get("healthy") else f"DAÑADO ({st['sui_health']['corrupted']})"
        c2_str = ", ".join(st.get("installed_c2", [])) or "(vacío)"
        self.lbl_nand_summary.config(
            text=(
                f"QLC NAND (build/mrm_sandbox/nand/):\n"
                f"  • NS/userdata/ : notes.txt (persistente)\n"
                f"  • PS/sui_system: {health}\n"
                f"  • PS/c2_layer  : {c2_str}\n"
                f"  • OS activo    : {st.get('active_os')}\n"
                f"  • Último evento: {st.get('last_action', '')[:44]}"
            )
        )
        self.root.after(150, self._refresh_state_loop)

    def run(self) -> None:
        self.root.mainloop()

    def close(self) -> None:
        try:
            self.server.shutdown()
            self.server.server_close()
        except Exception:
            pass
        self.root.destroy()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Coki Studios — MRM (Multi Recovery Mode) Experiment Lab")
    parser.add_argument("--sandbox", type=Path, default=DEFAULT_SANDBOX_DIR, help="Directorio del sandbox QLC")
    sub = parser.add_subparsers(dest="mode")

    p_gui = sub.add_parser("gui", help="Abrir laboratorio interactivo dual (por defecto)")
    p_gui.add_argument("--autoclose-ms", type=int, default=0, help="Cerrar automáticamente tras N ms (pruebas)")

    p_dev = sub.add_parser("device", help="Ejecutar monitor terminal en vivo del celular MRM")
    p_dev.add_argument("--step-delay", type=float, default=0.4)

    p_uic = sub.add_parser("uic", help="Cliente CLI PC UI Connect")
    p_uic.add_argument(
        "uic_cmd",
        choices=["status", "trust-pc", "connect", "disconnect", "sign", "inject", "tamper-test", "repair", "restore", "change-os", "ramdisk", "probe-usb"],
    )
    p_uic.add_argument("target", nargs="?", help="Archivo .c2/.bowl o nombre de slot OS")

    sub.add_parser("test", help="Ejecutar suite E2E real de verificación MRM")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    mode = args.mode or "gui"

    if mode == "test":
        return run_e2e_verification(verbose=True)
    if mode == "device":
        run_device_daemon(args.sandbox, step_delay=args.step_delay)
        return 0
    if mode == "uic":
        return run_uic_cli(args)
    if mode == "gui":
        autoclose = getattr(args, "autoclose_ms", 0)
        MRMLabGUI(args.sandbox, autoclose_ms=autoclose).run()
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
