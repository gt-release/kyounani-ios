# ARCHITECTURE

## 全体構成
- 実行入口: `Kyounani.swiftpm`（iPad Swift Playgrounds）
- 中核実装: `KyounaniApp`（Swift Package）

## Kyounani.swiftpm と KyounaniApp の関係
- `Kyounani.swiftpm` は起動/配布の器。
- 画面・モデル・サービス・Repository は主に `KyounaniApp` 側に実装。
- `Kyounani.swiftpm` は `KyounaniApp` をローカル参照して利用。

## 主要コンポーネント
- Models: Event / EventException / Stamp など
- Services:
  - `RecurrenceEngine`
  - `JapaneseHolidayService`
  - `BackupCryptoService`
  - `StampStore`
- Repository:
  - `SwiftDataEventRepository`
  - `FileBackedEventRepository`
  - `InMemoryEventRepository`
- Views/ViewModels:
  - Today / Calendar / Month / Week / DayDetail / ParentMode / EventEditor

## データフロー（概略）
1. View が ViewModel を介して Repository へアクセス。
2. Repository から Event/Exception/Stamp を取得。
3. `RecurrenceEngine` が表示範囲の occurrence を計算。
4. View がトークン表示・詳細表示を構成。
5. 編集時は Repository 保存 → 再取得 → 画面再描画。

## Repositoryフォールバック
- 既定は SwiftData を優先。
- SwiftData 初期化失敗時は FileBacked にフォールバック。
- （運用上）必要に応じて InMemory 実装を差し替え利用可能。

## Theme構成
- `KyounaniTheme` に Design Tokens を集約。
- プリセット:
  - Kid
  - High Contrast
- 親モードの設定が子どもモード表示にも反映される。

## タイムゾーン前提
- `RecurrenceEngine` は日本（`Asia/Tokyo`）前提のカレンダーを使用。
