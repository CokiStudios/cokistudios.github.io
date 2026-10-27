#pragma once

#include "LoopingValue.hpp"
#include "LoopingAST.hpp"
#include "LoopingParser.hpp"
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
#include <unistd.h>

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

    // 2b. SwiftUI (Apple Ecosystem: iOS, macOS, watchOS, visionOS)
    if (s == "swiftui" || s == "swift" || s == "apple" || s == "ios" || s == "macos" || s == "watchos" || s == "visionos") {
        return {
            "SwiftUI",
            "swiftui",
            "apple_glassmorphism",
            "#007AFF",
            "#5856D6",
            120,
            "Apple Metal & SwiftUI ProMotion 120Hz",
            "Apple Declarative Canvas & Dynamic Island Layout"
        };
    }

    // 3. Component 2 (.c2 - Shine Modular Android UI Bundle)
    if (s == "c2" || s == "component2" || s == "component_2" || s == "c2_module" || s == "c2-module") {
        return {
            "Component 2 (.c2)",
            "c2",
            "c2_modular_surface",
            "#38bdf8",
            "#10b981",
            120,
            "Modular Android UI Hot-Reload Pipeline (.c2)",
            "Dynamic Component 2 Bundle for Shine OS & Forkar Services"
        };
    }

    // 4. Vintage (niminticos / curved toolbar)
    if (s == "vintage" || s == "niminticos" || s == "tuilbar") {
        return {
            "Vintage",
            "vintage",
            "amber_retro_mono",
            "#f59e0b",
            "#78350f",
            60,
            "Curved Toolbar Ergonomic Hardware Engine",
            "Lower Curved tUIlbar & High-Contrast Monospace"
        };
    }

    // 5. hiUI (A1 / Low-RAM Lightweight)
    if (s == "hiui" || s == "hi_ui" || s == "hi-ui" || s == "a1") {
        return {
            "hiUI",
            "hiui",
            "feather_lite_a1",
            "#06b6d4",
            "#0e7490",
            60,
            "Low-Memory Ultra-Efficient Engine (<30MB RAM)",
            "Lightweight Single-Layer Responsive Surface"
        };
    }

    // 6. Default: Shine UI (Shine Loop Handheld Console / 60 FPS)
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

// ── Dynamic Window Creator Subsystem ──
// High-level programmatic and declarative dynamic graphical window builder for Loop OS
class DynamicWindow {
public:
    struct CardItem {
        std::string title;
        std::string text;
        double x = 0;
        double y = 0;
        double width = 240;
        double height = 150;
        std::string badge;
        std::string icon;
        std::string button_text;
        std::string action;
        std::string visible_when;
    };

    struct ButtonItem {
        std::string text;
        std::string action;
        double x = 0;
        double y = 0;
        double width = 140;
        double height = 40;
        std::string snippet;
        std::string visible_when;
    };

    struct InputItem {
        std::string placeholder;
        std::string binding;
        double x = 0;
        double y = 0;
        double width = 220;
        double height = 40;
        std::string visible_when;
    };

    struct SliderItem {
        std::string label;
        double min_val = 0;
        double max_val = 100;
        double current_val = 50;
        std::string binding;
        double x = 0;
        double y = 0;
        double width = 220;
        double height = 40;
        std::string visible_when;
    };

    struct ToggleItem {
        std::string label;
        bool is_checked = false;
        std::string binding;
        double x = 0;
        double y = 0;
        double width = 160;
        double height = 36;
        std::string visible_when;
    };

    struct ProgressItem {
        std::string label;
        double progress = 0;
        std::string binding;
        double x = 0;
        double y = 0;
        double width = 240;
        double height = 28;
        std::string visible_when;
    };

    struct ToolbarItem {
        std::string id;
        std::string text;
        std::string icon;
        std::string action;
        std::string position = "top";
        std::string visible_when;
    };

    struct ToneItem {
        double freq_hz = 440;
        double duration_ms = 80;
    };

    std::string app_name = "DynamicWindow";
    std::string title = "Looping Dynamic Window";
    double width = 850;
    double height = 540;
    std::string theme = "frosted_aqua_a17";
    std::string background = "";
    std::string target_ui = "shine_ui";
    std::string version = "1.0";
    std::vector<CardItem> cards;
    std::vector<ButtonItem> buttons;
    std::vector<InputItem> inputs;
    std::vector<SliderItem> sliders;
    std::vector<ToggleItem> toggles;
    std::vector<ProgressItem> progress_bars;
    std::vector<ToolbarItem> toolbar_items;
    std::vector<ToneItem> tones;
    std::vector<std::string> custom_statements;

    DynamicWindow(const std::string& win_title = "Looping Dynamic Window",
                  double w = 850, double h = 540,
                  const std::string& target = "shine_ui")
        : title(win_title), width(w), height(h), target_ui(target) {
        UIProfileSpecs specs = resolve_ui_profile(target);
        theme = specs.theme;
        app_name = sanitize_id(win_title);
    }

    DynamicWindow& set_title(const std::string& t) {
        title = t;
        if (app_name == "DynamicWindow" || app_name.empty()) app_name = sanitize_id(t);
        return *this;
    }

    DynamicWindow& set_size(double w, double h) {
        width = w;
        height = h;
        return *this;
    }

    DynamicWindow& set_theme(const std::string& th) {
        theme = th;
        return *this;
    }

    DynamicWindow& set_background(const std::string& bg) {
        background = bg;
        return *this;
    }

    DynamicWindow& set_bg(const std::string& bg) {
        return set_background(bg);
    }

    DynamicWindow& set_target(const std::string& tgt) {
        target_ui = tgt;
        UIProfileSpecs specs = resolve_ui_profile(tgt);
        theme = specs.theme;
        return *this;
    }

    DynamicWindow& add_toolbar_item(const std::string& tb_text, const std::string& tb_action = "",
                                   const std::string& tb_icon = "", const std::string& tb_pos = "top",
                                   const std::string& tb_id = "", const std::string& tb_vis = "") {
        ToolbarItem item;
        item.text = tb_text;
        item.id = tb_id.empty() ? sanitize_id(tb_text) : tb_id;
        item.action = tb_action.empty() ? item.id : tb_action;
        item.icon = tb_icon;
        item.position = tb_pos.empty() ? "top" : tb_pos;
        item.visible_when = tb_vis;
        toolbar_items.push_back(item);
        return *this;
    }

    DynamicWindow& add_card(const std::string& card_title, const std::string& card_text,
                           double x = -1, double y = -1, double w = -1, double h = -1,
                           const std::string& badge = "", const std::string& icon = "") {
        CardItem c;
        c.title = card_title;
        c.text = card_text;
        c.badge = badge.empty() ? derive_badge(card_title) : badge;
        c.icon = icon.empty() ? derive_icon(card_title) : icon;

        if (x < 0 || y < 0) {
            size_t idx = cards.size();
            double margin = 20;
            double cols = (width >= 900) ? 3 : 2;
            double col_w = (width - margin * (cols + 1)) / cols;
            double card_h = 160;
            size_t row = idx / static_cast<size_t>(cols);
            size_t col = idx % static_cast<size_t>(cols);
            c.x = margin + col * (col_w + margin);
            c.y = 80 + row * (card_h + 16);
            c.width = (w > 0) ? w : col_w;
            c.height = (h > 0) ? h : card_h;
        } else {
            c.x = x;
            c.y = y;
            c.width = (w > 0) ? w : 240;
            c.height = (h > 0) ? h : 150;
        }

        cards.push_back(c);
        return *this;
    }

    DynamicWindow& add_button(const std::string& btn_text, const std::string& action = "",
                             double x = -1, double y = -1, double w = 150, double h = 42,
                             const std::string& snippet_code = "") {
        ButtonItem b;
        b.text = btn_text;
        b.action = action.empty() ? sanitize_id(btn_text) : action;
        b.snippet = snippet_code;
        if (x < 0 || y < 0) {
            size_t idx = buttons.size();
            b.x = 24 + idx * (w + 16);
            b.y = height - h - 24;
        } else {
            b.x = x;
            b.y = y;
        }
        b.width = w;
        b.height = h;
        buttons.push_back(b);
        return *this;
    }

    DynamicWindow& add_input(const std::string& placeholder, const std::string& binding,
                            double x = -1, double y = -1, double w = 220, double h = 40) {
        InputItem inp;
        inp.placeholder = placeholder;
        inp.binding = binding;
        if (x < 0 || y < 0) {
            inp.x = 24;
            inp.y = height - h - 80;
        } else {
            inp.x = x;
            inp.y = y;
        }
        inp.width = w;
        inp.height = h;
        inputs.push_back(inp);
        return *this;
    }

    DynamicWindow& add_slider(const std::string& label, double min_v = 0, double max_v = 100, double cur_v = 50,
                             const std::string& binding = "", double x = -1, double y = -1, double w = 220, double h = 40) {
        SliderItem s;
        s.label = label;
        s.min_val = min_v;
        s.max_val = max_v;
        s.current_val = cur_v;
        s.binding = binding.empty() ? sanitize_id(label) : binding;
        if (x < 0 || y < 0) {
            s.x = 24;
            s.y = 80 + (cards.size() * 50) + (sliders.size() * 45);
        } else {
            s.x = x; s.y = y;
        }
        s.width = w > 0 ? w : 220;
        s.height = h > 0 ? h : 40;
        sliders.push_back(s);
        return *this;
    }

    DynamicWindow& add_toggle(const std::string& label, bool checked = false,
                             const std::string& binding = "", double x = -1, double y = -1, double w = 160, double h = 36) {
        ToggleItem t;
        t.label = label;
        t.is_checked = checked;
        t.binding = binding.empty() ? sanitize_id(label) : binding;
        if (x < 0 || y < 0) {
            t.x = 24;
            t.y = 80 + (cards.size() * 50) + (toggles.size() * 40);
        } else {
            t.x = x; t.y = y;
        }
        t.width = w > 0 ? w : 160;
        t.height = h > 0 ? h : 36;
        toggles.push_back(t);
        return *this;
    }

    DynamicWindow& add_progress(const std::string& label, double progress = 0,
                               const std::string& binding = "", double x = -1, double y = -1, double w = 240, double h = 28) {
        ProgressItem p;
        p.label = label;
        p.progress = progress;
        p.binding = binding.empty() ? sanitize_id(label) : binding;
        if (x < 0 || y < 0) {
            p.x = 24;
            p.y = 80 + (cards.size() * 50) + (progress_bars.size() * 35);
        } else {
            p.x = x; p.y = y;
        }
        p.width = w > 0 ? w : 240;
        p.height = h > 0 ? h : 28;
        progress_bars.push_back(p);
        return *this;
    }

    DynamicWindow& add_tone(double freq, double dur_ms) {
        tones.push_back({freq, dur_ms});
        return *this;
    }

    DynamicWindow& add_code(const std::string& code_line) {
        custom_statements.push_back(code_line);
        return *this;
    }

    std::string emit_loop_script() const {
        std::ostringstream ss;
        ss << "# ═══════════════════════════════════════════════════════════════\n";
        ss << "# ⚡ DYNAMIC WINDOW SCRIPT: " << title << "\n";
        ss << "# Generated dynamically by Looping Engine v2.5\n";
        ss << "# ═══════════════════════════════════════════════════════════════\n\n";
        ss << "import loop.ui as ui\n";
        ss << "import loop.system as sys\n\n";
        ss << "define app \"" << app_name << "\" version " << version << ":\n";
        ss << "    create window with title \"" << title << "\" and size (" << width << ", " << height << ")\n";
        ss << "    compile target \"" << target_ui << "\"\n";
        ss << "    set theme to \"" << theme << "\"\n";
        if (!background.empty()) {
            ss << "    set background to \"" << background << "\"\n";
        }
        ss << "\n";

        for (const auto& tb : toolbar_items) {
            ss << "    draw toolbar item \"" << tb.text << "\" action \"" << tb.action << "\" position \"" << tb.position << "\"\n";
        }
        if (!toolbar_items.empty()) ss << "\n";

        for (const auto& c : cards) {
            ss << "    draw card at (" << c.x << ", " << c.y << ") with size (" << c.width << ", " << c.height 
               << ") and title \"" << c.title << "\" and text \"" << escape_str(c.text) << "\"\n";
        }
        if (!cards.empty()) ss << "\n";

        for (const auto& b : buttons) {
            if (!b.snippet.empty()) {
                ss << "    draw button at (" << b.x << ", " << b.y << ") with text \"" << b.text 
                   << "\" and action \"" << b.action << "\" with snippet:\n";
                std::istringstream ssnip(b.snippet);
                std::string snip_l;
                while (std::getline(ssnip, snip_l)) {
                    ss << "        " << snip_l << "\n";
                }
                ss << "    end\n";
            } else {
                ss << "    draw button at (" << b.x << ", " << b.y << ") with text \"" << b.text 
                   << "\" and action \"" << b.action << "\"\n";
            }
        }
        if (!buttons.empty()) ss << "\n";

        for (const auto& t : tones) {
            ss << "    play tone at " << t.freq_hz << " Hz for " << t.duration_ms << " ms\n";
        }
        if (!tones.empty()) ss << "\n";

        for (const auto& code : custom_statements) {
            ss << "    " << code << "\n";
        }

        return ss.str();
    }

    std::string emit_html() const {
        UIProfileSpecs specs = resolve_ui_profile(target_ui);
        std::ostringstream h;
        h << "<!DOCTYPE html>\n";
        h << "<html lang=\"es\">\n";
        h << "<head>\n";
        h << "  <meta charset=\"UTF-8\">\n";
        h << "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n";
        h << "  <title>" << escape_html(title) << " — Loop OS Dynamic Window</title>\n";
        h << "  <style>\n";
        h << "    :root {\n";
        h << "      --primary: " << specs.primary_color << ";\n";
        h << "      --accent: " << specs.accent_color << ";\n";
        h << "      --bg: #070a12;\n";
        h << "      --card-bg: rgba(18, 24, 38, 0.75);\n";
        h << "      --border: rgba(255, 255, 255, 0.12);\n";
        h << "      --border-glow: " << specs.primary_color << "44;\n";
        h << "      --text: #f8fafc;\n";
        h << "      --text-muted: #94a3b8;\n";
        h << "    }\n";
        h << "    * { box-sizing: border-box; margin: 0; padding: 0; }\n";
        h << "    body {\n";
        h << "      background: var(--bg);\n";
        h << "      background-image: radial-gradient(circle at 20% 20%, " << specs.primary_color << "18 0%, transparent 40%),\n";
        h << "                        radial-gradient(circle at 80% 80%, " << specs.accent_color << "22 0%, transparent 50%);\n";
        h << "      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;\n";
        h << "      color: var(--text);\n";
        h << "      min-height: 100vh;\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      justify-content: center;\n";
        h << "      padding: 20px;\n";
        h << "      overflow-x: hidden;\n";
        h << "    }\n";
        h << "    .window {\n";
        h << "      width: 100%;\n";
        h << "      max-width: " << width << "px;\n";
        h << "      min-height: " << height << "px;\n";
        h << "      background: rgba(11, 16, 28, 0.88);\n";
        h << "      backdrop-filter: blur(28px);\n";
        h << "      -webkit-backdrop-filter: blur(28px);\n";
        h << "      border: 1px solid var(--border);\n";
        h << "      border-radius: 18px;\n";
        h << "      box-shadow: 0 30px 80px rgba(0,0,0,0.7), 0 0 40px var(--border-glow);\n";
        h << "      display: flex;\n";
        h << "      flex-direction: column;\n";
        h << "      overflow: hidden;\n";
        h << "      transition: transform 0.25s ease, opacity 0.25s ease;\n";
        h << "    }\n";
        h << "    .title-bar {\n";
        h << "      height: 48px;\n";
        h << "      background: rgba(255, 255, 255, 0.04);\n";
        h << "      border-bottom: 1px solid var(--border);\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      justify-content: space-between;\n";
        h << "      padding: 0 18px;\n";
        h << "      user-select: none;\n";
        h << "    }\n";
        h << "    .traffic-lights {\n";
        h << "      display: flex;\n";
        h << "      gap: 8px;\n";
        h << "    }\n";
        h << "    .dot {\n";
        h << "      width: 13px;\n";
        h << "      height: 13px;\n";
        h << "      border-radius: 50%;\n";
        h << "      cursor: pointer;\n";
        h << "      transition: transform 0.15s, opacity 0.15s;\n";
        h << "    }\n";
        h << "    .dot:hover { transform: scale(1.15); opacity: 0.85; }\n";
        h << "    .dot-close { background: #ff5f56; }\n";
        h << "    .dot-min { background: #ffbd2e; }\n";
        h << "    .dot-max { background: #27c93f; }\n";
        h << "    .window-title {\n";
        h << "      font-size: 13px;\n";
        h << "      font-weight: 700;\n";
        h << "      letter-spacing: 0.5px;\n";
        h << "      color: var(--text);\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      gap: 10px;\n";
        h << "    }\n";
        h << "    .profile-badge {\n";
        h << "      background: var(--border-glow);\n";
        h << "      color: var(--primary);\n";
        h << "      padding: 2px 8px;\n";
        h << "      border-radius: 20px;\n";
        h << "      font-size: 11px;\n";
        h << "      font-weight: 600;\n";
        h << "      border: 1px solid var(--primary);\n";
        h << "    }\n";
        h << "    .window-status {\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      gap: 14px;\n";
        h << "      font-size: 12px;\n";
        h << "      color: var(--text-muted);\n";
        h << "      font-family: monospace;\n";
        h << "    }\n";
        h << "    .fps-counter {\n";
        h << "      color: var(--primary);\n";
        h << "      font-weight: bold;\n";
        h << "    }\n";
        h << "    .content-area {\n";
        h << "      padding: 24px;\n";
        h << "      flex: 1;\n";
        h << "      display: flex;\n";
        h << "      flex-direction: column;\n";
        h << "      gap: 20px;\n";
        h << "    }\n";
        h << "    .cards-grid {\n";
        h << "      display: grid;\n";
        h << "      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));\n";
        h << "      gap: 16px;\n";
        h << "    }\n";
        h << "    .card {\n";
        h << "      background: var(--card-bg);\n";
        h << "      border: 1px solid var(--border);\n";
        h << "      border-radius: 14px;\n";
        h << "      padding: 18px;\n";
        h << "      display: flex;\n";
        h << "      flex-direction: column;\n";
        h << "      gap: 10px;\n";
        h << "      transition: all 0.25s ease;\n";
        h << "      position: relative;\n";
        h << "      overflow: hidden;\n";
        h << "    }\n";
        h << "    .card:hover {\n";
        h << "      transform: translateY(-3px);\n";
        h << "      border-color: var(--primary);\n";
        h << "      box-shadow: 0 12px 30px rgba(0,0,0,0.4), 0 0 20px var(--border-glow);\n";
        h << "    }\n";
        h << "    .card-header {\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      justify-content: space-between;\n";
        h << "    }\n";
        h << "    .card-title {\n";
        h << "      font-size: 15px;\n";
        h << "      font-weight: 700;\n";
        h << "      color: var(--text);\n";
        h << "      display: flex;\n";
        h << "      align-items: center;\n";
        h << "      gap: 8px;\n";
        h << "    }\n";
        h << "    .card-badge {\n";
        h << "      font-size: 10px;\n";
        h << "      padding: 2px 7px;\n";
        h << "      border-radius: 12px;\n";
        h << "      background: rgba(255, 255, 255, 0.08);\n";
        h << "      color: var(--primary);\n";
        h << "      font-weight: 600;\n";
        h << "      text-transform: uppercase;\n";
        h << "    }\n";
        h << "    .card-body {\n";
        h << "      font-size: 13px;\n";
        h << "      color: var(--text-muted);\n";
        h << "      line-height: 1.5;\n";
        h << "      white-space: pre-wrap;\n";
        h << "    }\n";
        h << "    .buttons-toolbar {\n";
        h << "      display: flex;\n";
        h << "      flex-wrap: wrap;\n";
        h << "      gap: 12px;\n";
        h << "      align-items: center;\n";
        h << "      padding-top: 10px;\n";
        h << "      border-top: 1px solid var(--border);\n";
        h << "    }\n";
        h << "    .btn {\n";
        h << "      background: linear-gradient(135deg, var(--primary), var(--accent));\n";
        h << "      color: #050811;\n";
        h << "      border: none;\n";
        h << "      border-radius: 10px;\n";
        h << "      padding: 10px 20px;\n";
        h << "      font-size: 13px;\n";
        h << "      font-weight: 700;\n";
        h << "      letter-spacing: 0.5px;\n";
        h << "      cursor: pointer;\n";
        h << "      transition: all 0.2s ease;\n";
        h << "      box-shadow: 0 4px 15px var(--border-glow);\n";
        h << "      display: inline-flex;\n";
        h << "      align-items: center;\n";
        h << "      gap: 6px;\n";
        h << "    }\n";
        h << "    .btn:hover {\n";
        h << "      transform: translateY(-2px);\n";
        h << "      filter: brightness(1.15);\n";
        h << "      box-shadow: 0 8px 25px var(--border-glow);\n";
        h << "    }\n";
        h << "    .btn:active {\n";
        h << "      transform: scale(0.97);\n";
        h << "    }\n";
        h << "    .log-drawer {\n";
        h << "      background: rgba(0,0,0,0.45);\n";
        h << "      border: 1px solid var(--border);\n";
        h << "      border-radius: 10px;\n";
        h << "      padding: 12px;\n";
        h << "      font-family: monospace;\n";
        h << "      font-size: 11px;\n";
        h << "      color: var(--text-muted);\n";
        h << "      max-height: 110px;\n";
        h << "      overflow-y: auto;\n";
        h << "    }\n";
        h << "    .log-entry {\n";
        h << "      line-height: 1.6;\n";
        h << "    }\n";
        h << "    .log-success { color: var(--primary); }\n";
        h << "    .log-action { color: #38bdf8; }\n";
        h << "    .code-toggle {\n";
        h << "      margin-left: auto;\n";
        h << "      background: transparent;\n";
        h << "      border: 1px solid var(--border);\n";
        h << "      color: var(--text-muted);\n";
        h << "      padding: 8px 14px;\n";
        h << "      border-radius: 8px;\n";
        h << "      font-size: 12px;\n";
        h << "      cursor: pointer;\n";
        h << "    }\n";
        h << "    .code-toggle:hover { color: var(--text); border-color: var(--primary); }\n";
        h << "    .code-panel {\n";
        h << "      display: none;\n";
        h << "      background: #04060b;\n";
        h << "      border: 1px solid var(--border);\n";
        h << "      border-radius: 10px;\n";
        h << "      padding: 16px;\n";
        h << "      font-family: monospace;\n";
        h << "      font-size: 12px;\n";
        h << "      color: #38bdf8;\n";
        h << "      white-space: pre-wrap;\n";
        h << "      max-height: 200px;\n";
        h << "      overflow-y: auto;\n";
        h << "    }\n";
        h << "  </style>\n";
        h << "</head>\n";
        h << "<body>\n";
        h << "  <div class=\"window\">\n";
        h << "    <div class=\"title-bar\">\n";
        h << "      <div class=\"traffic-lights\">\n";
        h << "        <div class=\"dot dot-close\" title=\"Cerrar\"></div>\n";
        h << "        <div class=\"dot dot-min\" title=\"Minimizar\"></div>\n";
        h << "        <div class=\"dot dot-max\" title=\"Pantalla Completa\"></div>\n";
        h << "      </div>\n";
        h << "      <div class=\"window-title\">\n";
        h << "        <span>" << escape_html(title) << "</span>\n";
        h << "        <span class=\"profile-badge\">" << specs.name << "</span>\n";
        h << "      </div>\n";
        h << "      <div class=\"window-status\">\n";
        h << "        <span id=\"fps-display\" class=\"fps-counter\">" << specs.target_fps << " FPS</span>\n";
        h << "        <span id=\"clock-display\">--:--:--</span>\n";
        h << "        <span>🔋 98%</span>\n";
        h << "      </div>\n";
        h << "    </div>\n";
        h << "    <div class=\"content-area\">\n";
        h << "      <div class=\"cards-grid\">\n";
        for (const auto& c : cards) {
            h << "        <div class=\"card\">\n";
            h << "          <div class=\"card-header\">\n";
            std::string icon_display = (c.icon.empty() ? "✦" : c.icon) + " ";
            if (!c.icon.empty() && c.title.find(c.icon) != std::string::npos) {
                icon_display = "";
            }
            h << "            <div class=\"card-title\">" << icon_display << escape_html(c.title) << "</div>\n";
            if (!c.badge.empty()) {
                h << "            <div class=\"card-badge\">" << escape_html(c.badge) << "</div>\n";
            }
            h << "          </div>\n";
            h << "          <div class=\"card-body\">" << escape_html(c.text) << "</div>\n";
            h << "        </div>\n";
        }
        h << "      </div>\n";
        h << "      <div class=\"buttons-toolbar\">\n";
        for (size_t i = 0; i < buttons.size(); ++i) {
            const auto& b = buttons[i];
            std::string label = (!b.snippet.empty() ? "⚡ " : "") + escape_html(b.text);
            h << "        <button class=\"btn\" onclick=\"onButtonClick(" << i << ")\">" 
              << label << "</button>\n";
        }
        h << "        <button class=\"code-toggle\" onclick=\"toggleCode()\">⚡ Ver Código .loop</button>\n";
        h << "      </div>\n";
        h << "      <div id=\"code-panel\" class=\"code-panel\">\n";
        h << "        <div style=\"display:flex;justify-content:space-between;margin-bottom:8px;\">\n";
        h << "          <strong style=\"color:#fff;\">Código Fuente Looping:</strong>\n";
        h << "          <button class=\"btn\" style=\"padding:4px 10px;font-size:11px;\" onclick=\"copyCode()\">Copiar</button>\n";
        h << "        </div>\n";
        h << "        <pre id=\"code-text\">" << escape_html(emit_loop_script()) << "</pre>\n";
        h << "      </div>\n";
        h << "      <div class=\"log-drawer\" id=\"window-log\">\n";
        h << "        <div class=\"log-entry log-success\">[Loop OS] Ventana dinámica '" << escape_html(title) << "' inicializada (" << specs.pipeline << ").</div>\n";
        h << "      </div>\n";
        h << "    </div>\n";
        h << "  </div>\n";
        h << "  <script>\n";
        h << "    const buttonConfigs = [\n";
        for (size_t i = 0; i < buttons.size(); ++i) {
            const auto& b = buttons[i];
            h << "      { text: \"" << escape_js(b.text) << "\", action: \"" << escape_js(b.action) 
              << "\", snippet: \"" << escape_js(b.snippet) << "\" }";
            if (i + 1 < buttons.size()) h << ",";
            h << "\n";
        }
        h << "    ];\n";
        h << "    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();\n";
        h << "    function playTone(freq, durMs) {\n";
        h << "      try {\n";
        h << "        if (audioCtx.state === 'suspended') audioCtx.resume();\n";
        h << "        const osc = audioCtx.createOscillator();\n";
        h << "        const gain = audioCtx.createGain();\n";
        h << "        osc.type = 'sine';\n";
        h << "        osc.frequency.setValueAtTime(freq, audioCtx.currentTime);\n";
        h << "        gain.gain.setValueAtTime(0.12, audioCtx.currentTime);\n";
        h << "        gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + durMs / 1000);\n";
        h << "        osc.connect(gain);\n";
        h << "        gain.connect(audioCtx.destination);\n";
        h << "        osc.start();\n";
        h << "        osc.stop(audioCtx.currentTime + durMs / 1000);\n";
        h << "      } catch(e) {}\n";
        h << "    }\n";
        h << "    function appendLog(msg, type = 'log-success') {\n";
        h << "      const log = document.getElementById('window-log');\n";
        h << "      const now = new Date().toTimeString().split(' ')[0];\n";
        h << "      const div = document.createElement('div');\n";
        h << "      div.className = 'log-entry ' + type;\n";
        h << "      div.textContent = '[' + now + '] ' + msg;\n";
        h << "      log.appendChild(div);\n";
        h << "      log.scrollTop = log.scrollHeight;\n";
        h << "    }\n";
        h << "    function onButtonClick(idx) {\n";
        h << "      const cfg = buttonConfigs[idx];\n";
        h << "      if (!cfg) return;\n";
        h << "      playTone(620, 90);\n";
        h << "      appendLog(\"Botón '\" + cfg.text + \"' presionado → Acción: \" + cfg.action, 'log-action');\n";
        h << "      if (cfg.snippet && cfg.snippet.trim().length > 0) {\n";
        h << "        const lines = cfg.snippet.split('\\n');\n";
        h << "        for (const line of lines) {\n";
        h << "          if (line.trim().length > 0) {\n";
        h << "            appendLog(\"  ⚡ \" + line, 'log-success');\n";
        h << "          }\n";
        h << "        }\n";
        h << "      }\n";
        h << "    }\n";
        h << "    function toggleCode() {\n";
        h << "      const p = document.getElementById('code-panel');\n";
        h << "      p.style.display = (p.style.display === 'block') ? 'none' : 'block';\n";
        h << "    }\n";
        h << "    function copyCode() {\n";
        h << "      const code = document.getElementById('code-text').innerText;\n";
        h << "      navigator.clipboard.writeText(code);\n";
        h << "      appendLog('Código .loop copiado al portapapeles', 'log-action');\n";
        h << "    }\n";
        h << "    document.querySelector('.dot-close').addEventListener('click', () => {\n";
        h << "      playTone(330, 120);\n";
        h << "      const win = document.querySelector('.window');\n";
        h << "      win.style.transform = 'scale(0.85)';\n";
        h << "      win.style.opacity = '0';\n";
        h << "      setTimeout(() => {\n";
        h << "        document.body.innerHTML = '<div style=\"font-family:sans-serif;color:#94a3b8;display:flex;align-items:center;justify-content:center;height:100vh;flex-direction:column;gap:12px;\"><h2>Ventana cerrada</h2><p>Recarga la página para volver a abrir.</p></div>';\n";
        h << "      }, 250);\n";
        h << "    });\n";
        h << "    document.querySelector('.dot-min').addEventListener('click', () => {\n";
        h << "      playTone(440, 80);\n";
        h << "      const c = document.querySelector('.content-area');\n";
        h << "      c.style.display = (c.style.display === 'none') ? 'flex' : 'none';\n";
        h << "    });\n";
        h << "    document.querySelector('.dot-max').addEventListener('click', () => {\n";
        h << "      playTone(880, 80);\n";
        h << "      if (!document.fullscreenElement) {\n";
        h << "        document.documentElement.requestFullscreen().catch(() => {});\n";
        h << "      } else {\n";
        h << "        document.exitFullscreen().catch(() => {});\n";
        h << "      }\n";
        h << "    });\n";
        h << "    let frameCount = 0;\n";
        h << "    let lastFpsUpdate = performance.now();\n";
        h << "    const fpsEl = document.getElementById('fps-display');\n";
        h << "    function fpsLoop() {\n";
        h << "      frameCount++;\n";
        h << "      const now = performance.now();\n";
        h << "      if (now - lastFpsUpdate >= 500) {\n";
        h << "        const fps = Math.round((frameCount * 1000) / (now - lastFpsUpdate));\n";
        h << "        if (fpsEl) fpsEl.textContent = fps + ' FPS';\n";
        h << "        frameCount = 0;\n";
        h << "        lastFpsUpdate = now;\n";
        h << "      }\n";
        h << "      requestAnimationFrame(fpsLoop);\n";
        h << "    }\n";
        h << "    requestAnimationFrame(fpsLoop);\n";
        h << "    function updateClock() {\n";
        h << "      const clockEl = document.getElementById('clock-display');\n";
        h << "      if (clockEl) {\n";
        h << "        const d = new Date();\n";
        h << "        clockEl.textContent = d.toTimeString().split(' ')[0];\n";
        h << "      }\n";
        h << "    }\n";
        h << "    setInterval(updateClock, 1000);\n";
        h << "    updateClock();\n";
        if (!tones.empty()) {
            h << "    const initTones = [";
            for (size_t i = 0; i < tones.size(); ++i) {
                if (i > 0) h << ", ";
                h << "[" << tones[i].freq_hz << ", " << tones[i].duration_ms << "]";
            }
            h << "];\n";
            h << "    window.addEventListener('click', () => {\n";
            h << "      if (audioCtx.state === 'suspended') audioCtx.resume();\n";
            h << "      initTones.forEach((t, idx) => {\n";
            h << "        setTimeout(() => playTone(t[0], t[1]), idx * 120);\n";
            h << "      });\n";
            h << "    }, { once: true });\n";
        }
        h << "  </script>\n";
        h << "</body>\n";
        h << "</html>\n";
        return h.str();
    }

    std::string render_ascii() const {
        std::ostringstream ss;
        UIProfileSpecs specs = resolve_ui_profile(target_ui);

        ss << "\n" << color::CYAN << "  ╔══════════════════════════════════════════════════════════════════════════════════╗" << color::RESET << "\n";
        ss << "  ║ \033[31m●\033[0m \033[33m●\033[0m \033[32m●\033[0m  " 
           << color::BOLD << color::WHITE << title << color::RESET 
           << " [" << static_cast<int>(width) << "x" << static_cast<int>(height) << "] "
           << color::CYAN << "«" << specs.name << " " << specs.target_fps << "Hz»" << color::RESET << "\n";
        ss << color::CYAN << "  ╠══════════════════════════════════════════════════════════════════════════════════╣" << color::RESET << "\n";

        if (cards.empty()) {
            ss << "  ║  " << color::YELLOW << "ℹ [VENTANA VACÍA] Usa window.add_card(...) para agregar tarjetas dinámicas." << color::RESET << "\n";
        } else {
            for (size_t i = 0; i < cards.size(); ++i) {
                const auto& c = cards[i];
                std::string icon_display = c.icon.empty() ? "✦ " : (c.icon + " ");
                if (!c.icon.empty() && c.title.find(c.icon) != std::string::npos) {
                    icon_display = "";
                }
                ss << "  ║  " << color::GREEN << icon_display
                   << color::BOLD << c.title << color::RESET;
                if (!c.badge.empty()) {
                    ss << "  " << color::CYAN << "[" << c.badge << "]" << color::RESET;
                }
                ss << "\n";
                std::stringstream lines(c.text);
                std::string l;
                while (std::getline(lines, l)) {
                    ss << "  ║    " << color::WHITE << l << color::RESET << "\n";
                }
                if (i + 1 < cards.size()) {
                    ss << color::CYAN << "  ╟──────────────────────────────────────────────────────────────────────────────────╢" << color::RESET << "\n";
                }
            }
        }

        if (!buttons.empty()) {
            ss << color::CYAN << "  ╠══════════════════════════════════════════════════════════════════════════════════╣" << color::RESET << "\n";
            ss << "  ║  ";
            for (const auto& b : buttons) {
                ss << "\033[44m\033[1m[ " << b.text << " ]\033[0m  ";
            }
            ss << "\n";
        }

        ss << color::CYAN << "  ╚══════════════════════════════════════════════════════════════════════════════════╝" << color::RESET << "\n";
        return ss.str();
    }

    bool save_loop(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            std::string dir = path.substr(0, slash);
            std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
            system(mkdir_cmd.c_str());
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_loop_script();
        return true;
    }

    bool save_html(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            std::string dir = path.substr(0, slash);
            std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
            system(mkdir_cmd.c_str());
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_html();
        return true;
    }

    std::string emit_native_gui_script() const {
        UIProfileSpecs specs = resolve_ui_profile(target_ui);
        std::ostringstream py;
        py << "#!/usr/bin/env python3\n";
        py << "# -*- coding: utf-8 -*-\n";
        py << "# =====================================================================\n";
        py << "# ⚡ LOOP OS NATIVE DESKTOP WINDOW: " << title << "\n";
        py << "# Generated by Looping Engine v2.5 (Direct Native OS - No HTML5 Required)\n";
        py << "# =====================================================================\n\n";
        py << "import tkinter as tk\n";
        py << "from tkinter import ttk\n";
        py << "import subprocess, sys, os, datetime\n\n";

        std::string bg_color = "#0b0f19";
        std::string card_bg = "#151d30";
        std::string card_border = "#22314e";
        std::string btn_bg = "#0284c7";
        std::string btn_fg = "#ffffff";
        std::string primary_color = specs.primary_color.empty() ? "#38bdf8" : specs.primary_color;

        if (specs.theme.find("aqua") != std::string::npos) {
            bg_color = "#04161f";
            card_bg = "#082736";
            card_border = "#134e6b";
            btn_bg = "#00b4d8";
            primary_color = "#00f5d4";
        } else if (specs.theme.find("indigo") != std::string::npos || specs.theme.find("fold") != std::string::npos) {
            bg_color = "#0d091a";
            card_bg = "#1a1333";
            card_border = "#352466";
            btn_bg = "#7c3aed";
            primary_color = "#c084fc";
        }

        std::string accent_color = (specs.accent_color.empty() || specs.accent_color == "#082f49") ? "#00f5d4" : specs.accent_color;

        py << "THEME = {\n";
        py << "    'bg': '" << bg_color << "',\n";
        py << "    'card_bg': '" << card_bg << "',\n";
        py << "    'card_border': '" << card_border << "',\n";
        py << "    'primary': '" << primary_color << "',\n";
        py << "    'accent': '" << accent_color << "',\n";
        py << "    'fg': '#f8fafc',\n";
        py << "    'sub_fg': '#94a3b8',\n";
        py << "    'btn_bg': '" << btn_bg << "',\n";
        py << "    'btn_fg': '" << btn_fg << "',\n";
        py << "    'log_bg': '#070a12',\n";
        py << "    'log_fg': '#10b981'\n";
        py << "}\n\n";

        py << "BUTTONS = [\n";
        for (const auto& b : buttons) {
            py << "    {'text': \"" << escape_py(b.text) << "\", 'action': \"" << escape_py(b.action) 
               << "\", 'snippet': \"" << escape_py(b.snippet) << "\"},\n";
        }
        py << "]\n\n";

        py << "class LoopNativeWindow(tk.Tk):\n";
        py << "    def __init__(self):\n";
        py << "        super().__init__()\n";
        py << "        self.title(\"" << escape_py(title) << " — Loop OS Native Window\")\n";
        py << "        self.geometry(f\"" << static_cast<int>(width) << "x" << static_cast<int>(height) << "\")\n";
        py << "        self.configure(bg=THEME['bg'])\n";
        py << "        self.minsize(580, 400)\n\n";
        py << "        self.setup_ui()\n";
        py << "        self.log(\"[Loop OS Native] Ventana '" << escape_py(title) << "' inicializada (" << specs.name << " " << specs.pipeline << ").\", 'success')\n\n";

        py << "    def setup_ui(self):\n";
        py << "        self.c_hdr = tk.Canvas(self, height=52, bg=THEME['card_bg'], highlightthickness=0)\n";
        py << "        self.c_hdr.pack(fill='x', side='top')\n";
        std::string t_prefix = (title.rfind("✦", 0) == 0) ? "" : "✦ ";
        py << "        self.c_hdr.create_text(20, 26, text=\"" << t_prefix << escape_py(title) << "\", anchor='w', fill=THEME['primary'], font=('Helvetica', 13, 'bold'))\n";
        py << "        self.c_hdr.create_rectangle(740, 13, 960, 39, fill=THEME['accent'], outline='', tags='hdr_badge_bg')\n";
        py << "        self.c_hdr.create_text(850, 26, text=\"" << specs.name << " • " << specs.target_fps << " FPS Direct\", fill='#0b0f19', font=('Helvetica', 9, 'bold'), tags='hdr_badge_txt')\n";
        py << "        def _on_hdr_resize(e):\n";
        py << "            w = e.width\n";
        py << "            self.c_hdr.coords('hdr_badge_bg', w - 210, 13, w - 16, 39)\n";
        py << "            self.c_hdr.coords('hdr_badge_txt', w - 113, 26)\n";
        py << "        self.c_hdr.bind('<Configure>', _on_hdr_resize)\n\n";

        py << "        main_frame = tk.Frame(self, bg=THEME['bg'], padx=14, pady=10)\n";
        py << "        main_frame.pack(fill='both', expand=True)\n\n";

        if (!cards.empty()) {
            py << "        cards_data = [\n";
            for (const auto& c : cards) {
                std::string card_t = (c.icon.empty() ? "✦ " : c.icon + " ") + c.title;
                py << "            {'title': \"" << escape_py(card_t) << "\", 'badge': \"" << escape_py(c.badge) << "\", 'text': \"" << escape_py(c.text) << "\"},\n";
            }
            py << "        ]\n";
            py << "        self.c_cards = tk.Canvas(main_frame, height=225, bg=THEME['bg'], highlightthickness=0)\n";
            py << "        self.c_cards.pack(fill='x', pady=(0, 10))\n";
            py << "        def _redraw_cards(e=None):\n";
            py << "            self.c_cards.delete('all')\n";
            py << "            w = self.c_cards.winfo_width()\n";
            py << "            if w < 100: w = 950\n";
            py << "            cols = 2 if w >= 600 else 1\n";
            py << "            gap = 14\n";
            py << "            cw = (w - gap) // cols if cols == 2 else w\n";
            py << "            ch = 98\n";
            py << "            for i, c in enumerate(cards_data):\n";
            py << "                col = i % cols\n";
            py << "                row = i // cols\n";
            py << "                x = col * (cw + gap)\n";
            py << "                y = row * (ch + 10)\n";
            py << "                self.c_cards.create_rectangle(x, y, x + cw, y + ch, fill=THEME['card_bg'], outline=THEME['card_border'], width=1)\n";
            py << "                self.c_cards.create_text(x + 14, y + 20, text=c['title'], anchor='w', fill=THEME['primary'], font=('Helvetica', 11, 'bold'))\n";
            py << "                if c['badge']:\n";
            py << "                    bw = len(c['badge']) * 7 + 16\n";
            py << "                    bx2 = x + cw - 12\n";
            py << "                    bx1 = bx2 - bw\n";
            py << "                    self.c_cards.create_rectangle(bx1, y + 10, bx2, y + 30, fill='#22314e', outline='')\n";
            py << "                    self.c_cards.create_text((bx1 + bx2) // 2, y + 20, text=c['badge'], fill=THEME['accent'], font=('Helvetica', 8, 'bold'))\n";
            py << "                self.c_cards.create_text(x + 14, y + 60, text=c['text'], anchor='w', fill=THEME['fg'], font=('Helvetica', 9), width=cw - 28)\n";
            py << "        self.c_cards.bind('<Configure>', _redraw_cards)\n";
            py << "        self.after(50, _redraw_cards)\n\n";
        }

        if (!inputs.empty() || !sliders.empty() || !toggles.empty() || !progress_bars.empty()) {
            py << "        ctrl_frame = tk.Frame(main_frame, bg=THEME['card_bg'], highlightbackground=THEME['card_border'], highlightthickness=1, padx=14, pady=10)\n";
            py << "        ctrl_frame.pack(fill='x', pady=(0, 10))\n\n";

            for (size_t i = 0; i < inputs.size(); ++i) {
                const auto& inp = inputs[i];
                py << "        tk.Label(ctrl_frame, text=\"Input [" << escape_py(inp.binding) << "]:\", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg']).pack(anchor='w')\n";
                py << "        self.inp_" << i << " = tk.Entry(ctrl_frame, bg='#1e293b', fg=THEME['fg'], insertbackground='white', highlightbackground=THEME['card_border'], relief='flat')\n";
                py << "        self.inp_" << i << ".insert(0, \"" << escape_py(inp.placeholder) << "\")\n";
                py << "        self.inp_" << i << ".pack(fill='x', pady=(2, 6))\n";
            }

            for (size_t i = 0; i < sliders.size(); ++i) {
                const auto& sl = sliders[i];
                py << "        self.sl_lbl_" << i << " = tk.Label(ctrl_frame, text=\"" << escape_py(sl.label) << ": " << sl.current_val << "\", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg'])\n";
                py << "        self.sl_lbl_" << i << ".pack(anchor='w')\n";
                py << "        def on_sl_" << i << "(val):\n";
                py << "            self.sl_lbl_" << i << ".config(text=f\"" << escape_py(sl.label) << ": {float(val):.0f}\")\n";
                py << "        self.sl_" << i << " = tk.Scale(ctrl_frame, from_=" << sl.min_val << ", to=" << sl.max_val 
                   << ", orient='horizontal', bg=THEME['card_bg'], fg=THEME['fg'], highlightthickness=0, troughcolor=THEME['log_bg'], activebackground=THEME['primary'], showvalue=0, command=on_sl_" << i << ")\n";
                py << "        self.sl_" << i << ".set(" << sl.current_val << ")\n";
                py << "        self.sl_" << i << ".pack(fill='x', pady=(2, 6))\n";
            }

            for (size_t i = 0; i < toggles.size(); ++i) {
                const auto& tg = toggles[i];
                py << "        self.tg_var_" << i << " = tk.BooleanVar(value=" << (tg.is_checked ? "True" : "False") << ")\n";
                py << "        def on_tg_" << i << "():\n";
                py << "            st = 'ACTIVADO' if self.tg_var_" << i << ".get() else 'DESACTIVADO'\n";
                py << "            self.log(f\"Toggle '" << escape_py(tg.label) << "' -> {st}\", 'action')\n";
                py << "        tk.Checkbutton(ctrl_frame, text=\"" << escape_py(tg.label) << "\", variable=self.tg_var_" << i << ", command=on_tg_" << i 
                   << ", font=('Helvetica', 9), fg=THEME['fg'], bg=THEME['card_bg'], selectcolor=THEME['log_bg'], activebackground=THEME['card_bg']).pack(anchor='w', pady=2)\n";
            }

            for (size_t i = 0; i < progress_bars.size(); ++i) {
                const auto& pr = progress_bars[i];
                py << "        tk.Label(ctrl_frame, text=\"" << escape_py(pr.label) << " (" << pr.progress << "%)\", font=('Helvetica', 9, 'bold'), fg=THEME['sub_fg'], bg=THEME['card_bg']).pack(anchor='w', pady=(4, 2))\n";
                py << "        self.c_pr_" << i << " = tk.Canvas(ctrl_frame, height=12, bg=THEME['log_bg'], highlightthickness=1, highlightbackground=THEME['card_border'])\n";
                py << "        self.c_pr_" << i << ".pack(fill='x', pady=(0, 4))\n";
                py << "        def _draw_pr_" << i << "(e=None):\n";
                py << "            self.c_pr_" << i << ".delete('all')\n";
                py << "            w = self.c_pr_" << i << ".winfo_width()\n";
                py << "            pct = " << pr.progress << "\n";
                py << "            self.c_pr_" << i << ".create_rectangle(0, 0, int(w * pct / 100), 12, fill=THEME['accent'], outline='')\n";
                py << "        self.c_pr_" << i << ".bind('<Configure>', _draw_pr_" << i << ")\n";
                py << "        self.after(60, _draw_pr_" << i << ")\n";
            }
        }

        py << "        # Buttons Toolbar\n";
        py << "        btn_bar = tk.Frame(main_frame, bg=THEME['bg'])\n";
        py << "        btn_bar.pack(fill='x', pady=(2, 10))\n\n";

        for (size_t i = 0; i < buttons.size(); ++i) {
            const auto& b = buttons[i];
            std::string label = (!b.snippet.empty() ? "⚡ " : "") + b.text;
            py << "        btn_" << i << " = tk.Button(btn_bar, text=\"" << escape_py(label) 
               << "\", font=('Helvetica', 9, 'bold'), bg=THEME['btn_bg'], fg=THEME['btn_fg'], relief='flat', padx=8, pady=5, activebackground=THEME['primary'], cursor='hand2', command=lambda idx=" << i << ": self.on_btn_click(idx))\n";
            py << "        btn_" << i << ".pack(side='left', padx=(0, 8))\n";
        }

        py << "\n        # Interactive Console Log Drawer\n";
        py << "        log_frame = tk.Frame(main_frame, bg=THEME['log_bg'], highlightbackground=THEME['card_border'], highlightthickness=1)\n";
        py << "        log_frame.pack(fill='both', expand=True)\n";
        py << "        log_scroll = tk.Scrollbar(log_frame)\n";
        py << "        log_scroll.pack(side='right', fill='y')\n";
        py << "        self.log_txt = tk.Text(log_frame, bg=THEME['log_bg'], fg=THEME['log_fg'], font=('Courier', 10), yscrollcommand=log_scroll.set, wrap='word', height=7, padx=10, pady=8, relief='flat')\n";
        py << "        self.log_txt.pack(fill='both', expand=True)\n";
        py << "        log_scroll.config(command=self.log_txt.yview)\n";
        py << "        self.log_txt.tag_config('action', foreground='#38bdf8')\n";
        py << "        self.log_txt.tag_config('success', foreground='#10b981')\n";
        py << "        self.log_txt.tag_config('snippet', foreground='#facc15')\n\n";

        py << "    def log(self, msg, tag='success'):\n";
        py << "        now = datetime.datetime.now().strftime('%H:%M:%S')\n";
        py << "        self.log_txt.insert('end', f'[{now}] {msg}\\n', tag)\n";
        py << "        self.log_txt.see('end')\n\n";

        py << "    def on_btn_click(self, idx):\n";
        py << "        cfg = BUTTONS[idx]\n";
        py << "        try:\n";
        py << "            self.bell()\n";
        py << "        except Exception:\n";
        py << "            pass\n";
        py << "        self.log(f\"Botón '{cfg['text']}' presionado → Acción: {cfg['action']}\", 'action')\n";
        py << "        snip = cfg.get('snippet', '').strip()\n";
        py << "        if snip:\n";
        py << "            for line in snip.splitlines():\n";
        py << "                if line.strip():\n";
        py << "                    self.log(f\"  ⚡ {line}\", 'snippet')\n";
        py << "            if snip.startswith('#!python') or snip.startswith('import '):\n";
        py << "                try:\n";
        py << "                    exec(snip, globals())\n";
        py << "                except Exception as e:\n";
        py << "                    self.log(f\"[Python Error] {e}\", 'action')\n";
        py << "            else:\n";
        py << "                candidates = ['./bin/looping', './LoopingEngine/cpp/looping', './looping', 'looping']\n";
        py << "                bin_path = next((c for c in candidates if os.path.exists(c)), 'looping')\n";
        py << "                try:\n";
        py << "                    res = subprocess.run([bin_path, 'eval', snip], capture_output=True, text=True, timeout=3)\n";
        py << "                    if res.stdout.strip():\n";
        py << "                        for l in res.stdout.strip().splitlines():\n";
        py << "                            self.log(f\"    {l}\", 'success')\n";
        py << "                except Exception as e:\n";
        py << "                    pass\n\n";

        py << "if __name__ == '__main__':\n";
        py << "    app = LoopNativeWindow()\n";
        py << "    app.mainloop()\n";

        return py.str();
    }

    bool save_native_gui(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            std::string dir = path.substr(0, slash);
            std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
            system(mkdir_cmd.c_str());
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_native_gui_script();
        return true;
    }

    bool show_native(bool launch_interactive = true) const {
        std::cout << render_ascii() << "\n";
        system("mkdir -p build");

        std::string py_path = "build/" + app_name + "_native.py";
        save_native_gui(py_path);

        std::cout << color::GREEN << "✔ [NATIVE OS WINDOW]" << color::RESET << " Native desktop window synthesized successfully:\n";
        std::cout << "  • Native GUI App: " << color::CYAN << py_path << color::RESET << " (Direct OS / Tkinter Native Engine)\n";

        if (launch_interactive) {
#ifdef _WIN32
            std::string open_cmd = "start pythonw \"" + py_path + "\"";
#else
            std::string open_cmd = "python3 \"" + py_path + "\" >/dev/null 2>&1 &";
#endif
            std::cout << color::CYAN << "[LAUNCH NATIVE GUI]" << color::RESET << " Launching native desktop OS window...\n";
            system(open_cmd.c_str());
        }
        return true;
    }

    bool show(bool launch_interactive = true, const std::string& mode = "native") const {
        std::cout << render_ascii() << "\n";
        system("mkdir -p build");

        std::string loop_path = "build/" + app_name + ".loop";
        std::string html_path = "build/" + app_name + ".html";
        std::string py_path = "build/" + app_name + "_native.py";

        save_loop(loop_path);
        save_html(html_path);
        save_native_gui(py_path);

        std::cout << color::GREEN << "✔ [DYNAMIC WINDOW]" << color::RESET << " Window synthesized successfully:\n";
        std::cout << "  • Source Script: " << color::CYAN << loop_path << color::RESET << "\n";
        std::cout << "  • Native OS GUI: " << color::CYAN << py_path << color::RESET << " (Pure Desktop OS Window)\n";
        std::cout << "  • Interactive HTML5: " << color::CYAN << html_path << color::RESET << "\n";

        if (launch_interactive) {
            if (mode == "html" || mode == "web") {
#ifdef __APPLE__
                std::cout << color::CYAN << "[LAUNCH GUI]" << color::RESET << " Opening dynamic window in web viewer...\n";
                std::string open_cmd = "open \"" + html_path + "\"";
                system(open_cmd.c_str());
#elif defined(_WIN32)
                std::string open_cmd = "start \"\" \"" + html_path + "\"";
                system(open_cmd.c_str());
#else
                std::string open_cmd = "xdg-open \"" + html_path + "\" 2>/dev/null &";
                system(open_cmd.c_str());
#endif
            } else {
#ifdef _WIN32
                std::string open_cmd = "start pythonw \"" + py_path + "\"";
#else
                std::string open_cmd = "python3 \"" + py_path + "\" >/dev/null 2>&1 &";
#endif
                std::cout << color::CYAN << "[LAUNCH NATIVE GUI]" << color::RESET << " Opening native desktop OS window...\n";
                system(open_cmd.c_str());
            }
        }
        return true;
    }

    static std::string derive_badge(const std::string& title) {
        std::string lower = title;
        for (char& c : lower) c = std::tolower(c);
        if (lower.find("juego") != std::string::npos || lower.find("game") != std::string::npos) return "60 FPS NATIVE";
        if (lower.find("métrica") != std::string::npos || lower.find("metric") != std::string::npos || lower.find("stats") != std::string::npos) return "TELEMETRÍA";
        if (lower.find("sistema") != std::string::npos || lower.find("kernel") != std::string::npos) return "SISTEMA";
        if (lower.find("red") != std::string::npos || lower.find("net") != std::string::npos) return "ONLINE";
        if (lower.find("hardware") != std::string::npos || lower.find("apu") != std::string::npos) return "240HZ DIRECT";
        return "ACTIVO";
    }

    static std::string derive_icon(const std::string& title) {
        std::string lower = title;
        for (char& c : lower) c = std::tolower(c);
        if (lower.find("juego") != std::string::npos || lower.find("game") != std::string::npos) return "🎮";
        if (lower.find("métrica") != std::string::npos || lower.find("metric") != std::string::npos || lower.find("stats") != std::string::npos) return "📊";
        if (lower.find("sistema") != std::string::npos || lower.find("kernel") != std::string::npos) return "⚡";
        if (lower.find("red") != std::string::npos || lower.find("net") != std::string::npos) return "🌐";
        if (lower.find("servicio") != std::string::npos || lower.find("módulo") != std::string::npos) return "📦";
        if (lower.find("control") != std::string::npos || lower.find("panel") != std::string::npos) return "🎯";
        return "🌟";
    }

    static std::string sanitize_id(const std::string& s) {
        std::string out;
        for (char c : s) {
            if (std::isalnum(static_cast<unsigned char>(c)) || c == '_') out += c;
            else if (c == ' ' || c == '-') out += '_';
        }
        if (out.empty() || std::isdigit(static_cast<unsigned char>(out[0]))) out = "win_" + out;
        return out;
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

    static std::string escape_html(const std::string& in) {
        std::string out;
        for (char c : in) {
            if (c == '<') out += "&lt;";
            else if (c == '>') out += "&gt;";
            else if (c == '&') out += "&amp;";
            else if (c == '"') out += "&quot;";
            else out += c;
        }
        return out;
    }

    static std::string escape_js(const std::string& in) {
        std::string out;
        for (char c : in) {
            if (c == '\\') out += "\\\\";
            else if (c == '"') out += "\\\"";
            else if (c == '\'') out += "\\'";
            else if (c == '\n') out += "\\n";
            else if (c == '\r') out += "\\r";
            else if (c == '\t') out += "\\t";
            else out += c;
        }
        return out;
    }

    static std::string escape_py(const std::string& in) {
        std::string out;
        for (char c : in) {
            if (c == '\\') out += "\\\\";
            else if (c == '"') out += "\\\"";
            else if (c == '\n') out += "\\n";
            else if (c == '\r') out += "\\r";
            else if (c == '\t') out += "\\t";
            else out += c;
        }
        return out;
    }
};

// ── SwiftUI Code Generator & Transpiler Subsystem (v2.9) ──
class SwiftUIEmitter {
public:
    static std::string format_color(const std::string& c) {
        if (c.empty()) return ".primary";
        if (c[0] == '.') return c;
        if (c == "blue" || c == "red" || c == "green" || c == "cyan" || c == "yellow" ||
            c == "purple" || c == "orange" || c == "pink" || c == "gray" || c == "white" || c == "black" ||
            c == "clear" || c == "mint" || c == "teal" || c == "indigo") {
            return "." + c;
        }
        if (c == "ultraThinMaterial" || c == "thinMaterial" || c == "regularMaterial" || c == "thickMaterial") {
            return "." + c;
        }
        return "Color(\"" + c + "\")";
    }

    static std::string emit_node(const std::shared_ptr<SwiftUIViewNode>& node, int indent_level) {
        if (!node) return "";
        std::string ind(indent_level * 4, ' ');
        std::ostringstream ss;

        switch (node->type) {
            case SwiftUIViewType::VStack: {
                ss << ind << "VStack";
                std::vector<std::string> params;
                if (node->attributes.count("alignment")) params.push_back("alignment: " + node->attributes.at("alignment"));
                if (node->attributes.count("spacing")) params.push_back("spacing: " + node->attributes.at("spacing"));
                if (!params.empty()) {
                    ss << "(";
                    for (size_t i = 0; i < params.size(); ++i) {
                        if (i > 0) ss << ", ";
                        ss << params[i];
                    }
                    ss << ")";
                }
                ss << " {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::HStack: {
                ss << ind << "HStack";
                std::vector<std::string> params;
                if (node->attributes.count("alignment")) params.push_back("alignment: " + node->attributes.at("alignment"));
                if (node->attributes.count("spacing")) params.push_back("spacing: " + node->attributes.at("spacing"));
                if (!params.empty()) {
                    ss << "(";
                    for (size_t i = 0; i < params.size(); ++i) {
                        if (i > 0) ss << ", ";
                        ss << params[i];
                    }
                    ss << ")";
                }
                ss << " {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::ZStack: {
                ss << ind << "ZStack";
                if (node->attributes.count("alignment")) ss << "(alignment: " + node->attributes.at("alignment") + ")";
                ss << " {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::List: {
                ss << ind << "List {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::ScrollView: {
                ss << ind << "ScrollView {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::Section: {
                ss << ind << "Section";
                if (!node->primary_arg.empty()) ss << "(header: Text(\"" << node->primary_arg << "\"))";
                ss << " {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::Group: {
                ss << ind << "Group {\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::ForEach: {
                ss << ind << "ForEach(" << (node->foreach_collection.empty() ? "0..<5" : node->foreach_collection) << ") { "
                   << (node->foreach_item_var.empty() ? "item" : node->foreach_item_var) << " in\n";
                for (const auto& ch : node->children) {
                    ss << emit_node(ch, indent_level + 1) << "\n";
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::Text: {
                std::string res;
                for (size_t i = 0; i < node->primary_arg.size(); ++i) {
                    if (node->primary_arg[i] == '$' && i + 1 < node->primary_arg.size() && (std::isalnum(static_cast<unsigned char>(node->primary_arg[i+1])) || node->primary_arg[i+1] == '_')) {
                        res += "\\(";
                        i++;
                        while (i < node->primary_arg.size() && (std::isalnum(static_cast<unsigned char>(node->primary_arg[i])) || node->primary_arg[i] == '_')) {
                            res += node->primary_arg[i++];
                        }
                        res += ")";
                        i--;
                    } else {
                        res += node->primary_arg[i];
                    }
                }
                ss << ind << "Text(\"" << res << "\")";
                break;
            }
            case SwiftUIViewType::Button: {
                ss << ind << "Button(\"" << node->primary_arg << "\") {\n";
                if (!node->action_code.empty()) {
                    std::istringstream act_s(node->action_code);
                    std::string al;
                    while (std::getline(act_s, al)) {
                        std::string tal = Parser::trim(al);
                        if (!tal.empty()) ss << ind << "    " << tal << "\n";
                    }
                }
                ss << ind << "}";
                break;
            }
            case SwiftUIViewType::Image: {
                if (node->attributes.count("systemName")) {
                    std::string sys = Parser::trim_quotes(node->attributes.at("systemName"));
                    ss << ind << "Image(systemName: \"" << sys << "\")";
                } else if (!node->primary_arg.empty() && node->primary_arg.find('/') == std::string::npos && node->primary_arg.rfind(".png") == std::string::npos) {
                    ss << ind << "Image(systemName: \"" << Parser::trim_quotes(node->primary_arg) << "\")";
                } else {
                    ss << ind << "Image(\"" << Parser::trim_quotes(node->primary_arg) << "\")";
                }
                break;
            }
            case SwiftUIViewType::TextField: {
                std::string b = node->binding_var.empty() ? "text" : node->binding_var;
                ss << ind << "TextField(\"" << node->primary_arg << "\", text: $" << b << ")";
                break;
            }
            case SwiftUIViewType::Toggle: {
                std::string b = node->binding_var.empty() ? "isOn" : node->binding_var;
                ss << ind << "Toggle(\"" << node->primary_arg << "\", isOn: $" << b << ")";
                break;
            }
            case SwiftUIViewType::Slider: {
                std::string b = node->binding_var.empty() ? "value" : node->binding_var;
                ss << ind << "Slider(value: $" << b << ")";
                break;
            }
            case SwiftUIViewType::ProgressView: {
                std::string pval = node->attributes.count("value") ? node->attributes.at("value") : node->primary_arg;
                if (!pval.empty()) {
                    ss << ind << "ProgressView(value: " << pval << ")";
                } else {
                    ss << ind << "ProgressView()";
                }
                break;
            }
            case SwiftUIViewType::Spacer: {
                ss << ind << "Spacer()";
                break;
            }
            case SwiftUIViewType::Divider: {
                ss << ind << "Divider()";
                break;
            }
            case SwiftUIViewType::Badge: {
                ss << ind << "Text(\"" << node->primary_arg << "\")\n"
                   << ind << "    .font(.caption2)\n"
                   << ind << "    .fontWeight(.bold)\n"
                   << ind << "    .padding(.horizontal, 6)\n"
                   << ind << "    .padding(.vertical, 2)\n"
                   << ind << "    .background(.blue)\n"
                   << ind << "    .foregroundColor(.white)\n"
                   << ind << "    .cornerRadius(6)";
                break;
            }
            case SwiftUIViewType::Circle: {
                ss << ind << "Circle()";
                break;
            }
            case SwiftUIViewType::Rectangle: {
                ss << ind << "Rectangle()";
                break;
            }
            case SwiftUIViewType::RoundedRectangle: {
                std::string r = node->attributes.count("cornerRadius") ? node->attributes.at("cornerRadius") : "10";
                ss << ind << "RoundedRectangle(cornerRadius: " << r << ")";
                break;
            }
            case SwiftUIViewType::Color: {
                ss << ind << format_color(node->primary_arg);
                break;
            }
            case SwiftUIViewType::Custom: {
                ss << ind << (node->custom_name.empty() ? "CustomView" : node->custom_name) << "()";
                break;
            }
        }

        // Emit chained modifiers
        for (const auto& mod : node->modifiers) {
            ss << "\n" << ind << "    ." << mod.name;
            if (!mod.args.empty() || !mod.named_args.empty()) {
                ss << "(";
                bool first = true;
                for (const auto& a : mod.args) {
                    if (!first) ss << ", ";
                    if (mod.name == "foregroundColor" || mod.name == "foregroundStyle" || mod.name == "tint" || mod.name == "background") {
                        ss << format_color(a);
                    } else if (mod.name == "font" && !a.empty() && a[0] != '.') {
                        ss << "." + a;
                    } else if (mod.name == "fontWeight" && !a.empty() && a[0] != '.') {
                        ss << "." + a;
                    } else {
                        ss << a;
                    }
                    first = false;
                }
                for (const auto& kv : mod.named_args) {
                    if (!first) ss << ", ";
                    ss << kv.first << ": " << kv.second;
                    first = false;
                }
                ss << ")";
            } else {
                ss << "()";
            }
        }

        return ss.str();
    }

    static std::string emit_component(const std::shared_ptr<SwiftUIComponentDeclStmt>& comp) {
        if (!comp) return "";
        std::ostringstream ss;
        ss << "public struct " << comp->name << ": View {\n";

        for (const auto& st : comp->states) {
            std::string init_val = st.initial_expr_str.empty() ? "0" : st.initial_expr_str;
            ss << "    @State private var " << st.name << " = " << init_val << "\n";
        }
        if (!comp->states.empty()) ss << "\n";

        ss << "    public init() {}\n\n";
        ss << "    public var body: some View {\n";
        if (comp->root_view) {
            ss << emit_node(comp->root_view, 2);
        } else {
            ss << "        Text(\"" << comp->name << "\")";
        }

        for (const auto& mod : comp->root_modifiers) {
            ss << "\n        ." << mod.name;
            if (!mod.args.empty() || !mod.named_args.empty()) {
                ss << "(";
                bool first = true;
                for (const auto& a : mod.args) {
                    if (!first) ss << ", ";
                    ss << a;
                    first = false;
                }
                for (const auto& kv : mod.named_args) {
                    if (!first) ss << ", ";
                    ss << kv.first << ": " << kv.second;
                    first = false;
                }
                ss << ")";
            } else {
                ss << "()";
            }
        }

        ss << "\n    }\n}\n";
        return ss.str();
    }

    static std::string transpile_script(const std::string& source_code) {
        Parser parser(source_code);
        auto statements = parser.parse_script();

        std::vector<std::shared_ptr<SwiftUIComponentDeclStmt>> comps;
        std::vector<std::shared_ptr<SwiftUIViewRenderStmt>> renders;

        for (const auto& st : statements) {
            if (auto c = std::dynamic_pointer_cast<SwiftUIComponentDeclStmt>(st)) {
                comps.push_back(c);
            } else if (auto r = std::dynamic_pointer_cast<SwiftUIViewRenderStmt>(st)) {
                renders.push_back(r);
            }
        }

        std::ostringstream ss;
        ss << "// ═══════════════════════════════════════════════════════════════\n";
        ss << "// 🚀 COMPILED SWIFTUI SOURCE — Looping Engine v2.9\n";
        ss << "// Coki Studios — Universal Apple Ecosystem Target (iOS & macOS)\n";
        ss << "// ═══════════════════════════════════════════════════════════════\n\n";
        ss << "import SwiftUI\n\n";

        std::string primary_view_name = "ContentView";

        if (!comps.empty()) {
            primary_view_name = comps[0]->name;
            for (const auto& c : comps) {
                ss << emit_component(c) << "\n";
            }
        }

        if (!renders.empty() && comps.empty()) {
            ss << "public struct ContentView: View {\n";
            ss << "    public init() {}\n\n";
            ss << "    public var body: some View {\n";
            ss << emit_node(renders[0]->root_view, 2);
            for (const auto& mod : renders[0]->root_modifiers) {
                ss << "\n        ." << mod.name << "()";
            }
            ss << "\n    }\n}\n\n";
        }

        ss << "#Preview {\n";
        ss << "    " << primary_view_name << "()\n";
        ss << "}\n\n";

        ss << "@main\n";
        ss << "struct LoopingApp: App {\n";
        ss << "    var body: some Scene {\n";
        ss << "        WindowGroup {\n";
        ss << "            " << primary_view_name << "()\n";
        ss << "        }\n";
        ss << "    }\n";
        ss << "}\n";

        return ss.str();
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

        // SwiftUI Native Swift Target Compilation
        if (specs.code == "swiftui") {
            bool wants_swift_file = (out_file.size() >= 6 && out_file.substr(out_file.size() - 6) == ".swift");
            std::string swift_file = wants_swift_file ? out_file : (out_file + ".swift");

            size_t slash = swift_file.find_last_of("/\\");
            if (slash != std::string::npos) {
                std::string dir = swift_file.substr(0, slash);
                std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
                system(mkdir_cmd.c_str());
            }

            std::string swift_code = SwiftUIEmitter::transpile_script(source_code);
            std::ofstream swift_out(swift_file);
            if (!swift_out.is_open()) {
                std::cerr << "\033[31m❌ Error: Cannot write SwiftUI target to: " << swift_file << "\033[0m\n";
                return false;
            }
            swift_out << swift_code;
            swift_out.close();

            if (!wants_swift_file) {
                // Compile directly into native Mach-O executable using Apple swiftc
                std::string swiftc_cmd = "swiftc -parse-as-library \"" + swift_file + "\" -o \"" + out_file + "\" 2>/dev/null";
                int ret = system(swiftc_cmd.c_str());
                if (ret == 0) {
                    if (out_created_path) *out_created_path = out_file;
                    std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Native SwiftUI binary compiled to: " << out_file << " [Apple Ecosystem / SwiftUI Metal 120Hz]\n";
                    return true;
                }
            }

            if (out_created_path) *out_created_path = swift_file;
            std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Native SwiftUI artifact compiled to: " << swift_file << " [Apple Ecosystem / SwiftUI Metal 120Hz]\n";
            return true;
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

        // Packaging for Component 2 (.c2) bundles
        if (specs.code == "c2" || (out_file.size() >= 3 && out_file.substr(out_file.size() - 3) == ".c2")) {
            std::string c2_file = out_file;
            if (c2_file.size() < 3 || c2_file.substr(c2_file.size() - 3) != ".c2") {
                c2_file += ".c2";
            }
            char cwd_buf[2048];
            std::string abs_c2_file = c2_file;
            std::string abs_out_file = out_file;
            if (getcwd(cwd_buf, sizeof(cwd_buf)) != nullptr) {
                if (abs_c2_file.empty() || abs_c2_file[0] != '/') {
                    abs_c2_file = std::string(cwd_buf) + "/" + abs_c2_file;
                }
                if (abs_out_file.empty() || abs_out_file[0] != '/') {
                    abs_out_file = std::string(cwd_buf) + "/" + abs_out_file;
                }
            }
            std::string tmp_dir = "/tmp/c2_build_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count());
            system(("mkdir -p \"" + tmp_dir + "\"").c_str());

            // 1. Manifest
            std::ofstream mf(tmp_dir + "/manifest.json");
            mf << "{\n"
               << "  \"c2_version\": \"2.0\",\n"
               << "  \"component_id\": \"com.cokistudios.c2." << specs.code << "\",\n"
               << "  \"name\": \"" << specs.name << "\",\n"
               << "  \"target_device\": \"shine_all\",\n"
               << "  \"target_fps\": " << specs.target_fps << ",\n"
               << "  \"theme\": \"" << specs.theme << "\",\n"
               << "  \"primary_color\": \"" << specs.primary_color << "\",\n"
               << "  \"entrypoint\": \"source.loop\"\n"
               << "}\n";
            mf.close();

            // 2. Tokens
            std::ofstream tk(tmp_dir + "/tokens.json");
            tk << "{\n"
               << "  \"primary\": \"" << specs.primary_color << "\",\n"
               << "  \"accent\": \"" << specs.accent_color << "\",\n"
               << "  \"fps\": " << specs.target_fps << ",\n"
               << "  \"layout_mode\": \"" << specs.layout_mode << "\"\n"
               << "}\n";
            tk.close();

            // 3. Layout
            std::ofstream ly(tmp_dir + "/layout.json");
            ly << "{\n"
               << "  \"version\": \"2.0\",\n"
               << "  \"type\": \"modular_surface\",\n"
               << "  \"title\": \"" << specs.name << "\",\n"
               << "  \"components\": [\"dock\", \"widgets\", \"cards\"]\n"
               << "}\n";
            ly.close();

            // 4. Source
            system(("cp \"" + abs_out_file + "\" \"" + tmp_dir + "/source.loop\"").c_str());

            // 5. Signature
            std::string sig_cmd = "(cd \"" + tmp_dir + "\" && shasum -a 256 manifest.json tokens.json layout.json source.loop > signature.sha256)";
            system(sig_cmd.c_str());

            // 6. Zip into .c2 (Remove pre-existing file so zip creates a clean new archive)
            std::string zip_cmd = "rm -f \"" + abs_c2_file + "\" && (cd \"" + tmp_dir + "\" && zip -q -r \"" + abs_c2_file + "\" .) && rm -rf \"" + tmp_dir + "\"";
            system(zip_cmd.c_str());
            std::cout << "\033[36m📦 [C2 PACKAGER]\033[0m Assembled Android Component 2 package: \033[1m" << abs_c2_file << "\033[0m\n";
        }

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

    // Factory: Creates dynamic window builder
    static DynamicWindow create_window(const std::string& title = "Dynamic Window", double w = 850, double h = 540, const std::string& target = "shine_ui") {
        return DynamicWindow(title, w, h, target);
    }

    // Factory: Creates dynamic program builder
    static DynamicProgram create_program(const std::string& name, const std::string& target = "shine_ui", const std::string& ver = "1.0") {
        return DynamicProgram(name, target, ver);
    }

    // Factory: Creates pre-configured template programs
    static DynamicProgram create_template(const std::string& type, const std::string& name, const std::string& target = "shine_ui") {
        DynamicProgram prog(name, target, "1.0");

        if (type == "window" || type == "win" || type == "gui") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " Window", 850, 540)
                .set_theme(specs.theme)
                .add_card(24, 20, 390, 160, "🌟 " + name, "Ventana dinámica generada por Looping Engine 2.5\nDiseño Loop OS & Glassmorphism Reactivo")
                .add_card(434, 20, 390, 160, "⚡ Métricas & Hardware", "Perfil UI: " + specs.name + " (" + specs.pipeline + ")\nRefresco: " + std::to_string(specs.target_fps) + " FPS Direct")
                .add_card(24, 200, 390, 180, "📦 Servicios Activos", "• Xtraps Engine v2.0\n• Looping JIT & Runtime v2.5\n• Audio Synthesizer Subsystem")
                .add_card(434, 200, 390, 180, "🎯 Panel de Control", "Control directo del subsistema gráfico y ejecución de tareas reactivas.")
                .add_button(36, 420, "INICIAR PROCESO", "start_process")
                .add_button(240, 420, "REINICIAR SERVICIOS", "restart_services")
                .add_button(440, 420, "EXPORTAR REGISTRO", "export_log")
                .add_code("play tone at 587 Hz for 80 ms\nplay tone at 880 Hz for 120 ms\nprint \"[DYNAMIC WINDOW] '" + name + "' inicializada con éxito.\"");
        } else if (type == "arcade" || type == "game") {
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
