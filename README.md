# kyounani-ios
子ども向け（4才/2才）に、文字が読めなくても予定がわかるローカルカレンダーのSwiftUI実装です。

## 実装内容（現時点）
- 子どもモード起動 + フィルタ（息子/娘/両方）
- ペアレンタルゲート（4点シーケンスタップ、失敗クールダウン、非常用4桁コード）
- Todayホーム（今日の予定、次の予定、先の予定チラ見せ）
- Today→カレンダー遷移
- カレンダー（**月/週切替、日曜始まり、日別詳細ドリルダウン**）
- 日セル「予定最大2件 +N」表示（publishedのみ・childScopeフィルタ反映）
- カレンダー日次集約ロジックをViewModelで共通化（Today/Month/Weekで再利用）
- 祝日/土日色分け（祝日/日曜=赤系、土曜=青系）
- タップ時の日本語読み上げ（enhanced優先）
- 残り時間リング（1時間=1周、1時間超は多層リング）
- JapaneseHolidayService（同梱CSV読み込み）
- RecurrenceEngine（週次、祝日スキップ、override/delete/splitFromThisDate）
- Repository層で永続化を抽象化（InMemory実装）
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

## Swift Packageのローカル検証（任意）
```bash
cd KyounaniApp
swift test
```

## 運用ルール（ドキュメント更新）
- 実装変更時は、**コード変更と同じPRでドキュメントも更新**してください。
- 最低限 `README.md` と `AGENTS.md` の該当箇所更新を必須とします。

## 今後の拡張
- SwiftData Repository実装の追加
- 例外編集UI（この日だけ/以降/全体）
- スタンプ画像インポート＋トリミングUI
- 暗号化エクスポート（CryptoKit AES-GCM）
