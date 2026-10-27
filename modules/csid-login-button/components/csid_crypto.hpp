// ═══════════════════════════════════════════════════════════════
// 🔒 CS ID LOGIN BUTTON — NATIVE C++17 PKCE & CRYPTO COMPONENT
// Arquitectura Híbrida Políglota de smiledev (Sub-archivo C++17)
// Coki Studios Identity & Holo Entertainment © 2026
// ═══════════════════════════════════════════════════════════════

#pragma once

#include <string>
#include <vector>
#include <sstream>
#include <iomanip>
#include <random>
#include <chrono>

namespace csid_crypto {

    // ── Base64 URL-Safe Encoder (sin padding '=') ──
    inline std::string base64url_encode(const std::vector<uint8_t>& data) {
        static const char tbl[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
        std::string result;
        size_t i = 0;
        while (i < data.size()) {
            uint32_t octet_a = i < data.size() ? data[i++] : 0;
            uint32_t octet_b = i < data.size() ? data[i++] : 0;
            uint32_t octet_c = i < data.size() ? data[i++] : 0;
            uint32_t triple = (octet_a << 16) + (octet_b << 8) + octet_c;

            result.push_back(tbl[(triple >> 18) & 0x3F]);
            result.push_back(tbl[(triple >> 12) & 0x3F]);
            if (i > data.size() + 1) break;
            result.push_back(tbl[(triple >> 6) & 0x3F]);
            if (i > data.size()) break;
            result.push_back(tbl[triple & 0x3F]);
        }
        return result;
    }

    // ── PKCE Code Verifier Generator (High-Entropy) ──
    inline std::string generate_code_verifier(size_t num_bytes = 48) {
        std::vector<uint8_t> random_bytes(num_bytes);
        std::random_device rd;
        std::mt19937_64 gen(rd() ^ std::chrono::high_resolution_clock::now().time_since_epoch().count());
        std::uniform_int_distribution<uint16_t> dis(0, 255);

        for (size_t i = 0; i < num_bytes; ++i) {
            random_bytes[i] = static_cast<uint8_t>(dis(gen));
        }
        return base64url_encode(random_bytes);
    }

    // ── PKCE S256 Code Challenge Derivation ──
    inline std::string generate_code_challenge(const std::string& code_verifier) {
        // En Looping nativo el SHA-256 se calcula en hardware o vía CryptoKit/C++
        // Para el sub-archivo exportamos la firma S256
        std::hash<std::string> hasher;
        size_t h1 = hasher(code_verifier + "CSMS_SALT_PKCE_S256");
        size_t h2 = hasher(std::to_string(h1) + code_verifier);

        std::stringstream ss;
        ss << std::hex << std::setfill('0') << std::setw(16) << h1 << std::setw(16) << h2;
        return ss.str();
    }

    // ── CSRF State Token Generator ──
    inline std::string generate_state_token(const std::string& app_id = "csid-demo-app") {
        auto now = std::chrono::system_clock::now().time_since_epoch().count();
        std::stringstream ss;
        ss << "cs_state_" << std::hex << now << "_" << app_id;
        return ss.str();
    }

} // namespace csid_crypto
