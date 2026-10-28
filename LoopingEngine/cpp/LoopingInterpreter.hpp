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
    std::string app_version = "1.0.0-commercial";
    std::string arch_version = "2.8A";
    std::string edition = "Commercial Edition";
    std::string target_platform = "Shine Loop Console (Holo Looping OoS)";
    std::string ui_profile = "xui";
    std::string theme = "frosted_aqua_a17";
    UIProfileSpecs active_ui_specs = resolve_ui_profile("xui");
    PythonBridge python_bridge;
    DynamicWindow current_window;

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

        // Initialize Dynamic Window subsystem
        current_window = DynamicWindow(app_name + " Window", 850, 540, ui_profile);
        current_window.set_theme(theme);
    }

    void print_banner() {
        std::cout << "\n" << color::BOLD << color::PURPLE << "----------------------------------------------------------------------" << color::RESET << "\n";
        std::cout << color::BOLD << color::CYAN << "[LOOPING COMMERCIAL]" << color::RESET << " " 
                  << color::GREEN << "Core Production Engine v" << app_version << color::RESET << " " 
                  << color::YELLOW << "(Arch " << arch_version << " / POSIX Native)" << color::RESET << "\n";
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
                return Value(app_version);
            }
            if (n == "sys.edition" || n == "looping.edition") {
                return Value(edition);
            }
            if (n == "sys.arch_version" || n == "looping.arch_version") {
                return Value(arch_version);
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
                    obj_var != "swiftui" &&
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
                                std::string snip = b.snippet;
                                size_t p = snip.find_first_not_of(" \t\r\n");
                                std::string prefix = (p != std::string::npos) ? snip.substr(p) : "";
                                if (prefix.rfind("#!python", 0) == 0 || prefix.rfind("import ", 0) == 0) {
                                    python_bridge.execute_block(snip, variables);
                                } else {
                                    execute_code(snip);
                                }
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
                return Value(ok ? path : "");
            }
            if (name == "window.show_native" || name == "window.open_native" || name == "window.native") {
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
        std::cout << color::CYAN << "│" << color::RESET << color::BOLD << " 🍎 SwiftUI Canvas Preview — Looping Engine v2.9 (Universal)     " << color::RESET << color::CYAN << "│" << color::RESET << "\n";
        std::cout << color::CYAN << "│" << color::RESET << " Target: Apple Ecosystem (iOS / macOS / visionOS)                " << color::CYAN << "│" << color::RESET << "\n";
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

            // Check if built-in stdlib module
            static const std::unordered_set<std::string> stdlib_modules = {
                "math", "crypto", "sys", "system", "csv", "datetime", "regex", "ui", "swiftui", "json", "file"
            };
            if (stdlib_modules.count(mod) > 0) {
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

                // Pure Looping module (.loop)
                std::ifstream lf(resolved_path);
                std::string loop_content((std::istreambuf_iterator<char>(lf)), std::istreambuf_iterator<char>());
                execute_code(loop_content);
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
            } else if (sp->entity_type == "portal") {
                std::cout << color::PURPLE << "[PORTAL]" << color::RESET << " Stage Goal at (" 
                          << sp->x << ", " << sp->y << ") [\"" << sp->text << "\"]\n";
            } else {
                std::cout << color::CYAN << "[WORLD]" << color::RESET << " Placed " << sp->entity_type 
                          << " Stage Component\n";
            }
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
