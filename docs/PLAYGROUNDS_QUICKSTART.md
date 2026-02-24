# PLAYGROUNDS QUICKSTART

## 対象
- iPad Swift Playgrounds で `Kyounani.swiftpm` を起動して確認したい人向け。

## 最短手順
1. iPadでリポジトリを取得する（Files/Working Copy等）。
2. Swift Playgrounds で `Kyounani.swiftpm` を開く。
3. `Run` を押す。
4. Today画面が開くことを確認する。

## よくある詰まり
- `Kyounani.swiftpm` ではなく `KyounaniApp` を開いている
  - → App project 側（`Kyounani.swiftpm`）を開く。
- Manifest評価で `Type 'Product' has no member 'iOSApplication'` や `.placeholder / .presetColor / .pad` 連鎖エラーが出る
  - → `Kyounani.swiftpm/Package.swift` は Playgrounds 互換のため `iOSApplication` を使わず、`executable product` で動かす版を利用する。
  - → iPad側に古いコピーが残っている場合は、プロジェクトを再取得して開き直す。
- 「The package at .../KyounaniApp cannot be accessed (Code=257)」が出る
  - → `Kyounani.swiftpm` を開き直し、同梱依存（`Packages/KyounaniEmbeddedApp`）を使う状態にする。
  - → それでも改善しない場合は、Playgroundsで当該プロジェクトを閉じて再読み込み（依存解決キャッシュ更新）。
- 初回起動で表示が重い
  - → リソース展開や初期読み込みの可能性。数秒待って再確認。
- 親モードに入れない
  - → 右上固定領域で「3本指2秒長押し」を正確に実施。
- スタンプ画像が表示されない
  - → Files権限付与後に再読み込み。対応形式は実質PNG/JPEG中心。

## 注意
- 本リポジトリは iPad Swift Playgrounds 実行を優先。
- Mac / Xcode / xcodebuild を前提にした手順は採用しない。
