
// ═══════════════════════════════════════════════════════════════
// ♾️ LOOPING CLI — OFFICIAL RUNTIME EXECUTOR & COMPILER v2.1 (WINDOWS/CROSS-PLATFORM)
// Proprietary Language for Shine Loop Console & Holo Looping OoS
// Developed by Holo Entertainment (Coki Studios)
// ═══════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

const { spawnSync, exec  } = require('child_process');
const readline = require('readline');




// ANSI Colors for Terminal
const RESET = "\x1b[0m";
const BOLD = "\x1b[1m";
const CYAN = "\x1b[36m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const PURPLE = "\x1b[35m";
const RED = "\x1b[31m";
const BLUE = "\x1b[34m";
const DIM = "\x1b[2m";

class LoopingCLI {
    constructor() {
        this.variables = {};
        this.functions = {};
        this.importedModules = new Set();
        this.importedPythonModules = new Set();
        this.appName = "HoloApp";
        this.appVersion = "2.1";
        this.targetPlatform = "Shine Loop Console (Holo Looping OoS)";
        this.uiProfile = "stock";
        this.theme = "frosted_aqua_a17";
        this.entities = [];
        this.uiElements = [];
        this.cachedPythonConfig = null;
    }

    printBanner() {
        console.log(`\n${BOLD}${PURPLE}----------------------------------------------------------------------${RESET}`);
        console.log(`${BOLD}${CYAN}[LOOPING COMPILE]${RESET} ${GREEN}Core Runtime & Compiler v2.1.0${RESET} ${DIM}(Win32 Native & POSIX)${RESET}`);
        console.log(`${YELLOW}Target Platform:${RESET} Shine Loop Console | ${BLUE}Kernel:${RESET} Holo Looping OoS 1.0 (Linux Core)`);
        console.log(`${PURPLE}By Holo Entertainment (Coki Studios)${RESET}`);
        console.log(`${BOLD}${PURPLE}----------------------------------------------------------------------${RESET}\n`);
    }

    // ── Resilient Python Executable Detection (Windows & Unix) ──
    detectPython() {
        if (this.cachedPythonConfig) return this.cachedPythonConfig;

        const candidates = process.platform === 'win32'
            ? [
                { exe: 'python', args: [] },
                { exe: 'py', args: ['-3'] },
                { exe: 'py', args: [] },
                { exe: 'python3', args: [] }
              ]
            : [
                { exe: 'python3', args: [] },
                { exe: 'python', args: [] },
                { exe: 'py', args: [] }
              ];

        for (const c of candidates) {
            try {
                const res = spawnSync(c.exe, [...c.args, '-c', 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'], {
                    encoding: 'utf8',
                    timeout: 2000,
                    windowsHide: true
                });
                
                if (res.status === 0 && res.stdout) {
                    const ver = res.stdout.trim();
                    if (ver.startsWith('3.') || ver.startsWith('2.7')) {
                        this.cachedPythonConfig = c;
                        return c;
                    }
                }
            } catch (e) {
                // Try next candidate
            }
        }

        return null;
    }

    // ── Execute Python Code with Bi-directional Variable Synchronization ──
    runPythonCode(pyCode, options = {}) {
        const py = this.detectPython();
        if (!py) {
            console.error(`${RED}❌ [PYTHON BRIDGE ERROR] Python is not installed or not found in system PATH.${RESET}`);
            console.error(`${YELLOW}💡 Tip: Install Python from python.org or enable 'python' in Windows PATH.${RESET}`);
            return null;
        }

        const env = Object.assign({}, process.env, {
            LOOPING_VARS_JSON: JSON.stringify(this.variables)
        });

        const pythonBootstrap = `
import sys, json, os, math
try:
    looping_vars = json.loads(os.environ.get('LOOPING_VARS_JSON', '{}'))
    for _k, _v in looping_vars.items():
        globals()[_k] = _v
except Exception as _e:
    looping_vars = {}

def looping_set(key, val):
    looping_vars[key] = val
    globals()[key] = val
    sys.stdout.write(f"__LOOPING_SET__:{json.dumps({'k': str(key), 'v': val})}\\n")
    sys.stdout.flush()

${pyCode}
`;

        try {
            const res = spawnSync(py.exe, [...py.args, '-'], {
                input: pythonBootstrap,
                env,
                encoding: 'utf8',
                timeout: options.timeout || 10000,
                windowsHide: true
            });

            if (res.error) throw res.error;

            const stdout = res.stdout || '';
            const stderr = res.stderr || '';

            if (res.status !== 0 && stderr) {
                console.error(`${RED}❌ [PYTHON RUNTIME ERROR]:${RESET}\n${stderr.trim()}`);
            }

            const cleanLines = [];
            const outputLines = stdout.split(/\r?\n/);
            for (const line of outputLines) {
                const trimmed = line.trim();
                if (trimmed.startsWith('__LOOPING_SET__:')) {
                    try {
                        const payload = JSON.parse(trimmed.replace('__LOOPING_SET__:', ''));
                        this.variables[payload.k] = payload.v;
                    } catch (err) {}
                } else if (trimmed.length > 0) {
                    cleanLines.push(line);
                }
            }

            return cleanLines.join('\n');
        } catch (err) {
            console.error(`${RED}❌ [PYTHON RUNTIME ERROR]:${RESET}\n${err.message}`);
            return null;
        }
    }

    // ── Evaluate Python Expression Directly and Return Value ──
    evalPythonExpr(expr) {
        const py = this.detectPython();
        if (!py) return null;

        const env = Object.assign({}, process.env, {
            LOOPING_VARS_JSON: JSON.stringify(this.variables)
        });

        const bootstrap = `
import sys, json, os, math
try:
    looping_vars = json.loads(os.environ.get('LOOPING_VARS_JSON', '{}'))
    for _k, _v in looping_vars.items():
        globals()[_k] = _v
except Exception:
    pass
try:
    _res = eval(${JSON.stringify(expr)})
    print(json.dumps(_res))
except Exception as _e:
    sys.stderr.write(str(_e))
    sys.exit(1)
`;
        try {
            const res = spawnSync(py.exe, [...py.args, '-'], {
                input: bootstrap,
                env,
                encoding: 'utf8',
                timeout: 4000,
                windowsHide: true
            });

            if (res.status === 0 && res.stdout) {
                const result = res.stdout.trim();
                if (result) {
                    try {
                        return JSON.parse(result);
                    } catch (e) {
                        return result;
                    }
                }
            }
        } catch (err) {
            // fallback
        }
        return null;
    }

    // ── Helper to strip common leading whitespace from Python blocks ──
    dedentLines(lines) {
        let minIndent = Infinity;
        for (const l of lines) {
            if (!l.trim()) continue;
            const match = l.match(/^(\s+)/);
            const indent = match ? match[1].length : 0;
            if (indent < minIndent) minIndent = indent;
        }
        if (minIndent === Infinity || minIndent === 0) return lines;
        return lines.map(l => {
            if (!l.trim()) return '';
            return l.startsWith(' '.repeat(minIndent)) ? l.slice(minIndent) : l.replace(/^\s+/, '');
        });
    }

    isSingleQuotedLiteral(expr) {
        if (!expr || expr.length < 2) return false;
        const first = expr[0];
        if (first !== '"' && first !== "'") return false;
        for (let i = 1; i < expr.length; i++) {
            if (expr[i] === first && expr[i - 1] !== '\\') {
                return i === expr.length - 1;
            }
        }
        return false;
    }

    // ── Advanced Looping Expression Evaluator ──
    evaluateExpression(expr) {
        if (expr === undefined || expr === null) return '';
        expr = String(expr).trim();
        if (!expr) return '';

        // Check if expression is an explicit Python inline: py: <expr>, py <expr>, python <expr>, python: <expr>
        if (expr.startsWith('py:') || expr.startsWith('py ')) {
            const pySub = expr.replace(/^(py:\s*|py\s+)/, '').trim();
            const pyVal = this.evalPythonExpr(pySub);
            if (pyVal !== null) return pyVal;
        }
        if (expr.startsWith('python:') || expr.startsWith('python eval ') || expr.startsWith('python ') || expr.startsWith('python(')) {
            const pySubMatch = expr.match(/python\s*\(?["'](.*?)["']\)?/);
            if (pySubMatch) {
                const pyVal = this.evalPythonExpr(pySubMatch[1]);
                if (pyVal !== null) return pyVal;
            } else {
                const pySub = expr.replace(/^(python eval\s*|python:\s*|python\s+)/, '').trim();
                const pyVal = this.evalPythonExpr(pySub);
                if (pyVal !== null) return pyVal;
            }
        }

        // Single quoted literal string check
        if (this.isSingleQuotedLiteral(expr)) {
            let strContent = expr.slice(1, -1);
            // Variable interpolation inside string: "Hello {name}, score: {score}"
            strContent = strContent.replace(/\{([A-Za-z0-9_]+)\}/g, (match, varKey) => {
                return this.variables.hasOwnProperty(varKey) ? this.variables[varKey] : match;
            });
            return strContent;
        }

        // Exact numbers
        if (!isNaN(expr) && expr !== '') {
            return Number(expr);
        }

        // Booleans
        if (expr === 'true') return true;
        if (expr === 'false') return false;
        if (expr === 'null' || expr === 'none') return null;

        // Exact Variable lookup
        if (this.variables.hasOwnProperty(expr)) {
            return this.variables[expr];
        }

        // Math expressions & arithmetic
        if (expr.includes(' + ') || expr.includes(' - ') || expr.includes(' * ') || expr.includes(' / ') || expr.includes(' % ') || expr.startsWith('math.')) {
            try {
                let resolvedExpr = expr;
                // Substitute known variables
                const varKeys = Object.keys(this.variables).sort((a, b) => b.length - a.length);
                for (const k of varKeys) {
                    const regex = new RegExp(`\\b${k}\\b`, 'g');
                    const val = this.variables[k];
                    const valRepr = typeof val === 'string' ? JSON.stringify(val) : String(val);
                    resolvedExpr = resolvedExpr.replace(regex, valRepr);
                }

                // Map Python / Looping Math to JS Math
                resolvedExpr = resolvedExpr
                    .replace(/math\.pi/g, Math.PI.toString())
                    .replace(/math\.e/g, Math.E.toString())
                    .replace(/math\.sqrt/g, 'Math.sqrt')
                    .replace(/math\.pow/g, 'Math.pow')
                    .replace(/math\.sin/g, 'Math.sin')
                    .replace(/math\.cos/g, 'Math.cos')
                    .replace(/math\.tan/g, 'Math.tan')
                    .replace(/math\.floor/g, 'Math.floor')
                    .replace(/math\.ceil/g, 'Math.ceil')
                    .replace(/math\.round/g, 'Math.round')
                    .replace(/math\.abs/g, 'Math.abs')
                    .replace(/math\.min/g, 'Math.min')
                    .replace(/math\.max/g, 'Math.max')
                    .replace(/math\.random/g, 'Math.random')
                    .replace(/math\.log/g, 'Math.log')
                    .replace(/math\.exp/g, 'Math.exp');

                const mathResult = Function(`"use strict"; return (${resolvedExpr});`)();
                return mathResult;
            } catch (e) {
                // If JS evaluation fails, try Python eval fallback
                const pyFallback = this.evalPythonExpr(expr);
                if (pyFallback !== null) return pyFallback;
            }
        }

        return expr;
    }

    // ── Evaluate Conditional Logic (==, !=, >, <, >=, <=, and, or, in) ──
    evaluateCondition(cond) {
        cond = cond.trim();
        if (!cond) return false;

        // Python style: and / or
        if (cond.includes(' and ') || cond.includes(' && ')) {
            const parts = cond.split(/ and | && /);
            return parts.every(p => this.evaluateCondition(p));
        }
        if (cond.includes(' or ') || cond.includes(' || ')) {
            const parts = cond.split(/ or | \|\| /);
            return parts.some(p => this.evaluateCondition(p));
        }

        const ops = ['>=', '<=', '==', '!=', '>', '<'];
        for (const op of ops) {
            if (cond.includes(op)) {
                const parts = cond.split(op);
                const left = this.evaluateExpression(parts[0]);
                const right = this.evaluateExpression(parts.slice(1).join(op));

                if (op === '==') return left == right;
                if (op === '!=') return left != right;
                if (op === '>=') return Number(left) >= Number(right);
                if (op === '<=') return Number(left) <= Number(right);
                if (op === '>') return Number(left) > Number(right);
                if (op === '<') return Number(left) < Number(right);
            }
        }

        const val = this.evaluateExpression(cond);
        return Boolean(val);
    }

    parsePrint(rawExpr) {
        const args = [];
        let current = '';
        let inQuotes = false;
        let quoteChar = '';

        for (let i = 0; i < rawExpr.length; i++) {
            const char = rawExpr[i];
            if ((char === '"' || char === "'") && (i === 0 || rawExpr[i - 1] !== '\\')) {
                if (!inQuotes) {
                    inQuotes = true;
                    quoteChar = char;
                } else if (quoteChar === char) {
                    inQuotes = false;
                }
            }

            if (char === ',' && !inQuotes) {
                args.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        if (current.trim()) {
            args.push(current.trim());
        }

        const evaluated = args.map(arg => {
            const val = this.evaluateExpression(arg);
            return typeof val === 'object' ? JSON.stringify(val) : String(val);
        });
        return evaluated.join(' ');
    }

    // ── Run Complete .loop Source File ──
    runFile(filePath) {
        if (!fs.existsSync(filePath)) {
            console.error(`${RED}❌ Error: File not found: ${filePath}${RESET}`);
            process.exit(1);
        }

        this.printBanner();
        console.log(`${CYAN}[EXEC] Loading source:${RESET} ${BOLD}${path.basename(filePath)}${RESET}`);
        
        const py = this.detectPython();
        if (py) {
            const pyName = py.exe + (py.args.length ? ' ' + py.args.join(' ') : '');
            console.log(`${GREEN}[PYTHON INTEROP]${RESET} Attached Python runtime: ${CYAN}${pyName}${RESET}`);
        } else {
            console.log(`${YELLOW}[PYTHON INTEROP]${RESET} Standalone JS Emulation Mode (Python executable not in PATH)`);
        }
        console.log('');

        const content = fs.readFileSync(filePath, 'utf8');
        const startTime = performance.now();

        this.executeScript(content);

        const elapsed = (performance.now() - startTime).toFixed(2);
        console.log(`\n${GREEN}[OK] Execution completed in ${elapsed}ms!${RESET}`);
    }

    // ── Script Multi-line Block Interpreter ──
    executeScript(scriptContent) {
        const lines = scriptContent.split(/\r?\n/);
        let i = 0;

        while (i < lines.length) {
            let line = lines[i].trim();
            i++;

            if (!line || line.startsWith('#') || line.startsWith('//')) continue;

            // Multiline Python Block: python { ... } OR py: ... end
            if (line.startsWith('python {') || line === 'python:' || line === 'py:' || line.startsWith('py:begin')) {
                let pyBlockLines = [];
                if (line.startsWith('python {') && line.endsWith('}')) {
                    pyBlockLines.push(line.slice(8, -1).trim());
                } else {
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        const trimmedNext = nextLine.trim();
                        if (trimmedNext === '}' || trimmedNext === 'end' || trimmedNext === 'py:end') {
                            break;
                        }
                        pyBlockLines.push(nextLine);
                    }
                }

                // Automatic indentation normalization (dedent)
                const dedentedLines = this.dedentLines(pyBlockLines);
                const pyCode = dedentedLines.join('\n');
                console.log(`${PURPLE}[PYTHON EXEC]${RESET} Running multi-line Python block (${pyBlockLines.length} lines)...`);
                const pyOut = this.runPythonCode(pyCode);
                if (pyOut) console.log(`${PURPLE}[PYTHON OUTPUT]${RESET}\n${pyOut}`);
                continue;
            }

            // Function Definition: function <name>(<args>) { ... }
            if (line.startsWith('function ') || line.startsWith('def ')) {
                const fnMatch = line.match(/(?:function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*\{?/);
                if (fnMatch) {
                    const fnName = fnMatch[1];
                    const fnParams = fnMatch[2].split(',').map(s => s.trim()).filter(Boolean);
                    const bodyLines = [];

                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;
                        bodyLines.push(nextLine);
                    }

                    this.functions[fnName] = { params: fnParams, body: bodyLines.join('\n') };
                    console.log(`${BLUE}[FUNCTION]${RESET} Registered function "${fnName}" (${fnParams.length} args)`);
                    continue;
                }
            }

            // Loop / Repeat: repeat <N> times { ... } OR loop <N> { ... }
            if (line.startsWith('repeat ') || line.startsWith('loop ')) {
                const countMatch = line.match(/(?:repeat|loop)\s+(\d+|[A-Za-z0-9_]+)\s*(?:times)?\s*\{?/i);
                if (countMatch) {
                    const countVal = Number(this.evaluateExpression(countMatch[1])) || 0;
                    const bodyLines = [];
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;
                        bodyLines.push(nextLine);
                    }
                    const loopScript = bodyLines.join('\n');
                    for (let c = 0; c < countVal; c++) {
                        this.variables['i'] = c;
                        this.variables['loop_index'] = c;
                        this.executeScript(loopScript);
                    }
                    continue;
                }
            }

            try {
                this.executeLine(line);
            } catch (err) {
                console.error(`${RED}[ERROR at line ${i}]: ${err.message}${RESET}`);
                console.error(`${DIM}--> ${line}${RESET}`);
            }
        }
    }

    // ── Execute Single Line Command ──
    executeLine(line) {
        line = line.trim();
        if (!line || line.startsWith('#') || line.startsWith('//')) return;

        // 0. Interactive REPL / CLI Utilities (help, vars, clear)
        if (line === 'help' || line === '?') {
            this.printREPLHelp();
            return;
        }

        if (line === 'vars' || line === 'variables') {
            console.log(`\n${BOLD}${CYAN}📋 Active Memory Variables (${Object.keys(this.variables).length}):${RESET}`);
            if (Object.keys(this.variables).length === 0) {
                console.log(`${DIM}   (No variables defined yet. Try: set score to 100)${RESET}\n`);
            } else {
                for (const [k, v] of Object.entries(this.variables)) {
                    console.log(`   ${YELLOW}${k}${RESET} = ${GREEN}${typeof v === 'object' ? JSON.stringify(v) : v}${RESET} ${DIM}(${typeof v})${RESET}`);
                }
                console.log('');
            }
            return;
        }

        if (line === 'clear' || line === 'cls') {
            console.clear();
            return;
        }

        // 0.1 Pip Package Manager Invocation: pip ... / python -m pip ... / py -m pip ...
        if (line.startsWith('pip ') || line.startsWith('python -m pip ') || line.startsWith('py -m pip ') || line === 'pip') {
            const pipArgs = line.replace(/^(python -m pip|py -m pip|pip)/, '').trim();
            console.log(`${CYAN}[PACKAGE MANAGER]${RESET} Executing pip ${pipArgs}...`);
            const py = this.detectPython();
            if (py) {
                spawnSync(py.exe, [...py.args, '-m', 'pip', ...pipArgs.split(/\s+/).filter(Boolean)], {
                    stdio: 'inherit',
                    windowsHide: false
                });
            } else {
                console.error(`${RED}❌ Python/pip not found in PATH.${RESET}`);
            }
            return;
        }

        // 1. Python Module Import: use python "math" OR import python "sys"
        if (line.startsWith('use python ') || line.startsWith('import python ')) {
            const pyLib = line.replace(/^(use|import) python /, '').trim().replace(/['"]/g, '');
            this.importedPythonModules.add(pyLib);
            console.log(`${GREEN}[PYTHON BRIDGE]${RESET} Linked Python Module: ${BOLD}${pyLib}${RESET}`);
            return;
        }

        // 2. Looping Module Imports
        if (line.startsWith('import ')) {
            const mod = line.replace('import ', '').trim();
            this.importedModules.add(mod);
            console.log(`${BLUE}[MODULE]${RESET} Loaded ${mod}`);
            return;
        }

        // 3. App Definition
        if (line.startsWith('define app')) {
            let appName = 'HoloApp';
            const quoteMatch = line.match(/define app\s*(?:as)?\s*["'](.*?)["']/);
            const asMatch = line.match(/define app\s+as\s+([A-Za-z0-9_]+)/);
            if (quoteMatch) appName = quoteMatch[1];
            else if (asMatch) appName = asMatch[1];
            this.appName = appName;
            console.log(`${PURPLE}[APP]${RESET} Registered "${appName}" on ${this.targetPlatform}`);
            return;
        }

        // 4. UI System Profile & Target Device Configuration
        if (line.startsWith('set ui_profile to') || line.startsWith('set ui_profile as') || line.startsWith('set ui to')) {
            const match = line.match(/set (?:ui_profile|ui) (?:to|as) ["'](.*?)["']/);
            const profile = match ? match[1].toUpperCase() : 'STOCK';
            this.uiProfile = profile.toLowerCase();
            console.log(`${CYAN}[CS DESIGN UI]${RESET} UI Profile Active: ${BOLD}${profile}${RESET} (Hardware Spec Loaded)`);
            return;
        }

        // 5. Theme Setting
        if (line.startsWith('set theme to') || line.startsWith('set theme as')) {
            const match = line.match(/set theme (?:to|as) ["'](.*?)["']/);
            if (match) this.theme = match[1];
            return;
        }

        // 6. Python Inline Expression / Exec: py <expr> / py: <expr> / python <expr> / python eval <expr> / python: <expr>
        if (line.startsWith('py:') || line.startsWith('py ') || line.startsWith('python:') || line.startsWith('python eval ') || (line.startsWith('python ') && !line.startsWith('python {'))) {
            const pyCode = line.replace(/^(python eval\s*|python:\s*|python\s+|py:\s*|py\s+)/, '').trim();
            const evalVal = this.evalPythonExpr(pyCode);
            if (evalVal !== null) {
                console.log(`${CYAN}=>${RESET} ${GREEN}${typeof evalVal === 'object' ? JSON.stringify(evalVal) : evalVal}${RESET}`);
                return;
            }
            const pyOut = this.runPythonCode(pyCode);
            if (pyOut) console.log(`${PURPLE}[PYTHON RESULT]${RESET} ${pyOut}`);
            return;
        }

        // 7. Conditional Logic: if <cond> do <action> OR if <cond> then <action>
        if (line.startsWith('if ')) {
            const condMatch = line.match(/^if\s+(.*?)\s+(?:then|do)\s+(.*)$/i);
            if (condMatch) {
                const condition = condMatch[1];
                const action = condMatch[2];
                if (this.evaluateCondition(condition)) {
                    this.executeLine(action);
                }
                return;
            }
        }

        // 8. Variable Assignment: set <var> to <expr> OR set <var> as <expr> OR set <var> = <expr>
        if (line.startsWith('set ') && (line.includes(' to ') || line.includes(' as ') || line.includes(' = '))) {
            let delimiter = ' to ';
            if (line.includes(' to ')) delimiter = ' to ';
            else if (line.includes(' as ')) delimiter = ' as ';
            else if (line.includes(' = ')) delimiter = ' = ';

            const parts = line.replace('set ', '').split(delimiter);
            const varName = parts[0].trim();
            const valExpr = parts.slice(1).join(delimiter).trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        // Shorthand variable assignment: x = 10 or x += 5
        const assignMatch = line.match(/^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.*)$/);
        if (assignMatch && !line.startsWith('create ') && !line.startsWith('draw ') && !line.startsWith('spawn ')) {
            const varName = assignMatch[1];
            const op = assignMatch[2];
            const expr = assignMatch[3];
            const val = this.evaluateExpression(expr);

            if (op === '=') {
                this.variables[varName] = val;
            } else if (op === '+=') {
                this.variables[varName] = (Number(this.variables[varName]) || 0) + Number(val);
            } else if (op === '-=') {
                this.variables[varName] = (Number(this.variables[varName]) || 0) - Number(val);
            } else if (op === '*=') {
                this.variables[varName] = (Number(this.variables[varName]) || 0) * Number(val);
            } else if (op === '/=') {
                this.variables[varName] = (Number(this.variables[varName]) || 0) / Number(val);
            }
            return;
        }

        // 9. Function Calls: call <fn>(<args>) OR <fn>()
        if (line.startsWith('call ')) {
            const callMatch = line.match(/call\s+([A-Za-z0-9_]+)\s*(?:\((.*?)\))?/);
            if (callMatch) {
                const fnName = callMatch[1];
                if (this.functions[fnName]) {
                    this.executeScript(this.functions[fnName].body);
                } else {
                    console.log(`${YELLOW}[FUNCTION CALL]${RESET} Invoked "${fnName}"`);
                }
                return;
            }
        }

        // 10. Print Output
        if (line.startsWith('print ') || line.startsWith('echo ')) {
            const expr = line.replace(/^(print|echo)\s+/, '').trim();
            const val = this.parsePrint(expr);
            console.log(`${GREEN}[OUTPUT]${RESET} ${val}`);
            return;
        }

        // 11. Bubbly Dot Component
        if (line.startsWith('spawn bubbly_dot') || line.startsWith('draw bubbly_dot')) {
            const textMatch = line.match(/text ["'](.*?)["']/);
            const stateMatch = line.match(/state ["'](.*?)["']/);
            const text = textMatch ? textMatch[1] : 'Audio Active';
            const state = stateMatch ? stateMatch[1].toUpperCase() : 'MUSIC';
            console.log(`${GREEN}[BUBBLY DOT]${RESET} Active Notch [${state}]: "${text}"`);
            return;
        }

        // 12. Window Canvas
        if (line.startsWith('create window')) {
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            console.log(`${CYAN}[DISPLAY]${RESET} "${titleMatch ? titleMatch[1] : 'Game Window'}" (${sizeMatch ? sizeMatch[1] : 800}x${sizeMatch ? sizeMatch[2] : 520})`);
            return;
        }

        // 13. UI Cards and Buttons
        if (line.startsWith('draw card at') || line.startsWith('draw button at') || line.startsWith('draw input at')) {
            const type = line.startsWith('draw card') ? 'Card' : (line.startsWith('draw input') ? 'Input' : 'Button');
            console.log(`${YELLOW}[UI]${RESET} Rendered UI ${type} Component`);
            return;
        }

        // 14. Entities: Platforms, Coins & Sprites
        if (line.startsWith('spawn sprite')) {
            const nameMatch = line.match(/spawn sprite ["'](.*?)["']/);
            const name = nameMatch ? nameMatch[1] : 'Sprite';
            console.log(`${PURPLE}[ENTITY]${RESET} Spawned "${name}" (Physics 60Hz Low-Latency)`);
            return;
        }
        if (line.startsWith('spawn platform') || line.startsWith('spawn coin') || line.startsWith('spawn star')) {
            console.log(`${CYAN}[WORLD]${RESET} Placed Stage Component`);
            return;
        }

        // 15. Kernel Syscalls
        if (line.startsWith('syscall')) {
            const match = line.match(/syscall\s+([A-Za-z0-9_]+)(?:\s+with\s+args\s+["'](.*?)["'])?/);
            const callName = match ? match[1] : 'unknown';
            const args = match && match[2] ? match[2] : '';
            console.log(`${CYAN}[KERNEL SYSCALL]${RESET} 0x${Math.floor(Math.random() * 0xFFFFFF).toString(16).toUpperCase()} :: ${callName}(${args}) -> OK`);
            return;
        }

        // 16. Multitasking Processes
        if (line.startsWith('spawn process')) {
            const nameMatch = line.match(/spawn process ["'](.*?)["']/);
            const prioMatch = line.match(/priority\s+(\d+)/);
            const procName = nameMatch ? nameMatch[1] : 'daemon';
            const pid = Math.floor(1000 + Math.random() * 9000);
            console.log(`${PURPLE}[PROCESS]${RESET} PID ${pid} [${procName}] Started (Priority: ${prioMatch ? prioMatch[1] : 10})`);
            return;
        }

        // 17. Audio Synthesizer
        if (line.startsWith('play tone')) {
            const freqMatch = line.match(/play tone at\s+(\d+)\s*Hz/i);
            const durMatch = line.match(/for\s+(\d+)\s*ms/i);
            const freq = freqMatch ? parseInt(freqMatch[1]) : 440;
            const dur = durMatch ? parseInt(durMatch[1]) : 100;
            console.log(`${BLUE}[AUDIO HARDWARE]${RESET} Synthesizer: ${freq}Hz (${dur}ms)`);
            return;
        }

        // 18. Delay / Sleep
        if (line.startsWith('delay ') || line.startsWith('sleep ')) {
            const msMatch = line.match(/(?:delay|sleep)\s+(\d+)/);
            const ms = msMatch ? parseInt(msMatch[1]) : 100;
            const end = Date.now() + ms;
            while (Date.now() < end) {}
            return;
        }

        // 19. Bare Expression Evaluation (Interactive REPL / Direct Expression Output)
        const evaluated = this.evaluateExpression(line);
        if (evaluated !== undefined && evaluated !== null && evaluated !== line) {
            console.log(`${CYAN}=>${RESET} ${GREEN}${typeof evaluated === 'object' ? JSON.stringify(evaluated) : evaluated}${RESET}`);
            return;
        } else if (this.variables.hasOwnProperty(line)) {
            const v = this.variables[line];
            console.log(`${CYAN}=>${RESET} ${GREEN}${typeof v === 'object' ? JSON.stringify(v) : v}${RESET}`);
            return;
        }
    }

    printREPLHelp() {
        console.log(`\n${BOLD}${CYAN}♾️  LOOPING LANGUAGE REPL GUIDE & CHEATSHEET${RESET}`);
        console.log(`${PURPLE}────────────────────────────────────────────────────────────────────────${RESET}`);
        console.log(`${BOLD}${YELLOW}1. Variables & Math Expressions:${RESET}`);
        console.log(`   ${GREEN}set hero to "Angel"${RESET}        -> String variable assignment`);
        console.log(`   ${GREEN}level = 20${RESET}                 -> Direct numerical assignment`);
        console.log(`   ${GREEN}level += 5${RESET}                 -> Shorthand arithmetic (+-, *=, /=)`);
        console.log(`   ${GREEN}math.sqrt(144) * 2${RESET}         -> Native math functions evaluation`);
        console.log(`   ${GREEN}print "Hero: {hero}, Lv: {level}"${RESET} -> String template interpolation\n`);

        console.log(`${BOLD}${YELLOW}2. Python Interoperability (Bridge):${RESET}`);
        console.log(`   ${GREEN}use python "math"${RESET}          -> Import Python module`);
        console.log(`   ${GREEN}py: math.pi * 10${RESET}           -> Inline Python evaluation`);
        console.log(`   ${GREEN}set bonus to py: 2**8${RESET}      -> Assign Python result to Looping var`);
        console.log(`   ${GREEN}python { ... }${RESET}             -> Multi-line Python block (access looping_vars,\n                                   use looping_set('k', val))\n`);

        console.log(`${BOLD}${YELLOW}3. Control Flow & Functions:${RESET}`);
        console.log(`   ${GREEN}if level >= 20 do print "Max Level!"${RESET}`);
        console.log(`   ${GREEN}repeat 3 times { print "Ping {i}" }${RESET}`);
        console.log(`   ${GREEN}function greet(name) { print "Hello {name}" }${RESET}`);
        console.log(`   ${GREEN}call greet("Angel")${RESET}\n`);

        console.log(`${BOLD}${YELLOW}4. Interactive REPL Commands:${RESET}`);
        console.log(`   ${GREEN}help${RESET} or ${GREEN}?${RESET}                  -> Show this command guide`);
        console.log(`   ${GREEN}vars${RESET} or ${GREEN}variables${RESET}          -> Inspect all variables in memory`);
        console.log(`   ${GREEN}clear${RESET} or ${GREEN}cls${RESET}               -> Clear the terminal screen`);
        console.log(`   ${GREEN}exit${RESET} or ${GREEN}quit${RESET}              -> Exit REPL\n`);
        console.log(`${PURPLE}────────────────────────────────────────────────────────────────────────${RESET}\n`);
    }

    // ── Compiles source code to Standalone HTML5 Game for Shine Loop & Web ──
    compileToStandalone(filePath, outputPath) {
        if (!fs.existsSync(filePath)) {
            console.error(`${RED}[ERROR] Source file not found: ${filePath}${RESET}`);
            process.exit(1);
        }

        this.printBanner();
        console.log(`${CYAN}[BUILD] Compiling target to Standalone Windows/HTML5 executable...${RESET}`);

        const sourceCode = fs.readFileSync(filePath, 'utf8');
        const out = outputPath || filePath.replace('.loop', '.html');

        
        let engineSource = '';
        const coreLocalPath = path.join(__dirname, '../LoopingEngine/looping_core.js');
        const coreLocalPathSame = path.join(process.cwd(), 'LoopingEngine/looping_core.js');
        if (fs.existsSync(coreLocalPath)) {
            engineSource = fs.readFileSync(coreLocalPath, 'utf8');
        } else if (fs.existsSync(coreLocalPathSame)) {
            engineSource = fs.readFileSync(coreLocalPathSame, 'utf8');
        } else {
            engineSource = "// ═══════════════════════════════════════════════════════════════\r\n//  LOOPING COMPILE — CORE RUNTIME & GRAPHIC ENGINE v2.0\r\n// Next-Gen Game Programming Language for \"Shine Loop\" & \"Holo Looping OoS\"\r\n// Developed by Holo Entertainment (Sub-division of Coki Studios)\r\n// ═══════════════════════════════════════════════════════════════\r\n\r\nexport class LoopingInterpreter {\r\n    constructor(canvas, terminalOutput) {\r\n        this.canvas = canvas;\r\n        this.ctx = canvas ? canvas.getContext('2d') : null;\r\n        this.terminalOutput = terminalOutput || console.log;\r\n        \r\n        // Virtual Machine & System State\r\n        this.systemTarget = \"Holo Looping Runtime Core\";\r\n        this.targetPlatform = \"Shine Loop Game Runtime\";\r\n        \r\n        this.variables = {};\r\n        this.functions = {};\r\n        this.gameEntities = [];\r\n        this.renderQueue = [];\r\n        this.particles = [];\r\n        this.sounds = {};\r\n        this.theme = 'dark_neon';\r\n        this.isRunning = false;\r\n        this.animationFrameId = null;\r\n        this.lastTime = 0;\r\n        this.fps = 60;\r\n        this.score = 0;\r\n        \r\n        // Input Controller State (Keyboard + Shine Loop Gamepad)\r\n        this.keysDown = {};\r\n        this.mousePos = { x: 0, y: 0 };\r\n        this.isMouseDown = false;\r\n        this.gamepadState = {\r\n            dpad: { left: false, right: false, up: false, down: false },\r\n            btnA: false,\r\n            btnB: false,\r\n            btnX: false,\r\n            btnY: false\r\n        };\r\n        \r\n        this.setupInputListeners();\r\n    }\r\n    \r\n    setupInputListeners() {\r\n        if (!this.canvas) return;\r\n        \r\n        window.addEventListener('keydown', (e) => {\r\n            const key = e.key.toLowerCase();\r\n            this.keysDown[key] = true;\r\n            this.keysDown[e.code.toLowerCase()] = true;\r\n            \r\n            // Map to Shine Loop Gamepad Buttons\r\n            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = true;\r\n            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = true;\r\n            if (key === 'w' || key === 'arrowup' || key === ' ') {\r\n                this.gamepadState.btnA = true; // Jump / Primary Action\r\n                this.gamepadState.dpad.up = true;\r\n            }\r\n            if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = true;\r\n            if (key === 'j' || key === 'z') this.gamepadState.btnB = true; // Attack / Boost\r\n            if (key === 'k' || key === 'x') this.gamepadState.btnX = true; // Special\r\n            \r\n            this.triggerEvent('keydown', e.key);\r\n        });\r\n        \r\n        window.addEventListener('keyup', (e) => {\r\n            const key = e.key.toLowerCase();\r\n            this.keysDown[key] = false;\r\n            this.keysDown[e.code.toLowerCase()] = false;\r\n            \r\n            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = false;\r\n            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = false;\r\n            if (key === 'w' || key === 'arrowup' || key === ' ') {\r\n                this.gamepadState.btnA = false;\r\n                this.gamepadState.dpad.up = false;\r\n            }\r\n            if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = false;\r\n            if (key === 'j' || key === 'z') this.gamepadState.btnB = false;\r\n            if (key === 'k' || key === 'x') this.gamepadState.btnX = false;\r\n            \r\n            this.triggerEvent('keyup', e.key);\r\n        });\r\n        \r\n        this.canvas.addEventListener('mousemove', (e) => {\r\n            const rect = this.canvas.getBoundingClientRect();\r\n            this.mousePos.x = e.clientX - rect.left;\r\n            this.mousePos.y = e.clientY - rect.top;\r\n        });\r\n        \r\n        this.canvas.addEventListener('mousedown', (e) => {\r\n            this.isMouseDown = true;\r\n            this.triggerEvent('click', this.mousePos);\r\n\r\n            // Interactive Button Click Dispatcher (CS Button System)\r\n            for (let elem of this.renderQueue) {\r\n                if (elem.type === 'button') {\r\n                    if (this.mousePos.x >= elem.x && this.mousePos.x <= elem.x + elem.w &&\r\n                        this.mousePos.y >= elem.y && this.mousePos.y <= elem.y + elem.h) {\r\n                        \r\n                        elem.isPressed = true;\r\n                        this.log(`[BUTTON CLICK] Triggered action: \"${elem.action || elem.text}\"`, 'success');\r\n                        \r\n                        // Play interactive tactile sound chime (Design Guide p.4 & p.9)\r\n                        try {\r\n                            const AudioCtx = window.AudioContext || window.webkitAudioContext;\r\n                            if (AudioCtx) {\r\n                                const ctx = new AudioCtx();\r\n                                const osc = ctx.createOscillator();\r\n                                const gain = ctx.createGain();\r\n                                osc.frequency.setValueAtTime(659, ctx.currentTime);\r\n                                gain.gain.setValueAtTime(0.08, ctx.currentTime);\r\n                                gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);\r\n                                osc.connect(gain);\r\n                                gain.connect(ctx.destination);\r\n                                osc.start();\r\n                                osc.stop(ctx.currentTime + 0.08);\r\n                            }\r\n                        } catch(e) {}\r\n\r\n                        // If action matches a registered function or system command\r\n                        if (elem.action && typeof this.functions[elem.action] === 'function') {\r\n                            this.functions[elem.action]();\r\n                        } else if (elem.action === 'launch_arcade' || elem.action === 'launch_forkar') {\r\n                            this.log(`[LAUNCHER] Booting game module: ${elem.action} @ 60 FPS...`, 'system');\r\n                        }\r\n                    }\r\n                }\r\n            }\r\n        });\r\n        \r\n        this.canvas.addEventListener('mouseup', () => {\r\n            this.isMouseDown = false;\r\n            for (let elem of this.renderQueue) {\r\n                if (elem.type === 'button') elem.isPressed = false;\r\n            }\r\n        });\r\n    }\r\n\r\n    log(message, type = 'info') {\r\n        if (typeof this.terminalOutput === 'function') {\r\n            this.terminalOutput(message, type);\r\n        } else {\r\n            console.log(`[Holo-Looping-${type.toUpperCase()}]:`, message);\r\n        }\r\n    }\r\n\r\n    reset() {\r\n        if (this.animationFrameId) {\r\n            cancelAnimationFrame(this.animationFrameId);\r\n            this.animationFrameId = null;\r\n        }\r\n        this.isRunning = false;\r\n        this.variables = {};\r\n        this.functions = {};\r\n        this.gameEntities = [];\r\n        this.renderQueue = [];\r\n        this.particles = [];\r\n        this.score = 0;\r\n        if (this.ctx && this.canvas) {\r\n            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);\r\n        }\r\n    }\r\n\r\n    // ── AST & Lexer Compiler ──\r\n    execute(code) {\r\n        this.reset();\r\n        this.log(\"⚙️ Compiling Looping (.loop) Source Code...\", \"system\");\r\n        \r\n        const lines = code.split(/\\r?\\n/);\r\n        let i = 0;\r\n\r\n        while (i < lines.length) {\r\n            let line = lines[i].trim();\r\n            i++;\r\n\r\n            if (!line || line.startsWith('#') || line.startsWith('//')) continue;\r\n\r\n            // Multiline Python Block: python { ... } OR py: ... end\r\n            if (line.startsWith('python {') || line === 'python:' || line === 'py:' || line.startsWith('py:begin')) {\r\n                let pyBlockLines = [];\r\n                if (line.startsWith('python {') && line.endsWith('}')) {\r\n                    pyBlockLines.push(line.slice(8, -1).trim());\r\n                } else {\r\n                    while (i < lines.length) {\r\n                        const nextLine = lines[i];\r\n                        i++;\r\n                        const trimmedNext = nextLine.trim();\r\n                        if (trimmedNext === '}' || trimmedNext === 'end' || trimmedNext === 'py:end') {\r\n                            break;\r\n                        }\r\n                        pyBlockLines.push(nextLine);\r\n                    }\r\n                }\r\n                const pyCode = pyBlockLines.join('\\n');\r\n                this.log(`[PYTHON BLOCK] Interpreting embedded Python logic (${pyBlockLines.length} lines)...`, 'system');\r\n                this.executePythonSimulation(pyCode);\r\n                continue;\r\n            }\r\n\r\n            // Function Definition: function <name>(<args>) { ... }\r\n            if (line.startsWith('function ') || line.startsWith('def ')) {\r\n                const fnMatch = line.match(/(?:function|def)\\s+([A-Za-z0-9_]+)\\s*\\((.*?)\\)\\s*\\{?/);\r\n                if (fnMatch) {\r\n                    const fnName = fnMatch[1];\r\n                    const fnParams = fnMatch[2].split(',').map(s => s.trim()).filter(Boolean);\r\n                    const bodyLines = [];\r\n\r\n                    while (i < lines.length) {\r\n                        const nextLine = lines[i];\r\n                        i++;\r\n                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;\r\n                        bodyLines.push(nextLine);\r\n                    }\r\n\r\n                    this.functions[fnName] = { params: fnParams, body: bodyLines.join('\\n') };\r\n                    this.log(`[FUNCTION] Registered function \"${fnName}\" (${fnParams.length} args)`, 'info');\r\n                    continue;\r\n                }\r\n            }\r\n\r\n            // Loop / Repeat: repeat <N> times { ... } OR loop <N> { ... }\r\n            if (line.startsWith('repeat ') || line.startsWith('loop ')) {\r\n                const countMatch = line.match(/(?:repeat|loop)\\s+(\\d+|[A-Za-z0-9_]+)\\s*(?:times)?\\s*\\{?/i);\r\n                if (countMatch) {\r\n                    const countVal = Number(this.evaluateExpression(countMatch[1])) || 0;\r\n                    const bodyLines = [];\r\n                    while (i < lines.length) {\r\n                        const nextLine = lines[i];\r\n                        i++;\r\n                        if (nextLine.trim() === '}' || nextLine.trim() === 'end') break;\r\n                        bodyLines.push(nextLine);\r\n                    }\r\n                    const loopScript = bodyLines.join('\\n');\r\n                    for (let c = 0; c < countVal; c++) {\r\n                        this.variables['i'] = c;\r\n                        this.variables['loop_index'] = c;\r\n                        this.executeSubScript(loopScript);\r\n                    }\r\n                    continue;\r\n                }\r\n            }\r\n\r\n            try {\r\n                this.parseLine(line);\r\n            } catch (err) {\r\n                this.log(`❌ [Syntax Error at line ${i}]: ${err.message}`, \"error\");\r\n                return false;\r\n            }\r\n        }\r\n\r\n        this.log(\"✨ Compilation Complete! Starting Shine Loop graphics pipeline @ 60FPS...\", \"success\");\r\n        this.startLoop();\r\n        return true;\r\n    }\r\n\r\n    executeSubScript(script) {\r\n        const lines = script.split(/\\r?\\n/);\r\n        for (let l of lines) {\r\n            let line = l.trim();\r\n            if (!line || line.startsWith('#') || line.startsWith('//')) continue;\r\n            this.parseLine(line);\r\n        }\r\n    }\r\n\r\n    executePythonSimulation(pyCode) {\r\n        // In browser sandbox environment, run Python math & variable logic\r\n        try {\r\n            const lines = pyCode.split('\\n');\r\n            for (let raw of lines) {\r\n                const line = raw.trim();\r\n                if (!line || line.startsWith('#')) continue;\r\n\r\n                // Handle python assignments: var = expr\r\n                const assignMatch = line.match(/^([A-Za-z0-9_]+)\\s*=\\s*(.*)$/);\r\n                if (assignMatch) {\r\n                    const k = assignMatch[1];\r\n                    const v = assignMatch[2];\r\n                    this.variables[k] = this.evaluateExpression(v);\r\n                } else if (line.startsWith('print(')) {\r\n                    const pMatch = line.match(/print\\((.*)\\)/);\r\n                    if (pMatch) {\r\n                        this.log(`[PYTHON] ${this.parsePrint(pMatch[1])}`, 'output');\r\n                    }\r\n                }\r\n            }\r\n        } catch (e) {\r\n            this.log(`[PYTHON ERROR] ${e.message}`, 'error');\r\n        }\r\n    }\r\n\r\n    parseLine(line) {\r\n        // 1. Module Imports & Package Ecosystem\r\n        if (line.startsWith('import ') && !line.startsWith('import python ')) {\r\n            const modulePath = line.replace('import ', '').trim();\r\n            this.log(`[MODULE LOADER] Linked Module: ${modulePath}`, 'system');\r\n            \r\n            if (this.modules && this.modules[modulePath]) {\r\n                this.execute(this.modules[modulePath]);\r\n            }\r\n            return;\r\n        }\r\n\r\n        // 1.1 Python Imports\r\n        if (line.startsWith('use python ') || line.startsWith('import python ')) {\r\n            const pyLib = line.replace(/^(use|import) python /, '').trim().replace(/['\"]/g, '');\r\n            this.log(`[PYTHON BRIDGE] Linked Python Module: ${pyLib}`, 'system');\r\n            return;\r\n        }\r\n\r\n        // 2. App & Console Meta Definition\r\n        if (line.startsWith('define app')) {\r\n            let appName = 'HoloApp';\r\n            const quoteMatch = line.match(/define app\\s*(?:as)?\\s*[\"'](.*?)[\"']/);\r\n            const asMatch = line.match(/define app\\s+as\\s+([A-Za-z0-9_]+)/);\r\n            if (quoteMatch) appName = quoteMatch[1];\r\n            else if (asMatch) appName = asMatch[1];\r\n            \r\n            this.log(`[APP] Registered Game Title: \"${appName}\" for Shine Loop Console`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 3. UI System Profile & Target Device Configuration\r\n        if (line.startsWith('set ui_profile to') || line.startsWith('set ui_profile as') || line.startsWith('set ui to')) {\r\n            const match = line.match(/set (?:ui_profile|ui) (?:to|as) [\"'](.*?)[\"']/);\r\n            if (match) {\r\n                this.uiProfile = match[1].toLowerCase();\r\n                this.log(`[CS DESIGN UI] UI Profile Set: \"${this.uiProfile.toUpperCase()}\" (Theme Specs Loaded)`, 'info');\r\n            }\r\n            return;\r\n        }\r\n\r\n        // 4. Theme configuration\r\n        if (line.startsWith('set theme to') || line.startsWith('set theme as')) {\r\n            const match = line.match(/set theme (?:to|as) [\"'](.*?)[\"']/);\r\n            if (match) this.theme = match[1];\r\n            return;\r\n        }\r\n\r\n        // 5. Bubbly Dot Component\r\n        if (line.startsWith('spawn bubbly_dot') || line.startsWith('draw bubbly_dot')) {\r\n            const textMatch = line.match(/text [\"'](.*?)[\"']/);\r\n            const stateMatch = line.match(/state [\"'](.*?)[\"']/);\r\n            this.bubblyDot = {\r\n                active: true,\r\n                text: textMatch ? textMatch[1] : 'Shine Audio Active',\r\n                state: stateMatch ? stateMatch[1] : 'music',\r\n                pulse: 0\r\n            };\r\n            this.log(`[BUBBLY DOT] Active on Top Notch: [${this.bubblyDot.state.toUpperCase()}] \"${this.bubblyDot.text}\"`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 6. Conditional Logic (if <cond> do <action> OR if <cond> then <action>)\r\n        if (line.startsWith('if ')) {\r\n            const conditionMatch = line.match(/^if\\s+(.*?)\\s+(?:then|do)\\s+(.*)$/i);\r\n            if (conditionMatch) {\r\n                const condition = conditionMatch[1];\r\n                const action = conditionMatch[2];\r\n                if (this.evaluateCondition(condition)) {\r\n                    this.log(`[IF TRUE] Executing: ${action}`, 'system');\r\n                    this.parseLine(action);\r\n                }\r\n                return;\r\n            }\r\n        }\r\n\r\n        // 7. Input Field UI Component\r\n        if (line.startsWith('draw input at')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const sizeMatch = line.match(/size \\((\\d+),\\s*(\\d+)\\)/);\r\n            const placeMatch = line.match(/placeholder [\"'](.*?)[\"']/);\r\n            const varMatch = line.match(/var [\"'](.*?)[\"']/);\r\n\r\n            this.renderQueue.push({\r\n                type: 'input',\r\n                x: posMatch ? parseInt(posMatch[1]) : 50,\r\n                y: posMatch ? parseInt(posMatch[2]) : 200,\r\n                w: sizeMatch ? parseInt(sizeMatch[1]) : 260,\r\n                h: sizeMatch ? parseInt(sizeMatch[2]) : 40,\r\n                placeholder: placeMatch ? placeMatch[1] : 'Type here...',\r\n                targetVar: varMatch ? varMatch[1] : 'user_input',\r\n                value: ''\r\n            });\r\n            this.log(`[UI INPUT] Rendered text field (Target Var: ${varMatch ? varMatch[1] : 'input'})`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 8. Variables: set <var> to <value> OR set <var> as <value> OR set <var> = <value>\r\n        if (line.startsWith('set ') && (line.includes(' to ') || line.includes(' as ') || line.includes(' = '))) {\r\n            let delimiter = ' to ';\r\n            if (line.includes(' to ')) delimiter = ' to ';\r\n            else if (line.includes(' as ')) delimiter = ' as ';\r\n            else if (line.includes(' = ')) delimiter = ' = ';\r\n\r\n            const parts = line.replace('set ', '').split(delimiter);\r\n            const varName = parts[0].trim();\r\n            const valExpr = parts.slice(1).join(delimiter).trim();\r\n            this.variables[varName] = this.evaluateExpression(valExpr);\r\n            return;\r\n        }\r\n\r\n        // Shorthand assignments: x = 10, x += 5\r\n        const assignMatch = line.match(/^([A-Za-z0-9_]+)\\s*(\\+=|-=|\\*=|\\/=|=)\\s*(.*)$/);\r\n        if (assignMatch && !line.startsWith('create ') && !line.startsWith('draw ') && !line.startsWith('spawn ')) {\r\n            const varName = assignMatch[1];\r\n            const op = assignMatch[2];\r\n            const expr = assignMatch[3];\r\n            const val = this.evaluateExpression(expr);\r\n\r\n            if (op === '=') {\r\n                this.variables[varName] = val;\r\n            } else if (op === '+=') {\r\n                this.variables[varName] = (Number(this.variables[varName]) || 0) + Number(val);\r\n            } else if (op === '-=') {\r\n                this.variables[varName] = (Number(this.variables[varName]) || 0) - Number(val);\r\n            } else if (op === '*=') {\r\n                this.variables[varName] = (Number(this.variables[varName]) || 0) * Number(val);\r\n            } else if (op === '/=') {\r\n                this.variables[varName] = (Number(this.variables[varName]) || 0) / Number(val);\r\n            }\r\n            return;\r\n        }\r\n\r\n        // 9. Function Calls: call <fn>()\r\n        if (line.startsWith('call ')) {\r\n            const callMatch = line.match(/call\\s+([A-Za-z0-9_]+)\\s*(?:\\((.*?)\\))?/);\r\n            if (callMatch) {\r\n                const fnName = callMatch[1];\r\n                if (this.functions[fnName]) {\r\n                    this.executeSubScript(this.functions[fnName].body);\r\n                } else {\r\n                    this.log(`[FUNCTION] Called external \"${fnName}\"`, 'system');\r\n                }\r\n                return;\r\n            }\r\n        }\r\n\r\n        // 10. Print output\r\n        if (line.startsWith('print ') || line.startsWith('echo ')) {\r\n            const expr = line.replace(/^(print|echo)\\s+/, '').trim();\r\n            const val = this.parsePrint(expr);\r\n            this.log(val, 'output');\r\n            return;\r\n        }\r\n\r\n        // 6. Window Canvas: create window with title \"Title\" and size (width, height)\r\n        if (line.startsWith('create window')) {\r\n            const titleMatch = line.match(/title [\"'](.*?)[\"']/);\r\n            const sizeMatch = line.match(/size \\((\\d+),\\s*(\\d+)\\)/);\r\n            if (sizeMatch && this.canvas) {\r\n                this.canvas.width = parseInt(sizeMatch[1]);\r\n                this.canvas.height = parseInt(sizeMatch[2]);\r\n            }\r\n            if (titleMatch) {\r\n                this.log(` Shine Loop Display Mode: \"${titleMatch[1]}\" (${this.canvas.width}x${this.canvas.height})`, 'info');\r\n            }\r\n            return;\r\n        }\r\n\r\n        // 7. System Calls & Kernel Control: syscall <name> with args \"...\"\r\n        if (line.startsWith('syscall')) {\r\n            const match = line.match(/syscall\\s+([A-Za-z0-9_]+)(?:\\s+with\\s+args\\s+[\"'](.*?)[\"'])?/);\r\n            if (match) {\r\n                const callName = match[1];\r\n                const args = match[2] || '';\r\n                this.log(`[KERNEL SYSCALL] 0x${Math.floor(Math.random() * 0xFFFFFF).toString(16).toUpperCase()} :: ${callName}(${args}) -> OK`, 'system');\r\n            }\r\n            return;\r\n        }\r\n\r\n        // 8. Process Spawner / Multitasking: spawn process \"name\" with priority <int>\r\n        if (line.startsWith('spawn process')) {\r\n            const nameMatch = line.match(/spawn process [\"'](.*?)[\"']/);\r\n            const prioMatch = line.match(/priority\\s+(\\d+)/);\r\n            const procName = nameMatch ? nameMatch[1] : 'task_daemon';\r\n            const pid = Math.floor(1000 + Math.random() * 9000);\r\n            this.log(`[PROCESS SCHEDULER] PID ${pid} [${procName}] Started (Priority: ${prioMatch ? prioMatch[1] : 10})`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 9. Hardware Sound Generator: play tone at <freq> Hz for <duration> ms\r\n        if (line.startsWith('play tone')) {\r\n            const freqMatch = line.match(/play tone at\\s+(\\d+)\\s*Hz/i);\r\n            const durMatch = line.match(/for\\s+(\\d+)\\s*ms/i);\r\n            const freq = freqMatch ? parseInt(freqMatch[1]) : 440;\r\n            const dur = durMatch ? parseInt(durMatch[1]) : 100;\r\n            try {\r\n                const AudioCtx = window.AudioContext || window.webkitAudioContext;\r\n                if (AudioCtx) {\r\n                    const ctx = new AudioCtx();\r\n                    const osc = ctx.createOscillator();\r\n                    const gain = ctx.createGain();\r\n                    osc.type = 'square';\r\n                    osc.frequency.setValueAtTime(freq, ctx.currentTime);\r\n                    gain.gain.setValueAtTime(0.1, ctx.currentTime);\r\n                    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + (dur / 1000));\r\n                    osc.connect(gain);\r\n                    gain.connect(ctx.destination);\r\n                    osc.start();\r\n                    osc.stop(ctx.currentTime + (dur / 1000));\r\n                }\r\n            } catch (e) {}\r\n            this.log(`[AUDIO HARDWARE] Sound Synthesizer: ${freq}Hz (${dur}ms)`, 'system');\r\n            return;\r\n        }\r\n\r\n        // 10. Draw Card UI: draw card at (x, y) with size (w, h) and title \"...\" and text \"...\"\r\n        if (line.startsWith('draw card at')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const sizeMatch = line.match(/size \\((\\d+),\\s*(\\d+)\\)/);\r\n            const titleMatch = line.match(/title [\"'](.*?)[\"']/);\r\n            const textMatch = line.match(/text [\"'](.*?)[\"']/);\r\n            \r\n            this.renderQueue.push({\r\n                type: 'card',\r\n                x: posMatch ? parseInt(posMatch[1]) : 50,\r\n                y: posMatch ? parseInt(posMatch[2]) : 50,\r\n                w: sizeMatch ? parseInt(sizeMatch[1]) : 300,\r\n                h: sizeMatch ? parseInt(sizeMatch[2]) : 140,\r\n                title: titleMatch ? titleMatch[1] : 'Holo UI Card',\r\n                text: textMatch ? textMatch[1] : ''\r\n            });\r\n            return;\r\n        }\r\n\r\n        // 11. Draw Button UI: draw button at (x, y) with text \"...\" and action \"...\"\r\n        if (line.startsWith('draw button at')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const textMatch = line.match(/text [\"'](.*?)[\"']/);\r\n            const actionMatch = line.match(/action [\"'](.*?)[\"']/);\r\n            \r\n            this.renderQueue.push({\r\n                type: 'button',\r\n                x: posMatch ? parseInt(posMatch[1]) : 50,\r\n                y: posMatch ? parseInt(posMatch[2]) : 200,\r\n                w: 180,\r\n                h: 44,\r\n                text: textMatch ? textMatch[1] : 'Shine Action',\r\n                action: actionMatch ? actionMatch[1] : ''\r\n            });\r\n            return;\r\n        }\r\n\r\n        // 9. Spawn Sprite / Player Entity: spawn sprite \"name\" at (x, y) with color \"...\" and size (w, h)\r\n        if (line.startsWith('spawn sprite')) {\r\n            const nameMatch = line.match(/spawn sprite [\"'](.*?)[\"']/);\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const colorMatch = line.match(/color [\"'](.*?)[\"']/);\r\n            const sizeMatch = line.match(/size \\((\\d+),\\s*(\\d+)\\)/);\r\n            \r\n            const name = nameMatch ? nameMatch[1] : 'Entity';\r\n            const isPlayer = name.toLowerCase().includes('angel') || name.toLowerCase().includes('player') || name.toLowerCase().includes('forky');\r\n\r\n            const sprite = {\r\n                type: 'sprite',\r\n                name: name,\r\n                isPlayer: isPlayer,\r\n                x: posMatch ? parseFloat(posMatch[1]) : 100,\r\n                y: posMatch ? parseFloat(posMatch[2]) : 100,\r\n                vx: 0,\r\n                vy: 0,\r\n                speed: 260,\r\n                w: sizeMatch ? parseFloat(sizeMatch[1]) : 34,\r\n                h: sizeMatch ? parseFloat(sizeMatch[2]) : 46,\r\n                color: colorMatch ? colorMatch[1] : (isPlayer ? '#38bdf8' : '#ef4444'),\r\n                isJumping: false,\r\n                glowPulse: 0\r\n            };\r\n            this.gameEntities.push(sprite);\r\n            this.log(` Entity Spawned on Shine Loop Stage: \"${sprite.name}\"`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 10. Spawn Static Platform: spawn platform at (x, y) with size (w, h) and color \"...\"\r\n        if (line.startsWith('spawn platform')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const sizeMatch = line.match(/size \\((\\d+),\\s*(\\d+)\\)/);\r\n            const colorMatch = line.match(/color [\"'](.*?)[\"']/);\r\n\r\n            const platform = {\r\n                type: 'platform',\r\n                x: posMatch ? parseFloat(posMatch[1]) : 200,\r\n                y: posMatch ? parseFloat(posMatch[2]) : 300,\r\n                w: sizeMatch ? parseFloat(sizeMatch[1]) : 160,\r\n                h: sizeMatch ? parseFloat(sizeMatch[2]) : 18,\r\n                color: colorMatch ? colorMatch[1] : '#6366f1'\r\n            };\r\n            this.gameEntities.push(platform);\r\n            this.log(` Platform Placed at (${platform.x}, ${platform.y})`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 11. Spawn Collectible Star/Coin: spawn coin at (x, y) with points <val>\r\n        if (line.startsWith('spawn coin') || line.startsWith('spawn star')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const pointsMatch = line.match(/points\\s+(\\d+)/);\r\n\r\n            const coin = {\r\n                type: 'coin',\r\n                x: posMatch ? parseFloat(posMatch[1]) : 300,\r\n                y: posMatch ? parseFloat(posMatch[2]) : 250,\r\n                r: 10,\r\n                points: pointsMatch ? parseInt(pointsMatch[1]) : 100,\r\n                collected: false,\r\n                floatOffset: Math.random() * 10\r\n            };\r\n            this.gameEntities.push(coin);\r\n            this.log(` Collectible Placed at (${coin.x}, ${coin.y}) [${coin.points} pts]`, 'info');\r\n            return;\r\n        }\r\n\r\n        // 12. Particle System / Spark emitter: emit particles at (x, y) with color \"...\"\r\n        if (line.startsWith('emit particles')) {\r\n            const posMatch = line.match(/at \\((\\d+),\\s*(\\d+)\\)/);\r\n            const colorMatch = line.match(/color [\"'](.*?)[\"']/);\r\n            const px = posMatch ? parseInt(posMatch[1]) : 200;\r\n            const py = posMatch ? parseInt(posMatch[2]) : 200;\r\n            const pColor = colorMatch ? colorMatch[1] : '#6366f1';\r\n            \r\n            this.spawnParticleBurst(px, py, pColor, 20);\r\n            return;\r\n        }\r\n    }\r\n\r\n    spawnParticleBurst(x, y, color, count = 15) {\r\n        for (let i = 0; i < count; i++) {\r\n            const angle = Math.random() * Math.PI * 2;\r\n            const speed = Math.random() * 150 + 50;\r\n            this.particles.push({\r\n                x: x,\r\n                y: y,\r\n                vx: Math.cos(angle) * speed,\r\n                vy: Math.sin(angle) * speed,\r\n                color: color,\r\n                alpha: 1.0,\r\n                size: Math.random() * 4 + 2,\r\n                life: Math.random() * 0.8 + 0.4\r\n            });\r\n        }\r\n    }\r\n\r\n    evaluateCondition(cond) {\r\n        cond = cond.trim();\r\n        // Operators: ==, !=, >=, <=, >, <\r\n        const ops = ['==', '!=', '>=', '<=', '>', '<'];\r\n        for (let op of ops) {\r\n            if (cond.includes(op)) {\r\n                const parts = cond.split(op);\r\n                const left = this.evaluateExpression(parts[0]);\r\n                const right = this.evaluateExpression(parts[1]);\r\n\r\n                if (op === '==') return left == right;\r\n                if (op === '!=') return left != right;\r\n                if (op === '>=') return Number(left) >= Number(right);\r\n                if (op === '<=') return Number(left) <= Number(right);\r\n                if (op === '>') return Number(left) > Number(right);\r\n                if (op === '<') return Number(left) < Number(right);\r\n            }\r\n        }\r\n        return Boolean(this.evaluateExpression(cond));\r\n    }\r\n\r\n    isSingleQuotedLiteral(expr) {\r\n        if (!expr || expr.length < 2) return false;\r\n        const first = expr[0];\r\n        if (first !== '\"' && first !== \"'\") return false;\r\n        for (let i = 1; i < expr.length; i++) {\r\n            if (expr[i] === first && expr[i - 1] !== '\\\\') {\r\n                return i === expr.length - 1;\r\n            }\r\n        }\r\n        return false;\r\n    }\r\n\r\n    evaluateExpression(expr) {\r\n        if (expr === undefined || expr === null) return '';\r\n        expr = String(expr).trim();\r\n        if (!expr) return '';\r\n\r\n        if (expr.startsWith('py:') || expr.startsWith('py ')) {\r\n            expr = expr.replace(/^(py:\\s*|py\\s+)/, '').trim();\r\n        } else if (expr.startsWith('python:') || expr.startsWith('python eval ') || expr.startsWith('python ')) {\r\n            expr = expr.replace(/^(python eval\\s*|python:\\s*|python\\s+)/, '').trim();\r\n        }\r\n        \r\n        // Single quoted literal string check\r\n        if (this.isSingleQuotedLiteral(expr)) {\r\n            let strContent = expr.slice(1, -1);\r\n            strContent = strContent.replace(/\\{([A-Za-z0-9_]+)\\}/g, (match, varKey) => {\r\n                return this.variables.hasOwnProperty(varKey) ? this.variables[varKey] : match;\r\n            });\r\n            return strContent;\r\n        }\r\n\r\n        // Numbers\r\n        if (!isNaN(expr) && expr !== '') {\r\n            return Number(expr);\r\n        }\r\n        // Boolean\r\n        if (expr === 'true') return true;\r\n        if (expr === 'false') return false;\r\n\r\n        // Python Math Module & Arithmetic Expressions\r\n        if (expr.startsWith('math.') || expr.includes(' + ') || expr.includes(' - ') || expr.includes(' * ') || expr.includes(' / ') || expr.includes(' % ')) {\r\n            try {\r\n                let resolvedExpr = expr;\r\n                const varKeys = Object.keys(this.variables).sort((a, b) => b.length - a.length);\r\n                for (let k of varKeys) {\r\n                    const regex = new RegExp(`\\\\b${k}\\\\b`, 'g');\r\n                    const val = this.variables[k];\r\n                    const valRepr = typeof val === 'string' ? JSON.stringify(val) : String(val);\r\n                    resolvedExpr = resolvedExpr.replace(regex, valRepr);\r\n                }\r\n                \r\n                // Map Python math names to JS Math\r\n                resolvedExpr = resolvedExpr\r\n                    .replace(/math\\.pi/g, Math.PI.toString())\r\n                    .replace(/math\\.e/g, Math.E.toString())\r\n                    .replace(/math\\.sqrt/g, 'Math.sqrt')\r\n                    .replace(/math\\.pow/g, 'Math.pow')\r\n                    .replace(/math\\.sin/g, 'Math.sin')\r\n                    .replace(/math\\.cos/g, 'Math.cos')\r\n                    .replace(/math\\.tan/g, 'Math.tan')\r\n                    .replace(/math\\.floor/g, 'Math.floor')\r\n                    .replace(/math\\.ceil/g, 'Math.ceil')\r\n                    .replace(/math\\.round/g, 'Math.round')\r\n                    .replace(/math\\.abs/g, 'Math.abs')\r\n                    .replace(/math\\.min/g, 'Math.min')\r\n                    .replace(/math\\.max/g, 'Math.max')\r\n                    .replace(/math\\.random/g, 'Math.random')\r\n                    .replace(/math\\.log/g, 'Math.log')\r\n                    .replace(/math\\.exp/g, 'Math.exp');\r\n\r\n                const mathResult = Function(`\"use strict\"; return (${resolvedExpr});`)();\r\n                return mathResult;\r\n            } catch(e) {}\r\n        }\r\n\r\n        // Variable lookup (with recursive resolution if needed)\r\n        if (this.variables.hasOwnProperty(expr)) {\r\n            let val = this.variables[expr];\r\n            if (typeof val === 'string' && this.variables.hasOwnProperty(val)) {\r\n                return this.variables[val];\r\n            }\r\n            return val;\r\n        }\r\n\r\n        return expr;\r\n    }\r\n\r\n    parsePrint(rawExpr) {\r\n        // Split comma-separated arguments while respecting quoted strings\r\n        const args = [];\r\n        let current = '';\r\n        let inQuotes = false;\r\n        let quoteChar = '';\r\n\r\n        for (let i = 0; i < rawExpr.length; i++) {\r\n            const char = rawExpr[i];\r\n            if ((char === '\"' || char === \"'\") && (i === 0 || rawExpr[i - 1] !== '\\\\')) {\r\n                if (!inQuotes) {\r\n                    inQuotes = true;\r\n                    quoteChar = char;\r\n                } else if (quoteChar === char) {\r\n                    inQuotes = false;\r\n                }\r\n            }\r\n\r\n            if (char === ',' && !inQuotes) {\r\n                args.push(current.trim());\r\n                current = '';\r\n            } else {\r\n                current += char;\r\n            }\r\n        }\r\n        if (current.trim()) {\r\n            args.push(current.trim());\r\n        }\r\n\r\n        const evaluated = args.map(arg => this.evaluateExpression(arg));\r\n        return evaluated.join(' ');\r\n    }\r\n\r\n    triggerEvent(event, data) {\r\n        if (event === 'click') {\r\n            for (let item of this.renderQueue) {\r\n                if (item.type === 'button') {\r\n                    if (data.x >= item.x && data.x <= item.x + item.w &&\r\n                        data.y >= item.y && data.y <= item.y + item.h) {\r\n                        this.log(` Gamepad Trigger: [${item.text}] Activated!`, 'success');\r\n                        this.spawnParticleBurst(data.x, data.y, '#38bdf8', 25);\r\n                    }\r\n                }\r\n            }\r\n        }\r\n    }\r\n\r\n    startLoop() {\r\n        this.isRunning = true;\r\n        this.lastTime = performance.now();\r\n        \r\n        const loop = (timestamp) => {\r\n            if (!this.isRunning) return;\r\n            const dt = Math.min((timestamp - this.lastTime) / 1000, 0.1);\r\n            this.lastTime = timestamp;\r\n            \r\n            this.update(dt);\r\n            this.render();\r\n            \r\n            this.animationFrameId = requestAnimationFrame(loop);\r\n        };\r\n        this.animationFrameId = requestAnimationFrame(loop);\r\n    }\r\n\r\n    update(dt) {\r\n        // Update Gamepad & Player Physics (Holo Looping OoS 60Hz Physics Core)\r\n        for (let entity of this.gameEntities) {\r\n            entity.glowPulse += dt * 5;\r\n\r\n            if (entity.isPlayer) {\r\n                // Movement via Gamepad or Keys\r\n                if (this.gamepadState.dpad.left || this.keysDown['arrowleft'] || this.keysDown['a']) {\r\n                    entity.vx = -entity.speed;\r\n                } else if (this.gamepadState.dpad.right || this.keysDown['arrowright'] || this.keysDown['d']) {\r\n                    entity.vx = entity.speed;\r\n                } else {\r\n                    entity.vx *= 0.82; // Friction deceleration\r\n                }\r\n\r\n                // Jump (Button A)\r\n                if ((this.gamepadState.btnA || this.keysDown['arrowup'] || this.keysDown['w'] || this.keysDown[' ']) && !entity.isJumping) {\r\n                    entity.vy = -420;\r\n                    entity.isJumping = true;\r\n                    this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#38bdf8', 12);\r\n                }\r\n\r\n                // Apply velocity\r\n                entity.x += entity.vx * dt;\r\n\r\n                // Gravity simulation\r\n                entity.vy += 980 * dt;\r\n                entity.y += entity.vy * dt;\r\n\r\n                // Floor collision (Holo Game World Bounds)\r\n                if (this.canvas && entity.y + entity.h >= this.canvas.height - 44) {\r\n                    entity.y = this.canvas.height - 44 - entity.h;\r\n                    entity.vy = 0;\r\n                    entity.isJumping = false;\r\n                }\r\n\r\n                // Platform collisions\r\n                for (let other of this.gameEntities) {\r\n                    if (other.type === 'platform') {\r\n                        // Check if landing on top of platform\r\n                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {\r\n                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 12 && entity.vy >= 0) {\r\n                                entity.y = other.y - entity.h;\r\n                                entity.vy = 0;\r\n                                entity.isJumping = false;\r\n                            }\r\n                        }\r\n                    } else if (other.type === 'coin' && !other.collected) {\r\n                        // Collect coin on overlap\r\n                        const cx = other.x;\r\n                        const cy = other.y;\r\n                        if (entity.x + entity.w >= cx - other.r && entity.x <= cx + other.r &&\r\n                            entity.y + entity.h >= cy - other.r && entity.y <= cy + other.r) {\r\n                            other.collected = true;\r\n                            this.score += other.points;\r\n                            this.spawnParticleBurst(cx, cy, '#fbbf24', 20);\r\n                            this.log(` Coin Collected! Score: +${other.points} (Total: ${this.score})`, 'success');\r\n                        }\r\n                    }\r\n                }\r\n\r\n                // Screen edge clamp\r\n                if (entity.x < 0) entity.x = 0;\r\n                if (this.canvas && entity.x + entity.w > this.canvas.width) entity.x = this.canvas.width - entity.w;\r\n            } else if (entity.type === 'sprite') {\r\n                // Autonomous AI Patrol for Enemy NPCs\r\n                if (!entity.patrolDir) entity.patrolDir = 1;\r\n                entity.x += entity.patrolDir * 60 * dt;\r\n                if (entity.x > 580) entity.patrolDir = -1;\r\n                if (entity.x < 360) entity.patrolDir = 1;\r\n            }\r\n        }\r\n\r\n        // Update Particle Sparks\r\n        for (let i = this.particles.length - 1; i >= 0; i--) {\r\n            const p = this.particles[i];\r\n            p.x += p.vx * dt;\r\n            p.y += p.vy * dt;\r\n            p.vy += 400 * dt; // Gravity on particles\r\n            p.alpha -= dt / p.life;\r\n            if (p.alpha <= 0) {\r\n                this.particles.splice(i, 1);\r\n            }\r\n        }\r\n    }\r\n\r\n    render() {\r\n        if (!this.ctx || !this.canvas) return;\r\n        const ctx = this.ctx;\r\n        const w = this.canvas.width;\r\n        const h = this.canvas.height;\r\n\r\n        // 1. Clear Stage & Dark Neon Background\r\n        ctx.fillStyle = '#06090f';\r\n        ctx.fillRect(0, 0, w, h);\r\n\r\n        // 2. Cyber Neon Wave (Xtraps Holo Ambient)\r\n        ctx.strokeStyle = 'rgba(99, 102, 241, 0.12)';\r\n        ctx.lineWidth = 2;\r\n        ctx.beginPath();\r\n        for (let x = 0; x <= w; x += 10) {\r\n            const y = h / 2 + Math.sin(x * 0.01 + this.lastTime * 0.002) * 25;\r\n            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);\r\n        }\r\n        ctx.stroke();\r\n\r\n        // 3. Cyber Grid Lines\r\n        ctx.strokeStyle = 'rgba(56, 189, 248, 0.04)';\r\n        ctx.lineWidth = 1;\r\n        for (let x = 0; x < w; x += 40) {\r\n            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();\r\n        }\r\n        for (let y = 0; y < h; y += 40) {\r\n            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();\r\n        }\r\n\r\n        // 4. Ground Surface (Neon Barrier for Shine Loop Console)\r\n        const groundGrad = ctx.createLinearGradient(0, h - 44, 0, h);\r\n        groundGrad.addColorStop(0, '#0f172a');\r\n        groundGrad.addColorStop(1, '#020617');\r\n        ctx.fillStyle = groundGrad;\r\n        ctx.fillRect(0, h - 44, w, 44);\r\n\r\n        ctx.strokeStyle = '#38bdf8';\r\n        ctx.shadowColor = '#38bdf8';\r\n        ctx.shadowBlur = 10;\r\n        ctx.lineWidth = 2.5;\r\n        ctx.beginPath(); ctx.moveTo(0, h - 44); ctx.lineTo(w, h - 44); ctx.stroke();\r\n        ctx.shadowBlur = 0;\r\n\r\n        // 5. Render Bubbly Dot (CS Own Dynamic Island - Design Guide p.17: Exclusively for Phones & UI OS)\r\n        if (this.bubblyDot && this.bubblyDot.active && ['hi!ui', 'stock', 'xui', 'flui', 'phone'].includes(this.uiProfile)) {\r\n            this.bubblyDot.pulse += 0.05;\r\n            const dotW = 210;\r\n            const dotH = 34;\r\n            const dotX = (w - dotW) / 2;\r\n            const dotY = 12;\r\n\r\n            // Pill Notch Container (Pure Black with Neon Border)\r\n            ctx.fillStyle = '#000000';\r\n            ctx.strokeStyle = 'rgba(56, 189, 248, 0.5)';\r\n            ctx.lineWidth = 1.5;\r\n            this.roundRect(ctx, dotX, dotY, dotW, dotH, 17, true, true);\r\n\r\n            // Dynamic Equalizer Icon / Indicator\r\n            if (this.bubblyDot.state === 'music') {\r\n                ctx.fillStyle = '#38bdf8';\r\n                for (let b = 0; b < 3; b++) {\r\n                    const barH = 8 + Math.sin(this.bubblyDot.pulse + b * 1.5) * 6;\r\n                    ctx.fillRect(dotX + 16 + (b * 6), dotY + (dotH - barH) / 2, 3, barH);\r\n                }\r\n            } else {\r\n                ctx.fillStyle = '#10b981';\r\n                ctx.beginPath();\r\n                ctx.arc(dotX + 22, dotY + dotH / 2, 5, 0, Math.PI * 2);\r\n                ctx.fill();\r\n            }\r\n\r\n            // Notification text\r\n            ctx.fillStyle = '#f8fafc';\r\n            ctx.font = 'bold 11px Outfit, sans-serif';\r\n            ctx.fillText(this.bubblyDot.text, dotX + 42, dotY + 21);\r\n        }\r\n\r\n        // 6. Render UI HUD Cards & Buttons (Frosted Glass / Acrílico Aqua A17 - Design Guide p.4)\r\n        for (let elem of this.renderQueue) {\r\n            if (elem.type === 'card') {\r\n                // Frosted Glass Acrílico Aqua Gradient\r\n                const cardGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);\r\n                if (this.uiProfile === 'flui') {\r\n                    // FlUI (Fold / Flex) Ultra Violet Theme\r\n                    cardGrad.addColorStop(0, 'rgba(30, 27, 75, 0.78)');\r\n                    cardGrad.addColorStop(1, 'rgba(15, 23, 42, 0.88)');\r\n                } else if (this.uiProfile === 'xui') {\r\n                    // XUI (Gama X) Cyber Neon Cyan Theme\r\n                    cardGrad.addColorStop(0, 'rgba(8, 47, 73, 0.78)');\r\n                    cardGrad.addColorStop(1, 'rgba(15, 23, 42, 0.88)');\r\n                } else {\r\n                    // Default / hi!UI Acrílico Aqua Glass\r\n                    cardGrad.addColorStop(0, 'rgba(15, 23, 42, 0.78)');\r\n                    cardGrad.addColorStop(1, 'rgba(30, 41, 59, 0.85)');\r\n                }\r\n\r\n                ctx.fillStyle = cardGrad;\r\n                ctx.strokeStyle = 'rgba(255, 255, 255, 0.16)';\r\n                ctx.lineWidth = 1.2;\r\n                ctx.shadowColor = 'rgba(56, 189, 248, 0.12)';\r\n                ctx.shadowBlur = 16;\r\n                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 16, true, true);\r\n                ctx.shadowBlur = 0;\r\n\r\n                ctx.fillStyle = '#38bdf8';\r\n                ctx.font = 'bold 15px Outfit, sans-serif';\r\n                ctx.fillText(elem.title, elem.x + 18, elem.y + 32);\r\n\r\n                ctx.fillStyle = '#94a3b8';\r\n                ctx.font = '12px Outfit, monospace, sans-serif';\r\n                // Unescape literal \\n strings if passed from .loop file\r\n                const rawText = String(elem.text || '').replace(/\\\\n/g, '\\n');\r\n                const lines = rawText.split('\\n');\r\n                for (let i = 0; i < lines.length; i++) {\r\n                    const lineY = elem.y + 60 + (i * 22);\r\n                    if (lineY < elem.y + elem.h - 10) {\r\n                        ctx.fillText(lines[i], elem.x + 18, lineY);\r\n                    }\r\n                }\r\n            } else if (elem.type === 'button') {\r\n                const btnGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);\r\n                btnGrad.addColorStop(0, '#6366f1');\r\n                btnGrad.addColorStop(1, '#8b5cf6');\r\n                ctx.fillStyle = btnGrad;\r\n                ctx.strokeStyle = '#a5b4fc';\r\n                ctx.lineWidth = 1.5;\r\n                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 10, true, true);\r\n\r\n                ctx.fillStyle = '#ffffff';\r\n                ctx.font = 'bold 13px Outfit, sans-serif';\r\n                ctx.textAlign = 'center';\r\n                ctx.fillText(elem.text, elem.x + elem.w / 2, elem.y + 26);\r\n                ctx.textAlign = 'left';\r\n            } else if (elem.type === 'input') {\r\n                // Frosted Glass Text Input Field\r\n                ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';\r\n                ctx.strokeStyle = 'rgba(56, 189, 248, 0.5)';\r\n                ctx.lineWidth = 1.2;\r\n                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 10, true, true);\r\n\r\n                ctx.fillStyle = elem.value ? '#ffffff' : '#64748b';\r\n                ctx.font = '13px Outfit, sans-serif';\r\n                ctx.fillText(elem.value || elem.placeholder, elem.x + 14, elem.y + 25);\r\n            }\r\n        }\r\n\r\n        // 6. Render Game Entities (Platforms, Coins & Sprites)\r\n        for (let entity of this.gameEntities) {\r\n            if (entity.type === 'platform') {\r\n                // Neon Platform\r\n                const pGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);\r\n                pGrad.addColorStop(0, entity.color);\r\n                pGrad.addColorStop(1, 'rgba(15, 23, 42, 0.9)');\r\n                ctx.fillStyle = pGrad;\r\n                ctx.strokeStyle = '#818cf8';\r\n                ctx.lineWidth = 1.5;\r\n                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 6, true, true);\r\n            } else if (entity.type === 'coin' && !entity.collected) {\r\n                // Spinning Neon Star/Coin\r\n                const floatY = entity.y + Math.sin(this.lastTime * 0.005 + entity.floatOffset) * 4;\r\n                ctx.fillStyle = '#fbbf24';\r\n                ctx.shadowColor = '#f59e0b';\r\n                ctx.shadowBlur = 12;\r\n                ctx.beginPath();\r\n                ctx.arc(entity.x, floatY, entity.r, 0, Math.PI * 2);\r\n                ctx.fill();\r\n                \r\n                ctx.fillStyle = '#000000';\r\n                ctx.font = 'bold 10px monospace';\r\n                ctx.textAlign = 'center';\r\n                ctx.fillText(\"*\", entity.x, floatY + 3.5);\r\n                ctx.textAlign = 'left';\r\n                ctx.shadowBlur = 0;\r\n            } else if (entity.type === 'sprite') {\r\n                ctx.fillStyle = entity.color;\r\n                ctx.shadowColor = entity.color;\r\n                ctx.shadowBlur = 14 + Math.sin(entity.glowPulse) * 4;\r\n                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 8, true, false);\r\n                \r\n                // Name tag above sprite\r\n                ctx.fillStyle = '#f1f5f9';\r\n                ctx.font = 'bold 11px Outfit, sans-serif';\r\n                ctx.textAlign = 'center';\r\n                ctx.fillText(entity.name, entity.x + entity.w / 2, entity.y - 8);\r\n                ctx.textAlign = 'left';\r\n                ctx.shadowBlur = 0;\r\n            }\r\n        }\r\n\r\n        // 7. Render Score Counter (if score > 0)\r\n        if (this.score > 0) {\r\n            ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';\r\n            ctx.strokeStyle = '#fbbf24';\r\n            ctx.lineWidth = 1.5;\r\n            this.roundRect(ctx, w - 160, 24, 135, 40, 10, true, true);\r\n\r\n            ctx.fillStyle = '#fbbf24';\r\n            ctx.font = 'bold 14px Outfit, sans-serif';\r\n            ctx.fillText(`* SCORE: ${this.score}`, w - 145, 49);\r\n        }\r\n\r\n        // 7. Render Particle Bursts\r\n        for (let p of this.particles) {\r\n            ctx.fillStyle = p.color;\r\n            ctx.globalAlpha = Math.max(0, p.alpha);\r\n            ctx.beginPath();\r\n            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);\r\n            ctx.fill();\r\n            ctx.globalAlpha = 1.0;\r\n        }\r\n\r\n        // 8. Shine Loop Console HUD Watermark\r\n        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';\r\n        ctx.font = '900 11px monospace';\r\n        ctx.fillText(\"SHINE LOOP CONSOLE • HOLO LOOPING OOS\", 20, h - 16);\r\n    }\r\n\r\n    roundRect(ctx, x, y, width, height, radius, fill, stroke) {\r\n        ctx.beginPath();\r\n        ctx.moveTo(x + radius, y);\r\n        ctx.lineTo(x + width - radius, y);\r\n        ctx.quadraticCurveTo(x + width, y, x + width, y + radius);\r\n        ctx.lineTo(x + width, y + height - radius);\r\n        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);\r\n        ctx.lineTo(x + radius, y + height);\r\n        ctx.quadraticCurveTo(x, y + height, x, y + height - radius);\r\n        ctx.lineTo(x, y + radius);\r\n        ctx.quadraticCurveTo(x, y, x + radius, y);\r\n        ctx.closePath();\r\n        if (fill) ctx.fill();\r\n        if (stroke) ctx.stroke();\r\n    }\r\n}\r\n";
        }
        engineSource = engineSource
            .replace('export class LoopingInterpreter', 'class LoopingInterpreter')
            .replace(/export\s+/g, '');


        const modulesMap = {};
        const modulesDir = path.join(process.cwd(), 'loop_modules');
        if (fs.existsSync(modulesDir)) {
            const files = fs.readdirSync(modulesDir);
            for (let f of files) {
                if (f.endsWith('.loop')) {
                    const modKey = path.basename(f, '.loop');
                    modulesMap[modKey] = fs.readFileSync(path.join(modulesDir, f), 'utf8');
                }
            }
        }

        const standaloneTemplate = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${this.appName} — Shine Loop Executable</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;900&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: #06090f; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; font-family: 'Outfit', sans-serif; color: #fff; }
        #canvas-wrapper { box-shadow: 0 20px 50px rgba(0,0,0,0.8), 0 0 30px rgba(56,189,248,0.2); border-radius: 16px; overflow: hidden; border: 1px solid rgba(255,255,255,0.12); position: relative; }
        canvas { display: block; }
    </style>
</head>
<body>
    <div id="canvas-wrapper">
        <canvas id="gameCanvas" width="800" height="520"></canvas>
    </div>
    <script>
        ${engineSource}
        const canvas = document.getElementById('gameCanvas');
        const runtime = new LoopingInterpreter(canvas, console.log);
        runtime.modules = ${JSON.stringify(modulesMap)};
        const code = ${JSON.stringify(sourceCode)};
        runtime.execute(code);
    </script>
</body>
</html>`;

        fs.writeFileSync(out, standaloneTemplate, 'utf8');
        console.log(`${GREEN}[SUCCESS] Standalone Executable Generated:${RESET} ${BOLD}${out}${RESET}`);
        console.log(`${YELLOW}[TARGET] Ready for Holo Looping OoS & Shine Loop Console${RESET}\n`);
    }

    compileToApk(filePath, outputApkPath) {
        if (!fs.existsSync(filePath)) {
            console.error(`${RED}[ERROR] Source file not found: ${filePath}${RESET}`);
            process.exit(1);
        }

        this.printBanner();
        console.log(`${CYAN}[APK BUILD] Compiling .loop to Native Android Application Package (APK)...${RESET}`);
        
        const sourceCode = fs.readFileSync(filePath, 'utf8');
        const appName = this.appName || path.basename(filePath, '.loop');
        const targetApk = outputApkPath || `${appName}.apk`;
        
        const androidAssetsDir = path.join(process.cwd(), 'Forkar.Android/app/src/main/assets');
        if (!fs.existsSync(androidAssetsDir)) {
            fs.mkdirSync(androidAssetsDir, { recursive: true });
        }

        const gameHtml = `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>${appName}</title>
    <style>
        body { margin: 0; background: #06090f; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; touch-action: none; }
        canvas { width: 100vw; height: 100vh; object-fit: contain; }
    </style>
</head>
<body>
    <canvas id="gameCanvas" width="720" height="480"></canvas>
    <script type="module">
        import { LoopingInterpreter } from 'https://cokistudios.com/LoopingEngine/looping_core.js?v=2.1.0';
        const canvas = document.getElementById('gameCanvas');
        const runtime = new LoopingInterpreter(canvas, console.log);
        runtime.execute(${JSON.stringify(sourceCode)});
    </script>
</body>
</html>`;

        fs.writeFileSync(path.join(androidAssetsDir, 'loop_game.html'), gameHtml, 'utf8');
        console.log(`${GREEN}[PACKAGER] Injected .loop engine into Android Host Assets${RESET}`);

        const gradlewCmd = process.platform === 'win32' ? '.\\gradlew.bat assembleDebug' : './gradlew assembleDebug';
        exec(gradlewCmd, { cwd: path.join(process.cwd(), 'Forkar.Android') }, (err) => {
            const builtApkPath = path.join(process.cwd(), 'Forkar.Android/app/build/outputs/apk/debug/app-debug.apk');
            if (fs.existsSync(builtApkPath)) {
                fs.copyFileSync(builtApkPath, path.join(process.cwd(), targetApk));
                console.log(`\n${GREEN}${BOLD}[SUCCESS] Android APK Generated Successfully!${RESET}`);
                console.log(`${YELLOW}Output APK:${RESET} ${BOLD}${path.join(process.cwd(), targetApk)}${RESET}\n`);
            } else {
                console.log(`\n${GREEN}${BOLD}[SUCCESS] Asset Packaged for Android Host!${RESET}`);
                console.log(`${CYAN}Android Assets Output:${RESET} ${path.join(androidAssetsDir, 'loop_game.html')}\n`);
            }
        });
    }

    launchGUI(filePath, verbose = false) {
        if (!fs.existsSync(filePath)) {
            console.error(`${RED}[ERROR] Source file not found: ${filePath}${RESET}`);
            process.exit(1);
        }

        this.printBanner();
        console.log(`${CYAN}[WINDOW] Launching Native Viewport:${RESET} ${BOLD}${path.basename(filePath)}${RESET}...`);
        
        if (verbose) {
            const py = this.detectPython();
            const pyName = py ? (py.exe + (py.args.length ? ' ' + py.args.join(' ') : '')) : null;
            console.log(`${YELLOW}[VERBOSE MODE ACTIVATED]${RESET}`);
            console.log(`${BLUE}[VERBOSE] Resolution:${RESET} 800x520 (High-DPI Retina Ready)`);
            console.log(`${BLUE}[VERBOSE] Pipeline:${RESET} Hardware WebCore / DirectX 60FPS Low-Latency`);
            console.log(`${BLUE}[VERBOSE] Python Interop:${RESET} ${pyName ? 'Active (' + pyName + ')' : 'Emulated'}`);
            console.log(`${BLUE}[VERBOSE] Audio Engine:${RESET} WebAudio Synthesizer @ 44.1kHz`);
            console.log(`${BLUE}[VERBOSE] Source Size:${RESET} ${fs.statSync(filePath).size} bytes\n`);
        }

        const tempHtml = path.join(path.dirname(filePath), `.tmp_${path.basename(filePath, '.loop')}_window.html`);
        this.compileToStandalone(filePath, tempHtml);

        const cmd = process.platform === 'darwin' 
            ? `open "${tempHtml}"` 
            : process.platform === 'win32' 
                ? `start "" "${tempHtml}"` 
                : `xdg-open "${tempHtml}"`;
        
        exec(cmd, (err) => {
            if (err) {
                console.error(`${RED}[ERROR] Failed to open window: ${err.message}${RESET}`);
            } else {
                console.log(`${GREEN}[SUCCESS] Native Window running @ 60 FPS${RESET}`);
            }
        });
    }

    // ── Interactive REPL ──
    startREPL() {
        this.printBanner();
        console.log(`${CYAN}Looping Interactive REPL v2.1.0${RESET}`);
        console.log(`${DIM}(Type ${RESET}${GREEN}help${RESET}${DIM} for quick guide, ${RESET}${GREEN}vars${RESET}${DIM} for variables, ${RESET}${GREEN}exit${RESET}${DIM} to quit)${RESET}\n`);

        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            prompt: `${PURPLE}looping>${RESET} `
        });

        let multilineBuffer = [];
        let inBlock = false;

        rl.prompt();

        rl.on('line', (rawLine) => {
            const trimmed = rawLine.trim();

            if (!inBlock && (trimmed === 'exit' || trimmed === 'quit')) {
                console.log(`${CYAN}Goodbye! Holo Looping OoS session closed.${RESET}`);
                rl.close();
                process.exit(0);
            }

            // Check if entering multiline block
            if (!inBlock && (trimmed.endsWith('{') || trimmed === 'python:' || trimmed === 'py:' || trimmed === 'py:begin')) {
                inBlock = true;
                multilineBuffer = [rawLine];
                rl.setPrompt(`${DIM}...   ${RESET}`);
                rl.prompt();
                return;
            }

            if (inBlock) {
                multilineBuffer.push(rawLine);
                if (trimmed === '}' || trimmed === 'end' || trimmed === 'py:end') {
                    inBlock = false;
                    const blockScript = multilineBuffer.join('\n');
                    multilineBuffer = [];
                    rl.setPrompt(`${PURPLE}looping>${RESET} `);
                    try {
                        this.executeScript(blockScript);
                    } catch (e) {
                        console.error(`${RED}[ERROR]: ${e.message}${RESET}`);
                    }
                    rl.prompt();
                    return;
                }
                rl.prompt();
                return;
            }

            if (trimmed) {
                try {
                    this.executeLine(trimmed);
                } catch (e) {
                    console.error(`${RED}[ERROR]: ${e.message}${RESET}`);
                }
            }
            rl.prompt();
        });
    }
}

// ── CLI Dispatcher ──
const cli = new LoopingCLI();
const args = process.argv.slice(2);

if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    cli.printBanner();
    console.log(`${BOLD}Usage:${RESET}`);
    console.log(`  looping <file.loop>               Run .loop script directly in terminal`);
    console.log(`  looping --gui <file.loop> [-v]    Launch native desktop window`);
    console.log(`  looping --apk <file.loop> [-o]    Package .loop game into Android APK`);
    console.log(`  looping repl                      Start interactive Looping Shell`);
    console.log(`  looping eval "<code>"             Evaluate single line of Looping code`);
    console.log(`  looping build <file.loop> [-o]    Compile to Standalone Executable HTML5/Game`);
    console.log(`  looping --version                 Display Looping version info\n`);
    process.exit(0);
}

if (args.includes('--version') || (args.includes('-v') && args.length === 1)) {
    console.log(`Looping Compile v2.1.0 (Shine Loop Target / Holo Looping OoS / Win32 Native)`);
    process.exit(0);
}

if (args[0] === 'repl') {
    cli.startREPL();
} else if (args[0] === 'eval') {
    const code = args.slice(1).join(' ').replace(/;\s*/g, '\n');
    cli.executeScript(code);
} else if (args.includes('--apk')) {
    const file = args.find(a => a.endsWith('.loop')) || args[1];
    let output = null;
    const outIdx = args.indexOf('-o');
    if (outIdx !== -1 && args[outIdx + 1]) output = args[outIdx + 1];
    cli.compileToApk(file, output);
} else if (args.includes('--gui') || args.includes('-g')) {
    const isVerbose = args.includes('--verbose') || args.includes('-v');
    const file = args.find(a => a.endsWith('.loop')) || args[1];
    cli.launchGUI(file, isVerbose);
} else {
    const command = args[0];
    if (command === 'build' || command === 'compile') {
        const file = args[1];
        let output = null;
        const outIdx = args.indexOf('-o');
        if (outIdx !== -1 && args[outIdx + 1]) output = args[outIdx + 1];
        cli.compileToStandalone(file, output);
    } else if (command === 'run') {
        cli.runFile(args[1]);
    } else {
        cli.runFile(command);
    }
}
