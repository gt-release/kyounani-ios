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
- 起動直後は Today タブ。
- 上部フィルタで「息子 / 娘 / 両方」を切替。
- 「つぎ」カードをタップすると読み上げ + 残り時間リング表示。

### 親モード
- 右上の隠し領域で **3本指2秒長押し** → 4点シーケンスで解除。
- 親モードでイベントの追加・編集・削除、テーマ切替（Kid / High Contrast）が可能。
- 「ロック」で子どもモードに即復帰。

### スタンプ追加
- 親モードで Files / Photos から追加。
- 画像は中央正方形にクロップして PNG 保存。
- Files 取り込み時は security-scoped resource を考慮。

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
- CIは **macOS GitHub Actions** で `KyounaniApp` の `swift test` を実行（xcodebuildは使わない）。
- macOSで unavailable な UI API は条件付きコンパイルでガードし、SwiftPMテストを安定化（例: Toolbar placementのOS分岐）。
- コンパイル負荷の高いViewはsubview分割で type-check timeout を回避し、CI安定性を優先。
- UIの見た目・操作確認は iPad Swift Playgrounds で行う。

## 既知の制約
- このリポジトリの実行入口は **iPad Swift Playgrounds (`Kyounani.swiftpm`) 優先**。
- **Mac / Xcode / xcodebuild 前提手順は採用しない**（検証手順にも含めない）。
- 初期スタンプは `builtin_stamps.json`（SF Symbols参照）で同梱。

## リポジトリ構成
- `Kyounani.swiftpm`: iPad Swift Playgrounds向け App project（実行入口）
- `KyounaniApp`: ドメイン/サービス/UIを提供する再利用Swift Package
- `KyounaniApp/Tests/KyounaniAppTests`: 単体テスト
- CIはGitHub Actionsで `macos-latest` 上から `KyounaniApp` の `swift test -v` を実行（SwiftPMテストのみ）。
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
