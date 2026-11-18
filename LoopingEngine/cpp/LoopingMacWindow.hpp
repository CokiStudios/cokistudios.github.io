#pragma once

#include "LoopingDirectXWindow.hpp"

#if defined(__APPLE__) && (!defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE) && !defined(LOOPING_NO_SUBPROCESS)
#include <cstddef>
#include <cstdint>

extern "C" {
void lp_asm_clear_bgra32(uint32_t* dst, size_t count, uint32_t bgra);
void lp_asm_fill_rect_bgra32(uint32_t* fb, int fb_w, int fb_h, int x, int y, int w, int h, uint32_t bgra);
uint64_t lp_asm_fnv1a64(const uint8_t* data, size_t len);
float lp_asm_lerp_f32(float a, float b, float t);
}

namespace looping {
namespace mac_native {

int run_mac_native_window(const DirectXWindowSpec& spec, int max_frames = 0, bool show_window = true);

} // namespace mac_native
} // namespace looping
#endif
