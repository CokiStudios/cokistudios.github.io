#pragma once

#include "LoopingValue.hpp"
#include <string>
#include <vector>
#include <memory>
#include <fstream>
#include <sstream>
#include <iostream>
#include <cstdlib>
#include <chrono>
#include <iomanip>
#include <map>
#include <algorithm>
#include <sys/stat.h>

namespace looping {

// ── UI Profile Specifications for Looping Target Compilation ──
struct UIProfileSpecs {
    std::string name;          // "Shine UI", "XUI", "flUI"
    std::string code;          // "shine_ui", "xui", "flui"
    std::string theme;         // "frosted_aqua_a17", "cyber_neon_xui", "aurora_indigo_fold"
    std::string primary_color; // "#00f5d4", "#38bdf8", "#c084fc"
    std::string accent_color;  // "#0284c7", "#082f49", "#ec4899"
    int target_fps;            // 60, 240, 120
    std::string pipeline;      // "Hardware APU Direct 60Hz", "Vulkan Ultra-Low Latency 240Hz", "Adaptive Dual-Screen 120Hz"
    std::string layout_mode;   // "Console Grid & Carousel", "Pro Gamer Esports HUD", "Foldable Multi-Deck Floating"
};

inline UIProfileSpecs resolve_ui_profile(const std::string& raw) {
    std::string s = raw;
    for (char& c : s) c = std::tolower(c);
    while (!s.empty() && (s.front() == ' ' || s.front() == '-' || s.front() == '_')) s.erase(0, 1);
    while (!s.empty() && (s.back() == ' ' || s.back() == '-' || s.back() == '_')) s.pop_back();

    // 1. XUI (Gama X / 240Hz Gaming)
    if (s == "xui" || s == "x_ui" || s == "x-ui" || s == "gama_x" || s == "gama-x" || s == "gamax") {
        return {
            "XUI",
            "xui",
            "cyber_neon_xui",
            "#38bdf8",
            "#082f49",
            240,
            "Direct-to-Vulkan Ultra-Low Latency 240Hz (<0.2ms)",
            "Pro Gamer Esports HUD (High-Refresh APU)"
        };
    }

    // 2. flUI (Foldable / Dual-Screen / Floating Multi-Window)
    if (s == "flui" || s == "fl_ui" || s == "fl-ui" || s == "fl ui" || s == "fold" || s == "foldable" || s == "floating" || s == "duo") {
        return {
            "flUI",
            "flui",
            "aurora_indigo_fold",
            "#c084fc",
            "#ec4899",
            120,
            "Fold-Aware Dynamic Multi-Window 120Hz",
            "Dual-Screen Deck / Floating Cards Responsive"
        };
    }

    // 3. Default: Shine UI (Shine Loop Handheld Console / 60 FPS)
    return {
        "Shine UI",
        "shine_ui",
        "frosted_aqua_a17",
        "#00f5d4",
        "#0284c7",
        60,
        "Shine APU Direct V-Sync 60Hz",
        "Handheld Console Grid & 3D Carousel"
    };
}

// ── Dynamic Program Builder ──
// Allows programmatic construction of Looping programs at runtime
class DynamicProgram {
public:
    std::string app_name;
    std::string version;
    std::string target_ui;
    std::string theme;
    std::string window_title;
    double window_width = 800;
    double window_height = 520;

    std::vector<std::pair<std::string, std::string>> imports;
    std::vector<std::string> python_modules;
    std::vector<std::string> declarations;
    std::vector<std::string> ui_cards;
    std::vector<std::string> ui_buttons;
    std::vector<std::string> ui_inputs;
    std::vector<std::string> custom_functions;
    std::vector<std::string> body_statements;

    DynamicProgram(const std::string& name = "DynamicApp", 
                   const std::string& target = "shine_ui", 
                   const std::string& ver = "1.0")
        : app_name(name), version(ver), target_ui(target) {
        UIProfileSpecs specs = resolve_ui_profile(target);
        theme = specs.theme;
        window_title = name + " - " + specs.name;
    }

    DynamicProgram& set_name(const std::string& name) {
        app_name = name;
        return *this;
    }

    DynamicProgram& set_version(const std::string& ver) {
        version = ver;
        return *this;
    }

    DynamicProgram& set_window(const std::string& title, double w = 800, double h = 520) {
        window_title = title;
        window_width = w;
        window_height = h;
        return *this;
    }

    DynamicProgram& set_target(const std::string& target) {
        target_ui = target;
        UIProfileSpecs specs = resolve_ui_profile(target);
        theme = specs.theme;
        return *this;
    }

    DynamicProgram& set_theme(const std::string& th) {
        theme = th;
        return *this;
    }

    DynamicProgram& add_import(const std::string& mod, const std::string& alias = "") {
        imports.push_back({mod, alias});
        return *this;
    }

    DynamicProgram& add_python_module(const std::string& mod) {
        python_modules.push_back(mod);
        return *this;
    }

    DynamicProgram& add_var(const std::string& name, const std::string& expr) {
        declarations.push_back("set " + name + " to " + expr);
        return *this;
    }

    DynamicProgram& add_card(double x, double y, double w, double h, const std::string& title, const std::string& text) {
        std::ostringstream ss;
        ss << "    draw card at (" << x << ", " << y << ") with size (" << w << ", " << h << ") and title \"" 
           << escape_str(title) << "\" and text \"" << escape_str(text) << "\"";
        ui_cards.push_back(ss.str());
        return *this;
    }

    DynamicProgram& add_button(double x, double y, const std::string& text, const std::string& action) {
        std::ostringstream ss;
        ss << "    draw button at (" << x << ", " << y << ") with text \"" << escape_str(text) 
           << "\" and action \"" << escape_str(action) << "\"";
        ui_buttons.push_back(ss.str());
        return *this;
    }

    DynamicProgram& add_input(double x, double y, double w, double h, const std::string& var_name, const std::string& placeholder) {
        std::ostringstream ss;
        ss << "    draw input at (" << x << ", " << y << ") with size (" << w << ", " << h << ") and binding \""
           << escape_str(var_name) << "\" and placeholder \"" << escape_str(placeholder) << "\"";
        ui_inputs.push_back(ss.str());
        return *this;
    }

    DynamicProgram& add_function(const std::string& fn_name, const std::vector<std::string>& params, const std::string& body) {
        std::ostringstream ss;
        ss << "fn " << fn_name << "(";
        for (size_t i = 0; i < params.size(); ++i) {
            if (i > 0) ss << ", ";
            ss << params[i];
        }
        ss << ") {\n";
        std::stringstream b_in(body);
        std::string line;
        while (std::getline(b_in, line)) {
            ss << "    " << line << "\n";
        }
        ss << "}\n";
        custom_functions.push_back(ss.str());
        return *this;
    }

    DynamicProgram& add_code(const std::string& code) {
        body_statements.push_back(code);
        return *this;
    }

    // Emits valid, formatted Looping source code
    std::string emit_source() const {
        std::ostringstream out;
        out << "# ═══════════════════════════════════════════════════════════════\n";
        out << "# ⚡ DYNAMICALLY GENERATED LOOPING PROGRAM: " << app_name << "\n";
        out << "# Target UI: " << target_ui << " | Version: " << version << "\n";
        out << "# Created via Looping Dynamic Compiler Subsystem\n";
        out << "# ═══════════════════════════════════════════════════════════════\n\n";

        if (imports.empty()) {
            out << "import loop.ui as ui\n";
            out << "import loop.system as sys\n";
            out << "import loop.engine as game\n\n";
        } else {
            for (const auto& imp : imports) {
                out << "import " << imp.first;
                if (!imp.second.empty()) out << " as " << imp.second;
                out << "\n";
            }
            out << "\n";
        }

        for (const auto& py : python_modules) {
            out << "use python \"" << py << "\"\n";
        }
        if (!python_modules.empty()) out << "\n";

        // Functions
        for (const auto& fn : custom_functions) {
            out << fn << "\n";
        }

        // App Block
        out << "define app \"" << app_name << "\" version " << version << ":\n";
        out << "    create window with title \"" << escape_str(window_title) << "\" and size (" 
            << window_width << ", " << window_height << ")\n";
        out << "    target(\"" << target_ui << "\")\n";
        out << "    set theme to \"" << theme << "\"\n\n";

        // Declarations
        for (const auto& decl : declarations) {
            out << "    " << decl << "\n";
        }
        if (!declarations.empty()) out << "\n";

        // UI Components
        for (const auto& card : ui_cards) out << card << "\n";
        for (const auto& btn : ui_buttons) out << btn << "\n";
        for (const auto& inp : ui_inputs) out << inp << "\n";
        if (!ui_cards.empty() || !ui_buttons.empty() || !ui_inputs.empty()) out << "\n";

        // Body Code
        for (const auto& stmt : body_statements) {
            std::stringstream ss(stmt);
            std::string line;
            while (std::getline(ss, line)) {
                out << "    " << line << "\n";
            }
        }

        return out.str();
    }

private:
    static std::string escape_str(const std::string& in) {
        std::string out;
        for (char c : in) {
            if (c == '"') out += "\\\"";
            else if (c == '\n') out += "\\n";
            else out += c;
        }
        return out;
    }
};

// ── Looping Compiler Core ──
// Provides static and dynamic compilation of Looping code to executable artifacts
class Compiler {
public:
    // Compiles raw source code string into target UI profile artifact
    static bool compile_source(const std::string& source_code, 
                               const std::string& target_name, 
                               const std::string& output_path,
                               std::string* out_created_path = nullptr) {
        UIProfileSpecs specs = resolve_ui_profile(target_name);

        std::string out_file = output_path;
        if (out_file.empty()) {
            out_file = "build/dynamic_program_" + specs.code;
        }

        // Create parent directories if needed
        size_t slash = out_file.find_last_of("/\\");
        if (slash != std::string::npos) {
            std::string dir = out_file.substr(0, slash);
            std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
            system(mkdir_cmd.c_str());
        }

        std::ofstream out(out_file);
        if (!out.is_open()) {
            std::cerr << "\033[31m❌ Error: Cannot write compiled target to: " << out_file << "\033[0m\n";
            return false;
        }

        out << "#!/usr/bin/env looping\n";
        out << "# ═══════════════════════════════════════════════════════════════\n";
        out << "# 🚀 COMPILED DYNAMIC LOOPING ARTIFACT — " << specs.name << "\n";
        out << "# System UI: " << specs.name << " [" << specs.code << "]\n";
        out << "# Hardware Refresh: " << specs.pipeline << " (" << specs.target_fps << " FPS)\n";
        out << "# Layout Mode: " << specs.layout_mode << "\n";
        out << "# Shader Palette: " << specs.theme << " (" << specs.primary_color << ")\n";
        out << "# Dynamic Looping Engine v2.5.0 (Coki Studios / Holo Entertainment)\n";
        out << "# ═══════════════════════════════════════════════════════════════\n\n";
        out << "compile target \"" << specs.code << "\"\n";
        out << "set ui_profile to \"" << specs.code << "\"\n";
        out << "set theme to \"" << specs.theme << "\"\n\n";

        // Filter source code to avoid duplicate target declarations
        std::stringstream in_stream(source_code);
        std::string cur_line;
        while (std::getline(in_stream, cur_line)) {
            std::string trimmed = cur_line;
            while (!trimmed.empty() && (trimmed.front() == ' ' || trimmed.front() == '\t')) trimmed.erase(0, 1);
            if (trimmed.rfind("compile target ", 0) == 0 || trimmed.rfind("compile for ", 0) == 0 ||
                trimmed.rfind("target(", 0) == 0 || trimmed.rfind("@target(", 0) == 0 ||
                trimmed.rfind("profile(", 0) == 0 || trimmed.rfind("@profile(", 0) == 0 ||
                trimmed.rfind("set ui_profile to", 0) == 0 || trimmed.rfind("set ui to", 0) == 0 ||
                trimmed.rfind("set theme to", 0) == 0) {
                out << "    # [Compiled Target Override]: " << trimmed << "\n";
            } else {
                out << cur_line << "\n";
            }
        }
        out.close();

        // Make executable
        std::string chmod_cmd = "chmod +x \"" + out_file + "\"";
        system(chmod_cmd.c_str());

        if (out_created_path) {
            *out_created_path = out_file;
        }

        std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Dynamic target artifact compiled to: " 
                  << "\033[1m" << out_file << "\033[0m [" << specs.name << " / " << specs.pipeline << "]\n";

        return true;
    }

    // Compiles a file to a target artifact
    static bool compile_file(const std::string& input_path, 
                             const std::string& target_name, 
                             const std::string& output_path,
                             std::string* out_created_path = nullptr) {
        std::ifstream file(input_path);
        if (!file.is_open()) {
            std::cerr << "\033[31m❌ Error: Cannot open input file: " << input_path << "\033[0m\n";
            return false;
        }

        std::stringstream buffer;
        buffer << file.rdbuf();
        std::string source_code = buffer.str();

        std::string out_file = output_path;
        if (out_file.empty()) {
            std::string base_name = input_path;
            size_t slash = base_name.find_last_of("/\\");
            if (slash != std::string::npos) base_name = base_name.substr(slash + 1);
            size_t dot = base_name.find_last_of('.');
            if (dot != std::string::npos) base_name = base_name.substr(0, dot);
            UIProfileSpecs specs = resolve_ui_profile(target_name);
            out_file = "build/" + base_name + "_" + specs.code;
        }

        return compile_source(source_code, target_name, out_file, out_created_path);
    }

    // Compiles a DynamicProgram object
    static bool compile_dynamic_program(const DynamicProgram& prog, 
                                        const std::string& output_path = "",
                                        std::string* out_created_path = nullptr) {
        std::string out_file = output_path;
        if (out_file.empty()) {
            UIProfileSpecs specs = resolve_ui_profile(prog.target_ui);
            out_file = "build/" + prog.app_name + "_" + specs.code;
        }
        return compile_source(prog.emit_source(), prog.target_ui, out_file, out_created_path);
    }

    // Factory: Creates dynamic program builder
    static DynamicProgram create_program(const std::string& name, const std::string& target = "shine_ui", const std::string& ver = "1.0") {
        return DynamicProgram(name, target, ver);
    }

    // Factory: Creates pre-configured template programs
    static DynamicProgram create_template(const std::string& type, const std::string& name, const std::string& target = "shine_ui") {
        DynamicProgram prog(name, target, "1.0");

        if (type == "arcade" || type == "game") {
            prog.set_window(name + " 2D Game", 800, 600)
                .add_import("loop.ui", "ui")
                .add_import("loop.engine", "game")
                .add_card(20, 20, 760, 80, "🎮 " + name, "State-of-the-art 2D Canvas Engine\nTarget: " + target)
                .add_button(35, 120, "PLAY GAME", "start_game")
                .add_code("play tone at 587 Hz for 80 ms\nplay tone at 880 Hz for 120 ms\nprint \"[GAME] Engine initialized at 60 FPS.\"");
        } else if (type == "dashboard" || type == "launcher") {
            prog.set_window(name + " Dashboard", 840, 560)
                .add_card(20, 20, 800, 70, "🌟 " + name, "System Dashboard & Telemetry Monitor")
                .add_card(20, 110, 380, 180, "CPU & MEMORY", "Usage: 14% • Temperature: 42°C\nStatus: Optimal")
                .add_card(420, 110, 400, 180, "NETWORK & DISPLAY", "Pipeline: Direct V-Sync\nLatency: 0.18ms")
                .add_button(35, 310, "REFRESH METRICS", "refresh_stats")
                .add_code("print \"[DASHBOARD] Loaded telemetry metrics successfully.\"");
        } else if (type == "tool" || type == "counter") {
            prog.set_window(name + " Tool", 600, 400)
                .add_card(20, 20, 560, 90, "⚡ " + name, "Dynamic Productivity Tool")
                .add_button(35, 130, "EJECUTAR TAREA", "run_task")
                .add_code("mut counter = 0\nfn run_task() {\n    counter += 1\n    print $\"Task executed. Counter: {counter}\"\n}\nprint \"Tool initialized and ready.\"");
        } else {
            prog.set_window(name, 700, 450)
                .add_card(20, 20, 660, 90, name, "Dynamic Application generated dynamically")
                .add_code("print $\"Dynamic application '{name}' running perfectly!\"");
        }

        return prog;
    }

    // Runs an executable artifact or script
    static bool run_artifact(const std::string& path) {
        std::cout << "\033[36m[LAUNCHER]\033[0m Executing artifact: \033[1m" << path << "\033[0m\n";
        std::string cmd;
        if (path.find(".loop") != std::string::npos || path.find(".ruup") != std::string::npos) {
            cmd = "looping \"" + path + "\"";
        } else if (path.rfind("./", 0) == 0 || path.front() == '/') {
            cmd = "\"" + path + "\"";
        } else {
            cmd = "./\"" + path + "\"";
        }
        int res = system(cmd.c_str());
        return (res == 0);
    }
};

} // namespace looping
