const vscode = require('vscode');
const path = require('path');
const fs = require('fs');
const cp = require('child_process');

/**
 * C2EditorProvider — Visual Inspector & Live Mobile Looping Editor for .c2 (Component 2) files.
 * Supports both:
 * 1. Plain text .c2 files: Mobile Looping code fragments (declarative UI components).
 * 2. Bundled .c2 packages: Signed ZIP containers.
 */
class C2EditorProvider {
    static register(context) {
        const provider = new C2EditorProvider(context);
        return vscode.window.registerCustomEditorProvider(
            'c2.viewer',
            provider,
            {
                webviewOptions: {
                    retainContextWhenHidden: true
                },
                supportsMultipleEditorsPerDocument: false
            }
        );
    }

    constructor(context) {
        this.context = context;
    }

    async openCustomDocument(uri, openContext, token) {
        return {
            uri,
            dispose: () => {}
        };
    }

    async resolveCustomEditor(document, webviewPanel, token) {
        webviewPanel.webview.options = {
            enableScripts: true,
            localResourceRoots: [
                vscode.Uri.file(this.context.extensionPath)
            ]
        };

        const filePath = document.uri.fsPath;
        const filename = path.basename(filePath);

        const render = async () => {
            try {
                const pkgData = await this.readC2(filePath);
                webviewPanel.webview.html = this.getHtmlForWebview(webviewPanel.webview, filename, filePath, pkgData);
            } catch (err) {
                webviewPanel.webview.html = this.getErrorHtml(filename, err.message);
            }
        };

        // Handle messages from the webview
        webviewPanel.webview.onDidReceiveMessage(async (msg) => {
            switch (msg.command) {
                case 'saveCode':
                    try {
                        if (msg.isRawCode) {
                            fs.writeFileSync(filePath, msg.code, 'utf8');
                            vscode.window.showInformationMessage(`✔ Fragmento de código Looping guardado en ${filename}!`);
                        } else {
                            // Save updated file inside package
                            await this.updatePackageFile(filePath, msg.subfile, msg.code);
                            vscode.window.showInformationMessage(`✔ Archivo ${msg.subfile} actualizado en paquete ${filename}!`);
                        }
                        await render();
                    } catch (e) {
                        vscode.window.showErrorMessage(`❌ Error al guardar: ${e.message}`);
                    }
                    break;
                case 'installToPhone':
                    await this.installToPhone(filePath, msg.device);
                    break;
                case 'deployOta':
                    await this.deployOta(filePath);
                    break;
                case 'extractPackage':
                    await this.extractPackage(filePath);
                    break;
                case 'reload':
                    await render();
                    break;
            }
        }, null, this.context.subscriptions);

        await render();
    }

    /**
     * Reads either a raw mobile Looping .c2 fragment or a zip container
     */
    async readC2(filePath) {
        if (!fs.existsSync(filePath)) {
            throw new Error(`Archivo no encontrado: ${filePath}`);
        }

        const buf = fs.readFileSync(filePath);
        const isZip = buf.length >= 4 && buf[0] === 0x50 && buf[1] === 0x4B && buf[2] === 0x03 && buf[3] === 0x04;

        if (!isZip) {
            // It's a raw mobile Looping code fragment!
            const rawCode = buf.toString('utf8');
            return this.parseLoopingMobileFragment(rawCode, filePath);
        }

        // It's a ZIP package
        return new Promise((resolve, reject) => {
            const pyScript = `
import zipfile, json, sys, hashlib, os
path = sys.argv[1]
try:
    with zipfile.ZipFile(path, 'r') as z:
        files = {}
        hashes = {}
        for n in z.namelist():
            raw = z.read(n)
            hashes[n] = hashlib.sha256(raw).hexdigest()
            try:
                files[n] = raw.decode('utf-8')
            except Exception:
                files[n] = f"[Binary data: {len(raw)} bytes]"
        size_bytes = os.path.getsize(path)
        print(json.dumps({'success': True, 'isRawCode': False, 'names': z.namelist(), 'files': files, 'hashes': hashes, 'size_bytes': size_bytes}))
except Exception as e:
    print(json.dumps({'success': False, 'error': str(e)}))
`;
            cp.execFile('python3', ['-c', pyScript, filePath], (err, stdout, stderr) => {
                if (!err && stdout) {
                    try {
                        const parsed = JSON.parse(stdout);
                        if (parsed.success) return resolve(parsed);
                    } catch (e) {}
                }
                reject(new Error(stderr || 'Error al inspeccionar paquete .c2'));
            });
        });
    }

    /**
     * Parses a mobile Looping code fragment into a virtual component structure
     */
    parseLoopingMobileFragment(code, filePath) {
        const nameMatch = code.match(/component\s+["'](.*?)["']/);
        const targetMatch = code.match(/target\s+["'](.*?)["']/);
        const deviceMatch = code.match(/device:\s*["'](.*?)["']/);
        const fpsMatch = code.match(/fps:\s*(\d+)/);
        const primaryMatch = code.match(/primary:\s*["'](.*?)["']/);
        const accentMatch = code.match(/accent:\s*["'](.*?)["']/);
        const bgMatch = code.match(/background:\s*["'](.*?)["']/);
        const surfMatch = code.match(/surface:\s*["'](.*?)["']/);
        const radiusMatch = code.match(/corner_radius:\s*(\d+)/);
        const elevMatch = code.match(/elevation:\s*(\d+)/);

        const compName = nameMatch ? nameMatch[1] : path.basename(filePath, '.c2');
        const targetFamily = targetMatch ? targetMatch[1] : 'xui';
        const targetDevice = deviceMatch ? deviceMatch[1] : 'Shine Smartphone';
        const targetFps = fpsMatch ? parseInt(fpsMatch[1]) : 120;
        const primaryColor = primaryMatch ? primaryMatch[1] : '#38bdf8';
        const accentColor = accentMatch ? accentMatch[1] : '#0284c7';
        const bg = bgMatch ? bgMatch[1] : '#07090e';
        const surf = surfMatch ? surfMatch[1] : 'rgba(15, 23, 42, 0.85)';
        const radius = radiusMatch ? parseInt(radiusMatch[1]) : 16;
        const elevation = elevMatch ? parseInt(elevMatch[1]) : 8;

        // Parse draw statements into UI components
        const components = [];
        const lines = code.split('\n');
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed.startsWith('draw status_pill')) {
                const textM = trimmed.match(/text\s+["'](.*?)["']/);
                components.push({
                    id: 'status_pill',
                    type: 'status_pill',
                    title: textM ? textM[1] : 'STATUS ACTIVE'
                });
            } else if (trimmed.startsWith('draw card')) {
                const titleM = trimmed.match(/title\s+["'](.*?)["']/);
                components.push({
                    id: 'card_' + (components.length + 1),
                    type: 'card',
                    title: titleM ? titleM[1] : 'MÓDULO REACTIVO'
                });
            } else if (trimmed.startsWith('draw dock')) {
                const appsM = trimmed.match(/apps\s+\[(.*?)\]/);
                const apps = appsM ? appsM[1].split(',').map(s => s.trim().replace(/['"]/g, '')) : ['phone', 'messages', 'shinemaps', 'camera', 'settings'];
                components.push({
                    id: 'mobile_dock',
                    type: 'dock',
                    apps
                });
            }
        }

        const manifest = {
            c2_version: "2.0 (Mobile Looping Fragment)",
            component_id: `com.cokistudios.c2.${compName.toLowerCase()}`,
            name: compName,
            author: "Coki Studios Mobile Developer",
            target_device: targetDevice,
            target_family: targetFamily,
            target_fps: targetFps,
            primary_color: primaryColor,
            accent_color: accentColor,
            entrypoint: path.basename(filePath)
        };

        const tokens = {
            primary: primaryColor,
            accent: accentColor,
            background: bg,
            surface: surf,
            fps: targetFps,
            corner_radius: radius,
            elevation_dp: elevation,
            layout_mode: `Looping Mobile UI DSL (${targetFamily.toUpperCase()})`
        };

        const layout = {
            version: "2.0",
            type: "modular_surface",
            title: compName,
            components
        };

        return {
            success: true,
            isRawCode: true,
            rawCode: code,
            size_bytes: Buffer.byteLength(code, 'utf8'),
            names: [path.basename(filePath)],
            files: {
                [path.basename(filePath)]: code,
                'manifest.json': JSON.stringify(manifest, null, 2),
                'tokens.json': JSON.stringify(tokens, null, 2),
                'layout.json': JSON.stringify(layout, null, 2),
                'source.loop': code,
                'signature.sha256': JSON.stringify({ "source.loop": "LIVE_SOURCE_FRAGMENT" }, null, 2)
            },
            hashes: {}
        };
    }

    async updatePackageFile(filePath, subfileName, newContent) {
        const pyScript = `
import zipfile, sys
pkg = sys.argv[1]
subf = sys.argv[2]
content = sys.argv[3]

with zipfile.ZipFile(pkg, 'r') as z_in:
    files = {n: z_in.read(n) for n in z_in.namelist()}

files[subf] = content.encode('utf-8')

with zipfile.ZipFile(pkg, 'w', zipfile.ZIP_DEFLATED) as z_out:
    for n, data in files.items():
        z_out.writestr(n, data)
print("OK")
`;
        return new Promise((resolve, reject) => {
            cp.execFile('python3', ['-c', pyScript, filePath, subfileName, newContent], (err, stdout) => {
                if (err) return reject(err);
                resolve();
            });
        });
    }

    async installToPhone(filePath, device) {
        const root = this.getWorkspaceRoot();
        const uiConnect = path.join(root, 'bin', 'ui-connect');
        const cmd = `"${uiConnect}" install "${filePath}"`;

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `UI Connect: Instalando fragmento ${path.basename(filePath)} en Shine Phone...`,
            cancellable: false
        }, () => {
            return new Promise((resolve) => {
                cp.exec(cmd, { cwd: root }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`❌ Error instalando en celular Shine: ${stderr || error.message}`);
                    } else {
                        vscode.window.showInformationMessage(`✨ Módulo '${path.basename(filePath)}' inyectado en caliente en el celular Shine!`);
                    }
                    resolve();
                });
            });
        });
    }

    async deployOta(filePath) {
        const root = this.getWorkspaceRoot();
        const uiConnect = path.join(root, 'bin', 'ui-connect');
        const cmd = `"${uiConnect}" deploy-ota "${filePath}"`;

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `CS WEBS Cloudflare: Desplegando ${path.basename(filePath)} a la nube (OTA)...`,
            cancellable: false
        }, () => {
            return new Promise((resolve) => {
                cp.exec(cmd, { cwd: root }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`❌ Error desplegando a CS WEBS Cloudflare: ${stderr || error.message}`);
                    } else {
                        vscode.window.showInformationMessage(`☁ Módulo '${path.basename(filePath)}' publicado en Cloudflare Edge (webs.cokistudios.com)!`);
                    }
                    resolve();
                });
            });
        });
    }

    async extractPackage(filePath) {
        const outDir = path.join(path.dirname(filePath), path.basename(filePath, '.c2') + '_extracted');
        fs.mkdirSync(outDir, { recursive: true });
        cp.exec(`unzip -o "${filePath}" -d "${outDir}"`, (error) => {
            if (error) {
                vscode.window.showErrorMessage(`❌ Error al extraer: ${error.message}`);
            } else {
                vscode.window.showInformationMessage(`📂 Módulo extraído en: ${outDir}`);
            }
        });
    }

    getWorkspaceRoot() {
        return vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0]
            ? vscode.workspace.workspaceFolders[0].uri.fsPath
            : process.cwd();
    }

    getErrorHtml(filename, errorMsg) {
        return `<!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { background: #0b0f19; color: #f8fafc; font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
                .box { background: #111827; border: 1px solid #ef4444; border-radius: 12px; padding: 24px; max-width: 500px; text-align: center; }
                h2 { color: #ef4444; margin-top: 0; }
                p { color: #94a3b8; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="box">
                <h2>❌ Error Abriendo ${filename}</h2>
                <p>${errorMsg}</p>
            </div>
        </body>
        </html>`;
    }

    getHtmlForWebview(webview, filename, filePath, pkg) {
        let manifest = {};
        let tokens = {};
        let layout = {};
        let signatures = {};

        try { manifest = JSON.parse(pkg.files['manifest.json'] || '{}'); } catch(e){}
        try { tokens = JSON.parse(pkg.files['tokens.json'] || '{}'); } catch(e){}
        try { layout = JSON.parse(pkg.files['layout.json'] || '{}'); } catch(e){}
        try { signatures = JSON.parse(pkg.files['signature.sha256'] || '{}'); } catch(e){}

        const primaryColor = tokens.primary || manifest.primary_color || '#38bdf8';
        const accentColor = tokens.accent || manifest.accent_color || '#0284c7';
        const targetFamily = manifest.target_family || 'xui';
        const targetDevice = manifest.target_device || 'Shine Phone';
        const targetFps = tokens.fps || manifest.target_fps || 60;
        const moduleName = manifest.name || filename.replace('.c2', '');
        const componentId = manifest.component_id || 'com.cokistudios.c2.module';
        const layoutMode = tokens.layout_mode || 'Fragmento de Código Looping Móvil';
        const sizeFormatted = (pkg.size_bytes / 1024.0).toFixed(1) + ' KB';
        const isRawCode = !!pkg.isRawCode;
        const mainSourceCode = isRawCode ? pkg.rawCode : (pkg.files['source.loop'] || pkg.files[filename] || '');

        const comps = layout.components || [];

        return `<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${moduleName} — Visual Inspector</title>
    <style>
        :root {
            --primary: ${primaryColor};
            --accent: ${accentColor};
            --bg: #070a12;
            --surface: #0f172a;
            --border: rgba(255, 255, 255, 0.08);
            --text: #f8fafc;
            --text-muted: #94a3b8;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background-color: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
            height: 100vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            font-size: 13px;
        }

        .header {
            background: rgba(15, 23, 42, 0.95);
            border-bottom: 1px solid var(--border);
            padding: 10px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            backdrop-filter: blur(16px);
            z-index: 10;
        }

        .header-title-box {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .c2-badge {
            background: linear-gradient(135deg, var(--primary), var(--accent));
            color: #000;
            font-weight: 900;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 11px;
            letter-spacing: 0.5px;
            box-shadow: 0 0 12px ${primaryColor}40;
        }

        .module-title {
            font-size: 15px;
            font-weight: 700;
            color: #ffffff;
        }

        .module-id {
            color: var(--text-muted);
            font-size: 11px;
            font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn {
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid var(--border);
            color: #ffffff;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn:hover {
            background: rgba(255, 255, 255, 0.12);
            border-color: rgba(255, 255, 255, 0.2);
            transform: translateY(-1px);
        }

        .btn-primary {
            background: var(--primary);
            color: #07090e;
            border: none;
            box-shadow: 0 0 14px ${primaryColor}50;
        }

        .btn-ota {
            background: #059669;
            color: white;
            border: none;
        }

        .workspace {
            flex: 1;
            display: grid;
            grid-template-columns: 330px 1fr;
            height: calc(100vh - 60px);
            overflow: hidden;
        }

        .simulator-pane {
            background: #05070c;
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 16px;
            overflow-y: auto;
        }

        .phone-bezel {
            width: 270px;
            height: 550px;
            background: #000000;
            border-radius: 36px;
            border: 3px solid rgba(255, 255, 255, 0.15);
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.8), 0 0 30px ${primaryColor}20;
            position: relative;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .phone-notch {
            position: absolute;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            width: 80px;
            height: 18px;
            background: #000;
            border-radius: 20px;
            z-index: 100;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .phone-camera {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #111;
            border: 1px solid #333;
        }

        .phone-screen {
            flex: 1;
            background: ${tokens.background || '#07090e'};
            display: flex;
            flex-direction: column;
            padding: 34px 14px 14px;
            color: ${tokens.text || '#f8fafc'};
            position: relative;
        }

        .phone-status-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 10px;
            font-weight: 700;
            opacity: 0.8;
            margin-bottom: 12px;
        }

        .surface-card {
            background: ${tokens.surface || 'rgba(15, 23, 42, 0.85)'};
            border-radius: ${tokens.corner_radius || 16}px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 12px;
            margin-bottom: 10px;
            box-shadow: 0 ${tokens.elevation_dp || 4}px 12px rgba(0, 0, 0, 0.4);
        }

        .surface-card-title {
            font-size: 11px;
            font-weight: 700;
            color: ${primaryColor};
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .phone-dock {
            margin-top: auto;
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(12px);
            border-radius: 20px;
            padding: 8px 10px;
            display: flex;
            justify-content: space-around;
            align-items: center;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .dock-app-icon {
            width: 32px;
            height: 32px;
            border-radius: 10px;
            background: rgba(255, 255, 255, 0.12);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            cursor: pointer;
        }

        .tuilbar-curved {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 48px;
            background: #140e05;
            border-top: 2px solid ${primaryColor};
            border-radius: 20px 20px 0 0;
            display: flex;
            align-items: center;
            justify-content: space-around;
            font-family: monospace;
            font-size: 11px;
            color: ${primaryColor};
            font-weight: bold;
        }

        .inspector-pane {
            display: flex;
            flex-direction: column;
            background: #090d16;
            overflow: hidden;
        }

        .tab-bar {
            display: flex;
            background: #0d121f;
            border-bottom: 1px solid var(--border);
            padding: 0 16px;
        }

        .tab {
            padding: 12px 18px;
            font-size: 12px;
            font-weight: 600;
            color: var(--text-muted);
            cursor: pointer;
            border-bottom: 2px solid transparent;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .tab.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
        }

        .tab-content {
            flex: 1;
            padding: 18px;
            overflow-y: auto;
            display: none;
        }

        .tab-content.active {
            display: flex;
            flex-direction: column;
        }

        .editor-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .code-textarea {
            width: 100%;
            flex: 1;
            min-height: 400px;
            background: #05070c;
            border: 1px solid var(--border);
            border-radius: 8px;
            color: #38bdf8;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
            font-size: 12px;
            line-height: 1.6;
            padding: 14px;
            resize: none;
            outline: none;
        }

        .code-textarea:focus {
            border-color: var(--primary);
            box-shadow: 0 0 10px ${primaryColor}30;
        }

        .editor-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .file-subtabs {
            display: flex;
            gap: 6px;
            margin-bottom: 12px;
        }

        .file-pill {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border);
            color: var(--text-muted);
            padding: 4px 12px;
            border-radius: 6px;
            font-size: 11px;
            font-family: monospace;
            cursor: pointer;
        }

        .file-pill.active {
            background: ${primaryColor}20;
            color: var(--primary);
            border-color: ${primaryColor}60;
            font-weight: 700;
        }

        pre.code-view {
            background: #05070c;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 14px;
            font-family: ui-monospace, monospace;
            font-size: 12px;
            line-height: 1.5;
            color: #e2e8f0;
            overflow-x: auto;
            max-height: calc(100vh - 240px);
        }
    </style>
</head>
<body>

    <div class="header">
        <div class="header-title-box">
            <span class="c2-badge">${isRawCode ? '.C2 LOOP SOURCE' : '.C2 PACKAGE'}</span>
            <div>
                <div class="module-title">${moduleName} <span style="font-size: 12px; color: ${primaryColor};">(${sizeFormatted})</span></div>
                <div class="module-id">${componentId} • ${targetDevice} (${targetFps} FPS)</div>
            </div>
        </div>
        <div class="header-actions">
            <button class="btn btn-primary" onclick="installToShine()">⚡ Instalar en Celular Shine (USB)</button>
            <button class="btn btn-ota" onclick="deployOta()">☁ Desplegar en Cloudflare Edge (OTA)</button>
            ${!isRawCode ? `<button class="btn" onclick="extractPackage()">📂 Extraer .zip</button>` : ''}
        </div>
    </div>

    <div class="workspace">
        
        <!-- Left: Phone Simulator -->
        <div class="simulator-pane">
            <div class="phone-bezel">
                <div class="phone-notch"><div class="phone-camera"></div></div>
                <div class="phone-screen">
                    <div class="phone-status-bar">
                        <span>18:55</span>
                        <span style="font-size: 9px; font-weight: 800; color: ${primaryColor};">[${targetFamily.toUpperCase()}]</span>
                        <span>100% ⚡</span>
                    </div>

                    <div style="background: ${primaryColor}20; border: 1px solid ${primaryColor}60; border-radius: 20px; padding: 4px 10px; font-size: 9px; font-weight: bold; color: ${primaryColor}; text-align: center; margin-bottom: 12px;">
                        ● SHINE OS • ${targetFps} FPS LOCKED
                    </div>

                    <div class="surface-card">
                        <div class="surface-card-title">
                            <span>${moduleName}</span>
                            <span style="font-size: 9px; opacity: 0.8;">v2.0</span>
                        </div>
                        <div style="font-size: 10px; color: ${tokens.text_muted || '#94a3b8'};">
                            ${layoutMode}
                        </div>
                    </div>

                    ${comps.map(c => `
                        <div class="surface-card" style="padding: 8px 12px; margin-bottom: 8px;">
                            <div class="surface-card-title" style="font-size: 10px;">
                                <span>[${c.type || 'widget'}] ${c.id || ''}</span>
                            </div>
                            <div style="font-size: 9px; color: ${tokens.text_muted || '#94a3b8'};">
                                ${c.title || c.source || 'Componente Activo'}
                            </div>
                        </div>
                    `).join('')}

                    ${targetFamily === 'vintage' ? `
                        <div class="tuilbar-curved">
                            <span>[1] TEL</span>
                            <span>[2] MAPS</span>
                            <span>[3] CHAT</span>
                            <span>[4] MENU</span>
                        </div>
                    ` : `
                        <div class="phone-dock">
                            <div class="dock-app-icon">📞</div>
                            <div class="dock-app-icon">💬</div>
                            <div class="dock-app-icon">🗺️</div>
                            <div class="dock-app-icon">📷</div>
                            <div class="dock-app-icon">⚙️</div>
                        </div>
                    `}
                </div>
            </div>
        </div>

        <!-- Right: Inspector & Live Editor -->
        <div class="inspector-pane">
            <div class="tab-bar">
                <div class="tab active" onclick="switchTab('editor')">✏️ Código Looping (.c2)</div>
                <div class="tab" onclick="switchTab('files')">📄 Archivos del Componente</div>
                <div class="tab" onclick="switchTab('tokens')">🎨 Design Tokens</div>
            </div>

            <!-- Tab 1: Live Looping Editor -->
            <div id="tab-editor" class="tab-content active">
                <div class="editor-container">
                    <div class="editor-toolbar">
                        <span style="font-size: 12px; color: var(--text-muted);">
                            Fragmento de Código Looping Móvil — <b>${filename}</b>
                        </span>
                        <div>
                            <button class="btn btn-primary" onclick="saveActiveCode()">💾 Guardar y Aplicar</button>
                        </div>
                    </div>
                    <textarea class="code-textarea" id="main-code-editor">${escapeHtml(mainSourceCode)}</textarea>
                </div>
            </div>

            <!-- Tab 2: Package Files -->
            <div id="tab-files" class="tab-content">
                <div class="file-subtabs">
                    ${Object.keys(pkg.files).map((name, i) => `
                        <span class="file-pill ${i === 0 ? 'active' : ''}" onclick="showFile('${name}')">${name}</span>
                    `).join('')}
                </div>
                <pre class="code-view" id="code-display">${escapeHtml(pkg.files[Object.keys(pkg.files)[0]] || '')}</pre>
            </div>

            <!-- Tab 3: Tokens -->
            <div id="tab-tokens" class="tab-content">
                <h3 style="font-size: 14px; margin-bottom: 12px; color: #fff;">Paleta de Color</h3>
                <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; margin-bottom: 20px;">
                    <div style="background: #0f172a; padding: 12px; border-radius: 8px; border: 1px solid var(--border); display: flex; align-items: center; gap: 10px;">
                        <div style="width: 32px; height: 32px; border-radius: 6px; background: ${primaryColor};"></div>
                        <div>
                            <div style="font-size: 10px; color: var(--text-muted);">PRIMARY</div>
                            <div style="font-weight: bold; font-family: monospace;">${primaryColor}</div>
                        </div>
                    </div>
                    <div style="background: #0f172a; padding: 12px; border-radius: 8px; border: 1px solid var(--border); display: flex; align-items: center; gap: 10px;">
                        <div style="width: 32px; height: 32px; border-radius: 6px; background: ${accentColor};"></div>
                        <div>
                            <div style="font-size: 10px; color: var(--text-muted);">ACCENT</div>
                            <div style="font-weight: bold; font-family: monospace;">${accentColor}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const vscode = acquireVsCodeApi();
        const files = ${JSON.stringify(pkg.files)};
        const isRawCode = ${isRawCode};

        function switchTab(tabId) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById('tab-' + tabId).classList.add('active');
        }

        function showFile(filename) {
            document.querySelectorAll('.file-pill').forEach(p => p.classList.remove('active'));
            event.target.classList.add('active');
            const code = files[filename] || '// Archivo no encontrado';
            document.getElementById('code-display').textContent = code;
        }

        function saveActiveCode() {
            const code = document.getElementById('main-code-editor').value;
            vscode.postMessage({
                command: 'saveCode',
                isRawCode: isRawCode,
                subfile: isRawCode ? '' : 'source.loop',
                code: code
            });
        }

        function installToShine() {
            vscode.postMessage({ command: 'installToPhone' });
        }

        function deployOta() {
            vscode.postMessage({ command: 'deployOta' });
        }

        function extractPackage() {
            vscode.postMessage({ command: 'extractPackage' });
        }
    </script>
</body>
</html>`;
    }
}

function escapeHtml(text) {
    return text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

module.exports = {
    C2EditorProvider
};
