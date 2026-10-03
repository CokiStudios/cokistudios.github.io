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

#if defined(_WIN32)
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

    PythonBridge() {
        detect();
    }

    void detect() {
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
            cmd += " -c \"import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')\" 2>/dev/null";

            FILE* pipe = popen(cmd.c_str(), "r");
            if (!pipe) continue;

            char buffer[128];
            std::string result = "";
            while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
                result += buffer;
            }
            int status = pclose(pipe);

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
    }

    std::string get_command_str() const {
        if (!is_available) return "";
        std::string s = detected_exe;
        for (const auto& a : detected_args) s += " " + a;
        return s;
    }

    // Execute multiline Python script with bidirectional variable sync
    std::string execute_block(const std::string& py_code, std::unordered_map<std::string, Value>& variables) {
        if (!is_available) {
            return "[Error: Python executable not found in PATH]";
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

        // Write temp python runner script
        std::string temp_py_path = "/tmp/looping_py_block_" + std::to_string(rand()) + ".py";
#if defined(_WIN32)
        char tmp_dir[MAX_PATH];
        GetTempPathA(MAX_PATH, tmp_dir);
        temp_py_path = std::string(tmp_dir) + "looping_py_block_" + std::to_string(rand()) + ".py";
#endif

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

        // Run python with env var
#if defined(_WIN32)
        _putenv_s("LOOPING_VARS_JSON", vars_json.c_str());
#else
        setenv("LOOPING_VARS_JSON", vars_json.c_str(), 1);
#endif

        std::string cmd = get_command_str() + " \"" + temp_py_path + "\" 2>&1";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) {
            remove(temp_py_path.c_str());
            return "[Error: Failed to execute python]";
        }

        std::string stdout_clean = "";
        char buffer[512];
        while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
            std::string line(buffer);
            const std::string prefix = "__LOOPING_SET__:";
            auto pos = line.find(prefix);
            if (pos != std::string::npos) {
                std::string payload = line.substr(pos + prefix.length());
                // Parse simple json: {"k": "...", "v": ...}
                parse_and_set_var(payload, variables);
            } else {
                stdout_clean += line;
            }
        }
        pclose(pipe);
        remove(temp_py_path.c_str());

        // Trim trailing newline
        while (!stdout_clean.empty() && (stdout_clean.back() == '\n' || stdout_clean.back() == '\r')) {
            stdout_clean.pop_back();
        }

        return stdout_clean;
    }

    // Evaluate inline Python expression
    Value eval_expr(const std::string& expr, const std::unordered_map<std::string, Value>& variables) {
        if (!is_available) return Value();

        std::string vars_json = "{";
        bool first = true;
        for (const auto& [k, v] : variables) {
            if (!first) vars_json += ", ";
            first = false;
            vars_json += "\"" + k + "\": " + v.to_json();
        }
        vars_json += "}";

#if defined(_WIN32)
        _putenv_s("LOOPING_VARS_JSON", vars_json.c_str());
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

        std::string temp_py_path = "/tmp/looping_eval_" + std::to_string(rand()) + ".py";
#if defined(_WIN32)
        char tmp_dir[MAX_PATH];
        GetTempPathA(MAX_PATH, tmp_dir);
        temp_py_path = std::string(tmp_dir) + "looping_eval_" + std::to_string(rand()) + ".py";
#endif

        FILE* f = fopen(temp_py_path.c_str(), "w");
        if (!f) return Value();
        fputs(py_script.c_str(), f);
        fclose(f);

        std::string cmd = get_command_str() + " \"" + temp_py_path + "\" 2>/dev/null";
        FILE* pipe = popen(cmd.c_str(), "r");
        if (!pipe) {
            remove(temp_py_path.c_str());
            return Value();
        }

        char buffer[256];
        std::string output = "";
        while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
            output += buffer;
        }
        int status = pclose(pipe);
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

} // namespace looping
