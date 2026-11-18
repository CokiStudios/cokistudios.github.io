#include "LoopingMacWindow.hpp"

#if defined(__APPLE__) && (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && !defined(LOOPING_NO_SUBPROCESS)

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace looping {
namespace mac_native {

namespace {

inline uint32_t parse_hex_bgra(const std::string& hex, uint8_t alpha = 255) {
    std::string s = hex;
    if (!s.empty() && s[0] == '#') s.erase(0, 1);
    if (s.size() == 3) {
        std::string exp;
        for (char c : s) { exp.push_back(c); exp.push_back(c); }
        s = exp;
    }
    if (s.size() < 6) return (static_cast<uint32_t>(alpha) << 24) | 0x0038BDF8u;
    unsigned int r = 56, g = 189, b = 248;
    std::sscanf(s.substr(0, 2).c_str(), "%x", &r);
    std::sscanf(s.substr(2, 2).c_str(), "%x", &g);
    std::sscanf(s.substr(4, 2).c_str(), "%x", &b);
    return (static_cast<uint32_t>(alpha) << 24) |
           ((r & 0xFFu) << 16) |
           ((g & 0xFFu) << 8) |
           (b & 0xFFu);
}

inline NSColor* nscolor_from_hex(const std::string& hex, CGFloat alpha = 1.0) {
    uint32_t bgra = parse_hex_bgra(hex, 255);
    CGFloat r = ((bgra >> 16) & 0xFF) / 255.0;
    CGFloat g = ((bgra >> 8) & 0xFF) / 255.0;
    CGFloat b = (bgra & 0xFF) / 255.0;
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:alpha];
}

inline uint32_t shade_bgra(uint32_t bgra, double lit) {
    lit = std::max(0.15, std::min(1.0, lit));
    uint32_t a = (bgra >> 24) & 0xFFu;
    uint32_t r = static_cast<uint32_t>(((bgra >> 16) & 0xFFu) * lit);
    uint32_t g = static_cast<uint32_t>(((bgra >> 8) & 0xFFu) * lit);
    uint32_t b = static_cast<uint32_t>((bgra & 0xFFu) * lit);
    return (a << 24) | (std::min(255u, r) << 16) | (std::min(255u, g) << 8) | std::min(255u, b);
}

inline void draw_line_bgra(uint32_t* fb, int w, int h, int x0, int y0, int x1, int y1, uint32_t bgra) {
    int dx = std::abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -std::abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    for (int steps = 0; steps < 4096; ++steps) {
        if (x0 >= 0 && x0 < w && y0 >= 0 && y0 < h) {
            fb[y0 * w + x0] = bgra;
        }
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
    }
}

inline void fill_triangle_bgra(uint32_t* fb, int w, int h,
                               double x0, double y0, double x1, double y1, double x2, double y2,
                               uint32_t bgra) {
    int min_x = std::max(0, static_cast<int>(std::floor(std::min({x0, x1, x2}))));
    int max_x = std::min(w - 1, static_cast<int>(std::ceil(std::max({x0, x1, x2}))));
    int min_y = std::max(0, static_cast<int>(std::floor(std::min({y0, y1, y2}))));
    int max_y = std::min(h - 1, static_cast<int>(std::ceil(std::max({y0, y1, y2}))));
    if (min_x > max_x || min_y > max_y) return;

    double area = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0);
    if (std::abs(area) < 1e-6) return;
    double inv_area = 1.0 / area;

    for (int py = min_y; py <= max_y; ++py) {
        double cy = py + 0.5;
        for (int px = min_x; px <= max_x; ++px) {
            double cx = px + 0.5;
            double w0 = ((x1 - cx) * (y2 - cy) - (y1 - cy) * (x2 - cx)) * inv_area;
            double w1 = ((x2 - cx) * (y0 - cy) - (y2 - cy) * (x0 - cx)) * inv_area;
            double w2 = 1.0 - w0 - w1;
            if (w0 >= -1e-4 && w1 >= -1e-4 && w2 >= -1e-4) {
                fb[py * w + px] = bgra;
            }
        }
    }
}

struct StageBullet {
    double x = 0, y = 0, vx = 0, vy = 0, ttl = 1.6;
    uint32_t color = 0xFF00F5D4u;
};

struct StageSimState {
    DirectXWindowSpec spec;
    std::vector<uint32_t> fb;
    int fb_w = 560;
    int fb_h = 340;

    bool key_left = false;
    bool key_right = false;
    bool key_up = false;
    bool key_down = false;
    bool key_jump = false;
    bool key_shoot = false;

    double cam_yaw = 0.25;
    double cam_pitch = 0.28;
    double time_sec = 0.0;
    int score = 0;
    int frame_count = 0;
    uint64_t last_frame_hash = 0;

    std::vector<StageBullet> bullets;
    std::unordered_map<std::string, double> slider_values;
    std::unordered_map<std::string, bool> toggle_values;
    std::unordered_map<std::string, std::string> input_values;
    std::vector<std::string> logs;

    void init(const DirectXWindowSpec& s, int w_px, int h_px) {
        spec = s;
        fb_w = std::max(160, w_px);
        fb_h = std::max(120, h_px);
        fb.assign(static_cast<size_t>(fb_w) * static_cast<size_t>(fb_h), 0xFF070B14u);
        for (const auto& sl : spec.sliders) {
            if (!sl.binding.empty()) slider_values[sl.binding] = sl.current_val;
        }
        for (const auto& tg : spec.toggles) {
            if (!tg.binding.empty()) toggle_values[tg.binding] = tg.is_checked;
        }
        for (const auto& inp : spec.inputs) {
            if (!inp.binding.empty()) input_values[inp.binding] = inp.value;
        }
        logs.push_back("[ASM+Cocoa] Zero-Python Mac Native Window initialized (" +
                       std::to_string(fb_w) + "x" + std::to_string(fb_h) + ")");
    }

    void step(double dt) {
        dt = std::max(0.001, std::min(0.05, dt));
        time_sec += dt;
        frame_count++;

        // 1. ASM fast clear
        uint32_t bg = parse_hex_bgra(spec.bg_color, 255);
        lp_asm_clear_bgra32(fb.data(), fb.size(), bg);

        bool has_3d = spec.is_3d_mode || !spec.entities_3d.empty();
        if (has_3d) {
            step_and_render_3d(dt);
        } else {
            step_and_render_2d(dt);
        }

        last_frame_hash = lp_asm_fnv1a64(reinterpret_cast<const uint8_t*>(fb.data()),
                                          fb.size() * sizeof(uint32_t));
    }

    void step_and_render_2d(double dt) {
        // Subtle cyber grid
        uint32_t grid_c = shade_bgra(parse_hex_bgra(spec.card_border, 255), 0.7);
        for (int gx = 0; gx < fb_w; gx += 40) {
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, gx, 0, 1, fb_h, grid_c);
        }
        for (int gy = 0; gy < fb_h; gy += 40) {
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, 0, gy, fb_w, 1, grid_c);
        }

        double world_w = std::max(400.0, spec.world_width);
        double world_h = std::max(240.0, spec.world_height);
        double sx = static_cast<double>(fb_w) / world_w;
        double sy = static_cast<double>(fb_h) / world_h;

        // Update 2D entities
        DxEntity2DSpec* player = nullptr;
        for (auto& e : spec.entities_2d) {
            if (e.is_player || e.type == "player") {
                player = &e;
                break;
            }
        }

        if (player) {
            double move = 0.0;
            if (key_left) move -= 1.0;
            if (key_right) move += 1.0;
            double spd = player->speed > 0 ? player->speed : 220.0;
            player->vx = lp_asm_lerp_f32(static_cast<float>(player->vx), static_cast<float>(move * spd), 0.35f);
            player->vy += spec.gravity * dt;
            player->x += player->vx * dt;
            player->y += player->vy * dt;

            if (player->x < 0) player->x = 0;
            if (player->x + player->w > world_w) player->x = world_w - player->w;

            // Ground / platform collisions
            bool grounded = false;
            double floor_y = world_h - player->h - 12.0;
            if (player->y >= floor_y) {
                player->y = floor_y;
                player->vy = 0;
                grounded = true;
            }
            for (const auto& p : spec.entities_2d) {
                if (p.type == "platform" || p.type == "moving_platform") {
                    if (player->vy >= 0 &&
                        player->x + player->w > p.x && player->x < p.x + p.w &&
                        player->y + player->h >= p.y && player->y + player->h <= p.y + p.h + 18.0) {
                        player->y = p.y - player->h;
                        player->vy = 0;
                        grounded = true;
                    }
                }
            }
            if (grounded) {
                player->is_jumping = false;
                player->can_double_jump = true;
            }
            if ((key_jump || key_up) && (grounded || player->can_double_jump)) {
                double jf = player->jump_force > 0 ? player->jump_force : 440.0;
                player->vy = -jf;
                if (!grounded) player->can_double_jump = false;
                player->is_jumping = true;
                key_jump = false;
            }
            if (player->shoot_cd > 0) player->shoot_cd -= dt;
            if (key_shoot && player->shoot_cd <= 0) {
                bullets.push_back({player->x + player->w * 0.5, player->y + player->h * 0.4,
                                   (player->vx >= -1.0 ? 520.0 : -520.0), 0.0, 1.5,
                                   parse_hex_bgra(spec.accent_color, 255)});
                player->shoot_cd = 0.22;
            }
        }

        // Patrol moving entities & collect coins
        for (auto& e : spec.entities_2d) {
            if (!e.alive || e.collected) continue;
            if (e.type == "moving_platform" || e.type == "enemy" || e.type == "boss") {
                double lo = e.min_pos;
                double hi = e.max_pos;
                if (hi > lo) {
                    e.x += e.dir * (e.speed > 0 ? e.speed : 80.0) * dt;
                    if (e.x < lo) { e.x = lo; e.dir = 1.0; }
                    if (e.x > hi) { e.x = hi; e.dir = -1.0; }
                }
            }
            if (player && (e.type == "coin" || e.type == "ring")) {
                double dx = (player->x + player->w * 0.5) - e.x;
                double dy = (player->y + player->h * 0.5) - e.y;
                if (dx * dx + dy * dy < 900.0) {
                    e.collected = true;
                    score += static_cast<int>(e.points > 0 ? e.points : 100);
                }
            }
        }

        // Update bullets
        for (auto& b : bullets) {
            b.x += b.vx * dt;
            b.y += b.vy * dt;
            b.ttl -= dt;
            int bx = static_cast<int>(b.x * sx);
            int by = static_cast<int>(b.y * sy);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, bx - 4, by - 2, 8, 4, b.color);
        }
        bullets.erase(std::remove_if(bullets.begin(), bullets.end(),
                                     [](const StageBullet& b) { return b.ttl <= 0; }),
                      bullets.end());

        // Draw entities via ASM rect fill
        for (const auto& e : spec.entities_2d) {
            if (!e.alive || e.collected) continue;
            int ex = static_cast<int>(e.x * sx);
            int ey = static_cast<int>(e.y * sy);
            int ew = std::max(8, static_cast<int>(e.w * sx));
            int eh = std::max(8, static_cast<int>(e.h * sy));
            uint32_t col = parse_hex_bgra(e.color, 255);
            if (e.type == "coin") {
                int r = std::max(5, static_cast<int>(e.radius * sx));
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex - r, ey - r, r * 2, r * 2, 0xFFFACC15u);
            } else {
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, ew, eh, col);
                if (e.is_player || e.type == "player") {
                    lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + 3, ey + 3, std::max(4, ew - 6), 5, 0xFFFFFFFFu);
                }
            }
        }
    }

    void step_and_render_3d(double dt) {
        if (key_left) cam_yaw -= 1.4 * dt;
        if (key_right) cam_yaw += 1.4 * dt;
        if (key_up) cam_pitch = std::min(1.1, cam_pitch + 1.0 * dt);
        if (key_down) cam_pitch = std::max(-0.2, cam_pitch - 1.0 * dt);

        double cy = std::cos(cam_yaw), sy = std::sin(cam_yaw);
        double cp = std::cos(cam_pitch), sp = std::sin(cam_pitch);
        double cam_dist = 18.0;
        double cx = -sy * cp * cam_dist;
        double cy_pos = 4.5 + sp * cam_dist;
        double cz = -cy * cp * cam_dist;
        double tx = 0.0, ty = 1.5, tz = 6.0;

        double fx = tx - cx, fy = ty - cy_pos, fz = tz - cz;
        double fl = std::hypot(fx, std::hypot(fy, fz));
        if (fl < 1e-6) fl = 1.0;
        fx /= fl; fy /= fl; fz /= fl;

        double rx = fz, ry = 0.0, rz = -fx;
        double rl = std::hypot(rx, rz);
        if (rl < 1e-6) rl = 1.0;
        rx /= rl; rz /= rl;

        double ux = ry * fz - rz * fy;
        double uy = rz * fx - rx * fz;
        double uz = rx * fy - ry * fx;

        double fov_scale = (fb_h * 0.5) / std::tan(60.0 * 0.5 * 3.14159265 / 180.0);

        auto project = [&](double wx, double wy, double wz, double& ox, double& oy, double& oz) -> bool {
            double vx = wx - cx, vy = wy - cy_pos, vz = wz - cz;
            double cam_z = vx * fx + vy * fy + vz * fz;
            if (cam_z <= 0.4) return false;
            double cam_x = vx * rx + vy * ry + vz * rz;
            double cam_y = vx * ux + vy * uy + vz * uz;
            ox = fb_w * 0.5 + (cam_x / cam_z) * fov_scale;
            oy = fb_h * 0.5 - (cam_y / cam_z) * fov_scale;
            oz = cam_z;
            return true;
        };

        // Ground cyber grid
        uint32_t grid_col = shade_bgra(parse_hex_bgra(spec.primary_color, 255), 0.42);
        for (int g = -24; g <= 24; g += 4) {
            double x0, y0, z0, x1, y1, z1;
            if (project(g, 0, -10, x0, y0, z0) && project(g, 0, 42, x1, y1, z1)) {
                draw_line_bgra(fb.data(), fb_w, fb_h, static_cast<int>(x0), static_cast<int>(y0),
                               static_cast<int>(x1), static_cast<int>(y1), grid_col);
            }
            if (project(-24, 0, g + 16, x0, y0, z0) && project(24, 0, g + 16, x1, y1, z1)) {
                draw_line_bgra(fb.data(), fb_w, fb_h, static_cast<int>(x0), static_cast<int>(y0),
                               static_cast<int>(x1), static_cast<int>(y1), grid_col);
            }
        }

        struct Tri3D {
            double z;
            double x0, y0, x1, y1, x2, y2;
            uint32_t col;
        };
        std::vector<Tri3D> tris;

        static const std::array<std::array<double, 3>, 8> kCubeVerts = {{
            {{-0.5, -0.5, -0.5}}, {{0.5, -0.5, -0.5}}, {{0.5, 0.5, -0.5}}, {{-0.5, 0.5, -0.5}},
            {{-0.5, -0.5,  0.5}}, {{0.5, -0.5,  0.5}}, {{0.5, 0.5,  0.5}}, {{-0.5, 0.5,  0.5}}
        }};
        static const int kCubeTris[12][3] = {
            {0,1,2},{0,2,3}, {4,6,5},{4,7,6},
            {0,4,5},{0,5,1}, {3,2,6},{3,6,7},
            {1,5,6},{1,6,2}, {0,3,7},{0,7,4}
        };

        for (auto& e : spec.entities_3d) {
            if (!e.alive || e.collected) continue;
            if (e.type == "crystal" || e.type == "ring") {
                e.rot_y += 65.0 * dt;
            } else if (e.type == "enemy" && e.max_pos > e.min_pos) {
                e.x += e.dir * e.speed * dt;
                if (e.x < e.min_pos) { e.x = e.min_pos; e.dir = 1.0; }
                if (e.x > e.max_pos) { e.x = e.max_pos; e.dir = -1.0; }
            }

            uint32_t base_col = parse_hex_bgra(e.color, 255);
            double ang = (e.rot_y * 3.14159265 / 180.0);
            double ca = std::cos(ang), sa = std::sin(ang);

            if (!e.verts.empty() && !e.faces.empty()) {
                std::vector<std::array<double, 3>> wv(e.verts.size());
                std::vector<std::array<double, 3>> pv(e.verts.size());
                std::vector<bool> ok(e.verts.size(), false);
                for (size_t i = 0; i < e.verts.size(); ++i) {
                    double lx = e.verts[i][0] * e.scx;
                    double ly = e.verts[i][1] * e.scy;
                    double lz = e.verts[i][2] * e.scz;
                    wv[i] = {e.x + lx * ca + lz * sa, e.y + ly, e.z - lx * sa + lz * ca};
                    ok[i] = project(wv[i][0], wv[i][1], wv[i][2], pv[i][0], pv[i][1], pv[i][2]);
                }
                for (const auto& f : e.faces) {
                    if (f.size() < 3) continue;
                    int i0 = f[0], i1 = f[1], i2 = f[2];
                    if (i0 < 0 || i1 < 0 || i2 < 0 ||
                        static_cast<size_t>(i0) >= ok.size() ||
                        static_cast<size_t>(i1) >= ok.size() ||
                        static_cast<size_t>(i2) >= ok.size()) continue;
                    if (!ok[i0] || !ok[i1] || !ok[i2]) continue;
                    double dz = (pv[i0][2] + pv[i1][2] + pv[i2][2]) / 3.0;
                    tris.push_back({dz, pv[i0][0], pv[i0][1], pv[i1][0], pv[i1][1], pv[i2][0], pv[i2][1], shade_bgra(base_col, 0.85)});
                }
            } else {
                double sx_v = (e.sx > 0 ? e.sx : e.radius * 1.6) * e.scx;
                double sy_v = (e.sy > 0 ? e.sy : e.radius * 1.6) * e.scy;
                double sz_v = (e.sz > 0 ? e.sz : e.radius * 1.6) * e.scz;
                std::array<std::array<double, 3>, 8> wv{}, pv{};
                std::array<bool, 8> ok{};
                for (int i = 0; i < 8; ++i) {
                    double lx = kCubeVerts[i][0] * sx_v;
                    double ly = kCubeVerts[i][1] * sy_v;
                    double lz = kCubeVerts[i][2] * sz_v;
                    wv[i] = {e.x + lx * ca + lz * sa, e.y + ly, e.z - lx * sa + lz * ca};
                    ok[i] = project(wv[i][0], wv[i][1], wv[i][2], pv[i][0], pv[i][1], pv[i][2]);
                }
                for (int t = 0; t < 12; ++t) {
                    int i0 = kCubeTris[t][0], i1 = kCubeTris[t][1], i2 = kCubeTris[t][2];
                    if (!ok[i0] || !ok[i1] || !ok[i2]) continue;
                    double ax = wv[i1][0] - wv[i0][0], ay = wv[i1][1] - wv[i0][1], az = wv[i1][2] - wv[i0][2];
                    double bx = wv[i2][0] - wv[i0][0], by = wv[i2][1] - wv[i0][1], bz = wv[i2][2] - wv[i0][2];
                    double nx = ay * bz - az * by, ny = az * bx - ax * bz, nz = ax * by - ay * bx;
                    double nl = std::hypot(nx, std::hypot(ny, nz));
                    if (nl > 1e-6) { nx /= nl; ny /= nl; nz /= nl; }
                    double lit = 0.40 + std::max(0.0, nx * 0.35 + ny * 0.80 - nz * 0.45) * 0.60;
                    double dz = (pv[i0][2] + pv[i1][2] + pv[i2][2]) / 3.0;
                    tris.push_back({dz, pv[i0][0], pv[i0][1], pv[i1][0], pv[i1][1], pv[i2][0], pv[i2][1], shade_bgra(base_col, lit)});
                }
            }
        }

        std::sort(tris.begin(), tris.end(), [](const Tri3D& a, const Tri3D& b) { return a.z > b.z; });
        for (const auto& t : tris) {
            fill_triangle_bgra(fb.data(), fb_w, fb_h, t.x0, t.y0, t.x1, t.y1, t.x2, t.y2, t.col);
        }
    }
};

void play_pcm_tone_macos(double freq_hz, double duration_ms) {
    if (freq_hz <= 20.0 || duration_ms <= 5.0) return;
    const uint32_t sampleRate = 22050;
    const uint32_t numSamples = static_cast<uint32_t>((sampleRate * std::min(1500.0, duration_ms)) / 1000.0);
    const uint32_t dataSize = numSamples * sizeof(int16_t);
    const uint32_t riffSize = 36 + dataSize;

    std::vector<uint8_t> wav(44 + dataSize, 0);
    std::memcpy(&wav[0], "RIFF", 4);
    std::memcpy(&wav[4], &riffSize, 4);
    std::memcpy(&wav[8], "WAVEfmt ", 8);
    uint32_t fmtSize = 16;
    uint16_t audioFmt = 1, channels = 1, blockAlign = 2, bits = 16;
    uint32_t byteRate = sampleRate * 2;
    std::memcpy(&wav[16], &fmtSize, 4);
    std::memcpy(&wav[20], &audioFmt, 2);
    std::memcpy(&wav[22], &channels, 2);
    std::memcpy(&wav[24], &sampleRate, 4);
    std::memcpy(&wav[28], &byteRate, 4);
    std::memcpy(&wav[32], &blockAlign, 2);
    std::memcpy(&wav[34], &bits, 2);
    std::memcpy(&wav[36], "data", 4);
    std::memcpy(&wav[40], &dataSize, 4);

    int16_t* pcm = reinterpret_cast<int16_t*>(&wav[44]);
    for (uint32_t i = 0; i < numSamples; ++i) {
        double env = 1.0 - (static_cast<double>(i) / std::max<uint32_t>(1, numSamples));
        double sample = std::sin(2.0 * 3.141592653589793 * freq_hz * (static_cast<double>(i) / sampleRate));
        pcm[i] = static_cast<int16_t>(sample * env * 9000.0);
    }

    NSData* data = [NSData dataWithBytes:wav.data() length:wav.size()];
    NSSound* snd = [[NSSound alloc] initWithData:data];
    if (snd) {
        [snd play];
    }
}

} // namespace
} // namespace mac_native
} // namespace looping

@interface LoopingMacCanvasView : NSView
@property (nonatomic, assign) looping::mac_native::StageSimState* sim;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) NSPoint lastDrag;
@end

@implementation LoopingMacCanvasView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (!_sim || _sim->fb.empty()) return;

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    CGDataProviderRef provider = CGDataProviderCreateWithData(
        nullptr,
        _sim->fb.data(),
        _sim->fb.size() * sizeof(uint32_t),
        nullptr
    );
    CGImageRef img = CGImageCreate(
        static_cast<size_t>(_sim->fb_w),
        static_cast<size_t>(_sim->fb_h),
        8, 32,
        static_cast<size_t>(_sim->fb_w) * 4,
        cs,
        kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst,
        provider,
        nullptr,
        false,
        kCGRenderingIntentDefault
    );
    if (img) {
        CGContextDrawImage(ctx, self.bounds, img);
        CGImageRelease(img);
    }
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(cs);
}

- (void)keyDown:(NSEvent*)event {
    if (!_sim) return;
    unsigned short kc = [event keyCode];
    NSString* chars = [[event charactersIgnoringModifiers] lowercaseString];
    if (kc == 123 || [chars isEqualToString:@"a"]) _sim->key_left = true;
    if (kc == 124 || [chars isEqualToString:@"d"]) _sim->key_right = true;
    if (kc == 126 || [chars isEqualToString:@"w"]) { _sim->key_up = true; _sim->key_jump = true; }
    if (kc == 125 || [chars isEqualToString:@"s"]) _sim->key_down = true;
    if (kc == 49 || [chars isEqualToString:@" "]) _sim->key_jump = true;
    if ([chars isEqualToString:@"f"] || [chars isEqualToString:@"j"]) _sim->key_shoot = true;
}

- (void)keyUp:(NSEvent*)event {
    if (!_sim) return;
    unsigned short kc = [event keyCode];
    NSString* chars = [[event charactersIgnoringModifiers] lowercaseString];
    if (kc == 123 || [chars isEqualToString:@"a"]) _sim->key_left = false;
    if (kc == 124 || [chars isEqualToString:@"d"]) _sim->key_right = false;
    if (kc == 126 || [chars isEqualToString:@"w"]) _sim->key_up = false;
    if (kc == 125 || [chars isEqualToString:@"s"]) _sim->key_down = false;
    if ([chars isEqualToString:@"f"] || [chars isEqualToString:@"j"]) _sim->key_shoot = false;
}

- (void)mouseDown:(NSEvent*)event {
    [[self window] makeFirstResponder:self];
    _dragging = YES;
    _lastDrag = [event locationInWindow];
}

- (void)mouseDragged:(NSEvent*)event {
    if (!_sim || !_dragging) return;
    NSPoint cur = [event locationInWindow];
    _sim->cam_yaw += (cur.x - _lastDrag.x) * 0.01;
    _sim->cam_pitch = std::max(-0.2, std::min(1.1, _sim->cam_pitch + (cur.y - _lastDrag.y) * 0.01));
    _lastDrag = cur;
}

- (void)mouseUp:(NSEvent*)event {
    (void)event;
    _dragging = NO;
}

@end

@interface LoopingMacWindowController : NSObject <NSWindowDelegate>
@property (nonatomic, strong) NSWindow* window;
@property (nonatomic, strong) LoopingMacCanvasView* canvasView;
@property (nonatomic, strong) NSTextView* logTextView;
@property (nonatomic, strong) NSTimer* renderTimer;
@property (nonatomic, assign) looping::mac_native::StageSimState* sim;
@property (nonatomic, assign) int maxFrames;
@property (nonatomic, assign) NSTimeInterval lastTick;
@property (nonatomic, strong) NSMutableArray<NSString*>* buttonActions;
@property (nonatomic, strong) NSMutableArray<NSString*>* buttonSnippets;
@end

@implementation LoopingMacWindowController

- (void)appendLog:(NSString*)msg {
    if (!_sim) return;
    _sim->logs.push_back([msg UTF8String] ? [msg UTF8String] : "");
    if (_logTextView) {
        NSString* cur = [_logTextView string] ?: @"";
        NSString* next = cur.length > 0 ? [NSString stringWithFormat:@"%@\n%@", cur, msg] : msg;
        [_logTextView setString:next];
        [_logTextView scrollRangeToVisible:NSMakeRange(next.length, 0)];
    }
}

- (void)onTick:(NSTimer*)timer {
    (void)timer;
    if (!_sim) return;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    double dt = (_lastTick > 0) ? (now - _lastTick) : (1.0 / 60.0);
    _lastTick = now;
    _sim->step(dt);
    [_canvasView setNeedsDisplay:YES];
    if (_maxFrames > 0 && _sim->frame_count >= _maxFrames) {
        [_renderTimer invalidate];
        _renderTimer = nil;
        [NSApp terminate:nil];
    }
}

- (void)onDynamicButtonClicked:(NSButton*)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= static_cast<NSInteger>(_buttonActions.count)) return;
    NSString* act = _buttonActions[idx];
    NSString* snip = _buttonSnippets[idx];
    [self appendLog:[NSString stringWithFormat:@"[Button] '%@' (action=%@)", sender.title, act]];
    looping::mac_native::play_pcm_tone_macos(587.33, 75.0);

    if (snip.length > 0 && _sim && !_sim->spec.host_exe.empty()) {
        NSString* hostExe = [NSString stringWithUTF8String:_sim->spec.host_exe.c_str()];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSTask* task = [[NSTask alloc] init];
            [task setExecutableURL:[NSURL fileURLWithPath:hostExe]];
            [task setArguments:@[@"-e", snip]];
            NSPipe* pipe = [NSPipe pipe];
            [task setStandardOutput:pipe];
            [task setStandardError:pipe];
            NSError* err = nil;
            if ([task launchAndReturnError:&err]) {
                [task waitUntilExit];
                NSData* outData = [[pipe fileHandleForReading] readDataToEndOfFile];
                NSString* outStr = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
                NSString* trimmed = [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (trimmed.length > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self appendLog:[NSString stringWithFormat:@"[Exec] %@", trimmed]];
                    });
                }
            }
        });
    }
}

- (void)onSliderChanged:(NSSlider*)sender {
    if (!_sim) return;
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < static_cast<NSInteger>(_sim->spec.sliders.size())) {
        auto& sl = _sim->spec.sliders[static_cast<size_t>(idx)];
        sl.current_val = [sender doubleValue];
        if (!sl.binding.empty()) _sim->slider_values[sl.binding] = sl.current_val;
        [self appendLog:[NSString stringWithFormat:@"[Slider] %s = %.2f", sl.label.c_str(), sl.current_val]];
    }
}

- (void)onToggleChanged:(NSButton*)sender {
    if (!_sim) return;
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < static_cast<NSInteger>(_sim->spec.toggles.size())) {
        auto& tg = _sim->spec.toggles[static_cast<size_t>(idx)];
        tg.is_checked = ([sender state] == NSControlStateValueOn);
        if (!tg.binding.empty()) _sim->toggle_values[tg.binding] = tg.is_checked;
        [self appendLog:[NSString stringWithFormat:@"[Toggle] %s = %s", tg.label.c_str(), tg.is_checked ? "true" : "false"]];
    }
}

- (void)windowWillClose:(NSNotification*)notification {
    (void)notification;
    [_renderTimer invalidate];
    _renderTimer = nil;
    [NSApp terminate:nil];
}

@end

namespace looping {
namespace mac_native {

int run_mac_native_window(const DirectXWindowSpec& spec, int max_frames, bool show_window) {
    StageSimState sim;
    int canvas_w = std::max(320, static_cast<int>(spec.width) - 340);
    int canvas_h = std::max(240, static_cast<int>(spec.height) - 140);
    sim.init(spec, canvas_w, canvas_h);

    if (!show_window) {
        int frames = max_frames > 0 ? max_frames : 3;
        for (int i = 0; i < frames; ++i) {
            sim.step(1.0 / 60.0);
        }
        return (sim.frame_count == frames && sim.last_frame_hash != 0) ? 0 : 1;
    }

    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        CGFloat winW = std::max(720.0, spec.width);
        CGFloat winH = std::max(480.0, spec.height);
        NSRect frame = NSMakeRect(0, 0, winW, winH);
        NSWindowStyleMask style = NSWindowStyleMaskTitled |
                                  NSWindowStyleMaskClosable |
                                  NSWindowStyleMaskMiniaturizable |
                                  NSWindowStyleMaskResizable;

        NSWindow* win = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:style
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        NSString* titleStr = [NSString stringWithUTF8String:spec.title.c_str()] ?: @"Looping Native Window";
        [win setTitle:titleStr];
        [win center];

        NSView* root = [win contentView];
        [root setWantsLayer:YES];
        root.layer.backgroundColor = nscolor_from_hex(spec.bg_color, 1.0).CGColor;

        LoopingMacWindowController* ctrl = [[LoopingMacWindowController alloc] init];
        ctrl.window = win;
        ctrl.sim = &sim;
        ctrl.maxFrames = max_frames;
        ctrl.buttonActions = [NSMutableArray array];
        ctrl.buttonSnippets = [NSMutableArray array];
        [win setDelegate:ctrl];

        // Header bar
        CGFloat headerH = 44.0;
        NSView* header = [[NSView alloc] initWithFrame:NSMakeRect(0, winH - headerH, winW, headerH)];
        header.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [header setWantsLayer:YES];
        header.layer.backgroundColor = nscolor_from_hex(spec.card_bg, 0.95).CGColor;
        [root addSubview:header];

        NSTextField* titleLbl = [NSTextField labelWithString:titleStr];
        titleLbl.frame = NSMakeRect(16, 10, winW * 0.55, 24);
        titleLbl.font = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
        titleLbl.textColor = [NSColor whiteColor];
        [header addSubview:titleLbl];

        NSString* badgeStr = [NSString stringWithUTF8String:
            (spec.badge_label.empty() ? "AppKit + ASM • Zero Python" : spec.badge_label).c_str()];
        NSTextField* badgeLbl = [NSTextField labelWithString:badgeStr];
        badgeLbl.frame = NSMakeRect(winW - 310, 12, 294, 20);
        badgeLbl.alignment = NSTextAlignmentRight;
        badgeLbl.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightSemibold];
        badgeLbl.textColor = nscolor_from_hex(spec.accent_color, 1.0);
        badgeLbl.autoresizingMask = NSViewMinXMargin;
        [header addSubview:badgeLbl];

        // Left Stage Canvas (for 2D/3D entities or telemetry)
        CGFloat sidebarW = 310.0;
        CGFloat logH = 92.0;
        CGFloat bodyH = winH - headerH - logH - 24.0;
        CGFloat stageW = std::max(260.0, winW - sidebarW - 36.0);

        LoopingMacCanvasView* canvas = [[LoopingMacCanvasView alloc]
            initWithFrame:NSMakeRect(14, logH + 14, stageW, bodyH)];
        canvas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        canvas.sim = &sim;
        [canvas setWantsLayer:YES];
        canvas.layer.cornerRadius = 10.0;
        canvas.layer.borderWidth = 1.0;
        canvas.layer.borderColor = nscolor_from_hex(spec.card_border, 1.0).CGColor;
        [root addSubview:canvas];
        ctrl.canvasView = canvas;

        // Right Controls & Cards Sidebar
        NSView* sidebar = [[NSView alloc] initWithFrame:NSMakeRect(stageW + 24, logH + 14, sidebarW, bodyH)];
        sidebar.autoresizingMask = NSViewMinXMargin | NSViewHeightSizable;
        [root addSubview:sidebar];

        CGFloat curY = bodyH - 8.0;
        for (const auto& card : spec.cards) {
            CGFloat ch = 64.0;
            curY -= (ch + 8.0);
            if (curY < 0) break;
            NSView* box = [[NSView alloc] initWithFrame:NSMakeRect(0, curY, sidebarW, ch)];
            [box setWantsLayer:YES];
            box.layer.backgroundColor = nscolor_from_hex(spec.card_bg, 0.92).CGColor;
            box.layer.cornerRadius = 8.0;
            box.layer.borderWidth = 1.0;
            box.layer.borderColor = nscolor_from_hex(spec.card_border, 1.0).CGColor;

            NSString* cTitle = [NSString stringWithUTF8String:card.title.c_str()] ?: @"Card";
            NSTextField* cLbl = [NSTextField labelWithString:cTitle];
            cLbl.frame = NSMakeRect(10, ch - 24, sidebarW - 20, 18);
            cLbl.font = [NSFont systemFontOfSize:12 weight:NSFontWeightBold];
            cLbl.textColor = nscolor_from_hex(spec.primary_color, 1.0);
            [box addSubview:cLbl];

            NSString* cText = [NSString stringWithUTF8String:card.text.c_str()] ?: @"";
            NSTextField* cBody = [NSTextField wrappingLabelWithString:cText];
            cBody.frame = NSMakeRect(10, 6, sidebarW - 20, ch - 30);
            cBody.font = [NSFont systemFontOfSize:11];
            cBody.textColor = [NSColor colorWithWhite:0.86 alpha:1.0];
            [box addSubview:cBody];
            [sidebar addSubview:box];
        }

        for (const auto& inp : spec.inputs) {
            curY -= 32.0;
            if (curY < 0) break;
            NSTextField* tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, curY, sidebarW, 26)];
            tf.placeholderString = [NSString stringWithUTF8String:inp.placeholder.c_str()] ?: @"";
            tf.stringValue = [NSString stringWithUTF8String:inp.value.c_str()] ?: @"";
            [sidebar addSubview:tf];
        }

        for (size_t i = 0; i < spec.sliders.size(); ++i) {
            const auto& sl = spec.sliders[i];
            curY -= 40.0;
            if (curY < 0) break;
            NSTextField* lbl = [NSTextField labelWithString:
                [NSString stringWithUTF8String:sl.label.c_str()] ?: @"Slider"];
            lbl.frame = NSMakeRect(0, curY + 20, sidebarW, 16);
            lbl.font = [NSFont systemFontOfSize:11];
            lbl.textColor = [NSColor colorWithWhite:0.82 alpha:1.0];
            [sidebar addSubview:lbl];

            NSSlider* slider = [NSSlider sliderWithValue:sl.current_val
                                                minValue:sl.min_val
                                                maxValue:sl.max_val
                                                  target:ctrl
                                                  action:@selector(onSliderChanged:)];
            slider.frame = NSMakeRect(0, curY, sidebarW, 20);
            slider.tag = static_cast<NSInteger>(i);
            [sidebar addSubview:slider];
        }

        for (size_t i = 0; i < spec.toggles.size(); ++i) {
            const auto& tg = spec.toggles[i];
            curY -= 26.0;
            if (curY < 0) break;
            NSString* tTitle = [NSString stringWithUTF8String:tg.label.c_str()] ?: @"Toggle";
            NSButton* chk = [NSButton checkboxWithTitle:tTitle target:ctrl action:@selector(onToggleChanged:)];
            chk.frame = NSMakeRect(0, curY, sidebarW, 22);
            chk.state = tg.is_checked ? NSControlStateValueOn : NSControlStateValueOff;
            chk.tag = static_cast<NSInteger>(i);
            [sidebar addSubview:chk];
        }

        for (const auto& pr : spec.progress_bars) {
            curY -= 32.0;
            if (curY < 0) break;
            NSTextField* lbl = [NSTextField labelWithString:
                [NSString stringWithUTF8String:pr.label.c_str()] ?: @"Progress"];
            lbl.frame = NSMakeRect(0, curY + 14, sidebarW, 16);
            lbl.font = [NSFont systemFontOfSize:11];
            lbl.textColor = [NSColor colorWithWhite:0.82 alpha:1.0];
            [sidebar addSubview:lbl];

            NSProgressIndicator* bar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, curY, sidebarW, 12)];
            bar.indeterminate = NO;
            bar.minValue = 0.0;
            bar.maxValue = 1.0;
            bar.doubleValue = std::max(0.0, std::min(1.0, pr.progress));
            [sidebar addSubview:bar];
        }

        for (size_t i = 0; i < spec.buttons.size(); ++i) {
            const auto& btn = spec.buttons[i];
            curY -= 34.0;
            if (curY < 0) break;
            NSString* bTitle = [NSString stringWithUTF8String:btn.text.c_str()] ?: @"Action";
            NSButton* nsBtn = [NSButton buttonWithTitle:bTitle target:ctrl action:@selector(onDynamicButtonClicked:)];
            nsBtn.frame = NSMakeRect(0, curY, sidebarW, 28);
            nsBtn.bezelStyle = NSBezelStyleRounded;
            nsBtn.tag = static_cast<NSInteger>(i);
            [ctrl.buttonActions addObject:[NSString stringWithUTF8String:btn.action.c_str()] ?: @""];
            [ctrl.buttonSnippets addObject:[NSString stringWithUTF8String:btn.snippet.c_str()] ?: @""];
            [sidebar addSubview:nsBtn];
        }

        // Bottom Telemetry Log Drawer
        NSScrollView* logScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(14, 10, winW - 28, logH - 6)];
        logScroll.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
        logScroll.hasVerticalScroller = YES;
        NSTextView* logTV = [[NSTextView alloc] initWithFrame:logScroll.bounds];
        logTV.editable = NO;
        logTV.backgroundColor = nscolor_from_hex(spec.log_bg, 1.0);
        logTV.textColor = nscolor_from_hex(spec.log_fg, 1.0);
        logTV.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
        logScroll.documentView = logTV;
        [root addSubview:logScroll];
        ctrl.logTextView = logTV;

        for (const auto& l : sim.logs) {
            [ctrl appendLog:[NSString stringWithUTF8String:l.c_str()] ?: @""];
        }
        for (const auto& tn : spec.tones) {
            play_pcm_tone_macos(tn.freq_hz, tn.duration_ms);
        }

        double interval = 1.0 / std::max(30, std::min(120, spec.target_fps));
        ctrl.renderTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                            target:ctrl
                                                          selector:@selector(onTick:)
                                                          userInfo:nil
                                                           repeats:YES];
        [win makeKeyAndOrderFront:nil];
        [win makeFirstResponder:canvas];
        [NSApp activateIgnoringOtherApps:YES];
        static LoopingMacWindowController* s_active_ctrl = nil;
        s_active_ctrl = ctrl;
        (void)s_active_ctrl;
        [NSApp run];
    }
    return 0;
}

} // namespace mac_native
} // namespace looping

#endif
