"use strict";

const fs = require("fs");
const path = require("path");

function loadPrettier(workspaceRoot) {
    const candidates = [];
    if (workspaceRoot) {
        candidates.push(path.join(workspaceRoot, "node_modules", "prettier"));
    }
    if (process.env.APPDATA) {
        candidates.push(path.join(process.env.APPDATA, "npm", "node_modules", "prettier"));
    }
    const home = process.env.USERPROFILE || process.env.HOME;
    if (home) {
        candidates.push(path.join(home, ".smiledev", "tools", "prettier", "node_modules", "prettier"));
    }
    candidates.push(path.join(__dirname, "node_modules", "prettier"));

    for (const cand of candidates) {
        try {
            if (fs.existsSync(cand)) {
                return { prettier: require(cand), resolvedFrom: cand };
            }
        } catch {
            // Try next candidate
        }
    }

    const fallback = require("prettier");
    return { prettier: fallback, resolvedFrom: "require('prettier')" };
}

function parseCliArgs(argv) {
    const opts = {
        mode: "format",
        filepath: "untitled.js",
        workspace: "",
        defaults: {}
    };

    for (let i = 0; i < argv.length; i++) {
        const arg = argv[i];
        if (arg === "--check") opts.mode = "check";
        else if (arg === "--format") opts.mode = "format";
        else if (arg === "--version") opts.mode = "version";
        else if (arg === "--filepath" && i + 1 < argv.length) opts.filepath = argv[++i];
        else if (arg === "--workspace" && i + 1 < argv.length) opts.workspace = argv[++i];
        else if (arg === "--tab-width" && i + 1 < argv.length) opts.defaults.tabWidth = parseInt(argv[++i], 10) || 4;
        else if (arg === "--use-tabs") opts.defaults.useTabs = argv[++i] === "true";
        else if (arg === "--single-quote") opts.defaults.singleQuote = argv[++i] === "true";
        else if (arg === "--semi") opts.defaults.semi = argv[++i] === "true";
        else if (arg === "--print-width" && i + 1 < argv.length) opts.defaults.printWidth = parseInt(argv[++i], 10) || 100;
    }
    return opts;
}

function readStdin() {
    return new Promise((resolve, reject) => {
        const chunks = [];
        process.stdin.on("data", (chunk) => chunks.push(chunk));
        process.stdin.on("end", () => resolve(Buffer.concat(chunks).toString("utf8").replace(/^\uFEFF/, "")));
        process.stdin.on("error", reject);
    });
}

(async () => {
    const cli = parseCliArgs(process.argv.slice(2));
    const { prettier, resolvedFrom } = loadPrettier(cli.workspace);

    if (cli.mode === "version") {
        process.stdout.write(JSON.stringify({ ok: true, version: prettier.version, resolvedFrom }));
        return;
    }

    const input = await readStdin();
    const ext = path.extname(cli.filepath || "").toLowerCase();
    const isLooping = ext === ".loop" || ext === ".ruup" || ext === ".c2";

    let configFile = null;
    let resolvedConfig = null;
    try {
        configFile = await prettier.resolveConfigFile(cli.filepath);
        resolvedConfig = await prettier.resolveConfig(cli.filepath, { editorconfig: true });
    } catch {
        resolvedConfig = null;
    }

    const loopingPlugin = path.join(__dirname, "prettier-plugin-looping.cjs");
    const plugins = Array.isArray(resolvedConfig?.plugins) ? [...resolvedConfig.plugins] : [];
    if (isLooping && !plugins.includes(loopingPlugin)) {
        plugins.push(loopingPlugin);
    }

    const prettierOptions = {
        ...cli.defaults,
        ...(resolvedConfig || {}),
        filepath: cli.filepath,
        plugins
    };

    if (isLooping) {
        prettierOptions.parser = "looping-parse";
    } else {
        const info = await prettier.getFileInfo(cli.filepath, { plugins });
        if (!info.inferredParser) {
            process.stdout.write(
                JSON.stringify({
                    ok: false,
                    unsupported: true,
                    version: prettier.version,
                    resolvedFrom,
                    error: `Extensión no soportada por Prettier: ${ext || "(sin extensión)"}`
                })
            );
            return;
        }
    }

    if (cli.mode === "check") {
        const isFormatted = await prettier.check(input, prettierOptions);
        process.stdout.write(
            JSON.stringify({
                ok: true,
                formatted: input,
                changed: !isFormatted,
                isFormatted,
                version: prettier.version,
                configFile: configFile || "",
                resolvedFrom
            })
        );
        return;
    }

    const formatted = await prettier.format(input, prettierOptions);
    process.stdout.write(
        JSON.stringify({
            ok: true,
            formatted,
            changed: formatted !== input,
            version: prettier.version,
            configFile: configFile || "",
            resolvedFrom
        })
    );
})().catch((err) => {
    process.stdout.write(
        JSON.stringify({
            ok: false,
            error: err && err.message ? err.message : String(err)
        })
    );
    process.exitCode = 1;
});
