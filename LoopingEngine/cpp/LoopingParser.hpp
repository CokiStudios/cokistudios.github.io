#pragma once

#include "LoopingAST.hpp"
#include <string>
#include <vector>
#include <memory>
#include <sstream>
#include <cctype>
#include <regex>

namespace looping {

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

            // Python multiline block: python { ... } OR py:begin ... py:end
            if (line.rfind("python {", 0) == 0 || line == "python:" || line == "py:" || line == "py:begin") {
                std::vector<std::string> py_lines;
                if (line.rfind("python {", 0) == 0 && line.back() == '}' && line.size() > 9) {
                    py_lines.push_back(line.substr(8, line.size() - 9));
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

            // Function definition: function <name>(<args>) { ... }
            if (line.rfind("function ", 0) == 0 || line.rfind("def ", 0) == 0) {
                std::regex fn_regex(R"((?:function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*\{?)");
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

            // Repeat Loop: repeat N times { ... } OR loop N { ... }
            if (line.rfind("repeat ", 0) == 0 || line.rfind("loop ", 0) == 0) {
                std::regex loop_regex(R"((?:repeat|loop)\s+(\d+|[A-Za-z0-9_]+)\s*(?:times)?\s*\{?)");
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

            // Parse single line statement
            auto stmt = parse_statement_line(line);
            if (stmt) {
                statements.push_back(stmt);
            }
        }

        return statements;
    }

    // Parse single line statement
    std::shared_ptr<Stmt> parse_statement_line(const std::string& line) {
        std::string s = trim(line);
        if (s.empty()) return nullptr;

        // 1. Python module import
        if (s.rfind("use python ", 0) == 0 || s.rfind("import python ", 0) == 0) {
            std::string mod = s.substr(s.rfind("python ", 0) == 0 ? 7 : (s.find("python ") + 7));
            mod = trim_quotes(trim(mod));
            return std::make_shared<ImportStmt>(mod, "", true);
        }

        // 2. Looping module import
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

        // 3. Define App
        if (s.rfind("define app", 0) == 0) {
            std::regex r(R"(define app\s*(?:as)?\s*["'](.*?)["'](?:\s*version\s*([0-9\.]+))?)");
            std::smatch m;
            if (std::regex_search(s, m, r)) {
                return std::make_shared<AppDefineStmt>(m[1], m[2].matched ? m[2].str() : "1.0");
            }
            return std::make_shared<AppDefineStmt>("HoloApp", "1.0");
        }

        // 4. UI profile / theme
        if (s.rfind("set ui_profile to", 0) == 0 || s.rfind("set ui to", 0) == 0) {
            std::string prof = trim_quotes(extract_after(s, "to"));
            return std::make_shared<ConfigStmt>("ui_profile", prof);
        }
        if (s.rfind("set theme to", 0) == 0 || s.rfind("set theme as", 0) == 0) {
            std::string th = trim_quotes(extract_after(s, s.find(" to ") != std::string::npos ? "to" : "as"));
            return std::make_shared<ConfigStmt>("theme", th);
        }

        // 5. Window Canvas
        if (s.rfind("create window", 0) == 0) {
            std::string title = "Game Window";
            double w = 800, h = 520;
            std::regex tr(R"(title\s*["'](.*?)["'])");
            std::regex sr(R"(size\s*\((\d+),\s*(\d+)\))");
            std::smatch m;
            if (std::regex_search(s, m, tr)) title = m[1];
            if (std::regex_search(s, m, sr)) {
                w = std::stod(m[1]);
                h = std::stod(m[2]);
            }
            return std::make_shared<WindowStmt>(title, w, h);
        }

        // 6. Conditional: if <cond> do <stmt> OR if <cond> then <stmt>
        if (s.rfind("if ", 0) == 0) {
            std::regex cr(R"(^if\s+(.*?)\s+(?:then|do)\s+(.*)$)", std::regex_constants::icase);
            std::smatch m;
            if (std::regex_search(s, m, cr)) {
                auto cond_expr = parse_single_expr(m[1]);
                auto then_stmt = parse_statement_line(m[2]);
                std::vector<std::shared_ptr<Stmt>> then_branch;
                if (then_stmt) then_branch.push_back(then_stmt);
                return std::make_shared<IfStmt>(cond_expr, then_branch);
            }
        }

        // 7. Print / Echo
        if (s.rfind("print ", 0) == 0 || s.rfind("echo ", 0) == 0 || s == "print" || s == "echo") {
            std::string args_str = s.rfind("print", 0) == 0 ? trim(s.substr(5)) : trim(s.substr(4));
            std::vector<std::shared_ptr<Expr>> exprs;
            if (!args_str.empty()) {
                std::vector<std::string> tokens = split_arguments(args_str);
                for (const auto& tok : tokens) {
                    exprs.push_back(parse_single_expr(tok));
                }
            }
            return std::make_shared<PrintStmt>(exprs);
        }

        // 8. Variable Assignment: set <var> to <expr> OR set <var> = <expr> OR var += expr
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

        // Shorthand Assignment: x = 10, x += 5, x -= 2
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

        // 9. Call statement: call name(...) OR name(...)
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

        // 10. UI Card / Button / Input
        if (s.rfind("draw card", 0) == 0 || s.rfind("draw button", 0) == 0 || s.rfind("draw input", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = s.rfind("draw card", 0) == 0 ? "card" : (s.rfind("draw input", 0) == 0 ? "input" : "button");

            std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
            std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
            std::regex tt_r(R"(title\s*["'](.*?)["'])");
            std::regex tx_r(R"(text\s*["'](.*?)["'])");
            std::regex ac_r(R"(action\s*["'](.*?)["'])");
            std::regex pl_r(R"(placeholder\s*["'](.*?)["'])");
            std::regex vr_r(R"(var\s*["'](.*?)["'])");
            std::smatch m;

            if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
            if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
            if (std::regex_search(s, m, tt_r)) d->title = m[1];
            if (std::regex_search(s, m, tx_r)) d->text = m[1];
            if (std::regex_search(s, m, ac_r)) d->action = m[1];
            if (std::regex_search(s, m, pl_r)) d->placeholder = m[1];
            if (std::regex_search(s, m, vr_r)) d->var_name = m[1];

            return d;
        }

        // 11. Spawn Entities
        if (s.rfind("spawn sprite", 0) == 0 || s.rfind("spawn platform", 0) == 0 || s.rfind("spawn coin", 0) == 0 || s.rfind("spawn bubbly_dot", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            if (s.rfind("spawn sprite", 0) == 0) sp->entity_type = "sprite";
            else if (s.rfind("spawn platform", 0) == 0) sp->entity_type = "platform";
            else if (s.rfind("spawn coin", 0) == 0) sp->entity_type = "coin";
            else sp->entity_type = "bubbly_dot";

            std::regex nm_r(R"(spawn\s+(?:sprite|platform|coin|bubbly_dot)\s*["']?(.*?)["']?(?:\s+at|\s+with|$))");
            std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
            std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
            std::regex col_r(R"(color\s*["'](.*?)["'])");
            std::regex tx_r(R"(text\s*["'](.*?)["'])");
            std::regex st_r(R"(state\s*["'](.*?)["'])");
            std::regex pt_r(R"(points\s*(\d+))");
            std::smatch m;

            if (std::regex_search(s, m, nm_r) && m[1].matched) sp->name = m[1];
            if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
            if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); }
            if (std::regex_search(s, m, col_r)) sp->color = m[1];
            if (std::regex_search(s, m, tx_r)) sp->text = m[1];
            if (std::regex_search(s, m, st_r)) sp->state = m[1];
            if (std::regex_search(s, m, pt_r)) sp->points = std::stod(m[1]);

            return sp;
        }

        // 12. Emit Particles
        if (s.rfind("emit particles", 0) == 0) {
            double x = 0, y = 0;
            std::string col = "#38bdf8";
            std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
            std::regex col_r(R"(color\s*["'](.*?)["'])");
            std::smatch m;
            if (std::regex_search(s, m, at_r)) { x = std::stod(m[1]); y = std::stod(m[2]); }
            if (std::regex_search(s, m, col_r)) col = m[1];
            return std::make_shared<EmitParticlesStmt>(x, y, col);
        }

        // 13. Play Audio Tone
        if (s.rfind("play tone", 0) == 0) {
            double freq = 440;
            double dur = 100;
            std::regex fr_r(R"(at\s*(\d+)\s*Hz)", std::regex_constants::icase);
            std::regex dr_r(R"(for\s*(\d+)\s*ms)", std::regex_constants::icase);
            std::smatch m;
            if (std::regex_search(s, m, fr_r)) freq = std::stod(m[1]);
            if (std::regex_search(s, m, dr_r)) dur = std::stod(m[1]);
            return std::make_shared<PlayToneStmt>(freq, dur);
        }

        // 14. Syscall
        if (s.rfind("syscall", 0) == 0) {
            std::regex sc_r(R"(syscall\s+([A-Za-z0-9_]+)(?:\s+with\s+args\s+["'](.*?)["'])?)");
            std::smatch m;
            if (std::regex_search(s, m, sc_r)) {
                return std::make_shared<SyscallStmt>(m[1], m[2].matched ? m[2].str() : "");
            }
        }

        // 15. Process
        if (s.rfind("spawn process", 0) == 0) {
            std::regex pr_r(R"(spawn process\s*["'](.*?)["'](?:\s+priority\s+(\d+))?)");
            std::smatch m;
            if (std::regex_search(s, m, pr_r)) {
                return std::make_shared<SpawnProcessStmt>(m[1], m[2].matched ? std::stoi(m[2].str()) : 10);
            }
        }

        // 16. Python inline statement: py: ...
        if (s.rfind("py:", 0) == 0 || s.rfind("py ", 0) == 0) {
            std::string code = trim(s.substr(s.rfind("py:", 0) == 0 ? 3 : 2));
            return std::make_shared<PythonBlockStmt>(code);
        }

        return nullptr;
    }

    // Parse single expression with operator precedence climbing
    std::shared_ptr<Expr> parse_single_expr(const std::string& raw) {
        std::string s = trim(raw);
        if (s.empty()) return std::make_shared<LiteralExpr>(Value());

        // Python inline prefix
        if (s.rfind("py:", 0) == 0 || s.rfind("py ", 0) == 0) {
            std::string code = trim(s.substr(s.rfind("py:", 0) == 0 ? 3 : 2));
            return std::make_shared<PyInlineExpr>(code);
        }

        // Interpolated String: "Hello {name}"
        if ((s.front() == '"' && s.back() == '"' && s.size() >= 2) ||
            (s.front() == '\'' && s.back() == '\'' && s.size() >= 2)) {
            std::string content = s.substr(1, s.size() - 2);
            if (content.find('{') != std::string::npos && content.find('}') != std::string::npos) {
                return std::make_shared<InterpolatedStringExpr>(content);
            }
            return std::make_shared<LiteralExpr>(Value(content));
        }

        // Tuple (x, y)
        if (s.front() == '(' && s.back() == ')' && s.size() >= 3) {
            std::string inner = s.substr(1, s.size() - 2);
            auto comma_pos = inner.find(',');
            if (comma_pos != std::string::npos) {
                auto x_expr = parse_single_expr(inner.substr(0, comma_pos));
                auto y_expr = parse_single_expr(inner.substr(comma_pos + 1));
                return std::make_shared<TupleExpr>(x_expr, y_expr);
            }
        }

        // Number literal
        if (is_numeric(s)) {
            if (s.find('.') != std::string::npos) {
                return std::make_shared<LiteralExpr>(Value(std::stod(s)));
            } else {
                return std::make_shared<LiteralExpr>(Value(static_cast<int64_t>(std::stoll(s))));
            }
        }

        // Boolean & Nil
        if (s == "true") return std::make_shared<LiteralExpr>(Value(true));
        if (s == "false") return std::make_shared<LiteralExpr>(Value(false));
        if (s == "nil" || s == "null" || s == "none") return std::make_shared<LiteralExpr>(Value());

        // Binary Operators with Precedence
        // 1. Logical OR (or, ||)
        std::vector<std::string> or_tokens = split_binary(s, {" or ", " || "});
        if (or_tokens.size() > 1) {
            auto root = parse_single_expr(or_tokens[0]);
            for (size_t i = 1; i < or_tokens.size(); ++i) {
                root = std::make_shared<BinaryExpr>(root, "or", parse_single_expr(or_tokens[i]));
            }
            return root;
        }

        // 2. Logical AND (and, &&)
        std::vector<std::string> and_tokens = split_binary(s, {" and ", " && "});
        if (and_tokens.size() > 1) {
            auto root = parse_single_expr(and_tokens[0]);
            for (size_t i = 1; i < and_tokens.size(); ++i) {
                root = std::make_shared<BinaryExpr>(root, "and", parse_single_expr(and_tokens[i]));
            }
            return root;
        }

        // 3. Comparisons (==, !=, <=, >=, <, >)
        for (const std::string& cmp : {"==", "!=", "<=", ">=", "<", ">"}) {
            auto p = find_operator_outside_quotes(s, cmp);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + cmp.size()));
                return std::make_shared<BinaryExpr>(left, cmp, right);
            }
        }

        // 4. Addition and Subtraction (+, -)
        for (const std::string& add_op : {" + ", " - "}) {
            auto p = find_operator_outside_quotes(s, add_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + add_op.size()));
                return std::make_shared<BinaryExpr>(left, trim(add_op), right);
            }
        }

        // 5. Multiplication, Division, Modulo (*, /, %)
        for (const std::string& mul_op : {" * ", " / ", " % "}) {
            auto p = find_operator_outside_quotes(s, mul_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(s.substr(0, p));
                auto right = parse_single_expr(s.substr(p + mul_op.size()));
                return std::make_shared<BinaryExpr>(left, trim(mul_op), right);
            }
        }

        // 6. Function calls: func(arg1, arg2)
        std::regex fn_call_r(R"(^([A-Za-z0-9_\.]+)\s*\((.*?)\)$)");
        std::smatch fcm;
        if (std::regex_search(s, fcm, fn_call_r)) {
            std::string callee = fcm[1];
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
