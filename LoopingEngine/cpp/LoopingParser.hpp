#pragma once

#include "LoopingAST.hpp"
#include <string>
#include <vector>
#include <memory>
#include <sstream>
#include <cctype>
#include <regex>
#include <unordered_map>

namespace looping {

struct ParsedArgs {
    std::vector<std::string> positional;
    std::unordered_map<std::string, std::string> named;

    bool has(const std::string& key) const {
        return named.find(key) != named.end();
    }

    std::string get(const std::string& key, const std::string& def = "") const {
        auto it = named.find(key);
        if (it != named.end()) return it->second;
        return def;
    }

    double get_num(const std::string& key, double def = 0.0) const {
        auto it = named.find(key);
        if (it != named.end()) {
            try { return std::stod(it->second); } catch (...) {}
        }
        return def;
    }

    std::pair<double, double> get_pair(const std::string& key, std::pair<double, double> def = {0, 0}) const {
        auto it = named.find(key);
        if (it != named.end()) {
            std::string s = it->second;
            std::regex r(R"(\(?\s*([0-9\.\-]+)\s*,\s*([0-9\.\-]+)\s*\)?)");
            std::smatch m;
            if (std::regex_search(s, m, r)) {
                try {
                    return { std::stod(m[1]), std::stod(m[2]) };
                } catch (...) {}
            }
        }
        return def;
    }
};

class Parser {
public:
    std::string source;
    size_t pos = 0;

    Parser(const std::string& src) : source(src), pos(0) {}

    // Parse entire script into statements
    std::vector<std::shared_ptr<Stmt>> parse_script() {
        std::vector<std::shared_ptr<Stmt>> statements;
        std::vector<std::string> lines = split_lines(source);
        size_t line_idx = 0;

        while (line_idx < lines.size()) {
            std::string line = trim(lines[line_idx]);
            line_idx++;

            if (line.empty() || line.rfind("#", 0) == 0 || line.rfind("//", 0) == 0) {
                continue;
            }

            // 1. Python multiline block: py! { ... } OR py { ... } OR python { ... } OR py:begin ... py:end
            if (line.rfind("py! {", 0) == 0 || line.rfind("py {", 0) == 0 || line.rfind("python {", 0) == 0 || 
                line == "python:" || line == "py:" || line == "py:begin") {
                std::vector<std::string> py_lines;
                size_t brace_p = line.find('{');
                if (brace_p != std::string::npos && line.back() == '}' && line.size() > brace_p + 1) {
                    py_lines.push_back(line.substr(brace_p + 1, line.size() - brace_p - 2));
                } else {
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string trimmed_next = trim(next);
                        if (trimmed_next == "}" || trimmed_next == "end" || trimmed_next == "py:end") {
                            break;
                        }
                        py_lines.push_back(next);
                    }
                }
                statements.push_back(std::make_shared<PythonBlockStmt>(join_lines(dedent(py_lines))));
                continue;
            }

            // 2. Function definition: fn <name>(<args>) { ... } OR fn <name>(<args>) => <expr>
            if (line.rfind("fn ", 0) == 0 || line.rfind("fun ", 0) == 0 || 
                line.rfind("function ", 0) == 0 || line.rfind("def ", 0) == 0) {
                
                // One-line arrow body: fn add(a, b) => a + b
                if (line.find("=>") != std::string::npos) {
                    auto arrow = line.find("=>");
                    std::string head = trim(line.substr(0, arrow));
                    std::string body_expr = trim(line.substr(arrow + 2));
                    std::regex f_r(R"((?:fn|fun|function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\))");
                    std::smatch m;
                    if (std::regex_search(head, m, f_r)) {
                        std::string fn_name = m[1];
                        std::vector<std::string> params = split_params(m[2]);
                        std::vector<std::shared_ptr<Stmt>> body;
                        body.push_back(std::make_shared<ReturnStmt>(parse_single_expr(body_expr)));
                        statements.push_back(std::make_shared<FunctionDefStmt>(fn_name, params, body));
                        continue;
                    }
                }

                std::regex fn_regex(R"((?:fn|fun|function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*\{?)");
                std::smatch m;
                if (std::regex_search(line, m, fn_regex)) {
                    std::string fn_name = m[1];
                    std::vector<std::string> params = split_params(m[2]);
                    std::vector<std::string> body_lines;

                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        if (trim(next) == "}" || trim(next) == "end") break;
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<FunctionDefStmt>(fn_name, params, sub_p.parse_script()));
                    continue;
                }
            }

            // 3. For in Range Loop: for (i in 0..5) { ... } OR for i in 0..5 { ... }
            if (line.rfind("for ", 0) == 0 || line.rfind("for(", 0) == 0) {
                std::regex for_r(R"(for\s*\(?\s*([A-Za-z0-9_]+)\s+in\s+([0-9A-Za-z_\.]+)\s*\.\.\s*([0-9A-Za-z_\.]+)\s*\)?\s*\{?)");
                std::smatch m;
                if (std::regex_search(line, m, for_r)) {
                    std::string var_name = m[1];
                    auto start_expr = parse_single_expr(m[2]);
                    auto end_expr = parse_single_expr(m[3]);
                    std::vector<std::string> body_lines;

                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        if (trim(next) == "}" || trim(next) == "end") break;
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<ForRangeStmt>(var_name, start_expr, end_expr, sub_p.parse_script()));
                    continue;
                }
            }

            // 4. While loop: while (cond) { ... } OR while cond { ... }
            if (line.rfind("while ", 0) == 0 || line.rfind("while(", 0) == 0) {
                std::regex wh_regex(R"(while\s*\(?(.*?)\)?\s*\{)");
                std::smatch m;
                if (std::regex_search(line, m, wh_regex)) {
                    std::string cond_str = trim(m[1]);
                    if (cond_str.front() == '(' && cond_str.back() == ')') {
                        cond_str = trim(cond_str.substr(1, cond_str.size() - 2));
                    }
                    auto cond_expr = parse_single_expr(cond_str);
                    std::vector<std::string> body_lines;

                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        if (trim(next) == "}" || trim(next) == "end") break;
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<WhileStmt>(cond_expr, sub_p.parse_script()));
                    continue;
                }
            }

            // 5. Repeat / Loop count: loop (N) { ... } OR loop N { ... } OR repeat N times { ... }
            if (line.rfind("repeat ", 0) == 0 || line.rfind("loop ", 0) == 0 || line.rfind("loop(", 0) == 0) {
                // Infinite loop: loop { ... }
                if (line == "loop {" || line == "loop") {
                    std::vector<std::string> body_lines;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        if (trim(next) == "}" || trim(next) == "end") break;
                        body_lines.push_back(next);
                    }
                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<WhileStmt>(std::make_shared<LiteralExpr>(Value(true)), sub_p.parse_script()));
                    continue;
                }

                std::regex loop_regex(R"((?:repeat|loop)\s*\(?\s*(\d+|[A-Za-z0-9_]+)\s*\)?\s*(?:times)?\s*\{?)");
                std::smatch m;
                if (std::regex_search(line, m, loop_regex)) {
                    std::string count_str = m[1];
                    std::vector<std::string> body_lines;

                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        if (trim(next) == "}" || trim(next) == "end") break;
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<RepeatStmt>(parse_single_expr(count_str), sub_p.parse_script()));
                    continue;
                }
            }

            // 6. Block Conditional: if (cond) { ... } else { ... }
            if ((line.rfind("if ", 0) == 0 || line.rfind("if(", 0) == 0) && (line.back() == '{' || line.find('{') != std::string::npos)) {
                size_t brace_pos = line.find('{');
                std::string cond_part = trim(line.substr(2, brace_pos - 2));
                if (cond_part.front() == '(' && cond_part.back() == ')') {
                    cond_part = trim(cond_part.substr(1, cond_part.size() - 2));
                }
                auto cond_expr = parse_single_expr(cond_part);

                std::vector<std::string> then_lines;
                std::vector<std::string> else_lines;
                bool in_else = false;

                while (line_idx < lines.size()) {
                    std::string next = lines[line_idx++];
                    std::string t_next = trim(next);
                    if (t_next == "} else {" || t_next == "} else" || t_next == "else {" || t_next == "else") {
                        in_else = true;
                        continue;
                    }
                    if (t_next == "}" || t_next == "end") break;
                    if (in_else) else_lines.push_back(next);
                    else then_lines.push_back(next);
                }

                Parser p_then(join_lines(then_lines));
                Parser p_else(join_lines(else_lines));
                statements.push_back(std::make_shared<IfStmt>(cond_expr, p_then.parse_script(), p_else.parse_script()));
                continue;
            }

            // 7. App declaration block: @app(...) { ... } or define app ...:
            if (line.rfind("@app", 0) == 0 || line.rfind("app(", 0) == 0 || line.rfind("define app", 0) == 0) {
                std::string app_name = "HoloApp", ver = "2.0";
                if (line.find('(') != std::string::npos) {
                    auto args = parse_call_args(line.substr(line.find('(') + 1, line.find_last_of(')') - line.find('(') - 1));
                    if (!args.positional.empty()) app_name = args.positional[0];
                    if (args.positional.size() > 1) ver = args.positional[1];
                } else {
                    std::regex r(R"(define app\s*(?:as)?\s*["'](.*?)["'](?:\s*version\s*([0-9\.]+))?)");
                    std::smatch m;
                    if (std::regex_search(line, m, r)) {
                        app_name = m[1];
                        if (m[2].matched) ver = m[2].str();
                    }
                }
                statements.push_back(std::make_shared<AppDefineStmt>(app_name, ver));
                continue;
            }

            // Parse single line statement (handling potential semicolons outside quotes)
            auto sub_lines = split_semicolons(line);
            for (const auto& sl : sub_lines) {
                auto stmt = parse_statement_line(sl);
                if (stmt) {
                    statements.push_back(stmt);
                }
            }
        }

        return statements;
    }

    // Parse single line statement
    std::shared_ptr<Stmt> parse_statement_line(const std::string& line) {
        std::string s = trim(line);
        // Strip trailing semicolon
        while (!s.empty() && s.back() == ';') s.pop_back();
        s = trim(s);
        if (s.empty()) return nullptr;

        // 1. Break
        if (s == "break") {
            return std::make_shared<BreakStmt>();
        }

        // 2. Return: return <expr> OR return OR -> <expr>
        if (s.rfind("return ", 0) == 0 || s == "return") {
            std::string val_str = s == "return" ? "" : trim(s.substr(7));
            return std::make_shared<ReturnStmt>(val_str.empty() ? nullptr : parse_single_expr(val_str));
        }
        if (s.rfind("-> ", 0) == 0) {
            return std::make_shared<ReturnStmt>(parse_single_expr(trim(s.substr(3))));
        }

        // 3. Python module import: use python "math" OR import python "math"
        if (s.rfind("use python ", 0) == 0 || s.rfind("import python ", 0) == 0) {
            std::string mod = s.substr(s.rfind("python ", 0) == 0 ? 7 : (s.find("python ") + 7));
            mod = trim_quotes(trim(mod));
            return std::make_shared<ImportStmt>(mod, "", true);
        }

        // 4. Module import: import loop.ui as ui OR use loop::ui
        if (s.rfind("import ", 0) == 0) {
            std::string rem = trim(s.substr(7));
            std::string mod = rem;
            std::string alias = "";
            auto as_pos = rem.find(" as ");
            if (as_pos != std::string::npos) {
                mod = trim(rem.substr(0, as_pos));
                alias = trim(rem.substr(as_pos + 4));
            }
            return std::make_shared<ImportStmt>(mod, alias, false);
        }
        if (s.rfind("use ", 0) == 0 && s.find("python") == std::string::npos) {
            std::string mod = trim(s.substr(4));
            return std::make_shared<ImportStmt>(mod, "", false);
        }

        // 5. App declaration single-line
        if (s.rfind("define app", 0) == 0 || s.rfind("@app(", 0) == 0 || s.rfind("app(", 0) == 0) {
            if (s.find('(') != std::string::npos) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                std::string aname = args.positional.empty() ? "HoloApp" : args.positional[0];
                std::string aver = args.positional.size() > 1 ? args.positional[1] : "1.0";
                return std::make_shared<AppDefineStmt>(aname, aver);
            }
            std::regex r(R"(define app\s*(?:as)?\s*["'](.*?)["'](?:\s*version\s*([0-9\.]+))?)");
            std::smatch m;
            if (std::regex_search(s, m, r)) {
                return std::make_shared<AppDefineStmt>(m[1], m[2].matched ? m[2].str() : "1.0");
            }
            return std::make_shared<AppDefineStmt>("HoloApp", "1.0");
        }

        // 6. UI Profile & Theme: profile("xui") / @profile("xui") / theme("dark_neon") / @theme(...)
        if (s.rfind("profile(", 0) == 0 || s.rfind("@profile(", 0) == 0 || s.rfind("set ui_profile to", 0) == 0 || s.rfind("set ui to", 0) == 0) {
            std::string prof = "xui";
            if (s.find('(') != std::string::npos) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                if (!args.positional.empty()) prof = args.positional[0];
            } else {
                prof = trim_quotes(extract_after(s, "to"));
            }
            return std::make_shared<ConfigStmt>("ui_profile", prof);
        }
        if (s.rfind("theme(", 0) == 0 || s.rfind("@theme(", 0) == 0 || s.rfind("set theme to", 0) == 0 || s.rfind("set theme as", 0) == 0) {
            std::string th = "dark_neon";
            if (s.find('(') != std::string::npos) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                if (!args.positional.empty()) th = args.positional[0];
            } else {
                th = trim_quotes(extract_after(s, s.find(" to ") != std::string::npos ? "to" : "as"));
            }
            return std::make_shared<ConfigStmt>("theme", th);
        }

        // 7. Window Canvas: window("Title", 800, 520) / @window(...) / create window with title ...
        if (s.rfind("window(", 0) == 0 || s.rfind("@window(", 0) == 0 || s.rfind("create window", 0) == 0) {
            std::string title = "Game Window";
            double w = 800, h = 520;
            if (s.find('(') != std::string::npos && s.rfind("create window", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                if (args.positional.size() > 0) title = args.positional[0];
                if (args.positional.size() > 1) { try { w = std::stod(args.positional[1]); } catch (...) {} }
                if (args.positional.size() > 2) { try { h = std::stod(args.positional[2]); } catch (...) {} }
                if (args.has("title")) title = args.get("title");
                auto sz = args.get_pair("size", {w, h});
                w = sz.first; h = sz.second;
            } else {
                std::regex tr(R"(title\s*["'](.*?)["'])");
                std::regex sr(R"(size\s*\((\d+),\s*(\d+)\))");
                std::smatch m;
                if (std::regex_search(s, m, tr)) title = m[1];
                if (std::regex_search(s, m, sr)) {
                    w = std::stod(m[1]);
                    h = std::stod(m[2]);
                }
            }
            return std::make_shared<WindowStmt>(title, w, h);
        }

        // 8. Single-line Conditionals:
        //    if (cond) -> stmt
        //    if (cond) => stmt
        //    if cond do stmt
        //    if cond then stmt
        if (s.rfind("if ", 0) == 0 || s.rfind("if(", 0) == 0) {
            std::string cond_part, stmt_part;
            size_t arrow_pos = s.find("->");
            if (arrow_pos == std::string::npos) arrow_pos = s.find("=>");
            if (arrow_pos != std::string::npos) {
                size_t start = s.rfind("if", 0) == 0 ? (s[2] == '(' ? 2 : 3) : 0;
                cond_part = trim(s.substr(start, arrow_pos - start));
                stmt_part = trim(s.substr(arrow_pos + 2));
            } else {
                std::regex cr(R"(^if\s+(.*?)\s+(?:then|do)\s+(.*)$)", std::regex_constants::icase);
                std::smatch m;
                if (std::regex_search(s, m, cr)) {
                    cond_part = m[1];
                    stmt_part = m[2];
                }
            }
            if (!cond_part.empty() && !stmt_part.empty()) {
                if (cond_part.front() == '(' && cond_part.back() == ')') {
                    cond_part = trim(cond_part.substr(1, cond_part.size() - 2));
                }
                auto cond_expr = parse_single_expr(cond_part);
                auto then_stmt = parse_statement_line(stmt_part);
                std::vector<std::shared_ptr<Stmt>> then_branch;
                if (then_stmt) then_branch.push_back(then_stmt);
                return std::make_shared<IfStmt>(cond_expr, then_branch);
            }
        }

        // 9. Output: out(...) / out ... / print(...) / print ... / echo(...)
        if (s.rfind("out(", 0) == 0 && s.back() == ')') {
            std::string inner = s.substr(4, s.size() - 5);
            std::vector<std::shared_ptr<Expr>> exprs;
            for (const auto& a : split_arguments(inner)) exprs.push_back(parse_single_expr(a));
            return std::make_shared<PrintStmt>(exprs);
        }
        if (s.rfind("print(", 0) == 0 && s.back() == ')') {
            std::string inner = s.substr(6, s.size() - 7);
            std::vector<std::shared_ptr<Expr>> exprs;
            for (const auto& a : split_arguments(inner)) exprs.push_back(parse_single_expr(a));
            return std::make_shared<PrintStmt>(exprs);
        }
        if (s.rfind("out ", 0) == 0 || s.rfind("print ", 0) == 0 || s.rfind("echo ", 0) == 0 || s == "print" || s == "out" || s == "echo") {
            size_t off = (s.rfind("print", 0) == 0 ? 5 : (s.rfind("echo", 0) == 0 ? 4 : 3));
            std::string args_str = s.size() > off ? trim(s.substr(off)) : "";
            std::vector<std::shared_ptr<Expr>> exprs;
            if (!args_str.empty()) {
                for (const auto& tok : split_arguments(args_str)) {
                    exprs.push_back(parse_single_expr(tok));
                }
            }
            return std::make_shared<PrintStmt>(exprs);
        }

        // 10. Modern Variable Declarations:
        //     let x = 10, mut x = 10, val x = 10, var x = 10
        if (s.rfind("let ", 0) == 0 || s.rfind("mut ", 0) == 0 || s.rfind("val ", 0) == 0 || s.rfind("var ", 0) == 0) {
            std::string rem = trim(s.substr(4));
            auto eq_pos = rem.find('=');
            if (eq_pos != std::string::npos) {
                std::string name = trim(rem.substr(0, eq_pos));
                std::string expr_str = trim(rem.substr(eq_pos + 1));
                return std::make_shared<SetStmt>(name, "=", parse_single_expr(expr_str));
            }
        }

        // 11. Walrus Declaration: x := 10
        auto walrus_pos = s.find(":=");
        if (walrus_pos != std::string::npos) {
            std::string name = trim(s.substr(0, walrus_pos));
            std::string expr_str = trim(s.substr(walrus_pos + 2));
            if (!name.empty() && !expr_str.empty()) {
                return std::make_shared<SetStmt>(name, "=", parse_single_expr(expr_str));
            }
        }

        // 12. Increment & Decrement: x++ / x--
        if (s.size() >= 3 && s.substr(s.size() - 2) == "++") {
            std::string name = trim(s.substr(0, s.size() - 2));
            return std::make_shared<SetStmt>(name, "+=", std::make_shared<LiteralExpr>(Value(1)));
        }
        if (s.size() >= 3 && s.substr(s.size() - 2) == "--") {
            std::string name = trim(s.substr(0, s.size() - 2));
            return std::make_shared<SetStmt>(name, "-=", std::make_shared<LiteralExpr>(Value(1)));
        }

        // 13. Legacy Variable Assignment: set <var> to <expr> OR set <var> = <expr>
        if (s.rfind("set ", 0) == 0) {
            std::string rem = trim(s.substr(4));
            std::string name, op = "=", expr_str;
            if (rem.find(" to ") != std::string::npos) {
                auto pos = rem.find(" to ");
                name = trim(rem.substr(0, pos));
                expr_str = trim(rem.substr(pos + 4));
            } else if (rem.find(" as ") != std::string::npos) {
                auto pos = rem.find(" as ");
                name = trim(rem.substr(0, pos));
                expr_str = trim(rem.substr(pos + 4));
            } else if (rem.find(" = ") != std::string::npos) {
                auto pos = rem.find(" = ");
                name = trim(rem.substr(0, pos));
                expr_str = trim(rem.substr(pos + 3));
            }
            if (!name.empty() && !expr_str.empty()) {
                return std::make_shared<SetStmt>(name, op, parse_single_expr(expr_str));
            }
        }

        // 14. UI Card Directives: ui.card(...) / @ui::card(...) / draw card ...
        if (s.rfind("ui.card(", 0) == 0 || s.rfind("@ui::card(", 0) == 0 || s.rfind("card(", 0) == 0 || s.rfind("draw card", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "card";
            if (s.find('(') != std::string::npos && s.rfind("draw card", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size");
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->title = args.get("title");
                d->text = args.get("text");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex tt_r(R"(title\s*["'](.*?)["'])");
                std::regex tx_r(R"(text\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, tt_r)) d->title = m[1];
                if (std::regex_search(s, m, tx_r)) d->text = m[1];
            }
            return d;
        }

        // 15. UI Button Directives: ui.btn(...) / ui.button(...) / @ui::btn(...) / draw button ...
        if (s.rfind("ui.btn(", 0) == 0 || s.rfind("ui.button(", 0) == 0 || s.rfind("@ui::btn(", 0) == 0 || 
            s.rfind("@ui::button(", 0) == 0 || s.rfind("button(", 0) == 0 || s.rfind("draw button", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "button";
            if (s.find('(') != std::string::npos && s.rfind("draw button", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                d->x = at.first; d->y = at.second;
                d->text = args.has("text") ? args.get("text") : (!args.positional.empty() ? args.positional[0] : "");
                d->action = args.get("action");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex tx_r(R"(text\s*["'](.*?)["'])");
                std::regex ac_r(R"(action\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, tx_r)) d->text = m[1];
                if (std::regex_search(s, m, ac_r)) d->action = m[1];
            }
            return d;
        }

        // 16. UI Input Directives: ui.input(...) / @ui::input(...) / draw input ...
        if (s.rfind("ui.input(", 0) == 0 || s.rfind("@ui::input(", 0) == 0 || s.rfind("input(", 0) == 0 || s.rfind("draw input", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "input";
            if (s.find('(') != std::string::npos && s.rfind("draw input", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size");
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->placeholder = args.get("placeholder");
                d->var_name = args.has("bind") ? args.get("bind") : args.get("var");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex pl_r(R"(placeholder\s*["'](.*?)["'])");
                std::regex vr_r(R"(var\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, pl_r)) d->placeholder = m[1];
                if (std::regex_search(s, m, vr_r)) d->var_name = m[1];
            }
            return d;
        }

        // 17. Spawn Sprite Directives: spawn.sprite(...) / @spawn::sprite(...) / entity.sprite(...) / spawn sprite ...
        if (s.rfind("spawn.sprite(", 0) == 0 || s.rfind("@spawn::sprite(", 0) == 0 || 
            s.rfind("entity.sprite(", 0) == 0 || s.rfind("spawn sprite", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "sprite";
            if (s.find('(') != std::string::npos && s.rfind("spawn sprite", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                sp->name = !args.positional.empty() ? args.positional[0] : args.get("name", "Sprite");
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size");
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->color = args.get("color", "#38bdf8");
            } else {
                std::regex nm_r(R"(spawn\s+sprite\s*["']?(.*?)["']?(?:\s+at|\s+with|$))");
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, nm_r) && m[1].matched) sp->name = m[1];
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); }
                if (std::regex_search(s, m, col_r)) sp->color = m[1];
            }
            return sp;
        }

        // 18. Spawn Platform Directives: spawn.platform(...) / @spawn::platform(...) / entity.platform(...) / spawn platform ...
        if (s.rfind("spawn.platform(", 0) == 0 || s.rfind("@spawn::platform(", 0) == 0 || 
            s.rfind("entity.platform(", 0) == 0 || s.rfind("spawn platform", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "platform";
            if (s.find('(') != std::string::npos && s.rfind("spawn platform", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size");
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->color = args.get("color", "#6366f1");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); }
                if (std::regex_search(s, m, col_r)) sp->color = m[1];
            }
            return sp;
        }

        // 19. Spawn Coin Directives: spawn.coin(...) / @spawn::coin(...) / entity.coin(...) / spawn coin ...
        if (s.rfind("spawn.coin(", 0) == 0 || s.rfind("@spawn::coin(", 0) == 0 || 
            s.rfind("entity.coin(", 0) == 0 || s.rfind("spawn coin", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "coin";
            if (s.find('(') != std::string::npos && s.rfind("spawn coin", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                sp->x = at.first; sp->y = at.second;
                sp->points = args.get_num("points", 100);
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex pt_r(R"(points\s*(\d+))");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, pt_r)) sp->points = std::stod(m[1]);
            }
            return sp;
        }

        // 20. Spawn Bubbly Dot: spawn.bubbly(...) / @spawn::bubbly(...) / spawn bubbly_dot ...
        if (s.rfind("spawn.bubbly(", 0) == 0 || s.rfind("@spawn::bubbly(", 0) == 0 || s.rfind("spawn bubbly_dot", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "bubbly_dot";
            if (s.find('(') != std::string::npos && s.rfind("spawn bubbly_dot", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                sp->text = !args.positional.empty() ? args.positional[0] : args.get("text", "Active");
                sp->state = args.get("state", "music");
            } else {
                std::regex tx_r(R"(text\s*["'](.*?)["'])");
                std::regex st_r(R"(state\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, tx_r)) sp->text = m[1];
                if (std::regex_search(s, m, st_r)) sp->state = m[1];
            }
            return sp;
        }

        // 21. Audio Tone Directives: audio.tone(...) / @audio::tone(...) / sound.tone(...) / play tone ...
        if (s.rfind("audio.tone(", 0) == 0 || s.rfind("@audio::tone(", 0) == 0 || 
            s.rfind("sound.tone(", 0) == 0 || s.rfind("play tone", 0) == 0) {
            double freq = 440, dur = 100;
            if (s.find('(') != std::string::npos && s.rfind("play tone", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                if (args.positional.size() > 0) { try { freq = std::stod(args.positional[0]); } catch (...) {} }
                if (args.positional.size() > 1) { try { dur = std::stod(args.positional[1]); } catch (...) {} }
                if (args.has("freq")) freq = args.get_num("freq", freq);
                if (args.has("dur") || args.has("for")) dur = args.get_num("dur", args.get_num("for", dur));
            } else {
                std::regex fr_r(R"(at\s*(\d+)\s*Hz)", std::regex_constants::icase);
                std::regex dr_r(R"(for\s*(\d+)\s*ms)", std::regex_constants::icase);
                std::smatch m;
                if (std::regex_search(s, m, fr_r)) freq = std::stod(m[1]);
                if (std::regex_search(s, m, dr_r)) dur = std::stod(m[1]);
            }
            return std::make_shared<PlayToneStmt>(freq, dur);
        }

        // 22. FX Particles: fx.particles(...) / @fx::particles(...) / emit particles ...
        if (s.rfind("fx.particles(", 0) == 0 || s.rfind("@fx::particles(", 0) == 0 || s.rfind("emit particles", 0) == 0) {
            double x = 0, y = 0;
            std::string col = "#38bdf8";
            if (s.find('(') != std::string::npos && s.rfind("emit particles", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                x = at.first; y = at.second;
                col = args.get("color", col);
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { x = std::stod(m[1]); y = std::stod(m[2]); }
                if (std::regex_search(s, m, col_r)) col = m[1];
            }
            return std::make_shared<EmitParticlesStmt>(x, y, col);
        }

        // 23. Shorthand Assignment: x = 10, x += 5, x -= 2
        std::regex assign_regex(R"(^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.*)$)");
        std::smatch am;
        if (std::regex_search(s, am, assign_regex)) {
            std::string name = am[1];
            std::string op = am[2];
            std::string expr_str = am[3];
            if (s.rfind("create ", 0) != 0 && s.rfind("draw ", 0) != 0 && s.rfind("spawn ", 0) != 0) {
                return std::make_shared<SetStmt>(name, op, parse_single_expr(expr_str));
            }
        }

        // 24. Function call statement: callee(...) OR call callee(...)
        if (s.rfind("call ", 0) == 0) {
            std::regex call_r(R"(call\s+([A-Za-z0-9_]+)\s*(?:\((.*?)\))?)");
            std::smatch m;
            if (std::regex_search(s, m, call_r)) {
                std::string fn_name = m[1];
                std::vector<std::shared_ptr<Expr>> args;
                if (m[2].matched && !m[2].str().empty()) {
                    for (const auto& arg : split_arguments(m[2])) {
                        args.push_back(parse_single_expr(arg));
                    }
                }
                return std::make_shared<CallStmt>(fn_name, args);
            }
        }
        std::regex fn_stmt_r(R"(^([A-Za-z0-9_]+)\s*\((.*?)\)$)");
        std::smatch fsm;
        if (std::regex_search(s, fsm, fn_stmt_r)) {
            std::string fn_name = fsm[1];
            std::string raw_args = fsm[2];
            std::vector<std::shared_ptr<Expr>> args;
            if (!raw_args.empty()) {
                for (const auto& a : split_arguments(raw_args)) {
                    args.push_back(parse_single_expr(a));
                }
            }
            return std::make_shared<CallStmt>(fn_name, args);
        }

        // 25. Syscall & Process
        if (s.rfind("syscall", 0) == 0) {
            std::regex sc_r(R"(syscall\s+([A-Za-z0-9_]+)(?:\s+with\s+args\s+["'](.*?)["'])?)");
            std::smatch m;
            if (std::regex_search(s, m, sc_r)) {
                return std::make_shared<SyscallStmt>(m[1], m[2].matched ? m[2].str() : "");
            }
        }
        if (s.rfind("spawn process", 0) == 0) {
            std::regex pr_r(R"(spawn process\s*["'](.*?)["'](?:\s+priority\s+(\d+))?)");
            std::smatch m;
            if (std::regex_search(s, m, pr_r)) {
                return std::make_shared<SpawnProcessStmt>(m[1], m[2].matched ? std::stoi(m[2].str()) : 10);
            }
        }

        // 26. Python inline statement: py: ...
        if (s.rfind("py:", 0) == 0 || s.rfind("py ", 0) == 0) {
            std::string code = trim(s.substr(s.rfind("py:", 0) == 0 ? 3 : 2));
            return std::make_shared<PythonBlockStmt>(code);
        }

        // 27. Expression Statement (pipelines: expr |> out, function invocations, etc.)
        if (s.find("|>") != std::string::npos || s.find('(') != std::string::npos || s.rfind("py!(", 0) == 0) {
            auto e = parse_single_expr(s);
            if (e) return std::make_shared<ExprStmt>(e);
        }

        return nullptr;
    }

    // Parse single expression with operator precedence climbing
    std::shared_ptr<Expr> parse_single_expr(const std::string& raw) {
        std::string s = trim(raw);
        if (s.empty()) return std::make_shared<LiteralExpr>(Value());

        // 0. Pipeline operator |>
        std::vector<std::string> pipe_tokens = split_binary(s, {" |> "});
        if (pipe_tokens.size() > 1) {
            auto root = parse_single_expr(pipe_tokens[0]);
            for (size_t i = 1; i < pipe_tokens.size(); ++i) {
                root = std::make_shared<BinaryExpr>(root, "|>", parse_single_expr(pipe_tokens[i]));
            }
            return root;
        }

        // 1. Python inline: py!(code) OR @py(code) OR py: code
        if (s.rfind("py!(", 0) == 0 && s.back() == ')') {
            std::string code = trim(s.substr(4, s.size() - 5));
            return std::make_shared<PyInlineExpr>(code);
        }
        if (s.rfind("@py(", 0) == 0 && s.back() == ')') {
            std::string code = trim(s.substr(4, s.size() - 5));
            return std::make_shared<PyInlineExpr>(code);
        }
        if (s.rfind("py:", 0) == 0 || s.rfind("py ", 0) == 0) {
            std::string code = trim(s.substr(s.rfind("py:", 0) == 0 ? 3 : 2));
            return std::make_shared<PyInlineExpr>(code);
        }

        // 2. Interpolated String: $"Hello {name}" OR f"..." OR "Hello {name}"
        if ((s.front() == '$' || s.front() == 'f') && s.size() >= 3) {
            std::string inner = s.substr(1);
            if ((inner.front() == '"' && inner.back() == '"') || (inner.front() == '\'' && inner.back() == '\'')) {
                std::string content = inner.substr(1, inner.size() - 2);
                return std::make_shared<InterpolatedStringExpr>(content);
            }
        }
        if ((s.front() == '"' && s.back() == '"' && s.size() >= 2) ||
            (s.front() == '\'' && s.back() == '\'' && s.size() >= 2)) {
            std::string content = s.substr(1, s.size() - 2);
            if (content.find('{') != std::string::npos && content.find('}') != std::string::npos) {
                return std::make_shared<InterpolatedStringExpr>(content);
            }
            return std::make_shared<LiteralExpr>(Value(content));
        }

        // 3. Tuple (x, y)
        if (s.front() == '(' && s.back() == ')' && s.size() >= 3) {
            std::string inner = s.substr(1, s.size() - 2);
            auto comma_pos = inner.find(',');
            if (comma_pos != std::string::npos) {
                auto x_expr = parse_single_expr(inner.substr(0, comma_pos));
                auto y_expr = parse_single_expr(inner.substr(comma_pos + 1));
                return std::make_shared<TupleExpr>(x_expr, y_expr);
            }
        }

        // 4. Number literal
        if (is_numeric(s)) {
            if (s.find('.') != std::string::npos) {
                return std::make_shared<LiteralExpr>(Value(std::stod(s)));
            } else {
                return std::make_shared<LiteralExpr>(Value(static_cast<int64_t>(std::stoll(s))));
            }
        }

        // 5. Boolean & Nil
        if (s == "true") return std::make_shared<LiteralExpr>(Value(true));
        if (s == "false") return std::make_shared<LiteralExpr>(Value(false));
        if (s == "nil" || s == "null" || s == "none") return std::make_shared<LiteralExpr>(Value());

        // 6. Logical OR (or, ||)
        std::vector<std::string> or_tokens = split_binary(s, {" or ", " || "});
        if (or_tokens.size() > 1) {
            auto root = parse_single_expr(or_tokens[0]);
            for (size_t i = 1; i < or_tokens.size(); ++i) {
                root = std::make_shared<BinaryExpr>(root, "or", parse_single_expr(or_tokens[i]));
            }
            return root;
        }

        // 7. Logical AND (and, &&)
        std::vector<std::string> and_tokens = split_binary(s, {" and ", " && "});
        if (and_tokens.size() > 1) {
            auto root = parse_single_expr(and_tokens[0]);
            for (size_t i = 1; i < and_tokens.size(); ++i) {
                root = std::make_shared<BinaryExpr>(root, "and", parse_single_expr(and_tokens[i]));
            }
            return root;
        }

        // 8. Comparisons (==, !=, <=, >=, <, >)
        for (const std::string& cmp : {"==", "!=", "<=", ">=", "<", ">"}) {
            auto p = find_operator_outside_quotes(s, cmp);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + cmp.size()));
                return std::make_shared<BinaryExpr>(left, cmp, right);
            }
        }

        // 9. Addition and Subtraction (+, -)
        for (const std::string& add_op : {" + ", " - "}) {
            auto p = find_operator_outside_quotes(s, add_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + add_op.size()));
                return std::make_shared<BinaryExpr>(left, trim(add_op), right);
            }
        }

        // 10. Multiplication, Division, Modulo (*, /, %)
        for (const std::string& mul_op : {" * ", " / ", " % "}) {
            auto p = find_operator_outside_quotes(s, mul_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + mul_op.size()));
                return std::make_shared<BinaryExpr>(left, trim(mul_op), right);
            }
        }

        // 11. Function calls: callee(args) or namespace::func(args) or namespace.func(args)
        std::regex fn_call_r(R"(^([A-Za-z0-9_\.:]+)\s*\((.*?)\)$)");
        std::smatch fcm;
        if (std::regex_search(s, fcm, fn_call_r)) {
            std::string callee = fcm[1];
            // Normalize :: to .
            auto col_col = callee.find("::");
            if (col_col != std::string::npos) {
                callee.replace(col_col, 2, ".");
            }
            std::vector<std::shared_ptr<Expr>> args;
            std::string raw_args = fcm[2];
            if (!raw_args.empty()) {
                for (const auto& a : split_arguments(raw_args)) {
                    args.push_back(parse_single_expr(a));
                }
            }
            return std::make_shared<CallExpr>(callee, args);
        }

        // Default: Variable Identifier
        return std::make_shared<VariableExpr>(s);
    }

    static ParsedArgs parse_call_args(const std::string& raw) {
        ParsedArgs res;
        for (const auto& a : split_arguments(raw)) {
            std::string arg = trim(a);
            if (arg.empty()) continue;
            auto colon = find_operator_outside_quotes(arg, ":");
            if (colon != std::string::npos && colon > 0 && colon < arg.size() - 1) {
                std::string k = trim(arg.substr(0, colon));
                std::string v = trim(arg.substr(colon + 1));
                res.named[k] = trim_quotes(v);
            } else {
                res.positional.push_back(trim_quotes(arg));
            }
        }
        return res;
    }

private:
    static std::string trim(const std::string& s) {
        size_t start = s.find_first_not_of(" \t\r\n");
        if (start == std::string::npos) return "";
        size_t end = s.find_last_not_of(" \t\r\n");
        return s.substr(start, end - start + 1);
    }

    static std::string trim_quotes(const std::string& s) {
        if (s.size() >= 2 && ((s.front() == '"' && s.back() == '"') || (s.front() == '\'' && s.back() == '\''))) {
            return s.substr(1, s.size() - 2);
        }
        return s;
    }

    static std::vector<std::string> split_lines(const std::string& text) {
        std::vector<std::string> lines;
        std::istringstream stream(text);
        std::string line;
        while (std::getline(stream, line)) {
            lines.push_back(line);
        }
        return lines;
    }

    static std::string join_lines(const std::vector<std::string>& lines) {
        std::string res;
        for (const auto& l : lines) res += l + "\n";
        return res;
    }

    static std::vector<std::string> dedent(const std::vector<std::string>& lines) {
        size_t min_indent = 1000;
        for (const auto& l : lines) {
            std::string t = trim(l);
            if (t.empty()) continue;
            size_t indent = l.find_first_not_of(" \t");
            if (indent < min_indent) min_indent = indent;
        }
        if (min_indent == 1000 || min_indent == 0) return lines;
        std::vector<std::string> out;
        for (const auto& l : lines) {
            if (trim(l).empty()) out.push_back("");
            else if (l.size() >= min_indent) out.push_back(l.substr(min_indent));
            else out.push_back(l);
        }
        return out;
    }

    static bool is_numeric(const std::string& s) {
        if (s.empty()) return false;
        size_t i = 0;
        if (s[0] == '-' || s[0] == '+') i = 1;
        bool has_digit = false;
        bool has_dot = false;
        for (; i < s.size(); ++i) {
            if (std::isdigit(s[i])) has_digit = true;
            else if (s[i] == '.' && !has_dot) has_dot = true;
            else return false;
        }
        return has_digit;
    }

    static std::vector<std::string> split_params(const std::string& raw) {
        std::vector<std::string> out;
        std::stringstream ss(raw);
        std::string token;
        while (std::getline(ss, token, ',')) {
            std::string t = trim(token);
            if (!t.empty()) out.push_back(t);
        }
        return out;
    }

    static std::vector<std::string> split_arguments(const std::string& raw) {
        std::vector<std::string> args;
        std::string curr;
        bool in_quotes = false;
        char quote_char = 0;
        int paren_depth = 0;

        for (size_t i = 0; i < raw.size(); ++i) {
            char c = raw[i];
            if ((c == '"' || c == '\'') && (i == 0 || raw[i - 1] != '\\')) {
                if (!in_quotes) { in_quotes = true; quote_char = c; }
                else if (quote_char == c) { in_quotes = false; }
            }
            if (!in_quotes) {
                if (c == '(' || c == '[') paren_depth++;
                else if (c == ')' || c == ']') paren_depth--;
                else if (c == ',' && paren_depth == 0) {
                    args.push_back(trim(curr));
                    curr.clear();
                    continue;
                }
            }
            curr += c;
        }
        if (!trim(curr).empty()) args.push_back(trim(curr));
        return args;
    }

    static std::vector<std::string> split_semicolons(const std::string& raw) {
        std::vector<std::string> stmts;
        std::string curr;
        bool in_quotes = false;
        char quote_char = 0;
        int paren_depth = 0;

        for (size_t i = 0; i < raw.size(); ++i) {
            char c = raw[i];
            if ((c == '"' || c == '\'') && (i == 0 || raw[i - 1] != '\\')) {
                if (!in_quotes) { in_quotes = true; quote_char = c; }
                else if (quote_char == c) { in_quotes = false; }
            }
            if (!in_quotes) {
                if (c == '(' || c == '[' || c == '{') paren_depth++;
                else if (c == ')' || c == ']' || c == '}') paren_depth--;
                else if (c == ';' && paren_depth == 0) {
                    if (!trim(curr).empty()) stmts.push_back(trim(curr));
                    curr.clear();
                    continue;
                }
            }
            curr += c;
        }
        if (!trim(curr).empty()) stmts.push_back(trim(curr));
        return stmts;
    }

    static std::vector<std::string> split_binary(const std::string& s, const std::vector<std::string>& ops) {
        for (const auto& op : ops) {
            auto p = find_operator_outside_quotes(s, op);
            if (p != std::string::npos) {
                std::vector<std::string> res;
                res.push_back(s.substr(0, p));
                std::string rem = s.substr(p + op.size());
                std::vector<std::string> rest = split_binary(rem, ops);
                res.insert(res.end(), rest.begin(), rest.end());
                return res;
            }
        }
        return {s};
    }

    static size_t find_operator_outside_quotes(const std::string& s, const std::string& op) {
        bool in_quotes = false;
        char quote_char = 0;
        int paren_depth = 0;

        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if ((c == '"' || c == '\'') && (i == 0 || s[i - 1] != '\\')) {
                if (!in_quotes) { in_quotes = true; quote_char = c; }
                else if (quote_char == c) { in_quotes = false; }
            }
            if (!in_quotes) {
                if (c == '(' || c == '[') paren_depth++;
                else if (c == ')' || c == ']') paren_depth--;
                else if (paren_depth == 0) {
                    if (s.substr(i, op.size()) == op) {
                        return i;
                    }
                }
            }
        }
        return std::string::npos;
    }

    static std::string extract_after(const std::string& s, const std::string& word) {
        auto pos = s.find(" " + word + " ");
        if (pos != std::string::npos) {
            return trim(s.substr(pos + word.size() + 2));
        }
        return "";
    }
};

} // namespace looping
