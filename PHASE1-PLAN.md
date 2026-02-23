# Phase 1 Plan: Swift Playgrounds (.swiftpm) 起動導線

## 目的
- Mac/Xcode なしで iPad の Swift Playgrounds から `Kyounani.swiftpm` を開いて実行可能にする。
- 起動直後に子ども用 Today ホームを表示し、以下を優先して成立させる。
  - published/draft の表示制御（子どもモードは published のみ）
  - childScope フィルタ（息子/娘/両方）
  - 日本語 TTS
  - 残り時間リング

## 完了状況（更新）
- Phase 1 の起動導線は完了。
  - `Kyounani.swiftpm` から起動して Todayホーム表示を確認。
  - `KyounaniApp` package をローカル参照して再利用。
- Phase 2 の一部（見通しUI）も実装済み。
- Phase 3 の一部（スタンプ中心UI）を実装。
  - 初期スタンプ同梱（Kyounani.swiftpm Resources: JSON+SF Symbols）
  - EventTokenRenderer に表示責務を集約
  - 親モードでスタンプ追加（Files/Photos）
  - stamps.json + 画像ファイルでユーザースタンプ復元
  - 日次集約ロジック共通化（最大2件 +N）
  - Todayホーム→カレンダー遷移
  - 月/週切替
  - 日別詳細への遷移

## 既存資産の再利用方針
- ドメイン/ロジックは既存 `KyounaniApp` package を再利用。
  - `Models`（Visibility, ChildScope など）
  - `RecurrenceEngine`
  - `JapaneseHolidayService`
  - `InMemoryEventRepository`
  - `TodayHomeView`, `ParentalGateView`, `ParentModeView`, `TimerRingView`

## 接続設計（Phase 1）
1. `Kyounani.swiftpm` に `@main App` を追加し、root で `TodayHomeView` を表示。
2. Root 側で `AppViewModel`, `SpeechService`, `InMemoryEventRepository`, `CalendarViewModel` を組み立てる。
3. 祝日 CSV は resources から読み込み `JapaneseHolidayService` へ渡す。
4. 親導線は簡易導線（解除ボタン→既存 `ParentalGateView` / `ParentModeView`）を接続。

## 次フェーズ（未完）
- 例外編集UI（この日だけ/以降/全体）
- スタンプ管理
- SwiftData Repository
