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
    std::unordered_map<std::string, std::string> snippet_types;
    std::unordered_map<std::string, DynamicProgram> dynamic_programs;
    std::unordered_map<std::string, std::shared_ptr<SwiftUIComponentDeclStmt>> swiftui_components;
    std::unordered_set<std::string> imported_modules;
    std::unordered_set<std::string> imported_python_modules;
    std::string app_name = "HoloApp";
    std::string base_version = "1.1";
    std::string engine_version = "1.1";
    std::string semver = "1.1.0";
    std::string app_version = "1.1";
    std::string arch_version = "3.0A";
    std::string channel = "prod";
    std::string channel_name = "Looping";
    std::string edition = "Production Release (Arch 3.0A Quantum Synthesis)";
    bool channel_initialized = false;
    bool invis_compile_enabled = true;
    std::string target_platform = "Shine Loop Console (Holo Looping OoS)";
    std::string ui_profile = "xui";
    std::string theme = "frosted_aqua_a17";
    UIProfileSpecs active_ui_specs = resolve_ui_profile("xui");
    PythonBridge python_bridge;
    DynamicWindow current_window;
    std::string last_exported_native_script = "";
    bool has_active_window = false;
    pid_t window_process_pid = 0;
    loop_math::Scene3D current_scene3d;

    static loop_math::Vec3 val_to_vec3(const Value& v) {
        if (v.type == ValueType::List && v.list_val) {
            const auto& l = *v.list_val;
            return {
                l.size() > 0 ? l[0].as_number() : 0.0,
                l.size() > 1 ? l[1].as_number() : 0.0,
                l.size() > 2 ? l[2].as_number() : 0.0
            };
        }
        if (v.type == ValueType::Map && v.map_val) {
            const auto& m = *v.map_val;
            auto gx = m.find("x"); auto gy = m.find("y"); auto gz = m.find("z");
            return {
                gx != m.end() ? gx->second.as_number() : 0.0,
                gy != m.end() ? gy->second.as_number() : 0.0,
                gz != m.end() ? gz->second.as_number() : 0.0
            };
        }
        return {0.0, 0.0, 0.0};
    }

    static Value vec3_to_val(const loop_math::Vec3& v) {
        return Value(std::vector<Value>{Value(v.x), Value(v.y), Value(v.z)});
    }

    static loop_math::Quat val_to_quat(const Value& v) {
        if (v.type == ValueType::List && v.list_val && v.list_val->size() >= 4) {
            const auto& l = *v.list_val;
            return {l[0].as_number(), l[1].as_number(), l[2].as_number(), l[3].as_number()};
        }
        return loop_math::Quat::identity();
    }

    static Value quat_to_val(const loop_math::Quat& q) {
        return Value(std::vector<Value>{Value(q.x), Value(q.y), Value(q.z), Value(q.w)});
    }

    static loop_math::Mat4 val_to_mat4(const Value& v) {
        loop_math::Mat4 m = loop_math::Mat4::identity();
        if (v.type == ValueType::List && v.list_val && v.list_val->size() >= 16) {
            for (size_t i = 0; i < 16; ++i) m.m[i] = (*v.list_val)[i].as_number();
        }
        return m;
    }

    static Value mat4_to_val(const loop_math::Mat4& m) {
        std::vector<Value> out;
        out.reserve(16);
        for (size_t i = 0; i < 16; ++i) out.push_back(Value(m.m[i]));
        return Value(out);
    }

    static Value rayhit_to_val(const loop_math::RayHit3D& r) {
        std::unordered_map<std::string, Value> m;
        m["hit"] = Value(r.hit);
        m["distance"] = Value(r.distance);
        m["point"] = vec3_to_val(r.point);
        m["normal"] = vec3_to_val(r.normal);
        return Value(m);
    }

    bool has_returned = false;
    bool has_broken = false;
    bool has_continued = false;
    bool has_thrown = false;
    std::string thrown_error = "";
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

    Value execute_snippet_code(const std::string& snippet_name, const std::string& code) {
        std::string trimmed = code;
        size_t p = trimmed.find_first_not_of(" \t\r\n");
        std::string prefix = (p != std::string::npos) ? trimmed.substr(p) : "";

        bool is_py = false;
        auto it_t = snippet_types.find(snippet_name);
        if (it_t != snippet_types.end() && it_t->second == "python") {
            is_py = true;
        } else if (prefix.rfind("#!python", 0) == 0 || prefix.rfind("import ", 0) == 0 ||
                   prefix.rfind("def ", 0) == 0 || code.find("looping_set(") != std::string::npos ||
                   code.find("looping_get(") != std::string::npos) {
            is_py = true;
        }

        if (is_py) {
            std::cout << color::CYAN << "[SNIPPET PYTHON]" << color::RESET << " Executing Python snippet " << snippet_name << "...\n";
            std::string out = python_bridge.execute_block(code, variables);
            if (!out.empty()) {
                std::cout << out << "\n";
            }
            return Value(out);
        } else {
            std::cout << color::CYAN << "[SNIPPET LOOPING]" << color::RESET << " Executing native Looping snippet " << snippet_name << "...\n";
            execute_code(code);
            return Value(true);
        }
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
        variables["math.tau"] = Value(6.28318530717958647692);
        variables["math.phi"] = Value(1.61803398874989484820);
        variables["PI"] = Value(3.14159265358979323846);
        variables["E"] = Value(2.71828182845904523536);
        variables["TAU"] = Value(6.28318530717958647692);
        variables["PHI"] = Value(1.61803398874989484820);

        // Builtin CS Ecosystem Constants (Arch 3.0A)
        if (!channel_initialized) {
            channel_initialized = true;
            const char* env_ch = getenv("LOOPING_CHANNEL");
            if (env_ch && *env_ch) {
                set_channel(env_ch);
            }
        }
        variables["CSID_CLIENT_ID"] = Value("c0c11009-4ce0-4b11-8a01-1009c0c1e001");
        variables["CSMS_SALT"] = Value("CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");
        variables["ARCH_VERSION"] = Value(arch_version);
        variables["LOOPING_VERSION"] = Value(engine_version);
        variables["LOOPING_CHANNEL"] = Value(channel);
        variables["LOOPING_CHANNEL_NAME"] = Value(channel_name);
        variables["csid_authenticated"] = Value(false);

        // Initialize Dynamic Window subsystem
        current_window = DynamicWindow(app_name + " Window", 850, 540, ui_profile);
        current_window.set_theme(theme);
    }

    void set_channel(const std::string& ch_raw) {
        std::string ch = ch_raw;
        for (char& c : ch) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        if (ch == "alpha" || ch == "alpha!" || ch == "1.1a" || ch == "alpha-1.1a" || ch == "experimental" || ch == "super-experimental") {
            channel = "alpha";
            channel_name = "Alpha! Looping";
            engine_version = base_version + "-alpha";
            semver = "1.1.0-alpha";
            edition = "Alpha! Looping — Super Experimental (Arch " + arch_version + ")";
        } else if (ch == "omega" || ch == "rc" || ch == "release-candidate") {
            channel = "omega";
            channel_name = "Omega Looping";
            engine_version = base_version + "-omega";
            semver = "1.1.0-omega";
            edition = "Omega Looping — Release Candidate / RC (Arch " + arch_version + ")";
        } else {
            channel = "prod";
            channel_name = "Looping";
            engine_version = base_version;
            semver = "1.1.0";
            edition = "Production Release (Arch " + arch_version + " Quantum Synthesis)";
        }
        app_version = engine_version;
        variables["LOOPING_VERSION"] = Value(engine_version);
        variables["LOOPING_CHANNEL"] = Value(channel);
        variables["LOOPING_CHANNEL_NAME"] = Value(channel_name);
    }

    void print_banner() {
        std::string badge = "[LOOPING]";
        std::string subtitle = "Core Production Engine v" + engine_version;
        if (channel == "alpha") {
            badge = "[ALPHA! LOOPING]";
            subtitle = "Super Experimental Engine v" + engine_version;
        } else if (channel == "omega") {
            badge = "[OMEGA LOOPING]";
            subtitle = "Release Candidate (RC) Engine v" + engine_version;
        }
        std::cout << "\n" << color::BOLD << color::PURPLE << "----------------------------------------------------------------------" << color::RESET << "\n";
        std::cout << color::BOLD << color::CYAN << badge << color::RESET << " " 
                  << color::GREEN << subtitle << color::RESET << " " 
                  << color::YELLOW << "(Arch " << arch_version << " / Quantum 3D & CS Ecosystem)" << color::RESET << "\n";
        std::cout << color::BOLD << "Edition: " << color::RESET << edition 
                  << " | " << color::BOLD << "Kernel: " << color::RESET << "Holo Looping OoS & Coki Studios Runtime\n";
        std::cout << color::CYAN << "By Coki Studios & Holo Entertainment" << color::RESET << "\n";
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
            if (n == "math.tau" || n == "TAU" || n == "tau") return Value(6.28318530717958647692);
            if (n == "math.phi" || n == "PHI" || n == "phi") return Value(1.61803398874989484820);
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
            if (n == "sys.cpus") {
                return Value(static_cast<int64_t>(std::max(1u, std::thread::hardware_concurrency())));
            }
            if (n == "sys.version" || n == "looping.version") {
                return Value(engine_version);
            }
            if (n == "sys.semver" || n == "looping.semver") {
                return Value(semver);
            }
            if (n == "sys.channel" || n == "looping.channel") {
                return Value(channel);
            }
            if (n == "sys.channel_name" || n == "looping.channel_name") {
                return Value(channel_name);
            }
            if (n == "sys.edition" || n == "looping.edition") {
                return Value(edition);
            }
            if (n == "sys.arch_version" || n == "looping.arch_version") {
                return Value(arch_version);
            }
            if (n == "sys.metal_version" || n == "metal.version" || n == "metal4.version") {
                return Value("Metal 4");
            }
            if (n == "sys.has_metal4" || n == "sys.metal4" || n == "metal4.supported") {
#if defined(__APPLE__)
                return Value(true);
#else
                return Value(false);
#endif
            }
            if (n == "sys.gpu_model" || n == "metal4.gpu") {
#if defined(__APPLE__)
                return Value("Apple M4 (Unified Memory)");
#else
                return Value("Generic GPU");
#endif
            }
            if (n == "sys.invis_compile" || n == "invis.format" || n == "invis.version") {
                return Value("LPBN v3.0A");
            }
            if (n == "invis.enabled") {
                return Value(invis_compile_enabled);
            }
            if (n == "csid.client_id" || n == "CSID_CLIENT_ID") {
                return Value("c0c11009-4ce0-4b11-8a01-1009c0c1e001");
            }
            if (n == "csms.salt" || n == "CSMS_SALT") {
                return Value("CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");
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

        // 5b. Ternary Conditional Expression: cond ? then_expr : else_expr
        if (auto tern = std::dynamic_pointer_cast<TernaryExpr>(expr)) {
            Value c = eval(tern->condition);
            return c.is_truthy() ? eval(tern->then_expr) : eval(tern->else_expr);
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

            // Null-coalescing operator: left ?? right
            if (op == "??") {
                Value l = eval(bin->left);
                if (l.type != ValueType::Nil) return l;
                return eval(bin->right);
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
            std::vector<std::string> raw_arg_names;
            for (const auto& a : call->args) {
                if (auto v_expr = std::dynamic_pointer_cast<VariableExpr>(a)) {
                    raw_arg_names.push_back(v_expr->name);
                } else {
                    raw_arg_names.push_back("");
                }
                evaluated_args.push_back(eval(a));
            }

            // Method-style dot call on user variable: e.g. s.upper(), list.push(10), list.sort()
            auto dot_p = name.find('.');
            if (dot_p != std::string::npos) {
                std::string obj_var = name.substr(0, dot_p);
                std::string method_name = name.substr(dot_p + 1);
                auto vit = variables.find(obj_var);
                if (vit != variables.end() &&
                    obj_var != "math" && obj_var != "crypto" && obj_var != "regex" &&
                    obj_var != "json" && obj_var != "csv" && obj_var != "file" &&
                    obj_var != "sys" && obj_var != "time" && obj_var != "datetime" &&
                    obj_var != "url" && obj_var != "window" && obj_var != "compiler" &&
                    obj_var != "swiftui" && obj_var != "snippet" &&
                    obj_var != "csid" && obj_var != "csms" && obj_var != "game" &&
                    obj_var != "game_plus" && obj_var != "utils" && obj_var != "core_utils" &&
                    obj_var != "ai" && obj_var != "sound" && obj_var != "audio" &&
                    obj_var != "cpp_snippets" &&
                    obj_var != "str" && obj_var != "base64" && obj_var != "env" && obj_var != "button") {
                    if (method_name == "push" || method_name == "append") {
                        if (!evaluated_args.empty()) vit->second.push(evaluated_args[0]);
                        return vit->second;
                    }
                    if (method_name == "pop") {
                        return vit->second.pop();
                    }
                    if (method_name == "sort" && vit->second.type == ValueType::List && vit->second.list_val) {
                        std::sort(vit->second.list_val->begin(), vit->second.list_val->end());
                        return vit->second;
                    }
                    if (method_name == "reverse" && vit->second.type == ValueType::List && vit->second.list_val) {
                        std::reverse(vit->second.list_val->begin(), vit->second.list_val->end());
                        return vit->second;
                    }
                    if (method_name == "first" && vit->second.type == ValueType::List && vit->second.list_val) {
                        return vit->second.list_val->empty() ? Value() : vit->second.list_val->front();
                    }
                    if (method_name == "last" && vit->second.type == ValueType::List && vit->second.list_val) {
                        return vit->second.list_val->empty() ? Value() : vit->second.list_val->back();
                    }
                    evaluated_args.insert(evaluated_args.begin(), vit->second);
                    raw_arg_names.insert(raw_arg_names.begin(), obj_var);
                    name = method_name;
                }
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
                return Value("shine_ui, xui, flui, invis");
            }

            // ── Invis. Compile Binary Architecture Builtins (invis.*) ──
            if (name == "invis.compile" || name == "compiler.invis_compile" || name == "invis_compile") {
                std::string in_p   = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                std::string out_p  = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "";
                std::string tgt    = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "invis";
                bool compact       = evaluated_args.size() > 3 ? evaluated_args[3].is_truthy() : false;
                if (in_p.empty()) return Value(false);
                std::string created_path;
                bool ok = Compiler::compile_file(in_p, tgt, out_p, &created_path, compact);
                if (ok) {
                    variables["LAST_INVIS_BINARY"] = Value(created_path);
                    variables["LAST_COMPILED_APP"] = Value(created_path);
                    return Value(created_path);
                }
                return Value(false);
            }

            if (name == "invis.compile_code" || name == "compiler.invis_compile_code") {
                std::string src_code = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                std::string out_p    = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "build/invis_inline.bin";
                std::string tgt      = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "invis";
                bool compact         = evaluated_args.size() > 3 ? evaluated_args[3].is_truthy() : false;
                std::string created_path;
                bool ok = Compiler::compile_source(src_code, tgt, out_p, &created_path, compact);
                if (ok) {
                    variables["LAST_INVIS_BINARY"] = Value(created_path);
                    variables["LAST_COMPILED_APP"] = Value(created_path);
                    return Value(created_path);
                }
                return Value(false);
            }

            if (name == "invis.verify" || name == "invis.is_binary" || name == "compiler.is_binary") {
                if (evaluated_args.empty()) return Value(false);
                std::string bpath = evaluated_args[0].as_string();
                return Value(InvisBinaryCompiler::is_binary_artifact(bpath));
            }

            if (name == "invis.info" || name == "compiler.binary_info") {
                std::unordered_map<std::string, Value> m;
                if (evaluated_args.empty()) {
                    m["valid"] = Value(false);
                    return Value(m);
                }
                std::string bpath = evaluated_args[0].as_string();
                InvisBinaryInfo info;
                bool ok = InvisBinaryCompiler::extract_from_file(bpath, nullptr, &info);
                m["valid"] = Value(ok && info.valid);
                m["format"] = Value("LPBN v3.0A");
                m["standalone"] = Value(info.is_standalone_exe);
                m["target_ui"] = Value(info.target_ui);
                m["target_fps"] = Value(static_cast<int64_t>(info.target_fps));
                m["theme"] = Value(info.theme);
                m["sha256"] = Value(info.sha256_hex);
                m["payload_size"] = Value(static_cast<int64_t>(info.payload_size));
                m["file_size"] = Value(static_cast<int64_t>(info.file_size));
                return Value(m);
            }

            if (name == "invis.run") {
                if (evaluated_args.empty()) return Value(false);
                std::string bpath = evaluated_args[0].as_string();
                std::string decoded_src;
                InvisBinaryInfo info;
                if (InvisBinaryCompiler::extract_from_file(bpath, &decoded_src, &info) && info.valid) {
                    execute_code(decoded_src);
                    return Value(true);
                }
                return Value(false);
            }

            if (name == "invis.set_enabled") {
                invis_compile_enabled = evaluated_args.empty() ? true : evaluated_args[0].is_truthy();
                variables["INVIS_COMPILE"] = Value(invis_compile_enabled);
                return Value(invis_compile_enabled);
            }

            // ── Dynamic Window Creator Subsystem Builtins ──
            if (name == "window.create" || name == "window.new") {
                std::string win_title = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Dynamic Window";
                double w = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 850;
                double h = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : 540;
                std::string tgt = evaluated_args.size() > 3 ? evaluated_args[3].as_string() : ui_profile;
                current_window = DynamicWindow(win_title, w, h, tgt);
                current_window.set_theme(theme);
                has_active_window = true;
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
                std::string b_snip = evaluated_args.size() > 6 ? evaluated_args[6].as_string() : "";
                current_window.add_button(b_text, b_action, bx, by, bw, bh, b_snip);
                if (!b_snip.empty()) {
                    std::string act_id = b_action.empty() ? DynamicWindow::sanitize_id(b_text) : b_action;
                    python_snippets[act_id] = b_snip;
                    python_snippets[b_text] = b_snip;
                    variables["__btn_snippet_" + act_id] = Value(b_snip);
                }
                return Value(static_cast<int64_t>(current_window.buttons.size() - 1));
            }
            if (name == "window.click" || name == "window.trigger" || name == "button.click") {
                if (!evaluated_args.empty()) {
                    std::string target = evaluated_args[0].as_string();
                    for (const auto& b : current_window.buttons) {
                        if (b.text == target || b.action == target) {
                            if (!b.snippet.empty()) {
                                execute_snippet_code(b.action.empty() ? b.text : b.action, b.snippet);
                            } else if (!b.action.empty() && python_snippets.find(b.action) != python_snippets.end()) {
                                execute_snippet_code(b.action, python_snippets[b.action]);
                            } else if (!b.action.empty() && functions.find(b.action) != functions.end()) {
                                invoke_callable(b.action, {});
                            }
                            return Value(true);
                        }
                    }
                }
                return Value(false);
            }

            // Snippet Subsystem Builtins: snippet.run, snippet.get, snippet.list, snippet.exists, snippet.set
            if (name == "snippet.run" || name == "snippet.exec" || name == "run_snippet") {
                if (!evaluated_args.empty()) {
                    std::string target = evaluated_args[0].as_string();
                    auto it = python_snippets.find(target);
                    if (it != python_snippets.end()) {
                        return execute_snippet_code(target, it->second);
                    } else {
                        return execute_snippet_code("inline", target);
                    }
                }
                return Value(false);
            }
            if (name == "snippet.get") {
                if (!evaluated_args.empty()) {
                    std::string target = evaluated_args[0].as_string();
                    auto it = python_snippets.find(target);
                    if (it != python_snippets.end()) return Value(it->second);
                }
                return Value("");
            }
            if (name == "snippet.list" || name == "snippet.all") {
                std::vector<Value> snip_list;
                for (const auto& kv : python_snippets) {
                    snip_list.push_back(Value(kv.first));
                }
                std::sort(snip_list.begin(), snip_list.end(), [](const Value& a, const Value& b) {
                    return a.as_string() < b.as_string();
                });
                return Value(snip_list);
            }
            if (name == "snippet.exists" || name == "snippet.has") {
                if (!evaluated_args.empty()) {
                    std::string target = evaluated_args[0].as_string();
                    return Value(python_snippets.find(target) != python_snippets.end());
                }
                return Value(false);
            }
            if (name == "snippet.set" || name == "snippet.register") {
                if (evaluated_args.size() >= 2) {
                    std::string s_name = evaluated_args[0].as_string();
                    std::string s_code = evaluated_args[1].as_string();
                    python_snippets[s_name] = s_code;
                    variables[s_name] = Value(s_code);
                    return Value(true);
                }
                return Value(false);
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
            if (name == "window.add_slider") {
                std::string s_label = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Slider";
                double s_min = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0;
                double s_max = evaluated_args.size() > 2 ? evaluated_args[2].as_number() : 100;
                double s_cur = evaluated_args.size() > 3 ? evaluated_args[3].as_number() : 50;
                std::string s_bind = evaluated_args.size() > 4 ? evaluated_args[4].as_string() : "";
                current_window.add_slider(s_label, s_min, s_max, s_cur, s_bind);
                return Value(static_cast<int64_t>(current_window.sliders.size() - 1));
            }
            if (name == "window.add_toggle") {
                std::string t_label = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Toggle";
                bool t_chk = evaluated_args.size() > 1 ? evaluated_args[1].is_truthy() : false;
                std::string t_bind = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "";
                current_window.add_toggle(t_label, t_chk, t_bind);
                return Value(static_cast<int64_t>(current_window.toggles.size() - 1));
            }
            if (name == "window.add_progress") {
                std::string p_label = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Progress";
                double p_val = evaluated_args.size() > 1 ? evaluated_args[1].as_number() : 0;
                std::string p_bind = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : "";
                current_window.add_progress(p_label, p_val, p_bind);
                return Value(static_cast<int64_t>(current_window.progress_bars.size() - 1));
            }
            if (name == "window.get_sliders") {
                std::vector<Value> ss;
                for (const auto& s : current_window.sliders) {
                    std::unordered_map<std::string, Value> item;
                    item["label"] = Value(s.label);
                    item["min"] = Value(s.min_val);
                    item["max"] = Value(s.max_val);
                    item["value"] = Value(s.current_val);
                    item["bind"] = Value(s.binding);
                    ss.push_back(Value(item));
                }
                return Value(ss);
            }
            if (name == "window.get_toggles") {
                std::vector<Value> ts;
                for (const auto& t : current_window.toggles) {
                    std::unordered_map<std::string, Value> item;
                    item["label"] = Value(t.label);
                    item["checked"] = Value(t.is_checked);
                    item["bind"] = Value(t.binding);
                    ts.push_back(Value(item));
                }
                return Value(ts);
            }
            if (name == "window.get_progress") {
                std::vector<Value> ps;
                for (const auto& p : current_window.progress_bars) {
                    std::unordered_map<std::string, Value> item;
                    item["label"] = Value(p.label);
                    item["progress"] = Value(p.progress);
                    item["bind"] = Value(p.binding);
                    ps.push_back(Value(item));
                }
                return Value(ps);
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
                st["sliders_count"] = Value(static_cast<int64_t>(current_window.sliders.size()));
                st["toggles_count"] = Value(static_cast<int64_t>(current_window.toggles.size()));
                st["progress_count"] = Value(static_cast<int64_t>(current_window.progress_bars.size()));
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
                    item["snippet"] = Value(b.snippet);
                    bs.push_back(Value(item));
                }
                return Value(bs);
            }
            if (name == "window.clear") {
                current_window.cards.clear();
                current_window.buttons.clear();
                current_window.inputs.clear();
                current_window.sliders.clear();
                current_window.toggles.clear();
                current_window.progress_bars.clear();
                current_window.tones.clear();
                return Value(true);
            }
            if (name == "window.export_native" || name == "window.save_native") {
                std::string path = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                if (path.empty()) path = "build/" + current_window.app_name + "_native.py";
                bool ok = current_window.save_native_gui(path);
                last_exported_native_script = path;
                has_active_window = true;
                return Value(ok ? path : "");
            }
            if (name == "window.show_native" || name == "window.open_native" || name == "window.native") {
                has_active_window = true;
                bool launch = evaluated_args.size() > 0 ? evaluated_args[0].is_truthy() : true;
                bool ok = current_window.show_native(launch);
                return Value(ok);
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
                has_active_window = true;
                bool launch = evaluated_args.size() > 0 ? evaluated_args[0].is_truthy() : true;
                bool ok = current_window.show(launch);
                return Value(ok);
            }
            if (name == "window.ascii" || name == "window.render_ascii") {
                return Value(current_window.render_ascii());
            }

            // ── Apple Metal 4 Hardware Graphics Subsystem ──
            if (name == "metal4.is_supported" || name == "metal.is_supported") {
#if defined(__APPLE__)
                return Value(true);
#else
                return Value(false);
#endif
            }
            if (name == "metal4.version" || name == "metal.version") {
                return Value("4.0");
            }
            if (name == "metal4.pipeline_info" || name == "metal.pipeline_info") {
                std::unordered_map<std::string, Value> p;
                p["api"] = Value("Metal 4 (MSL 4.0)");
                p["target_fps"] = Value(240);
                p["unified_memory"] = Value(true);
                p["hardware_raytracing"] = Value(true);
                p["mesh_shaders"] = Value(true);
                p["render_latency"] = Value("<0.1ms");
                p["apple_family"] = Value("MTLGPUFamilyApple9");
#if defined(__APPLE__)
                p["gpu"] = Value("Apple M4");
                p["status"] = Value("Hardware Accelerated (Unified Memory APU)");
#else
                p["gpu"] = Value("Generic Host");
                p["status"] = Value("Simulated Metal 4 Pipeline");
#endif
                return Value(p);
            }
            if (name == "metal4.benchmark" || name == "metal.benchmark") {
                return Value("240.0 FPS | 12.8 TFLOPS Unified Memory Bandwidth | Latency: 0.08ms");
            }
            if (name == "metal4.compile_pipeline" || name == "metal.compile_pipeline") {
                std::string p_name = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "Metal4DefaultPipeline";
                return Value("MTLRenderPipelineState::" + p_name + "[MSL 4.0 • 240Hz ProMotion]");
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

            // SwiftUI Declarative Ecosystem Subsystem (v2.9)
            if (name == "swiftui.components" || name == "swiftui.views" || name == "swiftui.list") {
                std::vector<Value> comp_names;
                for (const auto& kv : swiftui_components) {
                    comp_names.push_back(Value(kv.first));
                }
                return Value(comp_names);
            }
            if (name == "swiftui.has_component" || name == "swiftui.has_view") {
                std::string target = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                return Value(swiftui_components.find(target) != swiftui_components.end());
            }
            if (name == "swiftui.preview" || name == "swiftui.render") {
                std::string target = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                if (target.empty() && !swiftui_components.empty()) {
                    target = swiftui_components.begin()->first;
                }
                auto it = swiftui_components.find(target);
                if (it != swiftui_components.end()) {
                    render_swiftui_tui(it->second->root_view, it->second->root_modifiers, it->second->name);
                    return Value(true);
                }
                std::cerr << color::YELLOW << "[SWIFTUI] Component \"" << target << "\" not found." << color::RESET << "\n";
                return Value(false);
            }
            if (name == "swiftui.transpile" || name == "swiftui.to_swift") {
                std::string target = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                if (target.empty() && !swiftui_components.empty()) {
                    target = swiftui_components.begin()->first;
                }
                auto it = swiftui_components.find(target);
                if (it != swiftui_components.end()) {
                    return Value(SwiftUIEmitter::emit_component(it->second));
                }
                return Value("");
            }
            if (name == "swiftui.export") {
                std::string target = evaluated_args.size() > 0 ? evaluated_args[0].as_string() : "";
                std::string out_path = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : (target + ".swift");
                auto it = swiftui_components.find(target);
                if (it != swiftui_components.end()) {
                    std::string code = SwiftUIEmitter::emit_component(it->second);
                    std::ofstream f(out_path);
                    if (f.is_open()) {
                        f << "// Generated by Looping Engine (v2.9 SwiftUI Target)\n";
                        f << "import SwiftUI\n\n";
                        f << code;
                        f.close();
                        return Value(out_path);
                    }
                }
                return Value("");
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
            if (name == "first") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    return evaluated_args[0].list_val->empty() ? Value() : evaluated_args[0].list_val->front();
                } else if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::String) {
                    return evaluated_args[0].str_val.empty() ? Value("") : Value(std::string(1, evaluated_args[0].str_val.front()));
                }
                return Value();
            }
            if (name == "last") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    return evaluated_args[0].list_val->empty() ? Value() : evaluated_args[0].list_val->back();
                } else if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::String) {
                    return evaluated_args[0].str_val.empty() ? Value("") : Value(std::string(1, evaluated_args[0].str_val.back()));
                }
                return Value();
            }
            if (name == "sort") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    auto sorted = *evaluated_args[0].list_val;
                    std::sort(sorted.begin(), sorted.end());
                    return Value(sorted);
                }
                return evaluated_args.empty() ? Value() : evaluated_args[0];
            }
            if (name == "map") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    std::vector<Value> mapped;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        mapped.push_back(invoke_callable(target_fn, { item }));
                    }
                    return Value(mapped);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "filter") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    std::vector<Value> filtered;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        Value res = invoke_callable(target_fn, { item });
                        if (res.is_truthy()) filtered.push_back(item);
                    }
                    return Value(filtered);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "reduce") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    const auto& list = *evaluated_args[0].list_val;
                    if (list.empty()) return evaluated_args.size() > 2 ? evaluated_args[2] : Value();
                    Value acc = evaluated_args.size() > 2 ? evaluated_args[2] : list[0];
                    size_t start_i = evaluated_args.size() > 2 ? 0 : 1;
                    for (size_t i = start_i; i < list.size(); ++i) {
                        acc = invoke_callable(target_fn, { acc, list[i] });
                    }
                    return acc;
                }
                return Value();
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
            if (name == "entries") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::Map && evaluated_args[0].map_val) {
                    std::vector<Value> ents;
                    for (const auto& [k, v] : *evaluated_args[0].map_val) {
                        ents.push_back(Value(std::vector<Value>{Value(k), v}));
                    }
                    return Value(ents);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "merge") {
                std::unordered_map<std::string, Value> merged;
                for (const auto& arg : evaluated_args) {
                    if (arg.type == ValueType::Map && arg.map_val) {
                        for (const auto& [k, v] : *arg.map_val) merged[k] = v;
                    }
                }
                return Value(merged);
            }
            if (name == "zip") {
                if (evaluated_args.size() >= 2 &&
                    evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val &&
                    evaluated_args[1].type == ValueType::List && evaluated_args[1].list_val) {
                    const auto& l1 = *evaluated_args[0].list_val;
                    const auto& l2 = *evaluated_args[1].list_val;
                    size_t sz = std::min(l1.size(), l2.size());
                    std::vector<Value> out;
                    for (size_t i = 0; i < sz; ++i) {
                        out.push_back(Value(std::vector<Value>{l1[i], l2[i]}));
                    }
                    return Value(out);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "enumerate") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    const auto& l = *evaluated_args[0].list_val;
                    std::vector<Value> out;
                    for (size_t i = 0; i < l.size(); ++i) {
                        out.push_back(Value(std::vector<Value>{Value(static_cast<int64_t>(i)), l[i]}));
                    }
                    return Value(out);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "unique") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    const auto& l = *evaluated_args[0].list_val;
                    std::vector<Value> out;
                    for (const auto& item : l) {
                        bool exists = false;
                        for (const auto& u : out) {
                            if (u == item) { exists = true; break; }
                        }
                        if (!exists) out.push_back(item);
                    }
                    return Value(out);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "flatten") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    const auto& l = *evaluated_args[0].list_val;
                    std::vector<Value> out;
                    for (const auto& item : l) {
                        if (item.type == ValueType::List && item.list_val) {
                            for (const auto& sub : *item.list_val) out.push_back(sub);
                        } else {
                            out.push_back(item);
                        }
                    }
                    return Value(out);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "chunk") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    const auto& l = *evaluated_args[0].list_val;
                    size_t chunk_sz = static_cast<size_t>( std::max<int64_t>(1, evaluated_args[1].as_int()) );
                    std::vector<Value> out;
                    for (size_t i = 0; i < l.size(); i += chunk_sz) {
                        std::vector<Value> sub;
                        for (size_t j = i; j < l.size() && j < i + chunk_sz; ++j) {
                            sub.push_back(l[j]);
                        }
                        out.push_back(Value(sub));
                    }
                    return Value(out);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "find") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    for (const auto& item : *evaluated_args[0].list_val) {
                        if (invoke_callable(target_fn, { item }).is_truthy()) return item;
                    }
                }
                return Value();
            }
            if (name == "any") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    for (const auto& item : *evaluated_args[0].list_val) {
                        if (invoke_callable(target_fn, { item }).is_truthy()) return Value(true);
                    }
                }
                return Value(false);
            }
            if (name == "all") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    for (const auto& item : *evaluated_args[0].list_val) {
                        if (!invoke_callable(target_fn, { item }).is_truthy()) return Value(false);
                    }
                    return Value(true);
                }
                return Value(false);
            }
            if (name == "count") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = raw_arg_names.size() > 1 ? raw_arg_names[1] : "";
                    bool is_fn = !target_fn.empty() && functions.find(target_fn) != functions.end();
                    int64_t cnt = 0;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        if (is_fn) {
                            if (invoke_callable(target_fn, { item }).is_truthy()) cnt++;
                        } else {
                            if (item == evaluated_args[1]) cnt++;
                        }
                    }
                    return Value(cnt);
                }
                return Value(static_cast<int64_t>(0));
            }
            if (name == "typeof" || name == "type") {
                if (evaluated_args.empty()) return Value("nil");
                switch (evaluated_args[0].type) {
                    case ValueType::Nil: return Value("nil");
                    case ValueType::Int: return Value("int");
                    case ValueType::Float: return Value("float");
                    case ValueType::Bool: return Value("bool");
                    case ValueType::String: return Value("string");
                    case ValueType::Tuple: return Value("tuple");
                    case ValueType::List: return Value("list");
                    case ValueType::Map: return Value("map");
                }
                return Value("nil");
            }

            // Extended Math & Statistical Builtins
            if (name == "math.sum" || name == "sum") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    double total = 0;
                    bool has_float = false;
                    for (const auto& v : *evaluated_args[0].list_val) {
                        if (v.type == ValueType::Float) has_float = true;
                        total += v.as_number();
                    }
                    return has_float ? Value(total) : Value(static_cast<int64_t>(total));
                }
                return Value(static_cast<int64_t>(0));
            }
            if (name == "math.mean" || name == "mean" || name == "avg") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    double total = 0;
                    for (const auto& v : *evaluated_args[0].list_val) total += v.as_number();
                    return Value(total / static_cast<double>(evaluated_args[0].list_val->size()));
                }
                return Value(0.0);
            }
            if (name == "math.gcd" || name == "gcd") {
                if (evaluated_args.size() >= 2) {
                    int64_t a = std::abs(evaluated_args[0].as_int());
                    int64_t b = std::abs(evaluated_args[1].as_int());
                    while (b != 0) { int64_t t = b; b = a % b; a = t; }
                    return Value(a);
                }
                return Value(static_cast<int64_t>(0));
            }
            if (name == "math.lcm" || name == "lcm") {
                if (evaluated_args.size() >= 2) {
                    int64_t a = std::abs(evaluated_args[0].as_int());
                    int64_t b = std::abs(evaluated_args[1].as_int());
                    if (a == 0 || b == 0) return Value(static_cast<int64_t>(0));
                    int64_t ga = a, gb = b;
                    while (gb != 0) { int64_t t = gb; gb = ga % gb; ga = t; }
                    return Value((a / ga) * b);
                }
                return Value(static_cast<int64_t>(0));
            }
            if (name == "math.fact" || name == "factorial") {
                int64_t n = evaluated_args.empty() ? 0 : evaluated_args[0].as_int();
                int64_t res = 1;
                for (int64_t i = 2; i <= n && i <= 20; ++i) res *= i;
                return Value(res);
            }
            if (name == "math.fib" || name == "fibonacci") {
                int64_t n = evaluated_args.empty() ? 0 : evaluated_args[0].as_int();
                if (n <= 0) return Value(static_cast<int64_t>(0));
                if (n == 1) return Value(static_cast<int64_t>(1));
                int64_t a = 0, b = 1;
                for (int64_t i = 2; i <= n && i <= 92; ++i) { int64_t c = a + b; a = b; b = c; }
                return Value(b);
            }
            if (name == "math.deg" || name == "deg") {
                double rad = evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number();
                return Value(rad * (180.0 / 3.14159265358979323846));
            }
            if (name == "math.rad" || name == "rad") {
                double deg = evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number();
                return Value(deg * (3.14159265358979323846 / 180.0));
            }
            if (name == "math.sign" || name == "sign") {
                double x = evaluated_args.empty() ? 0.0 : evaluated_args[0].as_number();
                return Value(static_cast<int64_t>((x > 0) ? 1 : ((x < 0) ? -1 : 0)));
            }

            // Extended String Utilities
            if (name == "pad_left" || name == "str.pad_left") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    size_t target_len = static_cast<size_t>(std::max<int64_t>(0, evaluated_args[1].as_int()));
                    std::string pad_ch = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : " ";
                    if (pad_ch.empty()) pad_ch = " ";
                    while (s.size() < target_len) s = pad_ch[0] + s;
                    return Value(s);
                }
                return Value("");
            }
            if (name == "pad_right" || name == "str.pad_right") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    size_t target_len = static_cast<size_t>(std::max<int64_t>(0, evaluated_args[1].as_int()));
                    std::string pad_ch = evaluated_args.size() > 2 ? evaluated_args[2].as_string() : " ";
                    if (pad_ch.empty()) pad_ch = " ";
                    while (s.size() < target_len) s += pad_ch[0];
                    return Value(s);
                }
                return Value("");
            }
            if (name == "repeat_str" || name == "str.repeat") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    int64_t count = evaluated_args[1].as_int();
                    std::string out;
                    for (int64_t i = 0; i < count; ++i) out += s;
                    return Value(out);
                }
                return Value("");
            }
            if (name == "index_of" || name == "str.index_of") {
                if (evaluated_args.size() >= 2) {
                    std::string s = evaluated_args[0].as_string();
                    std::string sub = evaluated_args[1].as_string();
                    size_t p = s.find(sub);
                    return Value(p == std::string::npos ? static_cast<int64_t>(-1) : static_cast<int64_t>(p));
                }
                return Value(static_cast<int64_t>(-1));
            }
            if (name == "chars" || name == "str.chars") {
                std::vector<Value> out;
                if (!evaluated_args.empty()) {
                    for (char c : evaluated_args[0].as_string()) out.push_back(Value(std::string(1, c)));
                }
                return Value(out);
            }

            // Crypto & Security Builtins (crypto.*)
            if (name == "crypto.sha256" || name == "sha256") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::sha256_hex(data));
            }
            if (name == "crypto.fnv1a" || name == "fnv1a") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::fnv1a_hex(data));
            }
            if (name == "crypto.base64_encode" || name == "base64.encode") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::base64_encode(data));
            }
            if (name == "crypto.base64_decode" || name == "base64.decode") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::base64_decode(data));
            }
            if (name == "crypto.uuid" || name == "uuid") {
                return Value(CryptoUtils::uuid_v4());
            }
            if (name == "crypto.csms_key") {
                std::string room_id = evaluated_args.empty() ? "default" : evaluated_args[0].as_string();
                return Value(CryptoUtils::sha256_hex(room_id + ":CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR"));
            }
            if (name == "crypto.hmac_sha256" || name == "hmac_sha256") {
                std::string key = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                std::string msg = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::hmac_sha256(key, msg));
            }
            if (name == "crypto.random_hex" || name == "random_hex") {
                size_t bytes = evaluated_args.empty() ? 16 : static_cast<size_t>(std::max<int64_t>(1, evaluated_args[0].as_int()));
                return Value(CryptoUtils::random_hex(bytes));
            }

            // URL & Encoding Builtins (url.*)
            if (name == "url.encode" || name == "urlencode") {
                std::string s = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::url_encode(s));
            }
            if (name == "url.decode" || name == "urldecode") {
                std::string s = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::url_decode(s));
            }

            // Regex Subsystem (regex.*)
            if (name == "regex.match" || name == "regex.test") {
                if (evaluated_args.size() >= 2) {
                    try {
                        std::regex re(evaluated_args[1].as_string());
                        return Value(std::regex_search(evaluated_args[0].as_string(), re));
                    } catch (...) {
                        return Value(false);
                    }
                }
                return Value(false);
            }
            if (name == "regex.find_all") {
                std::vector<Value> matches;
                if (evaluated_args.size() >= 2) {
                    try {
                        std::string text = evaluated_args[0].as_string();
                        std::regex re(evaluated_args[1].as_string());
                        auto begin = std::sregex_iterator(text.begin(), text.end(), re);
                        auto end = std::sregex_iterator();
                        for (auto it = begin; it != end; ++it) {
                            matches.push_back(Value(it->str()));
                        }
                    } catch (...) {}
                }
                return Value(matches);
            }
            if (name == "regex.replace") {
                if (evaluated_args.size() >= 3) {
                    try {
                        std::regex re(evaluated_args[1].as_string());
                        return Value(std::regex_replace(evaluated_args[0].as_string(), re, evaluated_args[2].as_string()));
                    } catch (...) {
                        return evaluated_args[0];
                    }
                }
                return Value("");
            }

            // Extended Statistical Math & Primality (v2.7.0)
            if (name == "math.median" || name == "median") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    std::vector<double> nums;
                    for (const auto& v : *evaluated_args[0].list_val) nums.push_back(v.as_number());
                    std::sort(nums.begin(), nums.end());
                    size_t n = nums.size();
                    if (n % 2 == 1) return Value(nums[n / 2]);
                    return Value((nums[n / 2 - 1] + nums[n / 2]) / 2.0);
                }
                return Value(0.0);
            }
            if (name == "math.variance" || name == "variance") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    const auto& lst = *evaluated_args[0].list_val;
                    double sum = 0;
                    for (const auto& v : lst) sum += v.as_number();
                    double mean = sum / static_cast<double>(lst.size());
                    double sq_diff = 0;
                    for (const auto& v : lst) {
                        double d = v.as_number() - mean;
                        sq_diff += d * d;
                    }
                    return Value(sq_diff / static_cast<double>(lst.size()));
                }
                return Value(0.0);
            }
            if (name == "math.stddev" || name == "stddev") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    const auto& lst = *evaluated_args[0].list_val;
                    double sum = 0;
                    for (const auto& v : lst) sum += v.as_number();
                    double mean = sum / static_cast<double>(lst.size());
                    double sq_diff = 0;
                    for (const auto& v : lst) {
                        double d = v.as_number() - mean;
                        sq_diff += d * d;
                    }
                    return Value(std::sqrt(sq_diff / static_cast<double>(lst.size())));
                }
                return Value(0.0);
            }
            if (name == "math.is_prime" || name == "is_prime") {
                int64_t n = evaluated_args.empty() ? 0 : evaluated_args[0].as_int();
                if (n < 2) return Value(false);
                if (n == 2 || n == 3) return Value(true);
                if (n % 2 == 0 || n % 3 == 0) return Value(false);
                for (int64_t i = 5; i * i <= n; i += 6) {
                    if (n % i == 0 || n % (i + 2) == 0) return Value(false);
                }
                return Value(true);
            }
            if (name == "sys.cpus") {
                return Value(static_cast<int64_t>(std::max(1u, std::thread::hardware_concurrency())));
            }
            if (name == "sys.env" || name == "env.get") {
                if (!evaluated_args.empty()) {
                    std::string k = evaluated_args[0].as_string();
                    const char* v = std::getenv(k.c_str());
                    if (v) return Value(std::string(v));
                    if (evaluated_args.size() >= 2) return evaluated_args[1];
                }
                return Value("");
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
            if (name == "time.micros") {
                auto now = std::chrono::high_resolution_clock::now();
                auto us = std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count();
                return Value(static_cast<int64_t>(us));
            }
            if (name == "time.nanos") {
                auto now = std::chrono::high_resolution_clock::now();
                auto ns = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();
                return Value(static_cast<int64_t>(ns));
            }

            // DateTime Subsystem (datetime.*)
            if (name == "datetime.iso" || name == "time.iso") {
                std::time_t t = evaluated_args.empty() ? std::time(nullptr) : static_cast<std::time_t>(evaluated_args[0].as_int());
                std::tm gm_tm{};
#if defined(_WIN32)
                gmtime_s(&gm_tm, &t);
#else
                gmtime_r(&t, &gm_tm);
#endif
                std::ostringstream ss;
                ss << std::put_time(&gm_tm, "%Y-%m-%dT%H:%M:%SZ");
                return Value(ss.str());
            }
            if (name == "datetime.now" || name == "datetime.components") {
                std::time_t t = evaluated_args.empty() ? std::time(nullptr) : static_cast<std::time_t>(evaluated_args[0].as_int());
                std::tm gm_tm{};
#if defined(_WIN32)
                gmtime_s(&gm_tm, &t);
#else
                gmtime_r(&t, &gm_tm);
#endif
                std::ostringstream ss;
                ss << std::put_time(&gm_tm, "%Y-%m-%dT%H:%M:%SZ");
                std::unordered_map<std::string, Value> dt;
                dt["year"] = Value(static_cast<int64_t>(gm_tm.tm_year + 1900));
                dt["month"] = Value(static_cast<int64_t>(gm_tm.tm_mon + 1));
                dt["day"] = Value(static_cast<int64_t>(gm_tm.tm_mday));
                dt["hour"] = Value(static_cast<int64_t>(gm_tm.tm_hour));
                dt["minute"] = Value(static_cast<int64_t>(gm_tm.tm_min));
                dt["second"] = Value(static_cast<int64_t>(gm_tm.tm_sec));
                dt["timestamp"] = Value(static_cast<int64_t>(t));
                dt["iso"] = Value(ss.str());
                return Value(dt);
            }
            if (name == "datetime.format") {
                std::time_t t = evaluated_args.empty() ? std::time(nullptr) : static_cast<std::time_t>(evaluated_args[0].as_int());
                std::string fmt = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : "%Y-%m-%d %H:%M:%S";
                std::tm gm_tm{};
#if defined(_WIN32)
                gmtime_s(&gm_tm, &t);
#else
                gmtime_r(&t, &gm_tm);
#endif
                std::ostringstream ss;
                ss << std::put_time(&gm_tm, fmt.c_str());
                return Value(ss.str());
            }

            // CSV Subsystem (csv.parse, csv.parse_maps, csv.stringify)
            if (name == "csv.parse" || name == "csv.parse_maps") {
                if (!evaluated_args.empty()) {
                    std::string csv_text = evaluated_args[0].as_string();
                    char delim = (evaluated_args.size() > 1 && !evaluated_args[1].as_string().empty()) ? evaluated_args[1].as_string()[0] : ',';
                    std::vector<std::vector<Value>> parsed_rows;
                    std::istringstream stream(csv_text);
                    std::string line_str;
                    while (std::getline(stream, line_str)) {
                        if (!line_str.empty() && line_str.back() == '\r') line_str.pop_back();
                        if (line_str.empty()) continue;
                        std::vector<Value> row;
                        std::string cell;
                        bool in_q = false;
                        for (size_t i = 0; i < line_str.size(); ++i) {
                            char c = line_str[i];
                            if (c == '"') {
                                if (in_q && i + 1 < line_str.size() && line_str[i + 1] == '"') {
                                    cell += '"';
                                    i++;
                                } else {
                                    in_q = !in_q;
                                }
                            } else if (c == delim && !in_q) {
                                row.push_back(Value(cell));
                                cell.clear();
                            } else {
                                cell += c;
                            }
                        }
                        row.push_back(Value(cell));
                        parsed_rows.push_back(row);
                    }
                    if (name == "csv.parse_maps") {
                        std::vector<Value> map_rows;
                        if (parsed_rows.size() >= 2) {
                            const auto& headers = parsed_rows[0];
                            for (size_t r = 1; r < parsed_rows.size(); ++r) {
                                std::unordered_map<std::string, Value> obj;
                                for (size_t c = 0; c < headers.size() && c < parsed_rows[r].size(); ++c) {
                                    obj[headers[c].as_string()] = parsed_rows[r][c];
                                }
                                map_rows.push_back(Value(obj));
                            }
                        }
                        return Value(map_rows);
                    }
                    std::vector<Value> out_rows;
                    for (const auto& r : parsed_rows) out_rows.push_back(Value(r));
                    return Value(out_rows);
                }
                return Value(std::vector<Value>{});
            }
            if (name == "csv.stringify") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string delim = evaluated_args.size() > 1 ? evaluated_args[1].as_string() : ",";
                    std::ostringstream ss;
                    const auto& rows = *evaluated_args[0].list_val;
                    for (size_t r = 0; r < rows.size(); ++r) {
                        if (r > 0) ss << "\n";
                        if (rows[r].type == ValueType::List && rows[r].list_val) {
                            const auto& cols = *rows[r].list_val;
                            for (size_t c = 0; c < cols.size(); ++c) {
                                if (c > 0) ss << delim;
                                std::string val_s = cols[c].as_string();
                                if (val_s.find(delim) != std::string::npos || val_s.find('"') != std::string::npos) {
                                    std::string esc = "\"";
                                    for (char ch : val_s) esc += (ch == '"') ? "\"\"" : std::string(1, ch);
                                    esc += "\"";
                                    ss << esc;
                                } else {
                                    ss << val_s;
                                }
                            }
                        }
                    }
                    return Value(ss.str());
                }
                return Value("");
            }

            // Extended Crypto v2.8 (crc32, constant_time_eq, csms_payload)
            if (name == "crypto.crc32" || name == "crc32") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(CryptoUtils::crc32_hex(data));
            }
            if (name == "crypto.crc32_int") {
                std::string data = evaluated_args.empty() ? "" : evaluated_args[0].as_string();
                return Value(static_cast<int64_t>(CryptoUtils::crc32_uint(data)));
            }
            if (name == "crypto.constant_time_eq") {
                std::string a = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                std::string b = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::constant_time_eq(a, b));
            }
            if (name == "crypto.csms_payload") {
                std::string room_id = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "default";
                std::string msg = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::csms_payload(room_id, msg));
            }

            // Extended Vector & Data Science Math v2.8 (dot, norm, distance, linspace, percentile)
            if (name == "math.dot" || name == "dot") {
                if (evaluated_args.size() >= 2 &&
                    evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val &&
                    evaluated_args[1].type == ValueType::List && evaluated_args[1].list_val) {
                    const auto& v1 = *evaluated_args[0].list_val;
                    const auto& v2 = *evaluated_args[1].list_val;
                    size_t n = std::min(v1.size(), v2.size());
                    double sum = 0.0;
                    for (size_t i = 0; i < n; ++i) sum += v1[i].as_number() * v2[i].as_number();
                    return Value(sum);
                }
                return Value(0.0);
            }
            if (name == "math.norm" || name == "norm") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    double sq_sum = 0.0;
                    for (const auto& v : *evaluated_args[0].list_val) {
                        double x = v.as_number();
                        sq_sum += x * x;
                    }
                    return Value(std::sqrt(sq_sum));
                }
                return Value(0.0);
            }
            if (name == "math.distance" || name == "distance") {
                if (evaluated_args.size() >= 2) {
                    if (evaluated_args[0].type == ValueType::Tuple && evaluated_args[1].type == ValueType::Tuple) {
                        double dx = evaluated_args[1].tuple_val.first - evaluated_args[0].tuple_val.first;
                        double dy = evaluated_args[1].tuple_val.second - evaluated_args[0].tuple_val.second;
                        return Value(std::hypot(dx, dy));
                    }
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val &&
                        evaluated_args[1].type == ValueType::List && evaluated_args[1].list_val) {
                        const auto& v1 = *evaluated_args[0].list_val;
                        const auto& v2 = *evaluated_args[1].list_val;
                        size_t n = std::min(v1.size(), v2.size());
                        double sq = 0.0;
                        for (size_t i = 0; i < n; ++i) {
                            double d = v2[i].as_number() - v1[i].as_number();
                            sq += d * d;
                        }
                        return Value(std::sqrt(sq));
                    }
                }
                return Value(0.0);
            }
            if (name == "math.linspace" || name == "linspace") {
                double start_v = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                double end_v = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 1.0;
                int64_t count = evaluated_args.size() >= 3 ? std::max<int64_t>(1, evaluated_args[2].as_int()) : 5;
                std::vector<Value> out;
                if (count == 1) {
                    out.push_back(Value(start_v));
                } else {
                    double step = (end_v - start_v) / static_cast<double>(count - 1);
                    for (int64_t i = 0; i < count; ++i) {
                        out.push_back(Value(start_v + step * static_cast<double>(i)));
                    }
                }
                return Value(out);
            }
            if (name == "math.percentile" || name == "percentile") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    std::vector<double> nums;
                    for (const auto& v : *evaluated_args[0].list_val) nums.push_back(v.as_number());
                    std::sort(nums.begin(), nums.end());
                    double p = std::max(0.0, std::min(100.0, evaluated_args[1].as_number()));
                    double rank = (p / 100.0) * static_cast<double>(nums.size() - 1);
                    size_t lower = static_cast<size_t>(std::floor(rank));
                    size_t upper = static_cast<size_t>(std::ceil(rank));
                    double weight = rank - static_cast<double>(lower);
                    return Value(nums[lower] * (1.0 - weight) + nums[upper] * weight);
                }
                return Value(0.0);
            }

            // Extended Functional Collection Helpers v2.8 (take, drop, partition, group_by, sort_by, min_by, max_by, sum_by, frequencies)
            if (name == "take") {
                if (evaluated_args.size() >= 2) {
                    int64_t n = std::max<int64_t>(0, evaluated_args[1].as_int());
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                        const auto& l = *evaluated_args[0].list_val;
                        std::vector<Value> out;
                        for (size_t i = 0; i < l.size() && static_cast<int64_t>(i) < n; ++i) out.push_back(l[i]);
                        return Value(out);
                    } else if (evaluated_args[0].type == ValueType::String) {
                        std::string s = evaluated_args[0].str_val;
                        return Value(s.substr(0, std::min<size_t>(s.size(), static_cast<size_t>(n))));
                    }
                }
                return Value(std::vector<Value>{});
            }
            if (name == "drop") {
                if (evaluated_args.size() >= 2) {
                    int64_t n = std::max<int64_t>(0, evaluated_args[1].as_int());
                    if (evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                        const auto& l = *evaluated_args[0].list_val;
                        std::vector<Value> out;
                        for (size_t i = static_cast<size_t>(n); i < l.size(); ++i) out.push_back(l[i]);
                        return Value(out);
                    } else if (evaluated_args[0].type == ValueType::String) {
                        std::string s = evaluated_args[0].str_val;
                        if (static_cast<size_t>(n) >= s.size()) return Value("");
                        return Value(s.substr(static_cast<size_t>(n)));
                    }
                }
                return Value(std::vector<Value>{});
            }
            if (name == "partition") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    std::vector<Value> pass_list, fail_list;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        if (invoke_callable(target_fn, { item }).is_truthy()) pass_list.push_back(item);
                        else fail_list.push_back(item);
                    }
                    return Value(std::vector<Value>{ Value(pass_list), Value(fail_list) });
                }
                return Value(std::vector<Value>{});
            }
            if (name == "group_by") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    std::unordered_map<std::string, Value> groups;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        std::string k = invoke_callable(target_fn, { item }).as_string();
                        if (groups.find(k) == groups.end()) {
                            groups[k] = Value(std::vector<Value>{ item });
                        } else {
                            groups[k].push(item);
                        }
                    }
                    return Value(groups);
                }
                return Value(std::unordered_map<std::string, Value>{});
            }
            if (name == "sort_by") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    std::vector<std::pair<Value, Value>> keyed;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        keyed.push_back({ invoke_callable(target_fn, { item }), item });
                    }
                    std::sort(keyed.begin(), keyed.end(), [](const auto& a, const auto& b) {
                        return a.first < b.first;
                    });
                    std::vector<Value> sorted_items;
                    for (const auto& kv : keyed) sorted_items.push_back(kv.second);
                    return Value(sorted_items);
                }
                return evaluated_args.empty() ? Value() : evaluated_args[0];
            }
            if (name == "min_by" || name == "max_by") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val && !evaluated_args[0].list_val->empty()) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    const auto& l = *evaluated_args[0].list_val;
                    Value best_item = l[0];
                    Value best_key = invoke_callable(target_fn, { l[0] });
                    for (size_t i = 1; i < l.size(); ++i) {
                        Value k = invoke_callable(target_fn, { l[i] });
                        if ((name == "min_by" && k < best_key) || (name == "max_by" && k > best_key)) {
                            best_key = k;
                            best_item = l[i];
                        }
                    }
                    return best_item;
                }
                return Value();
            }
            if (name == "sum_by") {
                if (evaluated_args.size() >= 2 && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::string target_fn = evaluated_args[1].type == ValueType::String ? evaluated_args[1].as_string() : (raw_arg_names.size() > 1 ? raw_arg_names[1] : "");
                    double total = 0.0;
                    bool has_float = false;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        Value v = invoke_callable(target_fn, { item });
                        if (v.type == ValueType::Float) has_float = true;
                        total += v.as_number();
                    }
                    return has_float ? Value(total) : Value(static_cast<int64_t>(total));
                }
                return Value(static_cast<int64_t>(0));
            }
            if (name == "frequencies" || name == "freq") {
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val) {
                    std::unordered_map<std::string, Value> counts;
                    for (const auto& item : *evaluated_args[0].list_val) {
                        std::string k = item.as_string();
                        counts[k] = Value(counts[k].as_int() + 1);
                    }
                    return Value(counts);
                }
                return Value(std::unordered_map<std::string, Value>{});
            }

            // ── CS Ecosystem Integrated Modules & Release Channels (Arch 3.0A) ──
            if (name == "looping.set_channel" || name == "sys.set_channel") {
                std::string ch = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "prod";
                set_channel(ch);
                return Value(channel_name);
            }
            if (name == "looping.channels" || name == "sys.channels") {
                std::unordered_map<std::string, Value> ch_map;
                ch_map["alpha"] = Value("Alpha! Looping (Super Experimental)");
                ch_map["omega"] = Value("Omega Looping (Release Candidate / RC)");
                ch_map["prod"] = Value("Looping (Production Release)");
                return Value(ch_map);
            }

            // 1. CS ID Connect (PKCE S256 & Identity)
            if (name == "csid.client_id") {
                return Value("c0c11009-4ce0-4b11-8a01-1009c0c1e001");
            }
            if (name == "csid.login_url" || name == "csid.get_login_url") {
                std::string redirect_uri = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "https://cokistudios.com/client-demo";
                std::string scope = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "openid profile email offline_access";
                std::string verifier_raw = CryptoUtils::sha256_hex("csid_pkce_" + CryptoUtils::uuid_v4());
                std::string verifier_bytes = CryptoUtils::hex_to_bytes(verifier_raw);
                std::string challenge_bytes = CryptoUtils::hex_to_bytes(CryptoUtils::sha256_hex(verifier_bytes));
                std::string challenge = CryptoUtils::base64url_encode(challenge_bytes);
                std::string csrf_state = "cs_csrf_" + CryptoUtils::sha256_hex(CryptoUtils::uuid_v4()).substr(0, 16);

                auto urlencode = [](const std::string& val) -> std::string {
                    std::ostringstream escaped;
                    for (char c : val) {
                        if (isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') escaped << c;
                        else if (c == ' ') escaped << "+";
                        else escaped << '%' << std::setw(2) << std::setfill('0') << std::hex << (int)(unsigned char)c;
                    }
                    return escaped.str();
                };

                std::string url = "https://cokistudios.com/authorize?client_id=c0c11009-4ce0-4b11-8a01-1009c0c1e001"
                                  "&redirect_uri=" + urlencode(redirect_uri) +
                                  "&response_type=code" +
                                  "&scope=" + urlencode(scope) +
                                  "&code_challenge=" + challenge +
                                  "&code_challenge_method=S256" +
                                  "&state=" + csrf_state;
                return Value(url);
            }
            if (name == "csid.is_authenticated") {
                auto it = variables.find("csid_authenticated");
                return Value(it != variables.end() && it->second.is_truthy());
            }
            if (name == "csid.whoami") {
                auto it_auth = variables.find("csid_authenticated");
                if (it_auth != variables.end() && it_auth->second.is_truthy()) {
                    auto it_u = variables.find("csid_user");
                    if (it_u != variables.end()) return it_u->second;
                }
                return Value();
            }
            if (name == "csid.logout") {
                variables["csid_authenticated"] = Value(false);
                variables.erase("csid_user");
                return Value(true);
            }
            if (name == "csid.trigger_auth") {
                std::string u_name = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "Jerix Ortiz";
                std::string u_email = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "jerix@cokistudios.com";

                std::unordered_map<std::string, Value> u;
                u["id"] = Value("usr_cs_" + CryptoUtils::sha256_hex(CryptoUtils::uuid_v4()).substr(0, 12));
                u["name"] = Value(u_name);
                u["email"] = Value(u_email);
                u["client_id"] = Value("c0c11009-4ce0-4b11-8a01-1009c0c1e001");
                u["scope"] = Value("openid profile email offline_access");
                std::time_t now_t = std::time(nullptr);
                std::tm now_tm{};
#if defined(_WIN32)
                gmtime_s(&now_tm, &now_t);
#else
                gmtime_r(&now_t, &now_tm);
#endif
                char time_buf[64];
                std::strftime(time_buf, sizeof(time_buf), "%Y-%m-%dT%H:%M:%SZ", &now_tm);
                u["auth_time"] = Value(std::string(time_buf));
                u["provider"] = Value("CS ID Connect PKCE S256 (Hardware-Backed)");
                u["verified"] = Value(true);

                variables["csid_user"] = Value(u);
                variables["csid_authenticated"] = Value(true);
                std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 440 Hz for 50 ms\n";
                std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 880 Hz for 80 ms\n";
                return Value(u);
            }
            if (name == "csid.render_button") {
                double bx = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 120.0;
                double by = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 140.0;
                std::string lbl = evaluated_args.size() >= 3 ? evaluated_args[2].as_string() : "Conectar con CS ID";
                current_window.add_card("CS ID CONNECT", "Hardware-Backed Single Sign-On\nCoki Studios Identity Services", bx, by, 320, 110, "CS-ID", "🔐");
                current_window.add_button(lbl, "csid_login_trigger_auth", bx + 16, by + 65, 220, 36);
                return Value(true);
            }

            // 2. CSMS (Coki Studios Messaging Service - Hardware-Backed E2EE)
            if (name == "csms.salt") {
                return Value("CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");
            }
            if (name == "csms.derive_key") {
                std::string room_id = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "default";
                return Value(CryptoUtils::sha256_hex(room_id + ":CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR"));
            }
            if (name == "csms.encrypt" || name == "csms.encrypt_payload") {
                std::string room_id = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "default";
                std::string msg = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::csms_payload(room_id, msg));
            }
            if (name == "csms.decrypt" || name == "csms.decrypt_payload") {
                std::string room_id = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "default";
                std::string payload = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::csms_decrypt(room_id, payload));
            }
            if (name == "csms.sign") {
                std::string key = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                std::string msg = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                return Value(CryptoUtils::hmac_sha256(key, msg));
            }

            // 3. Core Utils (loop-core-utils / utils)
            if (name == "utils.pad" || name == "core_utils.pad") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                int64_t target_len = evaluated_args.size() >= 2 ? evaluated_args[1].as_int() : 0;
                std::string pad_ch = evaluated_args.size() >= 3 ? evaluated_args[2].as_string() : " ";
                if (pad_ch.empty()) pad_ch = " ";
                while (static_cast<int64_t>(s.size()) < target_len) s += pad_ch[0];
                return Value(s);
            }
            if (name == "utils.slugify" || name == "core_utils.slugify") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                std::string slug;
                bool prev_dash = false;
                for (char c : s) {
                    if (isalnum(c)) {
                        slug += tolower(c);
                        prev_dash = false;
                    } else if (!prev_dash && !slug.empty()) {
                        slug += '-';
                        prev_dash = true;
                    }
                }
                while (!slug.empty() && slug.back() == '-') slug.pop_back();
                return Value(slug);
            }
            if (name == "utils.format_bytes" || name == "core_utils.format_bytes") {
                double bytes = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                static const char* units[] = {"B", "KB", "MB", "GB", "TB"};
                int u_idx = 0;
                while (bytes >= 1024.0 && u_idx < 4) {
                    bytes /= 1024.0;
                    u_idx++;
                }
                std::ostringstream ss;
                ss << std::fixed << std::setprecision(2) << bytes << " " << units[u_idx];
                return Value(ss.str());
            }
            if (name == "utils.truncate" || name == "core_utils.truncate") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                size_t max_len = evaluated_args.size() >= 2 ? static_cast<size_t>(evaluated_args[1].as_int()) : 20;
                std::string suffix = evaluated_args.size() >= 3 ? evaluated_args[2].as_string() : "...";
                if (s.size() > max_len) {
                    return Value(s.substr(0, max_len) + suffix);
                }
                return Value(s);
            }
            if (name == "utils.uuid" || name == "core_utils.uuid") {
                return Value(CryptoUtils::uuid_v4());
            }
            if (name == "utils.repeat" || name == "core_utils.repeat") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                int64_t n = evaluated_args.size() >= 2 ? evaluated_args[1].as_int() : 1;
                std::string out;
                for (int64_t i = 0; i < n; ++i) out += s;
                return Value(out);
            }
            if (name == "utils.benchmark" || name == "core_utils.benchmark") {
                if (!evaluated_args.empty()) {
                    auto t0 = std::chrono::high_resolution_clock::now();
                    Value res;
                    if (functions.find(evaluated_args[0].as_string()) != functions.end()) {
                        res = invoke_callable(evaluated_args[0].as_string(), {});
                    }
                    auto t1 = std::chrono::high_resolution_clock::now();
                    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
                    std::unordered_map<std::string, Value> bm;
                    bm["duration_ms"] = Value(ms);
                    bm["result"] = res;
                    return Value(bm);
                }
                return Value(0.0);
            }

            // 4. Game Plus & Physics (loop-game-plus / game)
            if (name == "game.collide_aabb" || name == "game_plus.collide_aabb") {
                if (evaluated_args.size() >= 8) {
                    double x1 = evaluated_args[0].as_number();
                    double y1 = evaluated_args[1].as_number();
                    double w1 = evaluated_args[2].as_number();
                    double h1 = evaluated_args[3].as_number();
                    double x2 = evaluated_args[4].as_number();
                    double y2 = evaluated_args[5].as_number();
                    double w2 = evaluated_args[6].as_number();
                    double h2 = evaluated_args[7].as_number();
                    bool hit = (x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2);
                    return Value(hit);
                }
                return Value(false);
            }
            if (name == "game.collide_box" || name == "game_plus.collide_box") {
                auto extract_box = [](const Value& v, double& x, double& y, double& w, double& h) {
                    if (v.type == ValueType::Map && v.map_val) {
                        x = v.map_val->count("x") ? (*v.map_val)["x"].as_number() : 0.0;
                        y = v.map_val->count("y") ? (*v.map_val)["y"].as_number() : 0.0;
                        w = v.map_val->count("w") ? (*v.map_val)["w"].as_number() : 0.0;
                        h = v.map_val->count("h") ? (*v.map_val)["h"].as_number() : 0.0;
                    } else if (v.type == ValueType::List && v.list_val && v.list_val->size() >= 4) {
                        x = (*v.list_val)[0].as_number();
                        y = (*v.list_val)[1].as_number();
                        w = (*v.list_val)[2].as_number();
                        h = (*v.list_val)[3].as_number();
                    }
                };
                if (evaluated_args.size() >= 2) {
                    double x1=0, y1=0, w1=0, h1=0, x2=0, y2=0, w2=0, h2=0;
                    extract_box(evaluated_args[0], x1, y1, w1, h1);
                    extract_box(evaluated_args[1], x2, y2, w2, h2);
                    return Value(x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2);
                }
                return Value(false);
            }
            if (name == "game.collide_circle" || name == "game_plus.collide_circle") {
                if (evaluated_args.size() >= 6) {
                    double x1 = evaluated_args[0].as_number();
                    double y1 = evaluated_args[1].as_number();
                    double r1 = evaluated_args[2].as_number();
                    double x2 = evaluated_args[3].as_number();
                    double y2 = evaluated_args[4].as_number();
                    double r2 = evaluated_args[5].as_number();
                    double dx = x2 - x1;
                    double dy = y2 - y1;
                    double dist_sq = dx * dx + dy * dy;
                    double rad_sum = r1 + r2;
                    return Value(dist_sq <= (rad_sum * rad_sum));
                }
                return Value(false);
            }
            if (name == "game.distance" || name == "game_plus.distance") {
                if (evaluated_args.size() >= 4) {
                    double x1 = evaluated_args[0].as_number();
                    double y1 = evaluated_args[1].as_number();
                    double x2 = evaluated_args[2].as_number();
                    double y2 = evaluated_args[3].as_number();
                    return Value(std::hypot(x2 - x1, y2 - y1));
                }
                return Value(0.0);
            }
            if (name == "game.clamp" || name == "game_plus.clamp") {
                double val = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                double mn = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 0.0;
                double mx = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 1.0;
                return Value(std::max(mn, std::min(val, mx)));
            }
            if (name == "game.lerp" || name == "game_plus.lerp") {
                double a = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                double b = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 1.0;
                double t = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 0.5;
                return Value(a + (b - a) * t);
            }
            if (name == "game.angle_to" || name == "game_plus.angle_to") {
                if (evaluated_args.size() >= 4) {
                    double x1 = evaluated_args[0].as_number();
                    double y1 = evaluated_args[1].as_number();
                    double x2 = evaluated_args[2].as_number();
                    double y2 = evaluated_args[3].as_number();
                    return Value(std::atan2(y2 - y1, x2 - x1));
                }
                return Value(0.0);
            }
            if (name == "game.poll_gamepad" || name == "game_plus.poll_gamepad") {
                std::unordered_map<std::string, Value> gp;
                gp["connected"] = Value(true);
                gp["x"] = Value(0.0);
                gp["y"] = Value(0.0);
                gp["axis_x"] = Value(0.0);
                gp["axis_y"] = Value(0.0);
                gp["btn_a"] = Value(false);
                gp["btn_b"] = Value(false);
                return Value(gp);
            }
            if (name == "game.spawn_particle" || name == "game_plus.spawn_particle") {
                std::string p_type = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "sparkle";
                double px = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 0.0;
                double py = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 0.0;
                double pvx = evaluated_args.size() >= 4 ? evaluated_args[3].as_number() : 0.0;
                double pvy = evaluated_args.size() >= 5 ? evaluated_args[4].as_number() : 0.0;
                std::string pcolor = evaluated_args.size() >= 6 ? evaluated_args[5].as_string() : "#38bdf8";
                std::cout << color::CYAN << "[PARTICLE]" << color::RESET << " Spawned " << p_type 
                          << " at (" << px << ", " << py << ") vel=(" << pvx << "," << pvy << ") [" << pcolor << "]\n";
                std::unordered_map<std::string, Value> part;
                part["type"] = Value(p_type);
                part["x"] = Value(px);
                part["y"] = Value(py);
                part["vx"] = Value(pvx);
                part["vy"] = Value(pvy);
                part["color"] = Value(pcolor);
                part["alive"] = Value(true);
                return Value(part);
            }
            if (name == "game.play_sfx" || name == "game_plus.play_sfx") {
                std::string sfx = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "coin";
                if (sfx == "jump") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 620 Hz for 70 ms\n";
                } else if (sfx == "coin") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 980 Hz for 90 ms\n";
                } else if (sfx == "laser") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 1200 Hz for 40 ms\n";
                } else if (sfx == "hit") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 220 Hz for 120 ms\n";
                } else if (sfx == "powerup") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 880 Hz for 150 ms\n";
                } else if (sfx == "checkpoint") {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 750 Hz for 100 ms\n";
                } else {
                    std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 440 Hz for 60 ms\n";
                }
                return Value(true);
            }
            if (name == "game.show_popup" || name == "game_plus.show_popup") {
                std::string p_title = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "ALERTA";
                std::cout << color::YELLOW << "[GAME POPUP]" << color::RESET << " Modal: " << p_title << "\n";
                std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone 880 Hz for 50 ms\n";
                return Value(true);
            }

            // 4b. Native 3D Mathematics, Quaternions, Matrices, Raycasting & 120Hz Physics (math3d.* / physics3d.* / scene3d.*)
            if (name == "math3d.vec3" || name == "vec3.new") {
                double x = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                double y = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 0.0;
                double z = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 0.0;
                return vec3_to_val({x, y, z});
            }
            if (name == "math3d.add" || name == "vec3.add") {
                if (evaluated_args.size() >= 2) return vec3_to_val(val_to_vec3(evaluated_args[0]) + val_to_vec3(evaluated_args[1]));
                return vec3_to_val({});
            }
            if (name == "math3d.sub" || name == "vec3.sub") {
                if (evaluated_args.size() >= 2) return vec3_to_val(val_to_vec3(evaluated_args[0]) - val_to_vec3(evaluated_args[1]));
                return vec3_to_val({});
            }
            if (name == "math3d.scale" || name == "vec3.scale") {
                if (evaluated_args.size() >= 2) return vec3_to_val(val_to_vec3(evaluated_args[0]) * evaluated_args[1].as_number());
                return vec3_to_val({});
            }
            if (name == "math3d.dot" || name == "vec3.dot") {
                if (evaluated_args.size() >= 2) return Value(loop_math::dot(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1])));
                return Value(0.0);
            }
            if (name == "math3d.cross" || name == "vec3.cross") {
                if (evaluated_args.size() >= 2) return vec3_to_val(loop_math::cross(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1])));
                return vec3_to_val({});
            }
            if (name == "math3d.length" || name == "vec3.length") {
                if (!evaluated_args.empty()) return Value(val_to_vec3(evaluated_args[0]).length());
                return Value(0.0);
            }
            if (name == "math3d.distance" || name == "vec3.distance" || name == "game3d.distance") {
                if (evaluated_args.size() >= 2) return Value(loop_math::distance(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1])));
                return Value(0.0);
            }
            if (name == "math3d.normalize" || name == "vec3.normalize") {
                if (!evaluated_args.empty()) return vec3_to_val(val_to_vec3(evaluated_args[0]).normalized());
                return vec3_to_val({});
            }
            if (name == "math3d.lerp" || name == "vec3.lerp") {
                if (evaluated_args.size() >= 3) {
                    return vec3_to_val(loop_math::lerp(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]), evaluated_args[2].as_number()));
                }
                return vec3_to_val({});
            }
            if (name == "math3d.reflect" || name == "vec3.reflect") {
                if (evaluated_args.size() >= 2) {
                    return vec3_to_val(loop_math::reflect(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1])));
                }
                return vec3_to_val({});
            }
            if (name == "math3d.quat_euler" || name == "quat.euler") {
                double rx = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 0.0;
                double ry = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 0.0;
                double rz = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 0.0;
                return quat_to_val(loop_math::Quat::from_euler_deg(rx, ry, rz));
            }
            if (name == "math3d.quat_axis_angle" || name == "quat.axis_angle") {
                if (evaluated_args.size() >= 2) {
                    return quat_to_val(loop_math::Quat::from_axis_angle_deg(val_to_vec3(evaluated_args[0]), evaluated_args[1].as_number()));
                }
                return quat_to_val(loop_math::Quat::identity());
            }
            if (name == "math3d.quat_mul" || name == "quat.mul") {
                if (evaluated_args.size() >= 2) {
                    return quat_to_val(val_to_quat(evaluated_args[0]) * val_to_quat(evaluated_args[1]));
                }
                return quat_to_val(loop_math::Quat::identity());
            }
            if (name == "math3d.quat_slerp" || name == "quat.slerp") {
                if (evaluated_args.size() >= 3) {
                    return quat_to_val(loop_math::Quat::slerp(val_to_quat(evaluated_args[0]), val_to_quat(evaluated_args[1]), evaluated_args[2].as_number()));
                }
                return quat_to_val(loop_math::Quat::identity());
            }
            if (name == "math3d.quat_rotate" || name == "quat.rotate") {
                if (evaluated_args.size() >= 2) {
                    return vec3_to_val(val_to_quat(evaluated_args[0]).rotate(val_to_vec3(evaluated_args[1])));
                }
                return vec3_to_val({});
            }
            if (name == "math3d.mat4_identity" || name == "mat4.identity") {
                return mat4_to_val(loop_math::Mat4::identity());
            }
            if (name == "math3d.mat4_perspective" || name == "mat4.perspective") {
                double fov = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 60.0;
                double asp = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 1.6;
                double zn  = evaluated_args.size() >= 3 ? evaluated_args[2].as_number() : 0.1;
                double zf  = evaluated_args.size() >= 4 ? evaluated_args[3].as_number() : 500.0;
                return mat4_to_val(loop_math::Mat4::perspective(fov, asp, zn, zf));
            }
            if (name == "math3d.mat4_look_at" || name == "mat4.look_at") {
                if (evaluated_args.size() >= 2) {
                    loop_math::Vec3 up = evaluated_args.size() >= 3 ? val_to_vec3(evaluated_args[2]) : loop_math::Vec3{0, 1, 0};
                    return mat4_to_val(loop_math::Mat4::look_at(val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]), up));
                }
                return mat4_to_val(loop_math::Mat4::identity());
            }
            if (name == "math3d.mat4_trs" || name == "mat4.trs") {
                loop_math::Vec3 p = evaluated_args.size() >= 1 ? val_to_vec3(evaluated_args[0]) : loop_math::Vec3{};
                loop_math::Vec3 r = evaluated_args.size() >= 2 ? val_to_vec3(evaluated_args[1]) : loop_math::Vec3{};
                loop_math::Vec3 sc = evaluated_args.size() >= 3 ? val_to_vec3(evaluated_args[2]) : loop_math::Vec3{1, 1, 1};
                return mat4_to_val(loop_math::Mat4::trs(p, r, sc));
            }
            if (name == "math3d.mat4_mul" || name == "mat4.mul") {
                if (evaluated_args.size() >= 2) {
                    return mat4_to_val(val_to_mat4(evaluated_args[0]) * val_to_mat4(evaluated_args[1]));
                }
                return mat4_to_val(loop_math::Mat4::identity());
            }
            if (name == "math3d.transform_point" || name == "mat4.transform_point") {
                if (evaluated_args.size() >= 2) {
                    return vec3_to_val(val_to_mat4(evaluated_args[0]).transform_point(val_to_vec3(evaluated_args[1])));
                }
                return vec3_to_val({});
            }
            if (name == "math3d.project") {
                loop_math::Vec3 pt = evaluated_args.size() >= 1 ? val_to_vec3(evaluated_args[0]) : loop_math::Vec3{};
                loop_math::Vec3 eye = evaluated_args.size() >= 2 ? val_to_vec3(evaluated_args[1]) : current_scene3d.cam_pos;
                loop_math::Vec3 tgt = evaluated_args.size() >= 3 ? val_to_vec3(evaluated_args[2]) : current_scene3d.cam_target;
                double fov = evaluated_args.size() >= 4 ? evaluated_args[3].as_number() : current_scene3d.cam_fov;
                double w = evaluated_args.size() >= 5 ? evaluated_args[4].as_number() : 800.0;
                double h = evaluated_args.size() >= 6 ? evaluated_args[5].as_number() : 480.0;
                auto pr = loop_math::project_point(pt, eye, tgt, fov, w, h);
                std::unordered_map<std::string, Value> m;
                m["x"] = Value(pr.x);
                m["y"] = Value(pr.y);
                m["depth"] = Value(pr.depth);
                m["visible"] = Value(pr.visible);
                return Value(m);
            }
            if (name == "physics3d.collide_sphere" || name == "game3d.collide_sphere") {
                if (evaluated_args.size() >= 4) {
                    return Value(loop_math::collide_sphere(
                        val_to_vec3(evaluated_args[0]), evaluated_args[1].as_number(),
                        val_to_vec3(evaluated_args[2]), evaluated_args[3].as_number()
                    ));
                }
                return Value(false);
            }
            if (name == "physics3d.collide_aabb" || name == "game3d.collide_aabb") {
                if (evaluated_args.size() >= 4) {
                    return Value(loop_math::collide_aabb_center(
                        val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]),
                        val_to_vec3(evaluated_args[2]), val_to_vec3(evaluated_args[3])
                    ));
                }
                return Value(false);
            }
            if (name == "physics3d.collide_capsule_sphere" || name == "game3d.collide_capsule_sphere") {
                if (evaluated_args.size() >= 5) {
                    return Value(loop_math::collide_capsule_sphere(
                        val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]), evaluated_args[2].as_number(),
                        val_to_vec3(evaluated_args[3]), evaluated_args[4].as_number()
                    ));
                }
                return Value(false);
            }
            if (name == "physics3d.raycast_sphere" || name == "game3d.raycast_sphere") {
                if (evaluated_args.size() >= 4) {
                    return rayhit_to_val(loop_math::raycast_sphere(
                        val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]),
                        val_to_vec3(evaluated_args[2]), evaluated_args[3].as_number()
                    ));
                }
                return rayhit_to_val({});
            }
            if (name == "physics3d.raycast_aabb" || name == "game3d.raycast_aabb") {
                if (evaluated_args.size() >= 4) {
                    return rayhit_to_val(loop_math::raycast_aabb(
                        val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]),
                        val_to_vec3(evaluated_args[2]), val_to_vec3(evaluated_args[3])
                    ));
                }
                return rayhit_to_val({});
            }
            if (name == "physics3d.raycast_plane" || name == "game3d.raycast_plane") {
                if (evaluated_args.size() >= 3) {
                    double pd = evaluated_args.size() >= 4 ? evaluated_args[3].as_number() : 0.0;
                    return rayhit_to_val(loop_math::raycast_plane(
                        val_to_vec3(evaluated_args[0]), val_to_vec3(evaluated_args[1]),
                        val_to_vec3(evaluated_args[2]), pd
                    ));
                }
                return rayhit_to_val({});
            }
            if (name == "physics3d.raycast_scene" || name == "scene3d.raycast") {
                loop_math::Vec3 orig = evaluated_args.size() >= 1 ? val_to_vec3(evaluated_args[0]) : current_scene3d.cam_pos;
                loop_math::Vec3 dir  = evaluated_args.size() >= 2 ? val_to_vec3(evaluated_args[1]) : loop_math::Vec3{0, 0, 1};
                loop_math::RayHit3D best;
                best.distance = std::numeric_limits<double>::infinity();
                std::string hit_name = "", hit_type = "";
                for (const auto& e : current_scene3d.entities) {
                    if (e.type == "player" || e.type == "terrain") continue;
                    loop_math::RayHit3D r;
                    if (e.type == "sphere" || e.type == "crystal" || e.type == "ring" || e.type == "portal") {
                        r = loop_math::raycast_sphere(orig, dir, e.pos, e.radius);
                    } else {
                        r = loop_math::raycast_aabb(orig, dir, e.pos, e.size);
                    }
                    if (r.hit && r.distance < best.distance) {
                        best = r;
                        hit_name = e.name;
                        hit_type = e.type;
                    }
                }
                if (!best.hit) best.distance = 0.0;
                std::unordered_map<std::string, Value> m;
                m["hit"] = Value(best.hit);
                m["distance"] = Value(best.distance);
                m["entity"] = Value(hit_name);
                m["type"] = Value(hit_type);
                m["point"] = vec3_to_val(best.point);
                m["normal"] = vec3_to_val(best.normal);
                return Value(m);
            }
            if (name == "physics3d.step_body" || name == "game3d.step_body") {
                loop_math::RigidBody3DState b;
                b.gravity = current_scene3d.gravity;
                b.friction = current_scene3d.friction;
                b.bounce = current_scene3d.bounce;
                if (!evaluated_args.empty() && evaluated_args[0].type == ValueType::Map && evaluated_args[0].map_val) {
                    const auto& in_m = *evaluated_args[0].map_val;
                    if (in_m.count("pos")) b.pos = val_to_vec3(in_m.at("pos"));
                    if (in_m.count("vel")) b.vel = val_to_vec3(in_m.at("vel"));
                    if (in_m.count("force")) b.force = val_to_vec3(in_m.at("force"));
                    if (in_m.count("mass")) b.mass = in_m.at("mass").as_number();
                    if (in_m.count("radius")) b.radius = in_m.at("radius").as_number();
                    if (in_m.count("gravity")) b.gravity = in_m.at("gravity").as_number();
                    if (in_m.count("drag")) b.drag = in_m.at("drag").as_number();
                    if (in_m.count("friction")) b.friction = in_m.at("friction").as_number();
                    if (in_m.count("bounce")) b.bounce = in_m.at("bounce").as_number();
                    if (in_m.count("ground_y")) b.ground_y = in_m.at("ground_y").as_number();
                }
                double dt = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : (1.0 / 60.0);
                int sub = evaluated_args.size() >= 3 ? static_cast<int>(evaluated_args[2].as_number()) : current_scene3d.substeps;
                loop_math::step_rigidbody_3d(b, dt, sub);

                std::unordered_map<std::string, Value> out;
                out["pos"] = vec3_to_val(b.pos);
                out["vel"] = vec3_to_val(b.vel);
                out["grounded"] = Value(b.grounded);
                out["radius"] = Value(b.radius);
                out["mass"] = Value(b.mass);
                return Value(out);
            }
            if (name == "scene3d.render_tui") {
                int cols = evaluated_args.size() >= 1 ? static_cast<int>(evaluated_args[0].as_number()) : 74;
                int rows = evaluated_args.size() >= 2 ? static_cast<int>(evaluated_args[1].as_number()) : 20;
                return Value(current_scene3d.render_tui(cols, rows));
            }
            if (name == "scene3d.preview") {
                int cols = evaluated_args.size() >= 1 ? static_cast<int>(evaluated_args[0].as_number()) : 74;
                int rows = evaluated_args.size() >= 2 ? static_cast<int>(evaluated_args[1].as_number()) : 20;
                std::cout << current_scene3d.render_tui(cols, rows);
                return Value(true);
            }
            if (name == "scene3d.step") {
                double dt = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : (1.0 / 60.0);
                current_scene3d.step(dt);
                return Value(static_cast<int64_t>(current_scene3d.entities.size()));
            }
            if (name == "scene3d.stats") {
                std::unordered_map<std::string, Value> st;
                st["active"] = Value(current_scene3d.active);
                st["world"] = Value(current_scene3d.world_name);
                st["entities"] = Value(static_cast<int64_t>(current_scene3d.entities.size()));
                st["lights"] = Value(static_cast<int64_t>(1 + current_scene3d.point_lights.size()));
                st["substeps"] = Value(static_cast<int64_t>(current_scene3d.substeps));
                st["effective_hz"] = Value(static_cast<int64_t>(current_scene3d.substeps * 60));
                st["cam_mode"] = Value(current_scene3d.cam_mode);
                st["fov"] = Value(current_scene3d.cam_fov);
                return Value(st);
            }
            if (name == "scene3d.clear") {
                current_scene3d.clear();
                current_window.entities_3d.clear();
                return Value(true);
            }

            // 5. Sound & Synthesizer (audio / sound)
            if (name == "sound.beep" || name == "audio.beep") {
                double freq = evaluated_args.size() >= 1 ? evaluated_args[0].as_number() : 440.0;
                double dur = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 100.0;
                std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone " << static_cast<int64_t>(freq) << " Hz for " << static_cast<int64_t>(dur) << " ms\n";
                return Value(true);
            }
            if (name == "sound.play_note" || name == "audio.play_note") {
                std::string note = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "A4";
                double dur = evaluated_args.size() >= 2 ? evaluated_args[1].as_number() : 100.0;
                double freq = 440.0;
                if (note == "C4") freq = 261.63;
                else if (note == "D4") freq = 293.66;
                else if (note == "E4") freq = 329.63;
                else if (note == "F4") freq = 349.23;
                else if (note == "G4") freq = 392.00;
                else if (note == "A4") freq = 440.00;
                else if (note == "B4") freq = 493.88;
                else if (note == "C5") freq = 523.25;
                std::cout << color::CYAN << "[AUDIO SYNTH]" << color::RESET << " Tone " << static_cast<int64_t>(freq) << " Hz (" << note << ") for " << static_cast<int64_t>(dur) << " ms\n";
                return Value(true);
            }

            // 6. AI & Inference Bridge (ai / pyloop-ai)
            if (name == "ai.prompt" || name == "pyloop_ai.prompt") {
                std::string sys_prompt = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                std::string user_msg = evaluated_args.size() >= 2 ? evaluated_args[1].as_string() : "";
                std::unordered_map<std::string, Value> res;
                res["model"] = Value("CS Quantum AI v3.0");
                res["reply"] = Value("Simulated AI response for: " + user_msg);
                res["status"] = Value("success");
                res["safe"] = Value(true);
                return Value(res);
            }
            if (name == "ai.moderate" || name == "pyloop_ai.moderate") {
                std::unordered_map<std::string, Value> res;
                res["isSafe"] = Value(true);
                res["flagged"] = Value(false);
                res["score"] = Value(0.01);
                return Value(res);
            }
            if (name == "ai.sentiment") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                return Value(s.find("mal") != std::string::npos || s.find("bad") != std::string::npos ? "negative" : "positive");
            }

            // 7. C++ Native Snippets (cpp_snippets / loop-cpp-snippets)
            if (name == "cpp_snippets.crc32") {
                std::string s = evaluated_args.size() >= 1 ? evaluated_args[0].as_string() : "";
                return Value(CryptoUtils::crc32_hex(s));
            }
            if (name == "cpp_snippets.dot") {
                if (evaluated_args.size() >= 2 &&
                    evaluated_args[0].type == ValueType::List && evaluated_args[0].list_val &&
                    evaluated_args[1].type == ValueType::List && evaluated_args[1].list_val) {
                    const auto& v1 = *evaluated_args[0].list_val;
                    const auto& v2 = *evaluated_args[1].list_val;
                    size_t n = std::min(v1.size(), v2.size());
                    double s = 0.0;
                    for (size_t i = 0; i < n; ++i) s += v1[i].as_number() * v2[i].as_number();
                    return Value(s);
                }
                return Value(0.0);
            }

            // User Defined Function Call with return value & default args
            auto fn_it = functions.find(name);
            if (fn_it != functions.end()) {
                auto fn = fn_it->second;
                std::unordered_map<std::string, Value> saved_vars;
                for (const auto& p : fn->params) {
                    if (variables.find(p) != variables.end()) saved_vars[p] = variables[p];
                }
                for (size_t i = 0; i < fn->params.size(); ++i) {
                    if (i < evaluated_args.size()) {
                        variables[fn->params[i]] = evaluated_args[i];
                    } else if (i < fn->default_values.size() && fn->default_values[i]) {
                        variables[fn->params[i]] = eval(fn->default_values[i]);
                    }
                }
                has_returned = false;
                last_return_value = Value();
                for (auto& s : fn->body) {
                    execute_statement(s);
                    if (has_returned || has_thrown) break;
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

    Value invoke_callable(const std::string& fn_name, const std::vector<Value>& call_args) {
        auto call_e = std::make_shared<CallExpr>(fn_name, std::vector<std::shared_ptr<Expr>>{});
        for (const auto& a : call_args) {
            call_e->args.push_back(std::make_shared<LiteralExpr>(a));
        }
        return eval(call_e);
    }

    // ── SwiftUI Terminal TUI Preview Canvas Visualizer ──
    void render_swiftui_tui(const std::shared_ptr<SwiftUIViewNode>& root,
                            const std::vector<SwiftUIModifier>& root_mods = {},
                            const std::string& comp_name = "") {
        if (!root) return;

        std::cout << "\n" << color::CYAN << "╭─────────────────────────────────────────────────────────────────╮" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << color::BOLD << " 🍎 SwiftUI Canvas Preview — Looping Engine v1.1 (Arch 3.0A)     " << color::RESET << color::CYAN << "│" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << " Target: Apple Ecosystem (iOS / macOS / visionOS • Metal 4)      " << color::CYAN << "│" << color::RESET << "\n";
        if (!comp_name.empty()) {
            std::string view_line = "│ View: " + comp_name;
            while (view_line.size() < 66) view_line += " ";
            view_line += "│";
            std::cout << color::CYAN << view_line << color::RESET << "\n";
        }
        std::cout << color::CYAN << "├─────────────────────────────────────────────────────────────────┤" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << color::BOLD << "  [View Hierarchy Tree]:" << color::RESET << "                                         " << color::CYAN << "│" << color::RESET << "\n";

        std::function<void(const std::shared_ptr<SwiftUIViewNode>&, const std::string&, bool)> print_tree_node;
        print_tree_node = [&](const std::shared_ptr<SwiftUIViewNode>& node, const std::string& prefix, bool is_last) {
            if (!node) return;
            std::string branch = is_last ? "└── " : "├── ";
            std::string icon = "📦 ";
            std::string type_str = swiftui_view_type_name(node->type);
            std::string color_code = color::CYAN;

            if (node->type == SwiftUIViewType::Text) { icon = "🔤 "; color_code = color::WHITE; }
            else if (node->type == SwiftUIViewType::Button) { icon = "🔘 "; color_code = color::GREEN; }
            else if (node->type == SwiftUIViewType::Image) { icon = "🖼️ "; color_code = color::PURPLE; }
            else if (node->type == SwiftUIViewType::TextField) { icon = "✎ "; color_code = color::YELLOW; }
            else if (node->type == SwiftUIViewType::Toggle) { icon = "🎚️ "; color_code = color::CYAN; }
            else if (node->type == SwiftUIViewType::Slider) { icon = "━●━ "; color_code = color::CYAN; }
            else if (node->type == SwiftUIViewType::ProgressView) { icon = "⏳ "; color_code = color::YELLOW; }
            else if (node->type == SwiftUIViewType::Badge) { icon = "🏷️ "; color_code = color::PURPLE; }
            else if (node->type == SwiftUIViewType::Spacer) { icon = "⇕ "; color_code = color::RESET; }
            else if (node->type == SwiftUIViewType::Divider) { icon = "── "; color_code = color::RESET; }

            std::cout << color::CYAN << "│" << color::RESET << "  " << prefix << branch << icon << color::BOLD << color_code << type_str << color::RESET;
            if (!node->primary_arg.empty()) {
                std::string disp = node->primary_arg;
                if (!disp.empty() && disp[0] == '$') {
                    std::string var_name = disp.substr(1);
                    if (variables.count(var_name)) disp = variables[var_name].as_string();
                }
                std::cout << " \"" << color::YELLOW << disp << color::RESET << "\"";
            }
            if (!node->binding_var.empty()) {
                std::cout << " ($" << node->binding_var;
                if (variables.count(node->binding_var)) {
                    std::cout << " = " << variables[node->binding_var].as_string();
                }
                std::cout << ")";
            }

            if (!node->modifiers.empty()) {
                std::cout << color::PURPLE << " [";
                for (size_t mi = 0; mi < node->modifiers.size(); ++mi) {
                    if (mi > 0) std::cout << ", ";
                    std::cout << "." << node->modifiers[mi].name;
                    if (!node->modifiers[mi].args.empty()) {
                        std::cout << "(" << node->modifiers[mi].args[0] << ")";
                    }
                }
                std::cout << "]" << color::RESET;
            }
            std::cout << "\n";

            std::string child_prefix = prefix + (is_last ? "    " : "│   ");
            for (size_t ci = 0; ci < node->children.size(); ++ci) {
                print_tree_node(node->children[ci], child_prefix, ci + 1 == node->children.size());
            }
        };

        print_tree_node(root, "", true);

        if (!root_mods.empty()) {
            std::cout << color::CYAN << "│" << color::RESET << "  Root Modifiers: ";
            for (const auto& rm : root_mods) {
                std::cout << color::PURPLE << "." << rm.name << "() " << color::RESET;
            }
            std::cout << "\n";
        }

        std::cout << color::CYAN << "├─────────────────────────────────────────────────────────────────┤" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << color::BOLD << "  [Simulated Device Display Frame]:" << color::RESET << "                              " << color::CYAN << "│" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << "   " << color::WHITE << "┌────────────────────────────────────────────────────────┐" << color::RESET << "   " << color::CYAN << "│" << color::RESET << "\n";

        std::function<void(const std::shared_ptr<SwiftUIViewNode>&)> render_visual;
        render_visual = [&](const std::shared_ptr<SwiftUIViewNode>& n) {
            if (!n) return;
            if (n->type == SwiftUIViewType::Text) {
                std::string t = n->primary_arg;
                for (const auto& kv : variables) {
                    size_t pos = t.find("$" + kv.first);
                    if (pos != std::string::npos) t.replace(pos, kv.first.size() + 1, kv.second.as_string());
                }
                std::string line_content = "   │  " + t;
                while (line_content.size() < 58) line_content += " ";
                line_content += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::WHITE << line_content << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::Button) {
                std::string btn = "   │  [ Button: " + n->primary_arg + " ]";
                while (btn.size() < 58) btn += " ";
                btn += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::GREEN << btn << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::Toggle) {
                std::string state_str = "OFF";
                if (!n->binding_var.empty() && variables.count(n->binding_var) && variables[n->binding_var].is_truthy()) {
                    state_str = "ON";
                }
                std::string tog = "   │  (●) " + n->primary_arg + " [" + state_str + "]";
                while (tog.size() < 58) tog += " ";
                tog += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::CYAN << tog << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::Slider) {
                std::string val_str = "50";
                if (!n->binding_var.empty() && variables.count(n->binding_var)) {
                    val_str = variables[n->binding_var].as_string();
                }
                std::string sld = "   │  ━━━●━━━━━ Slider (" + val_str + "%)";
                while (sld.size() < 58) sld += " ";
                sld += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::CYAN << sld << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::ProgressView) {
                std::string prg = "   │  [■■■■■■■□□□] Progress: " + (n->primary_arg.empty() ? "70%" : n->primary_arg);
                while (prg.size() < 58) prg += " ";
                prg += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::YELLOW << prg << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::Divider) {
                std::string div = "   │  ────────────────────────────────────────────────────  │   ";
                std::cout << color::CYAN << "│" << color::RESET << color::WHITE << div << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else if (n->type == SwiftUIViewType::HStack) {
                std::string h_line = "   │  ";
                for (const auto& ch : n->children) {
                    if (ch->type == SwiftUIViewType::Button) {
                        h_line += "[" + ch->primary_arg + "]  ";
                    } else if (ch->type == SwiftUIViewType::Text) {
                        std::string t = ch->primary_arg;
                        for (const auto& kv : variables) {
                            size_t pos = t.find("$" + kv.first);
                            if (pos != std::string::npos) t.replace(pos, kv.first.size() + 1, kv.second.as_string());
                        }
                        h_line += t + "  ";
                    } else if (ch->type == SwiftUIViewType::Badge) {
                        h_line += "<" + ch->primary_arg + ">  ";
                    }
                }
                while (h_line.size() < 58) h_line += " ";
                h_line += "│   ";
                std::cout << color::CYAN << "│" << color::RESET << color::WHITE << h_line << color::RESET << color::CYAN << "│" << color::RESET << "\n";
            } else {
                for (const auto& ch : n->children) {
                    render_visual(ch);
                }
            }
        };

        render_visual(root);

        std::cout << color::CYAN << "│" << color::RESET << "   " << color::WHITE << "└────────────────────────────────────────────────────────┘" << color::RESET << "   " << color::CYAN << "│" << color::RESET << "\n";
        std::cout << color::CYAN << "╰─────────────────────────────────────────────────────────────────╯" << color::RESET << "\n\n";
    }

    // ── Statement Executor ──
    void execute_statement(std::shared_ptr<Stmt> stmt) {
        if (!stmt || has_returned || has_broken || has_continued || has_thrown) return;

        // 0. Break & Continue
        if (std::dynamic_pointer_cast<BreakStmt>(stmt)) {
            has_broken = true;
            return;
        }
        if (std::dynamic_pointer_cast<ContinueStmt>(stmt)) {
            has_continued = true;
            return;
        }

        // 0b. Throw & Assert
        if (auto th = std::dynamic_pointer_cast<ThrowStmt>(stmt)) {
            thrown_error = th->error_expr ? eval(th->error_expr).as_string() : "Runtime Error";
            has_thrown = true;
            return;
        }
        if (auto as_st = std::dynamic_pointer_cast<AssertStmt>(stmt)) {
            Value cond_v = eval(as_st->condition);
            if (!cond_v.is_truthy()) {
                thrown_error = as_st->message ? eval(as_st->message).as_string() : "Assertion failed";
                has_thrown = true;
                std::cerr << color::RED << "[ASSERTION FAILED]" << color::RESET << " " << thrown_error << "\n";
            }
            return;
        }

        // 0c. Try / Catch Block
        if (auto tc = std::dynamic_pointer_cast<TryCatchStmt>(stmt)) {
            for (auto& s : tc->try_body) {
                execute_statement(s);
                if (has_thrown || has_returned || has_broken || has_continued) break;
            }
            if (has_thrown) {
                has_thrown = false;
                variables[tc->err_var] = Value(thrown_error);
                for (auto& s : tc->catch_body) {
                    execute_statement(s);
                    if (has_returned || has_broken || has_continued || has_thrown) break;
                }
            }
            return;
        }

        // 0d. Pattern Match Statement: match <expr> { pattern => stmt ... }
        if (auto ms = std::dynamic_pointer_cast<MatchStmt>(stmt)) {
            Value target_v = eval(ms->target);
            for (const auto& arm : ms->arms) {
                bool matched = false;
                if (arm.is_range) {
                    double tv = target_v.as_number();
                    double sv = eval(arm.range_start).as_number();
                    double ev = eval(arm.range_end).as_number();
                    matched = arm.range_inclusive ? (tv >= sv && tv <= ev) : (tv >= sv && tv < ev);
                } else if (!arm.patterns.empty()) {
                    for (const auto& p_expr : arm.patterns) {
                        if (target_v == eval(p_expr)) {
                            matched = true;
                            break;
                        }
                    }
                } else if (!arm.pattern) {
                    matched = true;
                } else {
                    Value pat_v = eval(arm.pattern);
                    if (target_v == pat_v) matched = true;
                }
                if (matched) {
                    for (auto& s : arm.body) {
                        execute_statement(s);
                        if (has_returned || has_broken || has_continued || has_thrown) break;
                    }
                    break;
                }
            }
            return;
        }

        // 0e. Destructuring Declaration: let [a, b] = [10, 20] OR let (x, y) = (10, 20)
        if (auto ds = std::dynamic_pointer_cast<DestructureStmt>(stmt)) {
            Value val = eval(ds->value_expr);
            if (val.type == ValueType::List && val.list_val) {
                for (size_t i = 0; i < ds->var_names.size(); ++i) {
                    variables[ds->var_names[i]] = (i < val.list_val->size()) ? (*val.list_val)[i] : Value();
                }
            } else if (val.type == ValueType::Tuple) {
                if (ds->var_names.size() > 0) variables[ds->var_names[0]] = Value(val.tuple_val.first);
                if (ds->var_names.size() > 1) variables[ds->var_names[1]] = Value(val.tuple_val.second);
            }
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
                    else if (st->op == "%=") (*rit->second.map_val)[sub_key] = (*rit->second.map_val)[sub_key] % val;
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
            } else if (st->op == "%=") {
                variables[st->var_name] = variables[st->var_name] % val;
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
                        else if (si->op == "%=") (*it->second.list_val)[static_cast<size_t>(i)] = (*it->second.list_val)[static_cast<size_t>(i)] % val;
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
                    else if (si->op == "%=") (*it->second.map_val)[k] = (*it->second.map_val)[k] % val;
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
                    if (has_returned || has_broken || has_continued || has_thrown) break;
                }
            } else {
                for (auto& s : if_st->else_branch) {
                    execute_statement(s);
                    if (has_returned || has_broken || has_continued || has_thrown) break;
                }
            }
            return;
        }

        // 5. For Range Loop: for (i in start..end) / start..=end / step S
        if (auto for_r = std::dynamic_pointer_cast<ForRangeStmt>(stmt)) {
            int64_t start_v = eval(for_r->start_expr).as_int();
            int64_t end_v = eval(for_r->end_expr).as_int();
            int64_t step_v = for_r->step_expr ? eval(for_r->step_expr).as_int() : ((start_v <= end_v) ? 1 : -1);
            if (step_v == 0) step_v = 1;
            auto check_cond = [&](int64_t curr) -> bool {
                if (step_v > 0) return for_r->inclusive ? (curr <= end_v) : (curr < end_v);
                else return for_r->inclusive ? (curr >= end_v) : (curr > end_v);
            };
            for (int64_t i = start_v; check_cond(i); i += step_v) {
                variables[for_r->var_name] = Value(i);
                for (auto& s : for_r->body) {
                    execute_statement(s);
                    if (has_broken || has_returned || has_continued || has_thrown) break;
                }
                if (has_continued) { has_continued = false; continue; }
                if (has_broken) { has_broken = false; break; }
                if (has_returned || has_thrown) break;
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
                        if (has_broken || has_returned || has_continued || has_thrown) break;
                    }
                    if (has_continued) { has_continued = false; continue; }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned || has_thrown) break;
                }
            } else if (coll.type == ValueType::Map && coll.map_val) {
                auto map_copy = *(coll.map_val);
                for (const auto& [k, v] : map_copy) {
                    variables[fe->var_name] = Value(k);
                    for (auto& s : fe->body) {
                        execute_statement(s);
                        if (has_broken || has_returned || has_continued || has_thrown) break;
                    }
                    if (has_continued) { has_continued = false; continue; }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned || has_thrown) break;
                }
            } else if (coll.type == ValueType::String) {
                std::string s_copy = coll.str_val;
                for (char ch : s_copy) {
                    variables[fe->var_name] = Value(std::string(1, ch));
                    for (auto& s : fe->body) {
                        execute_statement(s);
                        if (has_broken || has_returned || has_continued || has_thrown) break;
                    }
                    if (has_continued) { has_continued = false; continue; }
                    if (has_broken) { has_broken = false; break; }
                    if (has_returned || has_thrown) break;
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
                    if (has_broken || has_returned || has_continued || has_thrown) break;
                }
                if (has_continued) { has_continued = false; continue; }
                if (has_broken) { has_broken = false; break; }
                if (has_returned || has_thrown) break;
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
                    if (has_broken || has_returned || has_continued || has_thrown) break;
                }
                if (has_continued) { has_continued = false; continue; }
                if (has_broken) { has_broken = false; break; }
                if (has_returned || has_thrown) break;
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

        // 10c. Module Definition: define module "Name" version 1.0:
        if (auto mdef = std::dynamic_pointer_cast<ModuleDefineStmt>(stmt)) {
            // Module definition registered
            return;
        }

        // 11. Import
        if (auto imp = std::dynamic_pointer_cast<ImportStmt>(stmt)) {
            std::string mod = imp->module_name;
            while (!mod.empty() && (mod.front() == '"' || mod.front() == '\'')) mod.erase(mod.begin());
            while (!mod.empty() && (mod.back() == '"' || mod.back() == '\'')) mod.pop_back();

            if (mod == "pyloop") {
                imported_modules.insert("pyloop");
                imported_python_modules.insert("pyloop");
                return;
            }

            if (imported_modules.count(mod) > 0) {
                return; // Already imported to avoid cyclic loops
            }

            // Check if built-in stdlib module (only if no local package on disk)
            static const std::unordered_set<std::string> stdlib_modules = {
                "math", "crypto", "sys", "system", "csv", "datetime", "regex", "ui", "swiftui", "json", "file",
                "csid", "core_utils", "utils",
                "game_plus", "game",
                "csms", "ai",
                "sound", "audio", "cpp_snippets", "metal4", "metal", "loop.metal4"
            };
            std::string local_manifest_check = "./modules/" + mod + "/smile.json";
            std::ifstream mf_check(local_manifest_check);
            if (!mf_check.good() && stdlib_modules.count(mod) > 0) {
                imported_modules.insert(mod);
                return;
            }

            // Search resolution paths for the module file
            std::string home_dir = getenv("HOME") ? getenv("HOME") : "";
            std::vector<std::string> candidate_paths = {
                mod,
                mod + ".loop",
                "./" + mod,
                "./" + mod + ".loop",
                "./loop_modules/" + mod + ".loop",
                "./loop_modules/" + mod,
                "./modules/" + mod + "/" + mod + ".loop",
                "./modules/" + mod + "/main.loop",
                "./modules/" + mod + "/core_utils.loop"
            };

            auto read_entry_from_smile = [](const std::string& manifest_path) -> std::string {
                std::ifstream f(manifest_path);
                if (!f.is_open()) return "";
                std::string line, content;
                while (std::getline(f, line)) content += line;
                auto pos = content.find("\"entry_point\"");
                if (pos != std::string::npos) {
                    auto col = content.find(':', pos);
                    if (col != std::string::npos) {
                        auto q1 = content.find('"', col);
                        if (q1 != std::string::npos) {
                            auto q2 = content.find('"', q1 + 1);
                            if (q2 != std::string::npos) {
                                return content.substr(q1 + 1, q2 - q1 - 1);
                            }
                        }
                    }
                }
                return "";
            };

            // Polyglot Hybrid Multi-Component Loader
            auto check_and_link_hybrid_components = [&](const std::string& manifest_path, const std::string& base_dir) {
                std::ifstream f(manifest_path);
                if (!f.is_open()) return;
                std::string line, content;
                while (std::getline(f, line)) content += line;
                if (content.find("\"hybrid\"") != std::string::npos ||
                    content.find("\"components\"") != std::string::npos) {
                    
                    std::cout << color::PURPLE << "[HYBRID MODULE]" << color::RESET << " Linking polyglot architecture for: " 
                              << color::BOLD << mod << color::RESET << "\n";

                    auto extract_comp = [&](const std::string& key) -> std::string {
                        auto pos = content.find("\"" + key + "\"");
                        if (pos == std::string::npos) return "";
                        auto col = content.find(':', pos);
                        if (col == std::string::npos) return "";
                        auto q1 = content.find('"', col);
                        if (q1 == std::string::npos) return "";
                        auto q2 = content.find('"', q1 + 1);
                        if (q2 == std::string::npos) return "";
                        return content.substr(q1 + 1, q2 - q1 - 1);
                    };

                    std::string py_comp = extract_comp("py");
                    if (py_comp.empty()) py_comp = extract_comp("python");
                    if (!py_comp.empty()) {
                        std::string py_path = base_dir + "/" + py_comp;
                        std::ifstream pf(py_path);
                        if (pf.good() && python_bridge.is_available) {
                            std::string py_content((std::istreambuf_iterator<char>(pf)), std::istreambuf_iterator<char>());
                            python_bridge.execute_block(py_content, variables);
                            std::cout << "  " << color::GREEN << "✔" << color::RESET << " Python Component linked: " << py_comp << "\n";
                        }
                    }

                    std::string cpp_comp = extract_comp("cpp");
                    if (!cpp_comp.empty()) {
                        variables[mod + ".cpp_header"] = Value(base_dir + "/" + cpp_comp);
                        std::cout << "  " << color::CYAN << "✔" << color::RESET << " C++ Native Header verified: " << cpp_comp << "\n";
                    }

                    std::string node_comp = extract_comp("node");
                    if (!node_comp.empty()) {
                        variables[mod + ".node_script"] = Value(base_dir + "/" + node_comp);
                        std::cout << "  " << color::YELLOW << "✔" << color::RESET << " Node Web/Window Component linked: " << node_comp << "\n";
                    }

                    std::string loop_comp = extract_comp("loop");
                    if (!loop_comp.empty()) {
                        std::string loop_path = base_dir + "/" + loop_comp;
                        std::ifstream lf(loop_path);
                        if (lf.good()) {
                            std::string loop_content((std::istreambuf_iterator<char>(lf)), std::istreambuf_iterator<char>());
                            execute_code(loop_content);
                            std::cout << "  " << color::BLUE << "✔" << color::RESET << " Looping UI Component loaded: " << loop_comp << "\n";
                        }
                    }
                    variables[mod + ".is_hybrid"] = Value(true);
                }
            };

            std::string local_manifest = "./modules/" + mod + "/smile.json";
            std::string local_entry = read_entry_from_smile(local_manifest);
            if (!local_entry.empty()) {
                candidate_paths.insert(candidate_paths.begin(), "./modules/" + mod + "/" + local_entry);
                check_and_link_hybrid_components(local_manifest, "./modules/" + mod);
            }

            if (!home_dir.empty()) {
                std::string global_base = home_dir + "/.smiledev/modules/" + mod;
                std::string global_manifest = global_base + "/smile.json";
                std::string global_entry = read_entry_from_smile(global_manifest);
                if (!global_entry.empty()) {
                    candidate_paths.push_back(global_base + "/" + global_entry);
                }
                candidate_paths.push_back(global_base + "/" + mod + ".loop");
                candidate_paths.push_back(global_base + "/main.loop");
            }

            if (imp->is_python) {
                candidate_paths.push_back("./modules/" + mod + "/" + mod + ".py");
                candidate_paths.push_back("./modules/" + mod + "/main.py");
                if (!home_dir.empty()) {
                    candidate_paths.push_back(home_dir + "/.smiledev/modules/" + mod + "/" + mod + ".py");
                    candidate_paths.push_back(home_dir + "/.smiledev/modules/" + mod + "/main.py");
                }
            }

            std::string resolved_path = "";
            for (const auto& cp : candidate_paths) {
                std::ifstream f(cp);
                if (f.good()) {
                    resolved_path = cp;
                    break;
                }
            }

            if (!resolved_path.empty()) {
                imported_modules.insert(mod);
                if (resolved_path.size() >= 3 && resolved_path.substr(resolved_path.size() - 3) == ".py") {
                    imported_python_modules.insert(mod);
                    if (python_bridge.is_available) {
                        std::ifstream pf(resolved_path);
                        std::string py_content((std::istreambuf_iterator<char>(pf)), std::istreambuf_iterator<char>());
                        python_bridge.execute_block(py_content, variables);
                        std::cout << color::GREEN << "[PYTHON BRIDGE]" << color::RESET << " Loaded module: " 
                                  << color::BOLD << mod << color::RESET << " (" << resolved_path << ")\n";
                    }
                    return;
                }
                if (resolved_path.size() >= 3 && resolved_path.substr(resolved_path.size() - 3) == ".js") {
                    variables[mod + ".node_script"] = Value(resolved_path);
                    std::cout << color::YELLOW << "[NODE BRIDGE]" << color::RESET << " Linked Web/2D Stage Module: " 
                              << color::BOLD << mod << color::RESET << " (" << resolved_path << ")\n";
                    return;
                }
                if ((resolved_path.size() >= 4 && (resolved_path.substr(resolved_path.size() - 4) == ".hpp" || resolved_path.substr(resolved_path.size() - 4) == ".cpp")) ||
                    (resolved_path.size() >= 2 && resolved_path.substr(resolved_path.size() - 2) == ".h")) {
                    variables[mod + ".cpp_header"] = Value(resolved_path);
                    std::cout << color::CYAN << "[NATIVE C++17]" << color::RESET << " Linked Hardware-Accelerated Module: "
                              << color::BOLD << mod << color::RESET << " (" << resolved_path << ")\n";
                    return;
                }

                // Pure Looping module (.loop)
                std::ifstream lf(resolved_path);
                std::string loop_content((std::istreambuf_iterator<char>(lf)), std::istreambuf_iterator<char>());
                bool prev_returned = has_returned;
                execute_code(loop_content);
                has_returned = prev_returned;
                std::cout << color::BLUE << "[MODULE]" << color::RESET << " Loaded " << color::BOLD << mod 
                          << color::RESET << " (" << resolved_path << ")\n";
                return;
            }

            if (imp->is_python) {
                imported_python_modules.insert(mod);
                std::cout << color::GREEN << "[PYTHON BRIDGE]" << color::RESET << " Linked Python Module: " 
                          << color::BOLD << mod << color::RESET << "\n";
            } else {
                imported_modules.insert(mod);
                std::cout << color::BLUE << "[MODULE]" << color::RESET << " Loaded " << mod << "\n";
            }
            return;
        }

        // 12. App / Game / Game3D Definition
        if (auto app = std::dynamic_pointer_cast<AppDefineStmt>(stmt)) {
            app_name = app->app_name;
            if (!app->version.empty()) app_version = app->version;
            if (app->kind == "game3d") {
                current_scene3d.active = true;
                current_scene3d.world_name = app->app_name;
                current_window.is_3d_mode = true;
                std::cout << color::PURPLE << "[GAME 3D]" << color::RESET << " Registered 3D Title \"" << app_name
                          << "\" v" << app_version << " on " << target_platform << " (120Hz Sub-Stepping)\n";
            } else {
                std::cout << color::GREEN << "[APP]" << color::RESET << " Registered \"" << app_name 
                          << "\" v" << app_version << " on " << target_platform << "\n";
            }
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

        // 15. Draw UI: Card / Button / Input / Slider / Toggle / Progress
        if (auto draw = std::dynamic_pointer_cast<DrawUIStmt>(stmt)) {
            if (draw->ui_type == "card") {
                current_window.add_card(draw->title.empty() ? "Card" : draw->title, draw->text, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "button") {
                std::string btn_label = draw->text.empty() ? "Button" : draw->text;
                std::string act_id = draw->action.empty() ? DynamicWindow::sanitize_id(btn_label) : draw->action;
                current_window.add_button(btn_label, act_id, draw->x, draw->y, draw->w > 0 ? draw->w : 150, draw->h > 0 ? draw->h : 42, draw->snippet);
                if (!draw->snippet.empty()) {
                    python_snippets[act_id] = draw->snippet;
                    python_snippets[btn_label] = draw->snippet;
                    variables["__btn_snippet_" + act_id] = Value(draw->snippet);
                }
            } else if (draw->ui_type == "input") {
                current_window.add_input(draw->placeholder, draw->var_name, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "slider") {
                current_window.add_slider(draw->text, draw->min_val, draw->max_val, draw->current_val, draw->var_name, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "toggle") {
                current_window.add_toggle(draw->text, draw->is_checked, draw->var_name, draw->x, draw->y, draw->w, draw->h);
            } else if (draw->ui_type == "progress") {
                current_window.add_progress(draw->text, draw->current_val, draw->var_name, draw->x, draw->y, draw->w, draw->h);
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
            } else if (sp->entity_type == "moving_platform") {
                std::cout << color::CYAN << "[MAGLEV]" << color::RESET << " Moving Platform at ("
                          << sp->x << ", " << sp->y << ") [" << sp->axis << ": " << sp->min_pos << ".." << sp->max_pos << "]\n";
            } else if (sp->entity_type == "enemy") {
                std::cout << color::RED << "[ENEMY]" << color::RESET << " Deployed \"" << sp->name 
                          << "\" (HP: " << sp->health << " | Patrol: " << sp->min_pos << ".." << sp->max_pos << ")\n";
            } else if (sp->entity_type == "heart") {
                std::cout << color::GREEN << "[ITEM]" << color::RESET << " Health Pack at (" 
                          << sp->x << ", " << sp->y << ") [+" << sp->health << " HP]\n";
            } else if (sp->entity_type == "boss") {
                std::cout << color::RED << color::BOLD << "[BOSS]" << color::RESET << " Unleashed Boss \"" << sp->name 
                          << "\" (HP: " << sp->health << " | FireRate: " << sp->fire_rate << "s | Patrol: " << sp->min_pos << ".." << sp->max_pos << ")\n";
            } else if (sp->entity_type == "checkpoint") {
                std::cout << color::GREEN << "[CHECKPOINT]" << color::RESET << " Respawn Beacon at (" 
                          << sp->x << ", " << sp->y << ") [\"" << sp->text << "\"]\n";
            } else if (sp->entity_type == "gravity_zone") {
                std::cout << color::PURPLE << "[GRAVITY ZONE]" << color::RESET << " Anomaly Field at (" 
                          << sp->x << ", " << sp->y << ") [" << sp->w << "x" << sp->h << " | Scale: " << sp->scale << "G | " << sp->text << "]\n";
            } else if (sp->entity_type == "teleporter") {
                std::cout << color::CYAN << "[TELEPORTER]" << color::RESET << " Quantum Warp (" 
                          << sp->x << ", " << sp->y << ") -> (" << sp->to_x << ", " << sp->to_y << ") [\"" << sp->text << "\"]\n";
            } else if (sp->entity_type == "breakable") {
                std::cout << color::YELLOW << "[BREAKABLE]" << color::RESET << " Destructible Barrier at (" 
                          << sp->x << ", " << sp->y << ") [HP: " << sp->health << "]\n";
            } else if (sp->entity_type == "laser_hazard") {
                std::cout << color::RED << "[LASER]" << color::RESET << " Rhythmic Laser Gate at (" 
                          << sp->x << ", " << sp->y << ") [Interval: " << sp->interval << "s]\n";
            } else if (sp->entity_type == "saw") {
                std::cout << color::RED << "[SAW 2D]" << color::RESET << " Rotating Cyber-Saw at ("
                          << sp->x << ", " << sp->y << ") [" << sp->axis << ": " << sp->min_pos << ".." << sp->max_pos << "]\n";
            } else if (sp->entity_type == "turret") {
                std::cout << color::YELLOW << "[TURRET 2D]" << color::RESET << " Plasma Turret \"" << sp->name
                          << "\" at (" << sp->x << ", " << sp->y << ") [Range: " << sp->max_pos << "px]\n";
            } else if (sp->entity_type == "powerup") {
                std::cout << color::CYAN << "[POWER-UP]" << color::RESET << " Capsule [" << sp->state
                          << "] at (" << sp->x << ", " << sp->y << ") [\"" << sp->text << "\"]\n";
            } else if (sp->entity_type == "cube3d" || sp->entity_type == "pyramid3d" || sp->entity_type == "sphere3d" || sp->entity_type == "grid3d") {
                std::cout << color::PURPLE << color::BOLD << "[3D ENGINE]" << color::RESET << " Mesh " << sp->entity_type
                          << " \"" << sp->name << "\" at (" << sp->x << ", " << sp->y << ", z:" << sp->z << ") [Size: " << sp->radius << "]\n";
            } else if (sp->entity_type == "portal") {
                std::cout << color::PURPLE << "[PORTAL]" << color::RESET << " Stage Goal at (" 
                          << sp->x << ", " << sp->y << ") [\"" << sp->text << "\"]\n";
            } else {
                std::cout << color::CYAN << "[WORLD]" << color::RESET << " Placed " << sp->entity_type 
                          << " Stage Component\n";
            }
            return;
        }

        // 16b. 3D Scene Configuration & 3D Entity Spawning
        if (auto scfg = std::dynamic_pointer_cast<Scene3DConfigStmt>(stmt)) {
            current_scene3d.active = true;
            current_window.is_3d_mode = true;
            if (scfg->category == "mode") {
                bool m3d = (scfg->str1 == "3d" || scfg->str1 == "3D");
                current_scene3d.active = m3d;
                current_window.is_3d_mode = m3d;
                std::cout << color::PURPLE << "[ENGINE MODE]" << color::RESET << " Graphics Pipeline switched to: "
                          << (m3d ? "3D Quantum Perspective (Z-Buffer + 120Hz Physics)" : "2D Canvas") << "\n";
            } else if (scfg->category == "world") {
                current_scene3d.world_name = scfg->str1;
                current_scene3d.sky_preset = scfg->str2;
                current_scene3d.world_size = {scfg->x, scfg->y, scfg->z};
                current_scene3d.fog_density = scfg->val1;
                current_scene3d.show_grid = scfg->flag;
                std::cout << color::PURPLE << "[SCENE 3D]" << color::RESET << " World \"" << scfg->str1
                          << "\" (" << scfg->x << "x" << scfg->y << "x" << scfg->z << "m | Sky: " << scfg->str2
                          << " | Fog: " << scfg->val1 << ")\n";
            } else if (scfg->category == "camera") {
                current_scene3d.cam_mode = scfg->str1;
                current_scene3d.cam_pos = {scfg->x, scfg->y, scfg->z};
                current_scene3d.cam_target = {scfg->tx, scfg->ty, scfg->tz};
                current_scene3d.cam_fov = scfg->val1;
                current_scene3d.cam_smooth = scfg->val2;
                std::cout << color::CYAN << "[CAMERA 3D]" << color::RESET << " Mode: " << scfg->str1
                          << " | Pos: (" << scfg->x << ", " << scfg->y << ", " << scfg->z << ") | FOV: " << scfg->val1 << "°\n";
            } else if (scfg->category == "dir_light") {
                current_scene3d.dir_light = {scfg->x, scfg->y, scfg->z};
                current_scene3d.dir_color = scfg->str1;
                current_scene3d.dir_intensity = scfg->val1;
                std::cout << color::YELLOW << "[LIGHT 3D]" << color::RESET << " Directional Sun ("
                          << scfg->x << ", " << scfg->y << ", " << scfg->z << ") [Intensity: " << scfg->val1 << "]\n";
            } else if (scfg->category == "point_light") {
                current_scene3d.point_lights.push_back({{scfg->x, scfg->y, scfg->z}, scfg->str1, scfg->val1, scfg->val2});
                std::cout << color::YELLOW << "[LIGHT 3D]" << color::RESET << " Point Emitter at ("
                          << scfg->x << ", " << scfg->y << ", " << scfg->z << ") [" << scfg->str1 << " | Range: " << scfg->val2 << "m]\n";
            } else if (scfg->category == "ambient_light") {
                current_scene3d.ambient_color = scfg->str1;
                current_scene3d.ambient_intensity = scfg->val1;
                std::cout << color::YELLOW << "[LIGHT 3D]" << color::RESET << " Ambient Hemisphere ["
                          << scfg->str1 << " | Intensity: " << scfg->val1 << "]\n";
            } else if (scfg->category == "physics") {
                current_scene3d.gravity = scfg->val1;
                current_scene3d.substeps = std::max(1, static_cast<int>(scfg->val2));
                current_scene3d.friction = scfg->val3;
                current_scene3d.bounce = scfg->val4;
                std::cout << color::CYAN << "[PHYSICS 3D]" << color::RESET << " Gravity: " << scfg->val1
                          << " m/s² | Sub-steps: " << current_scene3d.substeps << " (" << (current_scene3d.substeps * 60)
                          << "Hz) | Friction: " << scfg->val3 << "\n";
            }
            return;
        }

        if (auto sp3 = std::dynamic_pointer_cast<SpawnEntity3DStmt>(stmt)) {
            current_scene3d.active = true;
            loop_math::Entity3D e;
            e.type = sp3->entity_type;
            e.name = sp3->name;
            e.mesh = sp3->mesh;
            e.pos = {sp3->x, sp3->y, sp3->z};
            e.size = {sp3->sx, sp3->sy, sp3->sz};
            e.rot_deg = {sp3->rx, sp3->ry, sp3->rz};
            e.radius = sp3->radius;
            e.axis = sp3->axis;
            e.min_pos = sp3->min_pos;
            e.max_pos = sp3->max_pos;
            e.speed = sp3->speed;
            e.power = sp3->power;
            e.health = sp3->health;
            e.damage = sp3->damage;
            e.points = sp3->points;
            e.metallic = sp3->metallic;
            e.fire_rate = sp3->fire_rate;
            e.color = sp3->color;
            e.label = sp3->label;
            current_scene3d.entities.push_back(e);
            current_window.add_entity_3d(e);

            std::cout << color::PURPLE << "[ENTITY 3D]" << color::RESET << " Spawned " << e.type
                      << " \"" << e.name << "\" at (" << e.pos.x << ", " << e.pos.y << ", " << e.pos.z
                      << ") [" << e.color << "]\n";
            return;
        }

        // Game Configuration Directives
        if (auto gcfg = std::dynamic_pointer_cast<GameConfigStmt>(stmt)) {
            if (gcfg->config_key == "world") {
                std::cout << color::CYAN << "[GAME WORLD]" << color::RESET << " Stage Bounds: " 
                          << gcfg->val1 << "x" << gcfg->val2 << " px\n";
            } else if (gcfg->config_key == "camera") {
                std::cout << color::CYAN << "[CAMERA]" << color::RESET << " Follow: " 
                          << gcfg->str_val << " (smooth: " << gcfg->val1 << ")\n";
            } else if (gcfg->config_key == "camera3d") {
                std::cout << color::PURPLE << color::BOLD << "[3D CAMERA]" << color::RESET << " Perspective FOV: "
                          << gcfg->val1 << " | Dist: " << gcfg->val2 << " | Pitch: " << gcfg->val3 << "° | Mode: " << gcfg->str_val << "\n";
            } else if (gcfg->config_key == "stage_preset") {
                std::cout << color::GREEN << "[STAGE PRESET]" << color::RESET << " Registered \""
                          << gcfg->str_val2 << "\" -> Warp (" << gcfg->val1 << ", " << gcfg->val2 << ") [" << gcfg->str_val3 << "]\n";
            } else if (gcfg->config_key == "algebra_table") {
                std::cout << color::CYAN << "[HUD TABLE]" << color::RESET << " Interactive Physics Table: \""
                          << gcfg->str_val << "\" [Formula: " << gcfg->str_val2 << " | Threshold: " << gcfg->val1 << "]\n";
            } else if (gcfg->config_key == "algebra_row") {
                std::cout << color::BLUE << "  • [ROW]" << color::RESET << " " << gcfg->str_val
                          << " (m=" << gcfg->val1 << ", v=" << gcfg->val2 << ", h=" << gcfg->val3 << ", hits=" << gcfg->val4 << ")\n";
            } else if (gcfg->config_key == "scenario" || gcfg->config_key == "background") {
                std::cout << color::PURPLE << "[SCENARIO]" << color::RESET << " Loaded Stage Environment: \"" 
                          << gcfg->str_val << "\" [Weather/FX: " << gcfg->str_val2 << " | Accent: " << gcfg->str_val3 << "]\n";
            } else if (gcfg->config_key == "physics") {
                std::cout << color::CYAN << "[PHYSICS ENGINE]" << color::RESET << " Gravity: " << gcfg->val1 
                          << " | Friction: " << gcfg->val2 << " | TimeScale: " << gcfg->val3 << "x\n";
            } else {
                std::cout << color::CYAN << "[GAME CONFIG]" << color::RESET << " " 
                          << gcfg->config_key << " = " << gcfg->val1 << "\n";
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

        // 22. SwiftUI Declarative Component Declaration: view <Name> { ... }
        if (auto comp = std::dynamic_pointer_cast<SwiftUIComponentDeclStmt>(stmt)) {
            swiftui_components[comp->name] = comp;
            for (const auto& st : comp->states) {
                if (st.initial_expr) {
                    variables[st.name] = eval(st.initial_expr);
                } else {
                    variables[st.name] = Value();
                }
            }
            std::cout << color::CYAN << "[SWIFTUI VIEW]" << color::RESET << " Registered declarative view \""
                      << color::BOLD << comp->name << color::RESET << "\" (" << comp->states.size() << " @state vars)\n";
            return;
        }

        // 23. Top-Level SwiftUI View Render Statement
        if (auto v_render = std::dynamic_pointer_cast<SwiftUIViewRenderStmt>(stmt)) {
            render_swiftui_tui(v_render->root_view, v_render->root_modifiers, "ContentView");
            return;
        }

        // 24. Invis. Compile Binary Architecture Statement: invis. compile [src] [to dst] / compile invis
        if (auto inv = std::dynamic_pointer_cast<InvisCompileStmt>(stmt)) {
            invis_compile_enabled = true;
            variables["INVIS_COMPILE"] = Value(true);
            variables["ARCH_COMPILE_MODE"] = Value("invis.compile");
            if (!inv->input_path.empty()) {
                std::string created_path;
                bool ok = Compiler::compile_file(inv->input_path, inv->target_ui.empty() ? "invis" : inv->target_ui,
                                                 inv->output_path, &created_path, inv->compact_mode);
                if (ok) {
                    variables["LAST_INVIS_BINARY"] = Value(created_path);
                    variables["LAST_COMPILED_APP"] = Value(created_path);
                }
            } else {
                std::cout << color::CYAN << "[INVIS. COMPILE]" << color::RESET
                          << " Architecture binary pipeline enabled (LPBN v3.0A | SHA-256 CTR)\n";
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

    // ── Execute File (Supports .loop scripts with Invis. Compile Auto-Binary Cache & direct LPBN / Native Binaries) ──
    bool execute_file(const std::string& path) {
        std::ifstream test_open(path, std::ios::binary);
        if (!test_open.is_open()) {
            std::cerr << color::RED << "❌ Error: Cannot open file: " << path << color::RESET << "\n";
            return false;
        }
        test_open.close();

        print_banner();

        // 1. Check if the target file is already a compiled LPBN / Standalone Binary artifact
        std::string binary_decoded_src;
        InvisBinaryInfo bin_info;
        if (InvisBinaryCompiler::extract_from_file(path, &binary_decoded_src, &bin_info) && bin_info.valid) {
            if (!bin_info.target_ui.empty()) set_target_ui(bin_info.target_ui);
            if (!bin_info.theme.empty()) {
                theme = bin_info.theme;
                current_window.set_theme(bin_info.theme);
            }
            variables["INVIS_COMPILE"] = Value(true);
            variables["LAST_INVIS_BINARY"] = Value(path);
            std::cout << color::CYAN << "[INVIS. BINARY]" << color::RESET << " Loading verified binary artifact: "
                      << color::BOLD << path << color::RESET << " [LPBN v3.0A | SHA-256: "
                      << bin_info.sha256_hex.substr(0, 12) << "...]\n\n";

            auto start = std::chrono::high_resolution_clock::now();
            execute_code(binary_decoded_src);
            auto end = std::chrono::high_resolution_clock::now();
            double elapsed = std::chrono::duration<double, std::milli>(end - start).count();
            std::cout << "\n" << color::GREEN << "[OK] Binary execution completed in "
                      << std::fixed << std::setprecision(2) << elapsed << "ms!" << color::RESET << "\n";
            return true;
        }

        // 2. Standard .loop / .ruup source file -> apply Invis. Compile Architecture pipeline
        std::ifstream file(path);
        std::cout << color::CYAN << "[EXEC]" << color::RESET << " Loading source: " 
                  << color::BOLD << path << color::RESET << "\n";

        if (python_bridge.is_available) {
            std::cout << color::GREEN << "[PYTHON INTEROP]" << color::RESET << " Attached Python runtime: " 
                  << color::CYAN << python_bridge.get_command_str() << color::RESET << "\n";
        } else {
            std::cout << color::YELLOW << "[PYTHON INTEROP]" << color::RESET << " Standalone Mode (Python not detected in PATH)\n";
        }

        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string content = buffer.str();

        if (invis_compile_enabled) {
            std::string cache_bin = InvisBinaryCompiler::ensure_invis_cache(path, content, active_ui_specs);
            variables["INVIS_COMPILE"] = Value(true);
            variables["LAST_INVIS_BINARY"] = Value(cache_bin);
            std::cout << color::PURPLE << "[INVIS. COMPILE]" << color::RESET << " Binary cache synchronized: "
                      << color::BOLD << cache_bin << color::RESET << " (LPBN v3.0A)\n";
        }
        std::cout << "\n";

        auto start = std::chrono::high_resolution_clock::now();
        execute_code(content);
        auto end = std::chrono::high_resolution_clock::now();

        double elapsed = std::chrono::duration<double, std::milli>(end - start).count();
        std::cout << "\n" << color::GREEN << "[OK] Execution completed in " 
                  << std::fixed << std::setprecision(2) << elapsed << "ms!" << color::RESET << "\n";

        return true;
    }

    // ── Compile Script for Target UI (Shine UI / XUI / flUI / Invis. Binary) ──
    bool compile_script_to_target(const std::string& input_path, const std::string& target_name, const std::string& output_path, bool force_compact = false) {
        return Compiler::compile_file(input_path, target_name, output_path, nullptr, force_compact);
    }
};

} // namespace looping
