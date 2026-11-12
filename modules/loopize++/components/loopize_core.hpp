#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <cmath>
#include <algorithm>
#include "../../LoopingEngine/cpp/LoopingValue.hpp"
#include "../../LoopingEngine/cpp/Looping3D.hpp"

namespace loopize {

// =========================================================================
// loopize++ Core C++17 Game Additions Runtime (Arch 3.0A)
// ECS, Wave Director, FSM, Combos/XP, Inventory, Quests, Projectiles,
// Spatial Radius Queries & Spring-Arm Camera with Trauma Shake.
// =========================================================================

struct ECSEntity {
    int id = 0;
    std::string name;
    std::string archetype = "actor";
    std::vector<std::string> tags;
    std::unordered_map<std::string, looping::Value> components;
    loop_math::Vec3 pos{0, 0, 0};
    loop_math::Vec3 vel{0, 0, 0};
    bool alive = true;
};

struct WaveBlueprint {
    int wave_num = 1;
    std::string enemy_kind = "drone";
    int count = 3;
    double hp = 100.0;
    double speed = 12.0;
    std::string model = "valkyrie_drone.obj";
    bool spawned = false;
};

struct WaveState {
    std::string id;
    int current_wave = 0;
    int max_waves = 5;
    int enemies_per_wave = 4;
    int remaining = 0;
    double spawn_interval = 1.25;
    double cooldown = 0.0;
    bool active = false;
    bool completed = false;
};

struct FSMState {
    std::string name;
    std::string current = "idle";
    std::string previous = "";
    int transitions = 0;
    std::unordered_map<std::string, std::unordered_map<std::string, std::string>> edges;
};

struct QuestItem {
    std::string id;
    std::string title;
    int progress = 0;
    int goal = 1;
    int xp_reward = 250;
    bool completed = false;
};

struct ComboState {
    int count = 0;
    int best = 0;
    double timer = 0.0;
    double window_sec = 3.0;
    double multiplier = 1.0;
    int64_t total_score = 0;
};

struct ProjectileAdd {
    std::string owner = "player";
    loop_math::Vec3 pos{0, 0, 0};
    loop_math::Vec3 vel{0, 0, 0};
    double radius = 0.6;
    double damage = 25.0;
    double life = 3.0;
    bool active = true;
};

class LoopizeRuntime {
public:
    bool initialized = false;
    std::string title = "Loopize++ 3D Arena";
    int next_ecs_id = 1;
    int level = 1;
    int64_t xp = 0;
    int next_wave_cursor = 0;

    std::unordered_map<int, ECSEntity> ecs;
    std::vector<WaveBlueprint> wave_queue;
    std::unordered_map<std::string, WaveState> waves;
    std::unordered_map<std::string, FSMState> fsms;
    std::unordered_map<std::string, int> inventory;
    std::unordered_map<std::string, QuestItem> quests;
    std::vector<ProjectileAdd> projectiles;
    ComboState combo;
    loop_math::SpringArmCamera3D spring_cam;

    void reset(const std::string& world_title = "Loopize++ 3D Arena") {
        *this = LoopizeRuntime{};
        initialized = true;
        title = world_title;
    }

    int64_t add_xp(int64_t gain) {
        initialized = true;
        xp += std::max<int64_t>(0, gain);
        while (xp >= static_cast<int64_t>(level) * 1000) {
            xp -= static_cast<int64_t>(level) * 1000;
            ++level;
        }
        return xp;
    }

    int ecs_spawn(const std::string& name, const std::string& archetype, double x, double y, double z,
                  const std::string& tag = "default") {
        initialized = true;
        int id = next_ecs_id++;
        ECSEntity e;
        e.id = id;
        e.name = name;
        e.archetype = archetype;
        e.pos = {x, y, z};
        if (!tag.empty()) e.tags.push_back(tag);
        ecs[id] = e;
        return id;
    }

    bool ecs_set(int id, const std::string& key, const looping::Value& val) {
        auto it = ecs.find(id);
        if (it == ecs.end()) return false;
        it->second.components[key] = val;
        return true;
    }

    looping::Value ecs_get(int id, const std::string& key) const {
        auto it = ecs.find(id);
        if (it == ecs.end()) return looping::Value();
        auto cit = it->second.components.find(key);
        return (cit != it->second.components.end()) ? cit->second : looping::Value();
    }

    bool ecs_add_tag(int id, const std::string& tag) {
        auto it = ecs.find(id);
        if (it == ecs.end()) return false;
        if (std::find(it->second.tags.begin(), it->second.tags.end(), tag) == it->second.tags.end()) {
            it->second.tags.push_back(tag);
        }
        return true;
    }

    std::vector<int> ecs_query_tag(const std::string& tag) const {
        std::vector<int> out;
        for (const auto& kv : ecs) {
            if (!kv.second.alive) continue;
            if (tag == "*" || std::find(kv.second.tags.begin(), kv.second.tags.end(), tag) != kv.second.tags.end()) {
                out.push_back(kv.first);
            }
        }
        std::sort(out.begin(), out.end());
        return out;
    }

    bool ecs_destroy(int id) {
        return ecs.erase(id) > 0;
    }

    int wave_add(int wave_num, const std::string& kind, int count, double hp, double speed, const std::string& model) {
        initialized = true;
        WaveBlueprint bp;
        bp.wave_num = std::max(1, wave_num);
        bp.enemy_kind = kind;
        bp.count = std::max(1, count);
        bp.hp = hp;
        bp.speed = speed;
        bp.model = model;
        wave_queue.push_back(bp);
        return static_cast<int>(wave_queue.size());
    }

    const WaveBlueprint* wave_next() {
        if (next_wave_cursor >= static_cast<int>(wave_queue.size())) return nullptr;
        WaveBlueprint& bp = wave_queue[next_wave_cursor++];
        bp.spawned = true;
        return &bp;
    }

    WaveState& wave_create(const std::string& id, int max_waves = 5, int per_wave = 4, double interval = 1.2) {
        initialized = true;
        WaveState w;
        w.id = id;
        w.max_waves = std::max(1, max_waves);
        w.enemies_per_wave = std::max(1, per_wave);
        w.spawn_interval = std::max(0.05, interval);
        waves[id] = w;
        return waves[id];
    }

    bool wave_start(const std::string& id, int wave_num = 1) {
        if (!waves.count(id)) wave_create(id);
        WaveState& w = waves[id];
        w.current_wave = std::clamp(wave_num, 1, w.max_waves);
        w.remaining = w.enemies_per_wave + (w.current_wave - 1) * 2;
        w.cooldown = 0.0;
        w.active = true;
        w.completed = false;
        return true;
    }

    int wave_step(const std::string& id, double dt) {
        auto it = waves.find(id);
        if (it == waves.end()) return 0;
        WaveState& w = it->second;
        if (!w.active || w.completed) return 0;
        w.cooldown -= dt;
        int spawned_now = 0;
        while (w.cooldown <= 0.0 && w.remaining > 0) {
            --w.remaining;
            ++spawned_now;
            w.cooldown += w.spawn_interval;
        }
        if (w.remaining == 0 && w.current_wave >= w.max_waves) {
            w.active = false;
            w.completed = true;
        }
        return spawned_now;
    }

    void fsm_create(const std::string& name, const std::string& initial_state = "idle") {
        initialized = true;
        FSMState f;
        f.name = name;
        f.current = initial_state;
        fsms[name] = f;
    }

    void fsm_add_rule(const std::string& name, const std::string& from_state, const std::string& event, const std::string& to_state) {
        if (!fsms.count(name)) fsm_create(name, from_state);
        fsms[name].edges[from_state][event] = to_state;
    }

    std::string fsm_trigger(const std::string& name, const std::string& event) {
        auto it = fsms.find(name);
        if (it == fsms.end()) return "";
        FSMState& f = it->second;
        auto sit = f.edges.find(f.current);
        if (sit != f.edges.end()) {
            auto eit = sit->second.find(event);
            if (eit != sit->second.end()) {
                f.previous = f.current;
                f.current = eit->second;
                ++f.transitions;
                return f.current;
            }
        }
        if (f.edges.empty()) {
            f.previous = f.current;
            f.current = event;
            ++f.transitions;
        }
        return f.current;
    }

    int64_t combo_hit_pts(int64_t base_pts = 100, double window_sec = 3.0) {
        initialized = true;
        combo.window_sec = std::max(0.2, window_sec);
        ++combo.count;
        if (combo.count > combo.best) combo.best = combo.count;
        combo.timer = combo.window_sec;
        combo.multiplier = std::min(12.0, 1.0 + (combo.count - 1) * 0.25);
        int64_t pts = static_cast<int64_t>(std::round(base_pts * combo.multiplier));
        combo.total_score += pts;
        add_xp(std::max<int64_t>(10, pts / 4));
        return pts;
    }

    void combo_step(double dt) {
        if (combo.count <= 0) return;
        combo.timer -= dt;
        if (combo.timer <= 0.0) {
            combo.count = 0;
            combo.timer = 0.0;
            combo.multiplier = 1.0;
        }
    }

    int inventory_add(const std::string& item, int qty = 1) {
        initialized = true;
        inventory[item] = std::max(0, inventory[item] + qty);
        return inventory[item];
    }

    bool inventory_has(const std::string& item, int qty = 1) const {
        auto it = inventory.find(item);
        return it != inventory.end() && it->second >= qty;
    }

    void quest_add(const std::string& id, const std::string& title_txt, int goal = 1, int xp_reward = 250) {
        initialized = true;
        QuestItem q;
        q.id = id;
        q.title = title_txt;
        q.goal = std::max(1, goal);
        q.xp_reward = std::max(0, xp_reward);
        quests[id] = q;
    }

    bool quest_progress(const std::string& id, int delta = 1) {
        auto it = quests.find(id);
        if (it == quests.end()) return false;
        bool was_done = it->second.completed;
        it->second.progress = std::clamp(it->second.progress + delta, 0, it->second.goal);
        if (it->second.progress >= it->second.goal) {
            it->second.completed = true;
            if (!was_done) add_xp(it->second.xp_reward);
        }
        return it->second.completed;
    }

    void spawn_projectile(const std::string& owner, const loop_math::Vec3& pos, const loop_math::Vec3& vel,
                          double radius = 0.6, double damage = 25.0, double life = 3.0) {
        initialized = true;
        ProjectileAdd p;
        p.owner = owner;
        p.pos = pos;
        p.vel = vel;
        p.radius = radius;
        p.damage = damage;
        p.life = life;
        projectiles.push_back(p);
    }

    int step_projectiles(double dt, loop_math::Scene3D* scene = nullptr) {
        int hits = 0;
        for (auto& p : projectiles) {
            if (!p.active) continue;
            p.pos = p.pos + p.vel * dt;
            p.life -= dt;
            if (p.life <= 0.0) { p.active = false; continue; }
            if (scene) {
                for (auto& e : scene->entities) {
                    if (e.type == "terrain" || e.name == p.owner) continue;
                    double hit_r = std::max(0.8, e.radius) + p.radius;
                    if ((e.pos - p.pos).length_sq() <= hit_r * hit_r) {
                        e.health = std::max(0.0, e.health - p.damage);
                        p.active = false;
                        ++hits;
                        break;
                    }
                }
            }
        }
        projectiles.erase(
            std::remove_if(projectiles.begin(), projectiles.end(), [](const ProjectileAdd& p) { return !p.active; }),
            projectiles.end()
        );
        return hits;
    }
};

} // namespace loopize
