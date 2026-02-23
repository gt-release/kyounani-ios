# kyounani-ios
子ども向け（4才/2才）に、文字が読めなくても予定がわかるローカルカレンダーのSwiftUI実装です。

## 実装内容（現時点）
- 子どもモード起動 + フィルタ（息子/娘/両方）
- ペアレンタルゲート（右上の固定領域で3本指2秒長押し→4点シーケンス、失敗クールダウン、非常用4桁コード）
- 親モード画面で「ロック」実行時は子どもモードへ戻し、親モードシートを自動で閉じる
- 親モードの本格CRUD（＋追加 / 一覧タップ編集 / 削除）を実装し、EventEditorViewでイベントの主要項目を編集可能
- EventEditorViewのスタンプ選択UXを拡張（最近使った / 検索 / 並び替え[最近順・名前順]）
- Todayホーム（今日の予定、次の予定、先の予定チラ見せ）
- Today→カレンダー遷移
- カレンダー（**月/週切替、日曜始まり、日別詳細ドリルダウン**）
- 日セル「予定最大2件 +N」表示（publishedのみ・childScopeフィルタ反映）
- Phase 3: スタンプ中心UI（Today / 月週カレンダー / 日別詳細）
- 初期スタンプ同梱（Kyounani.swiftpm Resources/Stamps/builtin_stamps.json）
- 親モードでスタンプ追加（Files / Photos, センター正方形クロップ, PNG保存）
- Files取り込み時にsecurity-scoped resourceへ対応（iCloud Drive等でも読み込み可能化）
- イベント/スタンプ永続化（SwiftData Repository, 起動後も保持。スタンプの最終使用時刻 `lastUsedAt` も保持）
- バイナリ非対応PRツール向けに、初期スタンプはJSON+SF Symbolsで同梱
- `KyounaniApp` 側にも同じ`builtin_stamps.json`を配置し、Bundle解決を安定化
- 旧`builtin:<name>`形式も互換表示し、段階移行時の欠けを防止
- カレンダー日次集約ロジックをViewModelで共通化（Today/Month/Weekで再利用）
- 祝日/土日色分け（祝日/日曜=赤系、土曜=青系）
- タップ時の日本語読み上げ（enhanced優先）
- 残り時間リング（1時間=1周、1時間超は多層リング）
- JapaneseHolidayService（同梱CSV読み込み）
- RecurrenceEngine（週次、祝日スキップ、override/delete/splitFromThisDate）
- 親モード限定: 日別詳細の繰り返し予定に「この日だけ / 以降すべて / 全体」例外編集UIを実装（各選択肢に影響範囲の説明を表示）
- 例外由来シリーズを「全体」編集した際に重複予定が増えないよう保存先を補正
- 例外編集の EventEditorView に影響範囲プレビューを追加（次の3回分の日付 + 概算件数、最大90日/50件で制限）
- 「この日だけ削除」実行前に確認ダイアログを追加
- 日別詳細の例外編集でも同じ EventEditorView を再利用し、分岐（この日だけ / 以降すべて / 全体）を維持。編集画面上部に「編集スコープ」バナーと「範囲を選び直す」を追加
- Repository層で永続化を抽象化（SwiftData優先 + FileBacked fallback + InMemory実装）
- 単体テスト（祝日/繰り返し）

## 構成
- `Kyounani.swiftpm` : iPad Swift Playgrounds で実行する App project（実行入口）
- `KyounaniApp` : ドメイン・サービス・View群の再利用Swift Package
- `KyounaniApp/Sources/KyounaniApp/Models` : ドメインモデル
- `KyounaniApp/Sources/KyounaniApp/Services` : 祝日・繰り返し・音声
- `KyounaniApp/Sources/KyounaniApp/Repository` : Repository抽象
- `KyounaniApp/Sources/KyounaniApp/ViewModels` : MVVM ViewModel
- `KyounaniApp/Sources/KyounaniApp/Views` : SwiftUI画面（Today / CalendarRoot / Month / Week / DayDetail / ParentMode / EventEditor）
- `KyounaniApp/Tests/KyounaniAppTests` : 単体テスト

## 実行方法（Mac / Xcode不要）
1. iPad の Files か Working Copy でこのリポジトリを取得する。
2. Swift Playgrounds で `Kyounani.swiftpm` を開く。
3. Run を押す。

起動直後に子ども向け Today ホームが表示され、カレンダー画面へ遷移できます。

### データ保存場所（SwiftData）
- Swift Playgrounds版（`Kyounani.swiftpm`）では、`SwiftDataEventRepository` を使用してイベント/スタンプを永続化します。
- ユーザー追加スタンプ画像（PNG）は `Application Support/Kyounani/` 配下に保存されます。
- 旧 `Application Support/Kyounani/stamps.json` が存在し、SwiftData側が空の場合のみ初回インポートします（旧ファイルは削除しません）。
- SwiftDataが利用できない場合は `FileBackedEventRepository` にフォールバックし、`Application Support/Kyounani/*.json` にイベント/例外/スタンプを保持します。


### 親モード: スタンプを素早く選ぶ
- `＋追加` か既存予定の編集で `EventEditorView` を開く。
- 「スタンプ」セクションで名前検索が可能（部分一致）。
- 並び替えを「最近順 / 名前順」で切り替え可能。
- 「最近使った」セクションには、利用履歴（`lastUsedAt`）があるスタンプの上位10件を表示。
- 保存確定時にのみ選択中スタンプの `lastUsedAt` が更新されるため、キャンセル時に履歴がずれない。


### 親モード: 暗号化バックアップ（書き出し / 復元）
1. 親モードで「バックアップ」セクションを開く。
2. **書き出し**: 「バックアップを書き出す」→ パスフレーズ入力 → Files 保存先を選択。
   - 出力ファイル名は `kyounani-backup.kybk`。
   - AES-GCM で暗号化されるため、パスフレーズがないと復元できません。
3. **復元**: 「バックアップから復元」→ `.kybk` を選択 → パスフレーズ入力 → 件数サマリ確認 → 復元実行。

注意:
- 復元は**上書き方式**です。現在のイベント/例外/スタンプは置き換えられます。
- パスフレーズを忘れると復元できません。安全な場所に保管してください。
- 復号やデコードに失敗した場合、既存データは変更されません。

### iPadでのペアレンタルゲート再現手順（Swift Playgrounds）
1. iPadのSwift Playgroundsで `Kyounani.swiftpm` を起動し、子どもモードのTodayホームを表示する。
2. 子どもモード画面の右上にある固定領域（見た目は目立たない）を、**3本指で2秒間長押し**する。
3. `ParentalGateView`（4点シーケンス入力画面）が開くことを確認する。
4. 4点シーケンス入力で解除できること、3回失敗でクールダウンすること、非常用4桁コード（有効時）が動作することを確認する。

## Swift Packageのローカル検証（任意）
```bash
cd KyounaniApp
swift test
```


## PR作成エラー（400）時の確認
GitHubアプリ/クライアントで「リクエストに問題があります (400)」が出る場合は、次を確認してください。

1. **先にブランチをPushする**（headブランチがリモートに無いとPR作成APIが失敗）。
2. **base/headが同じブランチになっていないか**を確認する。
3. **同じheadブランチのPRが既に開いていないか**を確認する。
4. 失敗が続く場合は、WebのGitHub画面で作成し、具体的なAPIエラーメッセージを確認する。

推奨順序: `commit -> push -> create PR`。

## 運用ルール（ドキュメント更新）
- 実装変更時は、**コード変更と同じPRでドキュメントも更新**してください。
- 最低限 `README.md` と `AGENTS.md` の該当箇所更新を必須とします。

## 今後の拡張
- 例外編集UIの拡張（削除時確認＋分岐説明＋プレビュー）: 実装済み。次は説明文言や件数精度の改善。
- スタンプ管理UXの拡張（並び替え・検索・使用頻度表示）: 実装済み（最近使った/検索/最近順・名前順）。
- 暗号化バックアップ（CryptoKit AES-GCM, .kybk 1ファイル書き出し）
- バックアップ復元（FileImporter + パスフレーズ復号 + 件数サマリ確認 + 上書き復元）
