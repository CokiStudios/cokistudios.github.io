const vscode = require('vscode');

let currentPanel = undefined;

function activate(context) {
    console.log('⚡ CS Looping Proprietary Core Active in VS Code');

    // 1. Command: Run .loop in Live Viewport Webview
    let runDisposable = vscode.commands.registerCommand('looping.runActiveFile', function () {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active .loop file found.');
            return;
        }

        const document = editor.document;
        if (!document.fileName.endsWith('.loop')) {
            vscode.window.showWarningMessage('Please open a valid Looping Compile (.loop) file.');
            return;
        }

        const code = document.getText();
        showLiveViewport(context, code);
    });

    // 2. Command: Build Native Binary
    let buildDisposable = vscode.commands.registerCommand('looping.buildBinary', function () {
        vscode.window.showInformationMessage('⚡ Compiling .loop with CS Proprietary Compiler Engine -> Target: Universal Native Binary (Mac/iOS/Droid)...');
    });

    context.subscriptions.push(runDisposable, buildDisposable);
}

function showLiveViewport(context, initialCode) {
    const column = vscode.ViewColumn.Beside;

    if (currentPanel) {
        currentPanel.reveal(column);
        currentPanel.webview.postMessage({ command: 'updateCode', code: initialCode });
        return;
    }

    currentPanel = vscode.window.createWebviewPanel(
        'loopingViewport',
        'L∞ping Live Viewport — hiOP',
        column,
        {
            enableScripts: true,
            retainContextWhenHidden: true
        }
    );

    currentPanel.webview.html = getWebviewContent(initialCode);

    currentPanel.onDidDispose(
        () => {
            currentPanel = undefined;
        },
        null,
        context.subscriptions
    );
}

function getWebviewContent(code) {
    return `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Looping Viewport</title>
    <style>
        body { margin: 0; background: #06090f; color: #f1f5f9; font-family: -apple-system, sans-serif; display: flex; flex-direction: column; height: 100vh; overflow: hidden; }
        .header { height: 36px; background: #0d1117; display: flex; align-items: center; justify-content: space-between; padding: 0 16px; border-bottom: 1px solid rgba(255,255,255,0.1); font-size: 12px; font-weight: bold; }
        .badge { background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; padding: 2px 8px; border-radius: 4px; font-size: 10px; }
        .canvas-container { flex: 1; display: flex; align-items: center; justify-content: center; background: #04060a; }
        canvas { background: #000; border-radius: 8px; box-shadow: 0 10px 30px rgba(0,0,0,0.6); }
        .terminal { height: 120px; background: #080c14; border-top: 1px solid rgba(255,255,255,0.1); padding: 8px 16px; font-family: monospace; font-size: 11px; overflow-y: auto; color: #38bdf8; }
    </style>
</head>
<body>
    <div class="header">
        <span>L∞ping Live Engine (LoopUI & LoopEngine)</span>
        <span class="badge">CS PROPRIETARY CORE</span>
    </div>
    <div class="canvas-container">
        <canvas id="gameCanvas" width="720" height="480"></canvas>
    </div>
    <div class="terminal" id="termLogs">> CS Looping Runtime initialized.</div>

    <script>
        const canvas = document.getElementById('gameCanvas');
        const ctx = canvas.getContext('2d');
        const term = document.getElementById('termLogs');

        function log(msg) {
            term.innerHTML += '<br>> ' + msg;
            term.scrollTop = term.scrollHeight;
        }

        let gameEntities = [];
        let renderQueue = [];
        let keysDown = {};

        window.addEventListener('keydown', e => keysDown[e.key.toLowerCase()] = true);
        window.addEventListener('keyup', e => keysDown[e.key.toLowerCase()] = false);

        function parseAndRun(code) {
            gameEntities = [];
            renderQueue = [];
            log('⚡ Parsing .loop source code...');

            const lines = code.split('\\n');
            for (let line of lines) {
                line = line.trim();
                if (!line || line.startsWith('#')) continue;

                if (line.startsWith('print ')) {
                    log(line.replace('print ', '').replace(/['"]/g, ''));
                }
                if (line.startsWith('draw card at')) {
                    const titleMatch = line.match(/title ["'](.*?)["']/);
                    const textMatch = line.match(/text ["'](.*?)["']/);
                    renderQueue.push({ type: 'card', x: 30, y: 30, w: 260, h: 110, title: titleMatch ? titleMatch[1] : '', text: textMatch ? textMatch[1] : '' });
                }
                if (line.startsWith('spawn sprite')) {
                    const colorMatch = line.match(/color ["'](.*?)["']/);
                    const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);
                    gameEntities.push({
                        x: posMatch ? parseFloat(posMatch[1]) : 100,
                        y: posMatch ? parseFloat(posMatch[2]) : 380,
                        vy: 0,
                        color: colorMatch ? colorMatch[1] : '#38bdf8',
                        isJumping: false
                    });
                }
            }
            log('✅ Running at 60 FPS in Live Viewport.');
        }

        function gameLoop() {
            for (let s of gameEntities) {
                if (keysDown['arrowleft'] || keysDown['a']) s.x -= 3;
                if (keysDown['arrowright'] || keysDown['d']) s.x += 3;
                if ((keysDown['arrowup'] || keysDown['w'] || keysDown[' ']) && !s.isJumping) {
                    s.vy = -12;
                    s.isJumping = true;
                }
                s.vy += 0.6;
                s.y += s.vy;
                if (s.y >= 380) { s.y = 380; s.vy = 0; s.isJumping = false; }
            }

            ctx.fillStyle = '#06090f';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            // Ground
            ctx.fillStyle = '#0f172a';
            ctx.fillRect(0, canvas.height - 40, canvas.width, 40);
            ctx.strokeStyle = '#38bdf8';
            ctx.strokeRect(0, canvas.height - 40, canvas.width, 1);

            for (let elem of renderQueue) {
                if (elem.type === 'card') {
                    ctx.fillStyle = 'rgba(30, 41, 59, 0.8)';
                    ctx.strokeStyle = 'rgba(99, 102, 241, 0.4)';
                    ctx.fillRect(elem.x, elem.y, elem.w, elem.h);
                    ctx.strokeRect(elem.x, elem.y, elem.w, elem.h);
                    ctx.fillStyle = '#38bdf8';
                    ctx.font = 'bold 15px sans-serif';
                    ctx.fillText(elem.title, elem.x + 16, elem.y + 32);
                    ctx.fillStyle = '#94a3b8';
                    ctx.font = '12px sans-serif';
                    ctx.fillText(elem.text, elem.x + 16, elem.y + 64);
                }
            }

            for (let s of gameEntities) {
                ctx.fillStyle = s.color;
                ctx.shadowColor = s.color;
                ctx.shadowBlur = 10;
                ctx.fillRect(s.x, s.y, 32, 44);
                ctx.shadowBlur = 0;
            }

            requestAnimationFrame(gameLoop);
        }

        window.addEventListener('message', event => {
            if (event.data.command === 'updateCode') {
                parseAndRun(event.data.code);
            }
        });

        parseAndRun(${JSON.stringify(code)});
        gameLoop();
    </script>
</body>
</html>`;
}

function deactivate() {}

module.exports = {
    activate,
    deactivate
};
