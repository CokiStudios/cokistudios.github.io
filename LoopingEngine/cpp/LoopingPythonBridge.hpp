#pragma once

#include "LoopingValue.hpp"
#include <string>
#include <vector>
#include <unordered_map>
#include <sstream>
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <array>
#include <atomic>
#include <cmath>
#include <cctype>
#include <cstring>
#include <limits>
#include <algorithm>
#include <functional>

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#define popen _popen
#define pclose _pclose
#else
#include <unistd.h>
#include <sys/wait.h>
#endif

namespace looping {

class PythonBridge {
public:
    std::string detected_exe;
    std::vector<std::string> detected_args;
    bool is_available = false;
    bool has_probed = false;

    PythonBridge() = default;

    bool ensure_detected() {
        if (!has_probed) {
            detect();
        }
        return is_available;
    }

    bool check_available() {
        return ensure_detected();
    }

    void detect() {
        has_probed = true;
#if defined(__EMSCRIPTEN__) || defined(LOOPING_NO_SUBPROCESS)
        detected_exe = "";
        detected_args.clear();
        is_available = false;
        return;
#else
        std::vector<std::pair<std::string, std::vector<std::string>>> candidates;
#if defined(_WIN32)
        candidates.push_back({"python", {}});
        candidates.push_back({"py", {"-3"}});
        candidates.push_back({"py", {}});
        candidates.push_back({"python3", {}});
#else
        candidates.push_back({"python3", {}});
        candidates.push_back({"python", {}});
        candidates.push_back({"py", {}});
#endif

        for (const auto& [exe, args] : candidates) {
            std::string cmd = exe;
            for (const auto& a : args) cmd += " " + a;
            cmd += " -c \"import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')\"";

            int status = -1;
            std::string result = run_captured_command(cmd, &status);

            // Trim
            while (!result.empty() && (result.back() == '\n' || result.back() == '\r' || result.back() == ' ')) {
                result.pop_back();
            }

            if (status == 0 && (result.rfind("3.", 0) == 0 || result.rfind("2.7", 0) == 0)) {
                detected_exe = exe;
                detected_args = args;
                is_available = true;
                return;
            }
        }
        is_available = false;
#endif
    }

    std::string get_command_str() {
        if (!ensure_detected()) return "";
        std::string s = detected_exe;
        for (const auto& a : detected_args) s += " " + a;
        return s;
    }

    // Native C++17 fast-path for pure Python math/expression evaluation (zero Python dependency)
    static bool try_native_eval(const std::string& expr,
                                const std::unordered_map<std::string, Value>& variables,
                                Value& out_val) {
        NativePyParser parser(expr, variables);
        if (!parser.parse_full(out_val)) {
            return false;
        }
        return true;
    }

    // Native C++17 fast-path for multiline Python blocks (py! { ... }, pysnippet) without spawning Python
    static bool try_native_block(const std::string& py_code,
                                 std::unordered_map<std::string, Value>& variables,
                                 std::string& out_stdout);

    // Execute multiline Python script with bidirectional variable sync
    std::string execute_block(const std::string& py_code, std::unordered_map<std::string, Value>& variables) {
        std::string native_stdout;
        if (try_native_block(py_code, variables, native_stdout)) {
            return native_stdout;
        }

        if (!ensure_detected()) {
            return "[Error: Python executable not found in PATH (and block uses features outside C++ native Python subset)]";
        }

        // Build variables JSON
        std::string vars_json = "{";
        bool first = true;
        for (const auto& [k, v] : variables) {
            if (!first) vars_json += ", ";
            first = false;
            vars_json += "\"" + k + "\": " + v.to_json();
        }
        vars_json += "}";

        std::string temp_py_path = next_temp_py_path("looping_py_block_");
        FILE* f = fopen(temp_py_path.c_str(), "w");
        if (!f) return "[Error: Cannot create temporary script]";

        std::string bootstrap =
            "import sys, json, os, math\n"
            "try:\n"
            "    looping_vars = json.loads(os.environ.get('LOOPING_VARS_JSON', '{}'))\n"
            "    for _k, _v in looping_vars.items():\n"
            "        globals()[_k] = _v\n"
            "except Exception:\n"
            "    looping_vars = {}\n"
            "\n"
            "def looping_set(key, val):\n"
            "    looping_vars[key] = val\n"
            "    globals()[key] = val\n"
            "    sys.stdout.write(f'__LOOPING_SET__:' + json.dumps({'k': str(key), 'v': val}) + '\\n')\n"
            "    sys.stdout.flush()\n"
            "\n" + py_code + "\n";

        fputs(bootstrap.c_str(), f);
        fclose(f);

#if defined(_WIN32)
        SetEnvironmentVariableA("LOOPING_VARS_JSON", vars_json.c_str());
#else
        setenv("LOOPING_VARS_JSON", vars_json.c_str(), 1);
#endif

        int status = -1;
        std::string cmd = get_command_str() + " \"" + temp_py_path + "\"";
        std::string raw_output = run_captured_command(cmd, &status);
        remove(temp_py_path.c_str());

        if (status == -127) {
            return "[Error: Failed to execute python]";
        }

        std::string stdout_clean = "";
        std::istringstream iss(raw_output);
        std::string line;
        while (std::getline(iss, line)) {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            const std::string prefix = "__LOOPING_SET__:";
            auto pos = line.find(prefix);
            if (pos != std::string::npos) {
                std::string payload = line.substr(pos + prefix.length());
                parse_and_set_var(payload, variables);
            } else {
                if (!stdout_clean.empty()) stdout_clean += "\n";
                stdout_clean += line;
            }
        }

        while (!stdout_clean.empty() && (stdout_clean.back() == '\n' || stdout_clean.back() == '\r')) {
            stdout_clean.pop_back();
        }

        return stdout_clean;
    }

    // Evaluate inline Python expression (uses native C++ fast-path first to avoid Python dependency)
    Value eval_expr(const std::string& expr, const std::unordered_map<std::string, Value>& variables) {
        Value native_res;
        if (try_native_eval(expr, variables, native_res)) {
            return native_res;
        }

        if (!ensure_detected()) return Value();

        std::string vars_json = "{";
        bool first = true;
        for (const auto& [k, v] : variables) {
            if (!first) vars_json += ", ";
            first = false;
            vars_json += "\"" + k + "\": " + v.to_json();
        }
        vars_json += "}";

#if defined(_WIN32)
        SetEnvironmentVariableA("LOOPING_VARS_JSON", vars_json.c_str());
#else
        setenv("LOOPING_VARS_JSON", vars_json.c_str(), 1);
#endif

        std::string py_script =
            "import sys, json, os, math\n"
            "v = json.loads(os.environ.get('LOOPING_VARS_JSON', '{}'))\n"
            "globals().update(v)\n"
            "try:\n"
            "    res = (" + expr + ")\n"
            "    print(json.dumps(res))\n"
            "except Exception:\n"
            "    sys.exit(1)\n";

        std::string temp_py_path = next_temp_py_path("looping_eval_");
        FILE* f = fopen(temp_py_path.c_str(), "w");
        if (!f) return Value();
        fputs(py_script.c_str(), f);
        fclose(f);

        int status = -1;
        std::string cmd = get_command_str() + " \"" + temp_py_path + "\"";
        std::string output = run_captured_command(cmd, &status);
        remove(temp_py_path.c_str());

        while (!output.empty() && (output.back() == '\n' || output.back() == '\r' || output.back() == ' ')) {
            output.pop_back();
        }

        if (status == 0 && !output.empty()) {
            return parse_json_value(output);
        }

        return Value();
    }

private:
    static std::string next_temp_py_path(const std::string& prefix) {
        static std::atomic<uint64_t> counter{0};
        uint64_t seq = ++counter;
#if defined(_WIN32)
        char tmp_dir[MAX_PATH];
        GetTempPathA(MAX_PATH, tmp_dir);
        return std::string(tmp_dir) + prefix + std::to_string(GetCurrentProcessId()) + "_" + std::to_string(seq) + ".py";
#else
        return "/tmp/" + prefix + std::to_string(getpid()) + "_" + std::to_string(seq) + ".py";
#endif
    }

    static std::string run_captured_command(const std::string& cmd, int* out_status) {
#if defined(__EMSCRIPTEN__) || defined(LOOPING_NO_SUBPROCESS)
        (void)cmd;
        if (out_status) *out_status = -127;
        return "";
#elif defined(_WIN32)
        SECURITY_ATTRIBUTES sa{};
        sa.nLength = sizeof(SECURITY_ATTRIBUTES);
        sa.bInheritHandle = TRUE;
        sa.lpSecurityDescriptor = NULL;

        HANDLE hRead = NULL, hWrite = NULL;
        if (!CreatePipe(&hRead, &hWrite, &sa, 0)) {
            if (out_status) *out_status = -127;
            return "";
        }
        SetHandleInformation(hRead, HANDLE_FLAG_INHERIT, 0);

        STARTUPINFOA si{};
        si.cb = sizeof(STARTUPINFOA);
        si.hStdOutput = hWrite;
        si.hStdError = hWrite;
        si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
        si.dwFlags |= STARTF_USESTDHANDLES;

        PROCESS_INFORMATION pi{};
        std::vector<char> cmd_buf(cmd.begin(), cmd.end());
        cmd_buf.push_back('\0');

        BOOL ok = CreateProcessA(
            NULL, cmd_buf.data(), NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi
        );
        CloseHandle(hWrite);

        if (!ok) {
            CloseHandle(hRead);
            if (out_status) *out_status = -127;
            return "";
        }

        std::string output;
        char buffer[1024];
        DWORD bytesRead = 0;
        while (ReadFile(hRead, buffer, sizeof(buffer), &bytesRead, NULL) && bytesRead > 0) {
            output.append(buffer, static_cast<size_t>(bytesRead));
        }
        CloseHandle(hRead);
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 1;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        if (out_status) *out_status = static_cast<int>(exitCode);
        return output;
#else
        std::string full_cmd = cmd + " 2>&1";
        FILE* pipe = popen(full_cmd.c_str(), "r");
        if (!pipe) {
            if (out_status) *out_status = -127;
            return "";
        }
        std::string output;
        char buffer[512];
        while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
            output += buffer;
        }
        int st = pclose(pipe);
        if (out_status) *out_status = WIFEXITED(st) ? WEXITSTATUS(st) : st;
        return output;
#endif
    }

    // Native C++ recursive-descent evaluator for safe Python math/stdlib expressions
    struct NativePyParser {
        const std::string& src;
        const std::unordered_map<std::string, Value>& vars;
        size_t pos = 0;

        NativePyParser(const std::string& s, const std::unordered_map<std::string, Value>& v)
            : src(s), vars(v) {}

        void skip_ws() {
            while (pos < src.size() && (src[pos] == ' ' || src[pos] == '\t' || src[pos] == '\r' || src[pos] == '\n')) {
                ++pos;
            }
        }

        bool match_str(const char* kw) {
            skip_ws();
            size_t len = std::strlen(kw);
            if (pos + len > src.size()) return false;
            if (src.compare(pos, len, kw) != 0) return false;
            if (std::isalpha(static_cast<unsigned char>(kw[len - 1])) || kw[len - 1] == '_') {
                if (pos + len < src.size() && (std::isalnum(static_cast<unsigned char>(src[pos + len])) || src[pos + len] == '_')) {
                    return false;
                }
            }
            pos += len;
            return true;
        }

        bool parse_full(Value& out) {
            if (!parse_ternary(out)) return false;
            skip_ws();
            return pos == src.size();
        }

        bool parse_ternary(Value& out) {
            if (!parse_or(out)) return false;
            size_t save = pos;
            if (match_str("if")) {
                Value cond;
                if (!parse_or(cond)) { pos = save; return false; }
                if (!match_str("else")) { pos = save; return false; }
                Value false_val;
                if (!parse_ternary(false_val)) { pos = save; return false; }
                out = cond.is_truthy() ? out : false_val;
            }
            return true;
        }

        bool parse_or(Value& out) {
            if (!parse_and(out)) return false;
            while (match_str("or")) {
                Value rhs;
                if (!parse_and(rhs)) return false;
                out = Value(out.is_truthy() || rhs.is_truthy());
            }
            return true;
        }

        bool parse_and(Value& out) {
            if (!parse_not(out)) return false;
            while (match_str("and")) {
                Value rhs;
                if (!parse_not(rhs)) return false;
                out = Value(out.is_truthy() && rhs.is_truthy());
            }
            return true;
        }

        bool parse_not(Value& out) {
            if (match_str("not")) {
                Value sub;
                if (!parse_not(sub)) return false;
                out = Value(!sub.is_truthy());
                return true;
            }
            return parse_cmp(out);
        }

        bool parse_cmp(Value& out) {
            if (!parse_add(out)) return false;
            skip_ws();
            if (pos < src.size()) {
                std::string op;
                if (src.compare(pos, 2, "==") == 0 || src.compare(pos, 2, "!=") == 0 ||
                    src.compare(pos, 2, "<=") == 0 || src.compare(pos, 2, ">=") == 0) {
                    op = src.substr(pos, 2);
                    pos += 2;
                } else if (src[pos] == '<' || src[pos] == '>') {
                    op = std::string(1, src[pos]);
                    ++pos;
                } else if (match_str("not")) {
                    if (!match_str("in")) return false;
                    op = "not in";
                } else if (match_str("in")) {
                    op = "in";
                } else if (match_str("is")) {
                    op = match_str("not") ? "is not" : "is";
                }
                if (!op.empty()) {
                    Value rhs;
                    if (!parse_add(rhs)) return false;
                    if (op == "==") out = Value(out == rhs);
                    else if (op == "!=") out = Value(out != rhs);
                    else if (op == "<") out = Value(out < rhs);
                    else if (op == "<=") out = Value(out <= rhs);
                    else if (op == ">") out = Value(out > rhs);
                    else if (op == ">=") out = Value(out >= rhs);
                    else if (op == "is") out = Value(out == rhs);
                    else if (op == "is not") out = Value(out != rhs);
                    else if (op == "in" || op == "not in") {
                        bool found = false;
                        if (rhs.type == ValueType::String) {
                            found = rhs.str_val.find(out.as_string()) != std::string::npos;
                        } else if (rhs.type == ValueType::List && rhs.list_val) {
                            for (const auto& el : *rhs.list_val) {
                                if (el == out) { found = true; break; }
                            }
                        } else if (rhs.type == ValueType::Map && rhs.map_val) {
                            found = rhs.map_val->count(out.as_string()) > 0;
                        } else {
                            return false;
                        }
                        out = Value(op == "in" ? found : !found);
                    }
                }
            }
            return true;
        }

        bool parse_add(Value& out) {
            if (!parse_mul(out)) return false;
            while (true) {
                skip_ws();
                if (pos >= src.size()) break;
                char c = src[pos];
                if (c != '+' && c != '-') break;
                ++pos;
                Value rhs;
                if (!parse_mul(rhs)) return false;
                out = (c == '+') ? (out + rhs) : (out - rhs);
            }
            return true;
        }

        bool parse_mul(Value& out) {
            if (!parse_unary(out)) return false;
            while (true) {
                skip_ws();
                if (pos >= src.size()) break;
                if (pos + 1 < src.size() && src[pos] == '*' && src[pos + 1] == '*') break;
                if (pos + 1 < src.size() && src[pos] == '/' && src[pos + 1] == '/') {
                    pos += 2;
                    Value rhs;
                    if (!parse_unary(rhs)) return false;
                    double b = rhs.as_number();
                    if (std::abs(b) < 1e-15) return false;
                    double q = std::floor(out.as_number() / b);
                    out = (out.type == ValueType::Int && rhs.type == ValueType::Int)
                              ? Value(static_cast<int64_t>(q))
                              : Value(q);
                    continue;
                }
                char c = src[pos];
                if (c != '*' && c != '/' && c != '%') break;
                ++pos;
                Value rhs;
                if (!parse_unary(rhs)) return false;
                if ((c == '/' || c == '%') && std::abs(rhs.as_number()) < 1e-15) return false;
                if (c == '*') out = out * rhs;
                else if (c == '/') {
                    double dv = out.as_number() / rhs.as_number();
                    out = Value(dv);
                } else {
                    out = out % rhs;
                }
            }
            return true;
        }

        bool parse_unary(Value& out) {
            skip_ws();
            if (pos < src.size() && (src[pos] == '+' || src[pos] == '-')) {
                char c = src[pos++];
                Value sub;
                if (!parse_unary(sub)) return false;
                out = (c == '-') ? (Value(0) - sub) : sub;
                return true;
            }
            return parse_pow(out);
        }

        bool parse_pow(Value& out) {
            if (!parse_primary(out)) return false;
            skip_ws();
            if (pos + 1 < src.size() && src[pos] == '*' && src[pos + 1] == '*') {
                pos += 2;
                Value exp;
                if (!parse_unary(exp)) return false;
                out = out.power(exp);
            }
            return true;
        }

        static Value make_num_val(double d, bool prefer_int = false) {
            if (prefer_int && std::isfinite(d) && std::abs(d - std::round(d)) < 1e-12 &&
                d >= -9e15 && d <= 9e15) {
                return Value(static_cast<int64_t>(std::llround(d)));
            }
            return Value(d);
        }

        bool eval_builtin_call(const std::string& fn, const std::vector<Value>& args, Value& out) {
            if (fn == "math.sqrt" && args.size() == 1) {
                double x = args[0].as_number();
                if (x < 0.0) return false;
                out = Value(std::sqrt(x));
                return true;
            }
            if (fn == "math.pow" && args.size() == 2) {
                out = Value(std::pow(args[0].as_number(), args[1].as_number()));
                return true;
            }
            if (fn == "math.sin" && args.size() == 1) { out = Value(std::sin(args[0].as_number())); return true; }
            if (fn == "math.cos" && args.size() == 1) { out = Value(std::cos(args[0].as_number())); return true; }
            if (fn == "math.tan" && args.size() == 1) { out = Value(std::tan(args[0].as_number())); return true; }
            if (fn == "math.asin" && args.size() == 1) { out = Value(std::asin(args[0].as_number())); return true; }
            if (fn == "math.acos" && args.size() == 1) { out = Value(std::acos(args[0].as_number())); return true; }
            if (fn == "math.atan" && args.size() == 1) { out = Value(std::atan(args[0].as_number())); return true; }
            if (fn == "math.atan2" && args.size() == 2) { out = Value(std::atan2(args[0].as_number(), args[1].as_number())); return true; }
            if (fn == "math.floor" && args.size() == 1) { out = make_num_val(std::floor(args[0].as_number()), true); return true; }
            if (fn == "math.ceil" && args.size() == 1) { out = make_num_val(std::ceil(args[0].as_number()), true); return true; }
            if (fn == "math.fabs" && args.size() == 1) { out = Value(std::fabs(args[0].as_number())); return true; }
            if (fn == "math.exp" && args.size() == 1) { out = Value(std::exp(args[0].as_number())); return true; }
            if (fn == "math.log" && args.size() == 1) {
                double x = args[0].as_number();
                if (x <= 0.0) return false;
                out = Value(std::log(x));
                return true;
            }
            if (fn == "math.log10" && args.size() == 1) {
                double x = args[0].as_number();
                if (x <= 0.0) return false;
                out = Value(std::log10(x));
                return true;
            }
            if (fn == "math.degrees" && args.size() == 1) { out = Value(args[0].as_number() * 180.0 / 3.14159265358979323846); return true; }
            if (fn == "math.radians" && args.size() == 1) { out = Value(args[0].as_number() * 3.14159265358979323846 / 180.0); return true; }
            if (fn == "math.hypot" && args.size() == 2) { out = Value(std::hypot(args[0].as_number(), args[1].as_number())); return true; }
            if (fn == "math.factorial" && args.size() == 1) {
                int64_t n = args[0].as_int();
                if (n < 0 || n > 20) return false;
                int64_t r = 1;
                for (int64_t k = 2; k <= n; ++k) r *= k;
                out = Value(r);
                return true;
            }
            if (fn == "round" && (args.size() == 1 || args.size() == 2)) {
                double x = args[0].as_number();
                if (args.size() == 1) {
                    out = make_num_val(std::round(x), true);
                    return true;
                }
                int digits = static_cast<int>(args[1].as_int());
                double factor = std::pow(10.0, digits);
                out = Value(std::round(x * factor) / factor);
                return true;
            }
            if (fn == "abs" && args.size() == 1) {
                if (args[0].type == ValueType::Int) out = Value(std::llabs(args[0].int_val));
                else out = Value(std::fabs(args[0].as_number()));
                return true;
            }
            if (fn == "min" && !args.empty()) {
                if (args.size() == 1 && args[0].type == ValueType::List && args[0].list_val && !args[0].list_val->empty()) {
                    Value best = (*args[0].list_val)[0];
                    for (const auto& el : *args[0].list_val) if (el < best) best = el;
                    out = best;
                    return true;
                }
                Value best = args[0];
                for (const auto& el : args) if (el < best) best = el;
                out = best;
                return true;
            }
            if (fn == "max" && !args.empty()) {
                if (args.size() == 1 && args[0].type == ValueType::List && args[0].list_val && !args[0].list_val->empty()) {
                    Value best = (*args[0].list_val)[0];
                    for (const auto& el : *args[0].list_val) if (best < el) best = el;
                    out = best;
                    return true;
                }
                Value best = args[0];
                for (const auto& el : args) if (best < el) best = el;
                out = best;
                return true;
            }
            if (fn == "int" && args.size() == 1) { out = Value(args[0].as_int()); return true; }
            if (fn == "float" && args.size() == 1) { out = Value(args[0].as_number()); return true; }
            if (fn == "bool" && args.size() == 1) { out = Value(args[0].is_truthy()); return true; }
            if (fn == "str" && args.size() == 1) { out = Value(args[0].as_string()); return true; }
            if (fn == "len" && args.size() == 1) { out = Value(static_cast<int64_t>(args[0].size())); return true; }
            if (fn == "sum" && args.size() == 1 && args[0].type == ValueType::List && args[0].list_val) {
                double s = 0.0;
                bool all_int = true;
                for (const auto& el : *args[0].list_val) {
                    if (el.type != ValueType::Int) all_int = false;
                    s += el.as_number();
                }
                out = make_num_val(s, all_int);
                return true;
            }
            if (fn == "pow" && args.size() == 2) {
                out = Value(std::pow(args[0].as_number(), args[1].as_number()));
                return true;
            }
            if (fn == "math.log2" && args.size() == 1) {
                double x = args[0].as_number();
                if (x <= 0.0) return false;
                out = Value(std::log2(x));
                return true;
            }
            if (fn == "math.isfinite" && args.size() == 1) {
                out = Value(std::isfinite(args[0].as_number()));
                return true;
            }
            if (fn == "math.isnan" && args.size() == 1) {
                out = Value(std::isnan(args[0].as_number()));
                return true;
            }
            if (fn == "range" && (args.size() >= 1 && args.size() <= 3)) {
                int64_t start_v = (args.size() == 1) ? 0 : args[0].as_int();
                int64_t stop_v = (args.size() == 1) ? args[0].as_int() : args[1].as_int();
                int64_t step_v = (args.size() == 3) ? args[2].as_int() : 1;
                if (step_v == 0) return false;
                std::vector<Value> seq;
                for (int64_t i = start_v; (step_v > 0 ? i < stop_v : i > stop_v) && seq.size() < 10000; i += step_v) {
                    seq.push_back(Value(i));
                }
                out = Value(seq);
                return true;
            }
            if (fn == "list" && args.size() == 1) {
                if (args[0].type == ValueType::List) { out = args[0]; return true; }
                if (args[0].type == ValueType::String) {
                    std::vector<Value> chars;
                    for (char c : args[0].str_val) chars.push_back(Value(std::string(1, c)));
                    out = Value(chars);
                    return true;
                }
            }
            if (fn == "sorted" && args.size() == 1 && args[0].type == ValueType::List && args[0].list_val) {
                auto copy = *args[0].list_val;
                std::sort(copy.begin(), copy.end(), [](const Value& a, const Value& b) { return a < b; });
                out = Value(copy);
                return true;
            }
            if (fn == "any" && args.size() == 1 && args[0].type == ValueType::List && args[0].list_val) {
                bool res = false;
                for (const auto& el : *args[0].list_val) if (el.is_truthy()) { res = true; break; }
                out = Value(res);
                return true;
            }
            if (fn == "all" && args.size() == 1 && args[0].type == ValueType::List && args[0].list_val) {
                bool res = true;
                for (const auto& el : *args[0].list_val) if (!el.is_truthy()) { res = false; break; }
                out = Value(res);
                return true;
            }
            if (fn == "json.dumps" && args.size() == 1) {
                out = Value(args[0].to_json());
                return true;
            }
            return false;
        }

        bool eval_method_call(const Value& recv, const std::string& meth, const std::vector<Value>& args, Value& out) {
            if (recv.type == ValueType::String) {
                const std::string& s = recv.str_val;
                if (meth == "upper" && args.empty()) {
                    std::string r = s;
                    for (char& c : r) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
                    out = Value(r);
                    return true;
                }
                if (meth == "lower" && args.empty()) {
                    std::string r = s;
                    for (char& c : r) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
                    out = Value(r);
                    return true;
                }
                if (meth == "strip" && args.empty()) {
                    size_t a = s.find_first_not_of(" \t\r\n");
                    size_t b = s.find_last_not_of(" \t\r\n");
                    out = Value((a == std::string::npos) ? std::string("") : s.substr(a, b - a + 1));
                    return true;
                }
                if (meth == "startswith" && args.size() == 1) {
                    std::string p = args[0].as_string();
                    out = Value(s.rfind(p, 0) == 0);
                    return true;
                }
                if (meth == "endswith" && args.size() == 1) {
                    std::string suf = args[0].as_string();
                    out = Value(s.size() >= suf.size() && s.compare(s.size() - suf.size(), suf.size(), suf) == 0);
                    return true;
                }
                if (meth == "replace" && args.size() == 2) {
                    std::string r = s;
                    std::string from = args[0].as_string(), to = args[1].as_string();
                    if (!from.empty()) {
                        size_t p = 0;
                        while ((p = r.find(from, p)) != std::string::npos) {
                            r.replace(p, from.size(), to);
                            p += to.size();
                        }
                    }
                    out = Value(r);
                    return true;
                }
                if (meth == "split" && args.size() <= 1) {
                    std::vector<Value> parts;
                    if (args.empty()) {
                        std::istringstream iss(s);
                        std::string tok;
                        while (iss >> tok) parts.push_back(Value(tok));
                    } else {
                        std::string sep = args[0].as_string();
                        if (sep.empty()) return false;
                        size_t prev = 0, p = 0;
                        while ((p = s.find(sep, prev)) != std::string::npos) {
                            parts.push_back(Value(s.substr(prev, p - prev)));
                            prev = p + sep.size();
                        }
                        parts.push_back(Value(s.substr(prev)));
                    }
                    out = Value(parts);
                    return true;
                }
                if (meth == "join" && args.size() == 1 && args[0].type == ValueType::List && args[0].list_val) {
                    std::string joined;
                    for (size_t i = 0; i < args[0].list_val->size(); ++i) {
                        if (i > 0) joined += s;
                        joined += (*args[0].list_val)[i].as_string();
                    }
                    out = Value(joined);
                    return true;
                }
                if (meth == "find" && args.size() == 1) {
                    size_t idx = s.find(args[0].as_string());
                    out = Value(idx == std::string::npos ? int64_t(-1) : static_cast<int64_t>(idx));
                    return true;
                }
                if (meth == "count" && args.size() == 1) {
                    std::string sub = args[0].as_string();
                    if (sub.empty()) return false;
                    int64_t cnt = 0;
                    size_t p = 0;
                    while ((p = s.find(sub, p)) != std::string::npos) { ++cnt; p += sub.size(); }
                    out = Value(cnt);
                    return true;
                }
            }
            return false;
        }

        bool parse_primary(Value& out) {
            if (!parse_atom(out)) return false;
            while (true) {
                skip_ws();
                if (pos < src.size() && src[pos] == '[') {
                    ++pos;
                    skip_ws();
                    bool is_slice = false;
                    bool has_start = false, has_end = false;
                    int64_t start_i = 0, end_i = 0;
                    if (pos < src.size() && src[pos] == ':') {
                        is_slice = true;
                        ++pos;
                    } else {
                        Value idx_v;
                        if (!parse_ternary(idx_v)) return false;
                        has_start = true;
                        start_i = idx_v.as_int();
                        skip_ws();
                        if (pos < src.size() && src[pos] == ':') {
                            is_slice = true;
                            ++pos;
                        }
                    }
                    if (is_slice) {
                        skip_ws();
                        if (pos < src.size() && src[pos] != ']') {
                            Value end_v;
                            if (!parse_ternary(end_v)) return false;
                            has_end = true;
                            end_i = end_v.as_int();
                        }
                    }
                    skip_ws();
                    if (pos >= src.size() || src[pos] != ']') return false;
                    ++pos;
                    if (!is_slice) {
                        if (out.type == ValueType::List && out.list_val) {
                            int64_t n = static_cast<int64_t>(out.list_val->size());
                            int64_t k = start_i < 0 ? (n + start_i) : start_i;
                            if (k < 0 || k >= n) return false;
                            out = (*out.list_val)[static_cast<size_t>(k)];
                        } else if (out.type == ValueType::String) {
                            int64_t n = static_cast<int64_t>(out.str_val.size());
                            int64_t k = start_i < 0 ? (n + start_i) : start_i;
                            if (k < 0 || k >= n) return false;
                            out = Value(std::string(1, out.str_val[static_cast<size_t>(k)]));
                        } else {
                            return false;
                        }
                    } else {
                        int64_t n = out.size();
                        int64_t a = has_start ? (start_i < 0 ? n + start_i : start_i) : 0;
                        int64_t b = has_end ? (end_i < 0 ? n + end_i : end_i) : n;
                        a = std::max<int64_t>(0, std::min<int64_t>(n, a));
                        b = std::max<int64_t>(0, std::min<int64_t>(n, b));
                        if (out.type == ValueType::String) {
                            out = Value(b > a ? out.str_val.substr(static_cast<size_t>(a), static_cast<size_t>(b - a)) : std::string(""));
                        } else if (out.type == ValueType::List && out.list_val) {
                            std::vector<Value> sliced;
                            for (int64_t i = a; i < b; ++i) sliced.push_back((*out.list_val)[static_cast<size_t>(i)]);
                            out = Value(sliced);
                        } else {
                            return false;
                        }
                    }
                    continue;
                }
                if (pos < src.size() && src[pos] == '.') {
                    ++pos;
                    size_t ms = pos;
                    while (pos < src.size() && (std::isalnum(static_cast<unsigned char>(src[pos])) || src[pos] == '_')) ++pos;
                    std::string meth = src.substr(ms, pos - ms);
                    if (meth.empty()) return false;
                    skip_ws();
                    if (pos >= src.size() || src[pos] != '(') return false;
                    ++pos;
                    std::vector<Value> args;
                    skip_ws();
                    if (pos < src.size() && src[pos] == ')') {
                        ++pos;
                    } else {
                        while (true) {
                            Value arg;
                            if (!parse_ternary(arg)) return false;
                            args.push_back(arg);
                            skip_ws();
                            if (pos < src.size() && src[pos] == ',') ++pos;
                            else if (pos < src.size() && src[pos] == ')') { ++pos; break; }
                            else return false;
                        }
                    }
                    if (!eval_method_call(out, meth, args, out)) return false;
                    continue;
                }
                break;
            }
            return true;
        }

        bool parse_atom(Value& out) {
            skip_ws();
            if (pos >= src.size()) return false;

            if (pos + 1 < src.size() && (src[pos] == 'f' || src[pos] == 'F') &&
                (src[pos + 1] == '"' || src[pos + 1] == '\'')) {
                ++pos;
                char q = src[pos++];
                std::string res;
                while (pos < src.size() && src[pos] != q) {
                    if (src[pos] == '\\' && pos + 1 < src.size()) {
                        char esc = src[++pos];
                        if (esc == 'n') res += '\n';
                        else if (esc == 't') res += '\t';
                        else if (esc == 'r') res += '\r';
                        else res += esc;
                        ++pos;
                    } else if (src[pos] == '{') {
                        if (pos + 1 < src.size() && src[pos + 1] == '{') {
                            res += '{';
                            pos += 2;
                            continue;
                        }
                        ++pos;
                        size_t expr_start = pos;
                        int depth = 1;
                        while (pos < src.size() && depth > 0) {
                            if (src[pos] == '{') ++depth;
                            else if (src[pos] == '}') --depth;
                            if (depth > 0) ++pos;
                        }
                        if (pos >= src.size() || src[pos] != '}') return false;
                        std::string inner = src.substr(expr_start, pos - expr_start);
                        ++pos;
                        Value ev;
                        NativePyParser sub(inner, vars);
                        if (!sub.parse_full(ev)) return false;
                        res += ev.as_string();
                    } else {
                        res += src[pos++];
                    }
                }
                if (pos >= src.size() || src[pos] != q) return false;
                ++pos;
                out = Value(res);
                return true;
            }

            if (src[pos] == '(') {
                ++pos;
                if (!parse_ternary(out)) return false;
                skip_ws();
                if (pos >= src.size() || src[pos] != ')') return false;
                ++pos;
                return true;
            }

            if (src[pos] == '[') {
                ++pos;
                std::vector<Value> elems;
                skip_ws();
                if (pos < src.size() && src[pos] == ']') {
                    ++pos;
                    out = Value(elems);
                    return true;
                }
                while (true) {
                    Value el;
                    if (!parse_ternary(el)) return false;
                    elems.push_back(el);
                    skip_ws();
                    if (pos < src.size() && src[pos] == ',') {
                        ++pos;
                        skip_ws();
                        if (pos < src.size() && src[pos] == ']') { ++pos; break; }
                    } else if (pos < src.size() && src[pos] == ']') {
                        ++pos;
                        break;
                    } else {
                        return false;
                    }
                }
                out = Value(elems);
                return true;
            }

            if (src[pos] == '"' || src[pos] == '\'') {
                char q = src[pos++];
                std::string s;
                while (pos < src.size() && src[pos] != q) {
                    if (src[pos] == '\\' && pos + 1 < src.size()) {
                        char esc = src[++pos];
                        if (esc == 'n') s += '\n';
                        else if (esc == 't') s += '\t';
                        else if (esc == 'r') s += '\r';
                        else s += esc;
                        ++pos;
                    } else {
                        s += src[pos++];
                    }
                }
                if (pos >= src.size() || src[pos] != q) return false;
                ++pos;
                out = Value(s);
                return true;
            }

            if (std::isdigit(static_cast<unsigned char>(src[pos])) ||
                (src[pos] == '.' && pos + 1 < src.size() && std::isdigit(static_cast<unsigned char>(src[pos + 1])))) {
                size_t start = pos;
                bool is_float = false;
                while (pos < src.size() && (std::isdigit(static_cast<unsigned char>(src[pos])) || src[pos] == '.')) {
                    if (src[pos] == '.') is_float = true;
                    ++pos;
                }
                if (pos < src.size() && (src[pos] == 'e' || src[pos] == 'E')) {
                    is_float = true;
                    ++pos;
                    if (pos < src.size() && (src[pos] == '+' || src[pos] == '-')) ++pos;
                    while (pos < src.size() && std::isdigit(static_cast<unsigned char>(src[pos]))) ++pos;
                }
                std::string num_s = src.substr(start, pos - start);
                try {
                    if (is_float) out = Value(std::stod(num_s));
                    else out = Value(static_cast<int64_t>(std::stoll(num_s)));
                    return true;
                } catch (...) {
                    return false;
                }
            }

            if (std::isalpha(static_cast<unsigned char>(src[pos])) || src[pos] == '_') {
                size_t start = pos;
                while (pos < src.size() && (std::isalnum(static_cast<unsigned char>(src[pos])) || src[pos] == '_' || src[pos] == '.')) {
                    ++pos;
                }
                std::string ident = src.substr(start, pos - start);
                skip_ws();
                if (pos < src.size() && src[pos] == '(') {
                    ++pos;
                    std::vector<Value> args;
                    skip_ws();
                    if (pos < src.size() && src[pos] == ')') {
                        ++pos;
                    } else {
                        while (true) {
                            Value arg;
                            if (!parse_ternary(arg)) return false;
                            args.push_back(arg);
                            skip_ws();
                            if (pos < src.size() && src[pos] == ',') {
                                ++pos;
                            } else if (pos < src.size() && src[pos] == ')') {
                                ++pos;
                                break;
                            } else {
                                return false;
                            }
                        }
                    }
                    return eval_builtin_call(ident, args, out);
                }

                if (ident == "True") { out = Value(true); return true; }
                if (ident == "False") { out = Value(false); return true; }
                if (ident == "None") { out = Value(); return true; }
                if (ident == "math.pi") { out = Value(3.14159265358979323846); return true; }
                if (ident == "math.e") { out = Value(2.71828182845904523536); return true; }
                if (ident == "math.tau") { out = Value(6.28318530717958647692); return true; }
                if (ident == "math.inf") { out = Value(std::numeric_limits<double>::infinity()); return true; }

                auto vit = vars.find(ident);
                if (vit != vars.end()) {
                    out = vit->second;
                    return true;
                }
                return false;
            }

            return false;
        }
    };

    void parse_and_set_var(const std::string& json_str, std::unordered_map<std::string, Value>& variables) {
        // e.g. {"k": "target_xp", "v": 5400}
        auto k_pos = json_str.find("\"k\":");
        auto v_pos = json_str.find("\"v\":");
        if (k_pos == std::string::npos || v_pos == std::string::npos) return;

        // Extract key
        size_t k_start = json_str.find('"', k_pos + 4);
        if (k_start == std::string::npos) return;
        size_t k_end = json_str.find('"', k_start + 1);
        if (k_end == std::string::npos) return;
        std::string key = json_str.substr(k_start + 1, k_end - k_start - 1);

        // Extract value
        size_t v_start = v_pos + 4;
        while (v_start < json_str.size() && (json_str[v_start] == ' ' || json_str[v_start] == ':')) v_start++;
        size_t v_end = json_str.find_last_not_of(" }\r\n");
        if (v_end == std::string::npos || v_end < v_start) return;
        std::string raw_v = json_str.substr(v_start, v_end - v_start + 1);

        variables[key] = parse_json_value(raw_v);
    }

    Value parse_json_value(const std::string& s) {
        std::string trimmed = s;
        while (!trimmed.empty() && (trimmed.front() == ' ' || trimmed.front() == '\t')) trimmed.erase(0, 1);
        while (!trimmed.empty() && (trimmed.back() == ' ' || trimmed.back() == '\t' || trimmed.back() == '\n' || trimmed.back() == '\r')) trimmed.pop_back();

        if (trimmed == "true") return Value(true);
        if (trimmed == "false") return Value(false);
        if (trimmed == "null" || trimmed == "None") return Value();

        if (trimmed.size() >= 2 && trimmed.front() == '"' && trimmed.back() == '"') {
            return Value(trimmed.substr(1, trimmed.size() - 2));
        }

        // Try number
        try {
            if (trimmed.find('.') != std::string::npos) {
                return Value(std::stod(trimmed));
            } else {
                return Value(static_cast<int64_t>(std::stoll(trimmed)));
            }
        } catch (...) {}

        return Value(trimmed);
    }
};

inline bool PythonBridge::try_native_block(const std::string& py_code,
                                           std::unordered_map<std::string, Value>& variables,
                                           std::string& out_stdout) {
    struct PyLine {
        int indent;
        std::string text;
    };

    auto strip_comment = [](const std::string& raw) -> std::string {
        bool in_s = false, in_d = false;
        for (size_t i = 0; i < raw.size(); ++i) {
            char c = raw[i];
            if (c == '\\' && (in_s || in_d)) { ++i; continue; }
            if (c == '\'' && !in_d) in_s = !in_s;
            else if (c == '"' && !in_s) in_d = !in_d;
            else if (c == '#' && !in_s && !in_d) return raw.substr(0, i);
        }
        return raw;
    };

    std::vector<PyLine> lines;
    std::istringstream iss(py_code);
    std::string raw_line;
    int base_indent = -1;
    while (std::getline(iss, raw_line)) {
        if (!raw_line.empty() && raw_line.back() == '\r') raw_line.pop_back();
        std::string cleaned = strip_comment(raw_line);
        size_t first_nb = cleaned.find_first_not_of(" \t");
        if (first_nb == std::string::npos) continue;
        int ind = 0;
        for (size_t i = 0; i < first_nb; ++i) ind += (cleaned[i] == '\t' ? 4 : 1);
        if (base_indent < 0) base_indent = ind;
        size_t last_nb = cleaned.find_last_not_of(" \t");
        std::string trimmed = cleaned.substr(first_nb, last_nb - first_nb + 1);
        if (!trimmed.empty()) {
            lines.push_back({std::max(0, ind - base_indent), trimmed});
        }
    }

    if (lines.empty()) {
        out_stdout.clear();
        return true;
    }

    auto vars_backup = variables;
    std::ostringstream stdout_ss;

    auto split_args = [](const std::string& inner) -> std::vector<std::string> {
        std::vector<std::string> args;
        std::string cur;
        int paren = 0, brack = 0;
        bool in_s = false, in_d = false;
        for (size_t i = 0; i < inner.size(); ++i) {
            char c = inner[i];
            if (c == '\\' && (in_s || in_d) && i + 1 < inner.size()) {
                cur += c; cur += inner[++i]; continue;
            }
            if (c == '\'' && !in_d) in_s = !in_s;
            else if (c == '"' && !in_s) in_d = !in_d;
            else if (!in_s && !in_d) {
                if (c == '(') ++paren;
                else if (c == ')') --paren;
                else if (c == '[') ++brack;
                else if (c == ']') --brack;
                else if (c == ',' && paren == 0 && brack == 0) {
                    args.push_back(cur);
                    cur.clear();
                    continue;
                }
            }
            cur += c;
        }
        if (!cur.empty()) args.push_back(cur);
        return args;
    };

    auto trim_str = [](const std::string& s) -> std::string {
        size_t a = s.find_first_not_of(" \t\r\n");
        if (a == std::string::npos) return "";
        size_t b = s.find_last_not_of(" \t\r\n");
        return s.substr(a, b - a + 1);
    };

    auto is_ident = [](const std::string& s) -> bool {
        if (s.empty() || (!std::isalpha(static_cast<unsigned char>(s[0])) && s[0] != '_')) return false;
        for (char c : s) if (!std::isalnum(static_cast<unsigned char>(c)) && c != '_') return false;
        return true;
    };

    enum class FlowCtrl { None, Break, Continue };
    FlowCtrl flow = FlowCtrl::None;

    std::function<bool(size_t, size_t, int)> exec_range;
    exec_range = [&](size_t start_idx, size_t end_idx, int expected_indent) -> bool {
        size_t i = start_idx;
        while (i < end_idx) {
            if (flow != FlowCtrl::None) return true;
            if (lines[i].indent < expected_indent) break;
            if (lines[i].indent > expected_indent) return false;
            const std::string& stmt = lines[i].text;

            if (stmt == "pass") { ++i; continue; }
            if (stmt == "break") { flow = FlowCtrl::Break; return true; }
            if (stmt == "continue") { flow = FlowCtrl::Continue; return true; }

            if (stmt.rfind("import ", 0) == 0 || stmt.rfind("from ", 0) == 0) {
                if (stmt == "import math" || stmt == "import json" || stmt == "import os" ||
                    stmt == "import sys" || stmt.rfind("from math import ", 0) == 0) {
                    ++i;
                    continue;
                }
                return false;
            }

            if (stmt.rfind("def ", 0) == 0 || stmt.rfind("class ", 0) == 0 ||
                stmt.rfind("try:", 0) == 0 || stmt.rfind("with ", 0) == 0 ||
                stmt.rfind("return ", 0) == 0 || stmt == "return") {
                return false;
            }

            if (stmt.rfind("print(", 0) == 0 && stmt.back() == ')') {
                std::string inner = stmt.substr(6, stmt.size() - 7);
                auto raw_args = split_args(inner);
                std::string sep = " ";
                std::string end_s = "\n";
                std::vector<std::string> printed;
                for (const auto& ra : raw_args) {
                    std::string t = trim_str(ra);
                    if (t.rfind("sep=", 0) == 0) {
                        Value sv;
                        if (!try_native_eval(t.substr(4), variables, sv)) return false;
                        sep = sv.as_string();
                    } else if (t.rfind("end=", 0) == 0) {
                        Value ev;
                        if (!try_native_eval(t.substr(4), variables, ev)) return false;
                        end_s = ev.as_string();
                    } else if (!t.empty()) {
                        Value v;
                        if (!try_native_eval(t, variables, v)) return false;
                        printed.push_back(v.as_string());
                    }
                }
                for (size_t k = 0; k < printed.size(); ++k) {
                    if (k > 0) stdout_ss << sep;
                    stdout_ss << printed[k];
                }
                stdout_ss << end_s;
                ++i;
                continue;
            }

            // if / elif / else block
            if (stmt.rfind("if ", 0) == 0 && stmt.back() == ':') {
                struct Branch { std::string cond; bool is_else; size_t b_start; size_t b_end; };
                std::vector<Branch> branches;
                size_t j = i;
                while (j < end_idx && lines[j].indent == expected_indent) {
                    const std::string& bt = lines[j].text;
                    bool is_if = (j == i && bt.rfind("if ", 0) == 0 && bt.back() == ':');
                    bool is_elif = (j > i && bt.rfind("elif ", 0) == 0 && bt.back() == ':');
                    bool is_else = (j > i && bt == "else:");
                    if (!is_if && !is_elif && !is_else) break;
                    std::string cond = is_if ? trim_str(bt.substr(3, bt.size() - 4))
                                     : (is_elif ? trim_str(bt.substr(5, bt.size() - 6)) : "");
                    size_t body_s = j + 1;
                    size_t body_e = body_s;
                    while (body_e < end_idx && lines[body_e].indent > expected_indent) ++body_e;
                    if (body_s == body_e) return false;
                    branches.push_back({cond, is_else, body_s, body_e});
                    j = body_e;
                    if (is_else) break;
                }
                for (const auto& br : branches) {
                    bool take = br.is_else;
                    if (!take) {
                        Value cv;
                        if (!try_native_eval(br.cond, variables, cv)) return false;
                        take = cv.is_truthy();
                    }
                    if (take) {
                        if (!exec_range(br.b_start, br.b_end, lines[br.b_start].indent)) return false;
                        break;
                    }
                }
                i = j;
                continue;
            }

            // for <var> in <iterable>:
            if (stmt.rfind("for ", 0) == 0 && stmt.back() == ':') {
                size_t in_pos = stmt.find(" in ");
                if (in_pos == std::string::npos) return false;
                std::string loop_var = trim_str(stmt.substr(4, in_pos - 4));
                if (!is_ident(loop_var)) return false;
                std::string iter_expr = trim_str(stmt.substr(in_pos + 4, stmt.size() - (in_pos + 5)));
                Value iter_val;
                if (!try_native_eval(iter_expr, variables, iter_val)) return false;

                size_t body_s = i + 1;
                size_t body_e = body_s;
                while (body_e < end_idx && lines[body_e].indent > expected_indent) ++body_e;
                if (body_s == body_e) return false;

                std::vector<Value> items;
                if (iter_val.type == ValueType::List && iter_val.list_val) {
                    items = *iter_val.list_val;
                } else if (iter_val.type == ValueType::String) {
                    for (char c : iter_val.str_val) items.push_back(Value(std::string(1, c)));
                } else {
                    return false;
                }

                for (const auto& it_v : items) {
                    variables[loop_var] = it_v;
                    if (!exec_range(body_s, body_e, lines[body_s].indent)) return false;
                    if (flow == FlowCtrl::Break) { flow = FlowCtrl::None; break; }
                    if (flow == FlowCtrl::Continue) { flow = FlowCtrl::None; continue; }
                }
                i = body_e;
                continue;
            }

            // while <cond>:
            if (stmt.rfind("while ", 0) == 0 && stmt.back() == ':') {
                std::string cond_expr = trim_str(stmt.substr(6, stmt.size() - 7));
                size_t body_s = i + 1;
                size_t body_e = body_s;
                while (body_e < end_idx && lines[body_e].indent > expected_indent) ++body_e;
                if (body_s == body_e) return false;

                int guard = 0;
                while (guard++ < 100000) {
                    Value cv;
                    if (!try_native_eval(cond_expr, variables, cv)) return false;
                    if (!cv.is_truthy()) break;
                    if (!exec_range(body_s, body_e, lines[body_s].indent)) return false;
                    if (flow == FlowCtrl::Break) { flow = FlowCtrl::None; break; }
                    if (flow == FlowCtrl::Continue) { flow = FlowCtrl::None; continue; }
                }
                if (guard >= 100000) return false;
                i = body_e;
                continue;
            }

            // Assignments: +=, -=, *=, /=, //=, %=, =
            std::string aug_ops[] = {"//=", "+=", "-=", "*=", "/=", "%="};
            bool handled_assign = false;
            for (const auto& op : aug_ops) {
                size_t op_pos = stmt.find(op);
                if (op_pos != std::string::npos) {
                    std::string lhs = trim_str(stmt.substr(0, op_pos));
                    std::string rhs = trim_str(stmt.substr(op_pos + op.size()));
                    if (is_ident(lhs) && variables.count(lhs)) {
                        Value rv;
                        if (!try_native_eval(rhs, variables, rv)) return false;
                        Value cur = variables[lhs];
                        if (op == "+=") variables[lhs] = cur + rv;
                        else if (op == "-=") variables[lhs] = cur - rv;
                        else if (op == "*=") variables[lhs] = cur * rv;
                        else if (op == "/=") {
                            if (std::abs(rv.as_number()) < 1e-15) return false;
                            variables[lhs] = Value(cur.as_number() / rv.as_number());
                        } else if (op == "%=") {
                            if (std::abs(rv.as_number()) < 1e-15) return false;
                            variables[lhs] = cur % rv;
                        } else if (op == "//=") {
                            if (std::abs(rv.as_number()) < 1e-15) return false;
                            double q = std::floor(cur.as_number() / rv.as_number());
                            variables[lhs] = (cur.type == ValueType::Int && rv.type == ValueType::Int)
                                ? Value(static_cast<int64_t>(q))
                                : Value(q);
                        }
                        handled_assign = true;
                        break;
                    }
                }
            }
            if (handled_assign) { ++i; continue; }

            // Simple assignment `name = expr` (scan = not inside quotes/==)
            size_t eq_pos = std::string::npos;
            {
                bool in_s = false, in_d = false;
                int par = 0, brk = 0;
                for (size_t k = 0; k < stmt.size(); ++k) {
                    char c = stmt[k];
                    if (c == '\\' && (in_s || in_d)) { ++k; continue; }
                    if (c == '\'' && !in_d) in_s = !in_s;
                    else if (c == '"' && !in_s) in_d = !in_d;
                    else if (!in_s && !in_d) {
                        if (c == '(') ++par; else if (c == ')') --par;
                        else if (c == '[') ++brk; else if (c == ']') --brk;
                        else if (c == '=' && par == 0 && brk == 0) {
                            char prev = (k > 0) ? stmt[k - 1] : '\0';
                            char next = (k + 1 < stmt.size()) ? stmt[k + 1] : '\0';
                            if (prev != '!' && prev != '<' && prev != '>' && prev != '=' && next != '=') {
                                eq_pos = k;
                                break;
                            }
                        }
                    }
                }
            }
            if (eq_pos != std::string::npos) {
                std::string lhs = trim_str(stmt.substr(0, eq_pos));
                std::string rhs = trim_str(stmt.substr(eq_pos + 1));
                if (!is_ident(lhs)) return false;
                Value rv;
                if (!try_native_eval(rhs, variables, rv)) return false;
                variables[lhs] = rv;
                ++i;
                continue;
            }

            // Pure expression statement
            Value unused;
            if (!try_native_eval(stmt, variables, unused)) {
                return false;
            }
            ++i;
        }
        return true;
    };

    if (!exec_range(0, lines.size(), lines[0].indent)) {
        variables = std::move(vars_backup);
        return false;
    }

    out_stdout = stdout_ss.str();
    while (!out_stdout.empty() && (out_stdout.back() == '\n' || out_stdout.back() == '\r')) {
        out_stdout.pop_back();
    }
    return true;
}

} // namespace looping
