"use strict";

function formatLoopingSource(text, options) {
    const tabWidth = Number.isInteger(options.tabWidth) && options.tabWidth > 0 ? options.tabWidth : 4;
    const indentUnit = options.useTabs ? "\t" : " ".repeat(tabWidth);
    const eol = options.endOfLine === "crlf" ? "\r\n" : "\n";

    const lines = String(text ?? "").replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
    const out = [];
    let braceIndent = 0;
    let inColonBlock = false;
    let blankStreak = 0;

    for (const raw of lines) {
        const trim = raw.trim();
        if (trim.length === 0) {
            blankStreak += 1;
            if (blankStreak <= 1 && out.length > 0) {
                out.push("");
            }
            continue;
        }
        blankStreak = 0;

        const isClosingBrace = trim.startsWith("}") || trim.startsWith("]");
        if (isClosingBrace && braceIndent > 0) {
            braceIndent -= 1;
        }

        const isTopLevelDecl =
            trim.startsWith("define ") ||
            trim.startsWith("@app ") ||
            trim.startsWith("view ") ||
            trim.startsWith("component ");

        const isColonContinuation =
            trim.startsWith("elif ") ||
            trim.startsWith("else:") ||
            trim.startsWith("catch") ||
            trim.startsWith("finally:");

        if (isTopLevelDecl) {
            inColonBlock = false;
        }

        let effectiveIndent = braceIndent + (inColonBlock && !isTopLevelDecl ? 1 : 0);
        if (isColonContinuation && effectiveIndent > 0) {
            effectiveIndent -= 1;
        }

        out.push(indentUnit.repeat(Math.max(0, effectiveIndent)) + trim);

        const isComment = trim.startsWith("#") || trim.startsWith("//");
        if (!isComment) {
            if (trim.endsWith("{") || trim.endsWith("[")) {
                braceIndent += 1;
            } else if (
                trim.endsWith(":") &&
                (trim.startsWith("define ") ||
                    trim.startsWith("fn ") ||
                    trim.startsWith("if ") ||
                    trim.startsWith("elif ") ||
                    trim === "else:" ||
                    trim.startsWith("for ") ||
                    trim.startsWith("while ") ||
                    trim.startsWith("insert pysnippet") ||
                    trim === "code:")
            ) {
                inColonBlock = true;
            }
        }
    }

    while (out.length > 0 && out[out.length - 1] === "") {
        out.pop();
    }

    return out.join(eol) + eol;
}

module.exports = {
    languages: [
        {
            name: "Looping",
            extensions: [".loop", ".ruup"],
            parsers: ["looping-parse"]
        },
        {
            name: "Component2",
            extensions: [".c2"],
            parsers: ["looping-parse"]
        }
    ],
    parsers: {
        "looping-parse": {
            parse(text) {
                return {
                    type: "LoopingDocument",
                    body: String(text ?? "")
                };
            },
            astFormat: "looping-ast",
            locStart: () => 0,
            locEnd: (node) => (node.body ? node.body.length : 0)
        }
    },
    printers: {
        "looping-ast": {
            print(path, options) {
                const node = path.getValue();
                return formatLoopingSource(node.body, options);
            }
        }
    }
};
