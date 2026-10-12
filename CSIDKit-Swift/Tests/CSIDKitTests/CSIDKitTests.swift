import XCTest
@testable import CSIDKit

final class CSIDKitTests: XCTestCase {
    func testCodeVerifierGeneration() {
        #if canImport(AuthenticationServices)
        let verifier = CSIDManager.shared.generateCodeVerifier()
        XCTAssertFalse(verifier.isEmpty)
        XCTAssertGreaterThanOrEqual(verifier.count, 43)
        #endif
    }

    func testCodeChallengeSHA256() {
        #if canImport(AuthenticationServices)
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = CSIDManager.shared.sha256Base64URL(verifier)
        XCTAssertFalse(challenge.isEmpty)
        XCTAssertFalse(challenge.contains("+"))
        XCTAssertFalse(challenge.contains("/"))
        XCTAssertFalse(challenge.contains("="))
        #endif
    }

    func testCSIDUserModel() {
        let user = CSIDUser(id: "usr_123", email: "developer@cokistudios.com", name: "Dev Ortiz")
        XCTAssertEqual(user.initial, "D")
        XCTAssertEqual(user.id, "usr_123")
    }

    func testCSIDHardwareVaultRoundtrip() throws {
        let vault = CSIDHardwareVault.shared
        let originalText = "Coki Studios Secure Payload 2026"
        let seed = "room-test-1234"
        let encrypted = try vault.encryptString(originalText, seedString: seed)
        XCTAssertTrue(encrypted.hasPrefix("🔒 enc:v1:"))
        let decrypted = vault.decryptString(encrypted, seedString: seed)
        XCTAssertEqual(decrypted, originalText)
    }
}

