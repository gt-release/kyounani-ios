# Initial Stamp Assets (Phase 3)

PR作成ツールの互換性を優先し、初期スタンプは **バイナリPNGではなくJSON定義** で同梱しています。

- `builtin_stamps.json`
  - UUID（固定）
  - 表示名
  - SF Symbol 名

`StampStore` がこのJSONを読み込み、builtinスタンプを `symbol:<name>` として描画します。
ユーザー追加スタンプ（Files/Photos）は従来どおりPNG保存です。
