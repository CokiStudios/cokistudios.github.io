#pragma once

#include "Looping3D.hpp"
#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <algorithm>
#include <cmath>
#include <sstream>

namespace loopize {

// ═══════════════════════════════════════════════════════════════════════
//  LOOPIZE++ GAME ENGINE ADDITIONS — C++17 NATIVE CORE
//  ECS Registry, Wave Director, Finite State Machine, Combo System,
//  Spring-Arm Camera, Tweens, Spatial Hash Grid 3D, Inventory & Quests
// ═══════════════════════════════════════════════════════════════════════

struct ECSSlot {
    std::string id;
    std::string tag = "default";
    std::string layer = "world";
    bool active = true;
    loop_math::Vec3 pos{0, 0, 0};
    loop_math::Vec3 vel{0, 0, 0};
    double hp = 100.0;
    double max_hp = 100.0;
    double speed = 10.0;
    std::string obj_model = "";
    std::string cs_class = "";
    std::unordered_map<std::string, std::string> props;
};

struct WaveRule {
    int wave_number = 1;
    std::string enemy_type = "valkyrie";
    std::string obj_model = "valkyrie_drone.obj";
    int count = 3;
    double spawn_radius = 18.0;
    double enemy_hp = 80.0;
    double enemy_speed = 9.0;
    bool completed = false;
};

struct TweenTrack {
    std::string name;
    std::string curve = "out_cubic";
    double start_val = 0.0;
    double end_val = 1.0;
    double duration = 1.0;
    double elapsed = 0.0;
    bool ping_pong = false;
    bool finished = false;

    double current() const {
        if (duration <= 1e-9) return end_val;
        double u = std::clamp(elapsed / duration, 0.0, 1.0);
        if (ping_pong && u > 0.5) u = 1.0 - (u - 0.5) * 2.0;
        else if (ping_pong) u = u * 2.0;
        double k = loop_math::tween_ease(curve, u);
        return start_val + (end_val - start_val) * k;
    }

    void step(double dt) {
        if (finished) return;
        elapsed += dt;
        if (elapsed >= duration) {
            elapsed = duration;
            finished = true;
        }
    }
};

struct FSMState {
    std::string name = "idle";
    std::string prev_name = "idle";
    double time_in_state = 0.0;
    std::vector<std::string> history;

    void transition(const std::string& next_state) {
        if (next_state == name || next_state.empty()) return;
        prev_name = name;
        name = next_state;
        time_in_state = 0.0;
        history.push_back(next_state);
        if (history.size() > 32) history.erase(history.begin());
    }
};

struct ComboState {
    int hits = 0;
    int max_hits = 0;
    double multiplier = 1.0;
    double decay_timer = 0.0;
    double window_sec = 3.2;
    double total_bonus_score = 0.0;

    double register_hit(double base_points = 100.0) {
        hits++;
        if (hits > max_hits) max_hits = hits;
        decay_timer = window_sec;
        multiplier = std::min(12.0, 1.0 + (hits - 1) * 0.25);
        double awarded = base_points * multiplier;
        total_bonus_score += awarded;
        return awarded;
    }

    void step(double dt) {
        if (hits > 0) {
            decay_timer -= dt;
            if (decay_timer <= 0.0) {
                hits = 0;
                multiplier = 1.0;
                decay_timer = 0.0;
            }
        }
    }
};

struct QuestItem {
    std::string id;
    std::string title;
    int progress = 0;
    int target = 1;
    bool completed = false;
    int reward_xp = 250;
};

struct LoopizeRuntime {
    bool initialized = false;
    double time_scale = 1.0;
    double elapsed_time = 0.0;
    int xp = 0;
    int level = 1;

    // Subsystems
    std::unordered_map<std::string, ECSSlot> ecs;
    std::vector<WaveRule> waves;
    int active_wave_index = -1;
    std::unordered_map<std::string, FSMState> fsms;
    std::unordered_map<std::string, TweenTrack> tweens;
    std::unordered_map<std::string, int> inventory;
    std::unordered_map<std::string, QuestItem> quests;
    ComboState combo;
    loop_math::SpringArmCamera3D camera;
    std::vector<std::string> telemetry_log;

    void reset() {
        *this = LoopizeRuntime{};
        initialized = true;
    }

    std::string spawn_ecs(const std::string& id, const std::string& tag = "default",
                          const loop_math::Vec3& pos = {0, 0, 0}, double hp = 100.0,
                          const std::string& obj_model = "", const std::string& cs_class = "") {
        initialized = true;
        ECSSlot slot;
        slot.id = id.empty() ? ("ecs_" + std::to_string(ecs.size() + 1)) : id;
        slot.tag = tag.empty() ? "default" : tag;
        slot.pos = pos;
        slot.hp = hp;
        slot.max_hp = std::max(1.0, hp);
        slot.obj_model = obj_model;
        slot.cs_class = cs_class;
        ecs[slot.id] = slot;
        return slot.id;
    }

    std::vector<std::string> query_tag(const std::string& tag) const {
        std::vector<std::string> out;
        for (const auto& kv : ecs) {
            if (kv.second.active && (tag == "*" || kv.second.tag == tag)) {
                out.push_back(kv.first);
            }
        }
        std::sort(out.begin(), out.end());
        return out;
    }

    std::vector<std::string> spatial_radius(const loop_math::Vec3& center, double radius,
                                            const std::string& tag_filter = "*") const {
        std::vector<std::string> hits;
        double r2 = radius * radius;
        for (const auto& kv : ecs) {
            if (!kv.second.active) continue;
            if (tag_filter != "*" && kv.second.tag != tag_filter) continue;
            if ((kv.second.pos - center).length_sq() <= r2) {
                hits.push_back(kv.first);
            }
        }
        std::sort(hits.begin(), hits.end());
        return hits;
    }

    int add_wave(int num, const std::string& enemy_type, int count, double hp = 80.0,
                 double radius = 18.0, const std::string& obj_model = "valkyrie_drone.obj") {
        initialized = true;
        WaveRule r;
        r.wave_number = num;
        r.enemy_type = enemy_type;
        r.count = std::max(1, count);
        r.enemy_hp = hp;
        r.spawn_radius = radius;
        r.obj_model = obj_model;
        waves.push_back(r);
        return static_cast<int>(waves.size());
    }

    std::vector<loop_math::Entity3D> trigger_next_wave(loop_math::Scene3D& scene) {
        initialized = true;
        std::vector<loop_math::Entity3D> spawned;
        int next_idx = active_wave_index + 1;
        if (next_idx < 0 || next_idx >= static_cast<int>(waves.size())) return spawned;
        active_wave_index = next_idx;
        WaveRule& w = waves[next_idx];
        for (int i = 0; i < w.count; ++i) {
            double ang = (2.0 * loop_math::PI_3D * i) / std::max(1, w.count);
            loop_math::Vec3 p{
                std::cos(ang) * w.spawn_radius,
                3.2 + (i % 3) * 1.1,
                36.0 + std::sin(ang) * (w.spawn_radius * 0.65)
            };
            std::string eid = w.enemy_type + "_W" + std::to_string(w.wave_number) + "_" + std::to_string(i + 1);
            loop_math::Entity3D e;
            e.type = "enemy";
            e.name = eid;
            e.mesh = "obj";
            e.obj_file = w.obj_model;
            e.tag = "wave_enemy";
            e.pos = p;
            e.size = {2.6, 2.2, 2.6};
            e.radius = 1.6;
            e.health = w.enemy_hp;
            e.speed = w.enemy_speed;
            e.min_pos = p.x - 6.0;
            e.max_pos = p.x + 6.0;
            e.color = "#f43f5e";
            if (!w.obj_model.empty()) {
                e.custom_mesh = loop_math::make_preset_obj_mesh(w.obj_model);
                e.has_custom_mesh = !e.custom_mesh.vertices.empty();
            }
            scene.active = true;
            scene.entities.push_back(e);
            spawned.push_back(e);
            spawn_ecs(eid, "wave_enemy", p, w.enemy_hp, w.obj_model, "ValkyrieAI");
        }
        w.completed = true;
        return spawned;
    }

    int add_item(const std::string& item_id, int qty = 1) {
        initialized = true;
        inventory[item_id] = std::max(0, inventory[item_id] + qty);
        return inventory[item_id];
    }

    bool consume_item(const std::string& item_id, int qty = 1) {
        auto it = inventory.find(item_id);
        if (it == inventory.end() || it->second < qty) return false;
        it->second -= qty;
        return true;
    }

    void add_quest(const std::string& id, const std::string& title, int target = 1, int reward_xp = 250) {
        initialized = true;
        QuestItem q;
        q.id = id;
        q.title = title;
        q.target = std::max(1, target);
        q.reward_xp = reward_xp;
        quests[id] = q;
    }

    bool progress_quest(const std::string& id, int delta = 1) {
        auto it = quests.find(id);
        if (it == quests.end()) return false;
        if (it->second.completed) return true;
        it->second.progress = std::min(it->second.target, it->second.progress + delta);
        if (it->second.progress >= it->second.target) {
            it->second.completed = true;
            xp += it->second.reward_xp;
            while (xp >= level * 500) level++;
        }
        return it->second.completed;
    }

    void step(double dt) {
        double sdt = dt * time_scale;
        elapsed_time += sdt;
        combo.step(sdt);
        for (auto& kv : fsms) kv.second.time_in_state += sdt;
        for (auto& kv : tweens) kv.second.step(sdt);
    }
};

} // namespace loopize
