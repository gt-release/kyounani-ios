#if canImport(CryptoKit)
import Foundation
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

        XCTAssertEqual(decrypted.version, 2)
        XCTAssertEqual(decrypted.stamps.count, 1)
        XCTAssertEqual(decrypted.stamps.first?.stamp.name, "写真")
        XCTAssertEqual(decrypted.stamps.first?.customImageBase64, Data("image".utf8).base64EncodedString())
    }

    func testExportUsesFormatVersion2WithPBKDF2() throws {
        let payload = BackupPayload(stamps: [], events: [], exceptions: [])
        let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "secret")

        let json = try JSONSerialization.jsonObject(with: encrypted) as? [String: Any]
        XCTAssertEqual(json?["format"] as? String, "kyounani-backup")
        XCTAssertEqual(json?["formatVersion"] as? Int, 2)
        XCTAssertEqual(json?["kdf"] as? String, "PBKDF2-HMAC-SHA256")
        XCTAssertEqual(json?["iterations"] as? Int, 120_000)
    }

    func testDecryptWithWrongPassphraseFails() throws {
        let payload = BackupPayload(stamps: [], events: [], exceptions: [])
        let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "secret")

        XCTAssertThrowsError(try BackupCryptoService.decryptPayload(from: encrypted, passphrase: "wrong"))
    }

    func testDecryptRejectsUnsupportedFormatVersion() throws {
        let payload = BackupPayload(stamps: [], events: [], exceptions: [])
        let encrypted = try BackupCryptoService.exportEncryptedData(payload: payload, passphrase: "secret")

        let object = try JSONSerialization.jsonObject(with: encrypted) as? [String: Any]
        var modified = object ?? [:]
        modified["formatVersion"] = 1
        let modifiedData = try JSONSerialization.data(withJSONObject: modified, options: [.sortedKeys])

        XCTAssertThrowsError(try BackupCryptoService.decryptPayload(from: modifiedData, passphrase: "secret")) { error in
            XCTAssertEqual(error as? BackupCryptoError, .unsupportedVersion)
        }
    }
}

#endif
