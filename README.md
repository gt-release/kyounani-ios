# kyounani-ios

子ども（4才/2才）向けに、文字が読めなくても予定を把握できるローカルカレンダーです。iPad Swift Playgrounds での実行を前提にしています。

## 概要（何ができるか）
- 子ども向け Today 画面（**きょう / つぎ / あした**）
- Today / Calendar の常設2タブ導線
- 月/週カレンダー、日別詳細、予定タップ時の日本語TTS + TimerRing
- 親モードでイベントCRUD、繰り返し例外編集（この日だけ / 以降 / 全体）
- 親モード Diagnostics（Repository種別 / lastError / セルフテスト）
- スタンプ管理（初期スタンプ + Files/Photos 追加）
- ローカル保存（SwiftData優先、障害時のみFileBacked保険）と暗号化バックアップ（`.kybk`）

## 使い方
### 子どもモード
- 起動直後は「Today」タブ。
- 下部タブで「Today / Calendar」を切替。
- 上部フィルタで「息子 / 娘 / 両方」を切替。
- 「つぎ」カードをタップすると読み上げ + 残り時間リング表示。

### 親モード
- 右上のガイド表示付き領域で **2本指2秒長押し** → 4点シーケンスで解除。
- ガイド（「親モード / 右上を2本指で2秒」）が表示されるので、その範囲内で長押し。
- フォールバック導線: Todayの見出し「きょう」を **7回連続タップ** でも4点シーケンス画面を起動可能（親向けの隠し導線）。
- 安定化メモ: 右上ホットエリアと7回タップの両経路は同じ4点シーケンス画面を直接開く実装に統一。
- 親モードでイベントの追加・編集・削除、テーマ切替（Kid / High Contrast）が可能。
- 「ロック」で子どもモードに即復帰。

### スタンプ追加
- 親モードで Files / Photos から追加。
- 画像は中央正方形にクロップして PNG 保存。
- Files 取り込み時は security-scoped resource を考慮。

### クラッシュ調査手順（iPad単体）
- 次回起動時に「前回、異常終了の可能性があります」バナーが出たら「診断」から親ゲートへ進む。
- 親モード > Diagnostics で以下を確認:
  - Crash Marker（前回異常終了フラグ）
  - Breadcrumb直近50件（親モード遷移/エディタ/スタンプ/バックアップ/repoType/lastError）
  - `kyounani.log`（Application Support 追記ログ）
- Diagnostics画面の「Breadcrumbをコピー」「ファイルログをコピー」で端末単体で共有可能。
- 切り分け時は親モードの「セーフモード（次回起動で有効）」をONにして再起動し、再現有無を比較する。
  - セーフモードでは Repository を InMemory に固定
  - customImage読み込みを無効化（system symbol相当表示）
  - バックアップ書き出し/復元は無効化

### バックアップ
- 親モードから書き出し / 復元。
- 形式: `kyounani-backup.kybk`（`formatVersion=2` 固定、`PBKDF2-HMAC-SHA256` + `AES-GCM`）。
- **現行形式のみ対応**（旧形式バックアップの復元は非対応）。
- 復元は上書き方式。復号/デコード失敗時は既存データ無変更。

### Diagnostics（親向け診断）
- CIの検証は `macos-latest` の `swift test -v` を基準に実施。
- 画面の最終動作確認は iPad Swift Playgrounds (`Kyounani.swiftpm`) で実施。
- 親モードの Diagnostics で、現在有効なRepository（SwiftData / FileBacked / InMemory）と `lastError` を確認可能。
- セルフテストで、祝日CSV読込 / RecurrenceEngine生成 / バックアップround-trip（メモリ上）を実行。
- 失敗時は赤バナー表示で気づける（子どもモードには表示しない）。
- CI修正メモ: Diagnostics のバックアップセルフテストは `BackupCryptoService.decryptPayload(from:passphrase:)` を使用。

### データリセット（互換削除後の運用）
- 親モードの「データを全削除（リセット）」で、予定/例外/スタンプを全削除。
- 追加したカスタム画像（PNG）も同時に削除。
- 旧互換コードは削除済みのため、必要ならリセットして作り直してください。

## iPad Swift Playgrounds での起動手順（最短）
1. iPad でこのリポジトリを取得（Files/Working Copy 等）。
2. Swift Playgrounds で `Kyounani.swiftpm` を開く。
3. Run を押す。

> 詳細: [docs/PLAYGROUNDS_QUICKSTART.md](docs/PLAYGROUNDS_QUICKSTART.md)

## CI / 検証方針
- CIは **macOS GitHub Actions** で `Kyounani.swiftpm/Packages/KyounaniEmbeddedApp` の `swift package dump-package`（CI安全なManifest評価）と `KyounaniApp` の `swift test` を実行（xcodebuildは使わない）。
- macOSで unavailable な UI API は条件付きコンパイルでガードし、SwiftPMテストを安定化（例: Toolbar placementのOS分岐）。
- コンパイル負荷の高いViewはsubview分割で type-check timeout を回避し、CI安定性を優先。
- UIの見た目・操作確認は iPad Swift Playgrounds で行う。

- macOSビルドで ToolbarContent が不安定な場合に備え、toolbar定義は result builder 解釈できる形（ToolbarContentBuilder）を維持。


## 起動クラッシュ修正（2026-02）
- iPadで起動時に白画面化する端末差異に対し、`Kyounani.swiftpm/Package.swift` の `supportedInterfaceOrientations` へ `.portraitUpsideDown` を追加し、iPadマルチタスク時の「全向きサポート必須」警告を解消。
- `TodayHomeView` / `ParentModeView` の `onChange(of:perform:)` 旧シグネチャを iOS 17 推奨の zero-parameter 版へ移行し、Playgrounds の起動ログを整理。
- iPad Swift Playgrounds で、`Kyounani.swiftpm` から **親ディレクトリ参照のローカル package (`../KyounaniApp`)** を開けず、起動前に「Operation not permitted」で失敗するケースを修正。
- `Kyounani.swiftpm/Packages/KyounaniEmbeddedApp` に実行用ソースを同梱し、Playgrounds 側 `Package.swift` では **local package dependency を使わず** 同梱ソースを直接 target 化して参照する構成に変更。
- 併せて `ResourceBundleLocator` を追加し、`Bundle.module` 依存ではなく `.main` / 実行時に見える bundle 群（allBundles/allFrameworks）を横断して `syukujitsu*.csv` / `builtin_stamps.json` を探索する方式に変更。
- これにより Playgrounds のサンドボックス制約と bundle 構成差の両方で起動失敗リスクを低減。
- `Kyounani.swiftpm/Package.swift` は **iPad Swift Playgrounds の正常起動を優先**し、`canImport(AppleProductTypes)` 可能な環境では `.iOSApplication` を宣言してアプリターゲットを明示する。
- `AppleProductTypes` 非対応環境では `executable product` にフォールバックし、Manifest評価エラー（`Type 'Product' has no member 'iOSApplication'` など）を回避する。
- CIは `Kyounani.swiftpm` 直下Manifestの `dump-package` を必須チェックにせず、同梱 `KyounaniEmbeddedApp` 側で継続監視する。

## 既知の制約
- このリポジトリの実行入口は **iPad Swift Playgrounds (`Kyounani.swiftpm`) 優先**。
- **Mac / Xcode / xcodebuild 前提手順は採用しない**（検証手順にも含めない）。
- 初期スタンプは `builtin_stamps.json`（SF Symbols参照）で同梱。

## リポジトリ構成
- `Kyounani.swiftpm`: iPad Swift Playgrounds向け App project（実行入口）
- `KyounaniApp`: ドメイン/サービス/UIを提供する再利用Swift Package
- `KyounaniApp/Tests/KyounaniAppTests`: 単体テスト
- CIはGitHub Actionsで `macos-latest` 上から `Kyounani.swiftpm/Packages/KyounaniEmbeddedApp` の `swift package dump-package` と `KyounaniApp` の `swift test -v` を実行。
- ワークフロー内で `setup-xcode` により Xcode を明示選択し、`swift` ツールチェーンのぶれを抑制。

## ドキュメント一覧
- [CODE_REVIEW.md](CODE_REVIEW.md)
- [docs/PLAYGROUNDS_QUICKSTART.md](docs/PLAYGROUNDS_QUICKSTART.md)
- [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/SECURITY.md](docs/SECURITY.md)
- [AGENTS.md](AGENTS.md)
- [LEGACY_REMOVAL.md](LEGACY_REMOVAL.md)
- [PHASE1-PLAN.md](PHASE1-PLAN.md)
