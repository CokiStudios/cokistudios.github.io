#pragma once

#include "LoopingValue.hpp"
#include "Looping3D.hpp"
#include "LoopingAST.hpp"
#include "LoopingParser.hpp"
#include "LoopingDirectXWindow.hpp"
#include "LoopingMacWindow.hpp"
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
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <sys/stat.h>
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <io.h>
#include <direct.h>
#include <process.h>
#ifndef _PID_T_
#define _PID_T_
typedef int pid_t;
#endif
#define getcwd _getcwd
#define isatty _isatty
#define fileno _fileno
#else
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <signal.h>
#endif
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

namespace looping {

inline void ensure_dir_exists(const std::string& dir) {
    if (dir.empty()) return;
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);
}

inline void make_executable(const std::string& path) {
#ifdef _WIN32
    _chmod(path.c_str(), _S_IREAD | _S_IWRITE);
#else
    chmod(path.c_str(), 0755);
#endif
}

inline std::string get_user_home() {
    const char* h = std::getenv("HOME");
    if (h && *h) return std::string(h);
#ifdef _WIN32
    const char* up = std::getenv("USERPROFILE");
    if (up && *up) return std::string(up);
#endif
    return "";
}

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

struct CryptoUtils {
    static std::string fnv1a_hex(const std::string& data) {
        uint64_t hash = 14695981039346656037ULL;
        for (unsigned char c : data) {
            hash ^= static_cast<uint64_t>(c);
            hash *= 1099511628211ULL;
        }
        std::ostringstream ss;
        ss << std::hex << std::setfill('0') << std::setw(16) << hash;
        return ss.str();
    }

    static inline uint32_t rotr(uint32_t x, uint32_t n) {
        return (x >> n) | (x << (32 - n));
    }

    static std::string sha256_hex(const std::string& input) {
        static const uint32_t K[64] = {
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        };

        uint32_t h[8] = {
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        };

        std::vector<uint8_t> msg(input.begin(), input.end());
        uint64_t bit_len = static_cast<uint64_t>(msg.size()) * 8ULL;
        msg.push_back(0x80);
        while ((msg.size() % 64) != 56) msg.push_back(0x00);
        for (int i = 7; i >= 0; --i) {
            msg.push_back(static_cast<uint8_t>((bit_len >> (i * 8)) & 0xFF));
        }

        for (size_t offset = 0; offset < msg.size(); offset += 64) {
            uint32_t w[64];
            for (int i = 0; i < 16; ++i) {
                w[i] = (static_cast<uint32_t>(msg[offset + i * 4]) << 24) |
                       (static_cast<uint32_t>(msg[offset + i * 4 + 1]) << 16) |
                       (static_cast<uint32_t>(msg[offset + i * 4 + 2]) << 8) |
                       (static_cast<uint32_t>(msg[offset + i * 4 + 3]));
            }
            for (int i = 16; i < 64; ++i) {
                uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
                uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
                w[i] = w[i - 16] + s0 + w[i - 7] + s1;
            }

            uint32_t a = h[0], b = h[1], c = h[2], d = h[3];
            uint32_t e = h[4], f = h[5], g = h[6], hh = h[7];

            for (int i = 0; i < 64; ++i) {
                uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
                uint32_t ch = (e & f) ^ ((~e) & g);
                uint32_t temp1 = hh + S1 + ch + K[i] + w[i];
                uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
                uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
                uint32_t temp2 = S0 + maj;

                hh = g; g = f; f = e; e = d + temp1;
                d = c; c = b; b = a; a = temp1 + temp2;
            }

            h[0] += a; h[1] += b; h[2] += c; h[3] += d;
            h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
        }

        std::ostringstream ss;
        for (int i = 0; i < 8; ++i) {
            ss << std::hex << std::setfill('0') << std::setw(8) << h[i];
        }
        return ss.str();
    }

    static std::string base64_encode(const std::string& in) {
        static const char* b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::string out;
        int val = 0, valb = -6;
        for (unsigned char c : in) {
            val = (val << 8) + c;
            valb += 8;
            while (valb >= 0) {
                out.push_back(b64[(val >> valb) & 0x3F]);
                valb -= 6;
            }
        }
        if (valb > -6) out.push_back(b64[((val << 8) >> (valb + 8)) & 0x3F]);
        while (out.size() % 4) out.push_back('=');
        return out;
    }

    static std::string base64_decode(const std::string& in) {
        static const std::string b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::vector<int> T(256, -1);
        for (int i = 0; i < 64; i++) T[static_cast<unsigned char>(b64[i])] = i;
        std::string out;
        int val = 0, valb = -8;
        for (unsigned char c : in) {
            if (T[c] == -1) break;
            val = (val << 6) + T[c];
            valb += 6;
            if (valb >= 0) {
                out.push_back(char((val >> valb) & 0xFF));
                valb -= 8;
            }
        }
        return out;
    }

    static std::string uuid_v4() {
        static const char* hex = "0123456789abcdef";
        auto now_ns = std::chrono::high_resolution_clock::now().time_since_epoch().count();
        static uint64_t seed = 0x5bd1e995ULL;
        seed ^= static_cast<uint64_t>(now_ns) + 0x9e3779b97f4a7c15ULL;
        auto next_nibble = [&]() -> int {
            seed ^= seed << 13;
            seed ^= seed >> 7;
            seed ^= seed << 17;
            return static_cast<int>(seed & 0xF);
        };
        std::string res = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
        for (char& c : res) {
            if (c == 'x') c = hex[next_nibble()];
            else if (c == 'y') c = hex[(next_nibble() & 0x3) | 0x8];
        }
        return res;
    }

    static std::string hex_to_bytes(const std::string& hex) {
        std::string bytes;
        bytes.reserve(hex.size() / 2);
        for (size_t i = 0; i + 1 < hex.size(); i += 2) {
            unsigned int byte = 0;
            std::stringstream ss;
            ss << std::hex << hex.substr(i, 2);
            ss >> byte;
            bytes.push_back(static_cast<char>(byte));
        }
        return bytes;
    }

    static std::string hmac_sha256(std::string key, const std::string& message) {
        const size_t block_size = 64;
        if (key.size() > block_size) {
            key = hex_to_bytes(sha256_hex(key));
        }
        if (key.size() < block_size) {
            key.append(block_size - key.size(), '\0');
        }
        std::string o_key_pad(block_size, '\0');
        std::string i_key_pad(block_size, '\0');
        for (size_t i = 0; i < block_size; ++i) {
            o_key_pad[i] = static_cast<char>(static_cast<unsigned char>(key[i]) ^ 0x5c);
            i_key_pad[i] = static_cast<char>(static_cast<unsigned char>(key[i]) ^ 0x36);
        }
        std::string inner_hex = sha256_hex(i_key_pad + message);
        return sha256_hex(o_key_pad + hex_to_bytes(inner_hex));
    }

    static std::string random_hex(size_t num_bytes) {
        static const char* hex = "0123456789abcdef";
        auto now_ns = std::chrono::high_resolution_clock::now().time_since_epoch().count();
        static uint64_t seed = 0x9e3779b97f4a7c15ULL;
        seed ^= static_cast<uint64_t>(now_ns);
        std::string out;
        out.reserve(num_bytes * 2);
        for (size_t i = 0; i < num_bytes * 2; ++i) {
            seed ^= seed << 13;
            seed ^= seed >> 7;
            seed ^= seed << 17;
            out.push_back(hex[seed & 0xF]);
        }
        return out;
    }

    static std::string url_encode(const std::string& value) {
        std::ostringstream escaped;
        escaped.fill('0');
        escaped << std::hex << std::uppercase;
        for (unsigned char c : value) {
            if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
                escaped << c;
            } else {
                escaped << '%' << std::setw(2) << int(c);
            }
        }
        return escaped.str();
    }

    static std::string url_decode(const std::string& value) {
        std::string out;
        for (size_t i = 0; i < value.size(); ++i) {
            if (value[i] == '%' && i + 2 < value.size()) {
                unsigned int code = 0;
                std::istringstream iss(value.substr(i + 1, 2));
                if (iss >> std::hex >> code) {
                    out.push_back(static_cast<char>(code));
                    i += 2;
                    continue;
                }
            } else if (value[i] == '+') {
                out.push_back(' ');
                continue;
            }
            out.push_back(value[i]);
        }
        return out;
    }

    static uint32_t crc32_uint(const std::string& data) {
        uint32_t crc = 0xFFFFFFFFu;
        for (unsigned char b : data) {
            crc ^= static_cast<uint32_t>(b);
            for (int j = 0; j < 8; ++j) {
                uint32_t mask = -(crc & 1u);
                crc = (crc >> 1) ^ (0xEDB88320u & mask);
            }
        }
        return ~crc;
    }

    static std::string crc32_hex(const std::string& data) {
        uint32_t c = crc32_uint(data);
        std::ostringstream ss;
        ss << std::hex << std::setfill('0') << std::setw(8) << c;
        return ss.str();
    }

    static bool constant_time_eq(const std::string& a, const std::string& b) {
        if (a.size() != b.size()) return false;
        unsigned char diff = 0;
        for (size_t i = 0; i < a.size(); ++i) {
            diff |= static_cast<unsigned char>(a[i]) ^ static_cast<unsigned char>(b[i]);
        }
        return diff == 0;
    }

    static std::string csms_payload(const std::string& room_id, const std::string& plaintext) {
        std::string key_hex = sha256_hex(room_id + ":CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");
        std::string key_bytes = hex_to_bytes(key_hex);
        std::string iv_hex = sha256_hex(room_id + ":" + plaintext).substr(0, 24);
        std::string iv_bytes = hex_to_bytes(iv_hex);
        std::string cipher;
        cipher.resize(plaintext.size());
        for (size_t i = 0; i < plaintext.size(); ++i) {
            unsigned char k = static_cast<unsigned char>(key_bytes[i % key_bytes.size()]);
            unsigned char v = static_cast<unsigned char>(iv_bytes[i % iv_bytes.size()]);
            cipher[i] = static_cast<char>(static_cast<unsigned char>(plaintext[i]) ^ k ^ v);
        }
        std::string tag = hex_to_bytes(hmac_sha256(key_bytes, iv_bytes + cipher)).substr(0, 16);
        return "🔒 enc:v1:" + base64_encode(iv_bytes) + ":" + base64_encode(cipher + tag);
    }

    static std::string base64url_encode(const std::string& in) {
        std::string b64 = base64_encode(in);
        while (!b64.empty() && b64.back() == '=') b64.pop_back();
        for (char& c : b64) {
            if (c == '+') c = '-';
            else if (c == '/') c = '_';
        }
        return b64;
    }

    static std::string csms_decrypt(const std::string& room_id, const std::string& payload) {
        std::string body = payload;
        if (body.rfind("🔒 enc:v1:", 0) == 0) body = body.substr(12);
        else if (body.rfind("enc:v1:", 0) == 0) body = body.substr(7);
        else return payload;

        auto col = body.find(':');
        if (col == std::string::npos) return "";
        std::string iv_b64 = body.substr(0, col);
        std::string cipher_b64 = body.substr(col + 1);
        std::string iv_bytes = base64_decode(iv_b64);
        std::string cipher_tag = base64_decode(cipher_b64);
        if (cipher_tag.size() < 16) return "";
        std::string cipher = cipher_tag.substr(0, cipher_tag.size() - 16);
        std::string key_hex = sha256_hex(room_id + ":CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR");
        std::string key_bytes = hex_to_bytes(key_hex);
        std::string plain;
        plain.resize(cipher.size());
        for (size_t i = 0; i < cipher.size(); ++i) {
            unsigned char k = static_cast<unsigned char>(key_bytes[i % key_bytes.size()]);
            unsigned char v = static_cast<unsigned char>(iv_bytes[i % iv_bytes.size()]);
            plain[i] = static_cast<char>(static_cast<unsigned char>(cipher[i]) ^ k ^ v);
        }
        return plain;
    }
};

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

    // 0. Invis. Compile Binary Architecture (Arch 3.0A Native Binary Pipeline)
    if (s == "invis" || s == "invis.compile" || s == "invis_compile" || s == "inviscompile" || s == "invis. compile" || s == "binary" || s == "bin" || s == "lpbn") {
        return {
            "Invis. Compile Binary",
            "invis",
            "frosted_aqua_a17",
            "#00f5d4",
            "#38bdf8",
            240,
            "Invis. Compile LPBN v3.0A Native Binary Pipeline (SHA-256 CTR)",
            "Standalone Native Binary & Zero-Source Exposure"
        };
    }

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

    // 1b. Metal 4 (Apple Silicon APU Unified Memory & Hardware Raytracing 240Hz)
    if (s == "metal4" || s == "metal_4" || s == "metal-4" || s == "m4" || s == "apple_metal4" || s == "metal") {
        return {
            "Metal 4",
            "metal4",
            "metal4_quantum_cyan",
            "#00f5d4",
            "#0284c7",
            240,
            "Apple Metal 4 Unified Memory Pipeline 240Hz (<0.1ms)",
            "Apple Silicon APU Unified Memory & Hardware Raytracing"
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
            "Apple Metal 4 & SwiftUI ProMotion 120Hz/240Hz",
            "Apple Declarative Canvas & Dynamic Island Layout (Metal 4 Engine)"
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

    struct SnippetItem {
        std::string name;
        std::string code;
        std::string type = "looping";
    };

    std::vector<std::pair<std::string, std::string>> imports;
    std::vector<std::string> python_modules;
    std::vector<std::string> declarations;
    std::vector<std::string> ui_cards;
    std::vector<std::string> ui_buttons;
    std::vector<std::string> ui_inputs;
    std::vector<std::string> custom_functions;
    std::vector<SnippetItem> snippets;
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

    DynamicProgram& add_snippet(const std::string& name, const std::string& code, const std::string& type = "looping") {
        snippets.push_back({name, code, type});
        return *this;
    }

    DynamicProgram& add_card(double x, double y, double w, double h, const std::string& title, const std::string& text) {
        std::ostringstream ss;
        ss << "    draw card at (" << x << ", " << y << ") with size (" << w << ", " << h << ") and title \"" 
           << escape_str(title) << "\" and text \"" << escape_str(text) << "\"";
        ui_cards.push_back(ss.str());
        return *this;
    }

    DynamicProgram& add_button(double x, double y, const std::string& text, const std::string& action, const std::string& snippet = "") {
        std::ostringstream ss;
        if (!snippet.empty()) {
            ss << "    draw button at (" << x << ", " << y << ") with text \"" << escape_str(text) 
               << "\" and action \"" << escape_str(action) << "\" with snippet:\n";
            std::stringstream snip_ss(snippet);
            std::string line;
            while (std::getline(snip_ss, line)) {
                ss << "        " << line << "\n";
            }
        } else {
            ss << "    draw button at (" << x << ", " << y << ") with text \"" << escape_str(text) 
               << "\" and action \"" << escape_str(action) << "\"";
        }
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

        // Snippets (Arch 3.0A Embedded Reactive Snippets)
        for (const auto& snip : snippets) {
            if (snip.type == "python") {
                out << "insert pysnippet as " << snip.name << ":\n";
            } else {
                out << "insert snippet as " << snip.name << ":\n";
            }
            std::stringstream ss(snip.code);
            std::string line;
            while (std::getline(ss, line)) {
                out << "    " << line << "\n";
            }
            out << "\n";
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

inline std::string resolve_looping_host_exe() {
#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
    char exe_buf[MAX_PATH];
    DWORD len = GetModuleFileNameA(NULL, exe_buf, MAX_PATH);
    if (len > 0 && len < MAX_PATH) {
        return std::string(exe_buf);
    }
    return "looping.exe";
#elif defined(__APPLE__) && !defined(__EMSCRIPTEN__)
    char exe_buf[4096];
    uint32_t sz = sizeof(exe_buf);
    if (_NSGetExecutablePath(exe_buf, &sz) == 0) {
        return std::string(exe_buf);
    }
    return "looping";
#elif defined(__linux__) && !defined(__EMSCRIPTEN__)
    char exe_buf[4096];
    ssize_t len = readlink("/proc/self/exe", exe_buf, sizeof(exe_buf) - 1);
    if (len > 0) {
        exe_buf[len] = '\0';
        return std::string(exe_buf);
    }
    return "looping";
#else
    return "looping";
#endif
}

// Helper: cleanly spawn native Cocoa + Objective-C + Assembly dynamic window on macOS (Zero Python)
inline pid_t launch_mac_window_process(const std::string& dxwin_path) {
#if defined(__APPLE__) && (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && !defined(__EMSCRIPTEN__) && !defined(LOOPING_NO_SUBPROCESS)
    std::string host_exe = resolve_looping_host_exe();
    pid_t pid = fork();
    if (pid == 0) {
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        execl(host_exe.c_str(), host_exe.c_str(), "--mac-window", dxwin_path.c_str(), (char*)NULL);
        execlp("looping", "looping", "--mac-window", dxwin_path.c_str(), (char*)NULL);
        _exit(127);
    }
    return pid;
#else
    (void)dxwin_path;
    return 0;
#endif
}

// Helper: cleanly spawn native DirectX 11 dynamic window process on Windows (Zero Python)
inline pid_t launch_directx_window_process(const std::string& dxwin_path) {
#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
    STARTUPINFOA si{};
    si.cb = sizeof(STARTUPINFOA);
    PROCESS_INFORMATION pi{};
    std::string host_exe = resolve_looping_host_exe();
    std::string cmdline = "\"" + host_exe + "\" --dx-window \"" + dxwin_path + "\"";
    std::vector<char> buf(cmdline.begin(), cmdline.end());
    buf.push_back('\0');
    if (CreateProcessA(NULL, buf.data(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
        pid_t pid = static_cast<pid_t>(pi.dwProcessId);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return pid;
    }
    return 0;
#else
    (void)dxwin_path;
    return 0;
#endif
}

// Helper: cleanly spawn native Python/Pygame window without blocking or cluttering the persistent shell
inline pid_t launch_native_window_process(const std::string& script_path, const std::string& extra_args = "") {
#if defined(__EMSCRIPTEN__) || defined(LOOPING_NO_SUBPROCESS)
    (void)script_path;
    (void)extra_args;
    return 0;
#elif defined(_WIN32)
    STARTUPINFOA si{};
    si.cb = sizeof(STARTUPINFOA);
    PROCESS_INFORMATION pi{};
    const char* py_bins[] = {"pythonw.exe", "python.exe", "py.exe"};
    for (const char* py_exe : py_bins) {
        std::string cmdline = std::string(py_exe) + " \"" + script_path + "\"" + (extra_args.empty() ? "" : (" " + extra_args));
        std::vector<char> buf(cmdline.begin(), cmdline.end());
        buf.push_back('\0');
        if (CreateProcessA(NULL, buf.data(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
            pid_t pid = static_cast<pid_t>(pi.dwProcessId);
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            return pid;
        }
    }
    return 0;
#else
    pid_t pid = fork();
    if (pid == 0) {
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        if (!extra_args.empty()) {
            execlp("python3", "python3", script_path.c_str(), extra_args.c_str(), (char*)NULL);
        } else {
            execlp("python3", "python3", script_path.c_str(), (char*)NULL);
        }
        _exit(127);
    }
    return pid;
#endif
}

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
    bool is_3d_mode = false;
    std::vector<loop_math::Entity3D> entities_3d;
    std::vector<DxEntity2DSpec> entities_2d;
    double stage_world_width = 1200.0;
    double stage_world_height = 480.0;
    double stage_gravity = 980.0;
    std::string stage_scenario_name = "Holo Cyber Stage";
    std::string stage_scenario_accent = "#38bdf8";

    DynamicWindow& add_entity_3d(const loop_math::Entity3D& e) {
        is_3d_mode = true;
        entities_3d.push_back(e);
        return *this;
    }

    DynamicWindow& add_entity_2d(const DxEntity2DSpec& e) {
        entities_2d.push_back(e);
        return *this;
    }

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
        if (is_3d_mode || !entities_3d.empty()) {
            h << "    .viewport3d-wrap {\n";
            h << "      position: relative;\n";
            h << "      border-radius: 14px;\n";
            h << "      overflow: hidden;\n";
            h << "      border: 1px solid var(--border);\n";
            h << "      background: radial-gradient(circle at 50% 25%, #0e1b3d, #040714);\n";
            h << "      box-shadow: 0 12px 32px rgba(0,0,0,0.55), inset 0 0 28px rgba(56,189,248,0.12);\n";
            h << "    }\n";
            h << "    #canvas3d { width: 100%; height: 310px; display: block; cursor: grab; }\n";
            h << "    #canvas3d:active { cursor: grabbing; }\n";
            h << "    .hud3d {\n";
            h << "      position: absolute; top: 10px; left: 12px; right: 12px;\n";
            h << "      display: flex; justify-content: space-between; align-items: center;\n";
            h << "      pointer-events: none; font-family: monospace; font-size: 11px; color: #7dd3fc;\n";
            h << "      text-shadow: 0 1px 6px rgba(0,0,0,0.85);\n";
            h << "    }\n";
        }
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
        if (is_3d_mode || !entities_3d.empty()) {
            h << "      <div class=\"viewport3d-wrap\">\n";
            h << "        <canvas id=\"canvas3d\" width=\"920\" height=\"320\"></canvas>\n";
            h << "        <div class=\"hud3d\"><span>🕹️ SHINE LOOP 3D QUANTUM (.OBJ + C# BRIDGE)</span><span id=\"hud3d-stats\">Entities: " << entities_3d.size() << " | Drag: Orbit • Scroll: Zoom</span></div>\n";
            h << "      </div>\n";
        }
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
        if (is_3d_mode || !entities_3d.empty()) {
            h << "    const entities3D = [\n";
            for (size_t ei = 0; ei < entities_3d.size(); ++ei) {
                const auto& e = entities_3d[ei];
                h << "      { type: \"" << escape_js(e.type) << "\", name: \"" << escape_js(e.name)
                  << "\", obj: \"" << escape_js(e.obj_file) << "\", cs: \"" << escape_js(e.cs_class)
                  << "\", x: " << e.pos.x << ", y: " << e.pos.y << ", z: " << e.pos.z
                  << ", sx: " << e.size.x << ", sy: " << e.size.y << ", sz: " << e.size.z
                  << ", scx: " << e.scale.x << ", scy: " << e.scale.y << ", scz: " << e.scale.z
                  << ", r: " << e.radius << ", color: \"" << escape_js(e.color) << "\", rot: " << e.rot_deg.y;
                if (e.has_custom_mesh && !e.custom_mesh.vertices.empty() && e.custom_mesh.faces.size() <= 450) {
                    h << ", verts: [";
                    for (size_t vi = 0; vi < e.custom_mesh.vertices.size(); ++vi) {
                        if (vi > 0) h << ",";
                        const auto& v = e.custom_mesh.vertices[vi];
                        h << "[" << v.x << "," << v.y << "," << v.z << "]";
                    }
                    h << "], faces: [";
                    for (size_t fi = 0; fi < e.custom_mesh.faces.size(); ++fi) {
                        if (fi > 0) h << ",";
                        h << "[";
                        const auto& idx = e.custom_mesh.faces[fi].indices;
                        for (size_t k = 0; k < idx.size(); ++k) {
                            if (k > 0) h << ",";
                            h << idx[k];
                        }
                        h << "]";
                    }
                    h << "]";
                }
                h << " }" << (ei + 1 < entities_3d.size() ? "," : "") << "\n";
            }
            h << "    ];\n";
            h << "    (function init3DViewport(){\n";
            h << "      const c = document.getElementById('canvas3d'); if (!c) return;\n";
            h << "      const ctx = c.getContext('2d');\n";
            h << "      let yaw = 0.25, pitch = 0.34, dist = 28, drag = false, lx = 0, ly = 0;\n";
            h << "      c.addEventListener('mousedown', e => { drag = true; lx = e.clientX; ly = e.clientY; });\n";
            h << "      window.addEventListener('mouseup', () => { drag = false; });\n";
            h << "      window.addEventListener('mousemove', e => { if (!drag) return; yaw += (e.clientX - lx) * 0.008; pitch = Math.max(-0.2, Math.min(1.3, pitch + (e.clientY - ly) * 0.006)); lx = e.clientX; ly = e.clientY; });\n";
            h << "      c.addEventListener('wheel', e => { e.preventDefault(); dist = Math.max(8, Math.min(90, dist + e.deltaY * 0.03)); }, { passive: false });\n";
            h << "      function hexRgb(hex) { const m = /^#?([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})$/i.exec(hex || '#38bdf8'); return m ? [parseInt(m[1],16), parseInt(m[2],16), parseInt(m[3],16)] : [56,189,248]; }\n";
            h << "      function cubeVerts(sx, sy, sz) { const hx=sx*0.5, hy=sy*0.5, hz=sz*0.5; return [[-hx,-hy,-hz],[hx,-hy,-hz],[hx,hy,-hz],[-hx,hy,-hz],[-hx,-hy,hz],[hx,-hy,hz],[hx,hy,hz],[-hx,hy,hz]]; }\n";
            h << "      const cubeFaces = [[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[3,2,6,7],[4,5,1,0]];\n";
            h << "      function render3DFrame(t) {\n";
            h << "        const w = c.width, h = c.height; ctx.clearRect(0,0,w,h);\n";
            h << "        const target = entities3D.find(e => e.type === 'player') || { x:0, y:2, z:12 };\n";
            h << "        const ex = target.x - Math.sin(yaw) * Math.cos(pitch) * dist;\n";
            h << "        const ey = target.y + Math.sin(pitch) * dist + 2;\n";
            h << "        const ez = target.z - Math.cos(yaw) * Math.cos(pitch) * dist;\n";
            h << "        let fx = target.x - ex, fy = target.y - ey, fz = target.z - ez; const fl = Math.hypot(fx,fy,fz)||1; fx/=fl; fy/=fl; fz/=fl;\n";
            h << "        let rx = fz, ry = 0, rz = -fx; const rl = Math.hypot(rx,ry,rz)||1; rx/=rl; rz/=rl;\n";
            h << "        const ux = fy*rz - fz*ry, uy = fz*rx - fx*rz, uz = fx*ry - fy*rx, focal = h * 0.95;\n";
            h << "        function proj(wx, wy, wz) {\n";
            h << "          const dx = wx-ex, dy = wy-ey, dz = wz-ez;\n";
            h << "          const vx = dx*rx + dy*ry + dz*rz, vy = dx*ux + dy*uy + dz*uz, vz = dx*fx + dy*fy + dz*fz;\n";
            h << "          if (vz <= 0.35) return null;\n";
            h << "          const inv = focal / vz; return [w*0.5 + vx*inv, h*0.5 - vy*inv, vz];\n";
            h << "        }\n";
            h << "        ctx.strokeStyle = 'rgba(56,189,248,0.18)'; ctx.lineWidth = 1; ctx.beginPath();\n";
            h << "        for (let g = -48; g <= 48; g += 8) {\n";
            h << "          const a = proj(target.x+g, 0, target.z-48), b = proj(target.x+g, 0, target.z+48);\n";
            h << "          if (a && b) { ctx.moveTo(a[0],a[1]); ctx.lineTo(b[0],b[1]); }\n";
            h << "          const c1 = proj(target.x-48, 0, target.z+g), d1 = proj(target.x+48, 0, target.z+g);\n";
            h << "          if (c1 && d1) { ctx.moveTo(c1[0],c1[1]); ctx.lineTo(d1[0],d1[1]); }\n";
            h << "        }\n";
            h << "        ctx.stroke();\n";
            h << "        const q = [];\n";
            h << "        for (const e of entities3D) {\n";
            h << "          const vs = e.verts || cubeVerts(e.sx||1.6, e.sy||1.6, e.sz||1.6);\n";
            h << "          const fs = e.faces || cubeFaces;\n";
            h << "          const ang = (e.rot * Math.PI / 180) + (e.obj ? t*0.0005 : 0);\n";
            h << "          const ca = Math.cos(ang), sa = Math.sin(ang), rgb = hexRgb(e.color);\n";
            h << "          const scx = e.scx || 1, scy = e.scy || 1, scz = e.scz || 1;\n";
            h << "          const wvs = vs.map(v => { const lx = v[0]*scx, ly = v[1]*scy, lz = v[2]*scz; return [e.x + lx*ca + lz*sa, e.y + ly, e.z - lx*sa + lz*ca]; });\n";
            h << "          const pvs = wvs.map(wv => proj(wv[0], wv[1], wv[2]));\n";
            h << "          for (const f of fs) {\n";
            h << "            if (f.length < 3) continue;\n";
            h << "            const pts = f.map(i => pvs[i]); if (pts.some(p => !p)) continue;\n";
            h << "            const w0 = wvs[f[0]], w1 = wvs[f[1]], w2 = wvs[f[2]];\n";
            h << "            const ax = w1[0]-w0[0], ay = w1[1]-w0[1], az = w1[2]-w0[2];\n";
            h << "            const bx = w2[0]-w0[0], by = w2[1]-w0[1], bz = w2[2]-w0[2];\n";
            h << "            let nx = ay*bz - az*by, ny = az*bx - ax*bz, nz = ax*by - ay*bx;\n";
            h << "            const nl = Math.hypot(nx,ny,nz)||1; nx/=nl; ny/=nl; nz/=nl;\n";
            h << "            const lit = 0.42 + Math.max(0, nx*0.35 + ny*0.82 - nz*0.45) * 0.58;\n";
            h << "            const dz = pts.reduce((s,p)=>s+p[2],0)/pts.length;\n";
            h << "            q.push({ dz, pts, fill: `rgb(${(rgb[0]*lit)|0},${(rgb[1]*lit)|0},${(rgb[2]*lit)|0})` });\n";
            h << "          }\n";
            h << "        }\n";
            h << "        q.sort((a,b) => b.dz - a.dz);\n";
            h << "        for (const poly of q) {\n";
            h << "          ctx.beginPath(); ctx.moveTo(poly.pts[0][0], poly.pts[0][1]);\n";
            h << "          for (let k=1;k<poly.pts.length;k++) ctx.lineTo(poly.pts[k][0], poly.pts[k][1]);\n";
            h << "          ctx.closePath(); ctx.fillStyle = poly.fill; ctx.fill();\n";
            h << "          ctx.strokeStyle = 'rgba(226,232,240,0.22)'; ctx.lineWidth = 0.6; ctx.stroke();\n";
            h << "        }\n";
            h << "        requestAnimationFrame(render3DFrame);\n";
            h << "      }\n";
            h << "      requestAnimationFrame(render3DFrame);\n";
            h << "    })();\n";
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
            ensure_dir_exists(path.substr(0, slash));
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_loop_script();
        return true;
    }

    bool save_html(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            ensure_dir_exists(path.substr(0, slash));
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
        py << "# Generated by Looping Engine v3.0A (Pygame + PygameCompat Replication)\n";
        py << "# =====================================================================\n\n";
        py << "import sys, os, math, time, array, subprocess, datetime, threading\n";
        py << "os.environ.setdefault('TK_SILENCE_DEPRECATION', '1')\n\n";

        std::string bg_color = "#0b0f19";
        std::string card_bg = "#151d30";
        std::string card_border = "#22314e";
        std::string btn_bg = "#0284c7";
        std::string btn_fg = "#ffffff";
        std::string primary_color = specs.primary_color.empty() ? "#38bdf8" : specs.primary_color;
        std::string accent_color = (specs.accent_color.empty() || specs.accent_color == "#082f49") ? "#00f5d4" : specs.accent_color;

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
        } else if (specs.theme.find("metal4") != std::string::npos || specs.code == "metal4") {
            bg_color = "#070c18";
            card_bg = "#0e182a";
            card_border = "#1a3254";
            btn_bg = "#0284c7";
            primary_color = "#00f5d4";
            accent_color = "#38bdf8";
        }

        std::string badge_label = (specs.code == "metal4")
            ? "Metal 4 • 240 FPS Hardware Direct"
            : (specs.name + " • " + std::to_string(specs.target_fps) + " FPS Direct");

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

        py << "WINDOW_CFG = {\n";
        py << "    'title': \"" << escape_py(title) << "\",\n";
        py << "    'width': " << static_cast<int>(std::max(580.0, width)) << ",\n";
        py << "    'height': " << static_cast<int>(std::max(400.0, height)) << ",\n";
        py << "    'badge': \"" << escape_py(badge_label) << "\",\n";
        py << "    'pipeline': \"" << escape_py(specs.name + " " + specs.pipeline) << "\",\n";
        py << "    'target_fps': " << std::min(120, std::max(30, specs.target_fps)) << ",\n";
        py << "    'is_3d': " << ((is_3d_mode || !entities_3d.empty()) ? "True" : "False") << ",\n";
        py << "    'world_width': " << stage_world_width << ",\n";
        py << "    'world_height': " << stage_world_height << ",\n";
        py << "    'gravity': " << stage_gravity << "\n";
        py << "}\n\n";

        py << "CARDS = [\n";
        for (const auto& c : cards) {
            std::string card_t = (c.icon.empty() ? "✦ " : c.icon + " ") + c.title;
            py << "    {'title': \"" << escape_py(card_t) << "\", 'badge': \"" << escape_py(c.badge)
               << "\", 'text': \"" << escape_py(c.text) << "\"},\n";
        }
        py << "]\n\n";

        py << "INPUTS = [\n";
        for (const auto& inp : inputs) {
            py << "    {'placeholder': \"" << escape_py(inp.placeholder) << "\", 'binding': \""
               << escape_py(inp.binding) << "\", 'value': ''},\n";
        }
        py << "]\n\n";

        py << "SLIDERS = [\n";
        for (const auto& sl : sliders) {
            py << "    {'label': \"" << escape_py(sl.label) << "\", 'min': " << sl.min_val
               << ", 'max': " << sl.max_val << ", 'val': " << sl.current_val
               << ", 'bind': \"" << escape_py(sl.binding) << "\"},\n";
        }
        py << "]\n\n";

        py << "TOGGLES = [\n";
        for (const auto& tg : toggles) {
            py << "    {'label': \"" << escape_py(tg.label) << "\", 'checked': "
               << (tg.is_checked ? "True" : "False") << ", 'bind': \"" << escape_py(tg.binding) << "\"},\n";
        }
        py << "]\n\n";

        py << "PROGRESS_BARS = [\n";
        for (const auto& pr : progress_bars) {
            py << "    {'label': \"" << escape_py(pr.label) << "\", 'progress': " << pr.progress
               << ", 'bind': \"" << escape_py(pr.binding) << "\"},\n";
        }
        py << "]\n\n";

        py << "BUTTONS = [\n";
        for (const auto& b : buttons) {
            py << "    {'text': \"" << escape_py(b.text) << "\", 'action': \"" << escape_py(b.action)
               << "\", 'snippet': \"" << escape_py(b.snippet) << "\"},\n";
        }
        py << "]\n\n";

        py << "TONES = [";
        for (size_t i = 0; i < tones.size(); ++i) {
            if (i > 0) py << ", ";
            py << "(" << tones[i].freq_hz << ", " << tones[i].duration_ms << ")";
        }
        py << "]\n\n";

        py << "ENTITIES_3D = [\n";
        for (const auto& e : entities_3d) {
            py << "    {'type': \"" << escape_py(e.type) << "\", 'name': \"" << escape_py(e.name)
               << "\", 'obj': \"" << escape_py(e.obj_file) << "\", 'cs': \"" << escape_py(e.cs_class)
               << "\", 'x': " << e.pos.x << ", 'y': " << e.pos.y << ", 'z': " << e.pos.z
               << ", 'sx': " << e.size.x << ", 'sy': " << e.size.y << ", 'sz': " << e.size.z
               << ", 'scx': " << e.scale.x << ", 'scy': " << e.scale.y << ", 'scz': " << e.scale.z
               << ", 'r': " << e.radius << ", 'color': \"" << escape_py(e.color.empty() ? "#38bdf8" : e.color)
               << "\", 'speed': " << e.speed << ", 'axis': \"" << escape_py(e.axis)
               << "\", 'min_p': " << e.min_pos << ", 'max_p': " << e.max_pos
               << ", 'dir': 1.0, 'collected': False, 'alive': True, 'rot': " << e.rot_deg.y;
            if (e.has_custom_mesh && !e.custom_mesh.vertices.empty() && e.custom_mesh.faces.size() <= 450) {
                py << ", 'verts': [";
                for (size_t vi = 0; vi < e.custom_mesh.vertices.size(); ++vi) {
                    if (vi > 0) py << ",";
                    const auto& v = e.custom_mesh.vertices[vi];
                    py << "[" << v.x << "," << v.y << "," << v.z << "]";
                }
                py << "], 'faces': [";
                for (size_t fi = 0; fi < e.custom_mesh.faces.size(); ++fi) {
                    if (fi > 0) py << ",";
                    py << "[";
                    const auto& idx = e.custom_mesh.faces[fi].indices;
                    for (size_t k = 0; k < idx.size(); ++k) {
                        if (k > 0) py << ",";
                        py << idx[k];
                    }
                    py << "]";
                }
                py << "]";
            }
            py << "},\n";
        }
        py << "]\n\n";

        py << "ENTITIES_2D = [\n";
        for (const auto& e : entities_2d) {
            py << "    {'type': \"" << escape_py(e.type) << "\", 'name': \"" << escape_py(e.name)
               << "\", 'color': \"" << escape_py(e.color.empty() ? "#38bdf8" : e.color)
               << "\", 'x': " << e.x << ", 'y': " << e.y << ", 'w': " << e.w << ", 'h': " << e.h
               << ", 'sx': " << e.x << ", 'sy': " << e.y << ", 'vx': 0.0, 'vy': 0.0"
               << ", 'r': " << e.radius << ", 'speed': " << e.speed << ", 'jump': " << e.jump_force
               << ", 'power': " << e.power << ", 'hp': " << e.health << ", 'max_hp': " << e.max_health
               << ", 'dmg': " << e.damage << ", 'pts': " << e.points
               << ", 'min_p': " << e.min_pos << ", 'max_p': " << e.max_pos
               << ", 'dir': 1.0, 'is_player': " << (e.is_player ? "True" : "False")
               << ", 'collected': False, 'alive': True, 'jumping': False, 'dbl': True},\n";
        }
        py << "]\n\n";

        py << R"LOOP_PY(
try:
    import tkinter as tk
except Exception:
    tk = None

try:
    import winsound as _winsound
except Exception:
    _winsound = None


def _hex_color(col):
    if isinstance(col, str):
        return col if col.startswith('#') else '#38bdf8'
    if isinstance(col, (tuple, list)) and len(col) >= 3:
        r = max(0, min(255, int(col[0])))
        g = max(0, min(255, int(col[1])))
        b = max(0, min(255, int(col[2])))
        return f'#{r:02x}{g:02x}{b:02x}'
    return '#38bdf8'


def _rgb_tuple(col):
    if isinstance(col, (tuple, list)) and len(col) >= 3:
        return (max(0, min(255, int(col[0]))), max(0, min(255, int(col[1]))), max(0, min(255, int(col[2]))))
    s = str(col or '#38bdf8').lstrip('#')
    if len(s) == 3:
        s = ''.join(ch * 2 for ch in s)
    if len(s) >= 6:
        try:
            return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))
        except Exception:
            pass
    return (56, 189, 248)


class _CompatRect:
    def __init__(self, x, y=0, w=0, h=0):
        if isinstance(x, (tuple, list)):
            x, y, w, h = x[0], x[1], x[2], x[3]
        elif hasattr(x, 'x') and hasattr(x, 'w'):
            x, y, w, h = x.x, x.y, x.w, x.h
        self.x = int(x)
        self.y = int(y)
        self.w = int(w)
        self.h = int(h)

    @property
    def left(self): return self.x
    @property
    def top(self): return self.y
    @property
    def right(self): return self.x + self.w
    @property
    def bottom(self): return self.y + self.h
    @property
    def width(self): return self.w
    @property
    def height(self): return self.h
    @property
    def centerx(self): return self.x + self.w // 2
    @property
    def centery(self): return self.y + self.h // 2
    @property
    def center(self): return (self.centerx, self.centery)
    @property
    def topleft(self): return (self.x, self.y)
    @property
    def size(self): return (self.w, self.h)

    def collidepoint(self, px, py=None):
        if py is None and isinstance(px, (tuple, list)):
            px, py = px[0], px[1]
        return self.x <= px <= self.x + self.w and self.y <= py <= self.y + self.h

    def colliderect(self, other):
        return (self.x < other.x + other.w and self.x + self.w > other.x and
                self.y < other.y + other.h and self.y + self.h > other.y)

    def copy(self):
        return _CompatRect(self.x, self.y, self.w, self.h)

    def move(self, dx, dy):
        return _CompatRect(self.x + dx, self.y + dy, self.w, self.h)

    def inflate(self, dw, dh):
        return _CompatRect(self.x - dw // 2, self.y - dh // 2, self.w + dw, self.h + dh)


class _CompatEvent:
    def __init__(self, etype, **kwargs):
        self.type = etype
        self.__dict__.update(kwargs)


class _CompatSurface:
    def __init__(self, size, flags=0):
        self._w, self._h = int(size[0]), int(size[1])
        self._flags = flags
        self._ops = []

    def get_width(self): return self._w
    def get_height(self): return self._h
    def get_size(self): return (self._w, self._h)
    def get_rect(self, **kw):
        r = _CompatRect(0, 0, self._w, self._h)
        if 'center' in kw:
            cx, cy = kw['center']
            r.x = int(cx - self._w // 2)
            r.y = int(cy - self._h // 2)
        elif 'topleft' in kw:
            r.x, r.y = int(kw['topleft'][0]), int(kw['topleft'][1])
        return r

    def fill(self, color, rect=None):
        hx = _hex_color(color)
        if rect is None:
            self._ops.clear()
            self._ops.append(('rect', (0, 0, self._w, self._h), hx, '', 0))
        else:
            r = _CompatRect(rect)
            self._ops.append(('rect', (r.x, r.y, r.right, r.bottom), hx, '', 0))

    def blit(self, source, dest, area=None):
        dx = int(dest.x if hasattr(dest, 'x') else dest[0])
        dy = int(dest.y if hasattr(dest, 'y') else dest[1])
        if isinstance(source, _CompatTextSurface):
            self._ops.append(('text', dx, dy, source._text, source._font, source._color, source._bg))
        elif isinstance(source, _CompatSurface):
            for op in source._ops:
                kind = op[0]
                if kind == 'rect':
                    x1, y1, x2, y2 = op[1]
                    self._ops.append(('rect', (x1 + dx, y1 + dy, x2 + dx, y2 + dy), op[2], op[3], op[4]))
                elif kind == 'oval':
                    x1, y1, x2, y2 = op[1]
                    self._ops.append(('oval', (x1 + dx, y1 + dy, x2 + dx, y2 + dy), op[2], op[3], op[4]))
                elif kind == 'line':
                    pts = [v + (dx if i % 2 == 0 else dy) for i, v in enumerate(op[1])]
                    self._ops.append(('line', pts, op[2], op[3]))
                elif kind == 'poly':
                    pts = [v + (dx if i % 2 == 0 else dy) for i, v in enumerate(op[1])]
                    self._ops.append(('poly', pts, op[2], op[3], op[4]))
                elif kind == 'text':
                    self._ops.append(('text', op[1] + dx, op[2] + dy, op[3], op[4], op[5], op[6]))

    def convert_alpha(self): return self
    def copy(self):
        s = _CompatSurface((self._w, self._h), self._flags)
        s._ops = list(self._ops)
        return s


class _CompatTextSurface:
    def __init__(self, text, font_spec, color, bg=None):
        self._text = text
        self._font = font_spec
        self._color = _hex_color(color)
        self._bg = _hex_color(bg) if bg else None
        sz = font_spec[1]
        self._w = max(4, int(len(text) * sz * 0.60))
        self._h = max(8, int(sz * 1.4))

    def get_width(self): return self._w
    def get_height(self): return self._h
    def get_size(self): return (self._w, self._h)
    def get_rect(self, **kw):
        r = _CompatRect(0, 0, self._w, self._h)
        if 'center' in kw:
            r.x = int(kw['center'][0] - self._w // 2)
            r.y = int(kw['center'][1] - self._h // 2)
        return r


class _CompatKeyMap(dict):
    def __getitem__(self, k):
        return self.get(k, False)


class _PygameCompat:
    """Pure-Python Pygame API replication layer backed by Tkinter Canvas (or headless buffer)."""
    QUIT = 256
    KEYDOWN = 768
    KEYUP = 769
    MOUSEMOTION = 1024
    MOUSEBUTTONDOWN = 1025
    MOUSEBUTTONUP = 1026
    MOUSEWHEEL = 1027
    VIDEORESIZE = 32778
    RESIZABLE = 16
    SRCALPHA = 65536

    K_BACKSPACE = 8
    K_RETURN = 13
    K_ESCAPE = 27
    K_SPACE = 32
    K_a = ord('a')
    K_d = ord('d')
    K_e = ord('e')
    K_j = ord('j')
    K_q = ord('q')
    K_r = ord('r')
    K_s = ord('s')
    K_w = ord('w')
    K_x = ord('x')
    K_z = ord('z')
    K_UP = 273
    K_DOWN = 274
    K_RIGHT = 275
    K_LEFT = 276
    K_RSHIFT = 303
    K_LSHIFT = 304

    def __init__(self):
        self.Rect = _CompatRect
        self.Surface = _CompatSurface
        self.Event = _CompatEvent
        self._events = []
        self._keys = _CompatKeyMap()
        self._mouse_pos = (0, 0)
        self._mouse_btns = [False, False, False]
        self._root = None
        self._canvas = None
        self._surface = _CompatSurface((850, 540))
        self._caption = "Looping PygameCompat Window"
        self._start_ts = time.perf_counter()
        self._clip_rect = None
        self._tk_available = (tk is not None)

        pg_self = self

        class _DrawMod:
            @staticmethod
            def rect(surface, color, rect, width=0, border_radius=0):
                r = _CompatRect(rect)
                hx = _hex_color(color)
                if width == 0:
                    surface._ops.append(('rect', (r.x, r.y, r.right, r.bottom), hx, '', 0))
                else:
                    surface._ops.append(('rect', (r.x, r.y, r.right, r.bottom), '', hx, width))
                return r

            @staticmethod
            def circle(surface, color, center, radius, width=0):
                cx, cy = int(center[0]), int(center[1])
                rad = max(1, int(radius))
                hx = _hex_color(color)
                if width == 0:
                    surface._ops.append(('oval', (cx - rad, cy - rad, cx + rad, cy + rad), hx, '', 0))
                else:
                    surface._ops.append(('oval', (cx - rad, cy - rad, cx + rad, cy + rad), '', hx, width))
                return _CompatRect(cx - rad, cy - rad, rad * 2, rad * 2)

            @staticmethod
            def ellipse(surface, color, rect, width=0):
                r = _CompatRect(rect)
                hx = _hex_color(color)
                if width == 0:
                    surface._ops.append(('oval', (r.x, r.y, r.right, r.bottom), hx, '', 0))
                else:
                    surface._ops.append(('oval', (r.x, r.y, r.right, r.bottom), '', hx, width))
                return r

            @staticmethod
            def polygon(surface, color, points, width=0):
                if not points or len(points) < 3:
                    return _CompatRect(0, 0, 0, 0)
                flat = []
                for p in points:
                    flat.extend([float(p[0]), float(p[1])])
                hx = _hex_color(color)
                if width == 0:
                    surface._ops.append(('poly', flat, hx, '', 0))
                else:
                    surface._ops.append(('poly', flat, '', hx, width))
                return _CompatRect(0, 0, 1, 1)

            @staticmethod
            def line(surface, color, start_pos, end_pos, width=1):
                hx = _hex_color(color)
                surface._ops.append(('line', [float(start_pos[0]), float(start_pos[1]), float(end_pos[0]), float(end_pos[1])], hx, max(1, int(width))))
                return _CompatRect(0, 0, 1, 1)

            @staticmethod
            def aalines(surface, color, closed, points, blend=1):
                if len(points) < 2:
                    return
                hx = _hex_color(color)
                flat = []
                for p in points:
                    flat.extend([float(p[0]), float(p[1])])
                if closed and len(points) >= 2:
                    flat.extend([float(points[0][0]), float(points[0][1])])
                surface._ops.append(('line', flat, hx, 1))

        class _CompatFont:
            def __init__(self, family, size, bold=False, italic=False):
                weight = 'bold' if bold else 'normal'
                self._spec = (family or 'Helvetica', max(7, int(size * 0.78)), weight)
                self._px = size

            def render(self, text, antialias, color, background=None):
                return _CompatTextSurface(str(text), self._spec, color, background)

            def size(self, text):
                return (max(4, int(len(str(text)) * self._px * 0.56)), max(8, int(self._px * 1.3)))

        class _FontMod:
            @staticmethod
            def init(): pass
            @staticmethod
            def Font(name, size):
                return _CompatFont(name or 'Helvetica', size)
            @staticmethod
            def SysFont(name, size, bold=False, italic=False):
                fam = name[0] if isinstance(name, (list, tuple)) and name else (name or 'Helvetica')
                return _CompatFont(fam, size, bold, italic)

        class _Clock:
            def __init__(self):
                self._last = time.perf_counter()
                self._fps = 60.0

            def tick(self, framerate=0):
                now = time.perf_counter()
                dt = now - self._last
                if framerate > 0:
                    target = 1.0 / float(framerate)
                    if dt < target:
                        time.sleep(target - dt)
                        now = time.perf_counter()
                        dt = now - self._last
                self._last = now
                if dt > 0.0001:
                    self._fps = 0.85 * self._fps + 0.15 * (1.0 / dt)
                return int(dt * 1000.0)

            def get_fps(self):
                return self._fps

        class _TimeMod:
            Clock = _Clock
            @staticmethod
            def get_ticks():
                return int((time.perf_counter() - pg_self._start_ts) * 1000.0)

        class _EventMod:
            @staticmethod
            def get():
                evs = list(pg_self._events)
                pg_self._events.clear()
                return evs
            @staticmethod
            def post(ev):
                pg_self._events.append(ev)

        class _KeyMod:
            @staticmethod
            def get_pressed():
                return pg_self._keys

        class _MouseMod:
            @staticmethod
            def get_pos():
                return pg_self._mouse_pos
            @staticmethod
            def get_pressed():
                return tuple(pg_self._mouse_btns)

        class _DisplayMod:
            @staticmethod
            def init(): pass
            @staticmethod
            def set_caption(cap):
                pg_self._caption = cap
                if pg_self._root is not None:
                    pg_self._root.title(cap)
            @staticmethod
            def get_surface():
                return pg_self._surface
            @staticmethod
            def set_mode(size, flags=0):
                w, h = int(size[0]), int(size[1])
                pg_self._surface = _CompatSurface((w, h), flags)
                if pg_self._tk_available and pg_self._root is None:
                    try:
                        root = tk.Tk()
                        root.title(pg_self._caption)
                        root.geometry(f"{w}x{h}")
                        root.minsize(580, 400)
                        root.configure(bg=THEME['bg'])
                        cv = tk.Canvas(root, width=w, height=h, bg=THEME['bg'], highlightthickness=0)
                        cv.pack(fill='both', expand=True)
                        pg_self._root = root
                        pg_self._canvas = cv
                        pg_self._bind_tk_events(root, cv)
                    except Exception:
                        pg_self._tk_available = False
                        pg_self._root = None
                        pg_self._canvas = None
                return pg_self._surface

            @staticmethod
            def flip():
                cv = pg_self._canvas
                if cv is None:
                    return
                try:
                    cv.delete('all')
                    for op in pg_self._surface._ops:
                        kind = op[0]
                        if kind == 'rect':
                            x1, y1, x2, y2 = op[1]
                            cv.create_rectangle(x1, y1, x2, y2, fill=op[2], outline=op[3], width=op[4])
                        elif kind == 'oval':
                            x1, y1, x2, y2 = op[1]
                            cv.create_oval(x1, y1, x2, y2, fill=op[2], outline=op[3], width=op[4])
                        elif kind == 'poly':
                            cv.create_polygon(*op[1], fill=op[2], outline=op[3], width=op[4])
                        elif kind == 'line':
                            cv.create_line(*op[1], fill=op[2], width=op[3])
                        elif kind == 'text':
                            if op[6]:
                                tw = max(10, len(op[3]) * int(op[4][1] * 0.72))
                                th = int(op[4][1] * 1.5)
                                cv.create_rectangle(op[1], op[2], op[1] + tw, op[2] + th, fill=op[6], outline='')
                            cv.create_text(op[1], op[2], text=op[3], anchor='nw', fill=op[5], font=op[4])
                except Exception:
                    pass

            @staticmethod
            def update(rects=None):
                _DisplayMod.flip()

        class _DummySound:
            def __init__(self, *a, **kw): pass
            def play(self): pass
            def set_volume(self, v): pass

        class _MixerMod:
            Sound = _DummySound
            @staticmethod
            def init(*a, **kw): pass

        self.draw = _DrawMod()
        self.font = _FontMod()
        self.time = _TimeMod()
        self.event = _EventMod()
        self.key = _KeyMod()
        self.mouse = _MouseMod()
        self.display = _DisplayMod()
        self.mixer = _MixerMod()

    def init(self):
        self._start_ts = time.perf_counter()
        return (6, 0)

    def quit(self):
        if self._root is not None:
            try:
                self._root.destroy()
            except Exception:
                pass
            self._root = None

    def _map_keysym(self, ks):
        k = (ks or '').lower()
        table = {
            'backspace': self.K_BACKSPACE, 'return': self.K_RETURN, 'kp_enter': self.K_RETURN,
            'escape': self.K_ESCAPE, 'space': self.K_SPACE,
            'up': self.K_UP, 'down': self.K_DOWN, 'left': self.K_LEFT, 'right': self.K_RIGHT,
            'shift_l': self.K_LSHIFT, 'shift_r': self.K_RSHIFT,
        }
        if k in table:
            return table[k]
        if len(k) == 1:
            return ord(k)
        return 0

    def _bind_tk_events(self, root, cv):
        def on_close():
            self._events.append(_CompatEvent(self.QUIT))
        root.protocol("WM_DELETE_WINDOW", on_close)

        def on_cfg(e):
            if e.widget == cv and (e.width != self._surface._w or e.height != self._surface._h):
                self._surface._w = max(320, e.width)
                self._surface._h = max(240, e.height)
                self._events.append(_CompatEvent(self.VIDEORESIZE, w=self._surface._w, h=self._surface._h, size=(self._surface._w, self._surface._h)))
        cv.bind('<Configure>', on_cfg)

        def on_kp(e):
            code = self._map_keysym(e.keysym)
            if not code and getattr(e, 'char', ''):
                code = ord(e.char[0].lower())
            if code:
                self._keys[code] = True
            self._events.append(_CompatEvent(self.KEYDOWN, key=code, unicode=e.char or '', mod=0))
        def on_kr(e):
            code = self._map_keysym(e.keysym)
            if not code and getattr(e, 'char', ''):
                code = ord(e.char[0].lower())
            if code:
                self._keys[code] = False
            self._events.append(_CompatEvent(self.KEYUP, key=code, mod=0))
        root.bind_all('<KeyPress>', on_kp)
        root.bind_all('<KeyRelease>', on_kr)

        def on_motion(e):
            self._mouse_pos = (e.x, e.y)
            self._events.append(_CompatEvent(self.MOUSEMOTION, pos=(e.x, e.y)))
        def on_b1_down(e):
            cv.focus_set()
            self._mouse_pos = (e.x, e.y)
            self._mouse_btns[0] = True
            self._events.append(_CompatEvent(self.MOUSEBUTTONDOWN, pos=(e.x, e.y), button=1))
        def on_b1_up(e):
            self._mouse_pos = (e.x, e.y)
            self._mouse_btns[0] = False
            self._events.append(_CompatEvent(self.MOUSEBUTTONUP, pos=(e.x, e.y), button=1))
        def on_wheel(e):
            dy = 1 if getattr(e, 'delta', 0) > 0 or getattr(e, 'num', 0) == 4 else -1
            self._events.append(_CompatEvent(self.MOUSEWHEEL, x=0, y=dy))

        cv.bind('<Motion>', on_motion)
        cv.bind('<ButtonPress-1>', on_b1_down)
        cv.bind('<ButtonRelease-1>', on_b1_up)
        cv.bind('<MouseWheel>', on_wheel)
        cv.bind('<Button-4>', on_wheel)
        cv.bind('<Button-5>', on_wheel)


def _resolve_requested_backend(explicit='auto'):
    if explicit and explicit != 'auto':
        return explicit.lower()
    for i, a in enumerate(sys.argv[1:]):
        if a.startswith('--backend='):
            return a.split('=', 1)[1].lower()
        if a == '--backend' and i + 2 < len(sys.argv):
            return sys.argv[i + 2].lower()
        if a in ('--pygame', '-pg'):
            return 'pygame'
        if a in ('--compat', '--tk'):
            return 'compat'
    return os.environ.get('LOOPING_PY_BACKEND', 'auto').lower()


class LoopNativeWindow:
    def __init__(self, backend='auto'):
        req = _resolve_requested_backend(backend)
        self.pg = None
        self.backend_name = 'pygame-compat'
        if req in ('auto', 'pygame'):
            try:
                import pygame as _real_pygame
                self.pg = _real_pygame
                self.backend_name = 'pygame'
            except Exception:
                self.pg = None

        if self.pg is None:
            self.pg = _PygameCompat()
            self.backend_name = 'pygame-compat (Tkinter)' if self.pg._tk_available else 'pygame-compat (headless)'

        self.pg.init()
        try:
            self.pg.font.init()
        except Exception:
            pass
        try:
            self.pg.mixer.init(22050, -16, 1, 512)
        except Exception:
            pass

        self.width = int(WINDOW_CFG['width'])
        self.height = int(WINDOW_CFG['height'])
        self.pg.display.set_caption(f"{WINDOW_CFG['title']} — Loop OS Native Window")
        self.screen = self.pg.display.set_mode((self.width, self.height), self.pg.RESIZABLE)
        self.clock = self.pg.time.Clock()
        self.running = True
        self.total_time = 0.0
        self.fps_display = float(WINDOW_CFG['target_fps'])

        self._fonts = {}
        self.logs = []
        self.log_scroll = 0
        self.active_input = -1
        self.active_slider = -1
        self.hover_btn = -1
        self.dragging_3d = False
        self.last_mouse = (0, 0)

        self.inputs = [dict(x) for x in INPUTS]
        self.sliders = [dict(x) for x in SLIDERS]
        self.toggles = [dict(x) for x in TOGGLES]
        self.progress_bars = [dict(x) for x in PROGRESS_BARS]
        self.entities_3d = [dict(x) for x in ENTITIES_3D]
        self.entities_2d = [dict(x) for x in ENTITIES_2D]
        self.bullets_2d = []

        self.cam_yaw = 0.0
        self.cam_pitch = 0.28
        self.cam_dist = 18.0
        self.p_vel = [0.0, 0.0, 0.0]
        self.p_jumps = 0
        self.score_3d = 0
        self.cam2d_x = 0.0
        self.score_2d = 0
        self.lives_2d = 3

        self.vp_rect = None
        self.input_rects = []
        self.slider_rects = []
        self.toggle_rects = []
        self.button_rects = []
        self.log_rect = self.pg.Rect(0, 0, 100, 100)

        self.setup_ui()

    def _font(self, size, bold=False, mono=False):
        key = (size, bold, mono)
        if key not in self._fonts:
            fam = 'Courier' if mono else 'Helvetica'
            self._fonts[key] = self.pg.font.SysFont(fam, size, bold=bold)
        return self._fonts[key]

    def setup_ui(self):
        self._compute_layout()
        self.log(f"[Loop OS Native] Ventana '{WINDOW_CFG['title']}' inicializada ({WINDOW_CFG['pipeline']}) [{self.backend_name}].", 'success')
        for freq, dur in TONES[:1]:
            self.play_tone(freq, dur)

    def log(self, msg, tag='success'):
        now = datetime.datetime.now().strftime('%H:%M:%S')
        self.logs.append((f'[{now}] {msg}', tag))
        if len(self.logs) > 300:
            self.logs.pop(0)
        self.log_scroll = 0

    def play_tone(self, freq=440, dur_ms=80):
        try:
            sr = 22050
            n = max(64, int(sr * max(20, min(800, dur_ms)) / 1000.0))
            buf = array.array('h')
            for i in range(n):
                t = i / sr
                env = min(1.0, t / 0.01) * min(1.0, (n / sr - t) / 0.03)
                buf.append(int(math.sin(2.0 * math.pi * freq * t) * 5200 * max(0.0, env)))
            if self.backend_name == 'pygame' and hasattr(self.pg.mixer, 'Sound'):
                snd = self.pg.mixer.Sound(buffer=buf.tobytes())
                snd.play()
                return
        except Exception:
            pass
        if _winsound is not None:
            threading.Thread(target=lambda: _winsound.Beep(int(max(37, min(32767, freq))), int(max(20, dur_ms))), daemon=True).start()
        elif isinstance(self.pg, _PygameCompat) and self.pg._root is not None:
            try:
                self.pg._root.bell()
            except Exception:
                pass

    def on_btn_click(self, idx):
        cfg = BUTTONS[idx]
        self.play_tone(640, 80)
        self.log(f"Botón '{cfg['text']}' presionado → Acción: {cfg['action']}", 'action')
        snip = cfg.get('snippet', '').strip()
        if snip:
            for line in snip.splitlines():
                if line.strip():
                    self.log(f"  ⚡ {line}", 'snippet')
            if snip.startswith('#!python') or snip.startswith('import '):
                try:
                    exec(snip, globals())
                except Exception as e:
                    self.log(f"[Python Error] {e}", 'action')
            else:
                def _run_snip():
                    candidates = ['./bin/looping.exe', 'bin/looping.exe', 'looping.exe', './bin/looping', './looping', 'looping']
                    bin_path = next((c for c in candidates if os.path.exists(c)), 'looping')
                    try:
                        cflags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
                        res = subprocess.run([bin_path, 'eval', snip], capture_output=True, text=True, timeout=4, creationflags=cflags)
                        if res.stdout.strip():
                            for l in res.stdout.strip().splitlines():
                                self.log(f"    {l}", 'success')
                    except Exception:
                        pass
                threading.Thread(target=_run_snip, daemon=True).start()

    def _compute_layout(self):
        pad = 14
        w = max(320, self.width - pad * 2)
        y = 62
        has_3d = WINDOW_CFG['is_3d'] or bool(self.entities_3d)
        has_2d = (not has_3d) and bool(self.entities_2d)
        self.vp_rect = None
        if has_3d or has_2d:
            vp_h = max(160, min(320, int(self.height * 0.42)))
            self.vp_rect = self.pg.Rect(pad, y, w, vp_h)
            y += vp_h + 10

        self.card_rects = []
        if CARDS:
            cols = 2 if self.width >= 640 else 1
            gap = 12
            cw = (w - gap) // 2 if cols == 2 else w
            rows = (len(CARDS) + cols - 1) // cols
            ch = 78 if (rows > 2 or self.vp_rect) else 94
            for i in range(len(CARDS)):
                col = i % cols
                row = i // cols
                self.card_rects.append(self.pg.Rect(pad + col * (cw + gap), y + row * (ch + 10), cw, ch))
            y += rows * (ch + 10)

        self.input_rects = []
        self.slider_rects = []
        self.toggle_rects = []
        self.ctrl_rect = None
        if self.inputs or self.sliders or self.toggles or self.progress_bars:
            top = y
            cy = y + 10
            for _ in self.inputs:
                self.input_rects.append(self.pg.Rect(pad + 12, cy + 18, w - 24, 26))
                cy += 52
            for _ in self.sliders:
                self.slider_rects.append(self.pg.Rect(pad + 12, cy + 20, w - 24, 14))
                cy += 42
            for _ in self.toggles:
                self.toggle_rects.append(self.pg.Rect(pad + 12, cy + 2, 240, 24))
                cy += 30
            for _ in self.progress_bars:
                cy += 36
            self.ctrl_rect = self.pg.Rect(pad, top, w, cy - top + 6)
            y = self.ctrl_rect.bottom + 10

        self.button_rects = []
        if BUTTONS:
            bx = pad
            by = y
            for b in BUTTONS:
                bw = max(118, min(260, int(len(b['text']) * 8.4 + 36)))
                if bx + bw > pad + w and bx > pad:
                    bx = pad
                    by += 42
                self.button_rects.append(self.pg.Rect(bx, by, bw, 34))
                bx += bw + 10
            y = by + 44

        bottom = max(y + 72, self.height - 14)
        self.log_rect = self.pg.Rect(pad, y, w, bottom - y)

    def handle_events(self):
        pg = self.pg
        for ev in pg.event.get():
            if ev.type == pg.QUIT:
                self.running = False
            elif ev.type == pg.VIDEORESIZE:
                self.width, self.height = max(320, ev.w), max(240, ev.h)
                if self.backend_name == 'pygame':
                    self.screen = pg.display.set_mode((self.width, self.height), pg.RESIZABLE)
            elif ev.type == pg.KEYDOWN:
                if self.active_input >= 0 and self.active_input < len(self.inputs):
                    inp = self.inputs[self.active_input]
                    if ev.key == pg.K_BACKSPACE:
                        inp['value'] = inp['value'][:-1]
                    elif ev.key == pg.K_RETURN:
                        self.log(f"Input [{inp['binding']}] = \"{inp['value']}\"", 'action')
                        self.active_input = -1
                    elif getattr(ev, 'unicode', '') and ord(ev.unicode[0]) >= 32:
                        inp['value'] += ev.unicode
                elif ev.key == pg.K_r and self.entities_2d:
                    for e in self.entities_2d:
                        e['x'], e['y'], e['vx'], e['vy'] = e['sx'], e['sy'], 0.0, 0.0
                        e['collected'], e['alive'] = False, True
                    self.score_2d, self.lives_2d = 0, 3
            elif ev.type == pg.MOUSEMOTION:
                mx, my = ev.pos
                if self.dragging_3d:
                    self.cam_yaw += (mx - self.last_mouse[0]) * 0.008
                    self.cam_pitch = max(-0.2, min(1.3, self.cam_pitch + (my - self.last_mouse[1]) * 0.006))
                if 0 <= self.active_slider < len(self.slider_rects):
                    r = self.slider_rects[self.active_slider]
                    t = max(0.0, min(1.0, (mx - r.x) / max(1, r.w)))
                    sl = self.sliders[self.active_slider]
                    sl['val'] = sl['min'] + t * (sl['max'] - sl['min'])
                self.hover_btn = next((i for i, r in enumerate(self.button_rects) if r.collidepoint(mx, my)), -1)
                self.last_mouse = (mx, my)
            elif ev.type == pg.MOUSEBUTTONDOWN and getattr(ev, 'button', 1) == 1:
                mx, my = ev.pos
                self.last_mouse = (mx, my)
                self.active_input = -1
                if self.vp_rect and self.vp_rect.collidepoint(mx, my) and (WINDOW_CFG['is_3d'] or self.entities_3d):
                    self.dragging_3d = True
                    continue
                hit = False
                for i, r in enumerate(self.input_rects):
                    if r.collidepoint(mx, my):
                        self.active_input = i
                        hit = True
                        break
                if hit: continue
                for i, r in enumerate(self.slider_rects):
                    if r.inflate(0, 14).collidepoint(mx, my):
                        self.active_slider = i
                        t = max(0.0, min(1.0, (mx - r.x) / max(1, r.w)))
                        sl = self.sliders[i]
                        sl['val'] = sl['min'] + t * (sl['max'] - sl['min'])
                        hit = True
                        break
                if hit: continue
                for i, r in enumerate(self.toggle_rects):
                    if r.collidepoint(mx, my):
                        self.toggles[i]['checked'] = not self.toggles[i]['checked']
                        st = 'ACTIVADO' if self.toggles[i]['checked'] else 'DESACTIVADO'
                        self.play_tone(720 if self.toggles[i]['checked'] else 480, 50)
                        self.log(f"Toggle '{self.toggles[i]['label']}' -> {st}", 'action')
                        hit = True
                        break
                if hit: continue
                for i, r in enumerate(self.button_rects):
                    if r.collidepoint(mx, my):
                        self.on_btn_click(i)
                        break
            elif ev.type == pg.MOUSEBUTTONUP and getattr(ev, 'button', 1) == 1:
                self.dragging_3d = False
                self.active_slider = -1
            elif ev.type == pg.MOUSEWHEEL:
                mx, my = pg.mouse.get_pos()
                if self.vp_rect and self.vp_rect.collidepoint(mx, my) and (WINDOW_CFG['is_3d'] or self.entities_3d):
                    self.cam_dist = max(6.0, min(90.0, self.cam_dist - ev.y * 1.6))
                else:
                    self.log_scroll = max(0, min(max(0, len(self.logs) - 1), self.log_scroll + (2 if ev.y > 0 else -2)))

    def update(self, dt):
        self.total_time += dt
        if self.active_input >= 0:
            return
        pg = self.pg
        ks = pg.key.get_pressed()

        if WINDOW_CFG['is_3d'] or self.entities_3d:
            if ks[pg.K_q]: self.cam_yaw -= 1.8 * dt
            if ks[pg.K_e]: self.cam_yaw += 1.8 * dt
            player = next((o for o in self.entities_3d if o['type'] == 'player'), None)
            if player:
                spd = player['speed'] * (1.75 if (ks[pg.K_LSHIFT] or ks[pg.K_RSHIFT] or ks[pg.K_x]) else 1.0)
                fx, fz = math.sin(self.cam_yaw), math.cos(self.cam_yaw)
                rx, rz = math.cos(self.cam_yaw), -math.sin(self.cam_yaw)
                mx = (1 if (ks[pg.K_d] or ks[pg.K_RIGHT]) else 0) - (1 if (ks[pg.K_a] or ks[pg.K_LEFT]) else 0)
                mz = (1 if (ks[pg.K_w] or ks[pg.K_UP]) else 0) - (1 if (ks[pg.K_s] or ks[pg.K_DOWN]) else 0)
                self.p_vel[0] = (fx * mz + rx * mx) * spd
                self.p_vel[2] = (fz * mz + rz * mx) * spd
                if ks[pg.K_SPACE] and self.p_jumps < 2:
                    self.p_vel[1] = 15.0
                    self.p_jumps += 1
                    self.play_tone(520, 45)
                for _ in range(4):
                    sdt = dt * 0.25
                    self.p_vel[1] -= 26.0 * sdt
                    player['x'] += self.p_vel[0] * sdt
                    player['y'] += self.p_vel[1] * sdt
                    player['z'] += self.p_vel[2] * sdt
                    if player['y'] <= 0.6:
                        player['y'] = 0.6
                        self.p_vel[1] = 0.0
                        self.p_jumps = 0
            else:
                cam_spd = 2.2 if (ks[pg.K_LSHIFT] or ks[pg.K_RSHIFT]) else 1.0
                if ks[pg.K_a] or ks[pg.K_LEFT]: self.cam_yaw -= 1.8 * cam_spd * dt
                if ks[pg.K_d] or ks[pg.K_RIGHT]: self.cam_yaw += 1.8 * cam_spd * dt
                if ks[pg.K_w] or ks[pg.K_UP]: self.cam_dist = max(3.5, self.cam_dist - 12.0 * cam_spd * dt)
                if ks[pg.K_s] or ks[pg.K_DOWN]: self.cam_dist = min(90.0, self.cam_dist + 12.0 * cam_spd * dt)
            for o in self.entities_3d:
                o['rot'] = (o['rot'] + 90.0 * dt) % 360.0
                if o['type'] in ('moving_platform', 'enemy', 'boss') and o['alive']:
                    ax = o['axis'] if o['axis'] in ('x', 'y', 'z') else 'x'
                    o[ax] += o['dir'] * o['speed'] * dt
                    if o[ax] >= o['max_p']: o[ax] = o['max_p']; o['dir'] = -1.0
                    if o[ax] <= o['min_p']: o[ax] = o['min_p']; o['dir'] = 1.0
                if player and o['type'] in ('crystal', 'ring') and not o['collected']:
                    if (player['x'] - o['x']) ** 2 + (player['y'] - o['y']) ** 2 + (player['z'] - o['z']) ** 2 < (o['r'] + 1.5) ** 2:
                        o['collected'] = True
                        self.score_3d += 150
                        self.play_tone(880, 70)
                        self.log(f"[3D] Recogido {o['type']} (+150 pts) | Total: {self.score_3d}", 'success')
        elif self.entities_2d:
            player = next((e for e in self.entities_2d if e['is_player'] or e['type'] == 'player'), None)
            if player is None:
                player = next((e for e in self.entities_2d if e['type'] == 'sprite'), None)
            if player and player['alive']:
                mv = (1 if (ks[pg.K_d] or ks[pg.K_RIGHT]) else 0) - (1 if (ks[pg.K_a] or ks[pg.K_LEFT]) else 0)
                player['vx'] = mv * max(180.0, player['speed'])
                if (ks[pg.K_w] or ks[pg.K_UP] or ks[pg.K_SPACE]):
                    if not player['jumping']:
                        player['vy'] = -max(360.0, player['jump'])
                        player['jumping'] = True
                        self.play_tone(480, 45)
                player['vy'] += WINDOW_CFG['gravity'] * dt
                player['x'] = max(0.0, min(WINDOW_CFG['world_width'] - player['w'], player['x'] + player['vx'] * dt))
                player['y'] += player['vy'] * dt
                floor_y = WINDOW_CFG['world_height'] - 28.0
                if player['y'] + player['h'] >= floor_y:
                    player['y'] = floor_y - player['h']
                    player['vy'] = 0.0
                    player['jumping'] = False
                for e in self.entities_2d:
                    if e is player or not e['alive'] or e['collected']:
                        continue
                    if e['type'] in ('moving_platform', 'enemy', 'boss'):
                        e['x'] += e['dir'] * e['speed'] * dt
                        if e['max_p'] > e['min_p']:
                            if e['x'] >= e['max_p']: e['x'] = e['max_p']; e['dir'] = -1.0
                            if e['x'] <= e['min_p']: e['x'] = e['min_p']; e['dir'] = 1.0
                    if e['type'] in ('platform', 'moving_platform'):
                        if (player['vy'] >= 0 and player['x'] + player['w'] > e['x'] and player['x'] < e['x'] + e['w'] and
                                e['y'] <= player['y'] + player['h'] <= e['y'] + e['h'] + 14):
                            player['y'] = e['y'] - player['h']
                            player['vy'] = 0.0
                            player['jumping'] = False
                    elif e['type'] == 'coin':
                        if (player['x'] + player['w'] > e['x'] - e['r'] and player['x'] < e['x'] + e['r'] and
                                player['y'] + player['h'] > e['y'] - e['r'] and player['y'] < e['y'] + e['r']):
                            e['collected'] = True
                            self.score_2d += int(e['pts'])
                            self.play_tone(980, 60)
                self.cam2d_x += (max(0.0, player['x'] - 240.0) - self.cam2d_x) * min(1.0, dt * 8.0)

    def _proj3d(self, px, py, pz, eye, vw, vh, vx0, vy0):
        dx, dy, dz = px - eye[0], py - eye[1], pz - eye[2]
        cy, sy = math.cos(-self.cam_yaw), math.sin(-self.cam_yaw)
        rx = dx * cy + dz * sy
        rz = -dx * sy + dz * cy
        cp, sp = math.cos(-self.cam_pitch), math.sin(-self.cam_pitch)
        ry = dy * cp - rz * sp
        vz = dy * sp + rz * cp
        if vz <= 0.4:
            return None
        f = (vh * 0.92) / vz
        return (vx0 + vw * 0.5 + rx * f, vy0 + vh * 0.5 - ry * f, vz)

    def render(self, surf):
        pg = self.pg
        self._compute_layout()
        bg_rgb = _rgb_tuple(THEME['bg'])
        card_rgb = _rgb_tuple(THEME['card_bg'])
        border_rgb = _rgb_tuple(THEME['card_border'])
        prim_rgb = _rgb_tuple(THEME['primary'])
        acc_rgb = _rgb_tuple(THEME['accent'])
        fg_rgb = _rgb_tuple(THEME['fg'])
        sub_rgb = _rgb_tuple(THEME['sub_fg'])
        btn_rgb = _rgb_tuple(THEME['btn_bg'])
        log_bg_rgb = _rgb_tuple(THEME['log_bg'])
        log_fg_rgb = _rgb_tuple(THEME['log_fg'])

        surf.fill(bg_rgb)

        # 1. Header
        pg.draw.rect(surf, card_rgb, pg.Rect(0, 0, self.width, 52))
        pg.draw.line(surf, border_rgb, (0, 52), (self.width, 52), 1)
        t_txt = self._font(16, bold=True).render(f"✦ {WINDOW_CFG['title']}", True, prim_rgb)
        surf.blit(t_txt, (18, 14))

        mode_txt = f"{self.backend_name} • {self.fps_display:.0f} FPS"
        if self.width >= 680:
            mr = pg.Rect(self.width - 430, 13, 204, 26)
            pg.draw.rect(surf, bg_rgb, mr)
            pg.draw.rect(surf, border_rgb, mr, 1)
            ms = self._font(10, bold=True).render(mode_txt, True, prim_rgb)
            surf.blit(ms, (mr.x + 10, mr.y + 5))

        br = pg.Rect(self.width - 216, 13, 200, 26)
        pg.draw.rect(surf, acc_rgb, br)
        bs = self._font(10, bold=True).render(WINDOW_CFG['badge'], True, (11, 15, 25))
        surf.blit(bs, (br.x + 10, br.y + 5))

        # 2. 3D or 2D Viewport
        if self.vp_rect:
            vp = self.vp_rect
            pg.draw.rect(surf, (5, 8, 17), vp)
            if WINDOW_CFG['is_3d'] or self.entities_3d:
                player = next((o for o in self.entities_3d if o['type'] == 'player'), None)
                px, py_p, pz = (player['x'], player['y'], player['z']) if player else (0.0, 2.0, 0.0)
                eye = [
                    px - math.sin(self.cam_yaw) * math.cos(self.cam_pitch) * self.cam_dist,
                    py_p + math.sin(self.cam_pitch) * self.cam_dist + 2.5,
                    pz - math.cos(self.cam_yaw) * math.cos(self.cam_pitch) * self.cam_dist
                ]
                for gz in range(-20, 90, 8):
                    a = self._proj3d(-40, 0, gz, eye, vp.w, vp.h, vp.x, vp.y)
                    b = self._proj3d(40, 0, gz, eye, vp.w, vp.h, vp.x, vp.y)
                    if a and b and vp.collidepoint(a[0], a[1]) and vp.collidepoint(b[0], b[1]):
                        pg.draw.line(surf, (18, 49, 84), (a[0], a[1]), (b[0], b[1]), 1)
                draw_list = []
                for o in self.entities_3d:
                    if o.get('collected') or not o.get('alive', True) or o['type'] == 'terrain':
                        continue
                    pt = self._proj3d(o['x'], o['y'], o['z'], eye, vp.w, vp.h, vp.x, vp.y)
                    if pt:
                        draw_list.append((pt[2], o, pt))
                draw_list.sort(key=lambda it: -it[0])
                for vz, o, pt in draw_list:
                    col = _rgb_tuple(o['color'])
                    if o.get('verts') and o.get('faces'):
                        ry_rad = math.radians(o.get('rot', 0.0))
                        cy_o, sy_o = math.cos(ry_rad), math.sin(ry_rad)
                        scx, scy, scz = o.get('scx', 1.0), o.get('scy', 1.0), o.get('scz', 1.0)
                        proj_v = [
                            self._proj3d(
                                o['x'] + (vx * scx) * cy_o + (vz_l * scz) * sy_o,
                                o['y'] + (vy * scy),
                                o['z'] - (vx * scx) * sy_o + (vz_l * scz) * cy_o,
                                eye, vp.w, vp.h, vp.x, vp.y
                            )
                            for vx, vy, vz_l in o['verts']
                        ]
                        polys = []
                        for fc in o['faces']:
                            if len(fc) < 3: continue
                            pts = [proj_v[idx] for idx in fc if idx < len(proj_v)]
                            if len(pts) == len(fc) and all(p is not None for p in pts):
                                avg_d = sum(p[2] for p in pts) / len(pts)
                                polys.append((avg_d, [(p[0], p[1]) for p in pts]))
                        polys.sort(key=lambda it: -it[0])
                        for _, poly_pts in polys:
                            if all(vp.collidepoint(pxx, pyy) for pxx, pyy in poly_pts):
                                pg.draw.polygon(surf, col, poly_pts)
                                pg.draw.polygon(surf, (226, 232, 240), poly_pts, 1)
                    elif vp.collidepoint(pt[0], pt[1]):
                        rad = max(4, min(42, int((max(o['sx'], o['sy']) * vp.h * 0.45) / vz)))
                        pg.draw.ellipse(surf, col, pg.Rect(pt[0] - rad, pt[1] - int(rad * 0.7), rad * 2, int(rad * 1.4)))
                        pg.draw.ellipse(surf, (255, 255, 255), pg.Rect(pt[0] - rad, pt[1] - int(rad * 0.7), rad * 2, int(rad * 1.4)), 1)
                hud = self._font(11, bold=True, mono=True).render(f"SHINE LOOP 3D ({self.backend_name.upper()}) • SCORE: {self.score_3d} • [WASD] Move [SPACE] Jump [Q/E] Orbit", True, prim_rgb)
                surf.blit(hud, (vp.x + 12, vp.y + 8))
            else:
                sy = vp.h / max(300.0, WINDOW_CFG['world_height'])
                fy = int(vp.y + (WINDOW_CFG['world_height'] - 28.0) * sy)
                pg.draw.rect(surf, (18, 30, 52), pg.Rect(vp.x, fy, vp.w, vp.bottom - fy))
                for e in self.entities_2d:
                    if not e['alive'] or e['collected']: continue
                    ex = int(vp.x + (e['x'] - self.cam2d_x) * sy)
                    ey = int(vp.y + e['y'] * sy)
                    if ex < vp.x - 40 or ex > vp.right + 40: continue
                    ec = _rgb_tuple(e['color'])
                    if e['type'] == 'coin':
                        pg.draw.circle(surf, ec, (ex, ey), max(4, int(e['r'] * sy)))
                    else:
                        pg.draw.rect(surf, ec, pg.Rect(ex, ey, max(4, int(e['w'] * sy)), max(4, int(e['h'] * sy))))
                hud2 = self._font(11, bold=True, mono=True).render(f"SHINE LOOP 2D ({self.backend_name.upper()}) • SCORE: {self.score_2d} • [A/D] Move [W/SPACE] Jump [R] Reset", True, prim_rgb)
                surf.blit(hud2, (vp.x + 12, vp.y + 8))
            pg.draw.rect(surf, prim_rgb, vp, 1)

        # 3. Cards
        for i, cr in enumerate(self.card_rects):
            c = CARDS[i]
            pg.draw.rect(surf, card_rgb, cr)
            pg.draw.rect(surf, border_rgb, cr, 1)
            pg.draw.rect(surf, prim_rgb, pg.Rect(cr.x + 10, cr.y, cr.w - 20, 3))
            surf.blit(self._font(13, bold=True).render(c['title'], True, prim_rgb), (cr.x + 12, cr.y + 10))
            if c['badge']:
                bw = len(c['badge']) * 7 + 16
                bx = cr.right - bw - 10
                pg.draw.rect(surf, border_rgb, pg.Rect(bx, cr.y + 8, bw, 20))
                surf.blit(self._font(9, bold=True).render(c['badge'], True, acc_rgb), (bx + 8, cr.y + 11))
            y_off = cr.y + 34
            for line in c['text'].splitlines():
                if y_off + 14 > cr.bottom: break
                surf.blit(self._font(11).render(line[:66], True, fg_rgb), (cr.x + 12, y_off))
                y_off += 15

        # 4. Controls
        if self.ctrl_rect:
            pg.draw.rect(surf, card_rgb, self.ctrl_rect)
            pg.draw.rect(surf, border_rgb, self.ctrl_rect, 1)
            for i, ir in enumerate(self.input_rects):
                inp = self.inputs[i]
                surf.blit(self._font(10, bold=True).render(f"Input [{inp['binding']}]:", True, sub_rgb), (ir.x, ir.y - 16))
                pg.draw.rect(surf, (30, 41, 59), ir)
                pg.draw.rect(surf, prim_rgb if i == self.active_input else border_rgb, ir, 1)
                shown = inp['value'] if inp['value'] else inp['placeholder']
                if i == self.active_input and int(self.total_time * 2) % 2 == 0:
                    shown += '|'
                surf.blit(self._font(11).render(shown, True, fg_rgb if inp['value'] else sub_rgb), (ir.x + 8, ir.y + 5))
            for i, sr in enumerate(self.slider_rects):
                sl = self.sliders[i]
                surf.blit(self._font(10, bold=True).render(f"{sl['label']}: {sl['val']:.0f}", True, sub_rgb), (sr.x, sr.y - 17))
                tr = pg.Rect(sr.x, sr.y + 4, sr.w, 6)
                pg.draw.rect(surf, log_bg_rgb, tr)
                t = max(0.0, min(1.0, (sl['val'] - sl['min']) / max(1e-6, sl['max'] - sl['min'])))
                kx = int(tr.x + tr.w * t)
                pg.draw.rect(surf, prim_rgb, pg.Rect(tr.x, tr.y, max(2, kx - tr.x), tr.h))
                pg.draw.circle(surf, acc_rgb, (kx, tr.y + 3), 7)
            for i, tr in enumerate(self.toggle_rects):
                tg = self.toggles[i]
                box = pg.Rect(tr.x, tr.y + 3, 18, 18)
                pg.draw.rect(surf, prim_rgb if tg['checked'] else log_bg_rgb, box)
                pg.draw.rect(surf, prim_rgb if tg['checked'] else border_rgb, box, 1)
                if tg['checked']:
                    surf.blit(self._font(11, bold=True).render("✓", True, (11, 15, 25)), (box.x + 3, box.y))
                surf.blit(self._font(11).render(tg['label'], True, fg_rgb), (box.right + 8, tr.y + 3))
            p_y = self.ctrl_rect.y + 10 + len(self.inputs) * 52 + len(self.sliders) * 42 + len(self.toggles) * 30
            for pr in self.progress_bars:
                surf.blit(self._font(10, bold=True).render(f"{pr['label']} ({pr['progress']:.0f}%)", True, sub_rgb), (self.ctrl_rect.x + 12, p_y))
                tr = pg.Rect(self.ctrl_rect.x + 12, p_y + 18, self.ctrl_rect.w - 24, 10)
                pg.draw.rect(surf, log_bg_rgb, tr)
                pw = int(tr.w * max(0.0, min(1.0, pr['progress'] / 100.0)))
                if pw > 0:
                    pg.draw.rect(surf, acc_rgb, pg.Rect(tr.x, tr.y, pw, tr.h))
                p_y += 36

        # 5. Buttons
        for i, br in enumerate(self.button_rects):
            b = BUTTONS[i]
            hov = (i == self.hover_btn)
            pg.draw.rect(surf, prim_rgb if hov else btn_rgb, br)
            pg.draw.rect(surf, acc_rgb if hov else border_rgb, br, 1)
            lbl = ("⚡ " if b['snippet'] else "") + b['text']
            surf.blit(self._font(11, bold=True).render(lbl, True, (11, 15, 25) if hov else (255, 255, 255)), (br.x + 12, br.y + 8))

        # 6. Log Drawer
        pg.draw.rect(surf, log_bg_rgb, self.log_rect)
        pg.draw.rect(surf, border_rgb, self.log_rect, 1)
        max_lines = max(1, (self.log_rect.h - 14) // 18)
        end_idx = max(0, len(self.logs) - self.log_scroll)
        start_idx = max(0, end_idx - max_lines)
        ly = self.log_rect.y + 8
        tag_colors = {'action': (56, 189, 248), 'success': log_fg_rgb, 'snippet': (250, 204, 21)}
        for txt, tag in self.logs[start_idx:end_idx]:
            surf.blit(self._font(11, mono=True).render(txt[:115], True, tag_colors.get(tag, log_fg_rgb)), (self.log_rect.x + 10, ly))
            ly += 18

    def step_frame(self, dt=0.016):
        self.handle_events()
        self.update(dt)
        self.render(self.screen)
        self.pg.display.flip()
        if dt > 0.0001:
            self.fps_display = 0.85 * self.fps_display + 0.15 * (1.0 / dt)

    def mainloop(self):
        max_headless = int(os.environ.get('LOOPING_HEADLESS_FRAMES', '0') or '0')
        if self.backend_name != 'pygame' and isinstance(self.pg, _PygameCompat) and self.pg._root is not None:
            prev = time.perf_counter()
            frames = [0]
            def _tk_tick():
                nonlocal prev
                if not self.running:
                    self.pg.quit()
                    return
                now = time.perf_counter()
                dt = max(0.001, min(0.05, now - prev))
                prev = now
                self.step_frame(dt)
                frames[0] += 1
                if max_headless > 0 and frames[0] >= max_headless:
                    self.running = False
                    self.pg.quit()
                    return
                self.pg._root.after(16, _tk_tick)
            self.pg._root.after(10, _tk_tick)
            self.pg._root.mainloop()
        else:
            prev = time.perf_counter()
            frames = 0
            while self.running:
                ms = self.clock.tick(WINDOW_CFG['target_fps'])
                dt = max(0.001, min(0.05, ms / 1000.0 if ms > 0 else (time.perf_counter() - prev)))
                prev = time.perf_counter()
                self.step_frame(dt)
                frames += 1
                if max_headless > 0 and frames >= max_headless:
                    self.running = False
                    break
            self.pg.quit()


if __name__ == '__main__':
    app = LoopNativeWindow()
    app.mainloop()
)LOOP_PY";

        return py.str();
    }

    DirectXWindowSpec to_directx_spec(const std::string& host_exe = "") const {
        UIProfileSpecs specs = resolve_ui_profile(target_ui);
        DirectXWindowSpec dx;
        dx.app_name = app_name;
        dx.title = title;
        dx.theme = theme;
        dx.target_ui = target_ui;
        dx.pipeline = specs.name + " " + specs.pipeline;
        dx.badge_label = (specs.code == "metal4")
            ? "Metal 4 • 240 FPS Hardware Direct"
            : (specs.name + " • " + std::to_string(specs.target_fps) + " FPS Direct");
        dx.host_exe = host_exe.empty() ? resolve_looping_host_exe() : host_exe;
        dx.width = width;
        dx.height = height;
        dx.target_fps = specs.target_fps;

        dx.bg_color = "#0b0f19";
        dx.card_bg = "#151d30";
        dx.card_border = "#22314e";
        dx.btn_bg = "#0284c7";
        dx.btn_fg = "#ffffff";
        dx.primary_color = specs.primary_color.empty() ? "#38bdf8" : specs.primary_color;
        dx.accent_color = (specs.accent_color.empty() || specs.accent_color == "#082f49") ? "#00f5d4" : specs.accent_color;
        dx.log_bg = "#070a12";
        dx.log_fg = "#10b981";

        if (specs.theme.find("aqua") != std::string::npos) {
            dx.bg_color = "#04161f";
            dx.card_bg = "#082736";
            dx.card_border = "#134e6b";
            dx.btn_bg = "#00b4d8";
            dx.primary_color = "#00f5d4";
        } else if (specs.theme.find("indigo") != std::string::npos || specs.theme.find("fold") != std::string::npos) {
            dx.bg_color = "#0d091a";
            dx.card_bg = "#1a1333";
            dx.card_border = "#352466";
            dx.btn_bg = "#7c3aed";
            dx.primary_color = "#c084fc";
        } else if (specs.theme.find("metal4") != std::string::npos || specs.code == "metal4") {
            dx.bg_color = "#070c18";
            dx.card_bg = "#0e182a";
            dx.card_border = "#1a3254";
            dx.btn_bg = "#0284c7";
            dx.primary_color = "#00f5d4";
            dx.accent_color = "#38bdf8";
        }

        dx.is_3d_mode = is_3d_mode || !entities_3d.empty();
        dx.world_width = stage_world_width;
        dx.world_height = stage_world_height;
        dx.gravity = stage_gravity;
        dx.scenario_name = stage_scenario_name;
        dx.scenario_accent = stage_scenario_accent;

        for (const auto& c : cards) {
            dx.cards.push_back({c.title, c.text, c.badge, c.icon, c.x, c.y, c.width, c.height});
        }
        for (const auto& b : buttons) {
            dx.buttons.push_back({b.text, b.action, b.snippet, b.x, b.y, b.width, b.height});
        }
        for (const auto& inp : inputs) {
            dx.inputs.push_back({inp.placeholder, inp.binding, "", inp.x, inp.y, inp.width, inp.height});
        }
        for (const auto& sl : sliders) {
            dx.sliders.push_back({sl.label, sl.binding, sl.min_val, sl.max_val, sl.current_val});
        }
        for (const auto& tg : toggles) {
            dx.toggles.push_back({tg.label, tg.binding, tg.is_checked});
        }
        for (const auto& pr : progress_bars) {
            dx.progress_bars.push_back({pr.label, pr.binding, pr.progress});
        }
        for (const auto& tn : tones) {
            dx.tones.push_back({tn.freq_hz, tn.duration_ms});
        }
        for (const auto& e : entities_3d) {
            DxEntity3DSpec de;
            de.type = e.type;
            de.name = e.name;
            de.color = e.color.empty() ? "#38bdf8" : e.color;
            de.axis = e.axis;
            de.x = e.pos.x; de.y = e.pos.y; de.z = e.pos.z;
            de.sx = e.size.x; de.sy = e.size.y; de.sz = e.size.z;
            de.scx = e.scale.x; de.scy = e.scale.y; de.scz = e.scale.z;
            de.radius = e.radius;
            de.speed = e.speed;
            de.min_pos = e.min_pos;
            de.max_pos = e.max_pos;
            de.rot_y = e.rot_deg.y;
            if (e.has_custom_mesh && !e.custom_mesh.vertices.empty() && e.custom_mesh.faces.size() <= 8000) {
                for (const auto& v : e.custom_mesh.vertices) de.verts.push_back({v.x, v.y, v.z});
                for (const auto& f : e.custom_mesh.faces) de.faces.push_back(f.indices);
            }
            dx.entities_3d.push_back(std::move(de));
        }
        dx.entities_2d = entities_2d;
        return dx;
    }

    bool save_dxwin(const std::string& path, const std::string& host_exe = "") const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            ensure_dir_exists(path.substr(0, slash));
        }
        return save_dxwin_file(path, to_directx_spec(host_exe));
    }

    std::string emit_directx_cpp() const {
        std::ostringstream cs;
        cs << "// Standalone Looping DirectX 11 Window Harness for: " << title << "\n";
        cs << "// Compile: cl /std:c++17 /EHsc /utf-8 /O2 /Icpp <file.cpp>\n";
        cs << "#include \"LoopingDirectXWindow.hpp\"\n\n";
        cs << "int main() {\n";
        cs << "    looping::DirectXWindowSpec spec;\n";
        cs << "    spec.app_name = \"" << escape_str(app_name) << "\";\n";
        cs << "    spec.title = \"" << escape_str(title) << "\";\n";
        cs << "    spec.width = " << width << ";\n";
        cs << "    spec.height = " << height << ";\n";
        cs << "    spec.target_ui = \"" << escape_str(target_ui) << "\";\n";
        for (const auto& c : cards) {
            cs << "    spec.cards.push_back({\"" << escape_str(c.title) << "\", \"" << escape_str(c.text)
               << "\", \"" << escape_str(c.badge) << "\", \"" << escape_str(c.icon) << "\", "
               << c.x << ", " << c.y << ", " << c.width << ", " << c.height << "});\n";
        }
        for (const auto& b : buttons) {
            cs << "    spec.buttons.push_back({\"" << escape_str(b.text) << "\", \"" << escape_str(b.action)
               << "\", \"" << escape_str(b.snippet) << "\", " << b.x << ", " << b.y << ", " << b.width << ", " << b.height << "});\n";
        }
        cs << "    looping::dx_native::DirectXWindowApp app;\n";
        cs << "    app.spec = std::move(spec);\n";
        cs << "    return app.run();\n";
        cs << "}\n";
        return cs.str();
    }

    bool save_directx_cpp(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            ensure_dir_exists(path.substr(0, slash));
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_directx_cpp();
        return true;
    }

    bool save_native_gui(const std::string& path) const {
        size_t slash = path.find_last_of("/\\");
        if (slash != std::string::npos) {
            ensure_dir_exists(path.substr(0, slash));
        }
        std::ofstream out(path);
        if (!out.is_open()) return false;
        out << emit_native_gui_script();
        return true;
    }

    bool show_native(bool launch_interactive = true, const std::string& backend = "auto") const {
        std::cout << render_ascii() << "\n";
        ensure_dir_exists("build");

#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
        std::string b_low = backend;
        for (char& c : b_low) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        if (b_low == "auto" || b_low == "directx" || b_low == "dx" || b_low == "native") {
            std::string dx_path = "build/" + app_name + ".dxwin";
            save_dxwin(dx_path);
            std::cout << color::GREEN << "✔ [NATIVE DIRECTX WINDOW]" << color::RESET << " Native DirectX 11 desktop window synthesized successfully:\n";
            std::cout << "  • DirectX Window Spec: " << color::CYAN << dx_path << color::RESET << " (Direct3D 11 + Direct2D + DirectWrite, Zero-Python)\n";
            if (launch_interactive) {
                pid_t pid = launch_directx_window_process(dx_path);
                std::cout << color::CYAN << "[LAUNCH DIRECTX GUI]" << color::RESET << " Launching native DirectX 11 window (PID: " << pid << ")...\n";
            }
            return true;
        }
#elif defined(__APPLE__) && (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && !defined(__EMSCRIPTEN__) && !defined(LOOPING_NO_SUBPROCESS)
        std::string b_low = backend;
        for (char& c : b_low) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        if (b_low == "auto" || b_low == "cocoa" || b_low == "appkit" || b_low == "metal4" || b_low == "native") {
            std::string dx_path = "build/" + app_name + ".dxwin";
            save_dxwin(dx_path);
            std::cout << color::GREEN << "✔ [NATIVE MACOS WINDOW]" << color::RESET << " Native AppKit + Objective-C + Assembly desktop window synthesized successfully:\n";
            std::cout << "  • Native Window Spec: " << color::CYAN << dx_path << color::RESET << " (AppKit + CoreGraphics + ASM, Zero-Python)\n";
            if (launch_interactive) {
                pid_t pid = launch_mac_window_process(dx_path);
                std::cout << color::CYAN << "[LAUNCH MACOS GUI]" << color::RESET << " Launching native macOS AppKit window (PID: " << pid << ")...\n";
            }
            return true;
        }
#else
        (void)backend;
#endif

        std::string py_path = "build/" + app_name + "_native.py";
        save_native_gui(py_path);

        std::cout << color::GREEN << "✔ [NATIVE OS WINDOW]" << color::RESET << " Native desktop window synthesized successfully:\n";
        std::cout << "  • Native GUI App: " << color::CYAN << py_path << color::RESET << " (Pygame / PygameCompat Native Engine)\n";

        if (launch_interactive) {
            std::string extra = (backend == "pygame" || backend == "compat") ? ("--backend " + backend) : "";
            pid_t pid = launch_native_window_process(py_path, extra);
            std::cout << color::CYAN << "[LAUNCH NATIVE GUI]" << color::RESET << " Launching native desktop OS window (PID: " << pid << ")...\n";
        }
        return true;
    }

    bool show(bool launch_interactive = true, const std::string& mode = "native") const {
        std::cout << render_ascii() << "\n";
        ensure_dir_exists("build");

        std::string loop_path = "build/" + app_name + ".loop";
        std::string html_path = "build/" + app_name + ".html";
        save_loop(loop_path);
        save_html(html_path);

        std::string m_low = mode;
        for (char& c : m_low) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));

#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
        bool use_dx = (m_low != "html" && m_low != "web" && m_low != "python" && m_low != "py" && m_low != "pygame" && m_low != "compat" && m_low != "tk");
        if (use_dx) {
            std::string dx_path = "build/" + app_name + ".dxwin";
            save_dxwin(dx_path);
            std::cout << color::GREEN << "✔ [DYNAMIC WINDOW]" << color::RESET << " Window synthesized successfully:\n";
            std::cout << "  • Source Script: " << color::CYAN << loop_path << color::RESET << "\n";
            std::cout << "  • Native DirectX 11: " << color::CYAN << dx_path << color::RESET << " (Direct3D 11 + Direct2D Dynamic Window, Zero-Python)\n";
            std::cout << "  • Interactive HTML5: " << color::CYAN << html_path << color::RESET << "\n";
            if (launch_interactive) {
                pid_t pid = launch_directx_window_process(dx_path);
                std::cout << color::CYAN << "[LAUNCH DIRECTX GUI]" << color::RESET << " Opening dynamic DirectX 11 window (PID: " << pid << ")...\n";
            }
            return true;
        }
#elif defined(__APPLE__) && (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && !defined(__EMSCRIPTEN__) && !defined(LOOPING_NO_SUBPROCESS)
        bool use_mac = (m_low != "html" && m_low != "web" && m_low != "python" && m_low != "py" && m_low != "pygame" && m_low != "compat" && m_low != "tk");
        if (use_mac) {
            std::string dx_path = "build/" + app_name + ".dxwin";
            save_dxwin(dx_path);
            std::cout << color::GREEN << "✔ [DYNAMIC WINDOW]" << color::RESET << " Window synthesized successfully:\n";
            std::cout << "  • Source Script: " << color::CYAN << loop_path << color::RESET << "\n";
            std::cout << "  • Native macOS AppKit+ASM: " << color::CYAN << dx_path << color::RESET << " (Cocoa AppKit + CoreGraphics + ASM, Zero-Python)\n";
            std::cout << "  • Interactive HTML5: " << color::CYAN << html_path << color::RESET << "\n";
            if (launch_interactive) {
                pid_t pid = launch_mac_window_process(dx_path);
                std::cout << color::CYAN << "[LAUNCH MACOS GUI]" << color::RESET << " Opening native macOS window (PID: " << pid << ")...\n";
            }
            return true;
        }
#endif

        std::string py_path = "build/" + app_name + "_native.py";
        save_native_gui(py_path);

        std::cout << color::GREEN << "✔ [DYNAMIC WINDOW]" << color::RESET << " Window synthesized successfully:\n";
        std::cout << "  • Source Script: " << color::CYAN << loop_path << color::RESET << "\n";
        std::cout << "  • Native OS GUI: " << color::CYAN << py_path << color::RESET << " (Pygame / PygameCompat Desktop Window)\n";
        std::cout << "  • Interactive HTML5: " << color::CYAN << html_path << color::RESET << "\n";

        if (launch_interactive) {
            if (m_low == "html" || m_low == "web") {
#if defined(LOOPING_NO_SUBPROCESS) || defined(__EMSCRIPTEN__)
                (void)html_path;
#elif defined(__APPLE__)
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
                std::string extra = (m_low == "pygame" || m_low == "compat") ? ("--backend " + m_low) : "";
                pid_t pid = launch_native_window_process(py_path, extra);
                std::cout << color::CYAN << "[LAUNCH NATIVE GUI]" << color::RESET << " Opening native desktop OS window (PID: " << pid << ")...\n";
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

// ── Invis. Compile Binary Architecture (LPBN v3.0A) ──
// Converts .loop scripts into cryptographically verified binary files & standalone native Mach-O/ELF executables
static constexpr size_t kInvisSlotTotalSize = 131072; // 128 KB embedded binary slot in __DATA,__data
static constexpr size_t kInvisSlotAnchorSize = 16;

alignas(16) inline volatile unsigned char g_invis_binary_slot[kInvisSlotTotalSize] = {
    0x89, 'L', 'P', 'S', 'L', 'O', 'T', 0x1A,
    'C', 'O', 'K', 'I', '3', '0', 'A', 0x00,
    0x00
};

struct InvisBinaryInfo {
    bool valid = false;
    bool is_standalone_exe = false;
    uint16_t version = 0x0300;
    uint16_t flags = 0;
    uint32_t target_fps = 60;
    std::string target_ui = "shine_ui";
    std::string theme = "frosted_aqua_a17";
    std::string salt;
    std::string sha256_hex;
    uint64_t payload_size = 0;
    uint64_t file_size = 0;
};

class InvisBinaryCompiler {
public:
    static constexpr size_t kLpbnHeaderSize = 152;

    static inline bool match_slot_anchor(const uint8_t* p) {
        return (p[0]  == 0x89) && (p[1]  == 0x4C) && (p[2]  == 0x50) && (p[3]  == 0x53) &&
               (p[4]  == 0x4C) && (p[5]  == 0x4F) && (p[6]  == 0x54) && (p[7]  == 0x1A) &&
               (p[8]  == 0x43) && (p[9]  == 0x4F) && (p[10] == 0x4B) && (p[11] == 0x49) &&
               (p[12] == 0x33) && (p[13] == 0x30) && (p[14] == 0x41) && (p[15] == 0x00);
    }

    static inline bool match_lpbn_magic(const uint8_t* p) {
        return (p[0] == 0x89) && (p[1] == 0x4C) && (p[2] == 0x50) && (p[3] == 0x42) &&
               (p[4] == 0x4E) && (p[5] == 0x0D) && (p[6] == 0x0A) && (p[7] == 0x1A);
    }

    static std::string build_canonical_source(const std::string& source_code, const UIProfileSpecs& specs) {
        std::ostringstream out;
        out << "compile target \"" << specs.code << "\"\n";
        out << "set ui_profile to \"" << specs.code << "\"\n";
        out << "set theme to \"" << specs.theme << "\"\n\n";

        std::stringstream in_stream(source_code);
        std::string cur_line;
        while (std::getline(in_stream, cur_line)) {
            std::string trimmed = cur_line;
            while (!trimmed.empty() && (trimmed.front() == ' ' || trimmed.front() == '\t')) trimmed.erase(0, 1);
            if (trimmed.rfind("#!/usr/bin/env looping", 0) == 0) continue;
            if (trimmed.rfind("compile target ", 0) == 0 || trimmed.rfind("compile for ", 0) == 0 ||
                trimmed.rfind("target(", 0) == 0 || trimmed.rfind("@target(", 0) == 0 ||
                trimmed.rfind("profile(", 0) == 0 || trimmed.rfind("@profile(", 0) == 0 ||
                trimmed.rfind("set ui_profile to", 0) == 0 || trimmed.rfind("set ui to", 0) == 0 ||
                trimmed.rfind("set theme to", 0) == 0) {
                out << "# [Invis. Compile Target Override]: " << trimmed << "\n";
            } else {
                out << cur_line << "\n";
            }
        }
        return out.str();
    }

    static std::vector<uint8_t> encode_lpbn(const std::string& plain_source, const UIProfileSpecs& specs, uint16_t flags = 0x0001) {
        std::string salt = CryptoUtils::sha256_hex("INVIS_SALT_3_0A:" + specs.code + ":" + plain_source).substr(0, 16);
        std::string digest_hex = CryptoUtils::sha256_hex(plain_source);
        uint64_t psize = static_cast<uint64_t>(plain_source.size());

        std::vector<uint8_t> out(kLpbnHeaderSize + plain_source.size(), 0);
        // 0..7: LPBN Magic
        out[0] = 0x89; out[1] = 0x4C; out[2] = 0x50; out[3] = 0x42;
        out[4] = 0x4E; out[5] = 0x0D; out[6] = 0x0A; out[7] = 0x1A;
        // 8..9: Version 3.0A (0x0300)
        out[8] = 0x03; out[9] = 0x00;
        // 10..11: Flags
        out[10] = static_cast<uint8_t>(flags & 0xFF);
        out[11] = static_cast<uint8_t>((flags >> 8) & 0xFF);
        // 12..15: Target FPS (uint32 LE)
        uint32_t fps = static_cast<uint32_t>(specs.target_fps);
        out[12] = static_cast<uint8_t>(fps & 0xFF);
        out[13] = static_cast<uint8_t>((fps >> 8) & 0xFF);
        out[14] = static_cast<uint8_t>((fps >> 16) & 0xFF);
        out[15] = static_cast<uint8_t>((fps >> 24) & 0xFF);
        // 16..31: Target UI code (16 bytes)
        std::strncpy(reinterpret_cast<char*>(&out[16]), specs.code.c_str(), 15);
        // 32..63: Theme code (32 bytes)
        std::strncpy(reinterpret_cast<char*>(&out[32]), specs.theme.c_str(), 31);
        // 64..79: Salt (16 bytes)
        std::memcpy(&out[64], salt.data(), std::min<size_t>(16, salt.size()));
        // 80..143: SHA-256 hex digest (64 bytes)
        std::memcpy(&out[80], digest_hex.data(), std::min<size_t>(64, digest_hex.size()));
        // 144..151: Payload size (uint64 LE)
        for (int b = 0; b < 8; ++b) {
            out[144 + b] = static_cast<uint8_t>((psize >> (b * 8)) & 0xFF);
        }

        // Encrypt payload with 256-bit SHA-256 CTR Keystream (Zero plain-text source exposure)
        std::string key_block;
        for (size_t i = 0; i < plain_source.size(); ++i) {
            if (i % 32 == 0) {
                std::string block_hash = CryptoUtils::sha256_hex(salt + ":CS_INVIS_ARCH_3_0A_KEY:" + std::to_string(i / 32));
                key_block = CryptoUtils::hex_to_bytes(block_hash);
            }
            uint8_t k = static_cast<uint8_t>(key_block[i % 32]);
            out[kLpbnHeaderSize + i] = static_cast<uint8_t>(plain_source[i]) ^ k;
        }
        return out;
    }

    static bool decode_lpbn(const uint8_t* data, size_t len, std::string* out_source, InvisBinaryInfo* out_info = nullptr) {
        if (!data || len < kLpbnHeaderSize || !match_lpbn_magic(data)) return false;

        InvisBinaryInfo info;
        info.version = static_cast<uint16_t>((data[8] << 8) | data[9]);
        info.flags = static_cast<uint16_t>(data[10] | (data[11] << 8));
        info.target_fps = static_cast<uint32_t>(data[12]) |
                          (static_cast<uint32_t>(data[13]) << 8) |
                          (static_cast<uint32_t>(data[14]) << 16) |
                          (static_cast<uint32_t>(data[15]) << 24);

        char t_buf[17] = {0};
        std::memcpy(t_buf, &data[16], 16);
        info.target_ui = std::string(t_buf);

        char th_buf[33] = {0};
        std::memcpy(th_buf, &data[32], 32);
        info.theme = std::string(th_buf);

        info.salt = std::string(reinterpret_cast<const char*>(&data[64]), 16);
        info.sha256_hex = std::string(reinterpret_cast<const char*>(&data[80]), 64);

        uint64_t psize = 0;
        for (int b = 0; b < 8; ++b) {
            psize |= (static_cast<uint64_t>(data[144 + b]) << (b * 8));
        }
        info.payload_size = psize;

        if (psize > len - kLpbnHeaderSize) return false;

        std::string decrypted;
        decrypted.resize(static_cast<size_t>(psize));
        std::string key_block;
        for (size_t i = 0; i < static_cast<size_t>(psize); ++i) {
            if (i % 32 == 0) {
                std::string block_hash = CryptoUtils::sha256_hex(info.salt + ":CS_INVIS_ARCH_3_0A_KEY:" + std::to_string(i / 32));
                key_block = CryptoUtils::hex_to_bytes(block_hash);
            }
            uint8_t k = static_cast<uint8_t>(key_block[i % 32]);
            decrypted[i] = static_cast<char>(data[kLpbnHeaderSize + i] ^ k);
        }

        std::string computed_hash = CryptoUtils::sha256_hex(decrypted);
        if (!CryptoUtils::constant_time_eq(computed_hash, info.sha256_hex)) {
            return false;
        }

        info.valid = true;
        if (out_source) *out_source = decrypted;
        if (out_info) *out_info = info;
        return true;
    }

    static bool has_embedded_slot_payload() {
        uint8_t hdr[8];
        for (int i = 0; i < 8; ++i) {
            hdr[i] = g_invis_binary_slot[kInvisSlotAnchorSize + i];
        }
        return match_lpbn_magic(hdr);
    }

    static bool extract_from_embedded_slot(std::string* out_source, InvisBinaryInfo* out_info = nullptr) {
        if (!has_embedded_slot_payload()) return false;
        size_t max_payload = kInvisSlotTotalSize - kInvisSlotAnchorSize;
        std::vector<uint8_t> local_buf(max_payload);
        for (size_t i = 0; i < max_payload; ++i) {
            local_buf[i] = g_invis_binary_slot[kInvisSlotAnchorSize + i];
        }
        InvisBinaryInfo info;
        bool ok = decode_lpbn(local_buf.data(), local_buf.size(), out_source, &info);
        if (ok) {
            info.is_standalone_exe = true;
            if (out_info) *out_info = info;
        }
        return ok;
    }

    static bool extract_from_file(const std::string& path, std::string* out_source, InvisBinaryInfo* out_info = nullptr) {
        std::ifstream f(path, std::ios::binary | std::ios::ate);
        if (!f.is_open()) return false;
        std::streamsize fsize = f.tellg();
        if (fsize < static_cast<std::streamsize>(kLpbnHeaderSize)) return false;
        f.seekg(0, std::ios::beg);

        // 1. Fast check for compact LPBN binary at offset 0
        uint8_t head8[8] = {0};
        f.read(reinterpret_cast<char*>(head8), 8);
        f.seekg(0, std::ios::beg);

        if (match_lpbn_magic(head8)) {
            std::vector<uint8_t> bytes(static_cast<size_t>(fsize));
            if (!f.read(reinterpret_cast<char*>(bytes.data()), fsize)) return false;
            InvisBinaryInfo info;
            bool ok = decode_lpbn(bytes.data(), bytes.size(), out_source, &info);
            if (ok) {
                info.is_standalone_exe = false;
                info.file_size = static_cast<uint64_t>(fsize);
                if (out_info) *out_info = info;
            }
            return ok;
        }

        // 2. Check if Mach-O / ELF / PE binary containing populated g_invis_binary_slot
        uint8_t exe_mag[4] = {0};
        std::memcpy(exe_mag, head8, 4);
        bool looks_like_exe =
            (exe_mag[0] == 0xCA && exe_mag[1] == 0xFE && exe_mag[2] == 0xBA && exe_mag[3] == 0xBE) || // Fat Mach-O BE
            (exe_mag[0] == 0xCF && exe_mag[1] == 0xFA && exe_mag[2] == 0xED && exe_mag[3] == 0xFE) || // Mach-O 64 LE
            (exe_mag[0] == 0xFE && exe_mag[1] == 0xED && exe_mag[2] == 0xFA && exe_mag[3] == 0xCF) || // Mach-O 64 BE
            (exe_mag[0] == 0x7F && exe_mag[1] == 'E'  && exe_mag[2] == 'L'  && exe_mag[3] == 'F')  || // ELF
            (exe_mag[0] == 'M'  && exe_mag[1] == 'Z');                                                // PE
        if (!looks_like_exe) return false;

        std::vector<uint8_t> bytes(static_cast<size_t>(fsize));
        if (!f.read(reinterpret_cast<char*>(bytes.data()), fsize)) return false;

        for (size_t i = 0; i + kInvisSlotAnchorSize + kLpbnHeaderSize <= bytes.size(); ++i) {
            if (bytes[i] == 0x89 && match_slot_anchor(&bytes[i])) {
                const uint8_t* slot_payload = &bytes[i + kInvisSlotAnchorSize];
                size_t rem = bytes.size() - (i + kInvisSlotAnchorSize);
                if (match_lpbn_magic(slot_payload)) {
                    InvisBinaryInfo info;
                    if (decode_lpbn(slot_payload, rem, out_source, &info)) {
                        info.is_standalone_exe = true;
                        info.file_size = static_cast<uint64_t>(fsize);
                        if (out_info) *out_info = info;
                        return true;
                    }
                }
            }
        }
        return false;
    }

    static bool is_binary_artifact(const std::string& path) {
        InvisBinaryInfo info;
        return extract_from_file(path, nullptr, &info) && info.valid;
    }

    static std::string resolve_host_executable() {
#ifdef __APPLE__
        char exe_buf[4096];
        uint32_t sz = sizeof(exe_buf);
        if (_NSGetExecutablePath(exe_buf, &sz) == 0) {
            std::ifstream f(exe_buf, std::ios::binary);
            if (f.good()) return std::string(exe_buf);
        }
#elif defined(_WIN32)
        char exe_buf[MAX_PATH];
        DWORD len = GetModuleFileNameA(NULL, exe_buf, MAX_PATH);
        if (len > 0 && len < MAX_PATH) {
            std::ifstream f(exe_buf, std::ios::binary);
            if (f.good()) return std::string(exe_buf);
        }
#elif defined(__linux__)
        char exe_buf[4096];
        ssize_t len = readlink("/proc/self/exe", exe_buf, sizeof(exe_buf) - 1);
        if (len > 0) {
            exe_buf[len] = '\0';
            std::ifstream f(exe_buf, std::ios::binary);
            if (f.good()) return std::string(exe_buf);
        }
#endif
        std::vector<std::string> candidates = {
#ifdef _WIN32
            "bin/looping.exe",
            "../bin/looping.exe",
            "../../bin/looping.exe",
            "looping.exe",
#endif
            "bin/looping",
            "../bin/looping",
            "../../bin/looping",
            "/Users/jerix/cokistudios.github.io/bin/looping",
            "/Users/jerix/engine/bin/looping",
            "/usr/local/bin/looping"
        };
        for (const auto& c : candidates) {
            std::ifstream f(c, std::ios::binary);
            if (f.good()) return c;
        }
        return "";
    }

    static bool compile_to_binary(const std::string& canonical_source,
                                  const UIProfileSpecs& specs,
                                  const std::string& out_file,
                                  bool force_compact = false,
                                  bool silent = false,
                                  InvisBinaryInfo* out_info = nullptr) {
        size_t slash = out_file.find_last_of("/\\");
        if (slash != std::string::npos) {
            std::string dir = out_file.substr(0, slash);
            ensure_dir_exists(dir);
        }

        auto ends_with = [](const std::string& str, const std::string& suf) {
            return str.size() >= suf.size() && str.compare(str.size() - suf.size(), suf.size(), suf) == 0;
        };

        bool wants_compact = force_compact ||
                             ends_with(out_file, ".loopb") ||
                             ends_with(out_file, ".lbin") ||
                             ends_with(out_file, ".loopc");

        uint16_t flags = wants_compact ? 0x0001 : 0x0003;
        std::vector<uint8_t> lpbn_img = encode_lpbn(canonical_source, specs, flags);

        bool wrote_standalone = false;
        if (!wants_compact && (lpbn_img.size() + kInvisSlotAnchorSize <= kInvisSlotTotalSize)) {
            std::string host_exe = resolve_host_executable();
            if (!host_exe.empty()) {
                std::ifstream hf(host_exe, std::ios::binary | std::ios::ate);
                if (hf.is_open()) {
                    std::streamsize h_sz = hf.tellg();
                    hf.seekg(0, std::ios::beg);
                    if (h_sz > static_cast<std::streamsize>(kInvisSlotTotalSize)) {
                        std::vector<uint8_t> exe_bytes(static_cast<size_t>(h_sz));
                        if (hf.read(reinterpret_cast<char*>(exe_bytes.data()), h_sz)) {
                            size_t slots_patched = 0;
                            for (size_t i = 0; i + kInvisSlotTotalSize <= exe_bytes.size(); ++i) {
                                if (exe_bytes[i] == 0x89 && match_slot_anchor(&exe_bytes[i])) {
                                    std::memset(&exe_bytes[i + kInvisSlotAnchorSize], 0, kInvisSlotTotalSize - kInvisSlotAnchorSize);
                                    std::memcpy(&exe_bytes[i + kInvisSlotAnchorSize], lpbn_img.data(), lpbn_img.size());
                                    slots_patched++;
                                    i += kInvisSlotTotalSize - 1;
                                }
                            }
                            if (slots_patched > 0) {
                                // Remove existing file first to invalidate macOS kernel vnode code-signing cache
                                std::remove(out_file.c_str());
                                std::ofstream out(out_file, std::ios::binary);
                                if (out.is_open()) {
                                    out.write(reinterpret_cast<const char*>(exe_bytes.data()), static_cast<std::streamsize>(exe_bytes.size()));
                                    out.close();
                                    make_executable(out_file);
#if defined(__APPLE__) && !defined(LOOPING_NO_SUBPROCESS)
                                    std::string sign_cmd = "codesign --force --sign - \"" + out_file + "\" >/dev/null 2>&1";
                                    system(sign_cmd.c_str());
#endif
                                    wrote_standalone = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!wrote_standalone) {
            std::remove(out_file.c_str());
            std::ofstream out(out_file, std::ios::binary);
            if (!out.is_open()) {
                if (!silent) {
                    std::cerr << "\033[31m❌ Error: Cannot write binary target to: " << out_file << "\033[0m\n";
                }
                return false;
            }
            out.write(reinterpret_cast<const char*>(lpbn_img.data()), static_cast<std::streamsize>(lpbn_img.size()));
            out.close();
            make_executable(out_file);
        }

        if (out_info) {
            decode_lpbn(lpbn_img.data(), lpbn_img.size(), nullptr, out_info);
            out_info->is_standalone_exe = wrote_standalone;
        }
        return true;
    }

    static std::string ensure_invis_cache(const std::string& script_path, const std::string& raw_source, const UIProfileSpecs& specs) {
        std::string base = script_path;
        size_t sl = base.find_last_of("/\\");
        if (sl != std::string::npos) base = base.substr(sl + 1);
        size_t dot = base.find_last_of('.');
        if (dot != std::string::npos) base = base.substr(0, dot);
        if (base.empty()) base = "script";

        std::string clean_name;
        for (char c : base) {
            if (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-') clean_name += c;
            else clean_name += '_';
        }

        std::string cache_path = "build/.invis/" + clean_name + ".loopb";
        std::string canonical = build_canonical_source(raw_source, specs);
        std::string expected_sha = CryptoUtils::sha256_hex(canonical);

        InvisBinaryInfo existing_info;
        if (extract_from_file(cache_path, nullptr, &existing_info) && existing_info.valid &&
            existing_info.sha256_hex == expected_sha) {
            return cache_path;
        }

        compile_to_binary(canonical, specs, cache_path, /*force_compact=*/true, /*silent=*/true, nullptr);
        return cache_path;
    }
};

// ── Looping Compiler Core ──
// Provides static and dynamic compilation of Looping code to executable binary artifacts
class Compiler {
public:
    // Compiles raw source code string into target UI profile binary artifact (via Invis. Compile LPBN v3.0A)
    static bool compile_source(const std::string& source_code, 
                               const std::string& target_name, 
                               const std::string& output_path,
                               std::string* out_created_path = nullptr,
                               bool force_compact = false) {
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
                ensure_dir_exists(swift_file.substr(0, slash));
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
#if !defined(LOOPING_NO_SUBPROCESS) && !defined(__EMSCRIPTEN__)
                // Compile directly into native Mach-O executable using Apple swiftc
                std::string swiftc_cmd = "swiftc -parse-as-library \"" + swift_file + "\" -o \"" + out_file + "\" 2>/dev/null";
                int ret = system(swiftc_cmd.c_str());
                if (ret == 0) {
                    if (out_created_path) *out_created_path = out_file;
                    std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Native SwiftUI binary compiled to: " << out_file << " [Apple Ecosystem / SwiftUI Metal 120Hz]\n";
                    return true;
                }
#endif
            }

            if (out_created_path) *out_created_path = swift_file;
            std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Native SwiftUI artifact compiled to: " << swift_file << " [Apple Ecosystem / SwiftUI Metal 120Hz]\n";
            return true;
        }

        // C# / Unity / loopize++ Managed C# Target Compilation
        if (target_name == "csharp" || target_name == "cs" || target_name == "unity" ||
            (out_file.size() >= 3 && out_file.substr(out_file.size() - 3) == ".cs")) {
            bool wants_cs_file = (out_file.size() >= 3 && out_file.substr(out_file.size() - 3) == ".cs");
            std::string cs_file = wants_cs_file ? out_file : (out_file + ".cs");
            size_t slash = cs_file.find_last_of("/\\");
            if (slash != std::string::npos) {
                ensure_dir_exists(cs_file.substr(0, slash));
            }

            std::ostringstream cs;
            cs << "// Generated by Looping Engine v1.1 (Arch 3.0A) — C# & loopize++ Exporter\n";
            cs << "using System;\nusing System.Collections.Generic;\n\n";
            cs << "namespace CokiStudios.Loopize {\n";
            cs << "    public struct Vec3 { public float X, Y, Z; public Vec3(float x, float y, float z) { X = x; Y = y; Z = z; } }\n";
            cs << "    public class ObjMeshSpec { public string Name, ObjPath; public Vec3 Position; public float Scale; public string CsClass; }\n\n";
            cs << "    public class LoopizeExportedGame {\n";
            cs << "        public List<ObjMeshSpec> Entities = new List<ObjMeshSpec> {\n";
            std::istringstream iss(source_code);
            std::string src_line;
            while (std::getline(iss, src_line)) {
                if (src_line.find("spawn3d.obj") != std::string::npos) {
                    cs << "            // Source: " << src_line << "\n";
                }
            }
            cs << "        };\n\n";
            cs << "        public static void Main(string[] args) {\n";
            cs << "            var game = new LoopizeExportedGame();\n";
            cs << "            Console.WriteLine($\"[loopize++ C#] Ready with {game.Entities.Count} 3D specs.\");\n";
            cs << "        }\n";
            cs << "    }\n";
            cs << "}\n";

            std::ofstream cs_out(cs_file);
            if (!cs_out.is_open()) {
                std::cerr << "\033[31m❌ Error: Cannot write C# target to: " << cs_file << "\033[0m\n";
                return false;
            }
            cs_out << cs.str();
            cs_out.close();

            if (!wants_cs_file) {
#if defined(__EMSCRIPTEN__) || defined(LOOPING_NO_SUBPROCESS)
                // External C# compilation skipped inside WASM sandbox; export .cs source
#elif defined(_WIN32)
                std::string mcs_cmd = "(where.exe csc >NUL 2>&1 && csc /nologo /out:\"" + out_file + "\" \"" + cs_file + "\" >NUL 2>&1)";
                if (system(mcs_cmd.c_str()) == 0) {
                    if (out_created_path) *out_created_path = out_file;
                    std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Managed C# assembly compiled to: " << out_file << " [C# / loopize++]\n";
                    return true;
                }
#else
                std::string mcs_cmd = "(command -v mcs >/dev/null 2>&1 && mcs -out:\"" + out_file + "\" \"" + cs_file + "\" 2>/dev/null) || "
                                      "(command -v csc >/dev/null 2>&1 && csc -out:\"" + out_file + "\" \"" + cs_file + "\" 2>/dev/null)";
                if (system(mcs_cmd.c_str()) == 0) {
                    if (out_created_path) *out_created_path = out_file;
                    std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Managed C# assembly compiled to: " << out_file << " [C# / loopize++]\n";
                    return true;
                }
#endif
            }
            if (out_created_path) *out_created_path = cs_file;
            std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m C# loopize++ source artifact exported to: " << cs_file << " [C# / .OBJ 3D]\n";
            return true;
        }

        // Create parent directories if needed
        size_t slash = out_file.find_last_of("/\\");
        if (slash != std::string::npos) {
            ensure_dir_exists(out_file.substr(0, slash));
        }

        std::string canonical_source = InvisBinaryCompiler::build_canonical_source(source_code, specs);

        // Check if caller explicitly requested a plain-text .loop script (and NOT invis target)
        bool wants_plain_loop = (specs.code != "invis") &&
                                ((out_file.size() >= 5 && out_file.substr(out_file.size() - 5) == ".loop") ||
                                 (out_file.size() >= 5 && out_file.substr(out_file.size() - 5) == ".ruup"));

        InvisBinaryInfo bin_info;
        if (wants_plain_loop) {
            std::ofstream out(out_file);
            if (!out.is_open()) {
                std::cerr << "\033[31m❌ Error: Cannot write compiled target to: " << out_file << "\033[0m\n";
                return false;
            }
            out << "#!/usr/bin/env looping\n" << canonical_source;
            out.close();
            make_executable(out_file);
        } else {
            if (!InvisBinaryCompiler::compile_to_binary(canonical_source, specs, out_file, force_compact, /*silent=*/false, &bin_info)) {
                return false;
            }
        }

        // Packaging for Component 2 (.c2) bundles
        if (specs.code == "c2" || (out_file.size() >= 3 && out_file.substr(out_file.size() - 3) == ".c2")) {
            std::string c2_file = out_file;
            if (c2_file.size() < 3 || c2_file.substr(c2_file.size() - 3) != ".c2") {
                c2_file += ".c2";
            }
            std::error_code ec;
            std::string abs_c2_file = std::filesystem::absolute(c2_file, ec).string();
            std::string tmp_dir = (std::filesystem::temp_directory_path(ec) / ("c2_build_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count()))).string();
            ensure_dir_exists(tmp_dir);

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
               << "  \"entrypoint\": \"source.loop\",\n"
               << "  \"binary_entrypoint\": \"binary.loopb\"\n"
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

            // 4. Source & Invis. Binary
            {
                std::ofstream sf(tmp_dir + "/source.loop");
                sf << canonical_source;
            }
            InvisBinaryCompiler::compile_to_binary(canonical_source, specs, tmp_dir + "/binary.loopb", /*force_compact=*/true, /*silent=*/true);

            // 5. Signature (pure C++ SHA-256 across all bundled artifacts)
            {
                std::ofstream sig_f(tmp_dir + "/signature.sha256");
                for (const char* fname : {"manifest.json", "tokens.json", "layout.json", "source.loop", "binary.loopb"}) {
                    std::ifstream f_in(tmp_dir + "/" + fname, std::ios::binary);
                    if (f_in.is_open()) {
                        std::string bytes((std::istreambuf_iterator<char>(f_in)), std::istreambuf_iterator<char>());
                        sig_f << CryptoUtils::sha256_hex(bytes) << "  " << fname << "\n";
                    }
                }
            }

            // 6. Zip into .c2 (Remove pre-existing file so zip creates a clean new archive)
            std::filesystem::remove(abs_c2_file, ec);
#if defined(__EMSCRIPTEN__) || defined(LOOPING_NO_SUBPROCESS)
            // In WASM, leave virtual directory cleaned up or artifact written
#elif defined(_WIN32)
            {
                std::string zip_cmd = "powershell -NoProfile -Command \"Compress-Archive -Path '" + tmp_dir + "\\*' -DestinationPath '" + abs_c2_file + ".zip' -Force; Move-Item -Force '" + abs_c2_file + ".zip' '" + abs_c2_file + "'\" >NUL 2>&1";
                system(zip_cmd.c_str());
            }
#else
            {
                std::string zip_cmd = "(cd \"" + tmp_dir + "\" && zip -q -r \"" + abs_c2_file + "\" .)";
                system(zip_cmd.c_str());
            }
#endif
            std::filesystem::remove_all(tmp_dir, ec);
            std::cout << "\033[36m📦 [C2 PACKAGER]\033[0m Assembled Android Component 2 package: \033[1m" << abs_c2_file << "\033[0m\n";
        }

        if (out_created_path) {
            *out_created_path = out_file;
        }

        if (!wants_plain_loop) {
            std::cout << "\033[32m✔ [INVIS. COMPILE SUCCESS]\033[0m Binary artifact compiled to: "
                      << "\033[1m" << out_file << "\033[0m ["
                      << (bin_info.is_standalone_exe ? "Standalone Native Binary / LPBN v3.0A" : "LPBN v3.0A Compact Binary")
                      << " | SHA-256: " << (bin_info.sha256_hex.size() >= 12 ? bin_info.sha256_hex.substr(0, 12) : bin_info.sha256_hex)
                      << "... | " << specs.name << "]\n";
        } else {
            std::cout << "\033[32m✔ [COMPILER SUCCESS]\033[0m Dynamic target artifact compiled to: " 
                      << "\033[1m" << out_file << "\033[0m [" << specs.name << " / " << specs.pipeline << "]\n";
        }

        return true;
    }

    // Compiles a file to a target binary artifact
    static bool compile_file(const std::string& input_path, 
                             const std::string& target_name, 
                             const std::string& output_path,
                             std::string* out_created_path = nullptr,
                             bool force_compact = false) {
        std::string source_code;
        InvisBinaryInfo existing_bin;
        if (InvisBinaryCompiler::extract_from_file(input_path, &source_code, &existing_bin) && existing_bin.valid) {
            // Input is already a binary file; re-target or re-emit
        } else {
            std::ifstream file(input_path);
            if (!file.is_open()) {
                std::cerr << "\033[31m❌ Error: Cannot open input file: " << input_path << "\033[0m\n";
                return false;
            }
            std::stringstream buffer;
            buffer << file.rdbuf();
            source_code = buffer.str();
        }

        std::string out_file = output_path;
        if (out_file.empty()) {
            std::string base_name = input_path;
            size_t slash = base_name.find_last_of("/\\");
            if (slash != std::string::npos) base_name = base_name.substr(slash + 1);
            size_t dot = base_name.find_last_of('.');
            if (dot != std::string::npos) base_name = base_name.substr(0, dot);
            UIProfileSpecs specs = resolve_ui_profile(target_name);
            if (specs.code == "invis") {
                out_file = "build/" + base_name + (force_compact ? ".loopb" : ".bin");
            } else {
                out_file = "build/" + base_name + "_" + specs.code;
            }
        }

        return compile_source(source_code, target_name, out_file, out_created_path, force_compact);
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

    // Factory: Creates pre-configured template programs with Arch 3.0A CS modules & snippets
    static DynamicProgram create_template(const std::string& type, const std::string& name, const std::string& target = "shine_ui") {
        DynamicProgram prog(name, target, "1.1");

        if (type == "arcade" || type == "game" || type == "platformer") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " 2D Game", 800, 600)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("loop.engine", "game")
                .add_import("csid", "csid")
                .add_import("game_plus", "game_plus")
                .add_import("audio", "sound")
                .add_var("player_x", "100")
                .add_var("player_y", "350")
                .add_var("player_vx", "0.0")
                .add_var("player_vy", "0.0")
                .add_var("player_score", "0")
                .add_var("player_lives", "3")
                .add_var("coins_collected", "0")
                .add_var("is_jumping", "false")
                .add_snippet("on_player_jump",
                    "if (!is_jumping) {\n"
                    "    player_vy := -12.5;\n"
                    "    is_jumping := true;\n"
                    "    game.play_sfx(\"jump\");\n"
                    "    out(\"[GAME SNIPPET] Player jumped! Impulse vy = -12.5\");\n"
                    "}")
                .add_snippet("on_collect_coin",
                    "val coin_box = [340, 330, 24, 24];\n"
                    "val player_box = [player_x, player_y, 32, 32];\n"
                    "val hit = game.collide_box(player_box, coin_box);\n"
                    "if (hit) {\n"
                    "    player_score += 150;\n"
                    "    coins_collected += 1;\n"
                    "    game.play_sfx(\"coin\");\n"
                    "    game.spawn_particle(\"sparkle\", 340, 330, 0.0, -2.0, \"#facc15\");\n"
                    "    out($\"[GAME SNIPPET] Coin collected! Score: {player_score} (Coins: {coins_collected})\");\n"
                    "} else {\n"
                    "    player_score += 50;\n"
                    "    game.play_sfx(\"coin\");\n"
                    "    out($\"[GAME SNIPPET] Bonus coin! Score: {player_score}\");\n"
                    "}")
                .add_snippet("on_laser_fire",
                    "val laser_x = player_x + 36;\n"
                    "val laser_y = player_y + 12;\n"
                    "game.play_sfx(\"laser\");\n"
                    "game.spawn_particle(\"laser_bolt\", laser_x, laser_y, 14.0, 0.0, \"#38bdf8\");\n"
                    "out($\"[GAME SNIPPET] Laser beam discharged from ({laser_x}, {laser_y})\");")
                .add_snippet("on_enemy_hit",
                    "player_score += 500;\n"
                    "game.play_sfx(\"hit\");\n"
                    "game.spawn_particle(\"explosion\", 550, 300, 0.0, 0.0, \"#ef4444\");\n"
                    "out($\"[GAME SNIPPET] Enemy eliminated! Score: {player_score}\");")
                .add_snippet("on_game_loop",
                    "player_vy += 0.85; // Gravity\n"
                    "player_y += player_vy;\n"
                    "if (player_y >= 350) {\n"
                    "    player_y := 350;\n"
                    "    player_vy := 0.0;\n"
                    "    is_jumping := false;\n"
                    "}\n"
                    "player_x := game.clamp(player_x + player_vx, 20, 760);\n"
                    "out($\"[PHYSICS 60Hz] Player pos: ({player_x}, {player_y}) | vy: {player_vy}\");")
                .add_card(20, 20, 760, 85, "🎮 " + name + " (Quantum 2D Arena)", "State-of-the-art 2D Canvas Engine (Arch 3.0A)\nTarget: " + target + " | V-Sync Direct 60/120 FPS")
                .add_card(20, 115, 370, 160, "⚡ Estado del Héroe", "Vidas: 3 • Puntos: 0 • Monedas: 0\nFísica: Gravedad 0.85G • Salto: Activo")
                .add_card(410, 115, 370, 160, "👾 Anomalía & Enemigos", "Escenario: VoidStage Neon\nHaz Láser: Activo a 550px\nPortal: GATE-1 Sincronizado")
                .add_button(35, 290, "SALTO [SPACE]", "on_player_jump")
                .add_button(220, 290, "DISPARAR LÁSER [F]", "on_laser_fire")
                .add_button(430, 290, "RECOGER MONEDA", "on_collect_coin")
                .add_button(610, 290, "FRAME DE FÍSICA", "on_game_loop")
                .add_code("game.scenario(name: \"VoidStage\", weather: \"void\", accent: \"#38bdf8\")\n"
                          "spawn.sprite(\"PlayerHero\", at: (100, 350), color: \"#38bdf8\")\n"
                          "spawn.checkpoint(at: (300, 350), label: \"GATE-1\")\n"
                          "spawn.laser_hazard(at: (550, 300), size: (14, 100), interval: 1.8)\n"
                          "game.play_sfx(\"powerup\")\n"
                          "print \"[GAME ENGINE] Initialized 2D canvas with embedded reactive snippets.\"");
        } else if (type == "game3d" || type == "3d" || type == "racing3d") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " 3D Quantum Arena", 900, 620)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("loop.engine", "game")
                .add_import("csid", "csid")
                .add_import("game_plus", "game_plus")
                .add_import("audio", "sound")
                .add_var("pilot_pos", "[0.0, 2.0, 0.0]")
                .add_var("pilot_vel", "[0.0, 0.0, 0.0]")
                .add_var("score_3d", "0")
                .add_var("kers_boost", "100")
                .add_snippet("on_boost_3d",
                    "val fwd = math3d.normalize([0.0, 0.15, 1.0]);\n"
                    "pilot_vel := math3d.scale(fwd, 28.0);\n"
                    "kers_boost := game.clamp(kers_boost - 20, 0, 100);\n"
                    "game.play_sfx(\"powerup\");\n"
                    "out($\"[3D HYPER-DASH] Vector impulso: {pilot_vel} | KERS: {kers_boost}%\");")
                .add_snippet("on_raycast_scan",
                    "val hit = physics3d.raycast_sphere([0, 2, 0], [0, 0, 1], [0, 2, 18], 2.5);\n"
                    "if (hit[\"hit\"]) {\n"
                    "    score_3d += 250;\n"
                    "    game.play_sfx(\"laser\");\n"
                    "    out($\"[3D RAYCAST] Impacto confirmado a {hit.distance}m! Score: {score_3d}\");\n"
                    "}")
                .add_card(20, 20, 860, 80, "🕹️ " + name + " (Quantum 3D Engine)", "Motor 3D con Sub-Stepping 120Hz, Z-Buffer y Proyección en Perspectiva\nTarget: " + target + " | Iluminación Blinn-Phong & Sombras Dinámicas")
                .add_button(35, 120, "HYPER-DASH 3D [SHIFT]", "on_boost_3d")
                .add_button(260, 120, "ESCANEO RAYCAST 3D [Z]", "on_raycast_scan")
                .add_code("game.mode(\"3d\")\n"
                          "scene3d.world(name: \"" + name + "\", size: (180, 80, 180), sky: \"cyber_night\", fog: 0.010, grid: true)\n"
                          "camera3d.set(mode: \"chase\", pos: (0, 8, -16), target: (0, 2, 10), fov: 64, smooth: 0.14)\n"
                          "light3d.directional(dir: (-0.4, -1.0, -0.35), color: \"#f8fafc\", intensity: 1.1)\n"
                          "physics3d.config(gravity: -26.0, substeps: 4, friction: 0.86, bounce: 0.15)\n"
                          "spawn3d.player(\"" + name + "Pilot\", at: (0, 2, 0), mesh: \"hovercraft\", speed: 24, jump: 16, color: \"#38bdf8\")\n"
                          "spawn3d.box(at: (0, -0.5, 14), size: (14, 1, 28), color: \"#6366f1\")\n"
                          "spawn3d.ring(at: (0, 4, 18), radius: 3.2, points: 250, boost: 22, color: \"#00f5d4\")\n"
                          "spawn3d.crystal(at: (3, 3, 24), points: 150, color: \"#fbbf24\")\n"
                          "spawn3d.enemy(\"Sentinel3D\", at: (0, 2.5, 32), range: (-8, 8), axis: \"x\", speed: 9, health: 60)\n"
                          "spawn3d.portal(at: (0, 3.5, 48), radius: 3.8, label: \"QUANTUM GATE\")\n"
                          "print \"[3D ENGINE] Initialized 3D scene graph with 120Hz physics sub-stepping.\"");
        } else if (type == "rpg" || type == "adventure") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " RPG Adventure", 840, 580)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("loop.engine", "game")
                .add_import("core_utils", "utils")
                .add_import("audio", "sound")
                .add_var("hero_name", "\"Kael\"")
                .add_var("hero_hp", "120")
                .add_var("hero_max_hp", "120")
                .add_var("hero_mana", "60")
                .add_var("hero_gold", "250")
                .add_var("hero_inventory", "[\"Poción Curativa\", \"Cristal de Maná\", \"Daga de Cristal\"]")
                .add_snippet("on_dialogue_step",
                    "val dialogues = [\n"
                    "    \"Guardián CS: Bienvenido al núcleo del Arch 3.0A, valiente aventurero.\",\n"
                    "    \"Guardián CS: El portal cuántico requiere sincronizar la clave de sala CSMS.\",\n"
                    "    \"Guardián CS: Toma esta gema y avanza sin vacilar hacia el siguiente nivel.\"\n"
                    "];\n"
                    "sound.play_note(\"E4\", 80);\n"
                    "out($\"[RPG DIALOGUE] {dialogues[0]}\");")
                .add_snippet("on_combat_attack",
                    "val base_dmg = math.random(18, 32);\n"
                    "val is_crit = (math.random(1, 100) <= 25);\n"
                    "val final_dmg = is_crit ? (base_dmg * 2) : base_dmg;\n"
                    "if (is_crit) {\n"
                    "    game.play_sfx(\"powerup\");\n"
                    "    out($\"[RPG COMBAT] ¡GOLPE CRÍTICO! Infliges {final_dmg} de daño elemental.\");\n"
                    "} else {\n"
                    "    game.play_sfx(\"hit\");\n"
                    "    out($\"[RPG COMBAT] Ataque exitoso: infliges {final_dmg} de daño.\");\n"
                    "}")
                .add_snippet("on_use_potion",
                    "if (contains(hero_inventory, \"Poción Curativa\")) {\n"
                    "    hero_hp := math.min(hero_max_hp, hero_hp + 45);\n"
                    "    sound.play_note(\"G4\", 120);\n"
                    "    out($\"[RPG ITEM] Usaste Poción Curativa. Vida restaurada: {hero_hp}/{hero_max_hp}\");\n"
                    "} else {\n"
                    "    out(\"[RPG ITEM] No tienes más pociones curativas en el inventario.\");\n"
                    "}")
                .add_card(20, 20, 800, 80, "🗡️ " + name + " (RPG & Quest System)", "Aventura Reactiva • Coki Studios Story Engine (Arch 3.0A)")
                .add_card(20, 110, 390, 170, "🧙‍♂️ Estado del Héroe", "Nombre: Kael • Nivel: 5 • HP: 120/120\nManá: 60/60 • Oro: 250 • Equipo: Daga de Cristal")
                .add_card(430, 110, 390, 170, "📜 Misión Principal", "Objetivo: Explorar las Ruinas Cuánticas\nClave CSMS Requerida: S256 Hardware Enclave")
                .add_button(35, 300, "HABLAR CON NPC", "on_dialogue_step")
                .add_button(240, 300, "ATACAR ENEMIGO", "on_combat_attack")
                .add_button(450, 300, "USAR POCIÓN", "on_use_potion")
                .add_code("sound.play_note(\"C4\", 100)\nsound.play_note(\"G4\", 150)\nprint \"[RPG] Adventure realm loaded successfully.\"");
        } else if (type == "dashboard" || type == "app" || type == "launcher") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " Dashboard Pro", 860, 560)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("csid", "csid")
                .add_import("core_utils", "utils")
                .add_import("csms", "csms")
                .add_import("json", "json")
                .add_var("telemetry_status", "\"OPERATIONAL\"")
                .add_var("active_users", "1420")
                .add_var("latency_ms", "0.16")
                .add_var("session_id", "utils.uuid()")
                .add_snippet("on_csid_login",
                    "val user = csid.trigger_auth(\"Jerix Ortiz\", \"jerix@cokistudios.com\");\n"
                    "out($\"[CSID AUTH] Sesión iniciada para: {user.name} ({user.email})\");\n"
                    "out($\"[CSID CLAIMS] Identidad: {user.provider} | Scope: {user.scope}\");")
                .add_snippet("on_refresh_telemetry",
                    "latency_ms := (math.random(12, 28) / 100.0);\n"
                    "active_users += math.random(-5, 12);\n"
                    "val ts = datetime.iso();\n"
                    "out($\"[TELEMETRY REFRESH] Sincronizado a las {ts} | Latencia: {latency_ms} ms | Usuarios: {active_users}\");")
                .add_snippet("on_csms_encrypt_payload",
                    "val room = \"room_cs_ops_99\";\n"
                    "val raw_data = $\"status={telemetry_status};latency={latency_ms};users={active_users}\";\n"
                    "val encrypted = csms.encrypt(room, raw_data);\n"
                    "out($\"[CSMS E2EE] Payload cifrado para sala '{room}':\");\n"
                    "out($\"  {encrypted}\");")
                .add_snippet("on_export_json_report",
                    "val report = {\n"
                    "    \"app\": \"" + name + "\",\n"
                    "    \"session_id\": session_id,\n"
                    "    \"status\": telemetry_status,\n"
                    "    \"active_users\": active_users,\n"
                    "    \"latency_ms\": latency_ms,\n"
                    "    \"timestamp\": datetime.iso()\n"
                    "};\n"
                    "val json_out = json.stringify(report);\n"
                    "out(\"[DATA EXPORT] Reporte JSON generado exitosamente:\");\n"
                    "out(json_out);")
                .add_card(20, 20, 820, 75, "🌟 " + name + " (Coki Studios Enterprise Dashboard)", "Arch 3.0A Quantum Synthesis • Target: " + target + " • V-Sync 60/120/240Hz Direct")
                .add_card(20, 105, 395, 175, "🔐 CS ID Connect Identity", "Estado: Single Sign-On PKCE S256\nEndpoint: cokistudios.com/authorize\nHardware Enclave: Activo (SEP/T2)")
                .add_card(445, 105, 395, 175, "🔒 CSMS Mensajería E2EE", "Cifrado: Hardware-Backed SEP / T2 / StrongBox\nCanal: SHA-256 KDF con Salt Canónico\nFormato: enc:v1:<iv>:<ciphertext>")
                .add_button(35, 300, "CONECTAR CS ID", "on_csid_login")
                .add_button(235, 300, "REFRESCAR TELEMETRÍA", "on_refresh_telemetry")
                .add_button(450, 300, "CIFRAR PAYLOAD CSMS", "on_csms_encrypt_payload")
                .add_button(665, 300, "EXPORTAR JSON", "on_export_json_report")
                .add_code("play tone at 587 Hz for 80 ms\nplay tone at 880 Hz for 120 ms\nprint \"[DASHBOARD] Enterprise telemetry initialized with default CS modules.\"");
        } else if (type == "tool" || type == "counter" || type == "cli") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " Tool", 640, 440)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("core_utils", "utils")
                .add_import("csms", "csms")
                .add_import("json", "json")
                .add_var("counter", "0")
                .add_var("raw_payload", "\"CS_QUANTUM_DATA_PACKET\"")
                .add_snippet("on_process_data",
                    "counter += 1;\n"
                    "val hash = crypto.sha256($\"task_{counter}\");\n"
                    "out($\"[TOOL SNIPPET] Tarea #{counter} procesada. Hash: {hash}\");")
                .add_snippet("on_format_utility",
                    "val sample_bytes = 10485760;\n"
                    "val formatted = utils.format_bytes(sample_bytes);\n"
                    "val slug = utils.slugify(\"Coki Studios Looping Engine 1.1\");\n"
                    "out($\"[TOOL SNIPPET] Format: {formatted} | Slug: {slug}\");")
                .add_snippet("on_secure_encrypt",
                    "val enc = csms.encrypt(\"tool_sandbox\", raw_payload);\n"
                    "out($\"[TOOL SNIPPET] Encrypted payload: {enc}\");")
                .add_card(20, 20, 600, 80, "⚡ " + name + " (Productivity Tool)", "Universal Task & Data Transformer (Arch 3.0A)")
                .add_card(20, 110, 600, 150, "📦 Panel de Operaciones", "Contador Activo: Tareas bajo demanda\nAlgoritmos: SHA-256, CSMS KDF, Formato Kebab")
                .add_button(35, 280, "PROCESAR TAREA", "on_process_data")
                .add_button(235, 280, "UTILIDADES DE FORMATO", "on_format_utility")
                .add_button(450, 280, "CIFRADO SEGURO", "on_secure_encrypt")
                .add_code("print \"[TOOL] Utility initialized and ready.\"");
        } else if (type == "swiftui" || type == "apple") {
            prog.set_window(name + " SwiftUI", 700, 500)
                .set_target("swiftui")
                .add_code(
                    "component " + name + "View {\n"
                    "    @state count = 0\n"
                    "    @state is_active = true\n"
                    "    VStack {\n"
                    "        Text(\"🍎 " + name + " (SwiftUI)\")\n"
                    "            .font(.title)\n"
                    "            .foregroundColor(.primary)\n"
                    "        Text(\"Contador reactivo: $count\")\n"
                    "            .foregroundColor(.secondary)\n"
                    "        HStack {\n"
                    "            Button(\"Incrementar\")\n"
                    "            Button(\"Resetear\")\n"
                    "        }\n"
                    "        Toggle(\"Servicio Activo\", isOn: $is_active)\n"
                    "    }\n"
                    "    .padding(20)\n"
                    "}\n"
                    "print \"[SWIFTUI] Component registered. Preview with: looping preview\"\n"
                );
        } else if (type == "loopize3d" || type == "csharp3d" || type == "obj3d") {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " Loopize++ 3D", 920, 640)
                .set_theme(specs.theme)
                .add_import("loop.ui", "ui")
                .add_import("loopize++", "loopize++")
                .add_import("csharp", "csharp")
                .add_var("hero_speed", "28.0")
                .add_card(20, 20, 880, 85, "⚡ " + name + " (loopize++ .OBJ + C# 3D)", "ECS + Wave Director + Spring-Arm Camera + Wavefront .OBJ + C# MonoBehaviour")
                .add_button(36, 120, "SPAWN WAVE", "lz_wave_rush")
                .add_code("lz_banner(\"" + name + "\")\n"
                          "scene3d.world(name: \"" + name + "\", size: (220, 100, 220), sky: \"cyber_night\", fog: 0.008, grid: true)\n"
                          "spawn3d.obj(\"Starfighter\", obj: \"assets/models/starfighter.obj\", at: (0, 2, 10), scale: 1.5, color: \"#38bdf8\")\n"
                          "val w1 = lz_wave_rush(1, \"valkyrie\", 3, 90, \"valkyrie_drone.obj\")\n"
                          "lz_report()");
        } else {
            UIProfileSpecs specs = resolve_ui_profile(target);
            prog.set_window(name + " Window", 850, 540)
                .set_theme(specs.theme)
                .add_card(24, 20, 390, 160, "🌟 " + name, "Ventana dinámica generada por Looping v1.1 (Arch 3.0A)\nDiseño Loop OS & Glassmorphism Reactivo")
                .add_card(434, 20, 390, 160, "⚡ Métricas & Hardware", "Perfil UI: " + specs.name + " (" + specs.pipeline + ")\nRefresco: " + std::to_string(specs.target_fps) + " FPS Direct")
                .add_card(24, 200, 390, 180, "📦 Módulos Integrados", "• CS ID Connect PKCE S256\n• CSMS E2EE Hardware Encryption\n• Looping AST & Runtime v1.1 (Arch 3.0A)")
                .add_card(434, 200, 390, 180, "🎯 Panel de Control", "Control directo del subsistema gráfico y ejecución de snippets reactivos.")
                .add_button(36, 420, "INICIAR PROCESO", "start_process")
                .add_button(240, 420, "REINICIAR SERVICIOS", "restart_services")
                .add_button(440, 420, "EXPORTAR REGISTRO", "export_log")
                .add_code("play tone at 587 Hz for 80 ms\nplay tone at 880 Hz for 120 ms\nprint \"[DYNAMIC WINDOW] '" + name + "' inicializada con éxito.\"");
        }

        return prog;
    }

    // Runs an executable artifact or script (supports Standalone Native Binary, LPBN Compact Binary, and .loop scripts)
    static bool run_artifact(const std::string& path) {
#ifdef __EMSCRIPTEN__
        (void)path;
        return false;
#elif defined(LOOPING_NO_SUBPROCESS)
        (void)path;
        return false;
#else
        std::cout << "\033[36m[LAUNCHER]\033[0m Executing artifact: \033[1m" << path << "\033[0m\n";
        std::string host_exe = InvisBinaryCompiler::resolve_host_executable();
        if (host_exe.empty()) host_exe = "looping";

        auto is_abs_or_rel = [](const std::string& p) {
            if (p.rfind("./", 0) == 0 || p.rfind(".\\", 0) == 0 || (!p.empty() && (p.front() == '/' || p.front() == '\\'))) return true;
            if (p.size() >= 2 && p[1] == ':') return true;
            return false;
        };

        InvisBinaryInfo info;
        if (InvisBinaryCompiler::extract_from_file(path, nullptr, &info) && info.valid) {
            if (info.is_standalone_exe) {
#ifdef _WIN32
                std::string cmd = "\"" + path + "\"";
#else
                std::string cmd = is_abs_or_rel(path) ? ("\"" + path + "\"") : ("./\"" + path + "\"");
#endif
                return (system(cmd.c_str()) == 0);
            } else {
                std::string cmd = "\"" + host_exe + "\" \"" + path + "\"";
                return (system(cmd.c_str()) == 0);
            }
        }

        std::string cmd;
        if (path.find(".loop") != std::string::npos || path.find(".ruup") != std::string::npos) {
            cmd = "\"" + host_exe + "\" \"" + path + "\"";
        } else {
#ifdef _WIN32
            cmd = "\"" + path + "\"";
#else
            cmd = is_abs_or_rel(path) ? ("\"" + path + "\"") : ("./\"" + path + "\"");
#endif
        }
        int res = system(cmd.c_str());
        return (res == 0);
#endif
    }
};

} // namespace looping
