import CLoopingStageCore
import CoreGraphics
import Foundation

public struct StageInputMask: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let left = StageInputMask(rawValue: 1 << 0)
    public static let right = StageInputMask(rawValue: 1 << 1)
    public static let up = StageInputMask(rawValue: 1 << 2)
    public static let down = StageInputMask(rawValue: 1 << 3)
    public static let jump = StageInputMask(rawValue: 1 << 4)
    public static let shoot = StageInputMask(rawValue: 1 << 5)
    public static let dash = StageInputMask(rawValue: 1 << 6)
    public static let sprint = StageInputMask(rawValue: 1 << 7)
}

/// Thread-safe Swift bridge to the embedded C++17 & Assembly Looping Engine (`CLoopingStageCore`).
public final class LoopingCoreBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var handle: Int32 = 0
    private var framebuffer2D: [UInt32] = []

    public init() {}

    deinit {
        lock.lock()
        let h = handle
        handle = 0
        lock.unlock()
        if h > 0 {
            lp_destroy(h)
        }
    }

    private func ensureHandleLocked() -> Int32 {
        if handle <= 0 {
            handle = lp_create()
        }
        return handle
    }

    private static func stringFromC(_ ptr: UnsafePointer<CChar>?) -> String {
        guard let ptr else { return "" }
        return String(cString: ptr)
    }

    public func setChannel(_ channel: LoopingChannel) {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        channel.rawValue.withCString { cStr in
            lp_set_channel(h, cStr)
        }
    }

    public func execute(code: String, channel: LoopingChannel = .prod) -> ExecutionResponse {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        channel.rawValue.withCString { ch in
            lp_set_channel(h, ch)
        }
        let jsonStr = code.withCString { src in
            Self.stringFromC(lp_execute(h, src))
        }
        guard let data = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ExecutionResponse.self, from: data) else {
            return ExecutionResponse(ok: false, is3DMode: false, elapsedMs: 0, logs: [jsonStr])
        }
        return parsed
    }

    public func setInput(_ mask: StageInputMask, yawDelta: Double = 0.0, pitchDelta: Double = 0.0) {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        lp_set_input(h, mask.rawValue, yawDelta, pitchDelta)
    }

    public func step(dt: Double, viewWidth: Double, viewHeight: Double) -> StageSnapshot {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        let jsonStr = Self.stringFromC(lp_step(h, dt, viewWidth, viewHeight))
        guard let data = jsonStr.data(using: .utf8),
              let snap = try? JSONDecoder().decode(StageSnapshot.self, from: data) else {
            return StageSnapshot()
        }
        return snap
    }

    public func snapshot(viewWidth: Double, viewHeight: Double) -> StageSnapshot {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        let jsonStr = Self.stringFromC(lp_get_snapshot_json(h, viewWidth, viewHeight))
        guard let data = jsonStr.data(using: .utf8),
              let snap = try? JSONDecoder().decode(StageSnapshot.self, from: data) else {
            return StageSnapshot()
        }
        return snap
    }

    public func uiSnapshot() -> StageUiSnapshot {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        let jsonStr = Self.stringFromC(lp_get_ui_json(h))
        guard let data = jsonStr.data(using: .utf8),
              let ui = try? JSONDecoder().decode(StageUiSnapshot.self, from: data) else {
            return StageUiSnapshot()
        }
        return ui
    }

    public func clickButton(_ actionOrLabel: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        let h = ensureHandleLocked()
        let jsonStr = actionOrLabel.withCString { ptr in
            Self.stringFromC(lp_click_button(h, ptr))
        }
        if let data = jsonStr.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(ExecutionResponse.self, from: data) {
            return parsed.logs
        }
        return []
    }

    public func toggle3D() {
        lock.lock()
        defer { lock.unlock() }
        lp_toggle_3d(ensureHandleLocked())
    }

    public func cycleCamera3D() {
        lock.lock()
        defer { lock.unlock() }
        lp_cycle_camera3d(ensureHandleLocked())
    }

    public func restart() -> ExecutionResponse {
        lock.lock()
        defer { lock.unlock() }
        let jsonStr = Self.stringFromC(lp_restart(ensureHandleLocked()))
        guard let data = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ExecutionResponse.self, from: data) else {
            return ExecutionResponse()
        }
        return parsed
    }

    /// Renders either the 3D Z-buffer RGBA framebuffer from C++17 OR the 2D stage entities via ASM + CoreGraphics into a CGImage.
    public func renderStageCGImage(snapshot: StageSnapshot, width: Int, height: Int) -> CGImage? {
        let cw = max(64, min(1280, width))
        let ch = max(48, min(720, height))

        if snapshot.is3DMode {
            lock.lock()
            let h = ensureHandleLocked()
            guard let ptr = lp_render_3d_rgba(h, Int32(cw), Int32(ch)) else {
                lock.unlock()
                return nil
            }
            let byteCount = cw * ch * 4
            let data = Data(bytes: ptr, count: byteCount)
            lock.unlock()

            let cs = CGColorSpaceCreateDeviceRGB()
            guard let provider = CGDataProvider(data: data as CFData) else { return nil }
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
            return CGImage(
                width: cw,
                height: ch,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: cw * 4,
                space: cs,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        }

        // 2D Stage fast ASM clear + entity draw
        let count = cw * ch
        if framebuffer2D.count != count {
            framebuffer2D = [UInt32](repeating: 0, count: count)
        }
        let bgPx = Self.parseHexBGRA(snapshot.scenario.bg, fallback: 0xFF070B14)
        let gridPx: UInt32 = 0xFF172338
        framebuffer2D.withUnsafeMutableBufferPointer { buf in
            guard let base = buf.baseAddress else { return }
            lp_asm_clear_bgra32(base, buf.count, bgPx)
            var gx: Int32 = 0
            while gx < Int32(cw) {
                lp_asm_fill_rect_bgra32(base, Int32(cw), Int32(ch), gx, 0, 1, Int32(ch), gridPx)
                gx += 40
            }
            var gy: Int32 = 0
            while gy < Int32(ch) {
                lp_asm_fill_rect_bgra32(base, Int32(cw), Int32(ch), 0, gy, Int32(cw), 1, gridPx)
                gy += 40
            }

            let worldW = max(320.0, snapshot.world.width)
            let worldH = max(200.0, snapshot.world.height)
            let sx = Double(cw) / worldW
            let sy = Double(ch) / worldH

            for e in snapshot.entities where e.alive && !e.collected && !e.broken {
                let px = Int32((e.x - snapshot.camera.x * 0.25) * sx)
                let py = Int32((e.y - snapshot.camera.y * 0.25) * sy)
                let pw = max(6, Int32((e.w > 0 ? e.w : e.r * 2.0) * sx))
                let ph = max(6, Int32((e.h > 0 ? e.h : e.r * 2.0) * sy))
                let col = Self.parseHexBGRA(e.color, fallback: e.type == "player" ? 0xFF00F5D4 : 0xFF38BDF8)
                lp_asm_fill_rect_bgra32(base, Int32(cw), Int32(ch), px, py, pw, ph, col)
                if e.type == "player" {
                    lp_asm_fill_rect_bgra32(base, Int32(cw), Int32(ch), px + 2, py + 2, max(2, pw - 4), 4, 0xFFFFFFFF)
                }
            }
        }

        let byteCount = cw * ch * 4
        let data = framebuffer2D.withUnsafeBytes { Data($0.prefix(byteCount)) }
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        return CGImage(
            width: cw,
            height: ch,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: cw * 4,
            space: cs,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    public func formatCode(_ code: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        return code.withCString { ptr in
            Self.stringFromC(lp_format_code(ptr))
        }
    }

    public func encodeInvisHex(_ code: String, target: String = "shine_ui") -> InvisEncodeResponse {
        lock.lock()
        defer { lock.unlock() }
        let jsonStr = code.withCString { cPtr in
            target.withCString { tPtr in
                Self.stringFromC(lp_invis_encode_hex(cPtr, tPtr))
            }
        }
        guard let data = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(InvisEncodeResponse.self, from: data) else {
            return InvisEncodeResponse()
        }
        return parsed
    }

    public func benchmarkVM() -> BenchResponse {
        lock.lock()
        defer { lock.unlock() }
        let jsonStr = Self.stringFromC(lp_bench())
        guard let data = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(BenchResponse.self, from: data) else {
            return BenchResponse()
        }
        return parsed
    }

    public func runSelfTest() -> SelfTestResponse {
        lock.lock()
        defer { lock.unlock() }
        let jsonStr = Self.stringFromC(lp_run_selftest())
        guard let data = jsonStr.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(SelfTestResponse.self, from: data) else {
            return SelfTestResponse()
        }
        return parsed
    }

    public func versionJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return Self.stringFromC(lp_version_json())
    }

    public func asmDigest(for text: String) -> UInt64 {
        let bytes = Array(text.utf8)
        return bytes.withUnsafeBytes { raw in
            lp_asm_fnv1a64(raw.baseAddress, raw.count)
        }
    }

    private static func parseHexBGRA(_ hex: String, fallback: UInt32) -> UInt32 {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }
        if clean.count == 3 {
            clean = clean.map { "\($0)\($0)" }.joined()
        }
        guard clean.count >= 6, let rgb = UInt32(clean.prefix(6), radix: 16) else {
            return fallback
        }
        return 0xFF000000 | rgb
    }
}
