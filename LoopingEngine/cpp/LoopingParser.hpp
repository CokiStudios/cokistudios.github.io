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
    static void replace_all(std::string& str, const std::string& from, const std::string& to) {
        if (from.empty()) return;
        size_t start_pos = 0;
        while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
            str.replace(start_pos, from.length(), to);
            start_pos += to.length();
        }
    }

    Parser(const std::string& src) : source(src), pos(0) {
        replace_all(source, "“", "\"");
        replace_all(source, "”", "\"");
        replace_all(source, "‘", "'");
        replace_all(source, "’", "'");
    }

    // Parse entire script into statements
    std::vector<std::shared_ptr<Stmt>> parse_script() {
        std::vector<std::string> raw_lines = split_lines(source);
        std::vector<std::string> lines;
        for (const auto& rl : raw_lines) {
            if (rl.find(';') != std::string::npos) {
                auto sub = split_semicolons(rl);
                for (const auto& sl : sub) lines.push_back(sl);
            } else {
                lines.push_back(rl);
            }
        }
        std::vector<std::shared_ptr<Stmt>> statements;
        size_t line_idx = 0;

        while (line_idx < lines.size()) {
            std::string raw_line = lines[line_idx];
            replace_all(raw_line, "“", "\"");
            replace_all(raw_line, "”", "\"");
            replace_all(raw_line, "‘", "'");
            replace_all(raw_line, "’", "'");
            std::string line = trim(raw_line);
            line_idx++;

            if (line.empty() || line.rfind("#", 0) == 0 || line.rfind("//", 0) == 0 || line == "}" || line == "end") {
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

            // 1a. Button with Snippet Block:
            // insert button "Incrementar" with snippet:
            // draw button at (50, 150) with text "Resetear" and action "reset_act" with snippet:
            if ((line.rfind("insert button", 0) == 0 || line.rfind("draw button", 0) == 0 || line.rfind("ui.btn", 0) == 0) &&
                (line.find("with snippet:") != std::string::npos || line.find("with snippet {") != std::string::npos ||
                 line.find("snippet:") != std::string::npos) &&
                (line.back() == ':' || line.back() == '{')) {
                auto d = std::make_shared<DrawUIStmt>();
                d->ui_type = "button";
                d->x = -1;
                d->y = -1;
                d->w = 150;
                d->h = 42;

                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex tx_r(R"(text\s*["'](.*?)["'])");
                std::regex ins_r(R"(insert\s+button\s+["'](.*?)["'])");
                std::regex ac_r(R"(action\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(line, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(line, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(line, m, tx_r)) { d->text = m[1]; }
                else if (std::regex_search(line, m, ins_r)) { d->text = m[1]; }
                if (std::regex_search(line, m, ac_r)) { d->action = m[1]; }

                std::vector<std::string> snip_lines;
                while (line_idx < lines.size()) {
                    std::string next_raw = lines[line_idx++];
                    std::string next_t = trim(next_raw);
                    if (next_t == "end" || next_t == "}") break;
                    snip_lines.push_back(next_raw);
                }
                d->snippet = join_lines(dedent(snip_lines));
                statements.push_back(d);
                continue;
            }

            // 1b. Python snippet definition: insert pysnippet as <name>: ... OR insert snippet as <name>: ...
            std::regex snip_inline_r(R"(^(?:insert\s+)?(?:py(?:thon)?snippet|snippet|python)\s+(?:as\s+)?([A-Za-z0-9_]+)\s*:\s*(.+)$)");
            std::smatch snip_in_m;
            if (std::regex_search(line, snip_in_m, snip_inline_r)) {
                std::string snip_name = snip_in_m[1];
                std::string snip_code = snip_in_m[2];
                statements.push_back(std::make_shared<PySnippetDefStmt>(snip_name, snip_code));
                continue;
            }

            std::regex snip_r(R"(^(?:insert\s+)?(?:py(?:thon)?snippet|snippet)\s+(?:as\s+)?([A-Za-z0-9_]+)\s*(?:\{|:)?$)");
            std::smatch snip_m;
            if (std::regex_search(line, snip_m, snip_r)) {
                std::string snip_name = snip_m[1];

                // Single-line brace: insert pysnippet as sn1 { print("hi") }
                if (line.find('{') != std::string::npos && line.back() == '}' && line.find('{') < line.rfind('}')) {
                    size_t b_start = line.find('{');
                    size_t b_end = line.rfind('}');
                    std::string inner = line.substr(b_start + 1, b_end - b_start - 1);
                    statements.push_back(std::make_shared<PySnippetDefStmt>(snip_name, inner));
                    continue;
                }

                // Multi-line brace: insert pysnippet as sn1 { ... }
                if (line.find('{') != std::string::npos) {
                    std::vector<std::string> py_lines;
                    while (line_idx < lines.size()) {
                        std::string next_raw = lines[line_idx++];
                        std::string next_t = trim(next_raw);
                        if (next_t == "}" || next_t == "end") break;
                        py_lines.push_back(next_raw);
                    }
                    statements.push_back(std::make_shared<PySnippetDefStmt>(snip_name, join_lines(dedent(py_lines))));
                    continue;
                }

                // Indented or colon block (e.g. insert pysnippet as sn1:)
                size_t base_indent = raw_line.find_first_not_of(" \t");
                if (base_indent == std::string::npos) base_indent = 0;

                std::vector<std::string> py_lines;
                while (line_idx < lines.size()) {
                    std::string next_raw = lines[line_idx];
                    std::string next_t = trim(next_raw);

                    if (next_t.empty()) {
                        bool has_more = false;
                        for (size_t p = line_idx + 1; p < lines.size(); ++p) {
                            std::string pt = trim(lines[p]);
                            if (pt.empty()) continue;
                            size_t p_indent = lines[p].find_first_not_of(" \t");
                            if (p_indent > base_indent && pt != "end" && pt != "}") {
                                has_more = true;
                            }
                            break;
                        }
                        if (has_more) {
                            py_lines.push_back("");
                            line_idx++;
                            continue;
                        } else {
                            break;
                        }
                    }

                    if (next_t == "end" || next_t == "}") {
                        line_idx++;
                        break;
                    }

                    size_t next_indent = next_raw.find_first_not_of(" \t");
                    if (next_indent > base_indent) {
                        py_lines.push_back(next_raw);
                        line_idx++;
                    } else {
                        if (py_lines.empty()) {
                            bool has_end = false;
                            for (size_t p = line_idx; p < lines.size(); ++p) {
                                if (trim(lines[p]) == "end" || trim(lines[p]) == "}") {
                                    has_end = true;
                                    break;
                                }
                            }
                            if (has_end) {
                                while (line_idx < lines.size()) {
                                    std::string nr = lines[line_idx++];
                                    if (trim(nr) == "end" || trim(nr) == "}") break;
                                    py_lines.push_back(nr);
                                }
                                break;
                            }
                        }
                        break;
                    }
                }

                while (!py_lines.empty() && trim(py_lines.back()).empty()) {
                    py_lines.pop_back();
                }

                statements.push_back(std::make_shared<PySnippetDefStmt>(snip_name, join_lines(dedent(py_lines))));
                continue;
            }

            // 1c. Dynamic Program Compilation: compile program "Name" [target "flui"] [to "path"] [version "1.0"] [and run]:
            if (line.rfind("compile program ", 0) == 0 || line.rfind("dynamic program ", 0) == 0 ||
                line.rfind("create program ", 0) == 0) {
                std::string header_line = line;
                std::regex name_r(R"(program\s+["']([^"']+)["'])");
                std::smatch nm;
                std::string prog_name = "DynamicApp";
                if (std::regex_search(header_line, nm, name_r)) {
                    prog_name = nm[1];
                }

                std::string target_ui = "shine_ui";
                std::regex target_r(R"(target\s+["']?([A-Za-z0-9_]+)["']?)");
                std::smatch tm;
                if (std::regex_search(header_line, tm, target_r)) {
                    target_ui = tm[1];
                }

                std::string out_path = "";
                std::regex out_r(R"(to\s+["']([^"']+)["'])");
                std::smatch om;
                if (std::regex_search(header_line, om, out_r)) {
                    out_path = om[1];
                }

                std::string version = "1.0";
                std::regex ver_r(R"(version\s+["']?([0-9.]+)["']?)");
                std::smatch vm;
                if (std::regex_search(header_line, vm, ver_r)) {
                    version = vm[1];
                }

                bool and_run = (header_line.find("and run") != std::string::npos || 
                                header_line.find("and execute") != std::string::npos);

                auto stmt = std::make_shared<DynamicProgramCompileStmt>(prog_name, target_ui, out_path, version);
                stmt->and_run = and_run;

                std::vector<std::string> block_lines;
                size_t base_indent = raw_line.find_first_not_of(" \t");
                if (base_indent == std::string::npos) base_indent = 0;

                bool brace_style = (line.find('{') != std::string::npos);

                while (line_idx < lines.size()) {
                    std::string next_raw = lines[line_idx];
                    std::string next_t = trim(next_raw);

                    if (brace_style) {
                        line_idx++;
                        if (next_t == "}" || next_t == "end") break;
                        block_lines.push_back(next_raw);
                    } else {
                        if (next_t.empty()) {
                            bool has_more = false;
                            for (size_t p = line_idx + 1; p < lines.size(); ++p) {
                                std::string pt = trim(lines[p]);
                                if (pt.empty()) continue;
                                size_t p_indent = lines[p].find_first_not_of(" \t");
                                if (p_indent > base_indent && pt != "end" && pt != "}") {
                                    has_more = true;
                                }
                                break;
                            }
                            if (has_more) {
                                block_lines.push_back("");
                                line_idx++;
                                continue;
                            } else {
                                break;
                            }
                        }

                        if (next_t == "end" || next_t == "}") {
                            line_idx++;
                            break;
                        }

                        size_t next_indent = next_raw.find_first_not_of(" \t");
                        if (next_indent > base_indent) {
                            block_lines.push_back(next_raw);
                            line_idx++;
                        } else {
                            break;
                        }
                    }
                }

                stmt->raw_lines = dedent(block_lines);
                statements.push_back(stmt);
                continue;
            }

            // 1d. Pattern Matching Block: match <expr> { pattern => stmt ... }
            //     OR let/mut/val <var> = match <expr> { pattern => expr ... }
            std::string match_assign_lhs = "";
            std::string match_header_line = line;
            if (line.find("match ") != std::string::npos && line.find('{') != std::string::npos &&
                line.rfind("match ", 0) != 0 && line.rfind("match(", 0) != 0) {
                std::regex m_assign_r(R"(^(?:(?:let|mut|val|var)\s+)?([A-Za-z0-9_]+)\s*(?::=|=)\s*(match\b.*\{.*)$)");
                std::smatch mam;
                if (std::regex_search(line, mam, m_assign_r)) {
                    match_assign_lhs = trim(mam[1]);
                    match_header_line = trim(mam[2]);
                }
            }
            if ((match_header_line.rfind("match ", 0) == 0 || match_header_line.rfind("match(", 0) == 0) && match_header_line.find('{') != std::string::npos) {
                size_t brace_pos = match_header_line.find('{');
                std::string target_str = trim(match_header_line.substr(5, brace_pos - 5));
                if (is_enclosed_in_matching_parens(target_str)) {
                    target_str = trim(target_str.substr(1, target_str.size() - 2));
                }
                auto target_expr = parse_single_expr(target_str);

                std::vector<MatchArm> arms;
                size_t close_brace = match_header_line.rfind('}');
                if (close_brace != std::string::npos && close_brace > brace_pos) {
                    std::string arms_str = match_header_line.substr(brace_pos + 1, close_brace - brace_pos - 1);
                    auto arm_items = split_level_0(arms_str, ',');
                    for (const auto& raw_arm : arm_items) {
                        std::string next_t = trim(raw_arm);
                        if (next_t.empty()) continue;
                        size_t arrow_p = next_t.find("=>");
                        if (arrow_p == std::string::npos) arrow_p = next_t.find("->");
                        if (arrow_p != std::string::npos) {
                            std::string pat_str = trim(next_t.substr(0, arrow_p));
                            std::string arm_body_str = trim(next_t.substr(arrow_p + 2));

                            MatchArm arm;
                            if (pat_str == "_" || pat_str == "default" || pat_str == "else") {
                                arm.pattern = nullptr;
                            } else if (find_operator_outside_quotes(pat_str, "..=") != std::string::npos) {
                                size_t rp = find_operator_outside_quotes(pat_str, "..=");
                                arm.is_range = true;
                                arm.range_inclusive = true;
                                arm.range_start = parse_single_expr(trim(pat_str.substr(0, rp)));
                                arm.range_end = parse_single_expr(trim(pat_str.substr(rp + 3)));
                            } else if (find_operator_outside_quotes(pat_str, "..") != std::string::npos) {
                                size_t rp = find_operator_outside_quotes(pat_str, "..");
                                arm.is_range = true;
                                arm.range_inclusive = false;
                                arm.range_start = parse_single_expr(trim(pat_str.substr(0, rp)));
                                arm.range_end = parse_single_expr(trim(pat_str.substr(rp + 2)));
                            } else if (find_operator_outside_quotes(pat_str, "|") != std::string::npos) {
                                auto sub_pats = split_level_0(pat_str, '|');
                                for (const auto& sp : sub_pats) {
                                    std::string tsp = trim(sp);
                                    if (!tsp.empty()) arm.patterns.push_back(parse_single_expr(tsp));
                                }
                                if (!arm.patterns.empty()) arm.pattern = arm.patterns[0];
                            } else {
                                arm.pattern = parse_single_expr(pat_str);
                            }

                            if (!arm_body_str.empty() && arm_body_str.front() == '{' && arm_body_str.back() == '}') {
                                arm_body_str = trim(arm_body_str.substr(1, arm_body_str.size() - 2));
                            }
                            if (!match_assign_lhs.empty()) {
                                arm_body_str = match_assign_lhs + " = " + arm_body_str;
                            }
                            Parser sub_p(arm_body_str);
                            arm.body = sub_p.parse_script();
                            arms.push_back(arm);
                        }
                    }
                    statements.push_back(std::make_shared<MatchStmt>(target_expr, arms));
                    continue;
                }

                while (line_idx < lines.size()) {
                    std::string next_raw = lines[line_idx++];
                    std::string next_t = trim(next_raw);
                    if (next_t.empty() || next_t.rfind("//", 0) == 0 || next_t.rfind("#", 0) == 0) continue;
                    if (next_t == "}" || next_t == "end") break;

                    // Strip trailing comma if present
                    if (!next_t.empty() && next_t.back() == ',') next_t.pop_back();
                    next_t = trim(next_t);

                    size_t arrow_p = next_t.find("=>");
                    if (arrow_p == std::string::npos) arrow_p = next_t.find("->");
                    if (arrow_p != std::string::npos) {
                        std::string pat_str = trim(next_t.substr(0, arrow_p));
                        std::string arm_body_str = trim(next_t.substr(arrow_p + 2));

                        MatchArm arm;
                        if (pat_str == "_" || pat_str == "default" || pat_str == "else") {
                            arm.pattern = nullptr;
                        } else if (find_operator_outside_quotes(pat_str, "..=") != std::string::npos) {
                            size_t rp = find_operator_outside_quotes(pat_str, "..=");
                            arm.is_range = true;
                            arm.range_inclusive = true;
                            arm.range_start = parse_single_expr(trim(pat_str.substr(0, rp)));
                            arm.range_end = parse_single_expr(trim(pat_str.substr(rp + 3)));
                        } else if (find_operator_outside_quotes(pat_str, "..") != std::string::npos) {
                            size_t rp = find_operator_outside_quotes(pat_str, "..");
                            arm.is_range = true;
                            arm.range_inclusive = false;
                            arm.range_start = parse_single_expr(trim(pat_str.substr(0, rp)));
                            arm.range_end = parse_single_expr(trim(pat_str.substr(rp + 2)));
                        } else if (find_operator_outside_quotes(pat_str, "|") != std::string::npos) {
                            auto sub_pats = split_level_0(pat_str, '|');
                            for (const auto& sp : sub_pats) {
                                std::string tsp = trim(sp);
                                if (!tsp.empty()) arm.patterns.push_back(parse_single_expr(tsp));
                            }
                            if (!arm.patterns.empty()) arm.pattern = arm.patterns[0];
                        } else {
                            arm.pattern = parse_single_expr(pat_str);
                        }

                        if (!arm_body_str.empty() && arm_body_str.front() == '{' && arm_body_str.back() == '}') {
                            arm_body_str = trim(arm_body_str.substr(1, arm_body_str.size() - 2));
                        }
                        if (!match_assign_lhs.empty()) {
                            arm_body_str = match_assign_lhs + " = " + arm_body_str;
                        }
                        Parser sub_p(arm_body_str);
                        arm.body = sub_p.parse_script();
                        arms.push_back(arm);
                    }
                }
                statements.push_back(std::make_shared<MatchStmt>(target_expr, arms));
                continue;
            }

            // 1e. Try / Catch Block: try { ... } catch (err) { ... }
            if (line == "try {" || line == "try:" || line == "try") {
                std::vector<std::string> try_lines;
                std::vector<std::string> catch_lines;
                std::string err_var = "error";
                bool in_catch = false;

                while (line_idx < lines.size()) {
                    std::string next_raw = lines[line_idx++];
                    std::string next_t = trim(next_raw);
                    if (!in_catch && (next_t.rfind("} catch", 0) == 0 || next_t.rfind("catch", 0) == 0)) {
                        in_catch = true;
                        std::regex catch_r(R"(catch\s*\(?\s*([A-Za-z0-9_]+)\s*\)?)");
                        std::smatch cm;
                        if (std::regex_search(next_t, cm, catch_r)) {
                            err_var = cm[1];
                        }
                        continue;
                    }
                    if (next_t == "}" || next_t == "end") {
                        if (in_catch) break;
                        // Check if next line is catch
                        if (line_idx < lines.size() && trim(lines[line_idx]).rfind("catch", 0) == 0) {
                            std::string c_line = trim(lines[line_idx++]);
                            in_catch = true;
                            std::regex catch_r(R"(catch\s*\(?\s*([A-Za-z0-9_]+)\s*\)?)");
                            std::smatch cm;
                            if (std::regex_search(c_line, cm, catch_r)) {
                                err_var = cm[1];
                            }
                            continue;
                        }
                        break;
                    }
                    if (in_catch) catch_lines.push_back(next_raw);
                    else try_lines.push_back(next_raw);
                }

                Parser p_try(join_lines(try_lines));
                Parser p_catch(join_lines(catch_lines));
                statements.push_back(std::make_shared<TryCatchStmt>(p_try.parse_script(), err_var, p_catch.parse_script()));
                continue;
            }

            // 2. Function definition: fn <name>(<args>) { ... } OR fn <name>(<args>) => <expr>
            if (line.rfind("fn ", 0) == 0 || line.rfind("fun ", 0) == 0 || 
                line.rfind("function ", 0) == 0 || line.rfind("def ", 0) == 0) {
                
                // One-line arrow body: fn add(a, b = 10) => a + b
                if (line.find("=>") != std::string::npos) {
                    auto arrow = line.find("=>");
                    std::string head = trim(line.substr(0, arrow));
                    std::string body_expr = trim(line.substr(arrow + 2));
                    std::regex f_r(R"((?:fn|fun|function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\))");
                    std::smatch m;
                    if (std::regex_search(head, m, f_r)) {
                        std::string fn_name = m[1];
                        std::vector<std::string> raw_params = split_arguments(m[2]);
                        std::vector<std::string> params;
                        std::vector<std::shared_ptr<Expr>> defs;
                        for (const auto& rp : raw_params) {
                            size_t eq_p = find_operator_outside_quotes(rp, "=");
                            if (eq_p != std::string::npos) {
                                params.push_back(trim(rp.substr(0, eq_p)));
                                defs.push_back(parse_single_expr(trim(rp.substr(eq_p + 1))));
                            } else {
                                params.push_back(trim(rp));
                                defs.push_back(nullptr);
                            }
                        }
                        std::vector<std::shared_ptr<Stmt>> body;
                        body.push_back(std::make_shared<ReturnStmt>(parse_single_expr(body_expr)));
                        statements.push_back(std::make_shared<FunctionDefStmt>(fn_name, params, body, defs));
                        continue;
                    }
                }

                std::regex fn_regex(R"((?:fn|fun|function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*\{?)");
                std::smatch m;
                if (std::regex_search(line, m, fn_regex)) {
                    std::string fn_name = m[1];
                    std::vector<std::string> raw_params = split_arguments(m[2]);
                    std::vector<std::string> params;
                    std::vector<std::shared_ptr<Expr>> defs;
                    for (const auto& rp : raw_params) {
                        size_t eq_p = find_operator_outside_quotes(rp, "=");
                        if (eq_p != std::string::npos) {
                            params.push_back(trim(rp.substr(0, eq_p)));
                            defs.push_back(parse_single_expr(trim(rp.substr(eq_p + 1))));
                        } else {
                            params.push_back(trim(rp));
                            defs.push_back(nullptr);
                        }
                    }
                    std::vector<std::string> body_lines;
                    int brace_depth = (line.find('{') != std::string::npos) ? 1 : 0;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (brace_depth > 0) {
                            for (char ch : t) {
                                if (ch == '{') brace_depth++;
                                else if (ch == '}') {
                                    brace_depth--;
                                    if (brace_depth == 0) break;
                                }
                            }
                            if (brace_depth == 0) break;
                        } else {
                            if (t == "}" || t == "end") break;
                        }
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<FunctionDefStmt>(fn_name, params, sub_p.parse_script(), defs));
                    continue;
                }
            }

            // 3. For in Range Loop: for (i in 0..5) { ... } / for (i in 0..=5) / for (i in 0..10 step 2)
            if (line.rfind("for ", 0) == 0 || line.rfind("for(", 0) == 0) {
                // Single line range loop: for (i in 0..5) { ... }
                std::regex for_range_single(R"(for\s*\(?\s*([A-Za-z0-9_]+)\s+in\s+([0-9A-Za-z_\.\-]+)\s*(\.\.=?)\s*([0-9A-Za-z_\.\-]+)(?:\s+step\s+([0-9A-Za-z_\.\-]+))?\s*\)?\s*\{\s*(.*?)\s*\}\s*$)");
                std::smatch sm;
                if (std::regex_search(line, sm, for_range_single)) {
                    std::string var_name = sm[1];
                    auto start_expr = parse_single_expr(sm[2]);
                    bool inc = (sm[3].str() == "..=");
                    auto end_expr = parse_single_expr(sm[4]);
                    std::shared_ptr<Expr> step_e = sm[5].matched ? parse_single_expr(sm[5].str()) : nullptr;
                    Parser sub_p(sm[6]);
                    statements.push_back(std::make_shared<ForRangeStmt>(var_name, start_expr, end_expr, sub_p.parse_script(), inc, step_e));
                    continue;
                }

                std::regex for_r(R"(for\s*\(?\s*([A-Za-z0-9_]+)\s+in\s+([0-9A-Za-z_\.\-]+)\s*(\.\.=?)\s*([0-9A-Za-z_\.\-]+)(?:\s+step\s+([0-9A-Za-z_\.\-]+))?\s*\)?\s*\{?)");
                std::smatch m;
                if (std::regex_search(line, m, for_r)) {
                    std::string var_name = m[1];
                    auto start_expr = parse_single_expr(m[2]);
                    bool inc = (m[3].str() == "..=");
                    auto end_expr = parse_single_expr(m[4]);
                    std::shared_ptr<Expr> step_e = m[5].matched ? parse_single_expr(m[5].str()) : nullptr;
                    std::vector<std::string> body_lines;

                    int b_depth = 1;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (t == "{" || (!t.empty() && t.back() == '{' && t.front() != '#' && t.rfind("//", 0) != 0)) b_depth++;
                        if (t == "}" || t == "end") {
                            b_depth--;
                            if (b_depth == 0) break;
                        }
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<ForRangeStmt>(var_name, start_expr, end_expr, sub_p.parse_script(), inc, step_e));
                    continue;
                }

                // 3b. For in Collection: single line or multiline
                std::regex for_each_single_paren(R"(^\s*for\s*\(\s*([A-Za-z0-9_]+)\s+in\s+(.+?)\s*\)\s*\{\s*(.*?)\s*\}\s*$)");
                std::regex for_each_single_plain(R"(^\s*for\s+([A-Za-z0-9_]+)\s+in\s+(.+?)\s*\{\s*(.*?)\s*\}\s*$)");
                std::smatch sfem;
                if (std::regex_search(line, sfem, for_each_single_paren) || std::regex_search(line, sfem, for_each_single_plain)) {
                    std::string var_name = sfem[1];
                    auto coll_expr = parse_single_expr(trim(sfem[2]));
                    std::string inner_body = sfem[3];
                    Parser sub_p(inner_body);
                    statements.push_back(std::make_shared<ForEachStmt>(var_name, coll_expr, sub_p.parse_script()));
                    continue;
                }

                std::regex for_each_paren(R"(^\s*for\s*\(\s*([A-Za-z0-9_]+)\s+in\s+(.+?)\s*\)\s*(?:\{)?\s*$)");
                std::regex for_each_plain(R"(^\s*for\s+([A-Za-z0-9_]+)\s+in\s+(.+?)\s*(?:\{)?\s*$)");
                std::smatch fem;
                if (std::regex_search(line, fem, for_each_paren) || std::regex_search(line, fem, for_each_plain)) {
                    std::string var_name = fem[1];
                    auto coll_expr = parse_single_expr(trim(fem[2]));
                    std::vector<std::string> body_lines;

                    int b_depth = 1;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (t == "{" || (!t.empty() && t.back() == '{' && t.front() != '#' && t.rfind("//", 0) != 0)) b_depth++;
                        if (t == "}" || t == "end") {
                            b_depth--;
                            if (b_depth == 0) break;
                        }
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<ForEachStmt>(var_name, coll_expr, sub_p.parse_script()));
                    continue;
                }
            }

            // 4. While loop: while (cond) { ... } OR while cond { ... }
            if (line.rfind("while ", 0) == 0 || line.rfind("while(", 0) == 0) {
                std::regex wh_regex(R"(while\s*\(?(.*?)\)?\s*\{)");
                std::smatch m;
                if (std::regex_search(line, m, wh_regex)) {
                    std::string cond_str = trim(m[1]);
                    if (is_enclosed_in_matching_parens(cond_str)) {
                        cond_str = trim(cond_str.substr(1, cond_str.size() - 2));
                    }
                    auto cond_expr = parse_single_expr(cond_str);
                    std::vector<std::string> body_lines;

                    int b_depth = 1;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (t == "{" || (!t.empty() && t.back() == '{' && t.front() != '#' && t.rfind("//", 0) != 0)) b_depth++;
                        if (t == "}" || t == "end") {
                            b_depth--;
                            if (b_depth == 0) break;
                        }
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<WhileStmt>(cond_expr, sub_p.parse_script()));
                    continue;
                }
            }

            // 5. Repeat / Loop count: loop (N) { ... } OR loop N { ... } OR repeat N times { ... }
            if (line.rfind("repeat ", 0) == 0 || line.rfind("loop ", 0) == 0 || line.rfind("loop(", 0) == 0 || line == "loop {") {
                // Infinite loop: loop { ... }
                if (line == "loop {" || line == "loop") {
                    std::vector<std::string> body_lines;
                    int b_depth = 1;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (t == "{" || (!t.empty() && t.back() == '{' && t.front() != '#' && t.rfind("//", 0) != 0)) b_depth++;
                        if (t == "}" || t == "end") {
                            b_depth--;
                            if (b_depth == 0) break;
                        }
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

                    int b_depth = 1;
                    while (line_idx < lines.size()) {
                        std::string next = lines[line_idx++];
                        std::string t = trim(next);
                        if (t == "{" || (!t.empty() && t.back() == '{' && t.front() != '#' && t.rfind("//", 0) != 0)) b_depth++;
                        if (t == "}" || t == "end") {
                            b_depth--;
                            if (b_depth == 0) break;
                        }
                        body_lines.push_back(next);
                    }

                    Parser sub_p(join_lines(body_lines));
                    statements.push_back(std::make_shared<RepeatStmt>(parse_single_expr(count_str), sub_p.parse_script()));
                    continue;
                }
            }

            // 6. Block Conditional: if (cond) { ... } else if (cond2) { ... } else { ... }
            if ((line.rfind("if ", 0) == 0 || line.rfind("if(", 0) == 0) && (line.back() == '{' || line.find('{') != std::string::npos)) {
                size_t brace_pos = line.find('{');
                std::string cond_part = trim(line.substr(2, brace_pos - 2));
                if (is_enclosed_in_matching_parens(cond_part)) {
                    cond_part = trim(cond_part.substr(1, cond_part.size() - 2));
                }
                auto cond_expr = parse_single_expr(cond_part);

                struct CondBranch {
                    std::shared_ptr<Expr> cond; // nullptr for final else
                    std::vector<std::string> lines;
                };
                std::vector<CondBranch> branches;
                branches.push_back({cond_expr, {}});

                int depth = 1;
                while (line_idx < lines.size()) {
                    std::string next = lines[line_idx++];
                    std::string t_next = trim(next);

                    if (depth == 1 && (t_next.rfind("} else if ", 0) == 0 || t_next.rfind("} else if(", 0) == 0 ||
                                       t_next.rfind("else if ", 0) == 0 || t_next.rfind("else if(", 0) == 0)) {
                        size_t eif_pos = t_next.find("else if");
                        size_t b_pos = t_next.find('{', eif_pos);
                        std::string c_str = (b_pos != std::string::npos)
                            ? trim(t_next.substr(eif_pos + 7, b_pos - (eif_pos + 7)))
                            : trim(t_next.substr(eif_pos + 7));
                        if (is_enclosed_in_matching_parens(c_str)) {
                            c_str = trim(c_str.substr(1, c_str.size() - 2));
                        }
                        branches.push_back({parse_single_expr(c_str), {}});
                        continue;
                    }
                    if (depth == 1 && (t_next == "} else {" || t_next == "} else" || t_next == "else {" || t_next == "else")) {
                        branches.push_back({nullptr, {}});
                        continue;
                    }

                    if (!t_next.empty() && t_next.front() != '#' && t_next.rfind("//", 0) != 0) {
                        for (char ch : t_next) {
                            if (ch == '{') depth++;
                            else if (ch == '}') depth--;
                        }
                    }
                    if (depth <= 0 || (depth == 1 && t_next == "end")) {
                        // Check if immediately followed by `else` on next line
                        if (line_idx < lines.size()) {
                            std::string peek_t = trim(lines[line_idx]);
                            if (peek_t.rfind("else if ", 0) == 0 || peek_t.rfind("else if(", 0) == 0) {
                                line_idx++;
                                depth = 1;
                                size_t eif_pos = peek_t.find("else if");
                                size_t b_pos = peek_t.find('{', eif_pos);
                                std::string c_str = (b_pos != std::string::npos)
                                    ? trim(peek_t.substr(eif_pos + 7, b_pos - (eif_pos + 7)))
                                    : trim(peek_t.substr(eif_pos + 7));
                                if (is_enclosed_in_matching_parens(c_str)) {
                                    c_str = trim(c_str.substr(1, c_str.size() - 2));
                                }
                                branches.push_back({parse_single_expr(c_str), {}});
                                continue;
                            } else if (peek_t == "else {" || peek_t == "else") {
                                line_idx++;
                                depth = 1;
                                branches.push_back({nullptr, {}});
                                continue;
                            }
                        }
                        break;
                    }
                    branches.back().lines.push_back(next);
                }

                // Fold branches from back to front into nested IfStmt nodes
                std::vector<std::shared_ptr<Stmt>> current_else;
                for (long long bi = static_cast<long long>(branches.size()) - 1; bi >= 0; --bi) {
                    Parser p_br(join_lines(branches[bi].lines));
                    auto br_stmts = p_br.parse_script();
                    if (branches[bi].cond == nullptr) {
                        current_else = br_stmts;
                    } else {
                        auto if_node = std::make_shared<IfStmt>(branches[bi].cond, br_stmts, current_else);
                        current_else = { if_node };
                    }
                }
                if (!current_else.empty()) {
                    statements.push_back(current_else[0]);
                }
                continue;
            }

            // 7. App declaration block: @app(...) { ... } or @app "Name" v"2.8" or define app ...:
            if (line.rfind("@app", 0) == 0 || line.rfind("app(", 0) == 0 || line.rfind("define app", 0) == 0) {
                std::string app_name = "HoloApp", ver = "2.0";
                if (line.find('(') != std::string::npos) {
                    auto args = parse_call_args(line.substr(line.find('(') + 1, line.find_last_of(')') - line.find('(') - 1));
                    if (!args.positional.empty()) app_name = args.positional[0];
                    if (args.positional.size() > 1) ver = args.positional[1];
                } else {
                    std::regex r(R"((?:define app\s*(?:as)?|@app)\s*["'](.*?)["'](?:\s*(?:version\s*|v)?["']?([0-9\.]+)["']?)?)");
                    std::smatch m;
                    if (std::regex_search(line, m, r)) {
                        app_name = m[1];
                        if (m[2].matched && !m[2].str().empty()) ver = m[2].str();
                    }
                }
                statements.push_back(std::make_shared<AppDefineStmt>(app_name, ver));
                continue;
            }

            // 7b. Module declaration header: define module "Name" [version 1.0]: or @module(...)
            if (line.rfind("define module", 0) == 0 || line.rfind("@module", 0) == 0) {
                std::string mod_name = "custom_module", ver = "1.0";
                std::regex r(R"((?:define module\s*(?:as)?|@module)\s*["'](.*?)["'](?:\s*(?:version\s*|v)?["']?([0-9\.]+)["']?)?)");
                std::smatch m;
                if (std::regex_search(line, m, r)) {
                    mod_name = m[1];
                    if (m[2].matched && !m[2].str().empty()) ver = m[2].str();
                }
                statements.push_back(std::make_shared<ModuleDefineStmt>(mod_name, ver));
                continue;
            }

            // 8. SwiftUI Declarative View Component Declaration: view <Name> { ... } or component <Name> { ... }
            std::regex view_decl_r(R"(^(?:view|component)\s+([A-Za-z0-9_]+)(?:\s*\((.*?)\))?\s*\{?$)");
            std::smatch vm_match;
            if (std::regex_search(line, vm_match, view_decl_r)) {
                std::string comp_name = vm_match[1];
                auto comp_stmt = std::make_shared<SwiftUIComponentDeclStmt>(comp_name);
                if (vm_match[2].matched && !vm_match[2].str().empty()) {
                    comp_stmt->params = split_arguments(vm_match[2].str());
                }

                std::vector<std::string> comp_lines;
                int depth = 1;
                while (line_idx < lines.size()) {
                    std::string nl = lines[line_idx++];
                    std::string t = trim(nl);
                    if (t.empty()) continue;
                    for (char ch : t) {
                        if (ch == '{') depth++;
                        else if (ch == '}') {
                            depth--;
                            if (depth == 0) break;
                        }
                    }
                    if (depth == 0) break;
                    comp_lines.push_back(nl);
                }

                std::vector<std::string> view_body_lines;
                for (const auto& bl : comp_lines) {
                    std::string tb = trim(bl);
                    if (tb.empty()) continue;
                    if (tb.rfind("@state ", 0) == 0 || tb.rfind("@State ", 0) == 0 ||
                        tb.rfind("@binding ", 0) == 0 || tb.rfind("@Binding ", 0) == 0) {
                        SwiftUIStateDecl st_decl;
                        size_t sp = tb.find(' ');
                        std::string rem = trim(tb.substr(sp + 1));
                        if (rem.rfind("var ", 0) == 0) rem = trim(rem.substr(4));
                        size_t eq_p = rem.find('=');
                        if (eq_p != std::string::npos) {
                            st_decl.name = trim(rem.substr(0, eq_p));
                            st_decl.initial_expr_str = trim(rem.substr(eq_p + 1));
                            st_decl.initial_expr = parse_single_expr(st_decl.initial_expr_str);
                        } else {
                            st_decl.name = rem;
                            st_decl.initial_expr_str = "nil";
                        }
                        comp_stmt->states.push_back(st_decl);
                    } else {
                        view_body_lines.push_back(bl);
                    }
                }

                size_t v_idx = 0;
                comp_stmt->root_view = parse_swiftui_view(view_body_lines, v_idx);
                collect_following_modifiers(lines, line_idx, comp_stmt->root_modifiers);

                statements.push_back(comp_stmt);
                continue;
            }

            // 9. Top-Level SwiftUI View Render Statement (e.g. VStack { ... } at script level)
            if (is_swiftui_view_starter(line)) {
                line_idx--; // Rewind to current line
                auto view_node = parse_swiftui_view(lines, line_idx);
                if (view_node) {
                    statements.push_back(std::make_shared<SwiftUIViewRenderStmt>(view_node));
                    continue;
                } else {
                    line_idx++;
                }
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

        // 1. Break & Continue
        if (s == "break") {
            return std::make_shared<BreakStmt>();
        }
        if (s == "continue") {
            return std::make_shared<ContinueStmt>();
        }

        // 1b. Throw & Assert
        if (s.rfind("throw ", 0) == 0) {
            return std::make_shared<ThrowStmt>(parse_single_expr(trim(s.substr(6))));
        }
        if (s.rfind("assert(", 0) == 0 && s.back() == ')') {
            auto raw_args = split_arguments(s.substr(7, s.size() - 8));
            if (!raw_args.empty()) {
                auto cond_e = parse_single_expr(raw_args[0]);
                auto msg_e = raw_args.size() > 1 ? parse_single_expr(raw_args[1]) : nullptr;
                return std::make_shared<AssertStmt>(cond_e, msg_e);
            }
        }
        if (s.rfind("assert ", 0) == 0) {
            return std::make_shared<AssertStmt>(parse_single_expr(trim(s.substr(7))));
        }

        // 2. Return: return <expr> OR return OR -> <expr>
        if (s.rfind("return ", 0) == 0 || s == "return") {
            std::string val_str = s == "return" ? "" : trim(s.substr(7));
            return std::make_shared<ReturnStmt>(val_str.empty() ? nullptr : parse_single_expr(val_str));
        }
        if (s.rfind("-> ", 0) == 0) {
            return std::make_shared<ReturnStmt>(parse_single_expr(trim(s.substr(3))));
        }

        // 3. From-import: from <mod> import <symbols...>
        if (s.rfind("from ", 0) == 0) {
            auto imp_pos = s.find(" import ");
            if (imp_pos != std::string::npos) {
                std::string mod = trim(s.substr(5, imp_pos - 5));
                std::string items_str = trim(s.substr(imp_pos + 8));
                std::vector<std::string> symbols;
                std::string curr = "";
                for (char c : items_str) {
                    if (c == ',' || std::isspace(static_cast<unsigned char>(c))) {
                        if (!curr.empty()) {
                            symbols.push_back(curr);
                            curr = "";
                        }
                    } else {
                        curr += c;
                    }
                }
                if (!curr.empty()) symbols.push_back(curr);

                bool is_py = (mod == "pyloop" || mod.rfind("py.", 0) == 0 || mod.rfind("python.", 0) == 0);
                return std::make_shared<ImportStmt>(mod, "", is_py, symbols);
            }
        }

        // 3b. Python module import: use python "math" OR import python "math"
        if (s.rfind("use python ", 0) == 0 || s.rfind("import python ", 0) == 0) {
            std::string mod = s.substr(s.rfind("python ", 0) == 0 ? 7 : (s.find("python ") + 7));
            mod = trim_quotes(trim(mod));
            return std::make_shared<ImportStmt>(mod, "", true);
        }

        // 4. Module import: import loop.ui as ui OR use loop::ui OR use module "name"
        if (s.rfind("import ", 0) == 0) {
            std::string rem = trim(s.substr(7));
            if (rem.rfind("module ", 0) == 0) rem = trim(rem.substr(7));
            std::string mod = rem;
            std::string alias = "";
            auto as_pos = rem.find(" as ");
            if (as_pos != std::string::npos) {
                mod = trim(rem.substr(0, as_pos));
                alias = trim(rem.substr(as_pos + 4));
            }
            mod = trim_quotes(mod);
            return std::make_shared<ImportStmt>(mod, alias, false);
        }
        if (s.rfind("use ", 0) == 0 && s.find("python") == std::string::npos) {
            std::string mod = trim(s.substr(4));
            if (mod.rfind("module ", 0) == 0) mod = trim(mod.substr(7));
            mod = trim_quotes(mod);
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

        // 5b. Module declaration single-line: define module "name" version 1.0
        if (s.rfind("define module", 0) == 0 || s.rfind("@module", 0) == 0) {
            std::regex r(R"((?:define module\s*(?:as)?|@module)\s*["'](.*?)["'](?:\s*(?:version\s*|v)?["']?([0-9\.]+)["']?)?)");
            std::smatch m;
            if (std::regex_search(s, m, r)) {
                return std::make_shared<ModuleDefineStmt>(m[1], m[2].matched ? m[2].str() : "1.0");
            }
            return std::make_shared<ModuleDefineStmt>("module", "1.0");
        }

        // 6. Target UI Compilation & Profile: target("shine_ui") / compile target "xui" / profile("flui")
        if (s.rfind("compile target ", 0) == 0 || s.rfind("compile for ", 0) == 0 ||
            s.rfind("target(", 0) == 0 || s.rfind("@target(", 0) == 0 ||
            s.rfind("profile(", 0) == 0 || s.rfind("@profile(", 0) == 0 || 
            s.rfind("set ui_profile to", 0) == 0 || s.rfind("set ui to", 0) == 0 ||
            s.rfind("set target to", 0) == 0) {
            std::string prof = "xui";
            if (s.find('(') != std::string::npos) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                if (!args.positional.empty()) prof = args.positional[0];
            } else if (s.rfind("compile target ", 0) == 0) {
                prof = trim_quotes(trim(s.substr(15)));
            } else if (s.rfind("compile for ", 0) == 0) {
                prof = trim_quotes(trim(s.substr(12)));
            } else {
                prof = trim_quotes(extract_after(s, "to"));
            }
            return std::make_shared<TargetCompileStmt>(prof);
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
                if (is_enclosed_in_matching_parens(cond_part)) {
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

        // 10. Modern Variable Declarations & Destructuring:
        //     let [a, b] = [1, 2], let (x, y) = (10, 20)
        //     let x = 10, mut x = 10, val x = 10, var x = 10
        if (s.rfind("let ", 0) == 0 || s.rfind("mut ", 0) == 0 || s.rfind("val ", 0) == 0 || s.rfind("var ", 0) == 0) {
            std::string rem = trim(s.substr(4));
            auto eq_pos = rem.find('=');
            if (eq_pos != std::string::npos) {
                std::string lhs = trim(rem.substr(0, eq_pos));
                std::string expr_str = trim(rem.substr(eq_pos + 1));
                if ((lhs.front() == '[' && lhs.back() == ']') || (lhs.front() == '(' && lhs.back() == ')')) {
                    std::string inner_names = lhs.substr(1, lhs.size() - 2);
                    std::vector<std::string> names = split_params(inner_names);
                    return std::make_shared<DestructureStmt>(names, parse_single_expr(expr_str));
                }
                return std::make_shared<SetStmt>(lhs, "=", parse_single_expr(expr_str));
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
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {0, 0});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->title = args.has("title") ? args.get("title") : (!args.positional.empty() ? args.positional[0] : "");
                d->text = args.get("text");
                if (args.positional.size() >= 3 && !args.has("at")) {
                    try { d->x = std::stod(args.positional[1]); d->y = std::stod(args.positional[2]); } catch (...) {}
                }
                if (args.positional.size() >= 5 && !args.has("size")) {
                    try { d->w = std::stod(args.positional[3]); d->h = std::stod(args.positional[4]); } catch (...) {}
                }
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

        // 15. UI Button Directives: ui.btn(...) / ui.button(...) / @ui::btn(...) / draw button ... / insert button ...
        if (s.rfind("ui.btn(", 0) == 0 || s.rfind("ui.button(", 0) == 0 || s.rfind("@ui::btn(", 0) == 0 || 
            s.rfind("@ui::button(", 0) == 0 || s.rfind("button(", 0) == 0 || s.rfind("draw button", 0) == 0 ||
            s.rfind("insert button", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "button";
            if (s.find('(') != std::string::npos && s.rfind("draw button", 0) != 0 && s.rfind("insert button", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {150, 42});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->text = args.has("text") ? args.get("text") : (!args.positional.empty() ? args.positional[0] : "");
                d->action = args.get("action");
                d->snippet = args.get("snippet");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex tx_r(R"(text\s*["'](.*?)["'])");
                std::regex ins_r(R"(insert\s+button\s+["'](.*?)["'])");
                std::regex ac_r(R"(action\s*["'](.*?)["'])");
                std::regex sn_r(R"(snippet\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, tx_r)) d->text = m[1];
                else if (std::regex_search(s, m, ins_r)) d->text = m[1];
                if (std::regex_search(s, m, ac_r)) d->action = m[1];
                if (std::regex_search(s, m, sn_r)) d->snippet = m[1];
            }
            return d;
        }

        // 16. UI Input Directives: ui.input(...) / @ui::input(...) / draw input ...
        if (s.rfind("ui.input(", 0) == 0 || s.rfind("@ui::input(", 0) == 0 || s.rfind("input(", 0) == 0 || s.rfind("draw input", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "input";
            if (s.find('(') != std::string::npos && s.rfind("draw input", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {220, 40});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->placeholder = args.get("placeholder");
                d->var_name = args.has("bind") ? args.get("bind") : args.get("var");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex pl_r(R"(placeholder\s*["'](.*?)["'])");
                std::regex vr_r(R"((?:var|bind)\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, pl_r)) d->placeholder = m[1];
                if (std::regex_search(s, m, vr_r)) d->var_name = m[1];
            }
            return d;
        }

        // 16b. UI Slider Directives: ui.slider(...) / @ui::slider(...) / draw slider ...
        if (s.rfind("ui.slider(", 0) == 0 || s.rfind("@ui::slider(", 0) == 0 || s.rfind("slider(", 0) == 0 || s.rfind("draw slider", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "slider";
            d->min_val = 0; d->max_val = 100; d->current_val = 50;
            if (s.find('(') != std::string::npos && s.rfind("draw slider", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {220, 40});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->text = args.has("label") ? args.get("label") : (args.has("text") ? args.get("text") : (!args.positional.empty() ? args.positional[0] : "Slider"));
                d->min_val = args.get_num("min", 0);
                d->max_val = args.get_num("max", 100);
                d->current_val = args.has("val") ? args.get_num("val", 50) : args.get_num("value", 50);
                d->var_name = args.has("bind") ? args.get("bind") : args.get("var");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex lb_r(R"((?:label|text)\s*["'](.*?)["'])");
                std::regex mn_r(R"(min\s*([0-9\.\-]+))");
                std::regex mx_r(R"(max\s*([0-9\.\-]+))");
                std::regex vl_r(R"((?:val|value)\s*([0-9\.\-]+))");
                std::regex bd_r(R"((?:bind|var)\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, lb_r)) d->text = m[1];
                if (std::regex_search(s, m, mn_r)) d->min_val = std::stod(m[1]);
                if (std::regex_search(s, m, mx_r)) d->max_val = std::stod(m[1]);
                if (std::regex_search(s, m, vl_r)) d->current_val = std::stod(m[1]);
                if (std::regex_search(s, m, bd_r)) d->var_name = m[1];
            }
            return d;
        }

        // 16c. UI Toggle Directives: ui.toggle(...) / @ui::toggle(...) / draw toggle ...
        if (s.rfind("ui.toggle(", 0) == 0 || s.rfind("@ui::toggle(", 0) == 0 || s.rfind("toggle(", 0) == 0 || s.rfind("draw toggle", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "toggle";
            d->is_checked = false;
            if (s.find('(') != std::string::npos && s.rfind("draw toggle", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {160, 36});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->text = args.has("label") ? args.get("label") : (args.has("text") ? args.get("text") : (!args.positional.empty() ? args.positional[0] : "Toggle"));
                d->var_name = args.has("bind") ? args.get("bind") : args.get("var");
                std::string chk = args.get("checked", "false");
                d->is_checked = (chk == "true" || chk == "1");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex lb_r(R"((?:label|text)\s*["'](.*?)["'])");
                std::regex bd_r(R"((?:bind|var)\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, lb_r)) d->text = m[1];
                if (std::regex_search(s, m, bd_r)) d->var_name = m[1];
                if (s.find("checked") != std::string::npos && s.find("unchecked") == std::string::npos) {
                    d->is_checked = true;
                }
            }
            return d;
        }

        // 16d. UI Progress Directives: ui.progress(...) / @ui::progress(...) / draw progress ...
        if (s.rfind("ui.progress(", 0) == 0 || s.rfind("@ui::progress(", 0) == 0 || s.rfind("progress(", 0) == 0 || s.rfind("draw progress", 0) == 0) {
            auto d = std::make_shared<DrawUIStmt>();
            d->ui_type = "progress";
            d->current_val = 0;
            if (s.find('(') != std::string::npos && s.rfind("draw progress", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {-1, -1});
                auto sz = args.get_pair("size", {240, 28});
                d->x = at.first; d->y = at.second;
                d->w = sz.first; d->h = sz.second;
                d->text = args.has("label") ? args.get("label") : (args.has("text") ? args.get("text") : (!args.positional.empty() ? args.positional[0] : "Progress"));
                d->current_val = args.has("val") ? args.get_num("val", 0) : (args.has("value") ? args.get_num("value", 0) : args.get_num("progress", 0));
                d->var_name = args.has("bind") ? args.get("bind") : args.get("var");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex lb_r(R"((?:label|text)\s*["'](.*?)["'])");
                std::regex vl_r(R"((?:val|value|progress)\s*([0-9\.\-]+))");
                std::regex bd_r(R"((?:bind|var)\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { d->x = std::stod(m[1]); d->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { d->w = std::stod(m[1]); d->h = std::stod(m[2]); }
                if (std::regex_search(s, m, lb_r)) d->text = m[1];
                if (std::regex_search(s, m, vl_r)) d->current_val = std::stod(m[1]);
                if (std::regex_search(s, m, bd_r)) d->var_name = m[1];
            }
            return d;
        }

        // 17. Spawn Sprite Directives: spawn.sprite(...) / @spawn::sprite(...) / entity.sprite(...) / spawn sprite ... / spawn.player(...) / spawn player ...
        if (s.rfind("spawn.sprite(", 0) == 0 || s.rfind("@spawn::sprite(", 0) == 0 || 
            s.rfind("entity.sprite(", 0) == 0 || s.rfind("spawn sprite", 0) == 0 ||
            s.rfind("spawn.player(", 0) == 0 || s.rfind("spawn player", 0) == 0) {
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

        // 20. Spawn Spike / Hazard Directives: spawn.spike(...) / spawn spike ... / spawn hazard ...
        if (s.rfind("spawn.spike(", 0) == 0 || s.rfind("@spawn::spike(", 0) == 0 || 
            s.rfind("spawn spike", 0) == 0 || s.rfind("spawn hazard", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "spike";
            if (s.find('(') != std::string::npos && s.rfind("spawn spike", 0) != 0 && s.rfind("spawn hazard", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size", {32, 32});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->color = args.get("color", "#ef4444");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); } else { sp->w = 32; sp->h = 32; }
                if (std::regex_search(s, m, col_r)) sp->color = m[1]; else sp->color = "#ef4444";
            }
            return sp;
        }

        // 21. Spawn Jump Pad / Boost: spawn.pad(...) / spawn jump_pad ... / spawn pad ...
        if (s.rfind("spawn.pad(", 0) == 0 || s.rfind("spawn jump_pad", 0) == 0 || s.rfind("spawn pad", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "jump_pad";
            if (s.find('(') != std::string::npos && s.rfind("spawn jump_pad", 0) != 0 && s.rfind("spawn pad", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                auto sz = args.get_pair("size", {40, 12});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->color = args.get("color", "#fbbf24");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); } else { sp->w = 40; sp->h = 12; }
                if (std::regex_search(s, m, col_r)) sp->color = m[1]; else sp->color = "#fbbf24";
            }
            return sp;
        }

        // 22. Spawn Jump Ring / Orb: spawn.orb(...) / spawn orb ...
        if (s.rfind("spawn.orb(", 0) == 0 || s.rfind("spawn orb", 0) == 0 || s.rfind("spawn jump_ring", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "orb";
            if (s.find('(') != std::string::npos && s.rfind("spawn orb", 0) != 0 && s.rfind("spawn jump_ring", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at");
                sp->x = at.first; sp->y = at.second;
                sp->w = 28; sp->h = 28;
                sp->color = args.get("color", "#f59e0b");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                sp->w = 28; sp->h = 28;
                if (std::regex_search(s, m, col_r)) sp->color = m[1]; else sp->color = "#f59e0b";
            }
            return sp;
        }

        // 23. Spawn Bubbly Dot: spawn.bubbly(...) / @spawn::bubbly(...) / spawn bubbly_dot ...
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

        // 23b. Spawn Moving Platform: spawn.moving_platform(...) / spawn moving_platform ...
        if (s.rfind("spawn.moving_platform(", 0) == 0 || s.rfind("spawn moving_platform", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "moving_platform";
            if (s.find('(') != std::string::npos && s.rfind("spawn moving_platform", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {250, 280});
                auto sz = args.get_pair("size", {130, 18});
                auto rng = args.get_pair("range", {at.first, at.first + 180});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->axis = args.get("axis", "x");
                sp->min_pos = rng.first; sp->max_pos = rng.second;
                sp->speed = args.get_num("speed", 75);
                sp->color = args.get("color", "#06b6d4");
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex rng_r(R"(range\s*\((\d+),\s*(\d+)\))");
                std::regex ax_r(R"(axis\s*["'](.*?)["'])");
                std::regex spd_r(R"(speed\s*(\d+))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); } else { sp->w = 130; sp->h = 18; }
                if (std::regex_search(s, m, rng_r)) { sp->min_pos = std::stod(m[1]); sp->max_pos = std::stod(m[2]); }
                if (std::regex_search(s, m, ax_r)) sp->axis = m[1];
                if (std::regex_search(s, m, spd_r)) sp->speed = std::stod(m[1]);
                if (std::regex_search(s, m, col_r)) sp->color = m[1]; else sp->color = "#06b6d4";
            }
            return sp;
        }

        // 23c. Spawn Enemy NPC: spawn.enemy(...) / spawn enemy ...
        if (s.rfind("spawn.enemy(", 0) == 0 || s.rfind("spawn enemy", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "enemy";
            if (s.find('(') != std::string::npos && s.rfind("spawn enemy", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                sp->name = !args.positional.empty() ? args.positional[0] : args.get("name", "EnemyBot");
                auto at = args.get_pair("at", {450, 300});
                auto sz = args.get_pair("size", {34, 44});
                auto rng = args.get_pair("range", {at.first - 120, at.first + 120});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->min_pos = rng.first; sp->max_pos = rng.second;
                sp->speed = args.get_num("speed", 75);
                sp->health = args.get_num("health", 30);
                sp->color = args.get("color", "#ef4444");
            } else {
                std::regex nm_r(R"(spawn\s+enemy\s*["']?(.*?)["']?(?:\s+at|\s+with|$))");
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex rng_r(R"(range\s*\((\d+),\s*(\d+)\))");
                std::regex col_r(R"(color\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, nm_r) && m[1].matched) sp->name = m[1];
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); } else { sp->w = 34; sp->h = 44; }
                if (std::regex_search(s, m, rng_r)) { sp->min_pos = std::stod(m[1]); sp->max_pos = std::stod(m[2]); }
                if (std::regex_search(s, m, col_r)) sp->color = m[1]; else sp->color = "#ef4444";
            }
            return sp;
        }

        // 23d. Spawn Heart / Health Pack: spawn.heart(...) / spawn heart ...
        if (s.rfind("spawn.heart(", 0) == 0 || s.rfind("spawn heart", 0) == 0 || s.rfind("spawn potion", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "heart";
            if (s.find('(') != std::string::npos && s.rfind("spawn heart", 0) != 0 && s.rfind("spawn potion", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {400, 260});
                sp->x = at.first; sp->y = at.second;
                sp->health = args.get_num("heal", args.get_num("health", 30));
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex hl_r(R"((?:health|heal)\s*(\d+))");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, hl_r)) sp->health = std::stod(m[1]); else sp->health = 30;
            }
            return sp;
        }

        // 23e. Spawn Portal / Goal: spawn.portal(...) / spawn portal ... / spawn goal ...
        if (s.rfind("spawn.portal(", 0) == 0 || s.rfind("spawn portal", 0) == 0 || s.rfind("spawn goal", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "portal";
            if (s.find('(') != std::string::npos && s.rfind("spawn portal", 0) != 0 && s.rfind("spawn goal", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {700, 350});
                auto sz = args.get_pair("size", {44, 68});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->text = args.get("label", args.get("destination", "STAGE GOAL"));
            } else {
                std::regex at_r(R"(at\s*\((\d+),\s*(\d+)\))");
                std::regex sz_r(R"(size\s*\((\d+),\s*(\d+)\))");
                std::regex lb_r(R"((?:label|destination)\s*["'](.*?)["'])");
                std::smatch m;
                if (std::regex_search(s, m, at_r)) { sp->x = std::stod(m[1]); sp->y = std::stod(m[2]); }
                if (std::regex_search(s, m, sz_r)) { sp->w = std::stod(m[1]); sp->h = std::stod(m[2]); } else { sp->w = 44; sp->h = 68; }
                if (std::regex_search(s, m, lb_r)) sp->text = m[1]; else sp->text = "STAGE GOAL";
            }
            return sp;
        }

        // 23f. Spawn Boss Entity: spawn.boss(...) / spawn boss ...
        if (s.rfind("spawn.boss(", 0) == 0 || s.rfind("spawn boss", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "boss";
            if (s.find('(') != std::string::npos && s.rfind("spawn boss", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                sp->name = !args.positional.empty() ? args.positional[0] : args.get("name", "TitanBoss");
                auto at = args.get_pair("at", {900, 310});
                auto sz = args.get_pair("size", {58, 76});
                auto rng = args.get_pair("range", {at.first - 180, at.first + 180});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->min_pos = rng.first; sp->max_pos = rng.second;
                sp->speed = args.get_num("speed", 95);
                sp->health = args.get_num("health", 450);
                sp->fire_rate = args.get_num("fire_rate", 1.7);
                sp->color = args.get("color", "#ef4444");
            } else {
                sp->name = "TitanBoss";
                sp->x = 900; sp->y = 310; sp->w = 58; sp->h = 76;
                sp->min_pos = 720; sp->max_pos = 1080;
                sp->speed = 95; sp->health = 450; sp->fire_rate = 1.7; sp->color = "#ef4444";
            }
            return sp;
        }

        // 23g. Spawn Checkpoint: spawn.checkpoint(...) / spawn checkpoint ...
        if (s.rfind("spawn.checkpoint(", 0) == 0 || s.rfind("spawn checkpoint", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "checkpoint";
            if (s.find('(') != std::string::npos && s.rfind("spawn checkpoint", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {500, 310});
                sp->x = at.first; sp->y = at.second;
                sp->w = 28; sp->h = 56;
                sp->text = args.get("label", !args.positional.empty() ? args.positional[0] : "CHECKPOINT");
                sp->color = args.get("color", "#38bdf8");
            } else {
                sp->x = 500; sp->y = 310; sp->w = 28; sp->h = 56; sp->text = "CHECKPOINT"; sp->color = "#38bdf8";
            }
            return sp;
        }

        // 23h. Spawn Gravity / Physics Zone: spawn.gravity_zone(...) / spawn.zone(...) / spawn gravity_zone ...
        if (s.rfind("spawn.gravity_zone(", 0) == 0 || s.rfind("spawn.zone(", 0) == 0 || s.rfind("spawn gravity_zone", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "gravity_zone";
            if (s.find('(') != std::string::npos && s.rfind("spawn gravity_zone", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {400, 100});
                auto sz = args.get_pair("size", {300, 300});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->scale = args.get_num("scale", args.get_num("gravity_scale", 0.35));
                sp->wind_x = args.get_num("wind_x", 0);
                sp->wind_y = args.get_num("wind_y", 0);
                sp->text = args.get("label", "LOW-G ZONE");
                sp->color = args.get("color", "#c084fc");
            } else {
                sp->x = 400; sp->y = 100; sp->w = 300; sp->h = 300; sp->scale = 0.35; sp->text = "LOW-G ZONE"; sp->color = "#c084fc";
            }
            return sp;
        }

        // 23i. Spawn Teleporter: spawn.teleporter(...) / spawn teleporter ...
        if (s.rfind("spawn.teleporter(", 0) == 0 || s.rfind("spawn teleporter", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "teleporter";
            if (s.find('(') != std::string::npos && s.rfind("spawn teleporter", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {400, 300});
                auto to = args.get_pair("to", {800, 200});
                sp->x = at.first; sp->y = at.second;
                sp->to_x = to.first; sp->to_y = to.second;
                sp->w = 38; sp->h = 58;
                sp->text = args.get("label", "WARP");
                sp->color = args.get("color", "#00f5d4");
            } else {
                sp->x = 400; sp->y = 300; sp->to_x = 800; sp->to_y = 200; sp->w = 38; sp->h = 58; sp->text = "WARP"; sp->color = "#00f5d4";
            }
            return sp;
        }

        // 23j. Spawn Breakable Block: spawn.breakable(...) / spawn breakable ...
        if (s.rfind("spawn.breakable(", 0) == 0 || s.rfind("spawn breakable", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "breakable";
            if (s.find('(') != std::string::npos && s.rfind("spawn breakable", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {300, 260});
                auto sz = args.get_pair("size", {36, 72});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->health = args.get_num("health", 40);
                sp->points = args.get_num("points", 120);
                sp->color = args.get("color", "#f59e0b");
            } else {
                sp->x = 300; sp->y = 260; sp->w = 36; sp->h = 72; sp->health = 40; sp->points = 120; sp->color = "#f59e0b";
            }
            return sp;
        }

        // 23k. Spawn Laser Hazard: spawn.laser_hazard(...) / spawn laser_hazard ...
        if (s.rfind("spawn.laser_hazard(", 0) == 0 || s.rfind("spawn laser_hazard", 0) == 0) {
            auto sp = std::make_shared<SpawnEntityStmt>();
            sp->entity_type = "laser_hazard";
            if (s.find('(') != std::string::npos && s.rfind("spawn laser_hazard", 0) != 0) {
                auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
                auto at = args.get_pair("at", {350, 240});
                auto sz = args.get_pair("size", {12, 110});
                sp->x = at.first; sp->y = at.second;
                sp->w = sz.first; sp->h = sz.second;
                sp->interval = args.get_num("interval", 2.0);
                sp->damage = args.get_num("damage", 30);
                sp->color = args.get("color", "#f43f5e");
            } else {
                sp->x = 350; sp->y = 240; sp->w = 12; sp->h = 110; sp->interval = 2.0; sp->damage = 30; sp->color = "#f43f5e";
            }
            return sp;
        }

        // 23l. Game World & Directives: game.gravity(...) / game.world(...) / game.camera(...) / game.lives(...) / game.friction(...) / game.scenario(...) / game.physics(...) / game.time_scale(...)
        if (s.rfind("game.gravity(", 0) == 0 || s.rfind("game.friction(", 0) == 0 || 
            s.rfind("game.world(", 0) == 0 || s.rfind("game.lives(", 0) == 0 || s.rfind("game.camera(", 0) == 0 ||
            s.rfind("game.scenario(", 0) == 0 || s.rfind("game.background(", 0) == 0 ||
            s.rfind("game.physics(", 0) == 0 || s.rfind("game.time_scale(", 0) == 0) {
            std::string key = s.substr(5, s.find('(') - 5);
            auto args = parse_call_args(s.substr(s.find('(') + 1, s.find_last_of(')') - s.find('(') - 1));
            double v1 = 0, v2 = 0, v3 = 0;
            std::string sv = "", sv2 = "", sv3 = "";
            if (key == "gravity") {
                v1 = !args.positional.empty() ? std::stod(args.positional[0]) : args.get_num("val", 980);
            } else if (key == "friction") {
                v1 = !args.positional.empty() ? std::stod(args.positional[0]) : args.get_num("val", 0.82);
            } else if (key == "lives") {
                v1 = !args.positional.empty() ? std::stod(args.positional[0]) : args.get_num("val", 3);
            } else if (key == "world") {
                auto sz = args.get_pair("size", {args.get_num("width", 1200), args.get_num("height", 480)});
                v1 = sz.first; v2 = sz.second;
            } else if (key == "camera") {
                sv = args.get("follow", "player");
                v1 = args.get_num("smooth", 0.12);
            } else if (key == "scenario" || key == "background") {
                sv = !args.positional.empty() ? args.positional[0] : args.get("name", "CyberStage");
                sv2 = args.get("weather", args.get("theme", "stars"));
                sv3 = args.get("accent", args.get("bg", "#38bdf8"));
            } else if (key == "physics") {
                v1 = args.get_num("gravity", 980);
                v2 = args.get_num("friction", 0.82);
                v3 = args.get_num("time_scale", 1.0);
            } else if (key == "time_scale") {
                v1 = !args.positional.empty() ? std::stod(args.positional[0]) : args.get_num("val", 1.0);
            }
            return std::make_shared<GameConfigStmt>(key, v1, v2, sv, sv2, sv3, v3);
        }

        // 24. Audio Tone Directives: audio.tone(...) / @audio::tone(...) / sound.tone(...) / play tone ...
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

        // 25. FX Particles: fx.particles(...) / @fx::particles(...) / emit particles ...
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

        // 26a. Indexed Assignment: arr[idx] = val, map["key"] = val
        std::regex assign_idx_regex(R"(^([A-Za-z0-9_]+)\s*\[\s*(.*?)\s*\]\s*(\+=|-=|\*=|\/=|%=|=)\s*(.*)$)");
        std::smatch aim;
        if (std::regex_search(s, aim, assign_idx_regex)) {
            std::string name = aim[1];
            std::string idx_str = aim[2];
            std::string op = aim[3];
            std::string expr_str = aim[4];
            return std::make_shared<SetIndexStmt>(name, parse_single_expr(idx_str), op, parse_single_expr(expr_str));
        }

        // 26b. Shorthand Assignment: x = 10, x += 5, x -= 2, x %= 3, user.name = "Alice"
        std::regex assign_regex(R"(^([A-Za-z0-9_\.]+)\s*(\+=|-=|\*=|\/=|%=|=)\s*(.*)$)");
        std::smatch am;
        if (std::regex_search(s, am, assign_regex)) {
            std::string name = am[1];
            std::string op = am[2];
            std::string expr_str = am[3];
            if (s.rfind("create ", 0) != 0 && s.rfind("draw ", 0) != 0 && s.rfind("spawn ", 0) != 0) {
                return std::make_shared<SetStmt>(name, op, parse_single_expr(expr_str));
            }
        }

        // 27. Function call statement: callee(...) OR call callee(...)
        if (s.rfind("call ", 0) == 0) {
            std::regex call_r(R"(call\s+([A-Za-z0-9_\.]+)\s*(?:\((.*?)\))?)");
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
        std::regex fn_stmt_r(R"(^([A-Za-z0-9_\.]+)\s*\((.*?)\)$)");
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

        // 27b. run snippet / runpy shorthand statement: run snippet sn1 / runpy sn1 / execute snippet sn1
        if (s.rfind("run snippet ", 0) == 0 || s.rfind("run_snippet ", 0) == 0 || s.rfind("execute snippet ", 0) == 0) {
            size_t pos = s.find("snippet ");
            std::string arg = trim(s.substr(pos + 8));
            return std::make_shared<CallStmt>("snippet.run", std::vector<std::shared_ptr<Expr>>{parse_single_expr(arg)});
        }
        if (s.rfind("runpy ", 0) == 0) {
            std::string arg = trim(s.substr(6));
            return std::make_shared<CallStmt>("runpy", std::vector<std::shared_ptr<Expr>>{parse_single_expr(arg)});
        }

        // 28. Syscall & Process
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

        // 29. Python inline statement: py: ...
        if (s.rfind("py:", 0) == 0 || s.rfind("py ", 0) == 0) {
            std::string code = trim(s.substr(s.rfind("py:", 0) == 0 ? 3 : 2));
            return std::make_shared<PythonBlockStmt>(code);
        }

        // 30. Expression Statement (pipelines: expr |> out, function invocations, etc.)
        if (s.find("|>") != std::string::npos || s.find('(') != std::string::npos || s.rfind("py!(", 0) == 0) {
            auto e = parse_single_expr(s);
            if (e) return std::make_shared<ExprStmt>(e);
        }

        return nullptr;
    }

    // Parse single expression with operator precedence climbing and robust grouping
    std::shared_ptr<Expr> parse_single_expr(const std::string& raw) {
        std::string s = trim(raw);
        if (s.empty()) return std::make_shared<LiteralExpr>(Value());

        // 0. Pipeline operator |>
        size_t pipe_pos = find_level_0_op_rightmost(s, "|>");
        if (pipe_pos != std::string::npos) {
            auto left = parse_single_expr(trim(s.substr(0, pipe_pos)));
            auto right = parse_single_expr(trim(s.substr(pipe_pos + 2)));
            return std::make_shared<BinaryExpr>(left, "|>", right);
        }

        // 0b. Ternary operator: cond ? then_expr : else_expr
        size_t q_pos = find_level_0_op_rightmost(s, "?");
        if (q_pos != std::string::npos && (q_pos == 0 || s[q_pos - 1] != '?') && (q_pos + 1 >= s.size() || s[q_pos + 1] != '?')) {
            std::string cond_str = trim(s.substr(0, q_pos));
            std::string rem = trim(s.substr(q_pos + 1));
            size_t col_pos = find_level_0_op_rightmost(rem, ":");
            if (col_pos != std::string::npos) {
                auto cond_e = parse_single_expr(cond_str);
                auto then_e = parse_single_expr(trim(rem.substr(0, col_pos)));
                auto else_e = parse_single_expr(trim(rem.substr(col_pos + 1)));
                return std::make_shared<TernaryExpr>(cond_e, then_e, else_e);
            }
        }

        // 0c. Null-coalescing operator: left ?? right
        size_t nc_pos = find_level_0_op_rightmost(s, "??");
        if (nc_pos != std::string::npos) {
            auto left = parse_single_expr(trim(s.substr(0, nc_pos)));
            auto right = parse_single_expr(trim(s.substr(nc_pos + 2)));
            return std::make_shared<BinaryExpr>(left, "??", right);
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

        // 2. Parenthesized Grouping & Tuples: (expr) OR (x, y)
        if (is_enclosed_in_matching_parens(s)) {
            std::string inner = trim(s.substr(1, s.size() - 2));
            bool has_comma = false;
            size_t comma_idx = std::string::npos;
            int d = 0;
            bool in_sq = false, in_dq = false;
            for (size_t ci = 0; ci < inner.size(); ++ci) {
                char c = inner[ci];
                if (c == '\'' && !in_dq) in_sq = !in_sq;
                else if (c == '"' && !in_sq) in_dq = !in_dq;
                else if (!in_sq && !in_dq) {
                    if (c == '(' || c == '[' || c == '{') d++;
                    else if (c == ')' || c == ']' || c == '}') d--;
                    else if (c == ',' && d == 0) {
                        has_comma = true;
                        comma_idx = ci;
                        break;
                    }
                }
            }
            if (has_comma) {
                auto x_expr = parse_single_expr(trim(inner.substr(0, comma_idx)));
                auto y_expr = parse_single_expr(trim(inner.substr(comma_idx + 1)));
                return std::make_shared<TupleExpr>(x_expr, y_expr);
            } else {
                return parse_single_expr(inner);
            }
        }

        // 3. List Literals: [1, 2, 3]
        if (is_enclosed_in_matching_brackets(s)) {
            std::string inner = trim(s.substr(1, s.size() - 2));
            std::vector<std::shared_ptr<Expr>> elements;
            if (!inner.empty()) {
                auto raw_items = split_level_0(inner, ',');
                for (const auto& item_s : raw_items) {
                    elements.push_back(parse_single_expr(trim(item_s)));
                }
            }
            return std::make_shared<ListExpr>(elements);
        }

        // 4. Map Literals: {"key": val, "k2": v2}
        if (is_enclosed_in_matching_braces(s)) {
            std::string inner = trim(s.substr(1, s.size() - 2));
            std::vector<std::pair<std::string, std::shared_ptr<Expr>>> entries;
            if (!inner.empty()) {
                auto raw_entries = split_level_0(inner, ',');
                for (const auto& entry_s : raw_entries) {
                    std::string e = trim(entry_s);
                    if (e.empty()) continue;
                    size_t colon_p = std::string::npos;
                    int d = 0;
                    bool in_sq = false, in_dq = false;
                    for (size_t ci = 0; ci < e.size(); ++ci) {
                        char c = e[ci];
                        if (c == '\'' && !in_dq) in_sq = !in_sq;
                        else if (c == '"' && !in_sq) in_dq = !in_dq;
                        else if (!in_sq && !in_dq) {
                            if (c == '(' || c == '[' || c == '{') d++;
                            else if (c == ')' || c == ']' || c == '}') d--;
                            else if (c == ':' && d == 0) { colon_p = ci; break; }
                        }
                    }
                    if (colon_p != std::string::npos) {
                        std::string k = trim_quotes(trim(e.substr(0, colon_p)));
                        std::string v = trim(e.substr(colon_p + 1));
                        entries.push_back({k, parse_single_expr(v)});
                    }
                }
            }
            return std::make_shared<MapExpr>(entries);
        }

        // 5. Indexing Expression: target[index]
        if (s.back() == ']' && !is_enclosed_in_matching_brackets(s)) {
            int b_depth = 0;
            long long match_idx = -1;
            bool in_sq = false, in_dq = false;
            for (long long i = static_cast<long long>(s.size()) - 1; i >= 0; --i) {
                char c = s[i];
                if (c == '\'' && !in_dq) in_sq = !in_sq;
                else if (c == '"' && !in_sq) in_dq = !in_dq;
                else if (!in_sq && !in_dq) {
                    if (c == ']') b_depth++;
                    else if (c == '[') {
                        b_depth--;
                        if (b_depth == 0) {
                            match_idx = i;
                            break;
                        }
                    }
                }
            }
            if (match_idx > 0) {
                std::string target_part = trim(s.substr(0, match_idx));
                std::string index_part = trim(s.substr(match_idx + 1, s.size() - match_idx - 2));
                return std::make_shared<IndexExpr>(parse_single_expr(target_part), parse_single_expr(index_part));
            }
        }

        // 6. Interpolated String: $"Hello {name}" OR f"..." OR double-quoted "Hello {name}"
        if ((s.front() == '$' || s.front() == 'f') && s.size() >= 3) {
            std::string inner = s.substr(1);
            if ((inner.front() == '"' && inner.back() == '"') || (inner.front() == '\'' && inner.back() == '\'')) {
                std::string content = unescape_string_literal(inner.substr(1, inner.size() - 2));
                return std::make_shared<InterpolatedStringExpr>(content);
            }
        }
        if ((s.front() == '"' && s.back() == '"' && s.size() >= 2) ||
            (s.front() == '\'' && s.back() == '\'' && s.size() >= 2)) {
            std::string content = unescape_string_literal(s.substr(1, s.size() - 2));
            if (s.front() == '"') {
                size_t b_open = content.find('{');
                while (b_open != std::string::npos && b_open + 1 < content.size()) {
                    char first_c = content[b_open + 1];
                    size_t b_close = content.find('}', b_open + 1);
                    if ((std::isalpha(static_cast<unsigned char>(first_c)) || first_c == '_') && b_close != std::string::npos) {
                        std::string inside = content.substr(b_open + 1, b_close - b_open - 1);
                        if (inside.find(':') == std::string::npos && inside.find('"') == std::string::npos) {
                            return std::make_shared<InterpolatedStringExpr>(content);
                        }
                    }
                    b_open = content.find('{', b_open + 1);
                }
            }
            return std::make_shared<LiteralExpr>(Value(content));
        }

        // 7. Logical OR (or, ||)
        for (const std::string& or_op : {" or ", " || "}) {
            size_t p = find_level_0_op_rightmost(s, or_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(trim(s.substr(0, p)));
                auto right = parse_single_expr(trim(s.substr(p + or_op.size())));
                return std::make_shared<BinaryExpr>(left, "or", right);
            }
        }

        // 8. Logical AND (and, &&)
        for (const std::string& and_op : {" and ", " && "}) {
            size_t p = find_level_0_op_rightmost(s, and_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(trim(s.substr(0, p)));
                auto right = parse_single_expr(trim(s.substr(p + and_op.size())));
                return std::make_shared<BinaryExpr>(left, "and", right);
            }
        }

        // 9. Comparisons (==, !=, <=, >=, <, >)
        for (const std::string& cmp : {"==", "!=", "<=", ">=", "<", ">"}) {
            size_t p = find_level_0_op_rightmost(s, cmp);
            if (p != std::string::npos) {
                auto left = parse_single_expr(trim(s.substr(0, p)));
                auto right = parse_single_expr(trim(s.substr(p + cmp.size())));
                return std::make_shared<BinaryExpr>(left, cmp, right);
            }
        }

        // 10. Addition and Subtraction (+, -)
        for (const std::string& add_op : {"+", "-"}) {
            size_t p = find_level_0_op_rightmost(s, add_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(trim(s.substr(0, p)));
                auto right = parse_single_expr(trim(s.substr(p + 1)));
                return std::make_shared<BinaryExpr>(left, add_op, right);
            }
        }

        // 11. Multiplication, Division, Modulo (*, /, %)
        for (const std::string& mul_op : {"*", "/", "%"}) {
            size_t p = find_level_0_op_rightmost(s, mul_op);
            if (p != std::string::npos) {
                auto left = parse_single_expr(trim(s.substr(0, p)));
                auto right = parse_single_expr(trim(s.substr(p + 1)));
                return std::make_shared<BinaryExpr>(left, mul_op, right);
            }
        }

        // 12. Power (^)
        size_t pow_p = find_level_0_op_rightmost(s, "^");
        if (pow_p != std::string::npos) {
            auto left = parse_single_expr(trim(s.substr(0, pow_p)));
            auto right = parse_single_expr(trim(s.substr(pow_p + 1)));
            return std::make_shared<BinaryExpr>(left, "^", right);
        }

        // 13. Unary Operators: -x, !x, not x
        if (s.front() == '-' && s.size() > 1 && !is_numeric(s)) {
            return std::make_shared<UnaryExpr>("-", parse_single_expr(trim(s.substr(1))));
        }
        if (s.front() == '!' && s.size() > 1) {
            return std::make_shared<UnaryExpr>("!", parse_single_expr(trim(s.substr(1))));
        }
        if (s.rfind("not ", 0) == 0) {
            return std::make_shared<UnaryExpr>("not", parse_single_expr(trim(s.substr(4))));
        }

        // 14. Number literal
        if (is_numeric(s)) {
            if (s.find('.') != std::string::npos) {
                return std::make_shared<LiteralExpr>(Value(std::stod(s)));
            } else {
                return std::make_shared<LiteralExpr>(Value(static_cast<int64_t>(std::stoll(s))));
            }
        }

        // 15. Boolean & Nil
        if (s == "true") return std::make_shared<LiteralExpr>(Value(true));
        if (s == "false") return std::make_shared<LiteralExpr>(Value(false));
        if (s == "nil" || s == "null" || s == "none") return std::make_shared<LiteralExpr>(Value());

        // 16. Function calls & Chained Method Calls: callee(args) or expr.method(args)
        std::regex fn_call_r(R"(^([A-Za-z0-9_\.:]+)\s*\((.*?)\)$)");
        std::smatch fcm;
        if (std::regex_search(s, fcm, fn_call_r)) {
            std::string callee = fcm[1];
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
        if (!s.empty() && s.back() == ')') {
            int p_depth = 0;
            long long open_p = -1;
            bool in_sq = false, in_dq = false;
            for (long long i = static_cast<long long>(s.size()) - 1; i >= 0; --i) {
                char c = s[i];
                if (c == '\'' && !in_dq && (i == 0 || s[i - 1] != '\\')) in_sq = !in_sq;
                else if (c == '"' && !in_sq && (i == 0 || s[i - 1] != '\\')) in_dq = !in_dq;
                else if (!in_sq && !in_dq) {
                    if (c == ')') p_depth++;
                    else if (c == '(') {
                        p_depth--;
                        if (p_depth == 0) { open_p = i; break; }
                    }
                }
            }
            if (open_p > 0) {
                std::string prefix = trim(s.substr(0, static_cast<size_t>(open_p)));
                std::string raw_args = s.substr(static_cast<size_t>(open_p) + 1, s.size() - static_cast<size_t>(open_p) - 2);
                size_t last_dot = find_level_0_op_rightmost(prefix, ".");
                if (last_dot != std::string::npos) {
                    std::string receiver_str = trim(prefix.substr(0, last_dot));
                    std::string method_str = trim(prefix.substr(last_dot + 1));
                    if (!receiver_str.empty() && !method_str.empty()) {
                        std::vector<std::shared_ptr<Expr>> args;
                        args.push_back(parse_single_expr(receiver_str));
                        if (!raw_args.empty()) {
                            for (const auto& a : split_arguments(raw_args)) {
                                args.push_back(parse_single_expr(a));
                            }
                        }
                        return std::make_shared<CallExpr>(method_str, args);
                    }
                }
            }
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

public:
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

    static std::string unescape_string_literal(const std::string& s) {
        std::string res;
        for (size_t i = 0; i < s.size(); ++i) {
            if (s[i] == '\\' && i + 1 < s.size()) {
                char next = s[i + 1];
                if (next == 'n') { res += '\n'; i++; }
                else if (next == 't') { res += '\t'; i++; }
                else if (next == 'r') { res += '\r'; i++; }
                else if (next == '"') { res += '"'; i++; }
                else if (next == '\'') { res += '\''; i++; }
                else if (next == '\\') { res += '\\'; i++; }
                else { res += s[i]; }
            } else {
                res += s[i];
            }
        }
        return res;
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
                if (c == '(' || c == '[' || c == '{') paren_depth++;
                else if (c == ')' || c == ']' || c == '}') paren_depth--;
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

    static bool is_enclosed_in_matching_parens(const std::string& s) {
        if (s.size() < 2 || s.front() != '(' || s.back() != ')') return false;
        int depth = 0;
        bool in_single = false, in_double = false;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\'' && !in_double && (i == 0 || s[i - 1] != '\\')) in_single = !in_single;
            else if (c == '"' && !in_single && (i == 0 || s[i - 1] != '\\')) in_double = !in_double;
            else if (!in_single && !in_double) {
                if (c == '(') depth++;
                else if (c == ')') {
                    depth--;
                    if (depth == 0 && i < s.size() - 1) return false;
                }
            }
        }
        return depth == 0;
    }

    static bool is_enclosed_in_matching_brackets(const std::string& s) {
        if (s.size() < 2 || s.front() != '[' || s.back() != ']') return false;
        int depth = 0;
        bool in_single = false, in_double = false;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\'' && !in_double && (i == 0 || s[i - 1] != '\\')) in_single = !in_single;
            else if (c == '"' && !in_single && (i == 0 || s[i - 1] != '\\')) in_double = !in_double;
            else if (!in_single && !in_double) {
                if (c == '[') depth++;
                else if (c == ']') {
                    depth--;
                    if (depth == 0 && i < s.size() - 1) return false;
                }
            }
        }
        return depth == 0;
    }

    static bool is_enclosed_in_matching_braces(const std::string& s) {
        if (s.size() < 2 || s.front() != '{' || s.back() != '}') return false;
        int depth = 0;
        bool in_single = false, in_double = false;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\'' && !in_double && (i == 0 || s[i - 1] != '\\')) in_single = !in_single;
            else if (c == '"' && !in_single && (i == 0 || s[i - 1] != '\\')) in_double = !in_double;
            else if (!in_single && !in_double) {
                if (c == '{') depth++;
                else if (c == '}') {
                    depth--;
                    if (depth == 0 && i < s.size() - 1) return false;
                }
            }
        }
        return depth == 0;
    }

    static std::vector<std::string> split_level_0(const std::string& s, char delim) {
        std::vector<std::string> res;
        std::string curr = "";
        int depth = 0;
        bool in_single = false, in_double = false;
        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\'' && !in_double && (i == 0 || s[i - 1] != '\\')) { in_single = !in_single; curr += c; }
            else if (c == '"' && !in_single && (i == 0 || s[i - 1] != '\\')) { in_double = !in_double; curr += c; }
            else if (!in_single && !in_double) {
                if (c == '(' || c == '[' || c == '{') { depth++; curr += c; }
                else if (c == ')' || c == ']' || c == '}') { depth--; curr += c; }
                else if (c == delim && depth == 0) {
                    res.push_back(curr);
                    curr = "";
                } else {
                    curr += c;
                }
            } else {
                curr += c;
            }
        }
        if (!curr.empty()) res.push_back(curr);
        return res;
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
                if (c == '(' || c == '[' || c == '{') paren_depth++;
                else if (c == ')' || c == ']' || c == '}') paren_depth--;
                else if (paren_depth == 0) {
                    if (s.substr(i, op.size()) == op) {
                        return i;
                    }
                }
            }
        }
        return std::string::npos;
    }

    static size_t find_level_0_op_rightmost(const std::string& s, const std::string& op) {
        if (s.size() < op.size()) return std::string::npos;
        bool in_single = false, in_double = false;
        int depth = 0;

        std::vector<int> depths(s.size(), 0);
        std::vector<bool> in_str(s.size(), false);

        for (size_t i = 0; i < s.size(); ++i) {
            char c = s[i];
            if (c == '\'' && !in_double && (i == 0 || s[i - 1] != '\\')) in_single = !in_single;
            else if (c == '"' && !in_single && (i == 0 || s[i - 1] != '\\')) in_double = !in_double;
            in_str[i] = (in_single || in_double);
            if (!in_single && !in_double) {
                if (c == '(' || c == '[' || c == '{') depth++;
                else if (c == ')' || c == ']' || c == '}') depth--;
            }
            depths[i] = depth;
        }

        for (long long i = static_cast<long long>(s.size()) - static_cast<long long>(op.size()); i >= 0; --i) {
            if (!in_str[i] && depths[i] == 0) {
                if (s.substr(i, op.size()) == op) {
                    if (i > 0 && i + op.size() < s.size()) {
                        if (op == "-") {
                            long long p = i - 1;
                            while (p >= 0 && std::isspace(static_cast<unsigned char>(s[p]))) p--;
                            if (p >= 0) {
                                char prev = s[p];
                                if (prev == '+' || prev == '-' || prev == '*' || prev == '/' || 
                                    prev == '%' || prev == '^' || prev == '(' || prev == '[' || 
                                    prev == '=' || prev == '<' || prev == '>' || prev == '!' || prev == ',' ||
                                    prev == '?' || prev == ':') {
                                    continue;
                                }
                            } else {
                                continue;
                            }
                        }
                        return static_cast<size_t>(i);
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

    // ── SwiftUI View Hierarchy Declarative Parser Subsystem (v2.9) ──

    static bool match_swiftui_view_type(const std::string& word, SwiftUIViewType& out_type) {
        if (word == "VStack") { out_type = SwiftUIViewType::VStack; return true; }
        if (word == "HStack") { out_type = SwiftUIViewType::HStack; return true; }
        if (word == "ZStack") { out_type = SwiftUIViewType::ZStack; return true; }
        if (word == "List") { out_type = SwiftUIViewType::List; return true; }
        if (word == "ScrollView") { out_type = SwiftUIViewType::ScrollView; return true; }
        if (word == "Section") { out_type = SwiftUIViewType::Section; return true; }
        if (word == "Group") { out_type = SwiftUIViewType::Group; return true; }
        if (word == "ForEach") { out_type = SwiftUIViewType::ForEach; return true; }
        if (word == "Text") { out_type = SwiftUIViewType::Text; return true; }
        if (word == "Button") { out_type = SwiftUIViewType::Button; return true; }
        if (word == "Image") { out_type = SwiftUIViewType::Image; return true; }
        if (word == "TextField") { out_type = SwiftUIViewType::TextField; return true; }
        if (word == "Toggle") { out_type = SwiftUIViewType::Toggle; return true; }
        if (word == "Slider") { out_type = SwiftUIViewType::Slider; return true; }
        if (word == "ProgressView") { out_type = SwiftUIViewType::ProgressView; return true; }
        if (word == "Spacer") { out_type = SwiftUIViewType::Spacer; return true; }
        if (word == "Divider") { out_type = SwiftUIViewType::Divider; return true; }
        if (word == "Badge") { out_type = SwiftUIViewType::Badge; return true; }
        if (word == "Circle") { out_type = SwiftUIViewType::Circle; return true; }
        if (word == "Rectangle") { out_type = SwiftUIViewType::Rectangle; return true; }
        if (word == "RoundedRectangle") { out_type = SwiftUIViewType::RoundedRectangle; return true; }
        if (word == "Color") { out_type = SwiftUIViewType::Color; return true; }
        return false;
    }

    static bool is_swiftui_view_starter(const std::string& line) {
        std::string s = trim(line);
        if (s.empty()) return false;
        std::string word;
        size_t i = 0;
        while (i < s.size() && (std::isalnum(static_cast<unsigned char>(s[i])) || s[i] == '_')) {
            word += s[i++];
        }
        SwiftUIViewType vt;
        if (match_swiftui_view_type(word, vt)) {
            while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) i++;
            if (i >= s.size() || s[i] == '(' || s[i] == '{' || s[i] == '.' || s[i] == '"' || s[i] == '\'') {
                return true;
            }
        }
        return false;
    }

    static void extract_chained_modifiers(std::string& remaining_line, std::vector<SwiftUIModifier>& out_modifiers) {
        size_t p = 0;
        while (p < remaining_line.size()) {
            while (p < remaining_line.size() && std::isspace(static_cast<unsigned char>(remaining_line[p]))) p++;
            if (p < remaining_line.size() && remaining_line[p] == '.') {
                p++;
                std::string mod_name;
                while (p < remaining_line.size() && (std::isalnum(static_cast<unsigned char>(remaining_line[p])) || remaining_line[p] == '_')) {
                    mod_name += remaining_line[p++];
                }
                if (mod_name.empty()) break;
                SwiftUIModifier mod;
                mod.name = mod_name;
                while (p < remaining_line.size() && std::isspace(static_cast<unsigned char>(remaining_line[p]))) p++;
                if (p < remaining_line.size() && remaining_line[p] == '(') {
                    size_t open_p = p;
                    int depth = 0;
                    size_t close_p = std::string::npos;
                    for (size_t k = open_p; k < remaining_line.size(); ++k) {
                        if (remaining_line[k] == '(') depth++;
                        else if (remaining_line[k] == ')') {
                            depth--;
                            if (depth == 0) { close_p = k; break; }
                        }
                    }
                    if (close_p != std::string::npos) {
                        std::string inside = remaining_line.substr(open_p + 1, close_p - open_p - 1);
                        auto raw_args = split_arguments(inside);
                        for (const auto& a : raw_args) {
                            size_t col = find_operator_outside_quotes(a, ":");
                            if (col != std::string::npos) {
                                mod.named_args[trim(a.substr(0, col))] = trim(a.substr(col + 1));
                            } else {
                                mod.args.push_back(trim(a));
                            }
                        }
                        p = close_p + 1;
                    }
                }
                out_modifiers.push_back(mod);
            } else {
                break;
            }
        }
    }

    static void collect_following_modifiers(const std::vector<std::string>& lines, size_t& idx, std::vector<SwiftUIModifier>& out_modifiers) {
        while (idx < lines.size()) {
            std::string t = trim(lines[idx]);
            if (t.empty()) { idx++; continue; }
            if (t[0] == '.') {
                extract_chained_modifiers(t, out_modifiers);
                idx++;
            } else {
                break;
            }
        }
    }

    static std::shared_ptr<SwiftUIViewNode> parse_swiftui_view(const std::vector<std::string>& lines, size_t& idx) {
        if (idx >= lines.size()) return nullptr;
        std::string raw = trim(lines[idx]);
        if (raw.empty()) return nullptr;

        size_t p = 0;
        std::string view_type_str;
        while (p < raw.size() && (std::isalnum(static_cast<unsigned char>(raw[p])) || raw[p] == '_')) {
            view_type_str += raw[p++];
        }

        SwiftUIViewType vtype = SwiftUIViewType::Custom;
        if (!match_swiftui_view_type(view_type_str, vtype)) {
            vtype = SwiftUIViewType::Custom;
        }

        auto node = std::make_shared<SwiftUIViewNode>(vtype);
        if (vtype == SwiftUIViewType::Custom) {
            node->custom_name = view_type_str;
        }

        while (p < raw.size() && std::isspace(static_cast<unsigned char>(raw[p]))) p++;

        // Parse arguments in parentheses or quotes
        if (p < raw.size() && raw[p] == '(') {
            size_t open_p = p;
            int depth = 0;
            size_t close_p = std::string::npos;
            for (size_t k = open_p; k < raw.size(); ++k) {
                if (raw[k] == '(') depth++;
                else if (raw[k] == ')') {
                    depth--;
                    if (depth == 0) { close_p = k; break; }
                }
            }
            if (close_p != std::string::npos) {
                std::string arg_content = raw.substr(open_p + 1, close_p - open_p - 1);
                p = close_p + 1;
                auto args = split_arguments(arg_content);
                for (size_t ai = 0; ai < args.size(); ++ai) {
                    std::string a = trim(args[ai]);
                    size_t col = find_operator_outside_quotes(a, ":");
                    if (col != std::string::npos) {
                        std::string k = trim(a.substr(0, col));
                        std::string v = trim(a.substr(col + 1));
                        node->attributes[k] = v;
                        if (k == "text" || k == "isOn" || k == "value") {
                            if (!v.empty() && v[0] == '$') {
                                node->binding_var = v.substr(1);
                            }
                        }
                    } else {
                        // Positional arg
                        if (ai == 0) {
                            std::string val = a;
                            if (val.size() >= 2 && ((val.front() == '"' && val.back() == '"') || (val.front() == '\'' && val.back() == '\''))) {
                                val = val.substr(1, val.size() - 2);
                            }
                            node->primary_arg = val;
                        } else {
                            node->attributes["arg" + std::to_string(ai)] = a;
                        }
                    }
                }
            }
        } else if (p < raw.size() && (raw[p] == '"' || raw[p] == '\'')) {
            // Positional string without parens, e.g. Text "Hello"
            char q = raw[p++];
            std::string s_lit;
            while (p < raw.size() && raw[p] != q) {
                s_lit += raw[p++];
            }
            if (p < raw.size() && raw[p] == q) p++;
            node->primary_arg = s_lit;
        }

        idx++; // Advance past view declaration line

        while (p < raw.size() && std::isspace(static_cast<unsigned char>(raw[p]))) p++;

        // Check for trailing block { ... }
        bool has_block = false;
        std::string rest = (p < raw.size()) ? trim(raw.substr(p)) : "";
        if (!rest.empty() && rest[0] == '{') {
            has_block = true;
            rest = trim(rest.substr(1));
        } else if (idx < lines.size() && trim(lines[idx]) == "{") {
            has_block = true;
            idx++;
            rest = "";
        }

        if (has_block) {
            if (vtype == SwiftUIViewType::Button) {
                // Button trailing closure / action
                std::vector<std::string> act_lines;
                if (!rest.empty()) {
                    if (rest.back() == '}') {
                        act_lines.push_back(trim(rest.substr(0, rest.size() - 1)));
                        rest = "";
                    } else {
                        act_lines.push_back(rest);
                    }
                }
                int b_depth = (act_lines.empty() || rest.empty()) ? 1 : 0;
                while (idx < lines.size() && b_depth > 0) {
                    std::string l = trim(lines[idx++]);
                    if (l == "}") { b_depth--; break; }
                    for (char c : l) {
                        if (c == '{') b_depth++;
                        else if (c == '}') { b_depth--; if (b_depth == 0) break; }
                    }
                    if (b_depth > 0) act_lines.push_back(l);
                }
                node->action_code = join_lines(act_lines);
            } else {
                // Container children
                int b_depth = 1;
                while (idx < lines.size() && b_depth > 0) {
                    std::string next_line = trim(lines[idx]);
                    if (next_line.empty()) { idx++; continue; }
                    if (next_line == "}") {
                        idx++;
                        break;
                    }
                    if (next_line.rfind("}", 0) == 0) {
                        idx++;
                        std::string after = trim(next_line.substr(1));
                        if (!after.empty() && after[0] == '.') {
                            extract_chained_modifiers(after, node->modifiers);
                        }
                        break;
                    }

                    // Check if it's another view
                    if (is_swiftui_view_starter(next_line)) {
                        auto child = parse_swiftui_view(lines, idx);
                        if (child) {
                            node->children.push_back(child);
                        }
                    } else {
                        idx++;
                    }
                }
            }
        }

        // Chained modifiers on remainder of current line
        if (!rest.empty() && rest[0] == '.') {
            extract_chained_modifiers(rest, node->modifiers);
        }

        // Chained modifiers on subsequent lines
        collect_following_modifiers(lines, idx, node->modifiers);

        return node;
    }
};

} // namespace looping
