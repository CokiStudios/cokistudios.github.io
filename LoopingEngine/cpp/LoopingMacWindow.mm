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
    double radius = 5.0;
    double damage = 25.0;
    bool from_player = true;
    uint32_t color = 0xFF00F5D4u;
};

struct StageSimParticle {
    double x = 0, y = 0, vx = 0, vy = 0, life = 0.4, max_life = 0.4;
    uint32_t color = 0xFF38BDF8u;
};

struct StageSimState {
    DirectXWindowSpec spec;
    DirectXWindowSpec initial_spec;
    std::vector<uint32_t> fb;
    int fb_w = 560;
    int fb_h = 340;

    bool key_left = false;
    bool key_right = false;
    bool key_up = false;
    bool key_down = false;
    bool key_jump = false;
    bool key_shoot = false;
    bool key_dash = false;
    bool prev_jump = false;
    bool prev_dash = false;

    double cam_x = 0.0;
    double cam_yaw = 0.25;
    double cam_pitch = 0.28;
    double time_sec = 0.0;
    int score = 0;
    int lives = 3;
    int max_lives = 3;
    int active_preset_idx = 0;
    bool game_over = false;
    bool game_won = false;
    int frame_count = 0;
    uint64_t last_frame_hash = 0;

    std::vector<StageBullet> bullets;
    std::vector<StageSimParticle> particles;
    std::unordered_map<std::string, double> slider_values;
    std::unordered_map<std::string, bool> toggle_values;
    std::unordered_map<std::string, std::string> input_values;
    std::unordered_map<std::string, std::string> script_vars;
    std::vector<std::string> logs;

    void init(const DirectXWindowSpec& s, int w_px, int h_px) {
        initial_spec = s;
        spec = s;
        fb_w = std::max(160, w_px);
        fb_h = std::max(120, h_px);
        fb.assign(static_cast<size_t>(fb_w) * static_cast<size_t>(fb_h), 0xFF070B14u);
        reset_stage();
        logs.push_back("[ASM+Cocoa] Zero-Python Mac Native Window initialized (" +
                       std::to_string(fb_w) + "x" + std::to_string(fb_h) + ")");
    }

    void reset_stage() {
        spec = initial_spec;
        bullets.clear();
        particles.clear();
        cam_x = 0.0;
        score = 0;
        lives = std::max(1, spec.lives);
        max_lives = lives;
        active_preset_idx = 0;
        game_over = false;
        game_won = false;
        script_vars.clear();
        for (const auto& kv : spec.init_vars) {
            script_vars[kv.first] = kv.second;
        }
        slider_values.clear();
        for (const auto& sl : spec.sliders) {
            if (!sl.binding.empty()) slider_values[sl.binding] = sl.current_val;
        }
        toggle_values.clear();
        for (const auto& tg : spec.toggles) {
            if (!tg.binding.empty()) toggle_values[tg.binding] = tg.is_checked;
        }
        input_values.clear();
        for (const auto& inp : spec.inputs) {
            if (!inp.binding.empty()) input_values[inp.binding] = inp.value;
        }
    }

    std::string resolve_template(const std::string& raw) const {
        if (raw.find('{') == std::string::npos) return raw;
        std::string out;
        out.reserve(raw.size() + 16);
        size_t i = 0;
        while (i < raw.size()) {
            if (raw[i] == '{') {
                size_t close = raw.find('}', i);
                if (close != std::string::npos) {
                    std::string key = raw.substr(i + 1, close - i - 1);
                    auto sit = slider_values.find(key);
                    if (sit != slider_values.end()) {
                        char buf[48];
                        std::snprintf(buf, sizeof(buf), "%.2f", sit->second);
                        std::string num_s = buf;
                        while (num_s.find('.') != std::string::npos && (num_s.back() == '0' || num_s.back() == '.')) {
                            char ch = num_s.back();
                            num_s.pop_back();
                            if (ch == '.') break;
                        }
                        out += num_s;
                        i = close + 1;
                        continue;
                    }
                    auto tit = toggle_values.find(key);
                    if (tit != toggle_values.end()) {
                        out += (tit->second ? "true" : "false");
                        i = close + 1;
                        continue;
                    }
                    auto vit = script_vars.find(key);
                    if (vit != script_vars.end()) {
                        out += vit->second;
                        i = close + 1;
                        continue;
                    }
                }
            }
            out += raw[i++];
        }
        return out;
    }

    bool activate_preset(int idx) {
        if (idx < 0 || idx >= static_cast<int>(spec.stage_presets.size())) return false;
        active_preset_idx = idx;
        const auto& pr = spec.stage_presets[static_cast<size_t>(idx)];
        for (auto& e : spec.entities_2d) {
            if (e.is_player || e.type == "player") {
                e.x = pr.x;
                e.y = pr.y;
                e.vx = 0.0;
                e.vy = -120.0;
                e.spawn_x = pr.x;
                e.spawn_y = pr.y;
                e.overdrive = pr.overdrive;
                break;
            }
        }
        if (pr.gravity > 0) spec.gravity = pr.gravity;
        if (pr.friction > 0) spec.friction = pr.friction;
        if (!pr.bg.empty()) spec.bg_color = pr.bg;
        if (!pr.color.empty()) spec.scenario_accent = pr.color;
        spec.scenario_name = pr.label;
        logs.push_back("[Stage Preset] " + pr.label);
        return true;
    }

    void spawn_burst(double x, double y, uint32_t col, int count = 12) {
        for (int i = 0; i < count; ++i) {
            if (particles.size() >= 180) particles.erase(particles.begin());
            double ang = (static_cast<double>(i) / std::max(1, count)) * 6.2831853 + time_sec;
            double spd = 60.0 + ((i * 37) % 120);
            particles.push_back({x, y, std::cos(ang) * spd, std::sin(ang) * spd - 30.0, 0.35, 0.35, col});
        }
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
        double world_w = std::max(400.0, spec.world_width);
        double world_h = std::max(240.0, spec.world_height);
        double sy = static_cast<double>(fb_h) / world_h;
        double view_w = std::max(200.0, static_cast<double>(fb_w) / std::max(0.1, sy));
        double sx = (world_w <= view_w) ? (static_cast<double>(fb_w) / world_w) : sy;

        // Subtle scrolling cyber grid
        uint32_t grid_c = shade_bgra(parse_hex_bgra(spec.card_border, 255), 0.7);
        int gx_off = static_cast<int>(std::fmod(cam_x * sx, 40.0));
        for (int gx = -gx_off; gx < fb_w; gx += 40) {
            if (gx >= 0) lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, gx, 0, 1, fb_h, grid_c);
        }
        for (int gy = 0; gy < fb_h; gy += 40) {
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, 0, gy, fb_w, 1, grid_c);
        }

        DxEntity2DSpec* player = nullptr;
        for (auto& e : spec.entities_2d) {
            if (e.is_player || e.type == "player") {
                player = &e;
                break;
            }
        }

        // 1. Update dynamic platforms, lasers, saws, turrets, enemies, boss
        for (auto& e : spec.entities_2d) {
            if (!e.alive) continue;
            if (e.pulse > 0.0) e.pulse = std::max(0.0, e.pulse - dt * 3.0);
            if (e.type == "moving_platform") {
                double spd = e.speed > 0 ? e.speed : 80.0;
                if (e.axis == "y") {
                    e.y += e.dir * spd * dt;
                    e.vx = 0; e.vy = e.dir * spd;
                    if (e.max_pos > e.min_pos) {
                        if (e.y >= e.max_pos) { e.y = e.max_pos; e.dir = -1.0; }
                        if (e.y <= e.min_pos) { e.y = e.min_pos; e.dir = 1.0; }
                    }
                } else {
                    e.x += e.dir * spd * dt;
                    e.vx = e.dir * spd; e.vy = 0;
                    if (e.max_pos > e.min_pos) {
                        if (e.x >= e.max_pos) { e.x = e.max_pos; e.dir = -1.0; }
                        if (e.x <= e.min_pos) { e.x = e.min_pos; e.dir = 1.0; }
                    }
                }
            } else if (e.type == "laser_hazard") {
                e.timer += dt;
                if (e.timer >= std::max(0.2, e.interval)) {
                    e.timer = 0.0;
                    e.active = !e.active;
                }
            } else if (e.type == "saw") {
                double spd = e.speed > 0 ? e.speed : 120.0;
                if (e.max_pos > e.min_pos) {
                    if (e.axis == "y") {
                        e.y += e.dir * spd * dt;
                        if (e.y >= e.max_pos) { e.y = e.max_pos; e.dir = -1.0; }
                        if (e.y <= e.min_pos) { e.y = e.min_pos; e.dir = 1.0; }
                    } else {
                        e.x += e.dir * spd * dt;
                        if (e.x >= e.max_pos) { e.x = e.max_pos; e.dir = -1.0; }
                        if (e.x <= e.min_pos) { e.x = e.min_pos; e.dir = 1.0; }
                    }
                }
            } else if (e.type == "turret" && player && !game_over) {
                e.fire_timer += dt;
                double dist = std::hypot(player->x - e.x, player->y - e.y);
                double rng = e.max_pos > 0 ? e.max_pos : 480.0;
                if (dist < rng && e.fire_timer >= std::max(0.4, e.fire_rate)) {
                    e.fire_timer = 0.0;
                    double dx = (player->x + player->w * 0.5) - (e.x + e.w * 0.5);
                    double dy = (player->y + player->h * 0.5) - (e.y + e.h * 0.5);
                    double len = std::max(1.0, std::hypot(dx, dy));
                    bullets.push_back({e.x + e.w * 0.5, e.y + e.h * 0.5, (dx / len) * 300.0, (dy / len) * 300.0,
                                       2.5, 5.5, 22.0, false, 0xFFF43F5Eu});
                }
            } else if (e.type == "enemy" || e.type == "boss") {
                double lo = e.min_pos;
                double hi = e.max_pos;
                if (hi > lo) {
                    e.x += e.dir * (e.speed > 0 ? e.speed : 80.0) * dt;
                    if (e.x < lo) { e.x = lo; e.dir = 1.0; }
                    if (e.x > hi) { e.x = hi; e.dir = -1.0; }
                }
                if (e.type == "boss" && player && !game_over) {
                    e.fire_timer += dt;
                    if (e.fire_timer >= std::max(0.5, e.fire_rate)) {
                        e.fire_timer = 0.0;
                        double pdir = (player->x < e.x) ? -1.0 : 1.0;
                        bullets.push_back({e.x + e.w * 0.5, e.y + e.h * 0.4, pdir * 310.0, -25.0,
                                           2.5, 6.5, 25.0, false, 0xFFEF4444u});
                    }
                }
            }
        }

        // 2. Player physics, zones & collisions
        if (player && !game_over) {
            if (player->coyote_timer > 0) player->coyote_timer -= dt;
            if (player->jump_buf_timer > 0) player->jump_buf_timer -= dt;
            if (player->invuln_timer > 0) player->invuln_timer -= dt;
            if (player->dash_cd > 0) player->dash_cd -= dt;
            if (player->teleport_cd > 0) player->teleport_cd -= dt;
            if (player->shield_timer > 0) player->shield_timer -= dt;
            if (player->shoot_cd > 0) player->shoot_cd -= dt;

            bool wants_dash = key_dash && !prev_dash;
            double spd = player->speed > 0 ? player->speed : 240.0;
            if (wants_dash && player->dash_cd <= 0 && player->dash_timer <= 0) {
                player->dash_timer = 0.16;
                player->dash_cd = 0.65;
                player->vx = player->facing * spd * 2.4;
                player->vy = 0.0;
                spawn_burst(player->x + player->w * 0.5, player->y + player->h * 0.5, 0xFF00F5D4u, 10);
            }

            if (key_shoot && player->shoot_cd <= 0) {
                double px = player->x + (player->facing > 0 ? player->w : 0.0);
                double py = player->y + player->h * 0.45;
                bullets.push_back({px, py, player->facing * 600.0, 0.0, 1.6,
                                   player->overdrive ? 7.0 : 5.0, player->overdrive ? 40.0 : 25.0, true,
                                   parse_hex_bgra(player->overdrive ? "#f59e0b" : spec.accent_color, 255)});
                player->shoot_cd = player->overdrive ? 0.14 : 0.22;
            }

            if (player->dash_timer > 0) {
                player->dash_timer -= dt;
            } else {
                double move = 0.0;
                if (key_left) { move -= 1.0; player->facing = -1; }
                if (key_right) { move += 1.0; player->facing = 1; }
                if (move != 0.0) {
                    player->vx = lp_asm_lerp_f32(static_cast<float>(player->vx), static_cast<float>(move * spd), 0.4f);
                } else {
                    player->vx *= std::clamp(spec.friction, 0.5, 0.98);
                }

                bool jump_now = (key_jump || key_up);
                if (jump_now && !prev_jump) player->jump_buf_timer = 0.12;
                prev_jump = jump_now;

                if (player->jump_buf_timer > 0) {
                    double jf = player->jump_force > 0 ? player->jump_force : 440.0;
                    if (player->coyote_timer > 0 && !player->is_jumping) {
                        player->vy = -jf;
                        player->is_jumping = true;
                        player->coyote_timer = 0.0;
                        player->jump_buf_timer = 0.0;
                        player->can_double_jump = true;
                        spawn_burst(player->x + player->w * 0.5, player->y + player->h, 0xFF38BDF8u, 8);
                    } else if (player->can_double_jump && player->is_jumping) {
                        player->vy = -jf * 0.92;
                        player->can_double_jump = false;
                        player->jump_buf_timer = 0.0;
                        spawn_burst(player->x + player->w * 0.5, player->y + player->h, 0xFFC084FCu, 10);
                    }
                }

                double g_scale = 1.0, wx = 0.0, wy = 0.0;
                for (const auto& gz : spec.entities_2d) {
                    if (gz.type == "gravity_zone" &&
                        player->x + player->w > gz.x && player->x < gz.x + gz.w &&
                        player->y + player->h > gz.y && player->y < gz.y + gz.h) {
                        g_scale = gz.scale;
                        wx = gz.wind_x;
                        wy = gz.wind_y;
                    }
                }
                player->vx += wx * dt;
                player->vy += (spec.gravity * g_scale + wy) * dt;
            }
            prev_dash = key_dash;

            player->x += player->vx * dt;
            player->y += player->vy * dt;
            if (player->x < 0) player->x = 0;
            if (player->x + player->w > world_w) player->x = world_w - player->w;

            double floor_y = world_h - player->h - 12.0;
            if (player->y >= floor_y) {
                player->y = floor_y;
                player->vy = 0;
                player->is_jumping = false;
                player->coyote_timer = 0.12;
                player->can_double_jump = true;
            }

            auto apply_dmg = [&](double dmg) {
                if (player->invuln_timer > 0 || player->shield_timer > 0) return;
                player->health -= dmg;
                player->invuln_timer = 1.0;
                player->vy = -260.0;
                spawn_burst(player->x + player->w * 0.5, player->y + player->h * 0.5, 0xFFEF4444u, 14);
                if (player->health <= 0) {
                    lives--;
                    if (lives > 0) {
                        player->health = player->max_health;
                        player->x = player->spawn_x;
                        player->y = player->spawn_y;
                        player->vx = 0; player->vy = 0;
                    } else {
                        player->health = 0;
                        game_over = true;
                        logs.push_back("[Game Over] Press R to restart.");
                    }
                }
            };

            const DxEntity2DSpec* riding = nullptr;
            for (auto& other : spec.entities_2d) {
                if (other.is_player) continue;
                if (other.type == "platform" || other.type == "moving_platform") {
                    if (player->vy >= 0 &&
                        player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h >= other.y && player->y + player->h <= other.y + other.h + 18.0) {
                        player->y = other.y - player->h;
                        player->vy = 0;
                        player->is_jumping = false;
                        player->coyote_timer = 0.12;
                        player->can_double_jump = true;
                        if (other.type == "moving_platform") riding = &other;
                    }
                } else if (other.type == "breakable" && !other.broken) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        if (player->dash_timer > 0 || player->overdrive) {
                            other.broken = true;
                            other.alive = false;
                            score += static_cast<int>(other.points > 0 ? other.points : 100);
                            spawn_burst(other.x + other.w * 0.5, other.y + other.h * 0.5, parse_hex_bgra(other.color, 255), 18);
                        } else if (player->vy >= 0 && (player->y + player->h) <= other.y + 16.0) {
                            player->y = other.y - player->h;
                            player->vy = 0;
                            player->is_jumping = false;
                            player->coyote_timer = 0.12;
                        } else {
                            if (player->x + player->w * 0.5 < other.x + other.w * 0.5) player->x = other.x - player->w;
                            else player->x = other.x + other.w;
                            player->vx = 0;
                        }
                    }
                } else if (other.type == "checkpoint" && !other.activated) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        other.activated = true;
                        other.pulse = 1.0;
                        player->spawn_x = other.x;
                        player->spawn_y = other.y - 10.0;
                        player->health = std::min(player->max_health, player->health + 25.0);
                        spawn_burst(other.x + 14.0, other.y + 20.0, 0xFF4ADE80u, 16);
                        logs.push_back("[Checkpoint] " + (other.label.empty() ? "SAVED" : other.label));
                    }
                } else if (other.type == "teleporter" && player->teleport_cd <= 0) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        spawn_burst(player->x + player->w * 0.5, player->y + player->h * 0.5, parse_hex_bgra(other.color, 255), 14);
                        player->x = other.to_x;
                        player->y = other.to_y;
                        player->vy = -120.0;
                        player->teleport_cd = 1.1;
                        spawn_burst(player->x + player->w * 0.5, player->y + player->h * 0.5, parse_hex_bgra(other.color, 255), 16);
                    }
                } else if (other.type == "orb") {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 26.0 && (key_jump || key_up)) {
                        player->vy = -std::abs(other.power > 0 ? other.power : 480.0);
                        player->is_jumping = true;
                        player->can_double_jump = true;
                        other.pulse = 1.0;
                        spawn_burst(other.x, other.y, 0xFFFACC15u, 14);
                    }
                } else if (other.type == "jump_pad") {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h >= other.y && player->y + player->h <= other.y + other.h + 12.0 && player->vy >= 0) {
                        player->vy = -std::abs(other.power > 0 ? other.power : 650.0);
                        player->is_jumping = true;
                        player->can_double_jump = true;
                        other.pulse = 1.0;
                    }
                } else if ((other.type == "coin" || other.type == "ring") && !other.collected) {
                    double dx = (player->x + player->w * 0.5) - other.x;
                    double dy = (player->y + player->h * 0.5) - other.y;
                    if (dx * dx + dy * dy < 900.0) {
                        other.collected = true;
                        score += static_cast<int>(other.points > 0 ? other.points : 100);
                        spawn_burst(other.x, other.y, 0xFFFACC15u, 10);
                    }
                } else if (other.type == "heart" && !other.collected) {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 20.0) {
                        other.collected = true;
                        player->health = std::min(player->max_health, player->health + other.health);
                        spawn_burst(other.x, other.y, 0xFF10B981u, 12);
                    }
                } else if (other.type == "powerup" && !other.collected) {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < 30.0) {
                        other.collected = true;
                        if (other.state == "shield") player->shield_timer = 8.0;
                        else player->overdrive = true;
                        spawn_burst(other.x, other.y, parse_hex_bgra(other.color, 255), 14);
                    }
                } else if (other.type == "spike") {
                    if (player->x + player->w > other.x + 4 && player->x < other.x + other.w - 4 &&
                        player->y + player->h >= other.y + 6 && player->y <= other.y + other.h) {
                        apply_dmg(other.damage);
                    }
                } else if (other.type == "laser_hazard" && other.active) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h && player->dash_timer <= 0) {
                        apply_dmg(other.damage);
                    }
                } else if (other.type == "saw") {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 16.0) apply_dmg(other.damage);
                } else if ((other.type == "enemy" || other.type == "boss") && other.alive) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        if (player->vy > 0 && (player->y + player->h) <= other.y + 22.0) {
                            other.health -= (other.type == "boss" ? 90.0 : 100.0);
                            player->vy = -340.0;
                            player->can_double_jump = true;
                            if (other.health <= 0) {
                                other.alive = false;
                                int pts = (other.type == "boss") ? 1000 : 250;
                                score += pts;
                                spawn_burst(other.x + other.w * 0.5, other.y + other.h * 0.5, parse_hex_bgra(other.color, 255), 20);
                            }
                        } else {
                            apply_dmg(other.type == "boss" ? 35.0 : 25.0);
                        }
                    }
                } else if (other.type == "portal" && !game_won) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        game_won = true;
                        score += 500;
                        spawn_burst(other.x + other.w * 0.5, other.y + other.h * 0.5, 0xFFA855F7u, 28);
                        logs.push_back("[Victory] Stage cleared! Score: " + std::to_string(score));
                    }
                }
            }
            if (riding) {
                player->x += riding->vx * dt;
                player->y += riding->vy * dt;
            }

            if (world_w > view_w) {
                double target_cam = std::clamp(player->x - view_w * 0.42, 0.0, world_w - view_w);
                cam_x += (target_cam - cam_x) * 0.14;
            } else {
                cam_x = 0.0;
            }
        }

        // 3. Update & collide bullets
        for (auto& b : bullets) {
            b.x += b.vx * dt;
            b.y += b.vy * dt;
            b.ttl -= dt;
            if (b.ttl <= 0) continue;
            if (b.from_player) {
                for (auto& e : spec.entities_2d) {
                    if (!e.alive) continue;
                    if ((e.type == "enemy" || e.type == "boss") &&
                        b.x + b.radius > e.x && b.x - b.radius < e.x + e.w &&
                        b.y + b.radius > e.y && b.y - b.radius < e.y + e.h) {
                        e.health -= b.damage;
                        b.ttl = 0;
                        spawn_burst(b.x, b.y, b.color, 6);
                        if (e.health <= 0) {
                            e.alive = false;
                            score += (e.type == "boss") ? 1000 : 200;
                            spawn_burst(e.x + e.w * 0.5, e.y + e.h * 0.5, parse_hex_bgra(e.color, 255), 18);
                        }
                        break;
                    } else if (e.type == "breakable" && !e.broken &&
                               b.x + b.radius > e.x && b.x - b.radius < e.x + e.w &&
                               b.y + b.radius > e.y && b.y - b.radius < e.y + e.h) {
                        e.health -= b.damage;
                        b.ttl = 0;
                        spawn_burst(b.x, b.y, parse_hex_bgra(e.color, 255), 8);
                        if (e.health <= 0) {
                            e.broken = true;
                            e.alive = false;
                            score += static_cast<int>(e.points > 0 ? e.points : 100);
                            spawn_burst(e.x + e.w * 0.5, e.y + e.h * 0.5, parse_hex_bgra(e.color, 255), 16);
                        }
                        break;
                    } else if ((e.type == "platform" || e.type == "moving_platform") &&
                               b.x + b.radius > e.x && b.x - b.radius < e.x + e.w &&
                               b.y + b.radius > e.y && b.y - b.radius < e.y + e.h) {
                        b.ttl = 0;
                        break;
                    }
                }
            } else if (player && !game_over) {
                if (b.x + b.radius > player->x && b.x - b.radius < player->x + player->w &&
                    b.y + b.radius > player->y && b.y - b.radius < player->y + player->h) {
                    b.ttl = 0;
                    if (player->invuln_timer <= 0 && player->shield_timer <= 0) {
                        player->health -= b.damage;
                        player->invuln_timer = 0.8;
                        if (player->health <= 0) {
                            lives--;
                            if (lives > 0) {
                                player->health = player->max_health;
                                player->x = player->spawn_x;
                                player->y = player->spawn_y;
                            } else {
                                player->health = 0;
                                game_over = true;
                            }
                        }
                    }
                }
            }
        }
        bullets.erase(std::remove_if(bullets.begin(), bullets.end(),
                                     [](const StageBullet& b) { return b.ttl <= 0; }),
                      bullets.end());

        // Update particles
        for (size_t i = 0; i < particles.size();) {
            particles[i].x += particles[i].vx * dt;
            particles[i].y += particles[i].vy * dt;
            particles[i].vy += 240.0 * dt;
            particles[i].life -= dt;
            if (particles[i].life <= 0) particles.erase(particles.begin() + i);
            else ++i;
        }

        // 4. Draw gravity zones first (background outlines)
        for (const auto& e : spec.entities_2d) {
            if (e.type != "gravity_zone") continue;
            int ex = static_cast<int>((e.x - cam_x) * sx);
            int ey = static_cast<int>(e.y * sy);
            int ew = std::max(8, static_cast<int>(e.w * sx));
            int eh = std::max(8, static_cast<int>(e.h * sy));
            if (ex + ew < 0 || ex >= fb_w) continue;
            uint32_t col = parse_hex_bgra(e.color, 255);
            uint32_t dim = shade_bgra(col, 0.25);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, ew, 2, col);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey + eh - 2, ew, 2, col);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, 2, eh, col);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + ew - 2, ey, 2, eh, col);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + 4, ey + 4, std::max(1, ew - 8), 3, dim);
        }

        // 5. Draw entities via ASM rect fill
        for (const auto& e : spec.entities_2d) {
            if (!e.alive || e.collected || e.broken || e.type == "gravity_zone") continue;
            if (e.type == "laser_hazard" && !e.active) continue;
            int ex = static_cast<int>((e.x - cam_x) * sx);
            int ey = static_cast<int>(e.y * sy);
            int ew = std::max(6, static_cast<int>(e.w * sx));
            int eh = std::max(6, static_cast<int>(e.h * sy));
            if (ex + ew < -20 || ex > fb_w + 20) continue;
            uint32_t col = parse_hex_bgra(e.color, 255);
            if (e.type == "coin" || e.type == "orb" || e.type == "heart" || e.type == "saw") {
                int r = std::max(6, static_cast<int>(e.radius * sx));
                uint32_t c = (e.type == "coin") ? 0xFFFACC15u : col;
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex - r, ey - r, r * 2, r * 2, c);
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex - r / 2, ey - r / 2, std::max(2, r), std::max(2, r), 0xFFFFFFFFu);
            } else if (e.type == "checkpoint") {
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, 4, eh, 0xFFE2E8F0u);
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + 4, ey, std::max(12, ew - 4), eh / 2, e.activated ? 0xFF4ADE80u : col);
            } else if (e.type == "teleporter" || e.type == "portal") {
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, ew, eh, shade_bgra(col, 0.55));
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + 4, ey + 4, std::max(4, ew - 8), std::max(4, eh - 8), col);
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex + ew / 3, ey + eh / 4, std::max(4, ew / 3), std::max(4, eh / 2), 0xFFFFFFFFu);
            } else {
                lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey, ew, eh, col);
                if (e.is_player || e.type == "player") {
                    int visor_x = e.facing >= 0 ? (ex + ew / 2) : (ex + 3);
                    lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, visor_x, ey + 5, std::max(4, ew / 2 - 3), 6, 0xFFFFFFFFu);
                    if (e.overdrive) {
                        lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex - 2, ey - 2, ew + 4, 3, 0xFFF59E0Bu);
                    }
                } else if (e.type == "boss" || e.type == "enemy") {
                    double hp_r = std::max(0.0, e.health / std::max(1.0, e.max_health));
                    lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey - 8, ew, 4, 0xFF1E293Bu);
                    lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, ex, ey - 8, static_cast<int>(ew * hp_r), 4, 0xFFEF4444u);
                }
            }
        }

        // 6. Draw bullets & particles
        for (const auto& b : bullets) {
            int bx = static_cast<int>((b.x - cam_x) * sx);
            int by = static_cast<int>(b.y * sy);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, bx - 5, by - 2, 10, 4, b.color);
        }
        for (const auto& pt : particles) {
            int px = static_cast<int>((pt.x - cam_x) * sx);
            int py = static_cast<int>(pt.y * sy);
            lp_asm_fill_rect_bgra32(fb.data(), fb_w, fb_h, px - 2, py - 2, 4, 4, pt.color);
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

@interface LoopingMacFlippedView : NSView
@end
@implementation LoopingMacFlippedView
- (BOOL)isFlipped { return YES; }
@end

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

    // 2D HUD & Entity Labels Overlay (Cocoa Text)
    BOOL has3D = _sim->spec.is_3d_mode || !_sim->spec.entities_3d.empty();
    if (!has3D) {
        double world_w = std::max(400.0, _sim->spec.world_width);
        double world_h = std::max(240.0, _sim->spec.world_height);
        double sy = static_cast<double>(self.bounds.size.height) / world_h;
        double view_w = std::max(200.0, static_cast<double>(self.bounds.size.width) / std::max(0.1, sy));
        double sx = (world_w <= view_w) ? (static_cast<double>(self.bounds.size.width) / world_w) : sy;
        double sy_draw = static_cast<double>(self.bounds.size.height) / world_h;

        NSDictionary* lblAttrs = @{
            NSFontAttributeName: [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.95 alpha:0.92]
        };
        for (const auto& e : _sim->spec.entities_2d) {
            if (!e.alive || e.collected || e.broken) continue;
            if (e.label.empty() && e.name.empty()) continue;
            if (e.type == "platform" || e.type == "moving_platform") continue;
            double wx = (e.x - _sim->cam_x) * sx;
            if (wx < -80 || wx > self.bounds.size.width + 80) continue;
            double wy = self.bounds.size.height - (e.y * sy_draw) + 4.0;
            std::string txt = !e.label.empty() ? e.label : e.name;
            NSString* nsTxt = [NSString stringWithUTF8String:txt.c_str()];
            if (nsTxt) [nsTxt drawAtPoint:NSMakePoint(wx, std::min(self.bounds.size.height - 20.0, wy)) withAttributes:lblAttrs];
        }

        double hp = 100.0;
        for (const auto& e : _sim->spec.entities_2d) {
            if (e.is_player || e.type == "player") { hp = e.health; break; }
        }
        NSString* scName = [NSString stringWithUTF8String:_sim->spec.scenario_name.c_str()] ?: @"Stage 2D";
        NSString* hudStr = [NSString stringWithFormat:@"SCORE: %d   |   HP: %.0f   |   LIVES: %d   |   %@",
                            _sim->score, std::max(0.0, hp), _sim->lives, scName];
        NSDictionary* hudAttrs = @{
            NSFontAttributeName: [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor whiteColor]
        };
        [hudStr drawAtPoint:NSMakePoint(12, self.bounds.size.height - 24) withAttributes:hudAttrs];

        NSDictionary* hintAttrs = @{
            NSFontAttributeName: [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor colorWithWhite:0.78 alpha:0.85]
        };
        [@"A/D Move • W/Space Double Jump • Z/X/F Shoot • K/Shift Dash • [/] Stage • R Reset"
            drawAtPoint:NSMakePoint(12, 8) withAttributes:hintAttrs];

        if (_sim->game_won || _sim->game_over) {
            NSString* banner = _sim->game_won
                ? [NSString stringWithFormat:@"STAGE CLEARED! SCORE: %d (Press R to Restart)", _sim->score]
                : @"GAME OVER (Press R to Restart)";
            NSDictionary* banAttrs = @{
                NSFontAttributeName: [NSFont systemFontOfSize:20 weight:NSFontWeightHeavy],
                NSForegroundColorAttributeName: (_sim->game_won ? [NSColor systemGreenColor] : [NSColor systemRedColor])
            };
            NSSize bsz = [banner sizeWithAttributes:banAttrs];
            [banner drawAtPoint:NSMakePoint((self.bounds.size.width - bsz.width) * 0.5,
                                            (self.bounds.size.height - bsz.height) * 0.5)
                 withAttributes:banAttrs];
        }
    }
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
    if ([chars isEqualToString:@"f"] || [chars isEqualToString:@"j"] ||
        [chars isEqualToString:@"z"] || [chars isEqualToString:@"x"]) _sim->key_shoot = true;
    if ([chars isEqualToString:@"k"] || [chars isEqualToString:@"b"] ||
        ([event modifierFlags] & NSEventModifierFlagShift)) _sim->key_dash = true;
    if ([chars isEqualToString:@"r"]) _sim->reset_stage();
    if ([chars isEqualToString:@"["] && !_sim->spec.stage_presets.empty()) {
        int n = static_cast<int>(_sim->spec.stage_presets.size());
        _sim->activate_preset((_sim->active_preset_idx - 1 + n) % n);
    }
    if ([chars isEqualToString:@"]"] && !_sim->spec.stage_presets.empty()) {
        int n = static_cast<int>(_sim->spec.stage_presets.size());
        _sim->activate_preset((_sim->active_preset_idx + 1) % n);
    }
    if (chars.length == 1) {
        unichar ch = [chars characterAtIndex:0];
        if (ch >= '1' && ch <= '9') {
            int idx = static_cast<int>(ch - '1');
            if (idx < static_cast<int>(_sim->spec.stage_presets.size())) {
                _sim->activate_preset(idx);
            }
        }
    }
}

- (void)keyUp:(NSEvent*)event {
    if (!_sim) return;
    unsigned short kc = [event keyCode];
    NSString* chars = [[event charactersIgnoringModifiers] lowercaseString];
    if (kc == 123 || [chars isEqualToString:@"a"]) _sim->key_left = false;
    if (kc == 124 || [chars isEqualToString:@"d"]) _sim->key_right = false;
    if (kc == 126 || [chars isEqualToString:@"w"]) { _sim->key_up = false; _sim->key_jump = false; }
    if (kc == 125 || [chars isEqualToString:@"s"]) _sim->key_down = false;
    if (kc == 49 || [chars isEqualToString:@" "]) _sim->key_jump = false;
    if ([chars isEqualToString:@"f"] || [chars isEqualToString:@"j"] ||
        [chars isEqualToString:@"z"] || [chars isEqualToString:@"x"]) _sim->key_shoot = false;
    if ([chars isEqualToString:@"k"] || [chars isEqualToString:@"b"] ||
        !([event modifierFlags] & NSEventModifierFlagShift)) _sim->key_dash = false;
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
@property (nonatomic, strong) NSMutableArray<NSTextField*>* cardBodyLabels;
@property (nonatomic, strong) NSMutableArray<NSSlider*>* sliderViews;
@property (nonatomic, strong) NSMutableArray<NSButton*>* toggleViews;
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

- (void)refreshReactiveCards {
    if (!_sim) return;
    for (NSUInteger i = 0; i < _cardBodyLabels.count && i < _sim->spec.cards.size(); ++i) {
        const auto& card = _sim->spec.cards[i];
        std::string raw = card.raw_text.empty() ? card.text : card.raw_text;
        std::string resolved = _sim->resolve_template(raw);
        NSString* nsTxt = [NSString stringWithUTF8String:resolved.c_str()] ?: @"";
        [_cardBodyLabels[i] setStringValue:nsTxt];
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

- (void)onPresetClicked:(NSButton*)sender {
    if (!_sim) return;
    NSInteger idx = sender.tag;
    if (_sim->activate_preset(static_cast<int>(idx))) {
        [self appendLog:[NSString stringWithFormat:@"[Stage] Activated preset #%ld", (long)(idx + 1)]];
        looping::mac_native::play_pcm_tone_macos(660.0, 60.0);
        [_window makeFirstResponder:_canvasView];
    }
}

- (void)onDynamicButtonClicked:(NSButton*)sender {
    NSInteger idx = sender.tag;
    if (idx < 0 || idx >= static_cast<NSInteger>(_buttonActions.count)) return;
    NSString* act = _buttonActions[idx];
    NSString* snip = _buttonSnippets[idx];
    [self appendLog:[NSString stringWithFormat:@"[Button] '%@' (action=%@)", sender.title, act]];
    looping::mac_native::play_pcm_tone_macos(587.33, 75.0);

    if (_sim && ([act isEqualToString:@"restart"] || [act isEqualToString:@"reset"])) {
        _sim->reset_stage();
        for (NSUInteger si = 0; si < _sliderViews.count && si < _sim->spec.sliders.size(); ++si) {
            [_sliderViews[si] setDoubleValue:_sim->spec.sliders[si].current_val];
        }
        for (NSUInteger ti = 0; ti < _toggleViews.count && ti < _sim->spec.toggles.size(); ++ti) {
            [_toggleViews[ti] setState:(_sim->spec.toggles[ti].is_checked ? NSControlStateValueOn : NSControlStateValueOff)];
        }
        [self refreshReactiveCards];
        [self appendLog:@"[Reset] Stage and sandbox controls reset to initial values"];
        [_window makeFirstResponder:_canvasView];
        return;
    }

    if (_sim && ([act hasPrefix:@"lz_step"] || [act isEqualToString:@"step"])) {
        for (int k = 0; k < 15; ++k) _sim->step(1.0 / 60.0);
        [_canvasView setNeedsDisplay:YES];
        [self refreshReactiveCards];
        [self appendLog:[NSString stringWithFormat:@"[Step] Simulation stepped (t=%.2fs, score=%d)", _sim->time_sec, _sim->score]];
        [_window makeFirstResponder:_canvasView];
        return;
    }

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
        [self refreshReactiveCards];
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
        if (tg.binding.find("overdrive") != std::string::npos || tg.label.find("Overdrive") != std::string::npos) {
            for (auto& e : _sim->spec.entities_2d) {
                if (e.is_player || e.type == "player") {
                    e.overdrive = tg.is_checked;
                }
            }
        }
        [self refreshReactiveCards];
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
        ctrl.cardBodyLabels = [NSMutableArray array];
        ctrl.sliderViews = [NSMutableArray array];
        ctrl.toggleViews = [NSMutableArray array];
        [win setDelegate:ctrl];

        // Header bar
        CGFloat headerH = 44.0;
        NSView* header = [[NSView alloc] initWithFrame:NSMakeRect(0, winH - headerH, winW, headerH)];
        header.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [header setWantsLayer:YES];
        header.layer.backgroundColor = nscolor_from_hex(spec.card_bg, 0.95).CGColor;
        [root addSubview:header];

        NSString* hdrStr = [NSString stringWithUTF8String:
            (spec.header_text.empty() ? spec.title : spec.header_text).c_str()] ?: titleStr;
        NSTextField* titleLbl = [NSTextField labelWithString:hdrStr];
        titleLbl.frame = NSMakeRect(16, 10, winW * 0.62, 24);
        titleLbl.font = [NSFont systemFontOfSize:13 weight:NSFontWeightBold];
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
        CGFloat sidebarW = 320.0;
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

        // Right Scrollable Controls, Presets, Cards & Algebra Table Sidebar
        NSScrollView* sideScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(stageW + 24, logH + 14, sidebarW, bodyH)];
        sideScroll.autoresizingMask = NSViewMinXMargin | NSViewHeightSizable;
        sideScroll.hasVerticalScroller = YES;
        sideScroll.drawsBackground = NO;
        [root addSubview:sideScroll];

        LoopingMacFlippedView* sidebar = [[LoopingMacFlippedView alloc] initWithFrame:NSMakeRect(0, 0, sidebarW - 14, bodyH)];
        CGFloat curY = 6.0;
        CGFloat innerW = sidebarW - 18.0;

        for (const auto& lblTxt : spec.labels) {
            NSString* sTxt = [NSString stringWithUTF8String:lblTxt.c_str()] ?: @"";
            NSTextField* lbl = [NSTextField wrappingLabelWithString:sTxt];
            lbl.frame = NSMakeRect(0, curY, innerW, 20);
            lbl.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
            lbl.textColor = nscolor_from_hex(spec.accent_color, 1.0);
            [sidebar addSubview:lbl];
            curY += 22.0;
        }

        if (!spec.stage_presets.empty()) {
            NSTextField* pHdr = [NSTextField labelWithString:@"STAGE PRESETS"];
            pHdr.frame = NSMakeRect(0, curY, innerW, 16);
            pHdr.font = [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightBold];
            pHdr.textColor = [NSColor colorWithWhite:0.75 alpha:1.0];
            [sidebar addSubview:pHdr];
            curY += 18.0;
            for (size_t pi = 0; pi < spec.stage_presets.size(); ++pi) {
                const auto& pr = spec.stage_presets[pi];
                NSString* pTitle = [NSString stringWithUTF8String:pr.label.c_str()] ?: @"Stage";
                NSButton* pBtn = [NSButton buttonWithTitle:pTitle target:ctrl action:@selector(onPresetClicked:)];
                pBtn.frame = NSMakeRect(0, curY, innerW, 24);
                pBtn.bezelStyle = NSBezelStyleRounded;
                pBtn.font = [NSFont systemFontOfSize:11];
                pBtn.tag = static_cast<NSInteger>(pi);
                [sidebar addSubview:pBtn];
                curY += 26.0;
            }
            curY += 4.0;
        }

        for (const auto& card : spec.cards) {
            CGFloat ch = 64.0;
            NSView* box = [[NSView alloc] initWithFrame:NSMakeRect(0, curY, innerW, ch)];
            [box setWantsLayer:YES];
            box.layer.backgroundColor = nscolor_from_hex(spec.card_bg, 0.92).CGColor;
            box.layer.cornerRadius = 8.0;
            box.layer.borderWidth = 1.0;
            box.layer.borderColor = nscolor_from_hex(spec.card_border, 1.0).CGColor;

            NSString* cTitle = [NSString stringWithUTF8String:card.title.c_str()] ?: @"Card";
            NSTextField* cLbl = [NSTextField labelWithString:cTitle];
            cLbl.frame = NSMakeRect(10, 6, innerW - 20, 18);
            cLbl.font = [NSFont systemFontOfSize:12 weight:NSFontWeightBold];
            cLbl.textColor = nscolor_from_hex(spec.primary_color, 1.0);
            [box addSubview:cLbl];

            NSString* cText = [NSString stringWithUTF8String:card.text.c_str()] ?: @"";
            NSTextField* cBody = [NSTextField wrappingLabelWithString:cText];
            cBody.frame = NSMakeRect(10, 26, innerW - 20, ch - 32);
            cBody.font = [NSFont systemFontOfSize:11];
            cBody.textColor = [NSColor colorWithWhite:0.86 alpha:1.0];
            [box addSubview:cBody];
            [ctrl.cardBodyLabels addObject:cBody];
            [sidebar addSubview:box];
            curY += ch + 8.0;
        }

        for (const auto& inp : spec.inputs) {
            NSTextField* tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, curY, innerW, 26)];
            tf.placeholderString = [NSString stringWithUTF8String:inp.placeholder.c_str()] ?: @"";
            tf.stringValue = [NSString stringWithUTF8String:inp.value.c_str()] ?: @"";
            [sidebar addSubview:tf];
            curY += 32.0;
        }

        for (size_t i = 0; i < spec.sliders.size(); ++i) {
            const auto& sl = spec.sliders[i];
            NSTextField* lbl = [NSTextField labelWithString:
                [NSString stringWithUTF8String:sl.label.c_str()] ?: @"Slider"];
            lbl.frame = NSMakeRect(0, curY, innerW, 16);
            lbl.font = [NSFont systemFontOfSize:11];
            lbl.textColor = [NSColor colorWithWhite:0.82 alpha:1.0];
            [sidebar addSubview:lbl];

            NSSlider* slider = [NSSlider sliderWithValue:sl.current_val
                                                minValue:sl.min_val
                                                maxValue:sl.max_val
                                                  target:ctrl
                                                  action:@selector(onSliderChanged:)];
            slider.frame = NSMakeRect(0, curY + 16, innerW, 20);
            slider.tag = static_cast<NSInteger>(i);
            [ctrl.sliderViews addObject:slider];
            [sidebar addSubview:slider];
            curY += 40.0;
        }

        for (size_t i = 0; i < spec.toggles.size(); ++i) {
            const auto& tg = spec.toggles[i];
            NSString* tTitle = [NSString stringWithUTF8String:tg.label.c_str()] ?: @"Toggle";
            NSButton* chk = [NSButton checkboxWithTitle:tTitle target:ctrl action:@selector(onToggleChanged:)];
            chk.frame = NSMakeRect(0, curY, innerW, 22);
            chk.state = tg.is_checked ? NSControlStateValueOn : NSControlStateValueOff;
            chk.tag = static_cast<NSInteger>(i);
            [ctrl.toggleViews addObject:chk];
            [sidebar addSubview:chk];
            curY += 26.0;
        }

        for (const auto& pr : spec.progress_bars) {
            NSTextField* lbl = [NSTextField labelWithString:
                [NSString stringWithUTF8String:pr.label.c_str()] ?: @"Progress"];
            lbl.frame = NSMakeRect(0, curY, innerW, 16);
            lbl.font = [NSFont systemFontOfSize:11];
            lbl.textColor = [NSColor colorWithWhite:0.82 alpha:1.0];
            [sidebar addSubview:lbl];

            NSProgressIndicator* bar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, curY + 16, innerW, 12)];
            bar.indeterminate = NO;
            bar.minValue = 0.0;
            bar.maxValue = 1.0;
            double maxV = pr.max_val > 0.0 ? pr.max_val : 100.0;
            double normProgress = (pr.progress > 1.0 || maxV > 1.0) ? (pr.progress / maxV) : pr.progress;
            bar.doubleValue = std::max(0.0, std::min(1.0, normProgress));
            [sidebar addSubview:bar];
            curY += 32.0;
        }

        for (size_t i = 0; i < spec.buttons.size(); ++i) {
            const auto& btn = spec.buttons[i];
            NSString* bTitle = [NSString stringWithUTF8String:btn.text.c_str()] ?: @"Action";
            NSButton* nsBtn = [NSButton buttonWithTitle:bTitle target:ctrl action:@selector(onDynamicButtonClicked:)];
            nsBtn.frame = NSMakeRect(0, curY, innerW, 28);
            nsBtn.bezelStyle = NSBezelStyleRounded;
            nsBtn.tag = static_cast<NSInteger>(i);
            [ctrl.buttonActions addObject:[NSString stringWithUTF8String:btn.action.c_str()] ?: @""];
            [ctrl.buttonSnippets addObject:[NSString stringWithUTF8String:btn.snippet.c_str()] ?: @""];
            [sidebar addSubview:nsBtn];
            curY += 32.0;
        }

        if (spec.algebra_table.enabled) {
            curY += 4.0;
            NSString* tblHdr = [NSString stringWithUTF8String:spec.algebra_table.title.c_str()] ?: @"Physics Table";
            NSTextField* tLbl = [NSTextField labelWithString:tblHdr];
            tLbl.frame = NSMakeRect(0, curY, innerW, 18);
            tLbl.font = [NSFont systemFontOfSize:11 weight:NSFontWeightBold];
            tLbl.textColor = nscolor_from_hex(spec.primary_color, 1.0);
            [sidebar addSubview:tLbl];
            curY += 20.0;

            for (const auto& r : spec.algebra_table.rows) {
                double em = 0.5 * r.m * r.v * r.v + 9.8 * r.m * r.h;
                bool peak = r.hits >= spec.algebra_table.threshold;
                NSString* rStr = [NSString stringWithFormat:@"%@ | Em=%.0fJ | Hits=%.0f%s",
                                  [NSString stringWithUTF8String:r.label.c_str()] ?: @"",
                                  em, r.hits, peak ? " [MAX]" : ""];
                NSTextField* rLbl = [NSTextField wrappingLabelWithString:rStr];
                rLbl.frame = NSMakeRect(0, curY, innerW, 28);
                rLbl.font = [NSFont monospacedSystemFontOfSize:10 weight:(peak ? NSFontWeightBold : NSFontWeightRegular)];
                rLbl.textColor = peak ? nscolor_from_hex(spec.accent_color, 1.0) : [NSColor colorWithWhite:0.78 alpha:1.0];
                [sidebar addSubview:rLbl];
                curY += 30.0;
            }
        }

        sidebar.frame = NSMakeRect(0, 0, sidebarW - 14, std::max(bodyH, curY + 8.0));
        [sideScroll setDocumentView:sidebar];

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
