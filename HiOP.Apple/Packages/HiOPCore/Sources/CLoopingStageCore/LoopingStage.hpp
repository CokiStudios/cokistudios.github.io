#pragma once

#include "Looping3D.hpp"
#include "LoopingAST.hpp"
#include <algorithm>
#include <cmath>
#include <sstream>
#include <string>
#include <vector>

namespace looping {

// Input bitmask shared between WebAssembly host and C++ Stage runtime
enum StageInputMask : uint32_t {
    STAGE_INP_LEFT   = 1u << 0,
    STAGE_INP_RIGHT  = 1u << 1,
    STAGE_INP_UP     = 1u << 2,
    STAGE_INP_DOWN   = 1u << 3,
    STAGE_INP_JUMP   = 1u << 4,
    STAGE_INP_SHOOT  = 1u << 5,
    STAGE_INP_DASH   = 1u << 6,
    STAGE_INP_SPRINT = 1u << 7
};

struct StageEntity2D {
    std::string type = "platform";
    std::string name = "";
    double x = 0, y = 0, z = 0;
    double w = 32, h = 32;
    double vx = 0, vy = 0;
    double speed = 80;
    double jump_force = 440;
    double power = 650;
    double health = 100;
    double max_health = 100;
    double damage = 35;
    double points = 100;
    double radius = 12;
    double scale = 0.35;
    double wind_x = 0, wind_y = 0;
    double to_x = 0, to_y = 0;
    double min_pos = 0, max_pos = 0;
    double dir = 1.0;
    double fire_rate = 1.8;
    double fire_timer = 0.0;
    double interval = 2.0;
    double timer = 0.0;
    double angle = 0.0;
    double pulse = 0.0;
    double glow_pulse = 0.0;
    std::string axis = "x";
    std::string color = "#38bdf8";
    std::string label = "";
    std::string state = "";

    bool is_player = false;
    bool is_jumping = false;
    bool can_double_jump = true;
    bool double_jump_available = true;
    bool is_dashing = false;
    bool overdrive = false;
    bool collected = false;
    bool broken = false;
    bool activated = false;
    bool active = true;
    bool alive = true;
    bool wireframe = false;
    int facing = 1;
    int rings = 7;

    double spawn_x = 100, spawn_y = 300;
    double coyote_timer = 0.0;
    double jump_buffer_timer = 0.0;
    double invuln_timer = 0.0;
    double dash_timer = 0.0;
    double dash_cooldown = 0.0;
    double teleport_cooldown = 0.0;
    double shield_timer = 0.0;
    double shoot_cooldown = 0.0;
    double squash = 1.0, stretch = 1.0;
};

struct StageParticle {
    double x = 0, y = 0, z = 0;
    double vx = 0, vy = 0, vz = 0;
    double life = 0.5, max_life = 0.5;
    double size = 4.0;
    std::string color = "#38bdf8";
};

struct StageProjectile {
    double x = 0, y = 0, z = 0;
    double vx = 0, vy = 0, vz = 0;
    double radius = 5.0;
    double damage = 25.0;
    double life = 2.0;
    bool from_player = true;
    std::string color = "#38bdf8";
};

struct StagePopup {
    double x = 0, y = 0, z = 0;
    double vy = -48.0;
    double alpha = 1.0;
    std::string text;
    std::string color = "#38bdf8";
};

struct StagePreset2D {
    std::string id;
    std::string label;
    double x = 70, y = 300;
    std::string weather = "stars";
    double gravity = 980;
    std::string color = "#38bdf8";
    bool overdrive = false;
};

struct AlgebraRowSpec {
    std::string label;
    double m = 10.0, v = 8.0, h = 1.2, hits = 0.0;
};

struct AlgebraTableSpec {
    bool enabled = false;
    std::string title = "Modelo Algebraico";
    std::string formula = "0.5*m*v^2 + 9.8*m*h";
    double monster_hits = 760.0;
    std::vector<AlgebraRowSpec> rows;
};

/**
 * Unified C++17 2D & 3D Interactive Game Stage Runtime.
 * Shared by native Interpreter executions and WebAssembly Canvas hosts.
 */
class LoopingStageRuntime {
public:
    // World & Scenario
    double world_width = 1200.0;
    double world_height = 480.0;
    bool has_custom_bounds = false;
    double gravity = 980.0;
    double friction = 0.82;
    double time_scale = 1.0;
    double coyote_time = 0.12;
    double jump_buffer = 0.12;

    std::string scenario_name = "Holo Cyber Stage";
    std::string scenario_weather = "stars";
    std::string scenario_bg = "#06090f";
    std::string scenario_accent = "#38bdf8";

    // Camera 2D
    double cam_x = 0.0, cam_y = 0.0, cam_smooth = 0.12, cam_shake = 0.0;
    bool cam_3d_layer = false;

    // Gameplay Score & Lifecycle
    int score = 0;
    int lives = 3;
    int max_lives = 3;
    int combo = 0;
    double combo_timer = 0.0;
    bool game_over = false;
    bool game_won = false;
    double elapsed_time = 0.0;
    double fps_smooth = 60.0;

    // 3D Gameplay Controller State
    double p3d_vx = 0.0, p3d_vy = 0.0, p3d_vz = 0.0;
    double p3d_spawn_x = 0.0, p3d_spawn_y = 2.5, p3d_spawn_z = 0.0;
    double p3d_coyote = 0.0, p3d_jump_buf = 0.0;
    int p3d_jumps = 0;
    double p3d_invuln = 0.0, p3d_dash_timer = 0.0, p3d_dash_cd = 0.0, p3d_shoot_cd = 0.0;
    double cam3d_yaw_offset = 0.0, cam3d_pitch_offset = 0.24;
    double cam3d_cur_x = 0.0, cam3d_cur_y = 8.5, cam3d_cur_z = -16.0;
    double cam3d_tgt_x = 0.0, cam3d_tgt_y = 2.2, cam3d_tgt_z = 10.0;

    // Entities & FX
    std::vector<StageEntity2D> entities_2d;
    std::vector<StageParticle> particles;
    std::vector<StageProjectile> projectiles;
    std::vector<StagePopup> popups;
    std::vector<StagePreset2D> stage_presets;
    AlgebraTableSpec algebra_table;

    // Event Queues drained by host (WebAudio SFX + UI Log)
    std::vector<std::string> sfx_queue;
    std::vector<std::string> log_queue;

    // Input state
    uint32_t keys_mask = 0;
    uint32_t prev_keys_mask = 0;
    uint32_t rng_state = 0x5A17C0DEu;

    double rand_unit() {
        rng_state ^= rng_state << 13;
        rng_state ^= rng_state >> 17;
        rng_state ^= rng_state << 5;
        return static_cast<double>(rng_state & 0xFFFFFFu) / static_cast<double>(0x1000000u);
    }

    void reset() {
        *this = LoopingStageRuntime{};
    }

    void emit_sfx(const std::string& name) {
        if (sfx_queue.size() < 32) sfx_queue.push_back(name);
    }

    void emit_log(const std::string& msg) {
        if (log_queue.size() < 64) log_queue.push_back(msg);
    }

    void add_popup(double x, double y, const std::string& text, const std::string& color = "#38bdf8", double z = 0.0) {
        if (popups.size() >= 48) popups.erase(popups.begin());
        popups.push_back({x, y, z, -48.0, 1.0, text, color});
    }

    void spawn_particles(double x, double y, const std::string& color, int count = 16, double z = 0.0, bool is_3d = false) {
        for (int i = 0; i < count; ++i) {
            if (particles.size() >= 300) particles.erase(particles.begin());
            StageParticle p;
            p.x = x; p.y = y; p.z = z;
            double ang = rand_unit() * 6.283185307;
            if (is_3d) {
                double spd = 4.0 + rand_unit() * 10.0;
                p.vx = std::cos(ang) * spd;
                p.vy = 2.5 + rand_unit() * 8.0;
                p.vz = std::sin(ang) * spd;
                p.size = 0.25 + rand_unit() * 0.35;
            } else {
                double spd = 50.0 + rand_unit() * 170.0;
                p.vx = std::cos(ang) * spd;
                p.vy = std::sin(ang) * spd - 40.0;
                p.size = 2.5 + rand_unit() * 3.5;
            }
            p.max_life = 0.35 + rand_unit() * 0.35;
            p.life = p.max_life;
            p.color = color.empty() ? "#38bdf8" : color;
            particles.push_back(p);
        }
    }

    StageEntity2D* get_player_2d() {
        for (auto& e : entities_2d) {
            if (e.is_player) return &e;
        }
        return nullptr;
    }

    void ingest_spawn_2d(const SpawnEntityStmt& sp) {
        StageEntity2D e;
        e.type = sp.entity_type;
        e.name = sp.name;
        e.x = sp.x; e.y = sp.y; e.z = sp.z;
        e.w = sp.w > 0 ? sp.w : 32.0;
        e.h = sp.h > 0 ? sp.h : 32.0;
        e.speed = sp.speed;
        e.jump_force = sp.power > 0 ? sp.power : 440.0;
        e.power = sp.power;
        e.health = sp.health;
        e.max_health = std::max(1.0, sp.health);
        e.damage = sp.damage;
        e.points = sp.points > 0 ? sp.points : 100.0;
        e.radius = sp.radius > 0 ? sp.radius : 12.0;
        e.scale = sp.scale;
        e.wind_x = sp.wind_x;
        e.wind_y = sp.wind_y;
        e.to_x = sp.to_x;
        e.to_y = sp.to_y;
        e.min_pos = sp.min_pos;
        e.max_pos = sp.max_pos;
        e.fire_rate = sp.fire_rate;
        e.interval = sp.interval;
        e.axis = sp.axis;
        e.color = sp.color.empty() ? "#38bdf8" : sp.color;
        e.label = sp.text;
        e.state = sp.state;
        e.wireframe = sp.wireframe;
        e.rings = sp.rings;

        if (e.type == "player" || (e.type == "sprite" && !get_player_2d())) {
            e.type = "player";
            e.is_player = true;
            e.w = sp.w > 0 ? sp.w : 32.0;
            e.h = sp.h > 0 ? sp.h : 44.0;
            e.spawn_x = e.x;
            e.spawn_y = e.y;
            e.coyote_timer = coyote_time;
        } else if (e.type == "coin") {
            e.radius = sp.radius > 0 ? sp.radius : 12.0;
            e.color = "#fbbf24";
        } else if (e.type == "heart") {
            e.radius = 14.0;
            e.color = "#10b981";
        } else if (e.type == "enemy" || e.type == "boss") {
            if (e.max_pos <= e.min_pos) {
                e.min_pos = e.x - 120.0;
                e.max_pos = e.x + 120.0;
            }
        }
        entities_2d.push_back(e);

        if (!has_custom_bounds && e.x + e.w + 100.0 > world_width) {
            world_width = e.x + e.w + 100.0;
        }
    }

    void ingest_game_config(const GameConfigStmt& cfg) {
        if (cfg.config_key == "world") {
            world_width = std::max(400.0, cfg.val1);
            world_height = std::max(300.0, cfg.val2);
            has_custom_bounds = true;
        } else if (cfg.config_key == "gravity") {
            gravity = cfg.val1;
        } else if (cfg.config_key == "friction") {
            friction = cfg.val1;
        } else if (cfg.config_key == "lives") {
            lives = std::max(1, static_cast<int>(cfg.val1));
            max_lives = lives;
        } else if (cfg.config_key == "camera") {
            cam_smooth = std::clamp(cfg.val1, 0.02, 1.0);
        } else if (cfg.config_key == "physics") {
            gravity = cfg.val1;
            friction = cfg.val2;
            time_scale = std::clamp(cfg.val3, 0.1, 3.0);
        } else if (cfg.config_key == "time_scale") {
            time_scale = std::clamp(cfg.val1, 0.1, 3.0);
        } else if (cfg.config_key == "scenario" || cfg.config_key == "background") {
            if (!cfg.str_val.empty()) scenario_name = cfg.str_val;
            if (!cfg.str_val2.empty()) scenario_weather = cfg.str_val2;
            if (!cfg.str_val3.empty()) scenario_accent = cfg.str_val3;
        } else if (cfg.config_key == "stage_preset") {
            StagePreset2D pr;
            pr.x = cfg.val1;
            pr.y = cfg.val2;
            pr.color = cfg.str_val.empty() ? "#38bdf8" : cfg.str_val;
            pr.label = cfg.str_val2.empty() ? "Escenario" : cfg.str_val2;
            pr.weather = cfg.str_val3.empty() ? "stars" : cfg.str_val3;
            pr.gravity = cfg.val3 > 0 ? cfg.val3 : 980.0;
            pr.overdrive = cfg.val4 > 0.5;
            pr.id = "preset_" + std::to_string(stage_presets.size() + 1);
            stage_presets.push_back(pr);
        } else if (cfg.config_key == "algebra_table") {
            algebra_table.enabled = true;
            algebra_table.monster_hits = cfg.val1 > 0 ? cfg.val1 : 760.0;
            if (!cfg.str_val.empty()) algebra_table.title = cfg.str_val;
            if (!cfg.str_val2.empty()) algebra_table.formula = cfg.str_val2;
        } else if (cfg.config_key == "algebra_row") {
            algebra_table.enabled = true;
            algebra_table.rows.push_back({cfg.str_val, cfg.val1, cfg.val2, cfg.val3, cfg.val4});
        }
    }

    void heal_player(double amt, loop_math::Scene3D* scene3d = nullptr) {
        if (scene3d && scene3d->active) {
            for (auto& e : scene3d->entities) {
                if (e.type == "player") {
                    e.health = std::min(100.0, e.health + amt);
                    emit_sfx("heal");
                    add_popup(e.pos.x, e.pos.y + 2.0, "+" + std::to_string(static_cast<int>(amt)) + " HP", "#10b981", e.pos.z);
                    spawn_particles(e.pos.x, e.pos.y + 1.0, "#10b981", 16, e.pos.z, true);
                    break;
                }
            }
            return;
        }
        if (auto* p = get_player_2d()) {
            p->health = std::min(p->max_health, p->health + amt);
            emit_sfx("heal");
            add_popup(p->x, p->y - 12.0, "+" + std::to_string(static_cast<int>(amt)) + " HP", "#10b981");
            spawn_particles(p->x + p->w * 0.5, p->y + p->h * 0.5, "#10b981", 16);
        }
    }

    void boost_player(double power, loop_math::Scene3D* scene3d = nullptr) {
        if (scene3d && scene3d->active) {
            p3d_vy = std::max(p3d_vy, std::min(32.0, power * 0.045));
            emit_sfx("pad");
            for (const auto& e : scene3d->entities) {
                if (e.type == "player") {
                    add_popup(e.pos.x, e.pos.y + 2.5, "QUANTUM BOOST!", "#fbbf24", e.pos.z);
                    spawn_particles(e.pos.x, e.pos.y, "#fbbf24", 18, e.pos.z, true);
                    break;
                }
            }
            return;
        }
        if (auto* p = get_player_2d()) {
            p->vy = -std::abs(power);
            p->is_jumping = true;
            emit_sfx("pad");
            add_popup(p->x, p->y - 14.0, "LIVE BOOST!", "#fbbf24");
            spawn_particles(p->x + p->w * 0.5, p->y + p->h, "#fbbf24", 18);
        }
    }

    bool activate_preset(int idx) {
        if (idx < 0 || idx >= static_cast<int>(stage_presets.size())) return false;
        const auto& pr = stage_presets[static_cast<size_t>(idx)];
        if (auto* p = get_player_2d()) {
            p->x = pr.x;
            p->y = pr.y;
            p->vx = 0;
            p->vy = -120;
            p->spawn_x = pr.x;
            p->spawn_y = pr.y;
            p->overdrive = pr.overdrive;
        }
        if (!pr.weather.empty()) scenario_weather = pr.weather;
        if (pr.gravity > 0) gravity = pr.gravity;
        scenario_name = pr.label;
        emit_sfx("pad");
        if (auto* p = get_player_2d()) {
            add_popup(p->x, p->y - 16.0, pr.label, pr.color);
            spawn_particles(p->x + p->w * 0.5, p->y + p->h * 0.5, pr.color, 24);
        }
        return true;
    }

    void trigger_game_over() {
        if (game_over) return;
        game_over = true;
        emit_sfx("gameover");
        cam_shake = 16.0;
        emit_log("[GAME OVER] Mision terminada. Reinicia para volver a intentar.");
    }

    void trigger_victory() {
        if (game_won) return;
        game_won = true;
        score += 500;
        emit_sfx("victory");
        emit_log("[VICTORY] Etapa completada! Puntaje: " + std::to_string(score));
    }

    void step(double raw_dt, loop_math::Scene3D* scene3d = nullptr) {
        if (raw_dt > 0.0005) {
            double inst_fps = std::min(240.0, 1.0 / raw_dt);
            fps_smooth = fps_smooth * 0.92 + inst_fps * 0.08;
        }
        double dt = std::clamp(raw_dt, 0.001, 0.05) * time_scale;
        elapsed_time += dt;

        if (combo_timer > 0.0) {
            combo_timer -= dt;
            if (combo_timer <= 0.0) combo = 0;
        }
        if (cam_shake > 0.0) {
            cam_shake = std::max(0.0, cam_shake - dt * 28.0);
        }

        // Update particles & popups (shared 2D/3D)
        for (size_t i = 0; i < particles.size();) {
            particles[i].x += particles[i].vx * dt;
            particles[i].y += particles[i].vy * dt;
            particles[i].z += particles[i].vz * dt;
            if (scene3d && scene3d->active) particles[i].vy -= 12.0 * dt;
            else particles[i].vy += 260.0 * dt;
            particles[i].life -= dt;
            if (particles[i].life <= 0.0) particles.erase(particles.begin() + i);
            else ++i;
        }
        for (size_t i = 0; i < popups.size();) {
            popups[i].y += (scene3d && scene3d->active ? 1.8 : popups[i].vy) * dt;
            popups[i].alpha -= dt * 0.95;
            if (popups[i].alpha <= 0.0) popups.erase(popups.begin() + i);
            else ++i;
        }

        if (scene3d && scene3d->active) {
            step_3d(*scene3d, dt);
        } else {
            step_2d(dt);
        }
        prev_keys_mask = keys_mask;
    }

    std::vector<loop_math::Entity3D> build_3d_overlay_entities() const {
        std::vector<loop_math::Entity3D> out;
        for (const auto& pr : projectiles) {
            loop_math::Entity3D e;
            e.type = "projectile";
            e.pos = {pr.x, pr.y, pr.z};
            e.radius = 0.35;
            e.color = pr.color;
            out.push_back(e);
        }
        for (const auto& pt : particles) {
            loop_math::Entity3D e;
            e.type = "particle";
            e.pos = {pt.x, pt.y, pt.z};
            e.radius = std::max(0.12, pt.size * (pt.life / std::max(0.01, pt.max_life)));
            e.color = pt.color;
            out.push_back(e);
        }
        return out;
    }

    static std::string escape_json(const std::string& s) {
        std::string out;
        out.reserve(s.size() + 8);
        for (unsigned char c : s) {
            if (c == '"') out += "\\\"";
            else if (c == '\\') out += "\\\\";
            else if (c == '\n') out += "\\n";
            else if (c == '\r') out += "\\r";
            else if (c == '\t') out += "\\t";
            else if (c < 0x20) continue;
            else out.push_back(static_cast<char>(c));
        }
        return out;
    }

    std::string build_snapshot_json(const loop_math::Scene3D& scene3d,
                                    double view_w, double view_h,
                                    bool drain_queues = true) {
        std::ostringstream ss;
        ss << "{";
        ss << "\"is3DMode\":" << (scene3d.active ? "true" : "false") << ",";
        ss << "\"score\":" << score << ",";
        ss << "\"lives\":" << lives << ",";
        ss << "\"maxLives\":" << max_lives << ",";
        ss << "\"combo\":" << combo << ",";
        ss << "\"fps\":" << static_cast<int>(std::round(fps_smooth)) << ",";
        ss << "\"gravity\":" << gravity << ",";
        ss << "\"timeScale\":" << time_scale << ",";
        ss << "\"gameOver\":" << (game_over ? "true" : "false") << ",";
        ss << "\"gameWon\":" << (game_won ? "true" : "false") << ",";
        ss << "\"scenario\":{\"name\":\"" << escape_json(scenario_name) << "\",\"weather\":\"" << escape_json(scenario_weather)
           << "\",\"bg\":\"" << escape_json(scenario_bg) << "\",\"accent\":\"" << escape_json(scenario_accent) << "\"},";
        ss << "\"world\":{\"width\":" << world_width << ",\"height\":" << world_height << "},";
        ss << "\"camera\":{\"x\":" << cam_x << ",\"y\":" << cam_y << ",\"shake\":" << cam_shake << "},";
        ss << "\"camera3D\":{\"enabled\":" << (cam_3d_layer ? "true" : "false")
           << ",\"mode\":\"" << escape_json(scene3d.cam_mode) << "\",\"fov\":" << scene3d.cam_fov << "},";

        // Player summary
        ss << "\"player\":";
        if (scene3d.active) {
            const loop_math::Entity3D* p3 = nullptr;
            for (const auto& e : scene3d.entities) {
                if (e.type == "player") { p3 = &e; break; }
            }
            if (p3) {
                ss << "{\"x\":" << p3->pos.x << ",\"y\":" << p3->pos.y << ",\"z\":" << p3->pos.z
                   << ",\"health\":" << p3->health << ",\"maxHealth\":100,\"facing\":1}";
            } else {
                ss << "null";
            }
        } else if (auto* p2 = get_player_2d()) {
            ss << "{\"x\":" << p2->x << ",\"y\":" << p2->y << ",\"w\":" << p2->w << ",\"h\":" << p2->h
               << ",\"vx\":" << p2->vx << ",\"vy\":" << p2->vy
               << ",\"health\":" << p2->health << ",\"maxHealth\":" << p2->max_health
               << ",\"facing\":" << p2->facing << ",\"overdrive\":" << (p2->overdrive ? "true" : "false")
               << ",\"squash\":" << p2->squash << ",\"stretch\":" << p2->stretch
               << ",\"isDashing\":" << (p2->is_dashing ? "true" : "false")
               << ",\"shield\":" << (p2->shield_timer > 0 ? "true" : "false")
               << ",\"color\":\"" << escape_json(p2->color) << "\"}";
        } else {
            ss << "null";
        }
        ss << ",";

        // 2D Entities
        ss << "\"entities\":[";
        for (size_t i = 0; i < entities_2d.size(); ++i) {
            const auto& e = entities_2d[i];
            if (i > 0) ss << ",";
            ss << "{\"type\":\"" << escape_json(e.type) << "\",\"name\":\"" << escape_json(e.name) << "\","
               << "\"x\":" << e.x << ",\"y\":" << e.y << ",\"z\":" << e.z << ",\"w\":" << e.w << ",\"h\":" << e.h << ","
               << "\"r\":" << e.radius << ",\"color\":\"" << escape_json(e.color) << "\","
               << "\"label\":\"" << escape_json(e.label) << "\",\"state\":\"" << escape_json(e.state) << "\","
               << "\"health\":" << e.health << ",\"maxHealth\":" << e.max_health << ","
               << "\"angle\":" << e.angle << ",\"pulse\":" << e.pulse << ",\"facing\":" << e.facing << ","
               << "\"collected\":" << (e.collected ? "true" : "false") << ","
               << "\"broken\":" << (e.broken ? "true" : "false") << ","
               << "\"activated\":" << (e.activated ? "true" : "false") << ","
               << "\"active\":" << (e.active ? "true" : "false") << ","
               << "\"alive\":" << (e.alive ? "true" : "false") << ","
               << "\"overdrive\":" << (e.overdrive ? "true" : "false") << ","
               << "\"squash\":" << e.squash << ",\"stretch\":" << e.stretch << ","
               << "\"toX\":" << e.to_x << ",\"toY\":" << e.to_y << "}";
        }
        ss << "],";

        // Particles (for 2D Canvas)
        ss << "\"particles\":[";
        for (size_t i = 0; i < particles.size(); ++i) {
            const auto& p = particles[i];
            if (i > 0) ss << ",";
            ss << "{\"x\":" << p.x << ",\"y\":" << p.y << ",\"size\":" << p.size
               << ",\"alpha\":" << std::clamp(p.life / std::max(0.01, p.max_life), 0.0, 1.0)
               << ",\"color\":\"" << escape_json(p.color) << "\"}";
        }
        ss << "],";

        // Projectiles (for 2D Canvas)
        ss << "\"projectiles\":[";
        for (size_t i = 0; i < projectiles.size(); ++i) {
            const auto& pr = projectiles[i];
            if (i > 0) ss << ",";
            ss << "{\"x\":" << pr.x << ",\"y\":" << pr.y << ",\"r\":" << pr.radius
               << ",\"fromPlayer\":" << (pr.from_player ? "true" : "false")
               << ",\"color\":\"" << escape_json(pr.color) << "\"}";
        }
        ss << "],";

        // Popups (2D world coords, or 3D projected coords!)
        ss << "\"popups\":[";
        bool first_pop = true;
        for (const auto& pop : popups) {
            if (scene3d.active) {
                auto proj = loop_math::project_point({pop.x, pop.y, pop.z},
                                                     {cam3d_cur_x, cam3d_cur_y, cam3d_cur_z},
                                                     {cam3d_tgt_x, cam3d_tgt_y, cam3d_tgt_z},
                                                     scene3d.cam_fov, static_cast<int>(view_w), static_cast<int>(view_h));
                if (!proj.visible) continue;
                if (!first_pop) ss << ",";
                first_pop = false;
                ss << "{\"x\":" << proj.x << ",\"y\":" << proj.y << ",\"alpha\":" << pop.alpha
                   << ",\"text\":\"" << escape_json(pop.text) << "\",\"color\":\"" << escape_json(pop.color) << "\"}";
            } else {
                if (!first_pop) ss << ",";
                first_pop = false;
                ss << "{\"x\":" << pop.x << ",\"y\":" << pop.y << ",\"alpha\":" << pop.alpha
                   << ",\"text\":\"" << escape_json(pop.text) << "\",\"color\":\"" << escape_json(pop.color) << "\"}";
            }
        }
        ss << "],";

        // Stage Presets
        ss << "\"stagePresets\":[";
        for (size_t i = 0; i < stage_presets.size(); ++i) {
            const auto& pr = stage_presets[i];
            if (i > 0) ss << ",";
            ss << "{\"id\":\"" << escape_json(pr.id) << "\",\"label\":\"" << escape_json(pr.label)
               << "\",\"x\":" << pr.x << ",\"y\":" << pr.y << ",\"weather\":\"" << escape_json(pr.weather)
               << "\",\"gravity\":" << pr.gravity << ",\"color\":\"" << escape_json(pr.color)
               << "\",\"overdrive\":" << (pr.overdrive ? "true" : "false") << "}";
        }
        ss << "],";

        // Algebra Table
        if (algebra_table.enabled) {
            ss << "\"algebraTable\":{\"title\":\"" << escape_json(algebra_table.title)
               << "\",\"formula\":\"" << escape_json(algebra_table.formula)
               << "\",\"monsterHits\":" << algebra_table.monster_hits << ",\"rows\":[";
            for (size_t i = 0; i < algebra_table.rows.size(); ++i) {
                const auto& r = algebra_table.rows[i];
                if (i > 0) ss << ",";
                ss << "{\"label\":\"" << escape_json(r.label) << "\",\"m\":" << r.m << ",\"v\":" << r.v
                   << ",\"h\":" << r.h << ",\"hits\":" << r.hits << "}";
            }
            ss << "]},";
        } else {
            ss << "\"algebraTable\":null,";
        }

        // SFX Queue & Log Queue
        ss << "\"sfx\":[";
        for (size_t i = 0; i < sfx_queue.size(); ++i) {
            if (i > 0) ss << ",";
            ss << "\"" << escape_json(sfx_queue[i]) << "\"";
        }
        ss << "],";

        ss << "\"logs\":[";
        for (size_t i = 0; i < log_queue.size(); ++i) {
            if (i > 0) ss << ",";
            ss << "\"" << escape_json(log_queue[i]) << "\"";
        }
        ss << "]";

        if (drain_queues) {
            sfx_queue.clear();
            log_queue.clear();
        }
        ss << "}";
        return ss.str();
    }

private:
    void step_2d(double dt) {
        double floor_y = world_height - 44.0;
        StageEntity2D* player = get_player_2d();

        // 1. Update Moving Platforms, Portals, Teleporters, Lasers, Saws, Turrets
        for (auto& other : entities_2d) {
            if (!other.alive) continue;
            other.glow_pulse += dt * 5.0;
            if (other.pulse > 0.0) other.pulse = std::max(0.0, other.pulse - dt * 3.5);

            if (other.type == "moving_platform") {
                if (other.axis == "y") {
                    other.y += other.dir * other.speed * dt;
                    other.vx = 0; other.vy = other.dir * other.speed;
                    if (other.y >= other.max_pos) { other.y = other.max_pos; other.dir = -1.0; }
                    if (other.y <= other.min_pos) { other.y = other.min_pos; other.dir = 1.0; }
                } else {
                    other.x += other.dir * other.speed * dt;
                    other.vx = other.dir * other.speed; other.vy = 0;
                    if (other.x >= other.max_pos) { other.x = other.max_pos; other.dir = -1.0; }
                    if (other.x <= other.min_pos) { other.x = other.min_pos; other.dir = 1.0; }
                }
            } else if (other.type == "portal" || other.type == "teleporter") {
                other.angle += dt * 2.5;
            } else if (other.type == "laser_hazard") {
                other.timer += dt;
                if (other.timer >= std::max(0.2, other.interval)) {
                    other.timer = 0.0;
                    other.active = !other.active;
                }
            } else if (other.type == "saw") {
                other.angle += dt * 10.0;
                if (other.axis == "y") {
                    other.y += other.dir * other.speed * dt;
                    if (other.y >= other.max_pos) { other.y = other.max_pos; other.dir = -1.0; }
                    if (other.y <= other.min_pos) { other.y = other.min_pos; other.dir = 1.0; }
                } else {
                    other.x += other.dir * other.speed * dt;
                    if (other.x >= other.max_pos) { other.x = other.max_pos; other.dir = -1.0; }
                    if (other.x <= other.min_pos) { other.x = other.min_pos; other.dir = 1.0; }
                }
            } else if (other.type == "turret" && player && !game_over) {
                other.fire_timer += dt;
                double dist = std::hypot(player->x - other.x, player->y - other.y);
                if (dist < other.max_pos && other.fire_timer >= std::max(0.4, other.fire_rate)) {
                    other.fire_timer = 0.0;
                    double dx = (player->x + player->w * 0.5) - (other.x + other.w * 0.5);
                    double dy = (player->y + player->h * 0.5) - (other.y + other.h * 0.5);
                    double len = std::max(1.0, std::hypot(dx, dy));
                    projectiles.push_back({other.x + other.w * 0.5, other.y + other.h * 0.5, 0,
                                           (dx / len) * 320.0, (dy / len) * 320.0, 0,
                                           5.5, 22.0, 2.5, false, "#f43f5e"});
                }
            } else if ((other.type == "enemy" || other.type == "boss") && other.alive) {
                other.x += other.dir * other.speed * dt;
                if (other.x >= other.max_pos) { other.x = other.max_pos; other.dir = -1.0; }
                if (other.x <= other.min_pos) { other.x = other.min_pos; other.dir = 1.0; }
                if (other.type == "boss" && player && !game_over) {
                    other.fire_timer += dt;
                    if (other.fire_timer >= std::max(0.5, other.fire_rate)) {
                        other.fire_timer = 0.0;
                        double pdir = (player->x < other.x) ? -1.0 : 1.0;
                        projectiles.push_back({other.x + other.w * 0.5, other.y + other.h * 0.4, 0,
                                               pdir * 310.0, -35.0, 0, 7.0, 25.0, 2.5, false, "#ef4444"});
                    }
                }
            }
        }

        // 2. Player Physics & Input
        if (player && !game_over) {
            if (player->coyote_timer > 0) player->coyote_timer -= dt;
            if (player->jump_buffer_timer > 0) player->jump_buffer_timer -= dt;
            if (player->invuln_timer > 0) player->invuln_timer -= dt;
            if (player->dash_cooldown > 0) player->dash_cooldown -= dt;
            if (player->teleport_cooldown > 0) player->teleport_cooldown -= dt;
            if (player->shield_timer > 0) player->shield_timer -= dt;
            if (player->shoot_cooldown > 0) player->shoot_cooldown -= dt;

            bool wants_dash = (keys_mask & STAGE_INP_DASH) && !(prev_keys_mask & STAGE_INP_DASH);
            if (wants_dash && player->dash_cooldown <= 0 && !player->is_dashing) {
                player->is_dashing = true;
                player->dash_timer = 0.16;
                player->dash_cooldown = 0.65;
                player->vx = player->facing * player->speed * 2.45;
                player->vy = 0;
                emit_sfx("dash");
                spawn_particles(player->x + player->w * 0.5, player->y + player->h * 0.5, "#00f5d4", 12);
            }

            bool wants_shoot = (keys_mask & STAGE_INP_SHOOT) && !(prev_keys_mask & STAGE_INP_SHOOT);
            if (wants_shoot && player->shoot_cooldown <= 0) {
                player->shoot_cooldown = player->overdrive ? 0.14 : 0.24;
                double px = player->x + (player->facing > 0 ? player->w : 0.0);
                double py = player->y + player->h * 0.45;
                projectiles.push_back({px, py, 0, player->facing * 620.0, 0, 0,
                                       player->overdrive ? 7.0 : 5.0, player->overdrive ? 40.0 : 25.0,
                                       1.8, true, player->overdrive ? "#f59e0b" : "#38bdf8"});
                emit_sfx("shoot");
                spawn_particles(px, py, "#38bdf8", 6);
            }

            if (player->is_dashing) {
                player->dash_timer -= dt;
                spawn_particles(player->x + player->w * 0.5, player->y + player->h * 0.5, "#00f5d4", 2);
                if (player->dash_timer <= 0) player->is_dashing = false;
            } else {
                bool move_left = (keys_mask & STAGE_INP_LEFT) != 0;
                bool move_right = (keys_mask & STAGE_INP_RIGHT) != 0;
                if (move_left) {
                    player->vx = -player->speed;
                    player->facing = -1;
                } else if (move_right) {
                    player->vx = player->speed;
                    player->facing = 1;
                } else {
                    player->vx *= friction;
                }

                bool wants_jump = (keys_mask & (STAGE_INP_JUMP | STAGE_INP_UP)) != 0;
                bool jump_pressed = wants_jump && !((prev_keys_mask & (STAGE_INP_JUMP | STAGE_INP_UP)) != 0);
                if (jump_pressed) player->jump_buffer_timer = jump_buffer;

                if (player->jump_buffer_timer > 0) {
                    if (player->coyote_timer > 0 && !player->is_jumping) {
                        player->vy = -player->jump_force;
                        player->is_jumping = true;
                        player->coyote_timer = 0;
                        player->jump_buffer_timer = 0;
                        player->double_jump_available = player->can_double_jump;
                        player->stretch = 1.25; player->squash = 0.85;
                        emit_sfx("jump");
                        spawn_particles(player->x + player->w * 0.5, player->y + player->h, "#38bdf8", 12);
                    } else if (player->double_jump_available && player->is_jumping) {
                        player->vy = -player->jump_force * 0.92;
                        player->double_jump_available = false;
                        player->jump_buffer_timer = 0;
                        player->stretch = 1.3; player->squash = 0.8;
                        emit_sfx("double_jump");
                        spawn_particles(player->x + player->w * 0.5, player->y + player->h, "#c084fc", 16);
                        add_popup(player->x, player->y - 12.0, "DOUBLE JUMP!", "#c084fc");
                    }
                }

                double grav_scale = 1.0, wx = 0.0, wy = 0.0;
                for (const auto& gz : entities_2d) {
                    if (gz.type == "gravity_zone" &&
                        player->x + player->w > gz.x && player->x < gz.x + gz.w &&
                        player->y + player->h > gz.y && player->y < gz.y + gz.h) {
                        grav_scale = gz.scale;
                        wx = gz.wind_x;
                        wy = gz.wind_y;
                    }
                }
                player->vx += wx * dt;
                player->vy += (gravity * grav_scale + wy) * dt;
            }

            player->x += player->vx * dt;
            player->y += player->vy * dt;
            player->x = std::clamp(player->x, 0.0, std::max(0.0, world_width - player->w));
            player->squash += (1.0 - player->squash) * dt * 10.0;
            player->stretch += (1.0 - player->stretch) * dt * 10.0;

            if (player->y + player->h >= floor_y) {
                player->y = floor_y - player->h;
                player->vy = 0;
                player->is_jumping = false;
                player->coyote_timer = coyote_time;
                player->double_jump_available = player->can_double_jump;
            }

            auto apply_damage = [&](double dmg, const std::string& label) {
                if (player->invuln_timer > 0 || player->shield_timer > 0) return;
                player->health -= dmg;
                player->invuln_timer = 1.0;
                cam_shake = 10.0;
                emit_sfx("hurt");
                add_popup(player->x, player->y - 12.0, "-" + std::to_string(static_cast<int>(dmg)) + " " + label, "#ef4444");
                spawn_particles(player->x + player->w * 0.5, player->y + player->h * 0.5, "#ef4444", 18);
                player->vy = -280.0;
                if (player->health <= 0) {
                    lives--;
                    if (lives > 0) {
                        player->health = player->max_health;
                        player->x = player->spawn_x;
                        player->y = player->spawn_y;
                        player->vx = 0; player->vy = 0;
                        emit_log("Vidas restantes: " + std::to_string(lives));
                    } else {
                        player->health = 0;
                        trigger_game_over();
                    }
                }
            };

            const StageEntity2D* riding = nullptr;
            for (auto& other : entities_2d) {
                if (other.is_player) continue;
                if (other.type == "platform" || other.type == "moving_platform") {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h >= other.y && player->y + player->h <= other.y + other.h + 16.0 && player->vy >= 0) {
                        player->y = other.y - player->h;
                        player->vy = 0;
                        player->is_jumping = false;
                        player->coyote_timer = coyote_time;
                        player->double_jump_available = player->can_double_jump;
                        if (other.type == "moving_platform") riding = &other;
                    }
                } else if (other.type == "spike") {
                    if (player->x + player->w > other.x + 4 && player->x < other.x + other.w - 4 &&
                        player->y + player->h >= other.y + 6 && player->y <= other.y + other.h) {
                        apply_damage(other.damage, "HP");
                    }
                } else if (other.type == "jump_pad") {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h >= other.y && player->y + player->h <= other.y + other.h + 12.0 && player->vy >= 0) {
                        player->vy = -std::abs(other.power);
                        player->is_jumping = true;
                        player->double_jump_available = true;
                        other.pulse = 1.0;
                        emit_sfx("pad");
                        add_popup(other.x + other.w * 0.5, other.y - 14.0, "MEGA BOOST!", "#fbbf24");
                        spawn_particles(other.x + other.w * 0.5, other.y, "#fbbf24", 20);
                    }
                } else if (other.type == "orb") {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 26.0 && (keys_mask & (STAGE_INP_JUMP | STAGE_INP_UP))) {
                        player->vy = -std::abs(other.power);
                        player->is_jumping = true;
                        player->double_jump_available = true;
                        other.pulse = 1.0;
                        emit_sfx("pad");
                        add_popup(other.x, other.y - 14.0, "AIR BOOST!", "#f59e0b");
                        spawn_particles(other.x, other.y, "#f59e0b", 20);
                    }
                } else if (other.type == "coin" && !other.collected) {
                    if (player->x + player->w >= other.x - other.radius && player->x <= other.x + other.radius &&
                        player->y + player->h >= other.y - other.radius && player->y <= other.y + other.radius) {
                        other.collected = true;
                        score += static_cast<int>(other.points);
                        combo++; combo_timer = 3.0;
                        emit_sfx("coin");
                        add_popup(other.x, other.y - 10.0, "+" + std::to_string(static_cast<int>(other.points)), "#fbbf24");
                        spawn_particles(other.x, other.y, "#fbbf24", 18);
                        emit_log("Moneda +" + std::to_string(static_cast<int>(other.points)) + " (Score: " + std::to_string(score) + ")");
                    }
                } else if (other.type == "heart" && !other.collected) {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 20.0) {
                        other.collected = true;
                        player->health = std::min(player->max_health, player->health + other.health);
                        emit_sfx("heal");
                        add_popup(other.x, other.y - 12.0, "+" + std::to_string(static_cast<int>(other.health)) + " HP", "#10b981");
                        spawn_particles(other.x, other.y, "#10b981", 18);
                    }
                } else if (other.type == "checkpoint" && !other.activated) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        other.activated = true;
                        other.pulse = 1.0;
                        player->spawn_x = other.x;
                        player->spawn_y = other.y - 10.0;
                        player->health = std::min(player->max_health, player->health + 25.0);
                        emit_sfx("heal");
                        add_popup(other.x, other.y - 14.0, other.label.empty() ? "CHECKPOINT" : other.label, "#4ade80");
                        spawn_particles(other.x + 14.0, other.y + 20.0, "#4ade80", 20);
                    }
                } else if (other.type == "teleporter" && player->teleport_cooldown <= 0) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        spawn_particles(player->x + player->w * 0.5, player->y + player->h * 0.5, other.color, 18);
                        player->x = other.to_x; player->y = other.to_y; player->vy = -120.0;
                        player->teleport_cooldown = 1.1;
                        emit_sfx("pad");
                        add_popup(player->x, player->y - 14.0, other.label.empty() ? "WARP!" : other.label, other.color);
                        spawn_particles(player->x + player->w * 0.5, player->y + player->h * 0.5, other.color, 20);
                    }
                } else if (other.type == "breakable" && !other.broken) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        if (player->is_dashing || player->overdrive) {
                            other.broken = true;
                            score += static_cast<int>(other.points);
                            cam_shake = 8.0;
                            emit_sfx("stomp");
                            add_popup(other.x, other.y - 10.0, "SHATTER!", "#fbbf24");
                            spawn_particles(other.x + other.w * 0.5, other.y + other.h * 0.5, other.color, 24);
                        } else if (player->vy >= 0 && (player->y + player->h) <= other.y + 16.0) {
                            player->y = other.y - player->h; player->vy = 0;
                            player->is_jumping = false; player->coyote_timer = coyote_time;
                        } else {
                            if (player->x + player->w * 0.5 < other.x + other.w * 0.5) player->x = other.x - player->w;
                            else player->x = other.x + other.w;
                            player->vx = 0;
                        }
                    }
                } else if (other.type == "laser_hazard" && other.active) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h && !player->is_dashing) {
                        apply_damage(other.damage, "LASER");
                    }
                } else if (other.type == "saw") {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < other.radius + 16.0) apply_damage(other.damage, "SAW");
                } else if (other.type == "powerup" && !other.collected) {
                    double dist = std::hypot((player->x + player->w * 0.5) - other.x, (player->y + player->h * 0.5) - other.y);
                    if (dist < 30.0) {
                        other.collected = true;
                        if (other.state == "shield") player->shield_timer = 8.0;
                        else player->overdrive = true;
                        emit_sfx("heal");
                        add_popup(other.x, other.y - 14.0, other.label.empty() ? "POWER-UP!" : other.label, other.color);
                        spawn_particles(other.x, other.y, other.color, 20);
                    }
                } else if ((other.type == "enemy" || other.type == "boss") && other.alive) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        if (player->vy > 0 && (player->y + player->h) <= other.y + 22.0) {
                            other.health -= (other.type == "boss" ? 90.0 : 100.0);
                            player->vy = -340.0;
                            player->double_jump_available = true;
                            emit_sfx("stomp");
                            if (other.health <= 0) {
                                other.alive = false;
                                int pts = (other.type == "boss") ? 1000 : 250;
                                score += pts;
                                add_popup(other.x, other.y - 14.0, "+" + std::to_string(pts) + " STOMP!", "#38bdf8");
                                spawn_particles(other.x + other.w * 0.5, other.y + other.h * 0.5, other.color, 26);
                                emit_log("Enemigo neutralizado +" + std::to_string(pts));
                            }
                        } else {
                            apply_damage(other.type == "boss" ? 35.0 : 25.0, "HIT");
                        }
                    }
                } else if (other.type == "portal" && !game_won) {
                    if (player->x + player->w > other.x && player->x < other.x + other.w &&
                        player->y + player->h > other.y && player->y < other.y + other.h) {
                        trigger_victory();
                    }
                }
            }

            if (riding) {
                player->x += riding->vx * dt;
                player->y += riding->vy * dt;
            }

            // Camera follow
            double target_cam_x = std::clamp(player->x - 360.0, 0.0, std::max(0.0, world_width - 760.0));
            cam_x += (target_cam_x - cam_x) * cam_smooth;
        }

        // 3. Projectiles 2D
        for (size_t i = 0; i < projectiles.size();) {
            auto& pr = projectiles[i];
            pr.x += pr.vx * dt;
            pr.y += pr.vy * dt;
            pr.life -= dt;
            bool remove_me = (pr.life <= 0.0);

            if (!remove_me && pr.from_player) {
                for (auto& e : entities_2d) {
                    if ((e.type == "enemy" || e.type == "boss") && e.alive &&
                        pr.x + pr.radius > e.x && pr.x - pr.radius < e.x + e.w &&
                        pr.y + pr.radius > e.y && pr.y - pr.radius < e.y + e.h) {
                        e.health -= pr.damage;
                        remove_me = true;
                        spawn_particles(pr.x, pr.y, pr.color, 10);
                        if (e.health <= 0) {
                            e.alive = false;
                            int pts = (e.type == "boss") ? 1000 : 200;
                            score += pts;
                            emit_sfx("stomp");
                            add_popup(e.x, e.y - 12.0, "+" + std::to_string(pts), "#fbbf24");
                            spawn_particles(e.x + e.w * 0.5, e.y + e.h * 0.5, e.color, 22);
                        }
                        break;
                    }
                }
            } else if (!remove_me && !pr.from_player && player && !game_over) {
                if (pr.x + pr.radius > player->x && pr.x - pr.radius < player->x + player->w &&
                    pr.y + pr.radius > player->y && pr.y - pr.radius < player->y + player->h) {
                    remove_me = true;
                    if (player->invuln_timer <= 0 && player->shield_timer <= 0) {
                        player->health -= pr.damage;
                        player->invuln_timer = 0.8;
                        emit_sfx("hurt");
                        add_popup(player->x, player->y - 12.0, "-" + std::to_string(static_cast<int>(pr.damage)) + " HP", "#ef4444");
                        if (player->health <= 0) {
                            lives--;
                            if (lives > 0) {
                                player->health = player->max_health;
                                player->x = player->spawn_x; player->y = player->spawn_y;
                            } else {
                                player->health = 0;
                                trigger_game_over();
                            }
                        }
                    }
                }
            }

            if (remove_me) projectiles.erase(projectiles.begin() + i);
            else ++i;
        }
    }

    void step_3d(loop_math::Scene3D& scene, double dt) {
        scene.step(dt);

        loop_math::Entity3D* player = nullptr;
        for (auto& e : scene.entities) {
            if (e.type == "player") { player = &e; break; }
        }
        if (!player) {
            // Allow interactive camera orbit/pan even for 3D showcase scenes without a player entity
            double yaw_spd = ((keys_mask & STAGE_INP_RIGHT) ? 1.0 : 0.0) - ((keys_mask & STAGE_INP_LEFT) ? 1.0 : 0.0);
            double pitch_spd = ((keys_mask & STAGE_INP_UP) ? 1.0 : 0.0) - ((keys_mask & STAGE_INP_DOWN) ? 1.0 : 0.0);
            if (std::abs(yaw_spd) > 0.01) cam3d_yaw_offset += yaw_spd * 1.4 * dt;
            if (std::abs(pitch_spd) > 0.01) cam3d_pitch_offset = std::clamp(cam3d_pitch_offset + pitch_spd * 0.9 * dt, -0.35, 1.15);
            if (std::abs(cam3d_yaw_offset) > 1e-4 || std::abs(cam3d_pitch_offset - 0.24) > 1e-4) {
                double dist = 26.0;
                scene.cam_pos = {
                    scene.cam_target.x - std::sin(cam3d_yaw_offset) * dist,
                    scene.cam_target.y + 4.5 + std::sin(cam3d_pitch_offset) * 14.0,
                    scene.cam_target.z - std::cos(cam3d_yaw_offset) * dist
                };
            }
            return;
        }

        if (p3d_coyote > 0) p3d_coyote -= dt;
        if (p3d_jump_buf > 0) p3d_jump_buf -= dt;
        if (p3d_invuln > 0) p3d_invuln -= dt;
        if (p3d_dash_cd > 0) p3d_dash_cd -= dt;
        if (p3d_shoot_cd > 0) p3d_shoot_cd -= dt;

        if (!game_over) {
            double spd = player->speed * ((keys_mask & STAGE_INP_SPRINT) ? 1.55 : 1.0);
            double fwd_x = std::sin(cam3d_yaw_offset), fwd_z = std::cos(cam3d_yaw_offset);
            double right_x = std::cos(cam3d_yaw_offset), right_z = -std::sin(cam3d_yaw_offset);

            double mx = ((keys_mask & STAGE_INP_RIGHT) ? 1.0 : 0.0) - ((keys_mask & STAGE_INP_LEFT) ? 1.0 : 0.0);
            double mz = ((keys_mask & STAGE_INP_UP) ? 1.0 : 0.0) - ((keys_mask & STAGE_INP_DOWN) ? 1.0 : 0.0);

            bool wants_dash = (keys_mask & STAGE_INP_DASH) && !(prev_keys_mask & STAGE_INP_DASH);
            if (wants_dash && p3d_dash_cd <= 0) {
                p3d_dash_timer = 0.16;
                p3d_dash_cd = 0.65;
                double len = std::hypot(mx, mz);
                double dx = (len > 0.01) ? (fwd_x * mz + right_x * mx) / len : fwd_x;
                double dz = (len > 0.01) ? (fwd_z * mz + right_z * mx) / len : fwd_z;
                p3d_vx = dx * spd * 2.5;
                p3d_vz = dz * spd * 2.5;
                emit_sfx("dash");
                spawn_particles(player->pos.x, player->pos.y, "#38bdf8", 12, player->pos.z, true);
            }

            if (p3d_dash_timer > 0) {
                p3d_dash_timer -= dt;
            } else {
                p3d_vx = (fwd_x * mz + right_x * mx) * spd;
                p3d_vz = (fwd_z * mz + right_z * mx) * spd;
            }

            bool jump_pressed = (keys_mask & STAGE_INP_JUMP) && !(prev_keys_mask & STAGE_INP_JUMP);
            if (jump_pressed) p3d_jump_buf = jump_buffer;

            if (p3d_jump_buf > 0) {
                if (p3d_coyote > 0 || p3d_jumps == 0) {
                    p3d_vy = std::max(12.0, player->power);
                    p3d_jumps = 1;
                    p3d_coyote = 0; p3d_jump_buf = 0;
                    emit_sfx("jump");
                    spawn_particles(player->pos.x, player->pos.y, "#38bdf8", 10, player->pos.z, true);
                } else if (p3d_jumps < 2) {
                    p3d_vy = std::max(11.0, player->power * 0.92);
                    p3d_jumps = 2;
                    p3d_jump_buf = 0;
                    emit_sfx("double_jump");
                    spawn_particles(player->pos.x, player->pos.y, "#c084fc", 14, player->pos.z, true);
                    add_popup(player->pos.x, player->pos.y + 2.0, "DOUBLE JUMP!", "#c084fc", player->pos.z);
                }
            }

            bool shoot_pressed = (keys_mask & STAGE_INP_SHOOT) && !(prev_keys_mask & STAGE_INP_SHOOT);
            if (shoot_pressed && p3d_shoot_cd <= 0) {
                p3d_shoot_cd = 0.22;
                projectiles.push_back({player->pos.x, player->pos.y + 0.4, player->pos.z + 1.2,
                                       fwd_x * 68.0, 0.0, fwd_z * 68.0, 0.75, 35.0, 2.0, true, "#00f5d4"});
                emit_sfx("shoot");
            }

            int sub = std::clamp(scene.substeps, 1, 8);
            double sdt = dt / static_cast<double>(sub);
            for (int s = 0; s < sub; ++s) {
                p3d_vy += scene.gravity * sdt;
                player->pos.x += p3d_vx * sdt;
                player->pos.y += p3d_vy * sdt;
                player->pos.z += p3d_vz * sdt;

                // Floor plane y = 0
                if (player->pos.y <= 0.6) {
                    player->pos.y = 0.6;
                    p3d_vy = 0.0;
                    p3d_jumps = 0;
                    p3d_coyote = coyote_time;
                }

                // Box & Moving Platform landing
                for (const auto& box : scene.entities) {
                    if (box.type != "box" && box.type != "moving_platform") continue;
                    double hx = box.size.x * 0.5 + 0.7;
                    double hz = box.size.z * 0.5 + 0.7;
                    double top_y = box.pos.y + box.size.y * 0.5 + 0.6;
                    if (std::abs(player->pos.x - box.pos.x) <= hx &&
                        std::abs(player->pos.z - box.pos.z) <= hz &&
                        p3d_vy <= 0.0 && player->pos.y <= top_y + 0.45 && player->pos.y >= box.pos.y - 0.5) {
                        player->pos.y = top_y;
                        p3d_vy = 0.0;
                        p3d_jumps = 0;
                        p3d_coyote = coyote_time;
                        if (box.type == "moving_platform") {
                            double dir_sign = (box.vel.x >= 0) ? 1.0 : -1.0;
                            if (box.axis == "z") player->pos.z += dir_sign * box.speed * sdt;
                            else if (box.axis == "y") player->pos.y += dir_sign * box.speed * sdt;
                            else player->pos.x += dir_sign * box.speed * sdt;
                        }
                    }
                }
            }

            // Entity triggers (crystals, rings, pads, hearts, checkpoints, hazards, enemies, bosses, portals)
            for (auto& e : scene.entities) {
                if (e.type == "player" || e.health <= -9999.0) continue;
                double d = loop_math::distance(player->pos, e.pos);
                if ((e.type == "crystal" || e.type == "heart") && d < e.radius + 1.6) {
                    e.health = -9999.0;
                    if (e.type == "crystal") {
                        score += static_cast<int>(e.points);
                        emit_sfx("coin");
                        add_popup(e.pos.x, e.pos.y + 1.5, "+" + std::to_string(static_cast<int>(e.points)), "#fbbf24", e.pos.z);
                        spawn_particles(e.pos.x, e.pos.y, "#fbbf24", 16, e.pos.z, true);
                    } else {
                        player->health = std::min(100.0, player->health + e.health);
                        emit_sfx("heal");
                        add_popup(e.pos.x, e.pos.y + 1.5, "+HP", "#10b981", e.pos.z);
                        spawn_particles(e.pos.x, e.pos.y, "#10b981", 16, e.pos.z, true);
                    }
                } else if ((e.type == "ring" || e.type == "pad") && d < e.radius + 1.4 && p3d_vy <= 4.0) {
                    p3d_vy = std::max(18.0, e.power * 0.72);
                    p3d_jumps = 0;
                    emit_sfx("pad");
                    add_popup(e.pos.x, e.pos.y + 2.0, "TURBO RING!", e.color, e.pos.z);
                    spawn_particles(e.pos.x, e.pos.y, e.color, 18, e.pos.z, true);
                } else if (e.type == "checkpoint" && d < e.radius + 2.2) {
                    if (e.tag != "activated") {
                        e.tag = "activated";
                        p3d_spawn_x = e.pos.x; p3d_spawn_y = e.pos.y + 1.2; p3d_spawn_z = e.pos.z;
                        emit_sfx("heal");
                        add_popup(e.pos.x, e.pos.y + 2.2, e.label.empty() ? "CHECKPOINT" : e.label, "#4ade80", e.pos.z);
                    }
                } else if ((e.type == "hazard" || e.type == "enemy" || e.type == "boss") && d < e.radius + 1.3 && p3d_invuln <= 0) {
                    player->health -= e.damage;
                    p3d_invuln = 1.0;
                    p3d_vy = 11.0;
                    emit_sfx("hurt");
                    add_popup(player->pos.x, player->pos.y + 2.0, "-" + std::to_string(static_cast<int>(e.damage)) + " HP", "#ef4444", player->pos.z);
                    if (player->health <= 0) {
                        lives--;
                        if (lives > 0) {
                            player->health = 100.0;
                            player->pos = {p3d_spawn_x, p3d_spawn_y, p3d_spawn_z};
                            p3d_vx = p3d_vy = p3d_vz = 0.0;
                        } else {
                            player->health = 0;
                            trigger_game_over();
                        }
                    }
                } else if (e.type == "portal" && d < e.radius + 1.8 && !game_won) {
                    trigger_victory();
                }
            }
        }

        // Update 3D projectiles
        for (size_t i = 0; i < projectiles.size();) {
            auto& pr = projectiles[i];
            pr.x += pr.vx * dt; pr.y += pr.vy * dt; pr.z += pr.vz * dt;
            pr.life -= dt;
            bool rm = (pr.life <= 0.0);
            if (!rm && pr.from_player) {
                for (auto& e : scene.entities) {
                    if ((e.type == "enemy" || e.type == "boss") && e.health > 0.0 &&
                        loop_math::distance({pr.x, pr.y, pr.z}, e.pos) < e.radius + pr.radius + 0.6) {
                        e.health -= pr.damage;
                        rm = true;
                        spawn_particles(pr.x, pr.y, pr.color, 10, pr.z, true);
                        if (e.health <= 0.0) {
                            e.health = -9999.0;
                            int pts = (e.type == "boss") ? 1200 : 300;
                            score += pts;
                            emit_sfx("stomp");
                            add_popup(e.pos.x, e.pos.y + 2.0, "+" + std::to_string(pts), "#fbbf24", e.pos.z);
                            spawn_particles(e.pos.x, e.pos.y, e.color, 22, e.pos.z, true);
                        }
                        break;
                    }
                }
            }
            if (rm) projectiles.erase(projectiles.begin() + i);
            else ++i;
        }

        // Update Chase / Orbit / Topdown / FPS Camera & sync Scene3D camera
        double dist = 15.5, h_off = 6.2;
        if (scene.cam_mode == "fps") {
            cam3d_cur_x = player->pos.x;
            cam3d_cur_y = player->pos.y + 1.2;
            cam3d_cur_z = player->pos.z + 0.5;
            cam3d_tgt_x = cam3d_cur_x + std::sin(cam3d_yaw_offset) * 14.0;
            cam3d_tgt_y = cam3d_cur_y - std::sin(cam3d_pitch_offset) * 4.0;
            cam3d_tgt_z = cam3d_cur_z + std::cos(cam3d_yaw_offset) * 14.0;
        } else if (scene.cam_mode == "topdown") {
            cam3d_cur_x = player->pos.x;
            cam3d_cur_y = player->pos.y + 28.0;
            cam3d_cur_z = player->pos.z - 8.0;
            cam3d_tgt_x = player->pos.x;
            cam3d_tgt_y = player->pos.y;
            cam3d_tgt_z = player->pos.z + 4.0;
        } else {
            double des_x = player->pos.x - std::sin(cam3d_yaw_offset) * dist;
            double des_y = player->pos.y + h_off + std::sin(cam3d_pitch_offset) * 6.0;
            double des_z = player->pos.z - std::cos(cam3d_yaw_offset) * dist;
            double sm = std::clamp(scene.cam_smooth > 0 ? scene.cam_smooth : 0.14, 0.05, 1.0);
            cam3d_cur_x += (des_x - cam3d_cur_x) * sm;
            cam3d_cur_y += (des_y - cam3d_cur_y) * sm;
            cam3d_cur_z += (des_z - cam3d_cur_z) * sm;
            cam3d_tgt_x = player->pos.x + std::sin(cam3d_yaw_offset) * 8.0;
            cam3d_tgt_y = player->pos.y + 1.4;
            cam3d_tgt_z = player->pos.z + std::cos(cam3d_yaw_offset) * 8.0;
        }
        scene.cam_pos = {cam3d_cur_x, cam3d_cur_y, cam3d_cur_z};
        scene.cam_target = {cam3d_tgt_x, cam3d_tgt_y, cam3d_tgt_z};
    }
};

} // namespace looping
