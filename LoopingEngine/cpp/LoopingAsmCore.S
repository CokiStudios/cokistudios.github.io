/* =========================================================================
 * Looping Engine - Universal Assembly Core (ARM64 & x86_64)
 * Fast pixel clear, rect blit, FNV-1a hashing & scalar lerp with zero runtime deps.
 * ========================================================================= */

#if defined(__APPLE__)
#define CSYM(name) _##name
#else
#define CSYM(name) name
#endif

.text
.p2align 4

#if defined(__aarch64__) || defined(_M_ARM64)

/* void lp_asm_clear_bgra32(uint32_t* dst, size_t count, uint32_t bgra) */
.globl CSYM(lp_asm_clear_bgra32)
CSYM(lp_asm_clear_bgra32):
    cbz     x1, .Lclear_done_a64
    /* Duplicate 32-bit pixel into 64-bit x3 for 2-pixel stores */
    mov     w3, w2
    bfi     x3, x2, #32, #32
.Lclear_pair_a64:
    cmp     x1, #2
    b.lo    .Lclear_tail_a64
    str     x3, [x0], #8
    sub     x1, x1, #2
    b       .Lclear_pair_a64
.Lclear_tail_a64:
    cbz     x1, .Lclear_done_a64
    str     w2, [x0]
.Lclear_done_a64:
    ret

/* void lp_asm_fill_rect_bgra32(uint32_t* fb, int fb_w, int fb_h, int x, int y, int w, int h, uint32_t bgra) */
.globl CSYM(lp_asm_fill_rect_bgra32)
CSYM(lp_asm_fill_rect_bgra32):
    /* x0=fb, w1=fb_w, w2=fb_h, w3=x, w4=y, w5=w, w6=h, w7=bgra */
    cmp     w5, #0
    b.le    .Lrect_done_a64
    cmp     w6, #0
    b.le    .Lrect_done_a64
    /* Clamp x0 = max(x, 0), x1 = min(x+w, fb_w) */
    add     w8, w3, w5
    cmp     w3, #0
    csel    w3, wzr, w3, lt
    cmp     w8, w1
    csel    w8, w1, w8, gt
    sub     w5, w8, w3
    cmp     w5, #0
    b.le    .Lrect_done_a64
    /* Clamp y0 = max(y, 0), y1 = min(y+h, fb_h) */
    add     w9, w4, w6
    cmp     w4, #0
    csel    w4, wzr, w4, lt
    cmp     w9, w2
    csel    w9, w2, w9, gt
    sub     w6, w9, w4
    cmp     w6, #0
    b.le    .Lrect_done_a64

    sxtw    x10, w1         /* stride in pixels */
    sxtw    x11, w4         /* start y */
    sxtw    x12, w3         /* start x */
    mul     x11, x11, x10
    add     x11, x11, x12
    lsl     x11, x11, #2
    add     x0, x0, x11     /* row_ptr */
    lsl     x10, x10, #2    /* stride_bytes */
.Lrect_row_a64:
    mov     x13, x0
    mov     w14, w5
.Lrect_col_a64:
    str     w7, [x13], #4
    subs    w14, w14, #1
    b.ne    .Lrect_col_a64
    add     x0, x0, x10
    subs    w6, w6, #1
    b.ne    .Lrect_row_a64
.Lrect_done_a64:
    ret

/* uint64_t lp_asm_fnv1a64(const uint8_t* data, size_t len) */
.globl CSYM(lp_asm_fnv1a64)
CSYM(lp_asm_fnv1a64):
    /* FNV-1a offset basis 0xcbf29ce484222325 */
    movz    x2, #0x2325
    movk    x2, #0x8422, lsl #16
    movk    x2, #0x9ce4, lsl #32
    movk    x2, #0xcbf2, lsl #48
    /* FNV prime 0x00000100000001b3 */
    movz    x3, #0x01b3
    movk    x3, #0x0100, lsl #32
    cbz     x1, .Lfnv_done_a64
.Lfnv_loop_a64:
    ldrb    w4, [x0], #1
    eor     x2, x2, x4
    mul     x2, x2, x3
    subs    x1, x1, #1
    b.ne    .Lfnv_loop_a64
.Lfnv_done_a64:
    mov     x0, x2
    ret

/* float lp_asm_lerp_f32(float a, float b, float t) */
.globl CSYM(lp_asm_lerp_f32)
CSYM(lp_asm_lerp_f32):
    fsub    s3, s1, s0
    fmadd   s0, s3, s2, s0
    ret

#elif defined(__x86_64__) || defined(_M_X64)

/* void lp_asm_clear_bgra32(uint32_t* dst, size_t count, uint32_t bgra) */
.globl CSYM(lp_asm_clear_bgra32)
CSYM(lp_asm_clear_bgra32):
    /* rdi=dst, rsi=count, edx=bgra */
    test    %rsi, %rsi
    jz      .Lclear_done_x64
    mov     %edx, %eax
    mov     %rsi, %rcx
    cld
    rep     stosl
.Lclear_done_x64:
    ret

/* void lp_asm_fill_rect_bgra32(uint32_t* fb, int fb_w, int fb_h, int x, int y, int w, int h, uint32_t bgra) */
.globl CSYM(lp_asm_fill_rect_bgra32)
CSYM(lp_asm_fill_rect_bgra32):
    /* rdi=fb, esi=fb_w, edx=fb_h, ecx=x, r8d=y, r9d=w, [rsp+8]=h, [rsp+16]=bgra */
    push    %rbx
    push    %r12
    mov     24(%rsp), %r10d     /* h */
    mov     32(%rsp), %eax      /* bgra */
    test    %r9d, %r9d
    jle     .Lrect_done_x64
    test    %r10d, %r10d
    jle     .Lrect_done_x64

    /* Clamp x */
    mov     %ecx, %r11d
    add     %r9d, %r11d         /* x + w */
    test    %ecx, %ecx
    jge     .Lx0_ok_x64
    xor     %ecx, %ecx
.Lx0_ok_x64:
    cmp     %esi, %r11d
    jle     .Lx1_ok_x64
    mov     %esi, %r11d
.Lx1_ok_x64:
    sub     %ecx, %r11d         /* clamped_w */
    test    %r11d, %r11d
    jle     .Lrect_done_x64

    /* Clamp y */
    mov     %r8d, %r12d
    add     %r10d, %r12d        /* y + h */
    test    %r8d, %r8d
    jge     .Ly0_ok_x64
    xor     %r8d, %r8d
.Ly0_ok_x64:
    cmp     %edx, %r12d
    jle     .Ly1_ok_x64
    mov     %edx, %r12d
.Ly1_ok_x64:
    sub     %r8d, %r12d         /* clamped_h */
    test    %r12d, %r12d
    jle     .Lrect_done_x64

    movslq  %esi, %rsi          /* stride_px */
    movslq  %r8d, %r8
    movslq  %ecx, %rcx
    imul    %rsi, %r8
    add     %rcx, %r8
    lea     (%rdi, %r8, 4), %rbx
    shl     $2, %rsi            /* stride_bytes */
    cld
.Lrect_row_x64:
    mov     %rbx, %rdi
    mov     %r11d, %ecx
    rep     stosl
    add     %rsi, %rbx
    dec     %r12d
    jnz     .Lrect_row_x64
.Lrect_done_x64:
    pop     %r12
    pop     %rbx
    ret

/* uint64_t lp_asm_fnv1a64(const uint8_t* data, size_t len) */
.globl CSYM(lp_asm_fnv1a64)
CSYM(lp_asm_fnv1a64):
    movabs  $0xcbf29ce484222325, %rax
    movabs  $0x00000100000001b3, %r8
    test    %rsi, %rsi
    jz      .Lfnv_done_x64
.Lfnv_loop_x64:
    movzbl  (%rdi), %ecx
    xor     %rcx, %rax
    imul    %r8, %rax
    inc     %rdi
    dec     %rsi
    jnz     .Lfnv_loop_x64
.Lfnv_done_x64:
    ret

/* float lp_asm_lerp_f32(float a, float b, float t) */
.globl CSYM(lp_asm_lerp_f32)
CSYM(lp_asm_lerp_f32):
    subss   %xmm0, %xmm1
    mulss   %xmm2, %xmm1
    addss   %xmm1, %xmm0
    ret

#endif
