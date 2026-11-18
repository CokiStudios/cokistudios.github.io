#ifndef LOOPING_STAGE_CORE_H
#define LOOPING_STAGE_CORE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int32_t lp_create(void);
void lp_destroy(int32_t h);
const char* lp_execute(int32_t h, const char* code);
const char* lp_parse_line(int32_t h, const char* line);
const char* lp_eval_expr(int32_t h, const char* expr_str);
void lp_set_channel(int32_t h, const char* channel);
void lp_set_input(int32_t h, uint32_t keys_mask, double yaw_delta, double pitch_delta);
const char* lp_step(int32_t h, double dt, double view_w, double view_h);
const char* lp_get_snapshot_json(int32_t h, double view_w, double view_h);
const uint8_t* lp_render_3d_rgba(int32_t h, int w, int h_px);
const uint8_t* lp_render_3d_bgra(int32_t h, int w, int h_px);
const char* lp_get_vars_json(int32_t h);
const char* lp_get_ui_json(int32_t h);
const char* lp_click_button(int32_t h, const char* id_or_label);
void lp_heal_player(int32_t h, double amt);
void lp_boost_player(int32_t h, double power);
void lp_activate_preset(int32_t h, int idx);
void lp_set_time_scale(int32_t h, double ts);
void lp_toggle_3d(int32_t h);
void lp_cycle_camera3d(int32_t h);
const char* lp_restart(int32_t h);
const char* lp_check_ast(const char* code);
const char* lp_format_code(const char* code);
const char* lp_invis_encode_hex(const char* code, const char* target_ui);
const char* lp_bench(void);
const char* lp_run_selftest(void);
const char* lp_version_json(void);

/* Assembly fast-path core (ARM64 & x86_64) */
void lp_asm_clear_bgra32(uint32_t* dst, size_t count, uint32_t bgra);
void lp_asm_fill_rect_bgra32(uint32_t* fb, int fb_w, int fb_h, int x, int y, int w, int h, uint32_t bgra);
uint64_t lp_asm_fnv1a64(const uint8_t* data, size_t len);
float lp_asm_lerp_f32(float a, float b, float t);

#ifdef __cplusplus
}
#endif

#endif /* LOOPING_STAGE_CORE_H */
