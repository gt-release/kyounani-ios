# kyounani-ios
子ども向け（4才/2才）に、文字が読めなくても予定がわかるローカルカレンダーのSwiftUI実装です。

## 実装内容（現時点）
- 子どもモード起動 + フィルタ（息子/娘/両方）
- ペアレンタルゲート（4点シーケンスタップ、失敗クールダウン、非常用4桁コード）
- Todayホーム（今日の予定、次の予定、先の予定チラ見せ）
- Today→カレンダー遷移
- カレンダー（**月/週切替、日曜始まり、日別詳細ドリルダウン**）
- 日セル「予定最大2件 +N」表示（publishedのみ・childScopeフィルタ反映）
- Phase 3: スタンプ中心UI（Today / 月週カレンダー / 日別詳細）
- 初期スタンプ同梱（Kyounani.swiftpm Resources/Stamps/builtin_stamps.json）
- 親モードでスタンプ追加（Files / Photos, センター正方形クロップ, PNG保存）
- Files取り込み時にsecurity-scoped resourceへ対応（iCloud Drive等でも読み込み可能化）
- イベント/スタンプ永続化（SwiftData Repository, 起動後も保持）
- バイナリ非対応PRツール向けに、初期スタンプはJSON+SF Symbolsで同梱
- `KyounaniApp` 側にも同じ`builtin_stamps.json`を配置し、Bundle解決を安定化
- 旧`builtin:<name>`形式も互換表示し、段階移行時の欠けを防止
- カレンダー日次集約ロジックをViewModelで共通化（Today/Month/Weekで再利用）
- 祝日/土日色分け（祝日/日曜=赤系、土曜=青系）
- タップ時の日本語読み上げ（enhanced優先）
- 残り時間リング（1時間=1周、1時間超は多層リング）
- JapaneseHolidayService（同梱CSV読み込み）
- RecurrenceEngine（週次、祝日スキップ、override/delete/splitFromThisDate）
- 親モード限定: 日別詳細の繰り返し予定に「この日だけ / 以降すべて / 全体」例外編集UIを実装
- 例外由来シリーズを「全体」編集した際に重複予定が増えないよう保存先を補正
- Repository層で永続化を抽象化（SwiftData優先 + FileBacked fallback + InMemory実装）
- 単体テスト（祝日/繰り返し）

## 構成
- `Kyounani.swiftpm` : iPad Swift Playgrounds で実行する App project（実行入口）
- `KyounaniApp` : ドメイン・サービス・View群の再利用Swift Package
- `KyounaniApp/Sources/KyounaniApp/Models` : ドメインモデル
- `KyounaniApp/Sources/KyounaniApp/Services` : 祝日・繰り返し・音声
- `KyounaniApp/Sources/KyounaniApp/Repository` : Repository抽象
- `KyounaniApp/Sources/KyounaniApp/ViewModels` : MVVM ViewModel
- `KyounaniApp/Sources/KyounaniApp/Views` : SwiftUI画面（Today / CalendarRoot / Month / Week / DayDetail）
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
- 例外編集UIの拡張（delete導線や入力項目拡充）
- SwiftDataスキーマのマイグレーション運用強化
- 暗号化エクスポート（CryptoKit AES-GCM）
