#pragma once

#include "LoopingValue.hpp"
#include "LoopingAST.hpp"
#include "LoopingParser.hpp"
#include "LoopingPythonBridge.hpp"
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

namespace looping {

namespace color {
    inline const char* RESET   = "\033[0m";
    inline const char* BOLD    = "\033[1m";
    inline const char* CYAN    = "\033[36m";
    inline const char* GREEN   = "\033[32m";
    inline const char* YELLOW  = "\033[33m";
    inline const char* PURPLE  = "\033[35m";
    inline const char* RED     = "\033[31m";
    inline const char* BLUE    = "\033[34m";
    inline const char* WHITE   = "\033[37m";
}

class Interpreter {
public:
    std::unordered_map<std::string, Value> variables;
    std::unordered_map<std::string, std::shared_ptr<FunctionDefStmt>> functions;
    std::unordered_set<std::string> imported_modules;
    std::unordered_set<std::string> imported_python_modules;
    std::string app_name = "HoloApp";
    std::string app_version = "2.5.0";
    std::string target_platform = "Shine Loop Console (Holo Looping OoS)";
    std::string ui_profile = "stock";
    std::string theme = "frosted_aqua_a17";
    PythonBridge python_bridge;

    bool has_returned = false;
    bool has_broken = false;
    Value last_return_value;

    Interpreter() {
        init_builtins();
    }

    void init_builtins() {
        // Builtin Math Constants
        variables["math.pi"] = Value(3.14159265358979323846);
        variables["math.e"] = Value(2.71828182845904523536);
        variables["PI"] = Value(3.14159265358979323846);
        variables["E"] = Value(2.71828182845904523536);
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
            return Value(); // undefined defaults to Nil
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
            for (const auto& [k, v] : variables) {
                std::string pattern = "{" + k + "}";
                size_t p = 0;
                while ((p = res.find(pattern, p)) != std::string::npos) {
                    std::string repl = v.as_string();
                    res.replace(p, pattern.size(), repl);
                    p += repl.size();
                }
            }
            return Value(res);
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

            // String Builtins
            if (name == "len" || name == "length") {
                return Value(static_cast<int64_t>(evaluated_args.empty() ? 0 : evaluated_args[0].as_string().size()));
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

        // 3. Variable Assignment: let x = 10, mut x = 10, x := 10, x += 5
        if (auto st = std::dynamic_pointer_cast<SetStmt>(stmt)) {
            Value val = eval(st->value_expr);
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
            auto it = functions.find(call->name);
            if (it != functions.end()) {
                auto fn = it->second;
                std::unordered_map<std::string, Value> saved_vars;
                for (const auto& p : fn->params) {
                    if (variables.find(p) != variables.end()) saved_vars[p] = variables[p];
                }
                for (size_t i = 0; i < fn->params.size() && i < call->args.size(); ++i) {
                    variables[fn->params[i]] = eval(call->args[i]);
                }
                has_returned = false;
                for (auto& s : fn->body) {
                    execute_statement(s);
                    if (has_returned) break;
                }
                has_returned = false;
                for (const auto& [k, v] : saved_vars) variables[k] = v;
            } else {
                if (call->name == "out" || call->name == "print" || call->name == "echo") {
                    std::ostringstream ss;
                    for (size_t i = 0; i < call->args.size(); ++i) {
                        if (i > 0) ss << " ";
                        ss << eval(call->args[i]).as_string();
                    }
                    std::cout << color::GREEN << "[OUTPUT]" << color::RESET << " " << ss.str() << "\n";
                } else {
                    std::cout << color::YELLOW << "[FUNCTION CALL]" << color::RESET << " Invoked \"" << call->name << "\"\n";
                }
            }
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

        // 11. Import
        if (auto imp = std::dynamic_pointer_cast<ImportStmt>(stmt)) {
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
            std::cout << color::PURPLE << "[DISPLAY]" << color::RESET << " \"" << win->title 
                      << "\" (" << static_cast<int>(win->width) << "x" << static_cast<int>(win->height) << ")\n";
            return;
        }

        // 14. Theme & Config
        if (auto cfg = std::dynamic_pointer_cast<ConfigStmt>(stmt)) {
            if (cfg->key == "theme") {
                theme = cfg->value;
            } else if (cfg->key == "ui_profile") {
                ui_profile = cfg->value;
                std::cout << color::CYAN << "[CS DESIGN UI]" << color::RESET << " UI Profile Active: " 
                          << color::BOLD << ui_profile << color::RESET << " (Hardware Spec Loaded)\n";
            }
            return;
        }

        // 15. Draw UI: Card / Button / Input
        if (auto draw = std::dynamic_pointer_cast<DrawUIStmt>(stmt)) {
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
};

} // namespace looping
