#include "LoopingInterpreter.hpp"

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#elif defined(_WIN32) && defined(LOOPING_BUILD_DLL)
#define EMSCRIPTEN_KEEPALIVE __declspec(dllexport)
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

#include <chrono>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

using namespace looping;

inline std::string strip_ansi(const std::string& input) {
    std::string out;
    out.reserve(input.size());
    for (size_t i = 0; i < input.size(); ++i) {
        if (input[i] == '\033' && i + 1 < input.size() && input[i + 1] == '[') {
            i += 2;
            while (i < input.size() && !((input[i] >= 'A' && input[i] <= 'Z') || (input[i] >= 'a' && input[i] <= 'z'))) {
                ++i;
            }
            continue;
        }
        out.push_back(input[i]);
    }
    return out;
}

inline std::vector<std::string> split_clean_lines(const std::string& raw) {
    std::vector<std::string> lines;
    std::istringstream iss(strip_ansi(raw));
    std::string line;
    while (std::getline(iss, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (!line.empty()) lines.push_back(line);
    }
    return lines;
}

struct StreamCapture {
    std::ostringstream buffer;
    std::streambuf* old_cout = nullptr;
    std::streambuf* old_cerr = nullptr;

    StreamCapture() {
        old_cout = std::cout.rdbuf(buffer.rdbuf());
        old_cerr = std::cerr.rdbuf(buffer.rdbuf());
    }

    ~StreamCapture() {
        if (old_cout) std::cout.rdbuf(old_cout);
        if (old_cerr) std::cerr.rdbuf(old_cerr);
    }

    std::string str() const { return buffer.str(); }
};

struct WasmVMContext {
    Interpreter vm;
    std::string last_source;
    std::vector<uint8_t> rgba_fb;
    std::vector<uint8_t> bgra_fb;
    std::string out_buf;
};

std::unordered_map<int32_t, std::unique_ptr<WasmVMContext>>& vm_registry() {
    static std::unordered_map<int32_t, std::unique_ptr<WasmVMContext>> reg;
    return reg;
}

int32_t& next_handle_id() {
    static int32_t id = 1;
    return id;
}

std::string& global_out_buf() {
    static std::string buf;
    return buf;
}

WasmVMContext* get_ctx(int32_t h) {
    auto& reg = vm_registry();
    auto it = reg.find(h);
    return (it != reg.end()) ? it->second.get() : nullptr;
}

const char* emit_logs_json(std::string& target, bool ok, double elapsed_ms,
                           const WasmVMContext* ctx, const std::string& captured) {
    auto lines = split_clean_lines(captured);
    std::ostringstream ss;
    ss << "{";
    ss << "\"ok\":" << (ok ? "true" : "false") << ",";
    ss << "\"elapsedMs\":" << elapsed_ms << ",";
    if (ctx) {
        ss << "\"is3DMode\":" << (ctx->vm.current_scene3d.active ? "true" : "false") << ",";
        ss << "\"varsCount\":" << ctx->vm.variables.size() << ",";
        ss << "\"functionsCount\":" << ctx->vm.functions.size() << ",";
    }
    ss << "\"logs\":[";
    for (size_t i = 0; i < lines.size(); ++i) {
        if (i > 0) ss << ",";
        ss << "\"" << LoopingStageRuntime::escape_json(lines[i]) << "\"";
    }
    ss << "]}";
    target = ss.str();
    return target.c_str();
}

} // namespace

extern "C" {

EMSCRIPTEN_KEEPALIVE
int32_t lp_create() {
    int32_t id = next_handle_id()++;
    vm_registry()[id] = std::make_unique<WasmVMContext>();
    return id;
}

EMSCRIPTEN_KEEPALIVE
void lp_destroy(int32_t h) {
    vm_registry().erase(h);
}

EMSCRIPTEN_KEEPALIVE
const char* lp_execute(int32_t h, const char* code) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{\"ok\":false,\"logs\":[\"Invalid VM handle\"]}";
        return global_out_buf().c_str();
    }
    std::string src = code ? code : "";
    ctx->last_source = src;
    ctx->vm.reset_runtime();

    auto t0 = std::chrono::high_resolution_clock::now();
    bool ok = true;
    std::string captured;
    {
        StreamCapture cap;
        try {
            ctx->vm.execute_code(src);
            if (ctx->vm.has_thrown && !ctx->vm.thrown_error.empty()) {
                std::cerr << "[Uncaught Error] " << ctx->vm.thrown_error << "\n";
                ok = false;
            }
        } catch (const std::exception& ex) {
            std::cerr << "[Runtime Exception] " << ex.what() << "\n";
            ok = false;
        }
        captured = cap.str();
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    return emit_logs_json(ctx->out_buf, ok, ms, ctx, captured);
}

EMSCRIPTEN_KEEPALIVE
const char* lp_parse_line(int32_t h, const char* line) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{\"ok\":false,\"logs\":[\"Invalid VM handle\"]}";
        return global_out_buf().c_str();
    }
    std::string src = line ? line : "";
    auto t0 = std::chrono::high_resolution_clock::now();
    bool ok = true;
    std::string captured;
    {
        StreamCapture cap;
        try {
            ctx->vm.execute_code(src);
        } catch (const std::exception& ex) {
            std::cerr << "[Error] " << ex.what() << "\n";
            ok = false;
        }
        captured = cap.str();
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    return emit_logs_json(ctx->out_buf, ok, ms, ctx, captured);
}

EMSCRIPTEN_KEEPALIVE
const char* lp_eval_expr(int32_t h, const char* expr_str) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{\"ok\":false,\"value\":null,\"repr\":\"nil\",\"logs\":[]}";
        return global_out_buf().c_str();
    }
    std::string src = expr_str ? expr_str : "";
    Value result;
    bool ok = true;
    std::string captured;
    {
        StreamCapture cap;
        try {
            Parser p(src);
            auto expr = p.parse_single_expr(src);
            result = ctx->vm.eval(expr);
        } catch (const std::exception& ex) {
            std::cerr << "[Eval Error] " << ex.what() << "\n";
            ok = false;
        }
        captured = cap.str();
    }
    auto lines = split_clean_lines(captured);
    std::ostringstream ss;
    ss << "{\"ok\":" << (ok ? "true" : "false")
       << ",\"value\":" << result.to_json()
       << ",\"repr\":\"" << LoopingStageRuntime::escape_json(result.as_string()) << "\""
       << ",\"logs\":[";
    for (size_t i = 0; i < lines.size(); ++i) {
        if (i > 0) ss << ",";
        ss << "\"" << LoopingStageRuntime::escape_json(lines[i]) << "\"";
    }
    ss << "]}";
    ctx->out_buf = ss.str();
    return ctx->out_buf.c_str();
}

EMSCRIPTEN_KEEPALIVE
void lp_set_channel(int32_t h, const char* channel) {
    if (auto* ctx = get_ctx(h)) {
        ctx->vm.set_channel(channel ? channel : "prod");
    }
}

EMSCRIPTEN_KEEPALIVE
void lp_set_input(int32_t h, uint32_t keys_mask, double yaw_delta, double pitch_delta) {
    auto* ctx = get_ctx(h);
    if (!ctx) return;
    ctx->vm.stage.keys_mask = keys_mask;
    ctx->vm.stage.cam3d_yaw_offset += yaw_delta;
    ctx->vm.stage.cam3d_pitch_offset = std::clamp(ctx->vm.stage.cam3d_pitch_offset + pitch_delta, -0.35, 1.15);
}

EMSCRIPTEN_KEEPALIVE
const char* lp_step(int32_t h, double dt, double view_w, double view_h) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{}";
        return global_out_buf().c_str();
    }
    if (!ctx->vm.csharp_bridge.instances.empty()) {
        ctx->vm.csharp_bridge.step_all(dt, ctx->vm.variables, &ctx->vm.current_scene3d);
    }
    ctx->vm.loopize_runtime.step(dt);
    ctx->vm.stage.step(dt, &ctx->vm.current_scene3d);
    ctx->out_buf = ctx->vm.stage.build_snapshot_json(ctx->vm.current_scene3d, view_w, view_h, true);
    return ctx->out_buf.c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_get_snapshot_json(int32_t h, double view_w, double view_h) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{}";
        return global_out_buf().c_str();
    }
    ctx->out_buf = ctx->vm.stage.build_snapshot_json(ctx->vm.current_scene3d, view_w, view_h, true);
    return ctx->out_buf.c_str();
}

EMSCRIPTEN_KEEPALIVE
const uint8_t* lp_render_3d_rgba(int32_t h, int w, int h_px) {
    auto* ctx = get_ctx(h);
    if (!ctx) return nullptr;
    auto overlay = ctx->vm.stage.build_3d_overlay_entities();
    ctx->vm.current_scene3d.render_rgba(ctx->rgba_fb, w, h_px, &overlay);
    return ctx->rgba_fb.data();
}

EMSCRIPTEN_KEEPALIVE
const uint8_t* lp_render_3d_bgra(int32_t h, int w, int h_px) {
    auto* ctx = get_ctx(h);
    if (!ctx) return nullptr;
    int cw = std::clamp(w, 16, 1920);
    int ch = std::clamp(h_px, 16, 1080);
    auto overlay = ctx->vm.stage.build_3d_overlay_entities();
    std::vector<loop_math::RGBColor> fb;
    ctx->vm.current_scene3d.render_framebuffer(fb, cw, ch, &overlay);
    ctx->bgra_fb.resize(fb.size() * 4);
    for (size_t i = 0; i < fb.size(); ++i) {
        ctx->bgra_fb[i * 4 + 0] = fb[i].b;
        ctx->bgra_fb[i * 4 + 1] = fb[i].g;
        ctx->bgra_fb[i * 4 + 2] = fb[i].r;
        ctx->bgra_fb[i * 4 + 3] = 255;
    }
    return ctx->bgra_fb.data();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_get_vars_json(int32_t h) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{}";
        return global_out_buf().c_str();
    }
    std::ostringstream ss;
    ss << "{";
    bool first = true;
    for (const auto& [k, v] : ctx->vm.variables) {
        if (!first) ss << ",";
        first = false;
        ss << "\"" << LoopingStageRuntime::escape_json(k) << "\":" << v.to_json();
    }
    ss << "}";
    ctx->out_buf = ss.str();
    return ctx->out_buf.c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_get_ui_json(int32_t h) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{}";
        return global_out_buf().c_str();
    }
    const auto& win = ctx->vm.current_window;
    std::ostringstream ss;
    ss << "{";
    ss << "\"title\":\"" << LoopingStageRuntime::escape_json(win.title) << "\",";
    ss << "\"target\":\"" << LoopingStageRuntime::escape_json(win.target_ui) << "\",";
    ss << "\"theme\":\"" << LoopingStageRuntime::escape_json(win.theme) << "\",";
    ss << "\"width\":" << win.width << ",\"height\":" << win.height << ",";
    ss << "\"cards\":[";
    for (size_t i = 0; i < win.cards.size(); ++i) {
        if (i > 0) ss << ",";
        const auto& c = win.cards[i];
        ss << "{\"title\":\"" << LoopingStageRuntime::escape_json(c.title)
           << "\",\"text\":\"" << LoopingStageRuntime::escape_json(c.text)
           << "\",\"badge\":\"" << LoopingStageRuntime::escape_json(c.badge)
           << "\",\"x\":" << c.x << ",\"y\":" << c.y << ",\"w\":" << c.width << ",\"h\":" << c.height << "}";
    }
    ss << "],\"buttons\":[";
    for (size_t i = 0; i < win.buttons.size(); ++i) {
        if (i > 0) ss << ",";
        const auto& b = win.buttons[i];
        ss << "{\"text\":\"" << LoopingStageRuntime::escape_json(b.text)
           << "\",\"action\":\"" << LoopingStageRuntime::escape_json(b.action)
           << "\",\"x\":" << b.x << ",\"y\":" << b.y << "}";
    }
    ss << "],\"swiftuiComponents\":[";
    bool first_su = true;
    for (const auto& [name, comp] : ctx->vm.swiftui_components) {
        if (!first_su) ss << ",";
        first_su = false;
        ss << "\"" << LoopingStageRuntime::escape_json(name) << "\"";
    }
    ss << "]}";
    ctx->out_buf = ss.str();
    return ctx->out_buf.c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_click_button(int32_t h, const char* id_or_label) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{\"ok\":false}";
        return global_out_buf().c_str();
    }
    std::string target = id_or_label ? id_or_label : "";
    bool ok = false;
    std::string captured;
    {
        StreamCapture cap;
        Value res = ctx->vm.eval(std::make_shared<CallExpr>("window.click", std::vector<std::shared_ptr<Expr>>{
            std::make_shared<LiteralExpr>(Value(target))
        }));
        ok = res.is_truthy();
        captured = cap.str();
    }
    return emit_logs_json(ctx->out_buf, ok, 0.0, ctx, captured);
}

EMSCRIPTEN_KEEPALIVE
void lp_heal_player(int32_t h, double amt) {
    if (auto* ctx = get_ctx(h)) ctx->vm.stage.heal_player(amt, &ctx->vm.current_scene3d);
}

EMSCRIPTEN_KEEPALIVE
void lp_boost_player(int32_t h, double power) {
    if (auto* ctx = get_ctx(h)) ctx->vm.stage.boost_player(power, &ctx->vm.current_scene3d);
}

EMSCRIPTEN_KEEPALIVE
void lp_activate_preset(int32_t h, int idx) {
    if (auto* ctx = get_ctx(h)) ctx->vm.stage.activate_preset(idx);
}

EMSCRIPTEN_KEEPALIVE
void lp_set_time_scale(int32_t h, double ts) {
    if (auto* ctx = get_ctx(h)) ctx->vm.stage.time_scale = std::clamp(ts, 0.1, 3.0);
}

EMSCRIPTEN_KEEPALIVE
void lp_toggle_3d(int32_t h) {
    if (auto* ctx = get_ctx(h)) ctx->vm.stage.cam_3d_layer = !ctx->vm.stage.cam_3d_layer;
}

EMSCRIPTEN_KEEPALIVE
void lp_cycle_camera3d(int32_t h) {
    auto* ctx = get_ctx(h);
    if (!ctx) return;
    static const char* modes[] = {"chase", "orbit", "fps", "topdown"};
    int cur = 0;
    for (int i = 0; i < 4; ++i) {
        if (ctx->vm.current_scene3d.cam_mode == modes[i]) { cur = i; break; }
    }
    ctx->vm.current_scene3d.cam_mode = modes[(cur + 1) % 4];
}

EMSCRIPTEN_KEEPALIVE
const char* lp_restart(int32_t h) {
    auto* ctx = get_ctx(h);
    if (!ctx) {
        global_out_buf() = "{\"ok\":false}";
        return global_out_buf().c_str();
    }
    std::string src = ctx->last_source;
    return lp_execute(h, src.c_str());
}

EMSCRIPTEN_KEEPALIVE
const char* lp_check_ast(const char* code) {
    std::string src = code ? code : "";
    auto t0 = std::chrono::high_resolution_clock::now();
    Parser p(src);
    auto stmts = p.parse_script();
    auto t1 = std::chrono::high_resolution_clock::now();
    double parse_us = std::chrono::duration<double, std::micro>(t1 - t0).count();

    size_t total_nodes = 0, fn_count = 0, ui_count = 0, entity_count = 0, entity3d_count = 0, loop_count = 0;
    std::function<void(const std::vector<std::shared_ptr<Stmt>>&)> walk = [&](const std::vector<std::shared_ptr<Stmt>>& list) {
        for (const auto& st : list) {
            if (!st) continue;
            total_nodes++;
            if (auto fn = std::dynamic_pointer_cast<FunctionDefStmt>(st)) { fn_count++; walk(fn->body); }
            else if (std::dynamic_pointer_cast<DrawUIStmt>(st)) ui_count++;
            else if (std::dynamic_pointer_cast<SpawnEntityStmt>(st)) entity_count++;
            else if (std::dynamic_pointer_cast<SpawnEntity3DStmt>(st)) entity3d_count++;
            else if (auto fr = std::dynamic_pointer_cast<ForRangeStmt>(st)) { loop_count++; walk(fr->body); }
            else if (auto fe = std::dynamic_pointer_cast<ForEachStmt>(st)) { loop_count++; walk(fe->body); }
            else if (auto wh = std::dynamic_pointer_cast<WhileStmt>(st)) { loop_count++; walk(wh->body); }
            else if (auto rp = std::dynamic_pointer_cast<RepeatStmt>(st)) { loop_count++; walk(rp->body); }
            else if (auto ifs = std::dynamic_pointer_cast<IfStmt>(st)) { walk(ifs->then_branch); walk(ifs->else_branch); }
            else if (auto ms = std::dynamic_pointer_cast<MatchStmt>(st)) { for (const auto& a : ms->arms) walk(a.body); }
            else if (auto tc = std::dynamic_pointer_cast<TryCatchStmt>(st)) { walk(tc->try_body); walk(tc->catch_body); }
        }
    };
    walk(stmts);

    std::ostringstream ss;
    ss << "{\"ok\":true,\"parseUs\":" << parse_us
       << ",\"topStatements\":" << stmts.size()
       << ",\"totalNodes\":" << total_nodes
       << ",\"functions\":" << fn_count
       << ",\"uiDirectives\":" << ui_count
       << ",\"entities2d\":" << entity_count
       << ",\"entities3d\":" << entity3d_count
       << ",\"loops\":" << loop_count << "}";
    global_out_buf() = ss.str();
    return global_out_buf().c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_format_code(const char* code) {
    std::string src = code ? code : "";
    std::istringstream iss(src);
    std::ostringstream out;
    std::string line;
    int indent = 0;
    while (std::getline(iss, line)) {
        while (!line.empty() && (line.back() == ' ' || line.back() == '\t' || line.back() == '\r')) line.pop_back();
        size_t first = line.find_first_not_of(" \t");
        std::string trimmed = (first == std::string::npos) ? "" : line.substr(first);
        if (trimmed.empty()) {
            out << "\n";
            continue;
        }
        if (trimmed.rfind("}", 0) == 0 || trimmed == "end") indent = std::max(0, indent - 1);
        out << std::string(static_cast<size_t>(indent) * 4, ' ') << trimmed << "\n";
        if (trimmed.back() == '{' || trimmed.back() == ':') indent++;
    }
    global_out_buf() = out.str();
    return global_out_buf().c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_invis_encode_hex(const char* code, const char* target_ui) {
    std::string src = code ? code : "";
    std::string tgt = (target_ui && *target_ui) ? target_ui : "shine_ui";
    UIProfileSpecs specs = resolve_ui_profile(tgt);
    std::string canonical = InvisBinaryCompiler::build_canonical_source(src, specs);
    auto bin = InvisBinaryCompiler::encode_lpbn(canonical, specs, 0x0001);
    InvisBinaryInfo info;
    InvisBinaryCompiler::decode_lpbn(bin.data(), bin.size(), nullptr, &info);

    static const char* hex = "0123456789abcdef";
    std::string hex_str;
    hex_str.reserve(bin.size() * 2);
    for (uint8_t b : bin) {
        hex_str.push_back(hex[(b >> 4) & 0xF]);
        hex_str.push_back(hex[b & 0xF]);
    }

    std::ostringstream ss;
    ss << "{\"valid\":" << (info.valid ? "true" : "false")
       << ",\"format\":\"LPBN v3.0A\""
       << ",\"target\":\"" << LoopingStageRuntime::escape_json(info.target_ui) << "\""
       << ",\"sha256\":\"" << info.sha256_hex << "\""
       << ",\"byteLength\":" << bin.size()
       << ",\"hex\":\"" << hex_str << "\"}";
    global_out_buf() = ss.str();
    return global_out_buf().c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_bench() {
    auto t0 = std::chrono::high_resolution_clock::now();
    Interpreter bvm;
    {
        StreamCapture cap;
        bvm.execute_code(
            "fn compute_metric(x) => (x * 3 + 7) % 97\n"
            "mut acc = 0\n"
            "for (i in 1..=2500) {\n"
            "    acc += compute_metric(i)\n"
            "}\n"
            "val digest = crypto.sha256($\"bench:{acc}\")\n"
        );
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    std::ostringstream ss;
    ss << "{\"iterations\":2500,\"ms\":" << ms
       << ",\"acc\":" << bvm.variables["acc"].as_int()
       << ",\"sha256\":\"" << bvm.variables["digest"].as_string() << "\"}";
    global_out_buf() = ss.str();
    return global_out_buf().c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_run_selftest() {
    auto t0 = std::chrono::high_resolution_clock::now();
    int passed = 0, total = 0;
    std::vector<std::string> names;
    std::vector<bool> results;

    auto check = [&](const std::string& label, bool cond) {
        total++;
        if (cond) passed++;
        names.push_back(label);
        results.push_back(cond);
    };

    StreamCapture cap;
    {
        Interpreter vm;
        vm.execute_code("let a = 15\nmut b = 25\nval c = a + b\nd := 10\nd++\nfn add(x,y) => x + y\nval r = add(c, d)");
        check("Core Language & Arrow Functions", vm.variables["r"].as_int() == 51);
    }
    {
        Interpreter vm;
        vm.execute_code("val p = 64 |> math.sqrt\nval s = \"  coki  \".trim().upper()");
        check("Pipelines (|>) & Dot Methods", vm.variables["p"].as_int() == 8 && vm.variables["s"].as_string() == "COKI");
    }
    {
        Interpreter vm;
        vm.execute_code("mut out_r = \"\"\nmatch 95 {\n    90..=100 => out_r = \"S\"\n    _ => out_r = \"A\"\n}\nval fb = nil \?\? \"OK\"");
        check("Pattern Matching & Null Coalescing", vm.variables["out_r"].as_string() == "S" && vm.variables["fb"].as_string() == "OK");
    }
    {
        Interpreter vm;
        vm.execute_code("import csid\nimport csms\nval enc = csms.encrypt(\"wasm_room\", \"Hola WASM\")\nval dec = csms.decrypt(\"wasm_room\", enc)\nval url = csid.login_url()");
        check("CSID PKCE & CSMS E2EE Crypto", vm.variables["dec"].as_string() == "Hola WASM" && vm.variables["url"].as_string().find("code_challenge_method=S256") != std::string::npos);
    }
    {
        Interpreter vm;
        vm.execute_code(
            "define game3d \"Wasm3D\" version 3.0:\n"
            "scene3d.world(name: \"WasmArena\", size: (120, 60, 120), sky: \"cyber_night\", fog: 0.01, grid: true)\n"
            "spawn3d.player(\"Pilot\", at: (0, 2, 0), speed: 20)\n"
            "spawn3d.box(at: (0, 0, 12), size: (8, 1, 8), color: \"#6366f1\")\n"
            "spawn3d.crystal(at: (0, 3, 12), points: 200)\n"
            "val hit = physics3d.raycast_scene([0, 3, 0], [0, 0, 1])\n"
            "val h_ok = hit[\"hit\"]\n"
        );
        std::vector<uint8_t> rgba;
        vm.current_scene3d.render_rgba(rgba, 96, 64);
        check("Looping3D Z-Buffer RGBA & Raycast", vm.current_scene3d.active && vm.variables["h_ok"].is_truthy() && rgba.size() == 96u * 64u * 4u);
    }
    {
        Interpreter vm;
        vm.execute_code(
            "use \"csharp\"\n"
            "use \"loopize++\"\n"
            "cs! { public class DroneCS : MonoBehaviour { public float Power = 40.0f; public void Update(float dt) { Power += dt * 10.0f; LoopingBridge.Set(\"cs_pow\", Power); } } }\n"
            "csharp.new(\"DroneCS\", \"d1\", \"Drone1\")\n"
            "csharp.step(1.0)\n"
            "val c1 = loopize.combo_hit(100)\n"
        );
        check("C# Interop & loopize++ ECS", vm.variables["cs_pow"].as_number() >= 49.0 && vm.variables["c1"].as_number() == 100.0);
    }
    {
        Interpreter vm;
        vm.execute_code(
            "define game \"Wasm2D\" version 1.1:\n"
            "spawn.player(name: \"Hero\", at: (100, 320), speed: 280, jump: 440, health: 100)\n"
            "spawn.coin(at: (105, 325), points: 150)\n"
        );
        vm.stage.step(0.016, &vm.current_scene3d);
        check("Stage2D Physics & Collision Engine", vm.stage.score == 150 && vm.stage.get_player_2d() != nullptr);
    }

    auto t1 = std::chrono::high_resolution_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    std::ostringstream ss;
    ss << "{\"passed\":" << passed << ",\"total\":" << total << ",\"elapsedMs\":" << ms << ",\"tests\":[";
    for (size_t i = 0; i < names.size(); ++i) {
        if (i > 0) ss << ",";
        ss << "{\"name\":\"" << LoopingStageRuntime::escape_json(names[i]) << "\",\"passed\":" << (results[i] ? "true" : "false") << "}";
    }
    ss << "]}";
    global_out_buf() = ss.str();
    return global_out_buf().c_str();
}

EMSCRIPTEN_KEEPALIVE
const char* lp_version_json() {
    Interpreter vm;
    std::ostringstream ss;
    ss << "{\"engine\":\"Looping\",\"version\":\"" << vm.engine_version
       << "\",\"semver\":\"" << vm.semver
       << "\",\"arch\":\"" << vm.arch_version
       << "\",\"channel\":\"" << vm.channel
       << "\",\"runtime\":\"C++17 WebAssembly (LoopingWasm)\"}";
    global_out_buf() = ss.str();
    return global_out_buf().c_str();
}

} // extern "C"
