# Phase 1 Plan: Swift Playgrounds (.swiftpm) 起動導線

## 目的
- Mac/Xcode なしで iPad の Swift Playgrounds から `Kyounani.swiftpm` を開いて実行可能にする。
- 起動直後に子ども用 Today ホームを表示し、以下を優先して成立させる。
  - published/draft の表示制御（子どもモードは published のみ）
  - childScope フィルタ（息子/娘/両方）
  - 日本語 TTS
  - 残り時間リング

## 既存資産の再利用方針
- ドメイン/ロジックは既存 `KyounaniApp` package を再利用。
  - `Models`（Visibility, ChildScope など）
  - `RecurrenceEngine`
  - `JapaneseHolidayService`
  - `InMemoryEventRepository`
  - `TodayHomeView`, `ParentalGateView`, `ParentModeView`, `TimerRingView`
- 新規 `Kyounani.swiftpm` は executable target として、`KyounaniApp` に依存。

## 接続設計（Phase 1）
1. `Kyounani.swiftpm` に `@main App` を追加し、root で `TodayHomeView` を表示。
2. Root 側で `AppViewModel`, `SpeechService`, `InMemoryEventRepository`, `CalendarViewModel` を組み立てる。
3. 祝日 CSV は `Kyounani.swiftpm` の resources に同梱し、`Bundle.module` から読み込んで `JapaneseHolidayService(csvText:)` に渡す。
4. 親導線は Phase 1 では簡易導線（解除ボタン→既存 `ParentalGateView` / `ParentModeView`）を接続。

## 非スコープ（Phase 2 以降）
- 月/週カレンダー
- スタンプ管理
- 例外編集UI（この日だけ/以降/全体）
