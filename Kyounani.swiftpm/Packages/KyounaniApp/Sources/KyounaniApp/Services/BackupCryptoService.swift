#if canImport(CryptoKit)
import CryptoKit
import Foundation

public enum BackupCryptoError: Error, LocalizedError, Equatable {
    case invalidPassphrase
    case invalidBackupFile
    case unsupportedVersion
    case decryptFailed

    public var errorDescription: String? {
        switch self {
        case .invalidPassphrase:
            return "パスフレーズを入力してください"
        case .invalidBackupFile:
            return "バックアップファイルの形式が正しくありません"
        case .unsupportedVersion:
            return "このバックアップ形式は現在のアプリで復元できません"
        case .decryptFailed:
            return "復号に失敗しました。パスフレーズを確認してください"
        }
    }
}

public struct BackupPayload: Codable {
    public static let currentVersion = 2

    public var version: Int
    public var exportedAt: Date
    public var stamps: [StampBackupEntry]
    public var events: [Event]
    public var exceptions: [EventException]

    public init(version: Int = BackupPayload.currentVersion, exportedAt: Date = .now, stamps: [StampBackupEntry], events: [Event], exceptions: [EventException]) {
        self.version = version
        self.exportedAt = exportedAt
        self.stamps = stamps
        self.events = events
        self.exceptions = exceptions
    }
}

public struct StampBackupEntry: Codable {
    public var stamp: Stamp
    public var customImageBase64: String?

    public init(stamp: Stamp, customImageBase64: String?) {
        self.stamp = stamp
        self.customImageBase64 = customImageBase64
    }
}

private struct EncryptedBackupEnvelope: Codable {
    var format: String
    var formatVersion: Int
    var kdf: String
    var iterations: Int
    var saltBase64: String
    var nonceBase64: String
    var ciphertextBase64: String
    var tagBase64: String
}

public struct BackupSummary {
    public var stampCount: Int
    public var eventCount: Int
    public var exceptionCount: Int
}

public enum BackupCryptoService {
    private static let formatName = "kyounani-backup"
    private static let formatVersion = 2
    private static let kdfName = "PBKDF2-HMAC-SHA256"
    private static let pbkdf2Iterations = 120_000

    public static func exportEncryptedData(payload: BackupPayload, passphrase: String) throws -> Data {
        let normalizedPassphrase = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPassphrase.isEmpty else { throw BackupCryptoError.invalidPassphrase }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let plain = try encoder.encode(payload)

        let salt = randomBytes(count: 16)
        let nonce = try AES.GCM.Nonce(data: randomBytes(count: 12))
        let keyData = pbkdf2SHA256(
            password: Data(normalizedPassphrase.utf8),
            salt: salt,
            iterations: pbkdf2Iterations,
            keyByteCount: 32
        )
        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.seal(plain, using: key, nonce: nonce)

        let envelope = EncryptedBackupEnvelope(
            format: formatName,
            formatVersion: formatVersion,
            kdf: kdfName,
            iterations: pbkdf2Iterations,
            saltBase64: salt.base64EncodedString(),
            nonceBase64: Data(nonce).base64EncodedString(),
            ciphertextBase64: sealedBox.ciphertext.base64EncodedString(),
            tagBase64: sealedBox.tag.base64EncodedString()
        )

        let envelopeEncoder = JSONEncoder()
        envelopeEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try envelopeEncoder.encode(envelope)
    }

    public static func decryptPayload(from encryptedData: Data, passphrase: String) throws -> BackupPayload {
        let normalizedPassphrase = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPassphrase.isEmpty else { throw BackupCryptoError.invalidPassphrase }

        let envelope = try decodeEnvelope(data: encryptedData)

        guard let salt = Data(base64Encoded: envelope.saltBase64),
              let nonceData = Data(base64Encoded: envelope.nonceBase64),
              let ciphertext = Data(base64Encoded: envelope.ciphertextBase64),
              let tag = Data(base64Encoded: envelope.tagBase64),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw BackupCryptoError.invalidBackupFile
        }

        let keyData = pbkdf2SHA256(
            password: Data(normalizedPassphrase.utf8),
            salt: salt,
            iterations: envelope.iterations,
            keyByteCount: 32
        )
        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)

        let decrypted: Data
        do {
            decrypted = try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw BackupCryptoError.decryptFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: decrypted)
        guard payload.version == BackupPayload.currentVersion else {
            throw BackupCryptoError.unsupportedVersion
        }
        return payload
    }

    public static func summarize(payload: BackupPayload) -> BackupSummary {
        BackupSummary(stampCount: payload.stamps.count, eventCount: payload.events.count, exceptionCount: payload.exceptions.count)
    }

    private static func decodeEnvelope(data: Data) throws -> EncryptedBackupEnvelope {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(EncryptedBackupEnvelope.self, from: data)
        guard envelope.format == formatName,
              envelope.formatVersion == formatVersion,
              envelope.kdf == kdfName,
              envelope.iterations > 0 else {
            throw BackupCryptoError.unsupportedVersion
        }
        return envelope
    }

    private static func pbkdf2SHA256(password: Data, salt: Data, iterations: Int, keyByteCount: Int) -> Data {
        let hmacByteCount = 32
        let blocks = Int(ceil(Double(keyByteCount) / Double(hmacByteCount)))

        var derivedKey = Data()
        derivedKey.reserveCapacity(blocks * hmacByteCount)

        for blockIndex in 1...blocks {
            var int = UInt32(blockIndex).bigEndian
            let indexData = Data(bytes: &int, count: MemoryLayout<UInt32>.size)
            let initial = HMAC<SHA256>.authenticationCode(for: salt + indexData, using: SymmetricKey(data: password))

            var u = Data(initial)
            var t = Data(initial)

            if iterations > 1 {
                for _ in 2...iterations {
                    let next = HMAC<SHA256>.authenticationCode(for: u, using: SymmetricKey(data: password))
                    u = Data(next)
                    for i in 0..<t.count {
                        t[i] ^= u[i]
                    }
                }
            }

            derivedKey.append(t)
        }

        return derivedKey.prefix(keyByteCount)
    }

    private static func randomBytes(count: Int) -> Data {
        Data((0..<count).map { _ in UInt8.random(in: .min ... .max) })
    }
}

#endif
