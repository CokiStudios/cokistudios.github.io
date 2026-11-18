#pragma once

#include <string>
#include <vector>
#include <array>
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>

#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <commdlg.h>
#ifdef DrawText
#undef DrawText
#endif
#include <d3d11.h>
#include <dxgi.h>
#include <d2d1.h>
#include <dwrite.h>
#include <d3dcompiler.h>
#include <mutex>
#include <memory>
#include <thread>
#include <chrono>
#include <ctime>
#include <atomic>
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#endif

namespace looping {

struct DxCardSpec {
    std::string title;
    std::string text;
    std::string badge;
    std::string icon;
    double x = 0;
    double y = 0;
    double width = 240;
    double height = 150;
};

struct DxButtonSpec {
    std::string text;
    std::string action;
    std::string snippet;
    double x = 0;
    double y = 0;
    double width = 150;
    double height = 42;
};

struct DxInputSpec {
    std::string placeholder;
    std::string binding;
    std::string value;
    double x = 0;
    double y = 0;
    double width = 220;
    double height = 40;
};

struct DxSliderSpec {
    std::string label;
    std::string binding;
    double min_val = 0;
    double max_val = 100;
    double current_val = 50;
};

struct DxToggleSpec {
    std::string label;
    std::string binding;
    bool is_checked = false;
};

struct DxProgressSpec {
    std::string label;
    std::string binding;
    double progress = 0;
};

struct DxToneSpec {
    double freq_hz = 440;
    double duration_ms = 80;
};

struct DxEntity3DSpec {
    std::string type;
    std::string name;
    std::string color = "#38bdf8";
    std::string axis = "x";
    double x = 0, y = 0, z = 0;
    double sx = 1.6, sy = 1.6, sz = 1.6;
    double scx = 1.0, scy = 1.0, scz = 1.0;
    double radius = 1.0;
    double speed = 8.0;
    double min_pos = -5.0, max_pos = 5.0;
    double rot_y = 0.0;
    double dir = 1.0;
    bool collected = false;
    bool alive = true;
    std::vector<std::array<double, 3>> verts;
    std::vector<std::vector<int>> faces;
};

struct DxEntity2DSpec {
    std::string type = "platform";
    std::string name;
    std::string color = "#38bdf8";
    std::string label;
    std::string axis = "x";
    double x = 0, y = 0, w = 32, h = 32;
    double vx = 0, vy = 0;
    double radius = 12;
    double speed = 180;
    double jump_force = 440;
    double power = 650;
    double health = 100;
    double max_health = 100;
    double damage = 35;
    double points = 100;
    double min_pos = 0, max_pos = 0;
    double to_x = 0, to_y = 0;
    double dir = 1.0;
    double spawn_x = 100, spawn_y = 300;
    bool is_player = false;
    bool collected = false;
    bool alive = true;
    bool is_jumping = false;
    bool can_double_jump = true;
    double invuln_timer = 0.0;
    double dash_timer = 0.0;
    double dash_cd = 0.0;
    double shoot_cd = 0.0;
};

struct DirectXWindowSpec {
    std::string app_name = "DynamicWindow";
    std::string title = "Looping DirectX Window";
    std::string theme = "frosted_aqua_a17";
    std::string target_ui = "shine_ui";
    std::string pipeline = "DirectX 11 + Direct2D Hardware Pipeline";
    std::string badge_label = "DirectX 11 • 60 FPS";
    std::string host_exe;
    double width = 850;
    double height = 540;
    int target_fps = 60;

    std::string bg_color = "#0b0f19";
    std::string card_bg = "#151d30";
    std::string card_border = "#22314e";
    std::string primary_color = "#38bdf8";
    std::string accent_color = "#00f5d4";
    std::string btn_bg = "#0284c7";
    std::string btn_fg = "#ffffff";
    std::string log_bg = "#070a12";
    std::string log_fg = "#10b981";

    bool is_3d_mode = false;
    double world_width = 1200;
    double world_height = 480;
    double gravity = 980;
    std::string scenario_name = "Holo Cyber Stage";
    std::string scenario_accent = "#38bdf8";

    std::vector<DxCardSpec> cards;
    std::vector<DxButtonSpec> buttons;
    std::vector<DxInputSpec> inputs;
    std::vector<DxSliderSpec> sliders;
    std::vector<DxToggleSpec> toggles;
    std::vector<DxProgressSpec> progress_bars;
    std::vector<DxToneSpec> tones;
    std::vector<DxEntity3DSpec> entities_3d;
    std::vector<DxEntity2DSpec> entities_2d;
};

inline std::string dxwin_escape(const std::string& in) {
    std::string out;
    out.reserve(in.size());
    for (char c : in) {
        if (c == '\\') out += "\\\\";
        else if (c == '|') out += "\\p";
        else if (c == '\n') out += "\\n";
        else if (c == '\r') out += "\\r";
        else if (c == '\t') out += "\\t";
        else out += c;
    }
    return out;
}

inline std::string dxwin_unescape(const std::string& in) {
    std::string out;
    out.reserve(in.size());
    for (size_t i = 0; i < in.size(); ++i) {
        if (in[i] == '\\' && i + 1 < in.size()) {
            char n = in[++i];
            if (n == '\\') out += '\\';
            else if (n == 'p') out += '|';
            else if (n == 'n') out += '\n';
            else if (n == 'r') out += '\r';
            else if (n == 't') out += '\t';
            else out += n;
        } else {
            out += in[i];
        }
    }
    return out;
}

inline std::vector<std::string> dxwin_split_fields(const std::string& line) {
    std::vector<std::string> fields;
    std::string cur;
    for (size_t i = 0; i < line.size(); ++i) {
        if (line[i] == '\\' && i + 1 < line.size()) {
            cur += line[i];
            cur += line[i + 1];
            ++i;
        } else if (line[i] == '|') {
            fields.push_back(dxwin_unescape(cur));
            cur.clear();
        } else {
            cur += line[i];
        }
    }
    fields.push_back(dxwin_unescape(cur));
    return fields;
}

inline bool save_dxwin_file(const std::string& path, const DirectXWindowSpec& spec) {
    std::ofstream out(path, std::ios::binary);
    if (!out.is_open()) return false;

    out << "# LOOPING_DXWIN_V1\n";
    auto meta = [&](const char* k, const std::string& v) {
        out << "META|" << k << "|" << dxwin_escape(v) << "\n";
    };
    meta("app_name", spec.app_name);
    meta("title", spec.title);
    meta("theme", spec.theme);
    meta("target_ui", spec.target_ui);
    meta("pipeline", spec.pipeline);
    meta("badge_label", spec.badge_label);
    meta("host_exe", spec.host_exe);
    meta("width", std::to_string(spec.width));
    meta("height", std::to_string(spec.height));
    meta("target_fps", std::to_string(spec.target_fps));
    meta("bg_color", spec.bg_color);
    meta("card_bg", spec.card_bg);
    meta("card_border", spec.card_border);
    meta("primary_color", spec.primary_color);
    meta("accent_color", spec.accent_color);
    meta("btn_bg", spec.btn_bg);
    meta("btn_fg", spec.btn_fg);
    meta("log_bg", spec.log_bg);
    meta("log_fg", spec.log_fg);
    meta("is_3d_mode", spec.is_3d_mode ? "1" : "0");
    meta("world_width", std::to_string(spec.world_width));
    meta("world_height", std::to_string(spec.world_height));
    meta("gravity", std::to_string(spec.gravity));
    meta("scenario_name", spec.scenario_name);
    meta("scenario_accent", spec.scenario_accent);

    for (const auto& c : spec.cards) {
        out << "CARD|" << dxwin_escape(c.title) << "|" << dxwin_escape(c.text) << "|"
            << dxwin_escape(c.badge) << "|" << dxwin_escape(c.icon) << "|"
            << c.x << "|" << c.y << "|" << c.width << "|" << c.height << "\n";
    }
    for (const auto& b : spec.buttons) {
        out << "BTN|" << dxwin_escape(b.text) << "|" << dxwin_escape(b.action) << "|"
            << dxwin_escape(b.snippet) << "|" << b.x << "|" << b.y << "|" << b.width << "|" << b.height << "\n";
    }
    for (const auto& inp : spec.inputs) {
        out << "INP|" << dxwin_escape(inp.placeholder) << "|" << dxwin_escape(inp.binding) << "|"
            << dxwin_escape(inp.value) << "|" << inp.x << "|" << inp.y << "|" << inp.width << "|" << inp.height << "\n";
    }
    for (const auto& sl : spec.sliders) {
        out << "SLD|" << dxwin_escape(sl.label) << "|" << dxwin_escape(sl.binding) << "|"
            << sl.min_val << "|" << sl.max_val << "|" << sl.current_val << "\n";
    }
    for (const auto& tg : spec.toggles) {
        out << "TGL|" << dxwin_escape(tg.label) << "|" << dxwin_escape(tg.binding) << "|"
            << (tg.is_checked ? "1" : "0") << "\n";
    }
    for (const auto& pr : spec.progress_bars) {
        out << "PRG|" << dxwin_escape(pr.label) << "|" << dxwin_escape(pr.binding) << "|"
            << pr.progress << "\n";
    }
    for (const auto& tn : spec.tones) {
        out << "TONE|" << tn.freq_hz << "|" << tn.duration_ms << "\n";
    }
    for (const auto& e : spec.entities_3d) {
        std::ostringstream vs, fs;
        for (size_t i = 0; i < e.verts.size(); ++i) {
            if (i > 0) vs << ";";
            vs << e.verts[i][0] << "," << e.verts[i][1] << "," << e.verts[i][2];
        }
        for (size_t i = 0; i < e.faces.size(); ++i) {
            if (i > 0) fs << ";";
            for (size_t j = 0; j < e.faces[i].size(); ++j) {
                if (j > 0) fs << ",";
                fs << e.faces[i][j];
            }
        }
        out << "E3D|" << dxwin_escape(e.type) << "|" << dxwin_escape(e.name) << "|"
            << dxwin_escape(e.color) << "|" << dxwin_escape(e.axis) << "|"
            << e.x << "|" << e.y << "|" << e.z << "|"
            << e.sx << "|" << e.sy << "|" << e.sz << "|"
            << e.scx << "|" << e.scy << "|" << e.scz << "|"
            << e.radius << "|" << e.speed << "|" << e.min_pos << "|" << e.max_pos << "|"
            << e.rot_y << "|" << vs.str() << "|" << fs.str() << "\n";
    }
    for (const auto& e : spec.entities_2d) {
        out << "E2D|" << dxwin_escape(e.type) << "|" << dxwin_escape(e.name) << "|"
            << dxwin_escape(e.color) << "|" << dxwin_escape(e.label) << "|" << dxwin_escape(e.axis) << "|"
            << e.x << "|" << e.y << "|" << e.w << "|" << e.h << "|" << e.radius << "|"
            << e.speed << "|" << e.jump_force << "|" << e.power << "|" << e.health << "|"
            << e.damage << "|" << e.points << "|" << e.min_pos << "|" << e.max_pos << "|"
            << e.to_x << "|" << e.to_y << "|" << (e.is_player ? "1" : "0") << "\n";
    }
    return true;
}

inline bool load_dxwin_file(const std::string& path, DirectXWindowSpec& spec) {
    std::ifstream in(path, std::ios::binary);
    if (!in.is_open()) return false;
    spec = DirectXWindowSpec{};
    auto to_d = [](const std::string& s, double def = 0.0) {
        try { return s.empty() ? def : std::stod(s); } catch (...) { return def; }
    };
    auto to_i = [](const std::string& s, int def = 0) {
        try { return s.empty() ? def : std::stoi(s); } catch (...) { return def; }
    };

    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty() || line[0] == '#') continue;
        auto f = dxwin_split_fields(line);
        if (f.empty()) continue;

        if (f[0] == "META" && f.size() >= 3) {
            const std::string& k = f[1];
            const std::string& v = f[2];
            if (k == "app_name") spec.app_name = v;
            else if (k == "title") spec.title = v;
            else if (k == "theme") spec.theme = v;
            else if (k == "target_ui") spec.target_ui = v;
            else if (k == "pipeline") spec.pipeline = v;
            else if (k == "badge_label") spec.badge_label = v;
            else if (k == "host_exe") spec.host_exe = v;
            else if (k == "width") spec.width = to_d(v, 850);
            else if (k == "height") spec.height = to_d(v, 540);
            else if (k == "target_fps") spec.target_fps = to_i(v, 60);
            else if (k == "bg_color") spec.bg_color = v;
            else if (k == "card_bg") spec.card_bg = v;
            else if (k == "card_border") spec.card_border = v;
            else if (k == "primary_color") spec.primary_color = v;
            else if (k == "accent_color") spec.accent_color = v;
            else if (k == "btn_bg") spec.btn_bg = v;
            else if (k == "btn_fg") spec.btn_fg = v;
            else if (k == "log_bg") spec.log_bg = v;
            else if (k == "log_fg") spec.log_fg = v;
            else if (k == "is_3d_mode") spec.is_3d_mode = (v == "1");
            else if (k == "world_width") spec.world_width = to_d(v, 1200);
            else if (k == "world_height") spec.world_height = to_d(v, 480);
            else if (k == "gravity") spec.gravity = to_d(v, 980);
            else if (k == "scenario_name") spec.scenario_name = v;
            else if (k == "scenario_accent") spec.scenario_accent = v;
        } else if (f[0] == "CARD" && f.size() >= 9) {
            DxCardSpec c;
            c.title = f[1]; c.text = f[2]; c.badge = f[3]; c.icon = f[4];
            c.x = to_d(f[5]); c.y = to_d(f[6]); c.width = to_d(f[7], 240); c.height = to_d(f[8], 150);
            spec.cards.push_back(std::move(c));
        } else if (f[0] == "BTN" && f.size() >= 8) {
            DxButtonSpec b;
            b.text = f[1]; b.action = f[2]; b.snippet = f[3];
            b.x = to_d(f[4]); b.y = to_d(f[5]); b.width = to_d(f[6], 150); b.height = to_d(f[7], 42);
            spec.buttons.push_back(std::move(b));
        } else if (f[0] == "INP" && f.size() >= 8) {
            DxInputSpec inp;
            inp.placeholder = f[1]; inp.binding = f[2]; inp.value = f[3];
            inp.x = to_d(f[4]); inp.y = to_d(f[5]); inp.width = to_d(f[6], 220); inp.height = to_d(f[7], 40);
            spec.inputs.push_back(std::move(inp));
        } else if (f[0] == "SLD" && f.size() >= 6) {
            DxSliderSpec sl;
            sl.label = f[1]; sl.binding = f[2];
            sl.min_val = to_d(f[3], 0); sl.max_val = to_d(f[4], 100); sl.current_val = to_d(f[5], 50);
            spec.sliders.push_back(std::move(sl));
        } else if (f[0] == "TGL" && f.size() >= 4) {
            DxToggleSpec tg;
            tg.label = f[1]; tg.binding = f[2]; tg.is_checked = (f[3] == "1");
            spec.toggles.push_back(std::move(tg));
        } else if (f[0] == "PRG" && f.size() >= 4) {
            DxProgressSpec pr;
            pr.label = f[1]; pr.binding = f[2]; pr.progress = to_d(f[3], 0);
            spec.progress_bars.push_back(std::move(pr));
        } else if (f[0] == "TONE" && f.size() >= 3) {
            spec.tones.push_back({to_d(f[1], 440), to_d(f[2], 80)});
        } else if (f[0] == "E3D" && f.size() >= 21) {
            DxEntity3DSpec e;
            e.type = f[1]; e.name = f[2]; e.color = f[3]; e.axis = f[4];
            e.x = to_d(f[5]); e.y = to_d(f[6]); e.z = to_d(f[7]);
            e.sx = to_d(f[8], 1.6); e.sy = to_d(f[9], 1.6); e.sz = to_d(f[10], 1.6);
            e.scx = to_d(f[11], 1.0); e.scy = to_d(f[12], 1.0); e.scz = to_d(f[13], 1.0);
            e.radius = to_d(f[14], 1.0); e.speed = to_d(f[15], 8.0);
            e.min_pos = to_d(f[16], -5.0); e.max_pos = to_d(f[17], 5.0);
            e.rot_y = to_d(f[18], 0.0);
            if (!f[19].empty()) {
                std::istringstream vss(f[19]);
                std::string tok;
                while (std::getline(vss, tok, ';')) {
                    std::istringstream cs(tok);
                    std::string x_s, y_s, z_s;
                    if (std::getline(cs, x_s, ',') && std::getline(cs, y_s, ',') && std::getline(cs, z_s, ',')) {
                        e.verts.push_back({to_d(x_s), to_d(y_s), to_d(z_s)});
                    }
                }
            }
            if (!f[20].empty()) {
                std::istringstream fss(f[20]);
                std::string tok;
                while (std::getline(fss, tok, ';')) {
                    std::vector<int> face;
                    std::istringstream cs(tok);
                    std::string idx_s;
                    while (std::getline(cs, idx_s, ',')) {
                        face.push_back(to_i(idx_s));
                    }
                    if (face.size() >= 3) e.faces.push_back(std::move(face));
                }
            }
            spec.entities_3d.push_back(std::move(e));
        } else if (f[0] == "E2D" && f.size() >= 22) {
            DxEntity2DSpec e;
            e.type = f[1]; e.name = f[2]; e.color = f[3]; e.label = f[4]; e.axis = f[5];
            e.x = to_d(f[6]); e.y = to_d(f[7]); e.w = to_d(f[8], 32); e.h = to_d(f[9], 32);
            e.radius = to_d(f[10], 12); e.speed = to_d(f[11], 180); e.jump_force = to_d(f[12], 440);
            e.power = to_d(f[13], 650); e.health = to_d(f[14], 100); e.max_health = std::max(1.0, e.health);
            e.damage = to_d(f[15], 35); e.points = to_d(f[16], 100);
            e.min_pos = to_d(f[17]); e.max_pos = to_d(f[18]);
            e.to_x = to_d(f[19]); e.to_y = to_d(f[20]);
            e.is_player = (f[21] == "1");
            e.spawn_x = e.x;
            e.spawn_y = e.y;
            spec.entities_2d.push_back(std::move(e));
        }
    }
    return true;
}

#if defined(_WIN32) && !defined(__EMSCRIPTEN__)

namespace dx_native {

template <typename T>
struct ComPtr {
    T* ptr = nullptr;
    ComPtr() = default;
    ~ComPtr() { reset(); }
    ComPtr(const ComPtr&) = delete;
    ComPtr& operator=(const ComPtr&) = delete;
    ComPtr(ComPtr&& o) noexcept : ptr(o.ptr) { o.ptr = nullptr; }
    ComPtr& operator=(ComPtr&& o) noexcept {
        if (this != &o) { reset(); ptr = o.ptr; o.ptr = nullptr; }
        return *this;
    }
    void reset(T* p = nullptr) {
        if (ptr) ptr->Release();
        ptr = p;
    }
    T* get() const { return ptr; }
    T* operator->() const { return ptr; }
    T** put() { reset(); return &ptr; }
    explicit operator bool() const { return ptr != nullptr; }
};

static const GUID kIID_ID3D11Texture2D = {0x6f15aaf2, 0xd208, 0x4e89, {0x9a, 0xb4, 0x48, 0x95, 0x35, 0xd3, 0x4f, 0x9c}};
static const GUID kIID_IDXGISurface   = {0xcafcb56c, 0x6ac3, 0x4889, {0xbf, 0x47, 0x9e, 0x23, 0xbb, 0xd2, 0x60, 0xec}};
static const GUID kIID_IDXGIDevice    = {0x54ec77fa, 0x1377, 0x44e6, {0x8c, 0x32, 0x88, 0xfd, 0x5f, 0x44, 0xc8, 0x4c}};
static const GUID kIID_ID2D1Factory   = {0x06152247, 0x6f50, 0x465a, {0x92, 0x45, 0x11, 0x8b, 0xfd, 0x3b, 0x60, 0x07}};
static const GUID kIID_IDWriteFactory = {0xb859ee5a, 0xd838, 0x4b5b, {0xa2, 0xe8, 0x1a, 0xdc, 0x7d, 0x93, 0xdb, 0x48}};

struct DxApi {
    typedef HRESULT (WINAPI *PFN_D3D11CreateDeviceAndSwapChain)(
        IDXGIAdapter*, D3D_DRIVER_TYPE, HMODULE, UINT,
        const D3D_FEATURE_LEVEL*, UINT, UINT,
        const DXGI_SWAP_CHAIN_DESC*, IDXGISwapChain**, ID3D11Device**,
        D3D_FEATURE_LEVEL*, ID3D11DeviceContext**);
    typedef HRESULT (WINAPI *PFN_D2D1CreateFactory)(
        D2D1_FACTORY_TYPE, REFIID, const D2D1_FACTORY_OPTIONS*, void**);
    typedef HRESULT (WINAPI *PFN_DWriteCreateFactory)(
        DWRITE_FACTORY_TYPE, REFIID, IUnknown**);
    typedef HRESULT (WINAPI *PFN_D3DCompile)(
        LPCVOID, SIZE_T, LPCSTR, const D3D_SHADER_MACRO*, ID3DInclude*,
        LPCSTR, LPCSTR, UINT, UINT, ID3DBlob**, ID3DBlob**);
    typedef BOOL (WINAPI *PFN_PlaySoundA)(LPCSTR, HMODULE, DWORD);
    typedef HRESULT (WINAPI *PFN_DwmSetWindowAttribute)(HWND, DWORD, LPCVOID, DWORD);
    typedef BOOL (WINAPI *PFN_SetProcessDPIAware)();

    HMODULE hD3D11 = nullptr;
    HMODULE hD2D1 = nullptr;
    HMODULE hDWrite = nullptr;
    HMODULE hD3DCompiler = nullptr;
    HMODULE hWinMM = nullptr;
    HMODULE hDwmApi = nullptr;
    HMODULE hUser32 = nullptr;

    PFN_D3D11CreateDeviceAndSwapChain pD3D11CreateDeviceAndSwapChain = nullptr;
    PFN_D2D1CreateFactory pD2D1CreateFactory = nullptr;
    PFN_DWriteCreateFactory pDWriteCreateFactory = nullptr;
    PFN_D3DCompile pD3DCompile = nullptr;
    PFN_PlaySoundA pPlaySoundA = nullptr;
    PFN_DwmSetWindowAttribute pDwmSetWindowAttribute = nullptr;
    PFN_SetProcessDPIAware pSetProcessDPIAware = nullptr;

    bool loaded = false;

    bool init() {
        if (loaded) return true;
        hD3D11 = LoadLibraryA("d3d11.dll");
        hD2D1 = LoadLibraryA("d2d1.dll");
        hDWrite = LoadLibraryA("dwrite.dll");
        hD3DCompiler = LoadLibraryA("d3dcompiler_47.dll");
        if (!hD3DCompiler) hD3DCompiler = LoadLibraryA("d3dcompiler_46.dll");
        if (!hD3DCompiler) hD3DCompiler = LoadLibraryA("d3dcompiler_43.dll");
        hWinMM = LoadLibraryA("winmm.dll");
        hDwmApi = LoadLibraryA("dwmapi.dll");
        hUser32 = GetModuleHandleA("user32.dll");

        if (!hD3D11 || !hD2D1 || !hDWrite) return false;

        pD3D11CreateDeviceAndSwapChain = reinterpret_cast<PFN_D3D11CreateDeviceAndSwapChain>(
            GetProcAddress(hD3D11, "D3D11CreateDeviceAndSwapChain"));
        pD2D1CreateFactory = reinterpret_cast<PFN_D2D1CreateFactory>(
            GetProcAddress(hD2D1, "D2D1CreateFactory"));
        pDWriteCreateFactory = reinterpret_cast<PFN_DWriteCreateFactory>(
            GetProcAddress(hDWrite, "DWriteCreateFactory"));
        if (hD3DCompiler) {
            pD3DCompile = reinterpret_cast<PFN_D3DCompile>(GetProcAddress(hD3DCompiler, "D3DCompile"));
        }
        if (hWinMM) {
            pPlaySoundA = reinterpret_cast<PFN_PlaySoundA>(GetProcAddress(hWinMM, "PlaySoundA"));
        }
        if (hDwmApi) {
            pDwmSetWindowAttribute = reinterpret_cast<PFN_DwmSetWindowAttribute>(
                GetProcAddress(hDwmApi, "DwmSetWindowAttribute"));
        }
        if (hUser32) {
            pSetProcessDPIAware = reinterpret_cast<PFN_SetProcessDPIAware>(
                GetProcAddress(hUser32, "SetProcessDPIAware"));
        }
        loaded = (pD3D11CreateDeviceAndSwapChain && pD2D1CreateFactory && pDWriteCreateFactory);
        return loaded;
    }

    ~DxApi() {
        if (hD3DCompiler) FreeLibrary(hD3DCompiler);
        if (hDwmApi) FreeLibrary(hDwmApi);
        if (hWinMM) FreeLibrary(hWinMM);
        if (hDWrite) FreeLibrary(hDWrite);
        if (hD2D1) FreeLibrary(hD2D1);
        if (hD3D11) FreeLibrary(hD3D11);
    }
};

inline std::wstring utf8_to_wide(const std::string& s) {
    if (s.empty()) return L"";
    int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), static_cast<int>(s.size()), nullptr, 0);
    if (n <= 0) return std::wstring(s.begin(), s.end());
    std::wstring w(static_cast<size_t>(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), static_cast<int>(s.size()), &w[0], n);
    return w;
}

inline D2D1_COLOR_F hex_to_d2d(const std::string& hex, float alpha = 1.0f) {
    unsigned int r = 56, g = 189, b = 248;
    std::string h = hex;
    if (!h.empty() && h[0] == '#') h.erase(0, 1);
    if (h.size() == 3) {
        h = std::string{h[0], h[0], h[1], h[1], h[2], h[2]};
    }
    if (h.size() >= 6) {
        try {
            unsigned int v = static_cast<unsigned int>(std::stoul(h.substr(0, 6), nullptr, 16));
            r = (v >> 16) & 0xFF;
            g = (v >> 8) & 0xFF;
            b = v & 0xFF;
        } catch (...) {}
    }
    return D2D1_COLOR_F{r / 255.0f, g / 255.0f, b / 255.0f, alpha};
}

struct Vec3f {
    float x, y, z;
};

struct Mat4f {
    float m[16]{};
    static Mat4f identity() {
        Mat4f r;
        r.m[0] = r.m[5] = r.m[10] = r.m[15] = 1.0f;
        return r;
    }
    static Mat4f mul(const Mat4f& a, const Mat4f& b) {
        Mat4f r;
        for (int row = 0; row < 4; ++row) {
            for (int col = 0; col < 4; ++col) {
                float s = 0.0f;
                for (int k = 0; k < 4; ++k) s += a.m[row * 4 + k] * b.m[k * 4 + col];
                r.m[row * 4 + col] = s;
            }
        }
        return r;
    }
    static Mat4f trs(Vec3f pos, float rot_y_rad, Vec3f scale) {
        float c = std::cos(rot_y_rad);
        float s = std::sin(rot_y_rad);
        Mat4f r = identity();
        r.m[0] = c * scale.x;  r.m[2] = s * scale.z;  r.m[3] = pos.x;
        r.m[5] = scale.y;      r.m[7] = pos.y;
        r.m[8] = -s * scale.x; r.m[10] = c * scale.z; r.m[11] = pos.z;
        return r;
    }
    static Mat4f look_at_dx(Vec3f eye, Vec3f target, Vec3f up_hint = {0, 1, 0}) {
        auto norm = [](Vec3f v) -> Vec3f {
            float l = std::sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
            return l > 1e-6f ? Vec3f{v.x / l, v.y / l, v.z / l} : Vec3f{0, 0, 1};
        };
        auto cross = [](Vec3f a, Vec3f b) -> Vec3f {
            return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
        };
        auto dot = [](Vec3f a, Vec3f b) -> float {
            return a.x * b.x + a.y * b.y + a.z * b.z;
        };
        Vec3f fwd = norm({target.x - eye.x, target.y - eye.y, target.z - eye.z});
        Vec3f right = norm(cross(up_hint, fwd));
        if (right.x * right.x + right.y * right.y + right.z * right.z < 1e-5f) {
            right = {1, 0, 0};
        }
        Vec3f up = cross(fwd, right);
        Mat4f r = identity();
        r.m[0] = right.x;   r.m[1] = right.y;   r.m[2] = right.z;   r.m[3] = -dot(right, eye);
        r.m[4] = up.x;      r.m[5] = up.y;      r.m[6] = up.z;      r.m[7] = -dot(up, eye);
        r.m[8] = fwd.x;     r.m[9] = fwd.y;     r.m[10] = fwd.z;    r.m[11] = -dot(fwd, eye);
        return r;
    }
    static Mat4f perspective_dx(float fov_deg, float aspect, float near_z, float far_z) {
        Mat4f r{};
        float f = 1.0f / std::tan(fov_deg * 3.14159265f / 360.0f);
        if (aspect < 1e-4f) aspect = 1.0f;
        float q = far_z / (far_z - near_z);
        r.m[0] = f / aspect;
        r.m[5] = f;
        r.m[10] = q;
        r.m[11] = -near_z * q;
        r.m[14] = 1.0f;
        return r;
    }
};

struct Vertex3D {
    float x, y, z;
    float nx, ny, nz;
};

struct SceneCBData {
    float mvp[16];
    float world[16];
    float color[4];
    float light_dir[4];
    float params[4];
};

struct GpuMesh {
    ComPtr<ID3D11Buffer> vb;
    UINT vertex_count = 0;
};

struct LogEntry {
    std::string text;
    int kind = 0; // 0=success, 1=action, 2=snippet, 3=dx
};

struct Stage2DBullet {
    double x, y, vx, vy, life;
    bool from_player;
    std::string color;
};

struct Stage2DParticle {
    double x, y, vx, vy, life, max_life, size;
    std::string color;
};

class DirectXWindowApp {
public:
    DirectXWindowSpec spec;
    DxApi api;
    HWND hwnd = nullptr;

    ComPtr<ID3D11Device> d3d_device;
    ComPtr<ID3D11DeviceContext> d3d_ctx;
    ComPtr<IDXGISwapChain> swapchain;
    ComPtr<ID3D11RenderTargetView> rtv;
    ComPtr<ID3D11Texture2D> depth_tex;
    ComPtr<ID3D11DepthStencilView> dsv;
    ComPtr<ID3D11DepthStencilState> depth_state;
    ComPtr<ID3D11RasterizerState> rast_state;
    ComPtr<ID3D11VertexShader> vs;
    ComPtr<ID3D11PixelShader> ps;
    ComPtr<ID3D11InputLayout> input_layout;
    ComPtr<ID3D11Buffer> cb_scene;

    GpuMesh mesh_box;
    GpuMesh mesh_crystal;
    GpuMesh mesh_ring;
    GpuMesh mesh_grid;
    std::vector<GpuMesh> custom_meshes;
    bool has_3d_pipeline = false;
    std::string gpu_name = "DirectX 11";

    ComPtr<ID2D1Factory> d2d_factory;
    ComPtr<ID2D1RenderTarget> d2d_rt;
    ComPtr<ID2D1SolidColorBrush> brush;
    ComPtr<IDWriteFactory> dwrite_factory;
    ComPtr<IDWriteTextFormat> fmt_title;
    ComPtr<IDWriteTextFormat> fmt_badge;
    ComPtr<IDWriteTextFormat> fmt_card_title;
    ComPtr<IDWriteTextFormat> fmt_body;
    ComPtr<IDWriteTextFormat> fmt_btn;
    ComPtr<IDWriteTextFormat> fmt_mono;

    int client_w = 850;
    int client_h = 540;
    bool needs_resize = false;
    bool running = true;

    // Interactive state
    bool keys[256]{};
    bool is_key_down(int vk) const {
        if (vk < 0 || vk >= 256) return false;
        if (keys[vk]) return true;
        if (hwnd && GetForegroundWindow() == hwnd) {
            return (GetAsyncKeyState(vk) & 0x8000) != 0;
        }
        return false;
    }
    int mouse_x = -1, mouse_y = -1;
    bool mouse_down = false;
    bool dragging_3d = false;
    int active_slider = -1;
    int active_input = -1;
    int hover_btn = -1;
    int last_mouse_x = 0, last_mouse_y = 0;
    int log_scroll = 0;

    // 3D Camera & Gameplay
    double cam_yaw = 0.0;
    double cam_pitch = 0.30;
    double cam_dist = 18.0;
    double p3d_vel[3]{0, 0, 0};
    int p3d_jumps = 0;
    int score_3d = 0;

    // 2D Stage Gameplay
    double cam2d_x = 0.0;
    int score_2d = 0;
    int lives_2d = 3;
    std::vector<Stage2DBullet> bullets_2d;
    std::vector<Stage2DParticle> particles_2d;

    // Computed Layout Hitboxes
    D2D1_RECT_F vp_rect{0, 0, 0, 0};
    bool has_viewport = false;
    std::vector<D2D1_RECT_F> card_rects;
    std::vector<D2D1_RECT_F> input_rects;
    std::vector<D2D1_RECT_F> slider_rects;
    std::vector<D2D1_RECT_F> toggle_rects;
    std::vector<D2D1_RECT_F> button_rects;
    D2D1_RECT_F log_rect{0, 0, 0, 0};

    struct AsyncLogQueue {
        std::mutex mtx;
        std::vector<LogEntry> entries;
    };

    std::vector<LogEntry> logs;
    std::shared_ptr<AsyncLogQueue> async_logs = std::make_shared<AsyncLogQueue>();
    std::vector<uint8_t> current_audio_buffer;

    double fps_current = 60.0;
    int fps_frames = 0;
    double fps_timer = 0.0;
    double total_time = 0.0;

    static std::string current_time_str() {
        std::time_t t = std::time(nullptr);
        std::tm tm_val{};
        localtime_s(&tm_val, &t);
        char buf[16];
        std::snprintf(buf, sizeof(buf), "%02d:%02d:%02d", tm_val.tm_hour, tm_val.tm_min, tm_val.tm_sec);
        return std::string(buf);
    }

    void push_log(const std::string& msg, int kind = 0) {
        logs.push_back({"[" + current_time_str() + "] " + msg, kind});
        if (logs.size() > 300) logs.erase(logs.begin());
        log_scroll = 0;
    }

    void push_log_async(const std::string& msg, int kind = 0) {
        std::lock_guard<std::mutex> lk(async_logs->mtx);
        async_logs->entries.push_back({"[" + current_time_str() + "] " + msg, kind});
    }

    void play_tone(double freq_hz, double duration_ms) {
        if (!api.pPlaySoundA) return;
        double f = std::clamp(freq_hz, 80.0, 4000.0);
        double d_ms = std::clamp(duration_ms, 20.0, 1200.0);
        const uint32_t sample_rate = 22050;
        uint32_t num_samples = static_cast<uint32_t>((sample_rate * d_ms) / 1000.0);
        if (num_samples < 64) num_samples = 64;
        uint32_t data_bytes = num_samples * 2;
        uint32_t riff_size = 36 + data_bytes;

        std::vector<uint8_t> wav(44 + data_bytes);
        auto w32 = [&](size_t off, uint32_t v) { std::memcpy(&wav[off], &v, 4); };
        auto w16 = [&](size_t off, uint16_t v) { std::memcpy(&wav[off], &v, 2); };
        std::memcpy(&wav[0], "RIFF", 4);
        w32(4, riff_size);
        std::memcpy(&wav[8], "WAVEfmt ", 8);
        w32(16, 16);
        w16(20, 1); // PCM
        w16(22, 1); // Mono
        w32(24, sample_rate);
        w32(28, sample_rate * 2);
        w16(32, 2);
        w16(34, 16);
        std::memcpy(&wav[36], "data", 4);
        w32(40, data_bytes);

        for (uint32_t i = 0; i < num_samples; ++i) {
            double t = static_cast<double>(i) / sample_rate;
            double env = 1.0;
            double attack = std::min(0.01, (d_ms / 1000.0) * 0.25);
            double release = std::min(0.04, (d_ms / 1000.0) * 0.45);
            if (t < attack) env = t / attack;
            else if (t > (d_ms / 1000.0) - release) {
                env = std::max(0.0, ((d_ms / 1000.0) - t) / release);
            }
            double s = std::sin(2.0 * 3.141592653589793 * f * t) * 0.18 * env;
            int16_t pcm = static_cast<int16_t>(s * 32767.0);
            std::memcpy(&wav[44 + i * 2], &pcm, 2);
        }

        api.pPlaySoundA(nullptr, nullptr, 0);
        current_audio_buffer = std::move(wav);
        api.pPlaySoundA(reinterpret_cast<LPCSTR>(current_audio_buffer.data()), NULL, 0x0004 /*SND_MEMORY*/ | 0x0001 /*SND_ASYNC*/);
    }

    static LRESULT CALLBACK wnd_proc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
        DirectXWindowApp* self = reinterpret_cast<DirectXWindowApp*>(GetWindowLongPtrW(hWnd, GWLP_USERDATA));
        if (msg == WM_NCCREATE) {
            CREATESTRUCTW* cs = reinterpret_cast<CREATESTRUCTW*>(lParam);
            self = reinterpret_cast<DirectXWindowApp*>(cs->lpCreateParams);
            SetWindowLongPtrW(hWnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
            return DefWindowProcW(hWnd, msg, wParam, lParam);
        }
        if (self) return self->handle_msg(hWnd, msg, wParam, lParam);
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    }

    LRESULT handle_msg(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
        switch (msg) {
            case WM_CLOSE:
                running = false;
                DestroyWindow(hWnd);
                return 0;
            case WM_DESTROY:
                running = false;
                PostQuitMessage(0);
                return 0;
            case WM_SIZE:
                client_w = std::max(320, static_cast<int>(LOWORD(lParam)));
                client_h = std::max(240, static_cast<int>(HIWORD(lParam)));
                needs_resize = true;
                return 0;
            case WM_KILLFOCUS:
                std::fill(std::begin(keys), std::end(keys), false);
                return 0;
            case WM_KEYDOWN:
                if (wParam < 256) keys[wParam] = true;
                if (wParam == 'O' && (GetKeyState(VK_CONTROL) & 0x8000) && active_input < 0) {
                    open_obj_file_dialog();
                }
                if (wParam == 'R' && active_input < 0) {
                    if (!spec.entities_2d.empty()) reset_2d_stage();
                    else { cam_yaw = 0.0; cam_pitch = 0.30; cam_dist = 18.0; }
                }
                if (wParam == VK_BACK && active_input >= 0 && active_input < static_cast<int>(spec.inputs.size())) {
                    auto& val = spec.inputs[static_cast<size_t>(active_input)].value;
                    if (!val.empty()) val.pop_back();
                }
                if (wParam == VK_RETURN && active_input >= 0 && active_input < static_cast<int>(spec.inputs.size())) {
                    const auto& inp = spec.inputs[static_cast<size_t>(active_input)];
                    push_log("Input [" + inp.binding + "] = \"" + inp.value + "\"", 1);
                    active_input = -1;
                }
                return 0;
            case WM_KEYUP:
                if (wParam < 256) keys[wParam] = false;
                return 0;
            case WM_CHAR:
                if (active_input >= 0 && active_input < static_cast<int>(spec.inputs.size())) {
                    wchar_t ch = static_cast<wchar_t>(wParam);
                    if (ch >= 32 && ch != 127) {
                        char utf8[8]{};
                        int n = WideCharToMultiByte(CP_UTF8, 0, &ch, 1, utf8, sizeof(utf8) - 1, nullptr, nullptr);
                        if (n > 0) spec.inputs[static_cast<size_t>(active_input)].value.append(utf8, static_cast<size_t>(n));
                    }
                }
                return 0;
            case WM_MOUSEMOVE: {
                mouse_x = static_cast<short>(LOWORD(lParam));
                mouse_y = static_cast<short>(HIWORD(lParam));
                if (dragging_3d) {
                    cam_yaw += (mouse_x - last_mouse_x) * 0.008;
                    cam_pitch = std::clamp(cam_pitch + (mouse_y - last_mouse_y) * 0.006, -0.25, 1.35);
                }
                if (active_slider >= 0 && active_slider < static_cast<int>(slider_rects.size())) {
                    update_slider_from_x(active_slider, static_cast<float>(mouse_x));
                }
                last_mouse_x = mouse_x;
                last_mouse_y = mouse_y;
                update_hover();
                return 0;
            }
            case WM_LBUTTONDOWN: {
                SetFocus(hwnd);
                mouse_x = static_cast<short>(LOWORD(lParam));
                mouse_y = static_cast<short>(HIWORD(lParam));
                last_mouse_x = mouse_x;
                last_mouse_y = mouse_y;
                mouse_down = true;
                on_mouse_down(static_cast<float>(mouse_x), static_cast<float>(mouse_y));
                SetCapture(hWnd);
                return 0;
            }
            case WM_LBUTTONUP: {
                mouse_down = false;
                dragging_3d = false;
                active_slider = -1;
                ReleaseCapture();
                return 0;
            }
            case WM_MOUSEWHEEL: {
                int delta = GET_WHEEL_DELTA_WPARAM(wParam);
                if (has_viewport && (spec.is_3d_mode || !spec.entities_3d.empty()) && pt_in_rect(static_cast<float>(mouse_x), static_cast<float>(mouse_y), vp_rect)) {
                    cam_dist = std::clamp(cam_dist - (delta / 120.0) * 1.8, 6.0, 95.0);
                } else {
                    log_scroll = std::clamp(log_scroll + (delta > 0 ? 2 : -2), 0, std::max(0, static_cast<int>(logs.size()) - 1));
                }
                return 0;
            }
        }
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    }

    static bool pt_in_rect(float x, float y, const D2D1_RECT_F& r) {
        return x >= r.left && x <= r.right && y >= r.top && y <= r.bottom;
    }

    void update_hover() {
        hover_btn = -1;
        for (size_t i = 0; i < button_rects.size(); ++i) {
            if (pt_in_rect(static_cast<float>(mouse_x), static_cast<float>(mouse_y), button_rects[i])) {
                hover_btn = static_cast<int>(i);
                break;
            }
        }
    }

    void update_slider_from_x(int idx, float mx) {
        if (idx < 0 || idx >= static_cast<int>(spec.sliders.size())) return;
        const auto& r = slider_rects[static_cast<size_t>(idx)];
        float w = std::max(1.0f, r.right - r.left);
        double t = std::clamp(static_cast<double>(mx - r.left) / w, 0.0, 1.0);
        auto& sl = spec.sliders[static_cast<size_t>(idx)];
        sl.current_val = sl.min_val + t * (sl.max_val - sl.min_val);
    }

    void on_mouse_down(float mx, float my) {
        active_input = -1;
        if (has_viewport && (spec.is_3d_mode || !spec.entities_3d.empty()) && pt_in_rect(mx, my, vp_rect)) {
            dragging_3d = true;
            return;
        }
        for (size_t i = 0; i < input_rects.size(); ++i) {
            if (pt_in_rect(mx, my, input_rects[i])) {
                active_input = static_cast<int>(i);
                return;
            }
        }
        for (size_t i = 0; i < slider_rects.size(); ++i) {
            D2D1_RECT_F hit = slider_rects[i];
            hit.top -= 8.0f; hit.bottom += 8.0f;
            if (pt_in_rect(mx, my, hit)) {
                active_slider = static_cast<int>(i);
                update_slider_from_x(active_slider, mx);
                return;
            }
        }
        for (size_t i = 0; i < toggle_rects.size(); ++i) {
            if (pt_in_rect(mx, my, toggle_rects[i])) {
                spec.toggles[i].is_checked = !spec.toggles[i].is_checked;
                play_tone(spec.toggles[i].is_checked ? 720 : 480, 50);
                push_log("Toggle '" + spec.toggles[i].label + "' -> " + (spec.toggles[i].is_checked ? "ACTIVADO" : "DESACTIVADO"), 1);
                return;
            }
        }
        for (size_t i = 0; i < button_rects.size(); ++i) {
            if (pt_in_rect(mx, my, button_rects[i])) {
                on_button_click(i);
                return;
            }
        }
    }

    void on_button_click(size_t idx) {
        if (idx >= spec.buttons.size()) return;
        const auto btn = spec.buttons[idx];
        play_tone(640, 80);
        push_log("Botón '" + btn.text + "' presionado -> Acción: " + btn.action, 1);
        if (btn.action == "import_obj" || btn.action == "window.import_obj") {
            open_obj_file_dialog();
            return;
        }
        std::string snip = btn.snippet;
        while (!snip.empty() && (snip.front() == ' ' || snip.front() == '\t' || snip.front() == '\n' || snip.front() == '\r')) snip.erase(0, 1);
        while (!snip.empty() && (snip.back() == ' ' || snip.back() == '\t' || snip.back() == '\n' || snip.back() == '\r')) snip.pop_back();
        if (snip.empty()) return;

        std::istringstream iss(snip);
        std::string sl;
        while (std::getline(iss, sl)) {
            if (!sl.empty()) push_log("  ⚡ " + sl, 2);
        }

        std::string host = spec.host_exe;
        auto q_ptr = async_logs;
        std::thread([q_ptr, snip, host]() {
            bool is_py = (snip.rfind("#!python", 0) == 0 || snip.rfind("import ", 0) == 0);
            std::string cmd;
            if (is_py) {
                cmd = "python -c \"" + escape_cmd_arg(snip) + "\"";
            } else {
                std::string exe = host.empty() ? "looping.exe" : host;
                cmd = "\"" + exe + "\" eval \"" + escape_cmd_arg(snip) + "\"";
            }
            std::string out = run_hidden_process(cmd);
            std::istringstream ois(out);
            std::string line;
            while (std::getline(ois, line)) {
                if (!line.empty() && line.back() == '\r') line.pop_back();
                if (!line.empty()) {
                    std::lock_guard<std::mutex> lk(q_ptr->mtx);
                    q_ptr->entries.push_back({"[" + current_time_str() + "]     " + line, 0});
                }
            }
        }).detach();
    }

    static std::string escape_cmd_arg(const std::string& s) {
        std::string out;
        for (char c : s) {
            if (c == '"') out += "\\\"";
            else if (c == '\n') out += "; ";
            else if (c == '\r') {}
            else out += c;
        }
        return out;
    }

    static std::string run_hidden_process(const std::string& cmd) {
        SECURITY_ATTRIBUTES sa{};
        sa.nLength = sizeof(SECURITY_ATTRIBUTES);
        sa.bInheritHandle = TRUE;
        HANDLE hRead = NULL, hWrite = NULL;
        if (!CreatePipe(&hRead, &hWrite, &sa, 0)) return "";
        SetHandleInformation(hRead, HANDLE_FLAG_INHERIT, 0);

        STARTUPINFOA si{};
        si.cb = sizeof(STARTUPINFOA);
        si.hStdOutput = hWrite;
        si.hStdError = hWrite;
        si.dwFlags |= STARTF_USESTDHANDLES;

        PROCESS_INFORMATION pi{};
        std::vector<char> buf(cmd.begin(), cmd.end());
        buf.push_back('\0');
        BOOL ok = CreateProcessA(NULL, buf.data(), NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi);
        CloseHandle(hWrite);
        if (!ok) { CloseHandle(hRead); return ""; }

        std::string out;
        char ch[512];
        DWORD readBytes = 0;
        while (ReadFile(hRead, ch, sizeof(ch), &readBytes, NULL) && readBytes > 0) {
            out.append(ch, static_cast<size_t>(readBytes));
        }
        CloseHandle(hRead);
        WaitForSingleObject(pi.hProcess, 4000);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return out;
    }

    void reset_2d_stage() {
        score_2d = 0;
        lives_2d = 3;
        bullets_2d.clear();
        particles_2d.clear();
        for (auto& e : spec.entities_2d) {
            e.x = e.spawn_x;
            e.y = e.spawn_y;
            e.vx = e.vy = 0;
            e.collected = false;
            e.alive = true;
            e.health = e.max_health;
        }
        push_log("Escenario 2D reiniciado.", 3);
    }

    bool init_d3d_and_d2d() {
        if (!api.init()) return false;
        if (api.pSetProcessDPIAware) api.pSetProcessDPIAware();

        WNDCLASSEXW wc{};
        wc.cbSize = sizeof(WNDCLASSEXW);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = wnd_proc;
        wc.hInstance = GetModuleHandleW(nullptr);
        wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
        wc.hbrBackground = reinterpret_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
        wc.lpszClassName = L"LoopingDirectXWindowClass";
        RegisterClassExW(&wc);

        std::wstring wtitle = utf8_to_wide(spec.title + " — Loop OS DirectX 11");
        RECT rc{0, 0, static_cast<LONG>(std::max(580.0, spec.width)), static_cast<LONG>(std::max(400.0, spec.height))};
        AdjustWindowRect(&rc, WS_OVERLAPPEDWINDOW, FALSE);

        hwnd = CreateWindowExW(
            0, L"LoopingDirectXWindowClass", wtitle.c_str(),
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT, CW_USEDEFAULT,
            rc.right - rc.left, rc.bottom - rc.top,
            nullptr, nullptr, GetModuleHandleW(nullptr), this
        );
        if (!hwnd) return false;

        if (api.pDwmSetWindowAttribute) {
            BOOL dark = TRUE;
            api.pDwmSetWindowAttribute(hwnd, 20 /*DWMWA_USE_IMMUTABLE_DARK_MODE*/, &dark, sizeof(dark));
        }

        RECT crc{};
        GetClientRect(hwnd, &crc);
        client_w = std::max(320, static_cast<int>(crc.right - crc.left));
        client_h = std::max(240, static_cast<int>(crc.bottom - crc.top));

        DXGI_SWAP_CHAIN_DESC scd{};
        scd.BufferCount = 2;
        scd.BufferDesc.Width = static_cast<UINT>(client_w);
        scd.BufferDesc.Height = static_cast<UINT>(client_h);
        scd.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        scd.BufferDesc.RefreshRate.Numerator = static_cast<UINT>(std::max(60, spec.target_fps));
        scd.BufferDesc.RefreshRate.Denominator = 1;
        scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        scd.OutputWindow = hwnd;
        scd.SampleDesc.Count = 1;
        scd.Windowed = TRUE;
        scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

        D3D_FEATURE_LEVEL levels[] = {
            D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0,
            D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0
        };
        UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
        D3D_FEATURE_LEVEL got_level{};

        HRESULT hr = api.pD3D11CreateDeviceAndSwapChain(
            nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
            levels, 4, D3D11_SDK_VERSION, &scd,
            swapchain.put(), d3d_device.put(), &got_level, d3d_ctx.put()
        );
        bool is_warp = false;
        if (FAILED(hr)) {
            is_warp = true;
            hr = api.pD3D11CreateDeviceAndSwapChain(
                nullptr, D3D_DRIVER_TYPE_WARP, nullptr, flags,
                levels, 4, D3D11_SDK_VERSION, &scd,
                swapchain.put(), d3d_device.put(), &got_level, d3d_ctx.put()
            );
        }
        if (FAILED(hr)) return false;

        if (is_warp) {
            gpu_name = "DirectX 11 WARP";
        } else {
            ComPtr<IDXGIDevice> dxgi_dev;
            ComPtr<IDXGIAdapter> adapter;
            if (SUCCEEDED(d3d_device->QueryInterface(kIID_IDXGIDevice, reinterpret_cast<void**>(dxgi_dev.put()))) && dxgi_dev &&
                SUCCEEDED(dxgi_dev->GetAdapter(adapter.put())) && adapter) {
                DXGI_ADAPTER_DESC desc{};
                if (SUCCEEDED(adapter->GetDesc(&desc))) {
                    char utf[256]{};
                    WideCharToMultiByte(CP_UTF8, 0, desc.Description, -1, utf, sizeof(utf), nullptr, nullptr);
                    gpu_name = std::string("DX11 • ") + utf;
                    if (gpu_name.size() > 30) gpu_name.resize(30);
                }
            }
        }

        hr = api.pD2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, kIID_ID2D1Factory, nullptr,
                                    reinterpret_cast<void**>(d2d_factory.put()));
        if (FAILED(hr)) return false;

        hr = api.pDWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, kIID_IDWriteFactory,
                                      reinterpret_cast<IUnknown**>(dwrite_factory.put()));
        if (FAILED(hr)) return false;

        auto make_fmt = [&](const wchar_t* fam, DWRITE_FONT_WEIGHT w, float sz, IDWriteTextFormat** out_fmt) {
            dwrite_factory->CreateTextFormat(fam, nullptr, w, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL, sz, L"en-us", out_fmt);
        };
        make_fmt(L"Segoe UI", DWRITE_FONT_WEIGHT_BOLD, 16.0f, fmt_title.put());
        make_fmt(L"Segoe UI", DWRITE_FONT_WEIGHT_BOLD, 11.0f, fmt_badge.put());
        make_fmt(L"Segoe UI", DWRITE_FONT_WEIGHT_BOLD, 14.0f, fmt_card_title.put());
        make_fmt(L"Segoe UI", DWRITE_FONT_WEIGHT_NORMAL, 12.5f, fmt_body.put());
        make_fmt(L"Segoe UI", DWRITE_FONT_WEIGHT_BOLD, 12.0f, fmt_btn.put());
        make_fmt(L"Consolas", DWRITE_FONT_WEIGHT_NORMAL, 12.5f, fmt_mono.put());

        if (!recreate_size_dependent_resources()) return false;
        init_d3d11_3d_pipeline();
        return true;
    }

    bool recreate_size_dependent_resources() {
        brush.reset();
        d2d_rt.reset();
        rtv.reset();
        dsv.reset();
        depth_tex.reset();
        if (d3d_ctx) d3d_ctx->Flush();

        HRESULT hr = swapchain->ResizeBuffers(0, static_cast<UINT>(client_w), static_cast<UINT>(client_h), DXGI_FORMAT_UNKNOWN, 0);
        if (FAILED(hr)) return false;

        ComPtr<ID3D11Texture2D> backbuf;
        hr = swapchain->GetBuffer(0, kIID_ID3D11Texture2D, reinterpret_cast<void**>(backbuf.put()));
        if (FAILED(hr)) return false;

        hr = d3d_device->CreateRenderTargetView(backbuf.get(), nullptr, rtv.put());
        if (FAILED(hr)) return false;

        D3D11_TEXTURE2D_DESC dsd{};
        dsd.Width = static_cast<UINT>(client_w);
        dsd.Height = static_cast<UINT>(client_h);
        dsd.MipLevels = 1;
        dsd.ArraySize = 1;
        dsd.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
        dsd.SampleDesc.Count = 1;
        dsd.Usage = D3D11_USAGE_DEFAULT;
        dsd.BindFlags = D3D11_BIND_DEPTH_STENCIL;
        if (SUCCEEDED(d3d_device->CreateTexture2D(&dsd, nullptr, depth_tex.put()))) {
            d3d_device->CreateDepthStencilView(depth_tex.get(), nullptr, dsv.put());
        }

        ComPtr<IDXGISurface> dxgi_surf;
        hr = backbuf->QueryInterface(kIID_IDXGISurface, reinterpret_cast<void**>(dxgi_surf.put()));
        if (FAILED(hr)) return false;

        D2D1_RENDER_TARGET_PROPERTIES props{};
        props.type = D2D1_RENDER_TARGET_TYPE_DEFAULT;
        props.pixelFormat.format = DXGI_FORMAT_B8G8R8A8_UNORM;
        props.pixelFormat.alphaMode = D2D1_ALPHA_MODE_PREMULTIPLIED;
        props.dpiX = 96.0f;
        props.dpiY = 96.0f;
        hr = d2d_factory->CreateDxgiSurfaceRenderTarget(dxgi_surf.get(), &props, d2d_rt.put());
        if (FAILED(hr)) return false;

        d2d_rt->CreateSolidColorBrush(D2D1_COLOR_F{1, 1, 1, 1}, brush.put());
        return (brush && d2d_rt && rtv);
    }

    bool create_mesh_vb(const std::vector<Vertex3D>& verts, GpuMesh& out_mesh) {
        if (verts.empty()) return false;
        D3D11_BUFFER_DESC bd{};
        bd.Usage = D3D11_USAGE_IMMUTABLE;
        bd.ByteWidth = static_cast<UINT>(verts.size() * sizeof(Vertex3D));
        bd.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        D3D11_SUBRESOURCE_DATA sd{};
        sd.pSysMem = verts.data();
        if (FAILED(d3d_device->CreateBuffer(&bd, &sd, out_mesh.vb.put()))) return false;
        out_mesh.vertex_count = static_cast<UINT>(verts.size());
        return true;
    }

    static void add_mesh_tri(std::vector<Vertex3D>& out, Vec3f a, Vec3f b, Vec3f c) {
        Vec3f u{b.x - a.x, b.y - a.y, b.z - a.z};
        Vec3f v{c.x - a.x, c.y - a.y, c.z - a.z};
        Vec3f n{u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x};
        float len = std::sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
        if (len > 1e-6f) { n.x /= len; n.y /= len; n.z /= len; } else n = {0, 1, 0};
        out.push_back({a.x, a.y, a.z, n.x, n.y, n.z});
        out.push_back({b.x, b.y, b.z, n.x, n.y, n.z});
        out.push_back({c.x, c.y, c.z, n.x, n.y, n.z});
    }

    void build_custom_mesh_for_entity(size_t ei) {
        if (ei >= spec.entities_3d.size()) return;
        if (custom_meshes.size() <= ei) custom_meshes.resize(ei + 1);
        const auto& e = spec.entities_3d[ei];
        if (e.verts.empty() || e.faces.empty()) return;
        std::vector<Vertex3D> mv;
        for (const auto& fc : e.faces) {
            if (fc.size() < 3) continue;
            for (size_t k = 1; k + 1 < fc.size(); ++k) {
                int i0 = fc[0], i1 = fc[k], i2 = fc[k + 1];
                if (i0 < 0 || i1 < 0 || i2 < 0 ||
                    i0 >= static_cast<int>(e.verts.size()) ||
                    i1 >= static_cast<int>(e.verts.size()) ||
                    i2 >= static_cast<int>(e.verts.size())) continue;
                Vec3f a{static_cast<float>(e.verts[i0][0]), static_cast<float>(e.verts[i0][1]), static_cast<float>(e.verts[i0][2])};
                Vec3f b{static_cast<float>(e.verts[i1][0]), static_cast<float>(e.verts[i1][1]), static_cast<float>(e.verts[i1][2])};
                Vec3f c{static_cast<float>(e.verts[i2][0]), static_cast<float>(e.verts[i2][1]), static_cast<float>(e.verts[i2][2])};
                add_mesh_tri(mv, a, b, c);
            }
        }
        create_mesh_vb(mv, custom_meshes[ei]);
    }

    static bool parse_obj_file_to_spec(const std::string& path, DxEntity3DSpec& out_ent, double scale = 1.0) {
        std::ifstream f(path);
        if (!f.good()) return false;
        std::vector<std::array<double, 3>> raw_v;
        std::vector<std::vector<int>> raw_f;
        std::string line;
        while (std::getline(f, line)) {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            std::istringstream iss(line);
            std::string tag;
            if (!(iss >> tag)) continue;
            if (tag == "v") {
                double x = 0, y = 0, z = 0;
                if (iss >> x >> y >> z) raw_v.push_back({x, y, z});
            } else if (tag == "f") {
                std::vector<int> face;
                std::string tok;
                while (iss >> tok) {
                    size_t sl = tok.find('/');
                    std::string idx_s = (sl == std::string::npos) ? tok : tok.substr(0, sl);
                    if (idx_s.empty()) continue;
                    try {
                        int idx = std::stoi(idx_s);
                        if (idx < 0) idx = static_cast<int>(raw_v.size()) + idx;
                        else idx = idx - 1;
                        if (idx >= 0 && idx < static_cast<int>(raw_v.size())) face.push_back(idx);
                    } catch (...) {}
                }
                if (face.size() >= 3) raw_f.push_back(std::move(face));
            }
        }
        if (raw_v.empty() || raw_f.empty()) return false;

        double min_x = raw_v[0][0], max_x = raw_v[0][0];
        double min_y = raw_v[0][1], max_y = raw_v[0][1];
        double min_z = raw_v[0][2], max_z = raw_v[0][2];
        for (const auto& v : raw_v) {
            min_x = std::min(min_x, v[0]); max_x = std::max(max_x, v[0]);
            min_y = std::min(min_y, v[1]); max_y = std::max(max_y, v[1]);
            min_z = std::min(min_z, v[2]); max_z = std::max(max_z, v[2]);
        }
        double cx = (min_x + max_x) * 0.5;
        double cy = (min_y + max_y) * 0.5;
        double cz = (min_z + max_z) * 0.5;
        double max_span = std::max({max_x - min_x, max_y - min_y, max_z - min_z, 1e-4});
        double norm = (2.8 / max_span) * (scale > 0.0 ? scale : 1.0);
        for (auto& v : raw_v) {
            v[0] = (v[0] - cx) * norm;
            v[1] = (v[1] - cy) * norm;
            v[2] = (v[2] - cz) * norm;
        }
        out_ent.verts = std::move(raw_v);
        out_ent.faces = std::move(raw_f);
        return true;
    }

    bool import_obj_file(const std::string& obj_path, const std::string& entity_name = "",
                         const std::string& color = "#38bdf8", double scale = 1.0) {
        DxEntity3DSpec ent;
        ent.type = "obj";
        size_t sl = obj_path.find_last_of("/\\");
        std::string base = (sl == std::string::npos) ? obj_path : obj_path.substr(sl + 1);
        ent.name = entity_name.empty() ? base : entity_name;
        ent.color = color;
        ent.x = 0.0;
        ent.y = 2.0;
        ent.z = 6.0 + static_cast<double>(spec.entities_3d.size()) * 2.5;
        ent.sx = 1.0; ent.sy = 1.0; ent.sz = 1.0;
        ent.scx = 1.0; ent.scy = 1.0; ent.scz = 1.0;
        if (!parse_obj_file_to_spec(obj_path, ent, scale)) {
            push_log("[OBJ IMPORT] Error: no se pudo leer '" + obj_path + "'.", 2);
            return false;
        }
        size_t verts_cnt = ent.verts.size();
        size_t faces_cnt = ent.faces.size();
        spec.is_3d_mode = true;
        spec.entities_3d.push_back(std::move(ent));
        if (!has_3d_pipeline && d3d_device) {
            init_d3d11_3d_pipeline();
        } else if (d3d_device) {
            build_custom_mesh_for_entity(spec.entities_3d.size() - 1);
        }
        play_tone(880, 75);
        push_log("[OBJ IMPORT] Importado '" + spec.entities_3d.back().name + "' (" +
                 std::to_string(verts_cnt) + " vértices, " + std::to_string(faces_cnt) + " caras).", 1);
        return true;
    }

    bool open_obj_file_dialog() {
        using PfnGetOpenFileNameA = BOOL(WINAPI*)(LPOPENFILENAMEA);
        HMODULE comdlg = LoadLibraryA("comdlg32.dll");
        if (!comdlg) return false;
        auto pGetOpenFileNameA = reinterpret_cast<PfnGetOpenFileNameA>(GetProcAddress(comdlg, "GetOpenFileNameA"));
        if (!pGetOpenFileNameA) return false;
        char file_buf[MAX_PATH]{};
        OPENFILENAMEA ofn{};
        ofn.lStructSize = sizeof(OPENFILENAMEA);
        ofn.hwndOwner = hwnd;
        ofn.lpstrFilter = "Wavefront OBJ (*.obj)\0*.obj\0Todos los archivos (*.*)\0*.*\0";
        ofn.lpstrFile = file_buf;
        ofn.nMaxFile = MAX_PATH;
        ofn.lpstrTitle = "Importar modelo 3D (.obj) en Looping DirectX";
        ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_NOCHANGEDIR;
        if (pGetOpenFileNameA(&ofn)) {
            return import_obj_file(std::string(file_buf));
        }
        return false;
    }

    void init_d3d11_3d_pipeline() {
        if (!api.pD3DCompile) return;

        static const char* hlsl_src =
            "cbuffer SceneCB : register(b0) {\n"
            "    row_major float4x4 uMVP;\n"
            "    row_major float4x4 uWorld;\n"
            "    float4 uColor;\n"
            "    float4 uLightDir;\n"
            "    float4 uParams;\n"
            "};\n"
            "struct VSIn { float3 pos : POSITION; float3 norm : NORMAL; };\n"
            "struct PSIn { float4 pos : SV_POSITION; float3 wnorm : TEXCOORD0; float depth : TEXCOORD1; };\n"
            "PSIn VSMain(VSIn i) {\n"
            "    PSIn o;\n"
            "    o.pos = mul(uMVP, float4(i.pos, 1.0));\n"
            "    o.wnorm = normalize(mul((float3x3)uWorld, i.norm));\n"
            "    o.depth = o.pos.w;\n"
            "    return o;\n"
            "}\n"
            "float4 PSMain(PSIn i) : SV_TARGET {\n"
            "    if (uParams.w > 0.5) return uColor;\n"
            "    float3 n = normalize(i.wnorm);\n"
            "    float3 l = normalize(-uLightDir.xyz);\n"
            "    float ndl = max(dot(n, l), 0.0);\n"
            "    float hemi = 0.40 + 0.22 * max(n.y, 0.0);\n"
            "    float3 lit = uColor.rgb * (hemi + ndl * 0.65);\n"
            "    float fog = saturate((i.depth - 35.0) / 160.0);\n"
            "    lit = lerp(lit, float3(0.02, 0.032, 0.075), fog * 0.6);\n"
            "    return float4(lit, uColor.a);\n"
            "}\n";

        ComPtr<ID3DBlob> vs_blob, ps_blob, err_blob;
        if (FAILED(api.pD3DCompile(hlsl_src, std::strlen(hlsl_src), "dx11_vs", nullptr, nullptr, "VSMain", "vs_4_0", 0, 0, vs_blob.put(), err_blob.put()))) {
            return;
        }
        if (FAILED(api.pD3DCompile(hlsl_src, std::strlen(hlsl_src), "dx11_ps", nullptr, nullptr, "PSMain", "ps_4_0", 0, 0, ps_blob.put(), err_blob.put()))) {
            return;
        }
        if (FAILED(d3d_device->CreateVertexShader(vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), nullptr, vs.put()))) return;
        if (FAILED(d3d_device->CreatePixelShader(ps_blob->GetBufferPointer(), ps_blob->GetBufferSize(), nullptr, ps.put()))) return;

        D3D11_INPUT_ELEMENT_DESC ied[] = {
            {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0},
            {"NORMAL",   0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0}
        };
        if (FAILED(d3d_device->CreateInputLayout(ied, 2, vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), input_layout.put()))) return;

        D3D11_BUFFER_DESC cbd{};
        cbd.Usage = D3D11_USAGE_DYNAMIC;
        cbd.ByteWidth = sizeof(SceneCBData);
        cbd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        cbd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        if (FAILED(d3d_device->CreateBuffer(&cbd, nullptr, cb_scene.put()))) return;

        D3D11_RASTERIZER_DESC rd{};
        rd.FillMode = D3D11_FILL_SOLID;
        rd.CullMode = D3D11_CULL_NONE;
        rd.DepthClipEnable = TRUE;
        d3d_device->CreateRasterizerState(&rd, rast_state.put());

        D3D11_DEPTH_STENCIL_DESC dsd{};
        dsd.DepthEnable = TRUE;
        dsd.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
        dsd.DepthFunc = D3D11_COMPARISON_LESS_EQUAL;
        d3d_device->CreateDepthStencilState(&dsd, depth_state.put());

        auto add_tri = [](std::vector<Vertex3D>& out, Vec3f a, Vec3f b, Vec3f c) {
            Vec3f u{b.x - a.x, b.y - a.y, b.z - a.z};
            Vec3f v{c.x - a.x, c.y - a.y, c.z - a.z};
            Vec3f n{u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x};
            float len = std::sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
            if (len > 1e-6f) { n.x /= len; n.y /= len; n.z /= len; } else n = {0, 1, 0};
            out.push_back({a.x, a.y, a.z, n.x, n.y, n.z});
            out.push_back({b.x, b.y, b.z, n.x, n.y, n.z});
            out.push_back({c.x, c.y, c.z, n.x, n.y, n.z});
        };

        // Unit Box [-0.5..0.5]^3
        std::vector<Vertex3D> box_v;
        Vec3f p[8] = {
            {-0.5f,-0.5f,-0.5f}, {0.5f,-0.5f,-0.5f}, {0.5f,0.5f,-0.5f}, {-0.5f,0.5f,-0.5f},
            {-0.5f,-0.5f, 0.5f}, {0.5f,-0.5f, 0.5f}, {0.5f,0.5f, 0.5f}, {-0.5f,0.5f, 0.5f}
        };
        int qf[6][4] = {{0,1,2,3},{5,4,7,6},{4,0,3,7},{1,5,6,2},{3,2,6,7},{4,5,1,0}};
        for (auto& f : qf) {
            add_tri(box_v, p[f[0]], p[f[1]], p[f[2]]);
            add_tri(box_v, p[f[0]], p[f[2]], p[f[3]]);
        }
        create_mesh_vb(box_v, mesh_box);

        // Octahedron Crystal
        std::vector<Vertex3D> cry_v;
        Vec3f top{0, 0.7f, 0}, bot{0, -0.7f, 0};
        Vec3f mid[4] = {{0.5f, 0, 0}, {0, 0, 0.5f}, {-0.5f, 0, 0}, {0, 0, -0.5f}};
        for (int i = 0; i < 4; ++i) {
            int j = (i + 1) % 4;
            add_tri(cry_v, top, mid[i], mid[j]);
            add_tri(cry_v, bot, mid[j], mid[i]);
        }
        create_mesh_vb(cry_v, mesh_crystal);

        // Ring Torus-like polygon strip
        std::vector<Vertex3D> ring_v;
        const int segs = 18;
        for (int i = 0; i < segs; ++i) {
            float a0 = i * 6.2831853f / segs;
            float a1 = (i + 1) * 6.2831853f / segs;
            float r_in = 0.72f, r_out = 1.0f, h = 0.14f;
            Vec3f i0f{std::cos(a0) * r_in, std::sin(a0) * r_in, -h};
            Vec3f o0f{std::cos(a0) * r_out, std::sin(a0) * r_out, -h};
            Vec3f i1f{std::cos(a1) * r_in, std::sin(a1) * r_in, -h};
            Vec3f o1f{std::cos(a1) * r_out, std::sin(a1) * r_out, -h};
            Vec3f i0b{i0f.x, i0f.y, h}, o0b{o0f.x, o0f.y, h}, i1b{i1f.x, i1f.y, h}, o1b{o1f.x, o1f.y, h};
            add_tri(ring_v, i0f, o0f, o1f); add_tri(ring_v, i0f, o1f, i1f);
            add_tri(ring_v, o0b, i0b, i1b); add_tri(ring_v, o0b, i1b, o1b);
            add_tri(ring_v, o0f, o0b, o1b); add_tri(ring_v, o0f, o1b, o1f);
        }
        create_mesh_vb(ring_v, mesh_ring);

        // Ground Grid Lines
        std::vector<Vertex3D> grid_v;
        for (int g = -60; g <= 160; g += 6) {
            grid_v.push_back({-60.0f, 0.0f, static_cast<float>(g), 0, 1, 0});
            grid_v.push_back({ 60.0f, 0.0f, static_cast<float>(g), 0, 1, 0});
        }
        for (int g = -60; g <= 60; g += 6) {
            grid_v.push_back({static_cast<float>(g), 0.0f, -60.0f, 0, 1, 0});
            grid_v.push_back({static_cast<float>(g), 0.0f, 160.0f, 0, 1, 0});
        }
        create_mesh_vb(grid_v, mesh_grid);

        // Custom OBJ Meshes per Entity3D
        custom_meshes.resize(spec.entities_3d.size());
        for (size_t ei = 0; ei < spec.entities_3d.size(); ++ei) {
            build_custom_mesh_for_entity(ei);
        }

        has_3d_pipeline = (vs && ps && input_layout && cb_scene && mesh_box.vb);
    }

    void update_simulation(double dt) {
        total_time += dt;
        // Drain async log queue
        {
            std::lock_guard<std::mutex> lk(async_logs->mtx);
            for (auto& l : async_logs->entries) {
                logs.push_back(std::move(l));
            }
            async_logs->entries.clear();
            while (logs.size() > 300) logs.erase(logs.begin());
        }

        if (active_input >= 0) return; // Don't steal WASD while typing in an input box

        // 3D Simulation
        if (spec.is_3d_mode || !spec.entities_3d.empty()) {
            if (is_key_down('Q')) cam_yaw -= 1.8 * dt;
            if (is_key_down('E')) cam_yaw += 1.8 * dt;

            DxEntity3DSpec* player = nullptr;
            for (auto& e : spec.entities_3d) {
                if (e.type == "player") { player = &e; break; }
            }
            if (player) {
                double spd = player->speed * ((is_key_down(VK_SHIFT) || is_key_down('X')) ? 1.75 : 1.0);
                double fx = std::sin(cam_yaw), fz = std::cos(cam_yaw);
                double rx = std::cos(cam_yaw), rz = -std::sin(cam_yaw);
                double mx = ((is_key_down('D') || is_key_down(VK_RIGHT)) ? 1.0 : 0.0) - ((is_key_down('A') || is_key_down(VK_LEFT)) ? 1.0 : 0.0);
                double mz = ((is_key_down('W') || is_key_down(VK_UP)) ? 1.0 : 0.0) - ((is_key_down('S') || is_key_down(VK_DOWN)) ? 1.0 : 0.0);
                p3d_vel[0] = (fx * mz + rx * mx) * spd;
                p3d_vel[2] = (fz * mz + rz * mx) * spd;
                if (is_key_down(VK_SPACE) && p3d_jumps < 2) {
                    p3d_vel[1] = 15.0;
                    p3d_jumps++;
                    keys[VK_SPACE] = false;
                    play_tone(520, 45);
                }
                for (int sub = 0; sub < 4; ++sub) {
                    double sdt = dt * 0.25;
                    p3d_vel[1] -= 26.0 * sdt;
                    player->x += p3d_vel[0] * sdt;
                    player->y += p3d_vel[1] * sdt;
                    player->z += p3d_vel[2] * sdt;
                    if (player->y <= 0.6) {
                        player->y = 0.6;
                        p3d_vel[1] = 0.0;
                        p3d_jumps = 0;
                    }
                }
            } else {
                // Free-camera WASD / Arrow navigation when no explicit 3D player is spawned
                double cam_spd = is_key_down(VK_SHIFT) ? 2.2 : 1.0;
                if (is_key_down('A') || is_key_down(VK_LEFT)) cam_yaw -= 1.8 * cam_spd * dt;
                if (is_key_down('D') || is_key_down(VK_RIGHT)) cam_yaw += 1.8 * cam_spd * dt;
                if (is_key_down('W') || is_key_down(VK_UP)) cam_dist = std::max(3.5, cam_dist - 12.0 * cam_spd * dt);
                if (is_key_down('S') || is_key_down(VK_DOWN)) cam_dist = std::min(90.0, cam_dist + 12.0 * cam_spd * dt);
            }

            for (auto& o : spec.entities_3d) {
                if (o.type == "crystal" || o.type == "ring" || o.type == "portal" || o.type == "obj") {
                    o.rot_y = std::fmod(o.rot_y + 90.0 * dt, 360.0);
                }
                if ((o.type == "moving_platform" || o.type == "enemy" || o.type == "boss") && o.alive) {
                    double* coord = (o.axis == "y") ? &o.y : ((o.axis == "z") ? &o.z : &o.x);
                    *coord += o.dir * o.speed * dt;
                    if (*coord >= o.max_pos) { *coord = o.max_pos; o.dir = -1.0; }
                    if (*coord <= o.min_pos) { *coord = o.min_pos; o.dir = 1.0; }
                }
                if (player && (o.type == "crystal" || o.type == "ring") && !o.collected) {
                    double dx = player->x - o.x, dy = player->y - o.y, dz = player->z - o.z;
                    double rad = o.radius + 1.5;
                    if (dx * dx + dy * dy + dz * dz < rad * rad) {
                        o.collected = true;
                        score_3d += 150;
                        play_tone(880, 70);
                        push_log("[3D] Recogido " + o.type + " (+150 pts) | Total: " + std::to_string(score_3d), 0);
                    }
                }
            }
        } else if (!spec.entities_2d.empty()) {
            // 2D Stage Physics Simulation
            DxEntity2DSpec* player = nullptr;
            for (auto& e : spec.entities_2d) {
                if (e.is_player || e.type == "player") { player = &e; break; }
            }
            if (!player) {
                for (auto& e : spec.entities_2d) {
                    if (e.type == "sprite") { player = &e; break; }
                }
            }
            if (player && player->alive) {
                if (player->invuln_timer > 0) player->invuln_timer -= dt;
                if (player->dash_cd > 0) player->dash_cd -= dt;
                if (player->shoot_cd > 0) player->shoot_cd -= dt;

                double move = ((is_key_down('D') || is_key_down(VK_RIGHT)) ? 1.0 : 0.0) - ((is_key_down('A') || is_key_down(VK_LEFT)) ? 1.0 : 0.0);
                if (player->dash_timer > 0) {
                    player->dash_timer -= dt;
                } else {
                    player->vx = move * std::max(180.0, player->speed);
                }

                if ((is_key_down('X') || is_key_down(VK_SHIFT)) && player->dash_cd <= 0.0) {
                    double dir_d = (move != 0.0) ? move : 1.0;
                    player->vx = dir_d * 560.0;
                    player->dash_timer = 0.14;
                    player->dash_cd = 0.65;
                    play_tone(760, 45);
                }
                if ((is_key_down('W') || is_key_down(VK_UP) || is_key_down(VK_SPACE))) {
                    if (!player->is_jumping) {
                        player->vy = -std::max(360.0, player->jump_force);
                        player->is_jumping = true;
                        keys[VK_SPACE] = false; keys['W'] = false; keys[VK_UP] = false;
                        play_tone(480, 45);
                    } else if (player->can_double_jump) {
                        player->vy = -std::max(340.0, player->jump_force * 0.92);
                        player->can_double_jump = false;
                        keys[VK_SPACE] = false; keys['W'] = false; keys[VK_UP] = false;
                        play_tone(640, 45);
                    }
                }
                if ((is_key_down('Z') || is_key_down('J')) && player->shoot_cd <= 0.0) {
                    double dir_s = (move < 0) ? -1.0 : 1.0;
                    bullets_2d.push_back({player->x + player->w * 0.5, player->y + player->h * 0.45, dir_s * 540.0, 0.0, 1.4, true, "#38bdf8"});
                    player->shoot_cd = 0.25;
                    play_tone(920, 35);
                }

                player->vy += spec.gravity * dt;
                player->x = std::clamp(player->x + player->vx * dt, 0.0, std::max(400.0, spec.world_width - player->w));
                player->y += player->vy * dt;

                double floor_y = spec.world_height - 28.0;
                if (player->y + player->h >= floor_y) {
                    player->y = floor_y - player->h;
                    player->vy = 0;
                    player->is_jumping = false;
                    player->can_double_jump = true;
                }

                for (auto& e : spec.entities_2d) {
                    if (!e.alive || e.collected || &e == player) continue;
                    if (e.type == "moving_platform" || e.type == "enemy" || e.type == "boss") {
                        e.x += e.dir * e.speed * dt;
                        if (e.max_pos > e.min_pos) {
                            if (e.x >= e.max_pos) { e.x = e.max_pos; e.dir = -1.0; }
                            if (e.x <= e.min_pos) { e.x = e.min_pos; e.dir = 1.0; }
                        }
                    }
                    if (e.type == "platform" || e.type == "moving_platform" || e.type == "breakable") {
                        if (player->vy >= 0 &&
                            player->x + player->w > e.x && player->x < e.x + e.w &&
                            player->y + player->h >= e.y && player->y + player->h <= e.y + e.h + 14.0) {
                            player->y = e.y - player->h;
                            player->vy = 0;
                            player->is_jumping = false;
                            player->can_double_jump = true;
                        }
                    } else if (e.type == "coin" || e.type == "heart") {
                        double cx = e.x, cy = e.y;
                        if (player->x + player->w > cx - e.radius && player->x < cx + e.radius &&
                            player->y + player->h > cy - e.radius && player->y < cy + e.radius) {
                            e.collected = true;
                            if (e.type == "coin") {
                                score_2d += static_cast<int>(e.points);
                                play_tone(980, 60);
                            } else {
                                player->health = std::min(player->max_health, player->health + 35.0);
                                play_tone(660, 80);
                            }
                        }
                    } else if (e.type == "jump_pad" || e.type == "pad") {
                        if (player->x + player->w > e.x && player->x < e.x + e.w &&
                            player->y + player->h >= e.y - 6 && player->y <= e.y + e.h) {
                            player->vy = -std::max(550.0, e.power);
                            player->is_jumping = true;
                            player->can_double_jump = true;
                            play_tone(780, 65);
                        }
                    } else if ((e.type == "enemy" || e.type == "boss") &&
                               player->x + player->w > e.x && player->x < e.x + e.w &&
                               player->y + player->h > e.y && player->y < e.y + e.h) {
                        if (player->vy > 40.0 && player->y + player->h - 14.0 <= e.y + e.h * 0.5) {
                            e.health -= 50.0;
                            player->vy = -380.0;
                            play_tone(520, 60);
                            if (e.health <= 0) {
                                e.alive = false;
                                score_2d += 250;
                                push_log("[2D] Enemigo neutralizado (+250 pts)", 0);
                            }
                        } else if (player->invuln_timer <= 0) {
                            player->health -= e.damage;
                            player->invuln_timer = 1.0;
                            play_tone(220, 90);
                            if (player->health <= 0) {
                                lives_2d--;
                                if (lives_2d <= 0) reset_2d_stage();
                                else {
                                    player->health = player->max_health;
                                    player->x = player->spawn_x;
                                    player->y = player->spawn_y;
                                }
                            }
                        }
                    }
                }
                double target_cam = player->x - 240.0;
                cam2d_x += (std::clamp(target_cam, 0.0, std::max(0.0, spec.world_width - 600.0)) - cam2d_x) * std::min(1.0, dt * 8.0);
            }

            for (size_t i = 0; i < bullets_2d.size();) {
                bullets_2d[i].x += bullets_2d[i].vx * dt;
                bullets_2d[i].life -= dt;
                bool erase_b = (bullets_2d[i].life <= 0);
                if (!erase_b && bullets_2d[i].from_player) {
                    for (auto& e : spec.entities_2d) {
                        if (e.alive && (e.type == "enemy" || e.type == "boss" || e.type == "breakable") &&
                            bullets_2d[i].x >= e.x && bullets_2d[i].x <= e.x + e.w &&
                            bullets_2d[i].y >= e.y && bullets_2d[i].y <= e.y + e.h) {
                            e.health -= 25.0;
                            erase_b = true;
                            if (e.health <= 0) {
                                e.alive = false;
                                score_2d += 200;
                            }
                            break;
                        }
                    }
                }
                if (erase_b) bullets_2d.erase(bullets_2d.begin() + i);
                else ++i;
            }
        }
    }

    void compute_layout() {
        float pad = 14.0f;
        float y = 62.0f;
        float w = static_cast<float>(client_w) - pad * 2.0f;
        bool has_3d = (spec.is_3d_mode || !spec.entities_3d.empty());
        bool has_2d = (!has_3d && !spec.entities_2d.empty());
        has_viewport = (has_3d || has_2d);

        if (has_viewport) {
            float vp_h = std::clamp(static_cast<float>(client_h) * 0.42f, 160.0f, 320.0f);
            vp_rect = D2D1_RECT_F{pad, y, pad + w, y + vp_h};
            y += vp_h + 10.0f;
        }

        card_rects.clear();
        if (!spec.cards.empty()) {
            int cols = (client_w >= 640) ? 2 : 1;
            float gap = 12.0f;
            float cw = (cols == 2) ? (w - gap) * 0.5f : w;
            size_t rows = (spec.cards.size() + static_cast<size_t>(cols) - 1) / static_cast<size_t>(cols);
            float card_h = (rows > 2 || has_viewport) ? 78.0f : 94.0f;
            for (size_t i = 0; i < spec.cards.size(); ++i) {
                int col = static_cast<int>(i % static_cast<size_t>(cols));
                int row = static_cast<int>(i / static_cast<size_t>(cols));
                float cx = pad + col * (cw + gap);
                float cy = y + row * (card_h + 10.0f);
                card_rects.push_back(D2D1_RECT_F{cx, cy, cx + cw, cy + card_h});
            }
            y += static_cast<float>(rows) * (card_h + 10.0f);
        }

        input_rects.clear();
        slider_rects.clear();
        toggle_rects.clear();
        if (!spec.inputs.empty() || !spec.sliders.empty() || !spec.toggles.empty() || !spec.progress_bars.empty()) {
            float cy = y + 10.0f;
            for (size_t i = 0; i < spec.inputs.size(); ++i) {
                input_rects.push_back(D2D1_RECT_F{pad + 12.0f, cy + 18.0f, pad + w - 12.0f, cy + 44.0f});
                cy += 52.0f;
            }
            for (size_t i = 0; i < spec.sliders.size(); ++i) {
                slider_rects.push_back(D2D1_RECT_F{pad + 12.0f, cy + 22.0f, pad + w - 12.0f, cy + 34.0f});
                cy += 42.0f;
            }
            for (size_t i = 0; i < spec.toggles.size(); ++i) {
                toggle_rects.push_back(D2D1_RECT_F{pad + 12.0f, cy + 2.0f, pad + 260.0f, cy + 26.0f});
                cy += 30.0f;
            }
            for (size_t i = 0; i < spec.progress_bars.size(); ++i) {
                cy += 36.0f;
            }
            y = cy + 14.0f;
        }

        button_rects.clear();
        if (!spec.buttons.empty()) {
            float bx = pad;
            float by = y;
            for (size_t i = 0; i < spec.buttons.size(); ++i) {
                float bw = std::clamp(static_cast<float>(spec.buttons[i].text.size()) * 8.4f + 36.0f, 118.0f, 260.0f);
                if (bx + bw > pad + w && bx > pad) {
                    bx = pad;
                    by += 42.0f;
                }
                button_rects.push_back(D2D1_RECT_F{bx, by, bx + bw, by + 34.0f});
                bx += bw + 10.0f;
            }
            y = by + 44.0f;
        }

        float bottom = std::max(y + 80.0f, static_cast<float>(client_h) - 14.0f);
        log_rect = D2D1_RECT_F{pad, y, pad + w, bottom};
    }

    void render_3d_d3d11(const D2D1_RECT_F& vp) {
        if (!has_3d_pipeline) return;
        float vw = std::max(10.0f, vp.right - vp.left);
        float vh = std::max(10.0f, vp.bottom - vp.top);

        D3D11_VIEWPORT dvp{vp.left, vp.top, vw, vh, 0.0f, 1.0f};
        d3d_ctx->RSSetViewports(1, &dvp);
        d3d_ctx->RSSetState(rast_state.get());
        d3d_ctx->OMSetDepthStencilState(depth_state.get(), 0);
        d3d_ctx->VSSetShader(vs.get(), nullptr, 0);
        d3d_ctx->PSSetShader(ps.get(), nullptr, 0);
        d3d_ctx->IASetInputLayout(input_layout.get());

        ID3D11Buffer* cbs[] = {cb_scene.get()};
        d3d_ctx->VSSetConstantBuffers(0, 1, cbs);
        d3d_ctx->PSSetConstantBuffers(0, 1, cbs);

        const DxEntity3DSpec* player = nullptr;
        for (const auto& e : spec.entities_3d) {
            if (e.type == "player") { player = &e; break; }
        }
        Vec3f target = player
            ? Vec3f{static_cast<float>(player->x), static_cast<float>(player->y + 1.0), static_cast<float>(player->z)}
            : Vec3f{0.0f, 2.0f, 12.0f};
        Vec3f eye{
            target.x - static_cast<float>(std::sin(cam_yaw) * std::cos(cam_pitch) * cam_dist),
            target.y + static_cast<float>(std::sin(cam_pitch) * cam_dist + 2.5),
            target.z - static_cast<float>(std::cos(cam_yaw) * std::cos(cam_pitch) * cam_dist)
        };

        Mat4f view = Mat4f::look_at_dx(eye, target);
        Mat4f proj = Mat4f::perspective_dx(62.0f, vw / vh, 0.35f, 350.0f);
        Mat4f vp_mat = Mat4f::mul(proj, view);

        auto upload_cb = [&](const Mat4f& world, const D2D1_COLOR_F& col, bool is_grid) {
            Mat4f mvp = Mat4f::mul(vp_mat, world);
            D3D11_MAPPED_SUBRESOURCE ms{};
            if (SUCCEEDED(d3d_ctx->Map(cb_scene.get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &ms))) {
                auto* cb = reinterpret_cast<SceneCBData*>(ms.pData);
                std::memcpy(cb->mvp, mvp.m, sizeof(cb->mvp));
                std::memcpy(cb->world, world.m, sizeof(cb->world));
                cb->color[0] = col.r; cb->color[1] = col.g; cb->color[2] = col.b; cb->color[3] = col.a;
                cb->light_dir[0] = -0.42f; cb->light_dir[1] = -0.90f; cb->light_dir[2] = -0.35f; cb->light_dir[3] = 0.0f;
                cb->params[0] = 1.0f; cb->params[1] = static_cast<float>(total_time); cb->params[2] = 0.3f; cb->params[3] = is_grid ? 1.0f : 0.0f;
                d3d_ctx->Unmap(cb_scene.get(), 0);
            }
        };

        UINT stride = sizeof(Vertex3D), offset = 0;

        // Draw 3D Ground Grid
        if (mesh_grid.vb) {
            upload_cb(Mat4f::trs({target.x, 0.0f, target.z}, 0.0f, {1, 1, 1}), D2D1_COLOR_F{0.08f, 0.22f, 0.38f, 1.0f}, true);
            ID3D11Buffer* vb = mesh_grid.vb.get();
            d3d_ctx->IASetVertexBuffers(0, 1, &vb, &stride, &offset);
            d3d_ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
            d3d_ctx->Draw(mesh_grid.vertex_count, 0);
        }

        // Draw 3D Entities
        d3d_ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        for (size_t i = 0; i < spec.entities_3d.size(); ++i) {
            const auto& e = spec.entities_3d[i];
            if (e.collected || !e.alive || e.type == "terrain") continue;

            GpuMesh* gm = &mesh_box;
            Vec3f sc{static_cast<float>(e.sx), static_cast<float>(e.sy), static_cast<float>(e.sz)};
            if (i < custom_meshes.size() && custom_meshes[i].vb) {
                gm = &custom_meshes[i];
                sc = {static_cast<float>(e.scx), static_cast<float>(e.scy), static_cast<float>(e.scz)};
            } else if (e.type == "crystal") {
                gm = &mesh_crystal;
                sc = {static_cast<float>(e.radius * 1.3), static_cast<float>(e.radius * 1.6), static_cast<float>(e.radius * 1.3)};
            } else if (e.type == "ring" || e.type == "portal") {
                gm = &mesh_ring;
                sc = {static_cast<float>(e.radius), static_cast<float>(e.radius), static_cast<float>(e.radius * 0.5)};
            } else if (e.type == "player") {
                sc = {1.8f, 0.9f, 2.4f};
            }

            Mat4f world = Mat4f::trs(
                {static_cast<float>(e.x), static_cast<float>(e.y), static_cast<float>(e.z)},
                static_cast<float>(e.rot_y * 3.14159265 / 180.0),
                sc
            );
            upload_cb(world, hex_to_d2d(e.color), false);
            ID3D11Buffer* vb = gm->vb.get();
            d3d_ctx->IASetVertexBuffers(0, 1, &vb, &stride, &offset);
            d3d_ctx->Draw(gm->vertex_count, 0);
        }
    }

    void render_frame() {
        if (needs_resize) {
            needs_resize = false;
            recreate_size_dependent_resources();
        }
        if (!rtv || !d2d_rt || !brush) return;

        compute_layout();

        D2D1_COLOR_F bg = hex_to_d2d(spec.bg_color);
        float clear_rgba[4] = {bg.r, bg.g, bg.b, 1.0f};
        ID3D11RenderTargetView* rtvs[] = {rtv.get()};
        d3d_ctx->OMSetRenderTargets(1, rtvs, dsv.get());
        d3d_ctx->ClearRenderTargetView(rtv.get(), clear_rgba);
        if (dsv) d3d_ctx->ClearDepthStencilView(dsv.get(), D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.0f, 0);

        if (has_viewport && (spec.is_3d_mode || !spec.entities_3d.empty())) {
            render_3d_d3d11(vp_rect);
        }

        // Unbind D3D11 RT before Direct2D interop draw
        ID3D11RenderTargetView* null_rtv = nullptr;
        d3d_ctx->OMSetRenderTargets(1, &null_rtv, nullptr);

        d2d_rt->BeginDraw();

        D2D1_COLOR_F card_bg = hex_to_d2d(spec.card_bg);
        D2D1_COLOR_F card_border = hex_to_d2d(spec.card_border);
        D2D1_COLOR_F primary = hex_to_d2d(spec.primary_color);
        D2D1_COLOR_F accent = hex_to_d2d(spec.accent_color);
        D2D1_COLOR_F btn_bg = hex_to_d2d(spec.btn_bg);
        D2D1_COLOR_F btn_fg = hex_to_d2d(spec.btn_fg);
        D2D1_COLOR_F log_bg = hex_to_d2d(spec.log_bg);
        D2D1_COLOR_F log_fg = hex_to_d2d(spec.log_fg);
        D2D1_COLOR_F fg_col{0.97f, 0.98f, 0.99f, 1.0f};
        D2D1_COLOR_F sub_fg{0.58f, 0.64f, 0.72f, 1.0f};

        auto fill_rr = [&](const D2D1_RECT_F& r, float rad, D2D1_COLOR_F c) {
            brush->SetColor(c);
            d2d_rt->FillRoundedRectangle(D2D1_ROUNDED_RECT{r, rad, rad}, brush.get());
        };
        auto draw_rr = [&](const D2D1_RECT_F& r, float rad, D2D1_COLOR_F c, float w = 1.0f) {
            brush->SetColor(c);
            d2d_rt->DrawRoundedRectangle(D2D1_ROUNDED_RECT{r, rad, rad}, brush.get(), w);
        };
        auto draw_txt = [&](const std::string& t, const D2D1_RECT_F& r, IDWriteTextFormat* fmt, D2D1_COLOR_F c,
                            DWRITE_TEXT_ALIGNMENT ha = DWRITE_TEXT_ALIGNMENT_LEADING,
                            DWRITE_PARAGRAPH_ALIGNMENT va = DWRITE_PARAGRAPH_ALIGNMENT_NEAR) {
            if (!fmt || t.empty()) return;
            std::wstring wt = utf8_to_wide(t);
            fmt->SetTextAlignment(ha);
            fmt->SetParagraphAlignment(va);
            brush->SetColor(c);
            d2d_rt->DrawText(wt.c_str(), static_cast<UINT32>(wt.size()), fmt, r, brush.get());
        };

        // 1. Header Bar
        D2D1_RECT_F hdr{0, 0, static_cast<float>(client_w), 52.0f};
        brush->SetColor(card_bg);
        d2d_rt->FillRectangle(hdr, brush.get());
        brush->SetColor(card_border);
        d2d_rt->DrawLine(D2D1_POINT_2F{0, 52.0f}, D2D1_POINT_2F{static_cast<float>(client_w), 52.0f}, brush.get(), 1.0f);

        std::string title_txt = (spec.title.rfind("✦", 0) == 0 ? "" : "✦ ") + spec.title;
        draw_txt(title_txt, D2D1_RECT_F{18, 6, static_cast<float>(client_w) - 360.0f, 46}, fmt_title.get(), primary,
                 DWRITE_TEXT_ALIGNMENT_LEADING, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);

        // GPU + FPS Pill
        char fps_buf[64];
        std::snprintf(fps_buf, sizeof(fps_buf), "%s • %.0f FPS", gpu_name.c_str(), fps_current);
        D2D1_RECT_F gpu_pill{static_cast<float>(client_w) - 430.0f, 13.0f, static_cast<float>(client_w) - 216.0f, 39.0f};
        if (gpu_pill.left > 220.0f) {
            fill_rr(gpu_pill, 6.0f, bg);
            draw_rr(gpu_pill, 6.0f, card_border, 1.0f);
            draw_txt(fps_buf, gpu_pill, fmt_badge.get(), primary, DWRITE_TEXT_ALIGNMENT_CENTER, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        }

        // Profile Badge
        D2D1_RECT_F prof_pill{static_cast<float>(client_w) - 206.0f, 13.0f, static_cast<float>(client_w) - 14.0f, 39.0f};
        fill_rr(prof_pill, 6.0f, accent);
        draw_txt(spec.badge_label, prof_pill, fmt_badge.get(), D2D1_COLOR_F{0.04f, 0.06f, 0.10f, 1.0f},
                 DWRITE_TEXT_ALIGNMENT_CENTER, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);

        // 2. Viewport Frame / 2D Stage
        if (has_viewport) {
            if (spec.is_3d_mode || !spec.entities_3d.empty()) {
                draw_rr(vp_rect, 8.0f, primary, 1.5f);
                char hud[192];
                std::snprintf(hud, sizeof(hud), "DIRECTX 11 3D • SCORE: %d • [WASD] Move [SPACE] Jump [Q/E or Drag] Orbit [Wheel] Zoom", score_3d);
                draw_txt(hud, D2D1_RECT_F{vp_rect.left + 12, vp_rect.top + 8, vp_rect.right - 12, vp_rect.top + 32},
                         fmt_badge.get(), primary);
            } else {
                // 2D Stage Render
                fill_rr(vp_rect, 8.0f, D2D1_COLOR_F{0.02f, 0.035f, 0.07f, 1.0f});
                draw_rr(vp_rect, 8.0f, primary, 1.5f);
                d2d_rt->PushAxisAlignedClip(vp_rect, D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

                float vp_h = vp_rect.bottom - vp_rect.top;
                float scale_y = vp_h / static_cast<float>(std::max(300.0, spec.world_height));
                float scale_x = scale_y;
                float ox = vp_rect.left - static_cast<float>(cam2d_x) * scale_x;
                float oy = vp_rect.top;

                // Subtle grid
                brush->SetColor(D2D1_COLOR_F{0.08f, 0.15f, 0.25f, 0.5f});
                for (int gx = 0; gx < static_cast<int>(spec.world_width); gx += 80) {
                    float sx = ox + gx * scale_x;
                    if (sx >= vp_rect.left && sx <= vp_rect.right) {
                        d2d_rt->DrawLine(D2D1_POINT_2F{sx, vp_rect.top}, D2D1_POINT_2F{sx, vp_rect.bottom}, brush.get(), 1.0f);
                    }
                }
                // Floor
                float fy = oy + static_cast<float>(spec.world_height - 28.0) * scale_y;
                brush->SetColor(D2D1_COLOR_F{0.10f, 0.18f, 0.30f, 1.0f});
                d2d_rt->FillRectangle(D2D1_RECT_F{vp_rect.left, fy, vp_rect.right, vp_rect.bottom}, brush.get());

                for (const auto& e : spec.entities_2d) {
                    if (!e.alive || e.collected) continue;
                    float ex = ox + static_cast<float>(e.x) * scale_x;
                    float ey = oy + static_cast<float>(e.y) * scale_y;
                    float ew = static_cast<float>(e.w) * scale_x;
                    float eh = static_cast<float>(e.h) * scale_y;
                    D2D1_COLOR_F ec = hex_to_d2d(e.color);
                    if (e.type == "coin" || e.type == "heart" || e.type == "orb" || e.type == "portal") {
                        float r = static_cast<float>(e.radius) * scale_x;
                        brush->SetColor(ec);
                        d2d_rt->FillEllipse(D2D1_ELLIPSE{D2D1_POINT_2F{ex, ey}, r, r}, brush.get());
                    } else {
                        fill_rr(D2D1_RECT_F{ex, ey, ex + ew, ey + eh}, e.is_player ? 5.0f : 3.0f, ec);
                        if (e.is_player) {
                            brush->SetColor(D2D1_COLOR_F{1, 1, 1, 0.9f});
                            d2d_rt->FillRectangle(D2D1_RECT_F{ex + ew * 0.45f, ey + eh * 0.22f, ex + ew * 0.85f, ey + eh * 0.42f}, brush.get());
                        }
                    }
                }
                for (const auto& b : bullets_2d) {
                    float bx = ox + static_cast<float>(b.x) * scale_x;
                    float by = oy + static_cast<float>(b.y) * scale_y;
                    brush->SetColor(hex_to_d2d(b.color));
                    d2d_rt->FillEllipse(D2D1_ELLIPSE{D2D1_POINT_2F{bx, by}, 4.5f, 3.0f}, brush.get());
                }

                d2d_rt->PopAxisAlignedClip();
                char hud2[192];
                std::snprintf(hud2, sizeof(hud2), "DIRECT2D STAGE • SCORE: %d • LIVES: %d • [A/D] Move [W/SPACE] Jump [X] Dash [Z] Fire [R] Reset", score_2d, lives_2d);
                draw_txt(hud2, D2D1_RECT_F{vp_rect.left + 12, vp_rect.top + 8, vp_rect.right - 12, vp_rect.top + 32},
                         fmt_badge.get(), primary);
            }
        }

        // 3. Cards Grid
        float pad = 14.0f;
        float w = static_cast<float>(client_w) - pad * 2.0f;
        float cur_y = has_viewport ? (vp_rect.bottom + 10.0f) : 62.0f;
        if (!spec.cards.empty() && card_rects.size() == spec.cards.size()) {
            for (size_t i = 0; i < spec.cards.size(); ++i) {
                const auto& c = spec.cards[i];
                const auto& cr = card_rects[i];
                float cx = cr.left, cy = cr.top, cw = cr.right - cr.left, ch = cr.bottom - cr.top;
                fill_rr(cr, 8.0f, card_bg);
                draw_rr(cr, 8.0f, card_border, 1.0f);
                brush->SetColor(primary);
                d2d_rt->FillRectangle(D2D1_RECT_F{cx + 10, cy, cx + cw - 10, cy + 2.5f}, brush.get());

                std::string ctitle = (c.icon.empty() ? "✦ " : c.icon + " ") + c.title;
                draw_txt(ctitle, D2D1_RECT_F{cx + 14, cy + 8, cx + cw - 92, cy + 32}, fmt_card_title.get(), primary);
                if (!c.badge.empty()) {
                    D2D1_RECT_F br{cx + cw - 88, cy + 8, cx + cw - 10, cy + 26};
                    fill_rr(br, 4.0f, card_border);
                    draw_txt(c.badge, br, fmt_badge.get(), accent, DWRITE_TEXT_ALIGNMENT_CENTER, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
                }
                draw_txt(c.text, D2D1_RECT_F{cx + 14, cy + 34, cx + cw - 14, cy + ch - 8}, fmt_body.get(), fg_col);
                cur_y = std::max(cur_y, cr.bottom + 10.0f);
            }
        }

        // 4. Controls Panel
        if (!spec.inputs.empty() || !spec.sliders.empty() || !spec.toggles.empty() || !spec.progress_bars.empty()) {
            float panel_top = cur_y;
            float cy = panel_top + 10.0f;
            float panel_h = 16.0f +
                            spec.inputs.size() * 52.0f +
                            spec.sliders.size() * 42.0f +
                            spec.toggles.size() * 30.0f +
                            spec.progress_bars.size() * 36.0f;
            D2D1_RECT_F pr_panel{pad, panel_top, pad + w, panel_top + panel_h};
            fill_rr(pr_panel, 8.0f, card_bg);
            draw_rr(pr_panel, 8.0f, card_border, 1.0f);

            for (size_t i = 0; i < spec.inputs.size(); ++i) {
                const auto& inp = spec.inputs[i];
                draw_txt("Input [" + inp.binding + "]:", D2D1_RECT_F{pad + 12, cy, pad + w - 12, cy + 18}, fmt_badge.get(), sub_fg);
                D2D1_RECT_F ir = input_rects[i];
                fill_rr(ir, 5.0f, D2D1_COLOR_F{0.11f, 0.16f, 0.23f, 1.0f});
                draw_rr(ir, 5.0f, (active_input == static_cast<int>(i)) ? primary : card_border, 1.2f);
                std::string shown = inp.value.empty() ? inp.placeholder : inp.value;
                if (active_input == static_cast<int>(i) && (static_cast<int>(total_time * 2) % 2 == 0)) shown += "|";
                draw_txt(shown, D2D1_RECT_F{ir.left + 8, ir.top, ir.right - 8, ir.bottom}, fmt_body.get(),
                         inp.value.empty() ? sub_fg : fg_col, DWRITE_TEXT_ALIGNMENT_LEADING, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
                cy += 52.0f;
            }
            for (size_t i = 0; i < spec.sliders.size(); ++i) {
                const auto& sl = spec.sliders[i];
                char sbuf[128];
                std::snprintf(sbuf, sizeof(sbuf), "%s: %.0f", sl.label.c_str(), sl.current_val);
                draw_txt(sbuf, D2D1_RECT_F{pad + 12, cy, pad + w - 12, cy + 18}, fmt_badge.get(), sub_fg);
                D2D1_RECT_F sr = slider_rects[i];
                D2D1_RECT_F track{sr.left, sr.top + 3.0f, sr.right, sr.top + 9.0f};
                fill_rr(track, 3.0f, log_bg);
                double denom = std::max(1e-6, sl.max_val - sl.min_val);
                float t = static_cast<float>(std::clamp((sl.current_val - sl.min_val) / denom, 0.0, 1.0));
                float kx = track.left + (track.right - track.left) * t;
                fill_rr(D2D1_RECT_F{track.left, track.top, kx, track.bottom}, 3.0f, primary);
                brush->SetColor(accent);
                d2d_rt->FillEllipse(D2D1_ELLIPSE{D2D1_POINT_2F{kx, (track.top + track.bottom) * 0.5f}, 7.0f, 7.0f}, brush.get());
                cy += 42.0f;
            }
            for (size_t i = 0; i < spec.toggles.size(); ++i) {
                const auto& tg = spec.toggles[i];
                D2D1_RECT_F box{pad + 12, cy + 4, pad + 30, cy + 22};
                fill_rr(box, 4.0f, tg.is_checked ? primary : log_bg);
                draw_rr(box, 4.0f, tg.is_checked ? primary : card_border, 1.2f);
                if (tg.is_checked) {
                    draw_txt("✓", box, fmt_badge.get(), D2D1_COLOR_F{0.03f, 0.06f, 0.1f, 1.0f},
                             DWRITE_TEXT_ALIGNMENT_CENTER, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
                }
                draw_txt(tg.label, D2D1_RECT_F{pad + 38, cy + 2, pad + w - 12, cy + 24}, fmt_body.get(), fg_col,
                         DWRITE_TEXT_ALIGNMENT_LEADING, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
                cy += 30.0f;
            }
            for (size_t i = 0; i < spec.progress_bars.size(); ++i) {
                const auto& pr = spec.progress_bars[i];
                char pbuf[128];
                std::snprintf(pbuf, sizeof(pbuf), "%s (%.0f%%)", pr.label.c_str(), pr.progress);
                draw_txt(pbuf, D2D1_RECT_F{pad + 12, cy, pad + w - 12, cy + 18}, fmt_badge.get(), sub_fg);
                D2D1_RECT_F track{pad + 12, cy + 20, pad + w - 12, cy + 30};
                fill_rr(track, 5.0f, log_bg);
                float pct = static_cast<float>(std::clamp(pr.progress / 100.0, 0.0, 1.0));
                if (pct > 0.0f) {
                    fill_rr(D2D1_RECT_F{track.left, track.top, track.left + (track.right - track.left) * pct, track.bottom}, 5.0f, accent);
                }
                cy += 36.0f;
            }
        }

        // 5. Buttons Toolbar
        for (size_t i = 0; i < button_rects.size(); ++i) {
            const auto& b = spec.buttons[i];
            const auto& br = button_rects[i];
            bool hov = (hover_btn == static_cast<int>(i));
            fill_rr(br, 6.0f, hov ? primary : btn_bg);
            draw_rr(br, 6.0f, hov ? accent : card_border, 1.0f);
            std::string lbl = (!b.snippet.empty() ? "⚡ " : "") + b.text;
            draw_txt(lbl, br, fmt_btn.get(), hov ? D2D1_COLOR_F{0.03f, 0.06f, 0.1f, 1.0f} : btn_fg,
                     DWRITE_TEXT_ALIGNMENT_CENTER, DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        }

        // 6. Log Drawer
        fill_rr(log_rect, 8.0f, log_bg);
        draw_rr(log_rect, 8.0f, card_border, 1.0f);
        d2d_rt->PushAxisAlignedClip(log_rect, D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
        float line_h = 17.5f;
        int max_lines = std::max(1, static_cast<int>((log_rect.bottom - log_rect.top - 14.0f) / line_h));
        int total_l = static_cast<int>(logs.size());
        int end_idx = std::max(0, total_l - log_scroll);
        int start_idx = std::max(0, end_idx - max_lines);
        float ly = log_rect.top + 8.0f;
        for (int idx = start_idx; idx < end_idx; ++idx) {
            const auto& entry = logs[static_cast<size_t>(idx)];
            D2D1_COLOR_F lc = log_fg;
            if (entry.kind == 1) lc = D2D1_COLOR_F{0.22f, 0.74f, 0.97f, 1.0f};
            else if (entry.kind == 2) lc = D2D1_COLOR_F{0.98f, 0.80f, 0.08f, 1.0f};
            else if (entry.kind == 3) lc = D2D1_COLOR_F{0.75f, 0.52f, 0.99f, 1.0f};
            draw_txt(entry.text, D2D1_RECT_F{log_rect.left + 10, ly, log_rect.right - 10, ly + line_h}, fmt_mono.get(), lc);
            ly += line_h;
        }
        d2d_rt->PopAxisAlignedClip();

        d2d_rt->EndDraw();
        swapchain->Present(1, 0);
    }

    int run(int max_frames = 0, bool show_window = true) {
        if (!init_d3d_and_d2d()) return 1;

        push_log("[Loop OS DirectX 11] Ventana '" + spec.title + "' inicializada (" + spec.pipeline + ").", 3);
        push_log("[GPU Adapter] " + gpu_name + " (Direct3D 11 + Direct2D + DirectWrite, Zero-Python).", 0);

        if (show_window) {
            ShowWindow(hwnd, SW_SHOW);
            UpdateWindow(hwnd);
            SetForegroundWindow(hwnd);
            SetFocus(hwnd);
            if (!spec.tones.empty()) {
                play_tone(spec.tones[0].freq_hz, spec.tones[0].duration_ms);
            }
        }

        auto prev = std::chrono::high_resolution_clock::now();
        int rendered = 0;

        MSG msg{};
        while (running) {
            while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
                if (msg.message == WM_QUIT) {
                    running = false;
                    break;
                }
                TranslateMessage(&msg);
                DispatchMessageW(&msg);
            }
            if (!running) break;

            auto now = std::chrono::high_resolution_clock::now();
            double dt = std::chrono::duration<double>(now - prev).count();
            prev = now;
            dt = std::clamp(dt, 0.001, 0.05);

            fps_frames++;
            fps_timer += dt;
            if (fps_timer >= 0.4) {
                fps_current = fps_frames / fps_timer;
                fps_frames = 0;
                fps_timer = 0.0;
            }

            update_simulation(dt);
            render_frame();
            rendered++;

            if (max_frames > 0 && rendered >= max_frames) {
                running = false;
                break;
            }
        }

        if (api.pPlaySoundA) {
            api.pPlaySoundA(nullptr, nullptr, 0);
        }
        if (hwnd) {
            DestroyWindow(hwnd);
            hwnd = nullptr;
        }
        return 0;
    }
};

} // namespace dx_native

#endif // _WIN32 && !__EMSCRIPTEN__

} // namespace looping
