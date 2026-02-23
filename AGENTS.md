# AGENTS.md

このドキュメントは、`kyounani-ios` の目標設計に対して、現時点実装がどこまで対応しているかを整理したものです。

---

## 開発運用ルール（最重要）

- **実装変更とドキュメント更新は必ずセットで行うこと。**
  - 最低でも `README.md` と本 `AGENTS.md` の該当箇所を同一PRで更新する。
  - フェーズ計画に影響する場合は、`PHASE1-PLAN.md` など関連計画書も更新する。
- PR作成は **commit -> push -> create PR** の順で行う。
  - GitHubアプリで400系エラーが出る場合、head未push / base-head同一 / 既存PR重複を最初に確認する。

## 実行環境前提（追記）

- 開発・検証の実行入口は **iPadのSwift Playgroundsで開ける `.swiftpm`（App project）** を優先する。
- **Mac / Xcode / xcodebuild 前提の手順は採用しない**（このリポジトリでは検証手順にも含めない）。

---

## 1. 目的への対応状況

- 子どもが当日の予定を自力で把握できる導線: **対応強化（部分対応）**
  - Todayホームを「きょう / つぎ / あした」の3セクションで再構成し、見出し・余白・スタンプ表示を子ども向けに最適化。
  - Design Tokensベースの `KyounaniTheme`（Kid / HighContrast）を導入し、Today/Calendar/DayDetail/Token/TimerRing の配色・余白・角丸・タップ領域を統一。
  - Today/Calendarの2タブ導線を常設し、迷子になりにくい移動を実装。
  - 空状態（今日0件・次予定なし）の表示を追加し、予定が無い日でも把握しやすく改善。
- 先の予定の見通しで「がっかり」を減らす: **部分対応（前進）**
  - 月表示/週表示の見通しUIを追加。
  - 日別詳細へのドリルダウンを追加。
- 開始までの待ち時間可視化: **対応済み（最小）**
  - 残り時間リング（複数時間時の多層）と分表示を実装。

## 2. 技術方針への対応

- iPad / SwiftUI: **対応済み（最小）**
  - SwiftUI画面に加えて、`Kyounani.swiftpm`（iPad Swift Playgrounds向けApp project）を追加。
  - 既存Swift Packageをローカル参照し、起動直後にTodayホームへ接続。
- 永続化Repository分離: **対応強化（SwiftData導入）**
  - Repository抽象 + InMemory実装を維持。
  - `SwiftDataEventRepository` を追加し、`Kyounani.swiftpm` 起動時はSwiftData優先（失敗時は保険としてFileBackedフォールバック）。
  - Domain <-> Persistent変換はRepository内のmapperに集約。
- ネットワーク不要: **対応済み**
- 通知なし: **対応済み**

## 3. モード・権限制御

- 起動時は子ども用モード: **対応済み**
- 子ども用フィルタ（息子/娘/両方）: **対応済み**
- ペアレンタルゲート（3本指2秒長押し起点）: **対応済み**
  - 右上の固定領域で「3本指2秒長押し」を検出し、4点シーケンスゲートへ遷移。
  - 4点シーケンスタップ、失敗時クールダウン、緊急4桁コードを維持。
  - 子どもモードでは親導線ボタンを非表示化（隠しジェスチャー領域のみ残す）。
  - 親モード画面で「ロック」実行時に親画面を自動で閉じ、子どもモードへ即時復帰。
- Face ID/Touch ID未使用: **対応済み**

## 4. 情報設計（visibility）

- `published/draft` モデル: **対応済み**
- 子どもモードでpublishedのみ表示: **対応済み**
- 変更影響マーク: **未対応（任意機能）**

## 5. 画面構成

- Todayホーム: **対応強化（見た目最適化 + Theme適用）**
  - 「きょう / つぎ / あした」セクションを大きな見出しと広い余白で整理。
  - 今日・あしたはスタンプ優先の大きな表示で最大2件+`+N`を維持。
  - 次カードはカード全体タップで TTS + TimerRing を一体動作。
  - 今日0件 / 次予定なしの空状態UIを追加。
  - Themeプリセット（Kid / HighContrast）切替を親モードに追加し、子どもモードにも同設定を反映。
  - EventToken / TimerRing のアクセシビリティ文言（label/value）を強化し、VoiceOverで予定情報と残り時間を説明可能に改善。
- Today/Calendar導線: **対応済み（常設2タブ）**
  - TabViewで Today <-> Calendar の往復導線を固定化。
  - 子どもフィルタ（息子/娘/両方）はToday上部に常時表示し、タップしやすい領域を確保。
- 月/週カレンダー（見通し）: **対応済み（最小）**
  - 月表示/週表示の切替、日曜始まり、祝日/土日色分け、日セル2件+`+N` を実装。
- 日別詳細 + TimerOverlay: **部分対応**
  - 日別詳細一覧を追加。
  - 予定タップで既存TTS + TimerRing表示へ接続。
- 親モードCRUD/繰り返し例外UI/スタンプ管理/診断: **対応強化（前進）**
  - イベントの本格CRUD（新規作成 / 一覧タップ編集 / 削除）を実装。
  - `EventEditorView` で title / stamp / childScope / visibility / isAllDay / startDateTime / durationMinutes / recurrenceRule(週次) を編集可能。
  - 日別詳細で繰り返し予定の例外編集3択UI（この日だけ/以降/全体）を維持し、各選択肢に影響範囲の説明を表示。分岐後の編集画面として `EventEditorView` を再利用。
  - `EventEditorView` のスタンプ選択UXを拡張（最近使ったセクション / 検索 / 並び替え[最近順・名前順]）。
  - Diagnostics画面を追加し、有効Repository種別・lastError・バックアップ仕様（formatVersion=2 / PBKDF2-HMAC-SHA256 / AES-GCM）を表示。
  - Diagnosticsのセルフテストで、祝日CSV読込 / RecurrenceEngineの次3回生成 / バックアップround-trip（メモリ上）を実行可能。
  - セルフテスト失敗時は親モード内で赤バナー表示（子どもモードには非表示）。

## 6. 祝日（日本オフライン）

- CSV同梱 + `JapaneseHolidayService`: **対応済み（最小）**
- 祝日表示（赤など）: **対応済み（最小）**
  - カレンダー日付の文字色/背景色で表現。
- 繰り返しの祝日スキップ: **対応済み**

## 7. 予定仕様

- イベント主要属性: **対応強化（UI接続済み）**
  - 親モードの `EventEditorView` から主要属性を作成/編集して保存可能。
  - 空タイトルは既定文言（`よてい`）で保存し、入力不足で失敗しない。
- 繰り返し（週次）: **対応済み**
- 例外（override/delete/splitFromThisDate）: **対応済み（エンジン）**
  - `splitFromThisDate` は例外日が検索範囲外（過去）でも、検索範囲内の将来 occurrence に継続適用。
- 例外編集UI（この日だけ/以降/全体）: **対応済み（最小 / 親モード限定）**
  - 分岐後の編集画面を `EventEditorView` に統一。
  - 分岐後の編集画面上部に「編集スコープ」バナー（スコープ名＋説明）と「範囲を選び直す」を追加。
  - 影響範囲プレビュー（次の3回分の日付＋概算件数）を追加。プレビュー計算は `RecurrenceEngine` を利用し、最大90日/50件で制限。
  - 「この日だけ削除」実行前に確認ダイアログを追加。
  - 例外由来シリーズを全体編集した際の重複生成を防ぐ保存挙動を維持。

## 8. 子ども向けタップ挙動

- 日本語TTS（enhanced優先）: **対応済み**
- リング更新（分単位で進む体感）: **対応済み（1秒更新）**
- 開始済み表示: **対応済み**

## 9. スタンプ

- 初期スタンプセット同梱: **対応済み（Phase 3 最小 / JSON+SF Symbols）**
  - `Kyounani.swiftpm` と `KyounaniApp` の両Resourcesに `builtin_stamps.json` を配置。
  - stamp参照はUUID（現行一意ID）で統一し、旧形式互換は持たない。
- ユーザー追加（Files/Photos→トリミング→保存）: **対応済み（最小）**
  - Files取り込みは security-scoped resource を考慮。
- スタンプ選択UX（親モード）: **対応済み（強化）**
  - `EventEditorView` で「最近使った」を表示（`lastUsedAt` 降順、上位10件）。
  - 検索バーで `stamp.name` の部分一致フィルタ。
  - 並び替え切替（最近順 / 名前順）。
  - 保存確定時にのみ選択スタンプの `lastUsedAt` を更新し、キャンセル時の履歴ずれを防止。
  - `lastUsedAt` / `sortOrder` が `nil` でも安全に動作。
- カレンダートークンの差し替えポイント: **対応済み（Phase 3適用）**
  - `EventTokenRenderer` に描画責務を集約。

## 10. 保存/バックアップ

- ローカル永続化（SwiftData）: **対応済み（最小）**
  - イベント/例外/スタンプをSwiftDataに保存し、再起動後も保持。
  - 旧形式移行（`stamps.json` 初回インポート等）は実装しない。
- iCloud同期なし: **対応済み（未実装）**
- 暗号化バックアップ（書き出し/復元）: **対応済み（最小）**
  - 親モードに「バックアップを書き出す」「バックアップから復元」を追加。
  - 出力形式は `kyounani-backup.kybk`（1ファイル）。
  - 中身は formatVersion=2（PBKDF2-HMAC-SHA256 + AES-GCM）で暗号化し、平文JSONには stamps/events/exceptions と customImage(Base64) を含める。
  - 復元は上書き方式（既存データを置換）で、復元前に件数サマリを確認可能。
  - 旧形式バックアップの復元は非対応（formatVersion=2のみ）。
  - 親モードに「データを全削除（リセット）」を追加し、SwiftData/保険Repositoryデータ + customImageファイルを初期化可能。

## 11. アーキテクチャ

- MVVM: **対応済み（最小構成）**
- カレンダー日次集約（最大2件+N）の共通化: **対応済み（ViewModel/Presenter）**
- Repository分離: **対応済み（抽象＋SwiftData＋FileBacked[保険用途]＋InMemory）**
- `JapaneseHolidayService` / `RecurrenceEngine`: **対応済み**
- 日本タイムゾーン前提: **対応済み**

## 12. テスト

- `JapaneseHolidayService` 単体テスト: **対応済み**
- `RecurrenceEngine` 単体テスト（週次/祝日スキップ/override-delete/以降変更）: **対応済み**
- CI（GitHub Actions `swift-test`）: **対応済み（macos-latest / Xcode明示選択 / KyounaniApp / swift test -v）**
  - 不安定化要因だったツールチェーン差分を抑えるため、`setup-xcode` で Xcode を明示選択。
  - CIログの先頭エラー（SwiftDataRepositoryの条件付き束縛）を修正し、macOSでもコンパイル可能な形へ統一。
  - macOS unavailable なSwiftUI APIは `#if os(iOS)` でガードし、`swift test` の安定性を優先（UI最終確認はiPad Playgrounds）。

## 13. 受け入れ条件への現状判定

- 子どもモードで編集不可: **対応済み（運用上）**
- 起動直後Todayホーム: **対応済み**
- 月/週でスタンプ表示: **対応済み（スタンプ画像中心）**
- タップで日本語読み上げ: **対応済み**
- タップでリング進行 + 複数リング: **対応済み**
- 週次繰り返し + 祝日スキップ + 単発例外: **対応済み（ドメイン）**
- 祝日表示: **対応済み（最小）**
- スタンプユーザー追加: **対応済み（最小）**

## 14. 次の優先実装（推奨）

1. 視覚テーマの追加拡張（配色プリセット追加、画面別コントラスト評価、アクセシビリティサイズ段階の微調整）。
2. 親モードCRUDの入力項目拡張（メモ、場所、色など任意属性）。
3. 暗号化バックアップの改善（KDF強化、ZIPコンテナ化、差分/選択復元）。
4. CI（`swift test` 拡充、Playgrounds起動手順チェック、診断セルフテスト運用の文書化）。
5. 子ども向け空状態イラスト/文言の差し替え容易化（ローカライズ含む）。
