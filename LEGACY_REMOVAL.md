# LEGACY_REMOVAL

旧形式互換コードの棚卸しと、現行仕様（単一形式）への統一方針。

| 機能/互換名 | 該当ファイル/シンボル | 依存している箇所 | 削除方針 | 置換後の現行仕様 |
|---|---|---|---|---|
| 旧バックアップ鍵導出 `SHA256(passphrase+salt)` | `BackupCryptoService.deriveKey` / `EncryptedBackupEnvelope.kdf` | 親モードのバックアップ書き出し・復元 | **削除** | `formatVersion=2` + `PBKDF2-HMAC-SHA256` + `AES-GCM` のみ |
| 旧バックアップのバージョン許容（`<= current`） | `BackupCryptoService.decryptPayload` | 親モードのバックアップ復元 | **削除** | `formatVersion==2` / `payload.version==2` を厳密要求 |
| `builtin:<name>` 互換表示 | `StampStore.image(for:)` の legacy 分岐 | `EventTokenRenderer`, `ParentModeView` のスタンプ表示 | **削除** | スタンプは `Stamp.id`（UUID）参照 + `imageLocation="symbol:<sf-symbol>"` or custom PNG |
| `StampKind` の旧 raw value (`builtin` / `user`) デコード | `StampKind.init(from:)` | スタンプの JSON decode | **削除** | `systemSymbol` / `customImage` のみ |
| `stamps.json` からの初回移行（SwiftData） | `SwiftDataEventRepository.migrateLegacyUserStampsIfNeeded` | SwiftData 初期化時 | **削除** | SwiftData 既存データをそのまま使用。移行処理なし |
| `stamps.json` 旧構造の decode/migrate（FileBacked） | `FileBackedEventRepository.loadStampsFromDisk` + `LegacyPersistedStamp` | SwiftData失敗時の保険Repository | **削除（互換）/残す（保険）** | FileBacked は現行 `Stamp/Event/EventException` JSON のみを扱う保険実装 |

## 補足
- 旧データ互換は非対応（breaking change）。必要な場合は親モードの「データを全削除（リセット）」で初期化して再作成する。
- `FileBackedEventRepository` は **SwiftData障害時の保険** としてのみ維持し、レガシー変換責務は持たない。
