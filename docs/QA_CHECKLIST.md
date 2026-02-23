# QA CHECKLIST (互換削除後 / 5分スモーク)

## 0. 前提
- iPad Swift Playgrounds で `Kyounani.swiftpm` を起動（実行入口）。
- **旧バックアップ（formatVersion=1等）は復元不可**。現行は **formatVersion=2のみ**。
- テスト対象データが無い場合は親モードで数件作成してから実施。

## 1. 5分スモーク（必須）
- [ ] Today: 起動直後にToday表示 / 「きょう・つぎ・あした」表示 / 子どもフィルタ切替
- [ ] Calendar: Today/Calendarタブ往復 / 月週切替 / 日セル2件+`+N`
- [ ] DayDetail: 日別詳細に遷移し、予定タップで読み上げ+リング
- [ ] 親ゲート: 右上3本指2秒長押しで起動、4点シーケンス解除、ロックで子どもモード復帰
- [ ] CRUD: 親モードで新規作成・編集・削除（空タイトルでも保存）
- [ ] 繰り返し例外: 「この日だけ / 以降 / 全体」編集、削除確認、影響範囲プレビュー
- [ ] バックアップ: `.kybk` 書き出し→同パスフレーズで復元、誤パスフレーズで既存データ無変更
- [ ] スタンプ追加: Files/Photos追加、EventEditorで選択可能

## 2. Diagnostics（親モード）
- [ ] 親モードから Diagnostics 画面を開ける
- [ ] 有効Repository種別（SwiftData/FileBacked/InMemory）が表示される
- [ ] Repository lastError（なければ「異常なし」）が表示される
- [ ] バックアップ仕様（formatVersion=2 / PBKDF2-HMAC-SHA256 / AES-GCM）が表示される
- [ ] セルフテスト実行で、祝日CSV/RecurrenceEngine/バックアップround-trip結果が表示される
- [ ] 失敗時は赤バナーで気づける（子どもモードでは非表示）

## 3. リセット（トラブル時）
- [ ] 親モードの「データを全削除（リセット）」を実行できる
- [ ] 予定/例外/スタンプ/カスタム画像が初期化される
- [ ] リセット後に必要なデータを再作成できる

## 4. 回帰観点
- [ ] 子どもモードで編集導線が露出しない
- [ ] テーマ切替（Kid/High Contrast）がToday/Calendar/DayDetailに反映される
