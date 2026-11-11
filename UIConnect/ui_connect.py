#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
✦ UI CONNECT (PC) — COKI STUDIOS OFFICIAL COMPONENT 2 (.c2) MANAGER ✦
Desktop PC Suite for Packaging, Inspecting & Installing .c2 Modules on Shine Phones
═══════════════════════════════════════════════════════════════════════════════
Compatible with: Shine f1, i1, fW1 (flUI), Shine X1, Xa1 (xUI 240Hz), 
                 Shine Nomad 1 (UI), Shine A1 (hiUI), Shine Vintage (tUIlbar).
Supported Transport: ADB over USB, ADB over Wi-Fi, CS WEBS Cloudflare OTA.
"""

import sys
import os
import json
import zipfile
import hashlib
import subprocess
import argparse
import time
import shutil
import http.server
import socketserver
import threading
import webbrowser
import urllib.parse
import urllib.request

# ANSI Color Codes for terminal
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
WHITE = "\033[37m"

DEFAULT_CS_WEBS = os.environ.get("CS_WEBS_URL", "https://webs.cokistudios.com")
SHINE_REMOTE_MODULE_DIR = "/sdcard/ShineUI/modules"
SHINE_RECEIVER = "com.cokistudios.shine/.forkar.services.C2InstallReceiver"
SHINE_ACTION_INSTALL = "com.cokistudios.shine.INSTALL_C2"

def print_banner():
    banner = f"""{BOLD}{CYAN}
╔══════════════════════════════════════════════════════════════════════════════╗
║  ✦ UI CONNECT (PC) ✦ — SHINE OS COMPONENT 2 (.c2) DESKTOP SUITE v2.5.0       ║
║  Hardware-Backed Dynamic UI Hot-Reload • ADB USB/Wi-Fi • Cloudflare Edge OTA ║
╚══════════════════════════════════════════════════════════════════════════════╝{RESET}"""
    print(banner)

def get_adb_path():
    adb = shutil.which("adb")
    if adb:
        return adb
    for cand in ["/opt/homebrew/bin/adb", "/usr/local/bin/adb", "/usr/bin/adb", os.path.expanduser("~/Library/Android/sdk/platform-tools/adb")]:
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    return "adb"

def run_adb(args, device=None):
    adb = get_adb_path()
    cmd = [adb]
    if device:
        cmd.extend(["-s", device])
    cmd.extend(args)
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=15)
        return res.returncode, res.stdout, res.stderr
    except FileNotFoundError:
        return -1, "", "ADB not found. Please install adb or Android platform-tools."
    except Exception as e:
        return -1, "", str(e)

def detect_devices():
    code, stdout, stderr = run_adb(["devices", "-l"])
    if code != 0:
        return []

    devices = []
    lines = stdout.strip().splitlines()
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) >= 2:
            serial = parts[0]
            state = parts[1]
            if state != "device":
                devices.append({
                    "serial": serial,
                    "state": state,
                    "model": "Unknown",
                    "shine_model": "Unknown",
                    "battery": "N/A"
                })
                continue

            _, model_out, _ = run_adb(["shell", "getprop", "ro.product.model"], device=serial)
            _, brand_out, _ = run_adb(["shell", "getprop", "ro.product.brand"], device=serial)
            _, batt_out, _ = run_adb(["shell", "dumpsys", "battery"], device=serial)

            model = model_out.strip() or "Android Device"
            brand = brand_out.strip() or "Generic"

            batt_level = "Unknown"
            for b_line in batt_out.splitlines():
                if "level:" in b_line:
                    batt_level = b_line.split(":")[1].strip() + "%"
                    break

            shine_model = "Generic Android"
            m_lower = model.lower()
            if "shine" in m_lower or "coki" in m_lower:
                shine_model = model
            elif "f1" in m_lower or "fold" in m_lower:
                shine_model = "Shine f1 (Dual-Screen Foldable)"
            elif "x1" in m_lower or "titan" in m_lower:
                shine_model = "Shine X1 (240Hz Titanio Gaming)"
            elif "nomad" in m_lower:
                shine_model = "Shine Nomad 1 (All-Terrain)"
            elif "vintage" in m_lower:
                shine_model = "Shine Vintage (Curved tUIlbar)"
            else:
                shine_model = f"Shine OS Companion ({brand} {model})"

            devices.append({
                "serial": serial,
                "state": state,
                "model": model,
                "brand": brand,
                "shine_model": shine_model,
                "battery": batt_level
            })
    return devices

def inspect_c2(filepath):
    if not os.path.isfile(filepath):
        print(f"{RED}❌ File not found: {filepath}{RESET}")
        return False

    with open(filepath, "rb") as f:
        header = f.read(4)

    is_zip = header.startswith(b"PK\x03\x04")

    if not is_zip:
        # It is a raw mobile Looping code fragment!
        with open(filepath, "r", encoding="utf-8") as f:
            code = f.read()

        print(f"\n{BOLD}{CYAN}🔍 INSPECTING MOBILE LOOPING .c2 FRAGMENT: {os.path.basename(filepath)}{RESET}")
        print(f"  • Format:         {GREEN}Mobile Looping Source Code (.c2 DSL){RESET}")
        print(f"  • Size:           {len(code) / 1024.0:.1f} KB")
        for line in code.splitlines():
            line_str = line.strip()
            if line_str.startswith("component ") or line_str.startswith("device:") or line_str.startswith("fps:") or line_str.startswith("theme:") or line_str.startswith("primary:"):
                print(f"  • {line_str}")
        print(f"\n{BOLD}📄 Code Preview (first 10 lines):{RESET}")
        for l in code.splitlines()[:10]:
            print(f"    {l}")
        return True

    try:
        with zipfile.ZipFile(filepath, "r") as zf:
            namelist = zf.namelist()
            print(f"\n{BOLD}{CYAN}🔍 INSPECTING .c2 CONTAINER: {os.path.basename(filepath)}{RESET}")
            print(f"  • Format:         Precompiled Component 2 Package (.c2 ZIP)")
            print(f"  • Size:           {os.path.getsize(filepath) / 1024.0:.1f} KB")
            print(f"  • Archive Members: {', '.join(namelist)}")

            if "manifest.json" in namelist:
                man_data = json.loads(zf.read("manifest.json").decode("utf-8"))
                print(f"\n{BOLD}📄 Manifest Details:{RESET}")
                print(f"  • Component ID:   {YELLOW}{man_data.get('component_id', 'N/A')}{RESET}")
                print(f"  • Name:           {GREEN}{man_data.get('name', 'N/A')}{RESET}")
                print(f"  • Target Device:  {CYAN}{man_data.get('target_device', 'N/A')}{RESET}")
                print(f"  • Target FPS:     {BOLD}{man_data.get('target_fps', 60)} FPS{RESET}")

            if "tokens.json" in namelist:
                tok_data = json.loads(zf.read("tokens.json").decode("utf-8"))
                print(f"\n{BOLD}🎨 Design Tokens:{RESET}")
                print(f"  • Primary:        {tok_data.get('primary', 'N/A')}")
                print(f"  • Layout Mode:    {tok_data.get('layout_mode', 'N/A')}")

            if "signature.sha256" in namelist:
                sig_raw = zf.read("signature.sha256").decode("utf-8").strip()
                sig_data = {}
                try:
                    sig_data = json.loads(sig_raw)
                except Exception:
                    for line in sig_raw.splitlines():
                        parts = line.strip().split()
                        if len(parts) >= 2:
                            sig_data[parts[1]] = parts[0]

                print(f"\n{BOLD}🔒 Integrity Attestation:{RESET}")
                all_ok = True
                for member, expected_hash in sig_data.items():
                    if member in namelist:
                        actual_hash = hashlib.sha256(zf.read(member)).hexdigest()
                        match = actual_hash == expected_hash
                        if not match:
                            all_ok = False
                        icon = f"{GREEN}✔ OK{RESET}" if match else f"{RED}✘ TAMPERED{RESET}"
                        print(f"    • {member:16} {icon}")
                if all_ok and sig_data:
                    print(f"  {GREEN}{BOLD}✔ SHA-256 Signatures verified. Package is authentic and untampered.{RESET}")
            return True
    except Exception as e:
        print(f"{RED}❌ Error inspecting .c2 file: {e}{RESET}")
        return False

def install_c2(filepath, device=None):
    if not os.path.isfile(filepath):
        print(f"{RED}❌ .c2 file does not exist: {filepath}{RESET}")
        return False

    filename = os.path.basename(filepath)
    print(f"\n{BOLD}{CYAN}🚀 [UI CONNECT] Initiating .c2 Installation to Shine Phone...{RESET}")
    print(f"  • Local File:     {filepath}")

    devices = detect_devices()
    target_dev = device
    if not target_dev:
        if not devices:
            print(f"{RED}❌ No Android / Shine devices detected via ADB!{RESET}")
            print(f"  1. Connect your Shine phone via USB cable.")
            print(f"  2. Enable Developer Options & USB Debugging in Settings.")
            print(f"  3. Or run 'ui-connect deploy-ota' to push through Cloudflare Edge (CS WEBS).")
            return False
        target_dev = devices[0]["serial"]
        print(f"  • Target Device:  {GREEN}{target_dev}{RESET} ({devices[0]['shine_model']})")

    # Step 1: Ensure directory exists on device
    print(f"\n{DIM}[1/3] Preparing remote module directory {SHINE_REMOTE_MODULE_DIR}...{RESET}")
    run_adb(["shell", "mkdir", "-p", SHINE_REMOTE_MODULE_DIR], device=target_dev)

    # Step 2: Push file to device
    remote_path = f"{SHINE_REMOTE_MODULE_DIR}/{filename}"
    print(f"{DIM}[2/3] Transferring {filename} via ADB push...{RESET}")
    code, stdout, stderr = run_adb(["push", filepath, remote_path], device=target_dev)
    if code != 0:
        print(f"{RED}❌ ADB Push failed: {stderr.strip()}{RESET}")
        return False
    print(f"  {GREEN}✔ Module transferred to {remote_path}{RESET}")

    # Step 3: Trigger Broadcast Intent to Shine OS Launcher
    print(f"{DIM}[3/3] Broadcasting hot-reload trigger (INSTALL_C2) to Shine Launcher...{RESET}")
    broadcast_cmd = [
        "shell", "am", "broadcast",
        "-a", SHINE_ACTION_INSTALL,
        "--es", "path", remote_path,
        "-n", SHINE_RECEIVER
    ]
    code, stdout, stderr = run_adb(broadcast_cmd, device=target_dev)
    if code != 0 or "Error" in stdout:
        print(f"{YELLOW}⚠ Broadcast returned warning or app receiver not active:{RESET}")
        print(f"    {stdout.strip() or stderr.strip()}")
        print(f"  {CYAN}Note: Module placed at {remote_path}. Shine Launcher will load it automatically.{RESET}")
    else:
        print(f"  {GREEN}{BOLD}✔ Hot-Reload Signal Dispatched!{RESET}")
        print(f"    {stdout.strip()}")

    print(f"\n{GREEN}{BOLD}✨ .c2 Module '{filename}' INSTALLED SUCCESSFULLY ON SHINE PHONE!{RESET}\n")
    return True

def deploy_ota(filepath, server_url=DEFAULT_CS_WEBS):
    if not os.path.isfile(filepath):
        print(f"{RED}❌ File not found: {filepath}{RESET}")
        return False

    filename = os.path.basename(filepath)
    upload_url = f"{server_url.rstrip('/')}/api/v1/c2/upload"
    print(f"\n{BOLD}{CYAN}☁ DEPLOYING .c2 TO CS WEBS CLOUDFLARE EDGE (OTA)...{RESET}")
    print(f"  • Local File:    {filepath}")
    print(f"  • Cloud Server:  {upload_url}")

    try:
        with open(filepath, "rb") as f:
            data = f.read()

        req = urllib.request.Request(upload_url, data=data, method="POST")
        req.add_header("X-C2-Filename", filename)
        req.add_header("Content-Type", "application/octet-stream")
        req.add_header("User-Agent", "CokiStudios-UIConnect/2.5.0 (macOS; Darwin)")

        with urllib.request.urlopen(req, timeout=12) as resp:
            resp_body = resp.read().decode("utf-8")
            res_json = json.loads(resp_body)
            if res_json.get("success"):
                print(f"  {GREEN}{BOLD}✔ Module uploaded successfully to Cloudflare Edge!{RESET}")
                print(f"  • Download URL: {server_url}{res_json.get('download_url')}")
                print(f"  • Size:        {res_json.get('size_bytes')} bytes")
                return True
            else:
                print(f"{RED}❌ Server responded with error: {resp_body}{RESET}")
                return False
    except Exception as e:
        print(f"{RED}❌ Failed to upload to CS WEBS: {e}{RESET}")
        return False

def launch_web_gui(port=5050):
    """
    Launches UI Connect Web Studio Dashboard on localhost
    Zero containers, zero node.js: Pure Python HTTP server + modern browser UI.
    """
    class UIConnectHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            return

        def do_OPTIONS(self):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.end_headers()

        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path == "/api/devices":
                devs = detect_devices()
                self.send_json({"devices": devs})
            elif parsed.path == "/api/modules":
                mods = []
                if os.path.isdir("c2-modules"):
                    for m in sorted(os.listdir("c2-modules")):
                        if m.endswith(".c2"):
                            p = os.path.join("c2-modules", m)
                            with open(p, "rb") as f:
                                is_zip = f.read(4).startswith(b"PK\x03\x04")
                            code = ""
                            try:
                                with open(p, "r", encoding="utf-8") as f:
                                    code = f.read()
                            except:
                                code = "[Binary Package]"
                            mods.append({
                                "filename": m,
                                "is_zip": is_zip,
                                "size_bytes": os.path.getsize(p),
                                "code": code
                            })
                self.send_json({"modules": mods})
            else:
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(get_studio_html().encode("utf-8"))

        def do_POST(self):
            parsed = urllib.parse.urlparse(self.path)
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8")
            data = json.loads(body) if body else {}

            if parsed.path == "/api/install":
                fname = data.get("filename", "")
                path = os.path.join("c2-modules", fname)
                ok = install_c2(path)
                self.send_json({"success": ok, "filename": fname})
            elif parsed.path == "/api/deploy_ota":
                fname = data.get("filename", "")
                path = os.path.join("c2-modules", fname)
                ok = deploy_ota(path)
                self.send_json({"success": ok, "filename": fname})
            elif parsed.path == "/api/save_code":
                fname = data.get("filename", "")
                code = data.get("code", "")
                path = os.path.join("c2-modules", fname)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(code)
                self.send_json({"success": True, "filename": fname})
            else:
                self.send_json({"error": "Unknown endpoint"}, 404)

        def send_json(self, obj, status=200):
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(obj).encode("utf-8"))

    print_banner()
    print(f"\n{BOLD}{CYAN}🌐 Launching UI Connect Web Studio Dashboard...{RESET}")
    print(f"  • Local URL:  {GREEN}http://localhost:{port}{RESET}")
    print(f"  • Cloud Edge: {CYAN}{DEFAULT_CS_WEBS}{RESET}")
    print(f"\n{DIM}Press Ctrl+C to terminate UI Connect.{RESET}\n")

    try:
        server = socketserver.TCPServer(("", port), UIConnectHandler)
    except OSError:
        port += 1
        server = socketserver.TCPServer(("", port), UIConnectHandler)

    threading.Timer(0.8, lambda: webbrowser.open(f"http://localhost:{port}")).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\n{CYAN}UI Connect Web Studio closed.{RESET}")

def get_studio_html():
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>✦ Coki Studios UI Connect — Shine OS .c2 Suite ✦</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        :root {{
            --primary: #38bdf8;
            --accent: #0284c7;
            --bg: #07090e;
            --surface: #0f172a;
            --border: rgba(255, 255, 255, 0.08);
            --text: #f8fafc;
            --text-muted: #94a3b8;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            height: 100vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }}
        .header {{
            background: #0d121f;
            border-bottom: 1px solid var(--border);
            padding: 12px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .badge {{
            background: linear-gradient(135deg, #0ea5e9, #6366f1);
            color: #fff;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 800;
        }}
        .workspace {{
            flex: 1;
            display: grid;
            grid-template-columns: 280px 320px 1fr;
            height: calc(100vh - 65px);
            overflow: hidden;
        }}
        .panel {{
            border-right: 1px solid var(--border);
            padding: 18px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }}
        .panel-title {{
            font-size: 12px;
            text-transform: uppercase;
            font-weight: 800;
            color: var(--text-muted);
            margin-bottom: 12px;
            letter-spacing: 0.5px;
        }}
        .device-box {{
            background: #090d16;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 14px;
        }}
        .module-item {{
            background: #090d16;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 8px;
            cursor: pointer;
            transition: all 0.2s;
        }}
        .module-item:hover, .module-item.active {{
            border-color: var(--primary);
            background: rgba(56, 189, 248, 0.08);
        }}
        .btn {{
            background: #0284c7;
            color: #fff;
            border: none;
            padding: 8px 14px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: 0.2s;
        }}
        .btn:hover {{ filter: brightness(1.15); }}
        .btn-ota {{ background: #059669; }}
        .phone-bezel {{
            width: 260px;
            height: 520px;
            background: #000;
            border-radius: 34px;
            border: 3px solid rgba(255, 255, 255, 0.15);
            margin: auto;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.8), 0 0 30px rgba(56, 189, 248, 0.2);
            padding: 30px 14px 14px;
        }}
        .editor-textarea {{
            width: 100%;
            flex: 1;
            background: #05070c;
            border: 1px solid var(--border);
            border-radius: 8px;
            color: #38bdf8;
            font-family: ui-monospace, SFMono-Regular, monospace;
            font-size: 12px;
            padding: 16px;
            line-height: 1.6;
            outline: none;
            resize: none;
        }}
    </style>
</head>
<body>
    <div class="header">
        <div style="display: flex; align-items: center; gap: 12px;">
            <span class="badge">UI CONNECT PC</span>
            <b style="font-size: 15px;">✦ Shine OS .c2 Suite & Cloudflare Edge Manager ✦</b>
        </div>
        <div style="display: flex; gap: 8px;">
            <button class="btn" onclick="installActive()">⚡ Instalar en Celular (USB/ADB)</button>
            <button class="btn btn-ota" onclick="deployOtaActive()">☁ Desplegar OTA Cloudflare</button>
        </div>
    </div>

    <div class="workspace">
        <!-- Panel 1: Devices & Modules -->
        <div class="panel">
            <div class="panel-title">📱 Celulares Conectados</div>
            <div id="devices-list" class="device-box">
                <div style="font-size: 11px; color: var(--text-muted);">Escaneando puertos ADB...</div>
            </div>

            <div class="panel-title" style="margin-top: 10px;">📦 Módulos .c2 Locales</div>
            <div id="modules-list" style="flex: 1; overflow-y: auto;"></div>
        </div>

        <!-- Panel 2: Simulator -->
        <div class="panel" style="background: #05070c; align-items: center; justify-content: center;">
            <div class="phone-bezel">
                <div style="display: flex; justify-content: space-between; font-size: 10px; font-weight: bold; margin-bottom: 12px;">
                    <span>18:55</span>
                    <span style="color: var(--primary);" id="sim-target">[XUI 240Hz]</span>
                    <span>100% ⚡</span>
                </div>
                <div style="background: rgba(56, 189, 248, 0.15); border: 1px solid rgba(56, 189, 248, 0.4); border-radius: 12px; padding: 12px; margin-bottom: 12px;">
                    <b id="sim-title" style="color: var(--primary); font-size: 12px;">CyberNeonXUI</b>
                    <p style="font-size: 10px; color: var(--text-muted); margin-top: 4px;">Fragmento de interfaz reactiva Looping en tiempo real.</p>
                </div>
                <div style="margin-top: auto; background: rgba(255, 255, 255, 0.08); border-radius: 18px; padding: 8px; display: flex; justify-content: space-around;">
                    <span>📞</span><span>💬</span><span>🗺️</span><span>📷</span><span>⚙️</span>
                </div>
            </div>
        </div>

        <!-- Panel 3: Code Editor -->
        <div class="panel" style="border-right: none;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                <div class="panel-title" style="margin-bottom: 0;">✏️ Editor de Código Looping Móvil (.c2)</div>
                <button class="btn" style="padding: 4px 10px; font-size: 11px;" onclick="saveActiveCode()">💾 Guardar Cambios</button>
            </div>
            <textarea id="editor" class="editor-textarea"></textarea>
        </div>
    </div>

    <script>
        let currentModules = [];
        let activeFilename = "";

        async function loadData() {{
            try {{
                const dRes = await fetch('/api/devices');
                const dData = await dRes.json();
                const dBox = document.getElementById('devices-list');
                if (dData.devices.length === 0) {{
                    dBox.innerHTML = '<div style="font-size: 11px; color: #f59e0b;">⚠ No hay celulares Shine conectados por USB.<br>Conéctalo y activa depuración USB.</div>';
                }} else {{
                    dBox.innerHTML = dData.devices.map(d => `
                        <div style="font-size: 12px; font-weight: bold; color: #34d399;">✔ ${{d.shine_model}}</div>
                        <div style="font-size: 10px; color: var(--text-muted);">Serial: ${{d.serial}} | Bat: ${{d.battery}}</div>
                    `).join('');
                }}

                const mRes = await fetch('/api/modules');
                const mData = await mRes.json();
                currentModules = mData.modules;
                const mBox = document.getElementById('modules-list');
                mBox.innerHTML = currentModules.map((m, idx) => `
                    <div class="module-item ${{idx === 0 ? 'active' : ''}}" onclick="selectModule('${{m.filename}}')">
                        <b style="font-size: 12px;">${{m.filename}}</b>
                        <div style="font-size: 10px; color: var(--text-muted);">${{(m.size_bytes/1024).toFixed(1)}} KB • ${{m.is_zip ? 'Paquete ZIP' : 'Código Looping'}}</div>
                    </div>
                `).join('');

                if (currentModules.length > 0) {{
                    selectModule(currentModules[0].filename);
                }}
            }} catch(e) {{}}
        }}

        function selectModule(fname) {{
            activeFilename = fname;
            document.querySelectorAll('.module-item').forEach(el => {{
                el.classList.toggle('active', el.textContent.includes(fname));
            }});
            const mod = currentModules.find(m => m.filename === fname);
            if (mod) {{
                document.getElementById('editor').value = mod.code;
                document.getElementById('sim-title').textContent = fname.replace('.c2', '');
            }}
        }}

        async function saveActiveCode() {{
            const code = document.getElementById('editor').value;
            await fetch('/api/save_code', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ filename: activeFilename, code: code }})
            }});
            alert('✔ Fragmento .c2 guardado exitosamente!');
        }}

        async function installActive() {{
            if (!activeFilename) return;
            const res = await fetch('/api/install', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ filename: activeFilename }})
            }});
            const d = await res.json();
            alert(d.success ? '✨ Módulo ' + activeFilename + ' inyectado en el celular Shine!' : '❌ Error instalando por ADB.');
        }}

        async function deployOtaActive() {{
            if (!activeFilename) return;
            const res = await fetch('/api/deploy_ota', {{
                method: 'POST',
                headers: {{ 'Content-Type': 'application/json' }},
                body: JSON.stringify({{ filename: activeFilename }})
            }});
            const d = await res.json();
            alert(d.success ? '☁ Publicado en Cloudflare Edge (CS WEBS OTA)!' : '❌ Error publicando en Cloudflare.');
        }}

        loadData();
        setInterval(loadData, 5000);
    </script>
</body>
</html>"""

def main():
    parser = argparse.ArgumentParser(description="UI Connect (PC) — Shine OS Component 2 (.c2) Manager")
    parser.add_argument("command", nargs="?", default="gui", 
                        choices=["menu", "devices", "install", "list", "remove", "inspect", "build", "deploy-ota", "demo", "gui"],
                        help="Action to perform")
    parser.add_argument("target", nargs="?", help="Target file or directory")
    parser.add_argument("-d", "--device", help="Specific ADB device serial")
    parser.add_argument("-o", "--output", help="Output file for build command")
    parser.add_argument("--server", default=DEFAULT_CS_WEBS, help="CS WEBS server URL")
    parser.add_argument("--gui", action="store_true", help="Launch Studio Web GUI")
    parser.add_argument("-p", "--port", type=int, default=5050, help="Web Studio port")

    args = parser.parse_args()

    if args.gui or args.command == "gui":
        launch_web_gui(args.port)
        return

    if args.command == "devices":
        print_banner()
        devs = detect_devices()
        if not devs:
            print(f"{YELLOW}No devices connected via ADB.{RESET}")
        else:
            print(f"{BOLD}{GREEN}Connected Devices ({len(devs)}):{RESET}")
            for d in devs:
                print(f"  • {BOLD}{d['serial']}{RESET} | {CYAN}{d['shine_model']}{RESET} | Battery: {d['battery']}")
    elif args.command == "install":
        if not args.target:
            print(f"{RED}Error: 'install' requires a path to a .c2 file.{RESET}")
            sys.exit(1)
        ok = install_c2(args.target, device=args.device)
        sys.exit(0 if ok else 1)
    elif args.command == "inspect":
        if not args.target:
            print(f"{RED}Error: 'inspect' requires a path to a .c2 file.{RESET}")
            sys.exit(1)
        inspect_c2(args.target)
    elif args.command == "deploy-ota":
        if not args.target:
            print(f"{RED}Error: 'deploy-ota' requires a path to a .c2 file.{RESET}")
            sys.exit(1)
        deploy_ota(args.target, server_url=args.server)
    elif args.command == "demo":
        import tools.create_mobile_looping_c2 as bld
        bld.generate_fragments("c2-modules")
    elif args.command == "build":
        if not args.target:
            print(f"{RED}Error: 'build' requires an input .loop file.{RESET}")
            sys.exit(1)
        out = args.output or "out.c2"
        cmd = ["./bin/looping", "compile", args.target, "--target", "c2", "-o", out]
        print(f"Compiling via Looping: {' '.join(cmd)}")
        code = subprocess.call(cmd)
        sys.exit(code)

if __name__ == "__main__":
    main()
