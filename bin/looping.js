#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════
// ♾️ LOOPING CLI — OFFICIAL RUNTIME EXECUTOR & COMPILER v2.1 (WINDOWS/CROSS-PLATFORM)
// Proprietary Language for Shine Loop Console & Holo Looping OoS
// Developed by Holo Entertainment (Coki Studios)
// ═══════════════════════════════════════════════════════════════

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { spawnSync, exec } from 'child_process';
import readline from 'readline';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

export class LoopingCLI {
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
        if (fs.existsSync(coreLocalPath)) {
            engineSource = fs.readFileSync(coreLocalPath, 'utf8')
                .replace('export class LoopingInterpreter', 'class LoopingInterpreter')
                .replace(/export\s+/g, '');
        }

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
