#pragma once

#include "LoopingValue.hpp"
#include "LoopingAST.hpp"
#include "LoopingParser.hpp"
#include "LoopingPythonBridge.hpp"
#include "LoopingCompiler.hpp"
#include <iostream>
#include <fstream>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <memory>
#include <cmath>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <thread>

namespace looping {

class JsonParser {
    std::string src;
    size_t pos = 0;

    void skip_whitespace() {
        while (pos < src.size() && (src[pos] == ' ' || src[pos] == '\t' || src[pos] == '\n' || src[pos] == '\r')) {
            pos++;
        }
    }

public:
    JsonParser(const std::string& s) : src(s), pos(0) {}

    Value parse() {
        skip_whitespace();
        return parse_value();
    }

private:
    Value parse_value() {
        skip_whitespace();
        if (pos >= src.size()) return Value();
        char c = src[pos];
        if (c == 'n') {
            if (src.compare(pos, 4, "null") == 0) { pos += 4; return Value(); }
        } else if (c == 't') {
            if (src.compare(pos, 4, "true") == 0) { pos += 4; return Value(true); }
        } else if (c == 'f') {
            if (src.compare(pos, 5, "false") == 0) { pos += 5; return Value(false); }
        } else if (c == '"' || (c == '\\' && pos + 1 < src.size() && src[pos + 1] == '"')) {
            return Value(parse_string());
        } else if (c == '[') {
            return parse_array();
        } else if (c == '{') {
            return parse_object();
        } else if (c == '-' || (c >= '0' && c <= '9')) {
            return parse_number();
        }
        return Value();
    }

    std::string parse_string() {
        if (pos + 1 < src.size() && src[pos] == '\\' && src[pos + 1] == '"') pos += 2;
        else if (pos < src.size() && src[pos] == '"') pos++;
        std::string res;
        while (pos < src.size()) {
            if (pos + 1 < src.size() && src[pos] == '\\' && src[pos + 1] == '"') {
                pos += 2;
                break;
            }
            char c = src[pos++];
            if (c == '"') break;
            if (c == '\\' && pos < src.size()) {
                char esc = src[pos++];
                if (esc == 'n') res += '\n';
                else if (esc == 't') res += '\t';
                else if (esc == 'r') res += '\r';
                else if (esc == '"') res += '"';
                else if (esc == '\\') res += '\\';
                else res += esc;
            } else {
                res += c;
            }
        }
        return res;
    }

    Value parse_number() {
        size_t start = pos;
        if (pos < src.size() && src[pos] == '-') pos++;
        bool is_float = false;
        while (pos < src.size() && (std::isdigit(static_cast<unsigned char>(src[pos])) || 
                                    src[pos] == '.' || src[pos] == 'e' || src[pos] == 'E' || 
                                    src[pos] == '+' || src[pos] == '-')) {
            if (src[pos] == '.' || src[pos] == 'e' || src[pos] == 'E') is_float = true;
            pos++;
        }
        std::string num_str = src.substr(start, pos - start);
        try {
            if (is_float) {
                return Value(std::stod(num_str));
            } else {
                return Value(static_cast<int64_t>(std::stoll(num_str)));
            }
        } catch (...) {
            return Value(0.0);
        }
    }

    Value parse_array() {
        if (pos < src.size() && src[pos] == '[') pos++;
        std::vector<Value> list;
        skip_whitespace();
        if (pos < src.size() && src[pos] == ']') {
            pos++;
            return Value(list);
        }
        while (pos < src.size()) {
            list.push_back(parse_value());
            skip_whitespace();
            if (pos < src.size() && src[pos] == ',') {
                pos++;
            } else if (pos < src.size() && src[pos] == ']') {
                pos++;
                break;
            } else {
                break;
            }
        }
        return Value(list);
    }

    Value parse_object() {
        if (pos < src.size() && src[pos] == '{') pos++;
        std::unordered_map<std::string, Value> map_obj;
        skip_whitespace();
        if (pos < src.size() && src[pos] == '}') {
            pos++;
            return Value(map_obj);
        }
        while (pos < src.size()) {
            skip_whitespace();
            if (pos >= src.size() || (src[pos] != '"' && !(src[pos] == '\\' && pos + 1 < src.size() && src[pos + 1] == '"'))) break;
            std::string key = parse_string();
            skip_whitespace();
            if (pos < src.size() && src[pos] == ':') pos++;
            Value val = parse_value();
            map_obj[key] = val;
            skip_whitespace();
            if (pos < src.size() && src[pos] == ',') {
                pos++;
            } else if (pos < src.size() && src[pos] == '}') {
                pos++;
                break;
            } else {
                break;
            }
        }
        return Value(map_obj);
    }
};

class Interpreter {
public:
    std::unordered_map<std::string, Value> variables;
    std::unordered_map<std::string, std::shared_ptr<FunctionDefStmt>> functions;
    std::unordered_map<std::string, std::string> python_snippets;
    std::unordered_map<std::string, DynamicProgram> dynamic_programs;
    std::unordered_set<std::string> imported_modules;
    std::unordered_set<std::string> imported_python_modules;
    std::string app_name = "HoloApp";
    std::string app_version = "2.5.0";
    std::string target_platform = "Shine Loop Console (Holo Looping OoS)";
    std::string ui_profile = "xui";
    std::string theme = "frosted_aqua_a17";
    UIProfileSpecs active_ui_specs = resolve_ui_profile("xui");
    PythonBridge python_bridge;
    DynamicWindow current_window;

    bool has_returned = false;
    bool has_broken = false;
    Value last_return_value;

    void set_target_ui(const std::string& target_name) {
        active_ui_specs = resolve_ui_profile(target_name);
        ui_profile = active_ui_specs.code;
        theme = active_ui_specs.theme;
        variables["UI_PROFILE"] = Value(active_ui_specs.code);
        variables["UI_NAME"] = Value(active_ui_specs.name);
        variables["UI_THEME"] = Value(active_ui_specs.theme);
        variables["UI_FPS"] = Value(static_cast<int64_t>(active_ui_specs.target_fps));
    }

    Value execute_runpy(const std::vector<std::shared_ptr<Expr>>& args) {
        if (args.empty()) {
            std::cerr << color::RED << "[ERROR]" << color::RESET << " runpy expects a snippet name or expression\n";
            return Value();
        }

        std::string snippet_name = "snippet";
        std::string py_code = "";

        if (auto var = std::dynamic_pointer_cast<VariableExpr>(args[0])) {
            snippet_name = var->name;
            auto it = python_snippets.find(var->name);
            if (it != python_snippets.end()) {
                py_code = it->second;
            } else {
                Value v = eval(args[0]);
                if (v.type != ValueType::Nil) {
                    py_code = v.as_string();
                }
            }
        } else {
            Value v = eval(args[0]);
            std::string s = v.as_string();
            auto it = python_snippets.find(s);
            if (it != python_snippets.end()) {
                snippet_name = s;
                py_code = it->second;
            } else {
                py_code = s;
            }
        }

        std::cout << color::CYAN << "[FUNC RUNPY]" << color::RESET << " Executing " << snippet_name << "...\n";

        if (py_code.empty()) {
            std::cerr << color::YELLOW << "[WARNING]" << color::RESET << " Snippet \"" << snippet_name << "\" is empty or undefined.\n";
            return Value();
        }

        std::string out = python_bridge.execute_block(py_code, variables);
        if (!out.empty()) {
            std::cout << out << "\n";
        }

        return Value(out);
    }

    Interpreter() {
        init_builtins();
    }

    void init_builtins() {
        // Builtin Math Constants
        variables["math.pi"] = Value(3.14159265358979323846);
        variables["math.e"] = Value(2.71828182845904523536);
        variables["PI"] = Value(3.14159265358979323846);
        variables["E"] = Value(2.71828182845904523536);

        // Initialize Dynamic Window subsystem
        current_window = DynamicWindow(app_name + " Window", 850, 540, ui_profile);
        current_window.set_theme(theme);
    }

    void print_banner() {
        std::cout << "\n" << color::BOLD << color::PURPLE << "----------------------------------------------------------------------" << color::RESET << "\n";
        std::cout << color::BOLD << color::CYAN << "[LOOPING C++ NATIVE]" << color::RESET << " " 
                  << color::GREEN << "Core High-Performance Engine v2.5.0" << color::RESET << " " 
                  << color::YELLOW << "(POSIX / Win32 Native)" << color::RESET << "\n";
        std::cout << color::BOLD << "Target Platform: " << color::RESET << target_platform 
                  << " | " << color::BOLD << "Kernel: " << color::RESET << "Holo Looping OoS 1.0 (C++ Subsystem)\n";
        std::cout << color::CYAN << "By Holo Entertainment (Coki Studios)" << color::RESET << "\n";
        std::cout << color::BOLD << color::PURPLE << "----------------------------------------------------------------------" << color::RESET << "\n\n";
    }

    // ── Expression Evaluator ──
    Value eval(std::shared_ptr<Expr> expr) {
        if (!expr) return Value();

        // 1. Literal Value
        if (auto lit = std::dynamic_pointer_cast<LiteralExpr>(expr)) {
            return lit->val;
        }

        // 2. Variable Lookup
        if (auto var = std::dynamic_pointer_cast<VariableExpr>(expr)) {
            std::string n = var->name;
            // Check builtin constants
            if (n == "true") return Value(true);
            if (n == "false") return Value(false);
            if (n == "nil" || n == "null" || n == "none") return Value();
            if (n == "math.pi" || n == "PI" || n == "pi") return Value(3.14159265358979323846);
            if (n == "math.e" || n == "E" || n == "e") return Value(2.71828182845904523536);
            if (n == "sys.platform") {
#if defined(__APPLE__)
                return Value("darwin");
#elif defined(_WIN32)
                return Value("windows");
#elif defined(__linux__)
                return Value("linux");
#else
                return Value("unknown");
#endif
            }
            if (n == "sys.arch") {
#if defined(__arm64__) || defined(__aarch64__)
                return Value("arm64");
#elif defined(__x86_64__) || defined(_M_X64)
                return Value("x86_64");
#else
                return Value("unknown");
#endif
            }

            auto it = variables.find(n);
            if (it != variables.end()) {
                return it->second;
            }
            // Check normalized namespace math::pi -> math.pi
            auto col_pos = n.find("::");
            if (col_pos != std::string::npos) {
                std::string alt = n;
                alt.replace(col_pos, 2, ".");
                auto ait = variables.find(alt);
                if (ait != variables.end()) return ait->second;
            }
            // Check map property access via dot: e.g. user.name
            auto dot_pos = n.find('.');
            if (dot_pos != std::string::npos) {
                std::string root_var = n.substr(0, dot_pos);
                std::string sub_key = n.substr(dot_pos + 1);
                auto rit = variables.find(root_var);
                if (rit != variables.end() && rit->second.type == ValueType::Map && rit->second.map_val) {
                    auto mit = rit->second.map_val->find(sub_key);
                    if (mit != rit->second.map_val->end()) {
                        return mit->second;
                    }
                }
            }
            return Value(); // undefined defaults to Nil
        }

        // 2b. List Literal: [1, 2, 3]
        if (auto lst = std::dynamic_pointer_cast<ListExpr>(expr)) {
            std::vector<Value> items;
            items.reserve(lst->elements.size());
            for (const auto& el : lst->elements) {
                items.push_back(eval(el));
            }
            return Value(items);
        }

        // 2c. Map Literal: {"key": val, "k2": v2}
        if (auto mp = std::dynamic_pointer_cast<MapExpr>(expr)) {
            std::unordered_map<std::string, Value> map_data;
            for (const auto& [k, v_expr] : mp->entries) {
                map_data[k] = eval(v_expr);
            }
            return Value(map_data);
        }

        // 2d. Index Expression: target[index]
        if (auto idx = std::dynamic_pointer_cast<IndexExpr>(expr)) {
            Value target_val = eval(idx->target);
            Value index_val = eval(idx->index);
            if (target_val.type == ValueType::List && target_val.list_val) {
                int64_t i = index_val.as_int();
                int64_t sz = static_cast<int64_t>(target_val.list_val->size());
                if (i < 0) i += sz;
                if (i >= 0 && i < sz) {
                    return (*target_val.list_val)[static_cast<size_t>(i)];
                }
                return Value();
            } else if (target_val.type == ValueType::Map && target_val.map_val) {
                std::string k = index_val.as_string();
                auto it = target_val.map_val->find(k);
                if (it != target_val.map_val->end()) {
                    return it->second;
                }
                return Value();
            } else if (target_val.type == ValueType::String) {
                int64_t i = index_val.as_int();
                int64_t sz = static_cast<int64_t>(target_val.str_val.size());
                if (i < 0) i += sz;
                if (i >= 0 && i < sz) {
                    return Value(std::string(1, target_val.str_val[static_cast<size_t>(i)]));
                }
                return Value("");
            }
            return Value();
        }

        // 3. Tuple
        if (auto tup = std::dynamic_pointer_cast<TupleExpr>(expr)) {
            double x = eval(tup->x).as_number();
            double y = eval(tup->y).as_number();
            return Value(x, y);
        }

        // 4. Interpolated String
        if (auto interp = std::dynamic_pointer_cast<InterpolatedStringExpr>(expr)) {
            std::string res = interp->raw_template;
            std::string out = "";
            size_t i = 0;
            while (i < res.size()) {
                if (res[i] == '{') {
                    size_t close = res.find('}', i);
                    if (close != std::string::npos) {
                        std::string inner_expr = res.substr(i + 1, close - i - 1);
                        auto it = variables.find(inner_expr);
                        if (it != variables.end()) {
                            out += it->second.as_string();
                        } else {
                            Parser sub_p("");
                            auto parsed = sub_p.parse_single_expr(inner_expr);
                            if (parsed) {
                                Value v = eval(parsed);
                                out += v.as_string();
                            } else {
                                out += "{" + inner_expr + "}";
                            }
                        }
                        i = close + 1;
                        continue;
                    }
                }
                out += res[i++];
            }
            return Value(out);
        }

        // 5. Python Inline: py: math.sqrt(16) * 1.5
        if (auto py_expr = std::dynamic_pointer_cast<PyInlineExpr>(expr)) {
            return python_bridge.eval_expr(py_expr->py_code, variables);
        }

        // 6. Binary Operators
        if (auto bin = std::dynamic_pointer_cast<BinaryExpr>(expr)) {
            std::string op = bin->op;

            // Pipeline operator: left |> right
            if (op == "|>") {
                Value l = eval(bin->left);
                if (auto var_r = std::dynamic_pointer_cast<VariableExpr>(bin->right)) {
                    std::string fname = var_r->name;
                    if (fname == "print" || fname == "out" || fname == "echo") {
                        std::cout << color::GREEN << "[OUTPUT]" << color::RESET << " " << l.as_string() << "\n";
                        return l;
                    }
                    auto call_e = std::make_shared<CallExpr>(fname, std::vector<std::shared_ptr<Expr>>{std::make_shared<LiteralExpr>(l)});
                    return eval(call_e);
                } else if (auto call_r = std::dynamic_pointer_cast<CallExpr>(bin->right)) {
                    std::vector<std::shared_ptr<Expr>> new_args = { std::make_shared<LiteralExpr>(l) };
                    for (const auto& a : call_r->args) new_args.push_back(a);
                    auto call_e = std::make_shared<CallExpr>(call_r->callee, new_args);
                    return eval(call_e);
                }
                return l;
            }

            // Short-circuit logical operators
            if (op == "and" || op == "&&") {
                Value l = eval(bin->left);
                if (!l.is_truthy()) return Value(false);
                Value r = eval(bin->right);
                return Value(r.is_truthy());
            }
            if (op == "or" || op == "||") {
                Value l = eval(bin->left);
                if (l.is_truthy()) return Value(true);
                Value r = eval(bin->right);
                return Value(r.is_truthy());
            }

            Value left = eval(bin->left);
            Value right = eval(bin->right);

            if (op == "+") return left + right;
            if (op == "-") return left - right;
            if (op == "*") return left * right;
            if (op == "/") return left / right;
            if (op == "%") return left % right;
            if (op == "^") return left.power(right);
            if (op == "==") return Value(left == right);
            if (op == "!=") return Value(left != right);
            if (op == "<") return Value(left < right);
            if (op == "<=") return Value(left <= right);
            if (op == ">") return Value(left > right);
            if (op == ">=") return Value(left >= right);

            return Value();
        }

        // 7. Unary Operators
        if (auto un = std::dynamic_pointer_cast<UnaryExpr>(expr)) {
            Value val = eval(un->operand);
            if (un->op == "-" || un->op == "neg") return Value(0) - val;
            if (un->op == "not" || un->op == "!") return Value(!val.is_truthy());
            return val;
        }

        // 8. Function Calls & Builtins
        if (auto call = std::dynamic_pointer_cast<CallExpr>(expr)) {
            std::string name = call->callee;
            // Normalize :: to .
            auto col_p = name.find("::");
            if (col_p != std::string::npos) name.replace(col_p, 2, ".");

            std::vector<Value> evaluated_args;
            for (const auto& a : call->args) {
                evaluated_args.push_back(eval(a));
            }

            // pyloop runpy
            if (name == "runpy") {
                return execute_runpy(call->args);
            }

            // Builtin Math Functions
            if (name == "math.sqrt" || name == "sqrt") {
                return Value(std::sqrt(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.pow" || name == "pow") {
                double base = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                double exp = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 1.0;
                return Value(std::pow(base, exp));
            }
            if (name == "math.floor" || name == "floor") {
                return Value(std::floor(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.ceil" || name == "ceil") {
                return Value(std::ceil(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.round" || name == "round") {
                double val = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                if (evaluated_args.size() > 1) {
                    double decimals = evaluated_args[1].as_number();
                    double factor = std::pow(10.0, decimals);
                    return Value(std::round(val * factor) / factor);
                }
                return Value(std::round(val));
            }
            if (name == "math.abs" || name == "abs") {
                return Value(std::abs(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.sin" || name == "sin") {
                return Value(std::sin(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.cos" || name == "cos") {
                return Value(std::cos(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.tan" || name == "tan") {
                return Value(std::tan(evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number()));
            }
            if (name == "math.min" || name == "min") {
                double a = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                double b = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0.0;
                return Value(std::min(a, b));
            }
            if (name == "math.max" || name == "max") {
                double a = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                double b = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0.0;
                return Value(std::max(a, b));
            }
            if (name == "random" || name == "math.random") {
                if (evaluated_args.size() >= 2) {
                    int64_t min_v = evaluated_args[0].as_int();
                    int64_t max_v = evaluated_args[1].as_int();
                    if (min_v > max_v) std::swap(min_v, max_v);
                    int64_t r = min_v + (std::rand() % (max_v - min_v + 1));
                    return Value(r);
                }
                return Value(static_cast<double>(std::rand()) / RAND_MAX);
            }

            // Collection & String Length
            if (name == "len" || name == "length") {
                return Value(evaluated_args.empty() ? 0 : evaluated_args[0].size());
            }
            if (name == "upper") {
                std::string s = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                for (char& c : s) c = std::toupper(c);
                return Value(s);
            }
            if (name == "lower") {
                std::string s = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                for (char& c : s) c = std::tolower(c);
                return Value(s);
            }

            // Output Builtin inside expr
            if (name == "out" || name == "print") {
                std::ostringstream ss;
                for (size_t i = 0; i < evaluated_args.size(); ++i) {
                    if (i > 0) ss << " ";
                    ss << evaluated_args[i].as_string();
                }
                std::cout << color::GREEN << "[OUTPUT]" << color::RESET << " " << ss.str() << "\n";
                return evaluated_args.empty() ? Value() : evaluated_args[0];
            }

            // Dynamic Compiler Builtins in Looping expressions
            if (name == "compiler.compile" || name == "compile") {
                std::string source = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                std::string target = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "shine_ui";
                std::string out_p  = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "";
                std::string created_path;
                bool ok = Compiler::compile_source(source, target, out_p, &created_path);
                if (ok) {
                    variables["LAST_COMPILED_APP"] = Value(created_path);
                    return Value(created_path);
                }
                return Value(false);
            }

            if (name == "compiler.create_program" || name == "create_program") {
                std::string p_name   = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "DynamicApp";
                std::string p_target = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "shine_ui";
                std::string p_ver    = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "1.0";
                dynamic_programs[p_name] = Compiler::create_program(p_name, p_target, p_ver);
                std::cout << color::CYAN << "[DYNAMIC COMPILER]" << color::RESET << " Initialized program builder: \"" 
                          << p_name << "\" [Target: " << p_target << "]\n";
                return Value(p_name);
            }

            if (name == "compiler.add_card") {
                if (evaluated_args.size() >= 7) {
                    std::string p_name = evaluated_args[0].as_string();
                    double x = evaluated_args[1].as_number();
                    double y = evaluated_args[2].as_number();
                    double w = evaluated_args[3].as_number();
                    double h = evaluated_args[4].as_number();
                    std::string title = evaluated_args[5].as_string();
                    std::string text  = evaluated_args[6].as_string();
                    if (dynamic_programs.find(p_name) != dynamic_programs.end()) {
                        dynamic_programs[p_name].add_card(x, y, w, h, title, text);
                        return Value(true);
                    }
                }
                return Value(false);
            }

            if (name == "compiler.add_button") {
                if (evaluated_args.size() >= 5) {
                    std::string p_name = evaluated_args[0].as_string();
                    double x = evaluated_args[1].as_number();
                    double y = evaluated_args[2].as_number();
                    std::string text   = evaluated_args[3].as_string();
                    std::string action = evaluated_args[4].as_string();
                    if (dynamic_programs.find(p_name) != dynamic_programs.end()) {
                        dynamic_programs[p_name].add_button(x, y, text, action);
                        return Value(true);
                    }
                }
                return Value(false);
            }

            if (name == "compiler.add_code") {
                if (evaluated_args.size() >= 2) {
                    std::string p_name = evaluated_args[0].as_string();
                    std::string code   = evaluated_args[1].as_string();
                    if (dynamic_programs.find(p_name) != dynamic_programs.end()) {
                        dynamic_programs[p_name].add_code(code);
                        return Value(true);
                    }
                }
                return Value(false);
            }

            if (name == "compiler.build" || name == "compiler.compile_program") {
                if (evaluated_args.size() >= 1) {
                    std::string p_name = evaluated_args[0].as_string();
                    std::string out_p  = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "";
                    if (dynamic_programs.find(p_name) != dynamic_programs.end()) {
                        std::string created_path;
                        bool ok = Compiler::compile_dynamic_program(dynamic_programs[p_name], out_p, &created_path);
                        if (ok) {
                            variables["LAST_COMPILED_APP"] = Value(created_path);
                            return Value(created_path);
                        }
                    }
                }
                return Value(false);
            }

            if (name == "compiler.eval" || name == "eval") {
                if (!evaluated_args.empty()) {
                    std::string code = evaluated_args[0].as_string();
                    execute_code(code);
                    return last_return_value;
                }
                return Value();
            }

            if (name == "compiler.run" || name == "sys.launch" || name == "sys.run" || name == "run") {
                if (!evaluated_args.empty()) {
                    std::string path = evaluated_args[0].as_string();
                    bool ok = Compiler::run_artifact(path);
                    return Value(ok);
                }
                return Value(false);
            }

            if (name == "compiler.targets") {
                return Value("shine_ui, xui, flui");
            }

            // ── Dynamic Window Creator Subsystem Builtins ──
            if (name == "window.create" || name == "window.new") {
                std::string win_title = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Dynamic Window";
                double w = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 850;
                double h = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : 540;
                std::string tgt = evaluated_args.size() > 3 ? evaluated_args[3].as_string() : ui_profile;
                current_window = DynamicWindow(win_title, w, h, tgt);
                current_window.set_theme(theme);
                std::unordered_map<std::string, Value> st;
                st["title"] = Value(win_title);
                st["width"] = Value(w);
                st["height"] = Value(h);
                st["theme"] = Value(current_window.theme);
                st["target"] = Value(current_window.target_ui);
                return Value(st);
            }
            if (name == "window.set_title") {
                if (!evaluated_args.empty()) {
                    current_window.set_title(evaluated_args[0].as_string());
                }
                return Value(current_window.title);
            }
            if (name == "window.set_size") {
                if (evaluated_args.size() >= 2) {
                    current_window.set_size(evaluated_args[0].as_number(), evaluated_args[1].as_number());
                }
                return Value(true);
            }
            if (name == "window.set_theme") {
                if (!evaluated_args.empty()) {
                    std::string th = evaluated_args[0].as_string();
                    current_window.set_theme(th);
                    theme = th;
                }
                return Value(current_window.theme);
            }
            if (name == "window.set_target") {
                if (!evaluated_args.empty()) {
                    std::string tgt = evaluated_args[0].as_string();
                    current_window.set_target(tgt);
                    set_target_ui(tgt);
                }
                return Value(current_window.target_ui);
            }
            if (name == "window.add_card") {
                std::string c_title = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Card";
                std::string c_text = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "";
                double cx = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : -1;
                double cy = evaluated_args.size() > 3 ? evaluated_args[3].as_number() : -1;
                double cw = evaluated_args.size() > 4 ? evaluated_args[4].as_number() : -1;
                double ch = evaluated_args.size() > 5 ? evaluated_args[5].as_number() : -1;
                std::string badge = evaluated_args.size() > 6 ? evaluated_args[6].as_string() : "";
                std::string icon = evaluated_args.size() > 7 ? evaluated_args[7].as_string() : "";
                current_window.add_card(c_title, c_text, cx, cy, cw, ch, badge, icon);
                return Value(static_cast<int64_t>(current_window.cards.size() - 1));
            }
            if (name == "window.add_button") {
                std::string b_text = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Button";
                std::string b_action = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "";
                double bx = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : -1;
                double by = evaluated_args.size() > 3 ? evaluated_args[3].as_number() : -1;
                double bw = evaluated_args.size() > 4 ? evaluated_args[4].as_number() : 150;
                double bh = evaluated_args.size() > 5 ? evaluated_args[5].as_number() : 42;
                current_window.add_button(b_text, b_action, bx, by, bw, bh);
                return Value(static_cast<int64_t>(current_window.buttons.size() - 1));
            }
            if (name == "window.add_input") {
                std::string placeholder = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Texto...";
                std::string binding = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "input_val";
                double ix = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : -1;
                double iy = evaluated_args.size() > 3 ? evaluated_args[3].as_number() : -1;
                double iw = evaluated_args.size() > 4 ? evaluated_args[4].as_number() : 220;
                double ih = evaluated_args.size() > 5 ? evaluated_args[5].as_number() : 40;
                current_window.add_input(placeholder, binding, ix, iy, iw, ih);
                return Value(static_cast<int64_t>(current_window.inputs.size() - 1));
            }
            if (name == "window.play_tone" || name == "window.add_tone") {
                double freq = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 440;
                double dur = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 80;
                current_window.add_tone(freq, dur);
                return Value(true);
            }
            if (name == "window.get_state" || name == "window.info") {
                std::unordered_map<std::string, Value> st;
                st["title"] = Value(current_window.title);
                st["width"] = Value(current_window.width);
                st["height"] = Value(current_window.height);
                st["theme"] = Value(current_window.theme);
                st["target"] = Value(current_window.target_ui);
                st["cards_count"] = Value(static_cast<int64_t>(current_window.cards.size()));
                st["buttons_count"] = Value(static_cast<int64_t>(current_window.buttons.size()));
                st["inputs_count"] = Value(static_cast<int64_t>(current_window.inputs.size()));
                return Value(st);
            }
            if (name == "window.get_cards") {
                std::vector<Value> cs;
                for (const auto& c : current_window.cards) {
                    std::unordered_map<std::string, Value> item;
                    item["title"] = Value(c.title);
                    item["text"] = Value(c.text);
                    item["x"] = Value(c.x);
                    item["y"] = Value(c.y);
                    item["w"] = Value(c.width);
                    item["h"] = Value(c.height);
                    item["badge"] = Value(c.badge);
                    item["icon"] = Value(c.icon);
                    cs.push_back(Value(item));
                }
                return Value(cs);
            }
            if (name == "window.get_buttons") {
                std::vector<Value> bs;
                for (const auto& b : current_window.buttons) {
                    std::unordered_map<std::string, Value> item;
                    item["text"] = Value(b.text);
                    item["action"] = Value(b.action);
                    item["x"] = Value(b.x);
                    item["y"] = Value(b.y);
                    item["w"] = Value(b.width);
                    item["h"] = Value(b.height);
                    bs.push_back(Value(item));
                }
                return Value(bs);
            }
            if (name == "window.clear") {
                current_window.cards.clear();
                current_window.buttons.clear();
                current_window.inputs.clear();
                current_window.tones.clear();
                return Value(true);
            }
            if (name == "window.export_html") {
                std::string path = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                if (path.empty()) path = "build/" + current_window.app_name + ".html";
                bool ok = current_window.save_html(path);
                return Value(ok ? path : "");
            }
            if (name == "window.export_loop") {
                std::string path = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                if (path.empty()) path = "build/" + current_window.app_name + ".loop";
                bool ok = current_window.save_loop(path);
                return Value(ok ? path : "");
            }
            if (name == "window.show" || name == "window.open") {
                bool launch = evaluated_args.size() > 0 ? evaluated_args[0].is_truthy() : true;
                bool ok = current_window.show(launch);
                return Value(ok);
            }
            if (name == "window.ascii" || name == "window.render_ascii") {
                return Value(current_window.render_ascii());
            }
            if (name == "compiler.create_window") {
                std::string w_title = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Dynamic Window";
                double w = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 850;
                double h = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : 540;
                std::string tgt = evaluated_args.size() > 3 ? evaluated_args[3].as_string() : ui_profile;
                current_window = DynamicWindow(w_title, w, h, tgt);
                current_window.set_theme(theme);
                return Value(current_window.app_name);
            }

            // Interactive Console Input
            if (name == "input" || name == "read_line" || name == "prompt") {
                if (!evaluated_args.empty()) {
                    std::cout << evaluated_args[0].as_string();
                    std::cout.flush();
                }
                std::string user_line;
                if (std::getline(std::cin, user_line)) {
                    if (!user_line.empty() && user_line.back() == '\r') user_line.pop_back();
                    return Value(user_line);
                }
                return Value("");
            }

            if (name == "sys.clear" || name == "clear") {
                std::cout << "\033[2J\033[1;1H";
                std::cout.flush();
                return Value(true);
            }

            if (name == "sys.sleep" || name == "sleep") {
                double ms = evaluated_args.empty() ? 100.0 : evaluated_args[0].as_number();
                std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(ms)));
                return Value(true);
            }

            // Extended Math Builtins
            if (name == "math.clamp" || name == "clamp") {
                if (evaluated_args.size() >= 3) {
                    double val = evaluated_args[0].as_number();
                    double min_v = evaluated_args[1].as_number();
                    double max_v = evaluated_args[2].as_number();
                    return Value(std::max(min_v, std::min(val, max_v)));
                }
            }
            if (name == "math.lerp" || name == "lerp") {
                if (evaluated_args.size() >= 3) {
                    double a = evaluated_args[0].as_number();
                    double b = evaluated_args[1].as_number();
                    double t = evaluated_args[2].as_number();
                    return Value(a + (b - a) * t);
                }
            }
            if (name == "math.atan2" || name == "atan2") {
                double y = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                double x = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0.0;
                return Value(std::atan2(y, x));
            }
            if (name == "math.hypot" || name == "hypot") {
                double x = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 0.0;
                double y = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0.0;
                return Value(std::hypot(x, y));
            }
            if (name == "math.log" || name == "log") {
                double x = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 1.0;
                return Value(std::log(x));
            }
            if (name == "math.log10" || name == "log10") {
                double x = evaluated_args.size() > 0 ? evaluated_args[0].as_number() : 1.0;
                return Value(std::log10(x));
            }

            // Collection & String Operations
            if (name == "push" || name == "append") {
                if (evaluated_args.size() >= 2) {
                    evaluated_args[0].push(evaluated_args[1]);
                    return evaluated_args[0];
                }
                return Value();
            }
            if (name == "pop") {
                if (!evaluated_args.empty()) {
                    return evaluated_args[0].pop();
                }
                return Value();
            }
            if (name == "contains" || name == "has") {
                if (evaluated_args.size() >= 2) {
                    return Value(evaluated_args[0].contains(evaluated_args[1]));
                }
                return Value(false);
            }
            if (name == "split") {
                if (!evaluated_args.empty()) {
                    std::string s = evaluated_args[0].as_string();
                    std::string delim = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : " ";
                    std::vector<Value> tokens;
                    if (delim.empty()) {
                        for (char c : s) tokens.push_back(Value(std::string(1, c)));
                    } else {
                        size_t start = 0, end = 0;
                        while ((end = s.find(delim, start)) != std::string::npos) {
                            tokens.push_back(Value(s.substr(start, end - start)));
                            start = end + delim.length();
                        }
                        tokens.push_back(Value(s.substr(start)));
                    }
                    return Value(tokens);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "join") {
                if (!evaluated_args.empty()) {
                    std::string delim = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : ", ";
                    std::ostringstream ss;
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                        for (size_t i = 0; i < evaluated_args[0].list_val->size(); ++i) {
                            if (i > 0) ss << delim;
                            ss << (*evaluated_args[0].list_val)[i].as_string();
                        }
                    }
                    return Value(ss.str());
                }
                return Value("");
            }
            if (name == "trim") {
                if (!evaluated_args.empty()) {
                    std::string s = evaluated_args[0].as_string();
                    size_t first = s.find_first_not_of(" \t\n\r");
                    if (first == std::string::npos) return Value("");
                    size_t last = s.find_last_not_of(" \t\n\r");
                    return Value(s.substr(first, (last - first + 1)));
                }
                return Value("");
            }
            if (name == "replace") {
                if (evaluated_args.size() >= 3) {
                    std::string s = evaluated_args[0].as_string();
                    std::string target = evaluated_args[1].as_string();
                    std::string repl = evaluated_args[2].as_string();
                    if (!target.empty()) {
                        size_t p = 0;
                        while ((p = s.find(target, p)) != std::string::npos) {
                            s.replace(p, target.size(), repl);
                            p += repl.size();
                        }
                    }
                    return Value(s);
                }
                return evaluated_args.empty() ? Value("") : evaluated_args[0];
            }
            if (name == "starts_with") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    std::string prefix = evaluated_args[1].as_string();
                    return Value(s.rfind(prefix, 0) == 0);
                }
                return Value(false);
            }
            if (name == "ends_with") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    std::string suffix = evaluated_args[1].as_string();
                    if (suffix.size() > s.size()) return Value(false);
                    return Value(s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0);
                }
                return Value(false);
            }
            if (name == "slice") {
                if (evaluated_args.size() >= 2) {
                    int64_t start_idx = evaluated_args[1].as_int();
                    int64_t end_idx = evaluated_args.size() > 2 ? evaluated_args[2].as_int() : -1;
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                        int64_t sz = static_cast<int64_t>(evaluated_args[0].list_val->size());
                        if (start_idx < 0) start_idx += sz;
                        if (end_idx < 0) end_idx += sz;
                        if (start_idx < 0) start_idx = 0;
                        if (end_idx > sz) end_idx = sz;
                        std::vector<Value> sub;
                        for (int64_t i = start_idx; i < end_idx && i < sz; ++i) {
                            sub.push_back((*evaluated_args[0].list_val)[static_cast<size_t>(i)]);
                        }
                        return Value(sub);
                    } else if (evaluated_args[0].type == ValueType::String) {
                        std::string s = evaluated_args[0].str_val;
                        int64_t sz = static_cast<int64_t>(s.size());
                        if (start_idx < 0) start_idx += sz;
                        if (end_idx < 0) end_idx += sz;
                        if (start_idx < 0) start_idx = 0;
                        if (end_idx > sz) end_idx = sz;
                        if (end_idx <= start_idx) return Value("");
                        return Value(s.substr(static_cast<size_t>(start_idx), static_cast<size_t>(end_idx - start_idx)));
                    }
                }
                return Value();
            }
            if (name == "range") {
                int64_t r_start = 0;
                int64_t r_end = 0;
                int64_t r_step = 1;
                if (evaluated_args.size() == 1) {
                    r_end = evaluated_args[0].as_int();
                } else if (evaluated_args.size() >= 2) {
                    r_start = evaluated_args[0].as_int();
                    r_end = evaluated_args[1].as_int();
                    if (evaluated_args.size() >= 3) {
                        r_step = evaluated_args[2].as_int();
                        if (r_step == 0) r_step = 1;
                    }
                }
                std::vector<Value> nums;
                if (r_step > 0) {
                    for (int64_t v = r_start; v < r_end; v += r_step) nums.push_back(Value(v));
                } else {
                    for (int64_t v = r_start; v > r_end; v += r_step) nums.push_back(Value(v));
                }
                return Value(nums);
            }
            if (name == "reverse") {
                if (!evaluated_args.empty()) {
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                        auto rev = *evaluated_args[0].list_val;
                        std::reverse(rev.begin(), rev.end());
                        return Value(rev);
                    } else if (evaluated_args[0].type == ValueType::String) {
                        std::string rev = evaluated_args[0].str_val;
                        std::reverse(rev.begin(), rev.end());
                        return Value(rev);
                    }
                }
                return evaluated_args.empty() ? Value() : evaluated_args[0];
            }
            if (name == "sort") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    auto sorted = *evaluated_args[0].list_val;
                    std::sort(sorted.begin(), sorted.end());
                    return Value(sorted);
                }
                return evaluated_args.empty() ? Value() : evaluated_args[0];
            }
            if (name == "keys") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::Map && evaluated_args[0].map_val) {
                    std::vector<Value> ks;
                    for (const auto& [k, v] : *evaluated_args[0].map_val) ks.push_back(Value(k));
                    return Value(ks);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "values") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::Map && evaluated_args[0].map_val) {
                    std::vector<Value> vs;
                    for (const auto& [k, v] : *evaluated_args[0].map_val) vs.push_back(v);
                    return Value(vs);
                }
                return Value(std::vector<Value>{});
            }

            // File I/O Builtins
            if (name == "file.read") {
                if (!evaluated_args.empty()) {
                    std::string fpath = evaluated_args[0].as_string();
                    std::ifstream f(fpath);
                    if (f.is_open()) {
                        std::stringstream ss;
                        ss << f.rdbuf();
                        return Value(ss.str());
                    }
                }
                return Value("");
            }
            if (name == "file.write") {
                if (evaluated_args.size() >= 2) {
                    std::string fpath = evaluated_args[0].as_string();
                    std::string content = evaluated_args[1].as_string();
                    std::ofstream f(fpath);
                    if (f.is_open()) {
                        f << content;
                        return Value(true);
                    }
                }
                return Value(false);
            }
            if (name == "file.append") {
                if (evaluated_args.size() >= 2) {
                    std::string fpath = evaluated_args[0].as_string();
                    std::string content = evaluated_args[1].as_string();
                    std::ofstream f(fpath, std::ios::app);
                    if (f.is_open()) {
                        f << content;
                        return Value(true);
                    }
                }
                return Value(false);
            }
            if (name == "file.exists") {
                if (!evaluated_args.empty()) {
                    std::string fpath = evaluated_args[0].as_string();
                    std::ifstream f(fpath);
                    return Value(f.good());
                }
                return Value(false);
            }
            if (name == "file.size") {
                if (!evaluated_args.empty()) {
                    std::string fpath = evaluated_args[0].as_string();
                    std::ifstream f(fpath, std::ios::ate | std::ios::binary);
                    if (f.is_open()) {
                        return Value(static_cast<int64_t>(f.tellg()));
                    }
                }
                return Value(static_cast<int64_t>(-1));
            }
            if (name == "file.remove" || name == "file.delete") {
                if (!evaluated_args.empty()) {
                    std::string fpath = evaluated_args[0].as_string();
                    int res = std::remove(fpath.c_str());
                    return Value(res == 0);
                }
                return Value(false);
            }

            // JSON Builtins
            if (name == "json.parse") {
                if (!evaluated_args.empty()) {
                    JsonParser jp(evaluated_args[0].as_string());
                    return jp.parse();
                }
                return Value();
            }
            if (name == "json.stringify") {
                if (!evaluated_args.empty()) {
                    return Value(evaluated_args[0].to_json());
                }
                return Value("null");
            }

            // System Builtins
            if (name == "sys.env" || name == "sys.getenv") {
                if (!evaluated_args.empty()) {
                    const char* env_val = std::getenv(evaluated_args[0].as_string().c_str());
                    return Value(env_val ? env_val : "");
                }
                return Value("");
            }
            if (name == "sys.platform") {
#if defined(__APPLE__)
                return Value("darwin");
#elif defined(_WIN32)
                return Value("windows");
#elif defined(__linux__)
                return Value("linux");
#else
                return Value("unknown");
#endif
            }
            if (name == "sys.arch") {
#if defined(__arm64__) || defined(__aarch64__)
                return Value("arm64");
#elif defined(__x86_64__) || defined(_M_X64)
                return Value("x86_64");
#else
                return Value("unknown");
#endif
            }
            if (name == "sys.exec") {
                if (!evaluated_args.empty()) {
                    std::string cmd = evaluated_args[0].as_string();
                    FILE* pipe = popen(cmd.c_str(), "r");
                    if (!pipe) return Value("");
                    char buffer[256];
                    std::string result = "";
                    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
                        result += buffer;
                    }
                    pclose(pipe);
                    return Value(result);
                }
                return Value("");
            }
            if (name == "time.now" || name == "timestamp" || name == "sys.time") {
                auto now = std::chrono::system_clock::now();
                auto sec = std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch()).count();
                return Value(static_cast<int64_t>(sec));
            }
            if (name == "time.millis") {
                auto now = std::chrono::system_clock::now();
                auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
                return Value(static_cast<int64_t>(ms));
            }

            // User Defined Function Call with return value
            auto fn_it = functions.find(name);
            if (fn_it != functions.end()) {
                auto fn = fn_it->second;
                std::unordered_map<std::string, Value> saved_vars;
                for (const auto& p : fn->params) {
                    if (variables.find(p) != variables.end()) saved_vars[p] = variables[p];
                }
                for (size_t i = 0; i < fn->params.size() && i < evaluated_args.size(); ++i) {
                    variables[fn->params[i]] = evaluated_args[i];
                }
                has_returned = false;
                last_return_value = Value();
                for (auto& s : fn->body) {
                    execute_statement(s);
                    if (has_returned) break;
                }
                Value ret = last_return_value;
                has_returned = false;
                for (const auto& [k, v] : saved_vars) variables[k] = v;
                return ret;
            }

            // Fallback: If python module function, evaluate via Python Bridge
            if (name.find('.') != std::string::npos && python_bridge.is_available) {
                std::string py_call = name + "(";
                for (size_t i = 0; i < evaluated_args.size(); ++i) {
                    if (i > 0) py_call += ", ";
                    py_call += evaluated_args[i].to_json();
                }
                py_call += ")";
                return python_bridge.eval_expr(py_call, variables);
            }

            return Value();
        }

        return Value();
    }

    // ── Statement Executor ──
    void execute_statement(std::shared_ptr<Stmt> stmt) {
        if (!stmt || has_returned || has_broken) return;

        // 0. Break
        if (std::dynamic_pointer_cast<BreakStmt>(stmt)) {
            has_broken = true;
            return;
        }

        // 1. Return
        if (auto ret = std::dynamic_pointer_cast<ReturnStmt>(stmt)) {
            if (ret->value_expr) last_return_value = eval(ret->value_expr);
            else last_return_value = Value();
            has_returned = true;
            return;
        }

        // Expression Statement (e.g. pipelines, function invocations)
        if (auto es = std::dynamic_pointer_cast<ExprStmt>(stmt)) {
            eval(es->expr);
            return;
        }

        // 2. Print / Echo / Out
        if (auto pr = std::dynamic_pointer_cast<PrintStmt>(stmt)) {
            std::ostringstream ss;
            for (size_t i = 0; i < pr->expressions.size(); ++i) {
                if (i > 0) ss << " ";
                Value v = eval(pr->expressions[i]);
                ss << v.as_string();
            }
            std::cout << color::GREEN << "[OUTPUT]" << color::RESET << " " << ss.str() << "\n";
            return;
        }

        // 3. Variable Assignment: let x = 10, mut x = 10, x := 10, x += 5, user.name = "Alice"
        if (auto st = std::dynamic_pointer_cast<SetStmt>(stmt)) {
            Value val = eval(st->value_expr);
            auto dot_pos = st->var_name.find('.');
            if (dot_pos != std::string::npos) {
                std::string root_var = st->var_name.substr(0, dot_pos);
                std::string sub_key = st->var_name.substr(dot_pos + 1);
                auto rit = variables.find(root_var);
                if (rit != variables.end() && rit->second.type == ValueType::Map) {
                    if (!rit->second.map_val) rit->second.map_val = std::make_shared<std::unordered_map<std::string, Value>>();
                    if (st->op == "=") (*rit->second.map_val)[sub_key] = val;
                    else if (st->op == "+=") (*rit->second.map_val)[sub_key] = (*rit->second.map_val)[sub_key] + val;
                    else if (st->op == "-=") (*rit->second.map_val)[sub_key] = (*rit->second.map_val)[sub_key] - val;
                    else if (st->op == "*=") (*rit->second.map_val)[sub_key] = (*rit->second.map_val)[sub_key] * val;
                    else if (st->op == "/=") (*rit->second.map_val)[sub_key] = (*rit->second.map_val)[sub_key] / val;
                    return;
                }
            }
            if (st->op == "=") {
                variables[st->var_name] = val;
            } else if (st->op == "+=") {
                variables[st->var_name] = variables[st->var_name] + val;
            } else if (st->op == "-=") {
                variables[st->var_name] = variables[st->var_name] - val;
            } else if (st->op == "*=") {
                variables[st->var_name] = variables[st->var_name] * val;
            } else if (st->op == "/=") {
                variables[st->var_name] = variables[st->var_name] / val;
            }
            return;
        }

        // 3b. Indexed Assignment: arr[idx] = val, map["key"] = val
        if (auto si = std::dynamic_pointer_cast<SetIndexStmt>(stmt)) {
            auto it = variables.find(si->var_name);
            if (it != variables.end()) {
                Value idx = eval(si->index_expr);
                Value val = eval(si->value_expr);
                if (it->second.type == ValueType::List && it->second.list_val) {
                    int64_t i = idx.as_int();
                    int64_t sz = static_cast<int64_t>(it->second.list_val->size());
                    if (i < 0) i += sz;
                    if (i >= 0 && i < sz) {
                        if (si->op == "=") (*it->second.list_val)[static_cast<size_t>(i)] = val;
                        else if (si->op == "+=") (*it->second.list_val)[static_cast<size_t>(i)] = (*it->second.list_val)[static_cast<size_t>(i)] + val;
                        else if (si->op == "-=") (*it->second.list_val)[static_cast<size_t>(i)] = (*it->second.list_val)[static_cast<size_t>(i)] - val;
                        else if (si->op == "*=") (*it->second.list_val)[static_cast<size_t>(i)] = (*it->second.list_val)[static_cast<size_t>(i)] * val;
                        else if (si->op == "/=") (*it->second.list_val)[static_cast<size_t>(i)] = (*it->second.list_val)[static_cast<size_t>(i)] / val;
                    } else if (i == sz && si->op == "=") {
                        it->second.list_val->push_back(val);
                    }
                } else if (it->second.type == ValueType::Map) {
                    if (!it->second.map_val) it->second.map_val = std::make_shared<std::unordered_map<std::string, Value>>();
                    std::string k = idx.as_string();
                    if (si->op == "=") (*it->second.map_val)[k] = val;
                    else if (si->op == "+=") (*it->second.map_val)[k] = (*it->second.map_val)[k] + val;
                    else if (si->op == "-=") (*it->second.map_val)[k] = (*it->second.map_val)[k] - val;
                    else if (si->op == "*=") (*it->second.map_val)[k] = (*it->second.map_val)[k] * val;
                    else if (si->op == "/=") (*it->second.map_val)[k] = (*it->second.map_val)[k] / val;
                }
            }
            return;
        }

        // 4. Conditional: if (cond) { ... } else { ... } OR if cond -> stmt
        if (auto if_st = std::dynamic_pointer_cast<IfStmt>(stmt)) {
            Value cond_val = eval(if_st->condition);
            if (cond_val.is_truthy()) {
                for (auto& s : if_st->then_branch) {
                    execute_statement(s);
                    if (has_returned || has_broken) break;
                }
            } else {
                for (auto& s : if_st->else_branch) {
                    execute_statement(s);
                    if (has_returned || has_broken) break;
                }
            }
            return;
        }

        // 5. For Range Loop: for (i in start..end) { ... }
        if (auto for_r = std::dynamic_pointer_cast<ForRangeStmt>(stmt)) {
            int64_t start_v = eval(for_r->start_expr).as_int();
            int64_t end_v = eval(for_r->end_expr).as_int();
            for (int64_t i = start_v; i < end_v; ++i) {
                variables[for_r->var_name] = Value(i);
                for (auto& s : for_r->body) {
                    execute_statement(s);
                    if (has_broken || has_returned) break;
                }
                if (has_broken) { has_broken = false; break; }
                if (has_returned) break;
            }
            return;
        }

        // 5b. For-Each Loop: for (item in list) { ... }
        if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(stmt)) {
            Value coll = eval(fe->collection_expr);
            if (coll.type == ValueType::List && coll.list_val) {
                auto items = *(coll.list_val);
                for (const auto& item : items) {
                    variables[fe->var_name] = item;
                    for (auto& s : fe->body) {
                        execute_statement(s);
                        if (has_broken || has_returned) break;
                    }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned) break;
                }
            } else if (coll.type == ValueType::Map && coll.map_val) {
                auto map_copy = *(coll.map_val);
                for (const auto& [k, v] : map_copy) {
                    variables[fe->var_name] = Value(k);
                    for (auto& s : fe->body) {
                        execute_statement(s);
                        if (has_broken || has_returned) break;
                    }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned) break;
                }
            } else if (coll.type == ValueType::String) {
                std::string s_copy = coll.str_val;
                for (char ch : s_copy) {
                    variables[fe->var_name] = Value(std::string(1, ch));
                    for (auto& s : fe->body) {
                        execute_statement(s);
                        if (has_broken || has_returned) break;
                    }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned) break;
                }
            }
            return;
        }

        // 6. While Loop: while (cond) { ... }
        if (auto wh = std::dynamic_pointer_cast<WhileStmt>(stmt)) {
            size_t max_iterations = 1000000;
            size_t iter = 0;
            while (eval(wh->condition).is_truthy() && iter++ < max_iterations) {
                for (auto& s : wh->body) {
                    execute_statement(s);
                    if (has_broken || has_returned) break;
                }
                if (has_broken) { has_broken = false; break; }
                if (has_returned) break;
            }
            return;
        }

        // 7. Repeat / Loop Count: loop (N) { ... } OR repeat N times { ... }
        if (auto rep = std::dynamic_pointer_cast<RepeatStmt>(stmt)) {
            int64_t count = eval(rep->count_expr).as_int();
            for (int64_t i = 0; i < count; ++i) {
                variables["i"] = Value(i);
                variables["loop_index"] = Value(i);
                for (auto& s : rep->body) {
                    execute_statement(s);
                    if (has_broken || has_returned) break;
                }
                if (has_broken) { has_broken = false; break; }
                if (has_returned) break;
            }
            return;
        }

        // 8. Function Definition
        if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(stmt)) {
            functions[fn->name] = fn;
            std::cout << color::BLUE << "[FUNCTION]" << color::RESET << " Registered fn \"" << fn->name 
                      << "\" (" << fn->params.size() << " args)\n";
            return;
        }

        // 9. Function Call Statement: name(...) OR call name(...)
        if (auto call = std::dynamic_pointer_cast<CallStmt>(stmt)) {
            auto call_e = std::make_shared<CallExpr>(call->name, call->args);
            eval(call_e);
            return;
        }

        // 10. Python Multiline Block
        if (auto py_b = std::dynamic_pointer_cast<PythonBlockStmt>(stmt)) {
            std::cout << color::PURPLE << "[PYTHON EXEC]" << color::RESET << " Running Python block...\n";
            std::string out = python_bridge.execute_block(py_b->py_code, variables);
            if (!out.empty()) {
                std::cout << color::PURPLE << "[PYTHON OUTPUT]" << color::RESET << "\n" << out << "\n";
            }
            return;
        }

        // 10b. Python Snippet Definition: insert pysnippet as <name>: ...
        if (auto sn = std::dynamic_pointer_cast<PySnippetDefStmt>(stmt)) {
            python_snippets[sn->snippet_name] = sn->py_code;
            variables[sn->snippet_name] = Value(sn->py_code);
            return;
        }

        // 11. Import
        if (auto imp = std::dynamic_pointer_cast<ImportStmt>(stmt)) {
            if (imp->module_name == "pyloop") {
                imported_modules.insert("pyloop");
                imported_python_modules.insert("pyloop");
                return;
            }
            if (imp->is_python) {
                imported_python_modules.insert(imp->module_name);
                std::cout << color::GREEN << "[PYTHON BRIDGE]" << color::RESET << " Linked Python Module: " 
                          << color::BOLD << imp->module_name << color::RESET << "\n";
            } else {
                imported_modules.insert(imp->module_name);
                std::cout << color::BLUE << "[MODULE]" << color::RESET << " Loaded " << imp->module_name << "\n";
            }
            return;
        }

        // 12. App Definition
        if (auto app = std::dynamic_pointer_cast<AppDefineStmt>(stmt)) {
            app_name = app->app_name;
            app_version = app->version;
            std::cout << color::GREEN << "[APP]" << color::RESET << " Registered \"" << app_name 
                      << "\" v" << app_version << " on " << target_platform << "\n";
            return;
        }

        // 13. Window Canvas
        if (auto win = std::dynamic_pointer_cast<WindowStmt>(stmt)) {
            current_window.set_title(win->title);
            current_window.set_size(win->width, win->height);
            std::cout << color::PURPLE << "[DISPLAY]" << color::RESET << " \"" << win->title 
                      << "\" (" << static_cast<int>(win->width) << "x" << static_cast<int>(win->height) << ")\n";
            return;
        }

        // 14. Target UI Compilation: compile target "shine_ui" / target("xui") / profile("flui")
        if (auto tgt = std::dynamic_pointer_cast<TargetCompileStmt>(stmt)) {
            set_target_ui(tgt->target_ui);
            current_window.set_target(tgt->target_ui);
            std::cout << color::CYAN << "[UI COMPILER]" << color::RESET << " Target UI Profile: "
                      << color::BOLD << color::GREEN << active_ui_specs.name << color::RESET
                      << " [" << active_ui_specs.pipeline << "]\n";
            std::cout << color::BLUE << "[UI SHADER]" << color::RESET << " Theme: "
                      << active_ui_specs.theme << " | Primary: " << active_ui_specs.primary_color
                      << " | Layout: " << active_ui_specs.layout_mode << "\n";
            return;
        }

        // 14b. Theme & Config
        if (auto cfg = std::dynamic_pointer_cast<ConfigStmt>(stmt)) {
            if (cfg->key == "theme") {
                theme = cfg->value;
                current_window.set_theme(cfg->value);
            } else if (cfg->key == "ui_profile" || cfg->key == "target") {
                set_target_ui(cfg->value);
                current_window.set_target(cfg->value);
                std::cout << color::CYAN << "[CS DESIGN UI]" << color::RESET << " UI Profile Active: " 
                          << color::BOLD << active_ui_specs.name << color::RESET << " (" << active_ui_specs.pipeline << ")\n";
            }
            return;
        }

        // 15. Draw UI: Card / Button / Input
        if (auto draw = std::dynamic_pointer_cast<DrawUIStmt>(stmt)) {
            if (draw->ui_type == "card") {
                current_window.add_card(draw->title.empty() ? "Card" : draw->title, draw->text, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "button") {
                current_window.add_button(draw->text.empty() ? "Button" : draw->text, draw->action, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "input") {
                current_window.add_input(draw->placeholder, draw->var_name, draw->x, draw->y, draw->w, draw->h);
            }
            std::string label = draw->ui_type;
            label[0] = std::toupper(label[0]);
            std::cout << color::YELLOW << "[UI]" << color::RESET << " Rendered UI " << label << " Component";
            if (!draw->title.empty()) std::cout << " [\"" << draw->title << "\"]";
            else if (!draw->text.empty()) std::cout << " [\"" << draw->text << "\"]";
            std::cout << "\n";
            return;
        }

        // 16. Spawn Entity: Sprite / Platform / Coin / Bubbly Dot
        if (auto sp = std::dynamic_pointer_cast<SpawnEntityStmt>(stmt)) {
            if (sp->entity_type == "bubbly_dot") {
                std::cout << color::GREEN << "[BUBBLY DOT]" << color::RESET << " Active Notch [" 
                          << (sp->state.empty() ? "MUSIC" : sp->state) << "]: \"" 
                          << (sp->text.empty() ? "Audio Active" : sp->text) << "\"\n";
            } else if (sp->entity_type == "sprite") {
                std::cout << color::PURPLE << "[ENTITY]" << color::RESET << " Spawned \"" << sp->name 
                          << "\" (Physics 60Hz Low-Latency)\n";
            } else if (sp->entity_type == "spike" || sp->entity_type == "hazard") {
                std::cout << color::RED << "[HAZARD]" << color::RESET << " Armed Spike at (" 
                          << sp->x << ", " << sp->y << ")\n";
            } else if (sp->entity_type == "jump_pad" || sp->entity_type == "pad") {
                std::cout << color::YELLOW << "[BOOST]" << color::RESET << " Placed Jump Pad at (" 
                          << sp->x << ", " << sp->y << ")\n";
            } else if (sp->entity_type == "orb") {
                std::cout << color::PURPLE << "[ORB]" << color::RESET << " Placed Jump Ring at (" 
                          << sp->x << ", " << sp->y << ")\n";
            } else {
                std::cout << color::CYAN << "[WORLD]" << color::RESET << " Placed " << sp->entity_type 
                          << " Stage Component\n";
            }
            return;
        }

        // 17. Emit Particles
        if (auto em = std::dynamic_pointer_cast<EmitParticlesStmt>(stmt)) {
            std::cout << color::CYAN << "[PARTICLES]" << color::RESET << " Emitted FX burst at (" 
                      << em->x << ", " << em->y << ") [" << em->color << "]\n";
            return;
        }

        // 18. Audio Tone
        if (auto tone = std::dynamic_pointer_cast<PlayToneStmt>(stmt)) {
            current_window.add_tone(tone->freq_hz, tone->duration_ms);
            std::cout << color::GREEN << "[AUDIO SYNTH]" << color::RESET << " Tone " 
                      << static_cast<int>(tone->freq_hz) << " Hz for " 
                      << static_cast<int>(tone->duration_ms) << " ms\n";
            return;
        }

        // 19. Syscall
        if (auto sc = std::dynamic_pointer_cast<SyscallStmt>(stmt)) {
            std::cout << color::CYAN << "[KERNEL SYSCALL]" << color::RESET << " 0x" 
                      << sc->call_name << " (" << sc->args << ")\n";
            return;
        }

        // 20. Process
        if (auto proc = std::dynamic_pointer_cast<SpawnProcessStmt>(stmt)) {
            std::cout << color::PURPLE << "[PROCESS]" << color::RESET << " Spawned daemon process: " 
                      << proc->process_name << " (priority: " << proc->priority << ")\n";
            return;
        }

        // 21. Dynamic Program Compilation Block: compile program "..." target "..." to "...":
        if (auto dyn = std::dynamic_pointer_cast<DynamicProgramCompileStmt>(stmt)) {
            std::cout << color::CYAN << "[DYNAMIC COMPILER]" << color::RESET << " Synthesizing dynamic program: \"" 
                      << color::BOLD << dyn->program_name << color::RESET << "\" (Target: " << dyn->target_ui << ")\n";

            DynamicProgram prog(dyn->program_name, dyn->target_ui, dyn->version);

            // Parse inner directives and statements
            bool in_code_section = false;
            for (const auto& raw_line : dyn->raw_lines) {
                std::string trimmed = raw_line;
                while (!trimmed.empty() && (trimmed.front() == ' ' || trimmed.front() == '\t')) trimmed.erase(0, 1);
                if (trimmed.empty() || trimmed.front() == '#') continue;

                if (trimmed == "code:" || trimmed == "code {") {
                    in_code_section = true;
                    continue;
                }

                if (in_code_section) {
                    if (trimmed == "}" || trimmed == "end") {
                        in_code_section = false;
                    } else {
                        prog.add_code(raw_line);
                    }
                    continue;
                }

                if (trimmed.rfind("title ", 0) == 0) {
                    std::regex tr(R"(title\s+["'](.*?)["'])");
                    std::smatch m;
                    if (std::regex_search(trimmed, m, tr)) {
                        prog.window_title = m[1];
                    }
                } else if (trimmed.rfind("size ", 0) == 0) {
                    std::regex sr(R"(size\s*\((\d+),\s*(\d+)\))");
                    std::smatch m;
                    if (std::regex_search(trimmed, m, sr)) {
                        prog.window_width = std::stod(m[1]);
                        prog.window_height = std::stod(m[2]);
                    }
                } else if (trimmed.rfind("theme ", 0) == 0) {
                    std::regex thr(R"(theme\s+["'](.*?)["'])");
                    std::smatch m;
                    if (std::regex_search(trimmed, m, thr)) {
                        prog.set_theme(m[1]);
                    }
                } else if (trimmed.rfind("draw card", 0) == 0 || trimmed.rfind("card ", 0) == 0) {
                    double cx = 20, cy = 20, cw = 760, ch = 100;
                    std::string c_title = "Card", c_text = "";
                    std::regex ar(R"(at\s*\((\d+),\s*(\d+)\))");
                    std::regex sr(R"(size\s*\((\d+),\s*(\d+)\))");
                    std::regex tr(R"(title\s*["'](.*?)["'])");
                    std::regex txtr(R"(text\s*["'](.*?)["'])");
                    std::smatch m;
                    if (std::regex_search(trimmed, m, ar)) { cx = std::stod(m[1]); cy = std::stod(m[2]); }
                    if (std::regex_search(trimmed, m, sr)) { cw = std::stod(m[1]); ch = std::stod(m[2]); }
                    if (std::regex_search(trimmed, m, tr)) { c_title = m[1]; }
                    if (std::regex_search(trimmed, m, txtr)) { c_text = m[1]; }
                    prog.add_card(cx, cy, cw, ch, c_title, c_text);
                } else if (trimmed.rfind("draw button", 0) == 0 || trimmed.rfind("button ", 0) == 0) {
                    double bx = 20, by = 20;
                    std::string b_text = "Button", b_act = "";
                    std::regex ar(R"(at\s*\((\d+),\s*(\d+)\))");
                    std::regex tr(R"(text\s*["'](.*?)["'])");
                    std::regex actr(R"(action\s*["'](.*?)["'])");
                    std::smatch m;
                    if (std::regex_search(trimmed, m, ar)) { bx = std::stod(m[1]); by = std::stod(m[2]); }
                    if (std::regex_search(trimmed, m, tr)) { b_text = m[1]; }
                    if (std::regex_search(trimmed, m, actr)) { b_act = m[1]; }
                    prog.add_button(bx, by, b_text, b_act);
                } else {
                    prog.add_code(raw_line);
                }
            }

            dynamic_programs[dyn->program_name] = prog;

            std::string created_path;
            bool ok = Compiler::compile_dynamic_program(prog, dyn->output_path, &created_path);
            if (ok) {
                variables["LAST_COMPILED_APP"] = Value(created_path);
                variables[dyn->program_name] = Value(created_path);
                if (dyn->and_run) {
                    std::cout << color::CYAN << "[DYNAMIC RUN]" << color::RESET << " Launching dynamic program artifact...\n";
                    Compiler::run_artifact(created_path);
                }
            }
            return;
        }
    }

    // ── Execute Multiple Statements ──
    void execute_code(const std::string& code) {
        has_returned = false;
        has_broken = false;
        Parser parser(code);
        auto statements = parser.parse_script();
        for (auto& s : statements) {
            execute_statement(s);
        }
    }

    // ── Execute File ──
    bool execute_file(const std::string& path) {
        std::ifstream file(path);
        if (!file.is_open()) {
            std::cerr << color::RED << "❌ Error: Cannot open file: " << path << color::RESET << "\n";
            return false;
        }

        print_banner();
        std::cout << color::CYAN << "[EXEC]" << color::RESET << " Loading source: " 
                  << color::BOLD << path << color::RESET << "\n";

        if (python_bridge.is_available) {
            std::cout << color::GREEN << "[PYTHON INTEROP]" << color::RESET << " Attached Python runtime: " 
                  << color::CYAN << python_bridge.get_command_str() << color::RESET << "\n";
        } else {
            std::cout << color::YELLOW << "[PYTHON INTEROP]" << color::RESET << " Standalone Mode (Python not detected in PATH)\n";
        }
        std::cout << "\n";

        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();

        auto start = std::chrono::high_resolution_clock::now();
        execute_code(content);
        auto end = std::chrono::high_resolution_clock::now();

        double elapsed = std::chrono::duration<double, std::milli>(end - start).count();
        std::cout << "\n" << color::GREEN << "[OK] Execution completed in " 
                  << std::fixed << std::setprecision(2) << elapsed << "ms!" << color::RESET << "\n";

        return true;
    }

    // ── Compile Script for Target UI (Shine UI / XUI / flUI) ──
    bool compile_script_to_target(const std::string& input_path, const std::string& target_name, const std::string& output_path) {
        return Compiler::compile_file(input_path, target_name, output_path);
    }
};

} // namespace looping
