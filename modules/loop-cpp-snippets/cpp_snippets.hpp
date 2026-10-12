// cpp_snippets.hpp - Coki Studios Looping Snippet Library
// Essential high-performance C++ snippets for Looping applications and game engines.
#pragma once

#include <iostream>
#include <chrono>
#include <string>
#include <vector>
#include <array>
#include <cmath>
#include <sstream>
#include <iomanip>
#include <functional>
#include <cstdint>
#include <algorithm>
#include <thread>

namespace looping {
namespace snippets {

// ============================================================================
// 1. BenchmarkTimer: High-resolution RAII stopwatch and profiler
// ============================================================================
class BenchmarkTimer {
public:
    explicit BenchmarkTimer(std::string name = "Benchmark", bool auto_print = false)
        : name_(std::move(name)), auto_print_(auto_print),
          start_point_(std::chrono::high_resolution_clock::now()) {}

    ~BenchmarkTimer() {
        if (auto_print_) {
            double ms = elapsed_ms();
            std::cout << "[Timer] " << name_ << ": " << ms << " ms (" 
                      << elapsed_us() << " µs)" << std::endl;
        }
    }

    void reset() {
        start_point_ = std::chrono::high_resolution_clock::now();
    }

    double elapsed_ms() const {
        auto end_point = std::chrono::high_resolution_clock::now();
        return std::chrono::duration<double, std::milli>(end_point - start_point_).count();
    }

    int64_t elapsed_us() const {
        auto end_point = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::microseconds>(end_point - start_point_).count();
    }

    int64_t elapsed_ns() const {
        auto end_point = std::chrono::high_resolution_clock::now();
        return std::chrono::duration_cast<std::chrono::nanoseconds>(end_point - start_point_).count();
    }

private:
    std::string name_;
    bool auto_print_;
    std::chrono::time_point<std::chrono::high_resolution_clock> start_point_;
};

// ============================================================================
// 2. RingBuffer: Fixed-capacity circular buffer for frame times & telemetry
// ============================================================================
template <typename T, size_t Capacity>
class RingBuffer {
public:
    RingBuffer() : head_(0), size_(0) {}

    void push(const T& item) {
        data_[head_] = item;
        head_ = (head_ + 1) % Capacity;
        if (size_ < Capacity) {
            ++size_;
        }
    }

    void clear() {
        head_ = 0;
        size_ = 0;
    }

    size_t size() const { return size_; }
    constexpr size_t capacity() const { return Capacity; }
    bool empty() const { return size_ == 0; }
    bool full() const { return size_ == Capacity; }

    // Access elements from oldest (0) to newest (size - 1)
    T get(size_t index) const {
        if (index >= size_) return T{};
        size_t start = (head_ + Capacity - size_) % Capacity;
        return data_[(start + index) % Capacity];
    }

    // Access the latest pushed element
    T latest() const {
        if (empty()) return T{};
        size_t idx = (head_ + Capacity - 1) % Capacity;
        return data_[idx];
    }

    // Average value (for numerical types like frametimes)
    double average() const {
        if (empty()) return 0.0;
        double sum = 0.0;
        for (size_t i = 0; i < size_; ++i) {
            sum += static_cast<double>(get(i));
        }
        return sum / static_cast<double>(size_);
    }

private:
    std::array<T, Capacity> data_{};
    size_t head_;
    size_t size_;
};

// ============================================================================
// 3. FNV1a: Compile-time and runtime string hashing for fast switch statements
// ============================================================================
struct FNV1a {
    static constexpr uint32_t OFFSET_BASIS_32 = 0x811c9dc5;
    static constexpr uint32_t PRIME_32 = 0x01000193;

    static constexpr uint32_t hash32(const char* str, size_t len) {
        uint32_t hash = OFFSET_BASIS_32;
        for (size_t i = 0; i < len; ++i) {
            hash ^= static_cast<uint8_t>(str[i]);
            hash *= PRIME_32;
        }
        return hash;
    }

    static constexpr uint32_t hash32(const char* str) {
        uint32_t hash = OFFSET_BASIS_32;
        while (*str) {
            hash ^= static_cast<uint8_t>(*str++);
            hash *= PRIME_32;
        }
        return hash;
    }

    static inline uint32_t hash32(const std::string& str) {
        return hash32(str.data(), str.size());
    }
};

// User-defined string literal for switch statements: switch(hash32(str)) { case "click"_hash: ... }
constexpr uint32_t operator""_hash(const char* str, size_t len) {
    return FNV1a::hash32(str, len);
}

// ============================================================================
// 4. ColorRGBA: 32-bit color utilities, hex parsing, and interpolation
// ============================================================================
struct ColorRGBA {
    uint8_t r{255};
    uint8_t g{255};
    uint8_t b{255};
    uint8_t a{255};

    ColorRGBA() = default;
    ColorRGBA(uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha = 255)
        : r(red), g(green), b(blue), a(alpha) {}

    static ColorRGBA from_hex(const std::string& hex) {
        std::string h = hex;
        if (!h.empty() && h[0] == '#') h = h.substr(1);
        if (h.length() == 6) {
            uint32_t val = static_cast<uint32_t>(std::stoul(h, nullptr, 16));
            return ColorRGBA((val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF, 255);
        } else if (h.length() == 8) {
            uint32_t val = static_cast<uint32_t>(std::stoul(h, nullptr, 16));
            return ColorRGBA((val >> 24) & 0xFF, (val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF);
        }
        return ColorRGBA(255, 255, 255, 255);
    }

    std::string to_hex(bool include_alpha = false) const {
        std::ostringstream ss;
        ss << "#" << std::hex << std::setfill('0');
        ss << std::setw(2) << static_cast<int>(r);
        ss << std::setw(2) << static_cast<int>(g);
        ss << std::setw(2) << static_cast<int>(b);
        if (include_alpha) {
            ss << std::setw(2) << static_cast<int>(a);
        }
        return ss.str();
    }

    static ColorRGBA lerp(const ColorRGBA& c1, const ColorRGBA& c2, float t) {
        t = std::max(0.0f, std::min(1.0f, t));
        auto r = static_cast<uint8_t>(c1.r + (c2.r - c1.r) * t);
        auto g = static_cast<uint8_t>(c1.g + (c2.g - c1.g) * t);
        auto b = static_cast<uint8_t>(c1.b + (c2.b - c1.b) * t);
        auto a = static_cast<uint8_t>(c1.a + (c2.a - c1.a) * t);
        return ColorRGBA(r, g, b, a);
    }

    float luminance() const {
        return (0.299f * r + 0.587f * g + 0.114f * b) / 255.0f;
    }
};

// ============================================================================
// 5. Math & 2D Physics: Vector2, AABB Overlap, and Math Interpolators
// ============================================================================
template <typename T>
inline T clamp(T val, T min_val, T max_val) {
    return (val < min_val) ? min_val : (val > max_val ? max_val : val);
}

template <typename T>
inline T lerp(T a, T b, float t) {
    return static_cast<T>(a + (b - a) * t);
}

inline float smoothstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return x * x * (3.0f - 2.0f * x);
}

struct Vec2 {
    float x{0.0f};
    float y{0.0f};

    Vec2() = default;
    Vec2(float x_, float y_) : x(x_), y(y_) {}

    Vec2 operator+(const Vec2& o) const { return {x + o.x, y + o.y}; }
    Vec2 operator-(const Vec2& o) const { return {x - o.x, y - o.y}; }
    Vec2 operator*(float scalar) const { return {x * scalar, y * scalar}; }

    float length() const { return std::sqrt(x * x + y * y); }
    float length_sq() const { return x * x + y * y; }

    Vec2 normalized() const {
        float len = length();
        return (len > 0.00001f) ? Vec2(x / len, y / len) : Vec2(0.0f, 0.0f);
    }

    static float dot(const Vec2& a, const Vec2& b) {
        return a.x * b.x + a.y * b.y;
    }
};

struct AABB2D {
    Vec2 min_pt;
    Vec2 max_pt;

    bool overlaps(const AABB2D& other) const {
        return (min_pt.x <= other.max_pt.x && max_pt.x >= other.min_pt.x) &&
               (min_pt.y <= other.max_pt.y && max_pt.y >= other.min_pt.y);
    }

    bool contains(const Vec2& pt) const {
        return (pt.x >= min_pt.x && pt.x <= max_pt.x &&
                pt.y >= min_pt.y && pt.y <= max_pt.y);
    }
};

// ============================================================================
// 6. String Utilities: Trim, Split, Join, Replace
// ============================================================================
inline std::string trim(const std::string& str) {
    size_t first = str.find_first_not_of(" \t\n\r");
    if (first == std::string::npos) return "";
    size_t last = str.find_last_not_of(" \t\n\r");
    return str.substr(first, (last - first + 1));
}

inline std::vector<std::string> split(const std::string& str, char delim) {
    std::vector<std::string> tokens;
    std::stringstream ss(str);
    std::string token;
    while (std::getline(ss, token, delim)) {
        tokens.push_back(token);
    }
    return tokens;
}

inline std::string join(const std::vector<std::string>& list, const std::string& delim) {
    std::ostringstream ss;
    for (size_t i = 0; i < list.size(); ++i) {
        ss << list[i];
        if (i + 1 < list.size()) ss << delim;
    }
    return ss.str();
}

inline std::string replace_all(std::string str, const std::string& from, const std::string& to) {
    size_t start_pos = 0;
    while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length();
    }
    return str;
}

// ============================================================================
// 7. Window FrameLimiter: Precise FPS targeting for dynamic windows & loops
// ============================================================================
class FrameLimiter {
public:
    explicit FrameLimiter(int target_fps = 60)
        : target_fps_(target_fps),
          frame_duration_us_(target_fps > 0 ? (1000000 / target_fps) : 0),
          last_frame_time_(std::chrono::high_resolution_clock::now()) {}

    void set_target_fps(int fps) {
        target_fps_ = fps;
        frame_duration_us_ = (fps > 0 ? (1000000 / fps) : 0);
    }

    void wait_next_frame() {
        if (frame_duration_us_ <= 0) return;
        auto now = std::chrono::high_resolution_clock::now();
        auto elapsed_us = std::chrono::duration_cast<std::chrono::microseconds>(now - last_frame_time_).count();

        if (elapsed_us < frame_duration_us_) {
            auto sleep_us = frame_duration_us_ - elapsed_us;
            std::this_thread::sleep_for(std::chrono::microseconds(sleep_us));
        }
        last_frame_time_ = std::chrono::high_resolution_clock::now();
    }

    double current_fps() const {
        auto now = std::chrono::high_resolution_clock::now();
        auto elapsed_us = std::chrono::duration_cast<std::chrono::microseconds>(now - last_frame_time_).count();
        if (elapsed_us <= 0) return 0.0;
        return 1000000.0 / static_cast<double>(elapsed_us);
    }

private:
    int target_fps_;
    int64_t frame_duration_us_;
    std::chrono::time_point<std::chrono::high_resolution_clock> last_frame_time_;
};

} // namespace snippets
} // namespace looping
