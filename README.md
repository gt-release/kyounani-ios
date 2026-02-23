# kyounani-ios
子ども向け（4才/2才）に、文字が読めなくても予定がわかるローカルカレンダーのSwiftUI実装です。

## 実装内容（現時点）
- 子どもモード起動 + フィルタ（息子/娘/両方）
- ペアレンタルゲート（4点シーケンスタップ、失敗クールダウン、非常用4桁コード）
- Todayホーム（今日の予定、次の予定、先の予定チラ見せ）
- タップ時の日本語読み上げ（enhanced優先）
- 残り時間リング（1時間=1周、1時間超は多層リング）
- JapaneseHolidayService（同梱CSV読み込み）
- RecurrenceEngine（週次、祝日スキップ、override/delete/splitFromThisDate）
- Repository層で永続化を抽象化（InMemory実装）
- 単体テスト（祝日/繰り返し）

## 構成
- `Kyounani.xcodeproj` : iOS/iPadOS Appターゲット（`Kyounani`）
- `Kyounani-iOS/Kyounani` : Appエントリポイント（`KyounaniRootView` を起動）
- `KyounaniApp/Sources/KyounaniApp/Models` : ドメインモデル
- `KyounaniApp/Sources/KyounaniApp/Services` : 祝日・繰り返し・音声
- `KyounaniApp/Sources/KyounaniApp/Repository` : Repository抽象
- `KyounaniApp/Sources/KyounaniApp/ViewModels` : MVVM ViewModel
- `KyounaniApp/Sources/KyounaniApp/Views` : SwiftUI画面
- `KyounaniApp/Tests/KyounaniAppTests` : 単体テスト

## 開き方 / 実行方法

### XcodeでiPadアプリとして実行
1. Xcodeで `Kyounani.xcodeproj` を開く。
2. Schemeで `Kyounani` を選ぶ。
3. 実行先を iPad Simulator または実機 iPad に設定する。
4. `Run`（⌘R）で起動する。

アプリ起動後は、Swift Packageで実装済みの `KyounaniRootView` が表示され、Todayホームから開始します。

### Swift Packageのローカル検証
```bash
cd KyounaniApp
swift test
```

### iOS Appターゲットのビルド検証（Xcode環境）
```bash
xcodebuild -project Kyounani.xcodeproj -scheme Kyounani -destination "generic/platform=iOS" build
```

## 今後の拡張
- SwiftData Repository実装の追加
- 月/週カレンダー画面の詳細化
- スタンプ画像インポート＋トリミングUI
- 暗号化エクスポート（CryptoKit AES-GCM）
