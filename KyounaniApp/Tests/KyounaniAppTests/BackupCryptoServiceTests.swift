#if canImport(CryptoKit)
import XCTest
@testable import KyounaniApp

final class BackupCryptoServiceTests: XCTestCase {
    func testEncryptAndDecryptRoundTrip() throws {
        let stamp = Stamp(
            id: UUID(),
            name: "写真",
            kind: .customImage,
            imageLocation: "abc.png",
            isBuiltin: false
        )
        let payload = BackupPayload(
            stamps: [StampBackupEntry(stamp: stamp, customImageBase64: Data("image".utf8).base64EncodedString())],
            events: [],
            exceptions: []
        )

        let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "123456")
        let decrypted = try BackupCryptoService.decryptPayload(from: encrypted, passphrase: "123456")

        XCTAssertEqual(decrypted.stamps.count, 1)
        XCTAssertEqual(decrypted.stamps.first?.stamp.name, "写真")
        XCTAssertEqual(decrypted.stamps.first?.customImageBase64, Data("image".utf8).base64EncodedString())
    }

    func testDecryptWithWrongPassphraseFails() throws {
        let payload = BackupPayload(stamps: [], events: [], exceptions: [])
        let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "secret")

        XCTAssertThrowsError(try BackupCryptoService.decryptPayload(from: encrypted, passphrase: "wrong"))
    }
}

#endif
