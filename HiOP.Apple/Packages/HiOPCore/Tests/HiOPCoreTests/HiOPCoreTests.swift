import XCTest
@testable import HiOPCore

final class HiOPCoreTests: XCTestCase {
    func testEmbeddedEngineExecutionAnd3DRender() {
        let bridge = LoopingCoreBridge()
        let code = WorkspaceTemplates.arch31APresets[0].code
        let res = bridge.execute(code: code, channel: .prod)
        XCTAssertTrue(res.ok)
        XCTAssertTrue(res.is3DMode)
        XCTAssertFalse(res.logs.isEmpty)

        let snap = bridge.step(dt: 1.0 / 60.0, viewWidth: 320, viewHeight: 200)
        XCTAssertTrue(snap.is3DMode)
        let img = bridge.renderStageCGImage(snapshot: snap, width: 320, height: 200)
        XCTAssertNotNil(img)
    }

    func testSelfTestAndInvisCompile() {
        let bridge = LoopingCoreBridge()
        let st = bridge.runSelfTest()
        XCTAssertTrue(st.ok)
        XCTAssertGreaterThan(st.total, 0)
        XCTAssertEqual(st.passed, st.total)

        let inv = bridge.encodeInvisHex("say(\"Apple Native\")", target: "metal4")
        XCTAssertTrue(inv.valid)
        XCTAssertGreaterThan(inv.byteLength, 0)
    }

    func testBlockCompilerProducesExecutableLoop() {
        let bridge = LoopingCoreBridge()
        for kit in BlockLoopCompiler.starterKits {
            let source = BlockLoopCompiler.compile(kit.blocks)
            let diags = LoopingBuiltInAnalyzer.checkCode(source)
            XCTAssertFalse(diags.contains(where: { $0.severity == "Error" }), "Kit \(kit.id) had syntax error")
            let execRes = bridge.execute(code: source, channel: .prod)
            XCTAssertTrue(execRes.ok, "Kit \(kit.id) failed execution")
        }
    }
}
