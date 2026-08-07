# AGENTS

## 前提

- ゲームエンジン: Godot 4.7
- スクリプト言語: GDScript
- シェーダー言語: Godot Shader Language

### プラグイン

- [Godot AI](https://github.com/hi-godot/godot-ai)

## ドキュメント

作業前に、次の対応するファイルを参照すること。

- 設計: `docs/DESIGN.md`
- GDScript関連: `docs/GDSCRIPT.md`
- Shader関連: `docs/SHADER.md`

## 基本方針

情報が不足している、選択肢が複数あるなど、確認が必要な場合、質問してから実装を進める。

複数の規則が競合する場合は、次の優先順位に従う。

1. ユーザーからの明示的な指示
2. 参照ドキュメント
3. 既存実装

ノード、クラス名の命名は次に従う。

- 抽象的になりすぎない範囲でシンプルな名前をつける。
- 機能を機械的に説明するような名前ではなく、役割に基づいた名前をつける。

### 注意事項

- `.godot/` 以下のファイルは編集しない。ただし、Godotによるインポートや検証で自動的に生成、更新されることは許容する。
- `addons/` 以下のファイルは編集しない。
- フォルダ名の最初に `_` がついているフォルダは、指示がない限り編集しない。

## Godot AI MCP

Godot Editorとの連携にはGodot AI MCPを使用する。公開ドメインは次のとおり。

- `api`
- `batch`
- `editor`
- `filesystem`
- `game`
- `input_map`
- `node`
- `project`
- `resource`
- `scene`
- `testing`

次の作業は、MCPツールを使わない。

- スクリプト・シェーダーの作成、編集。
- `.tscn` の新規作成。
- 文字列・パスの一括置換。

## 作業前の確認

作業を開始する前に、対象とその周辺の実装を確認する。

- 責務、所有関係、依存関係
- SceneTree上の位置
- Signalと公開API
- 関連するResourceとプロジェクト設定
- 再利用可能な既存実装

## 検証

実装内容に応じた検証を行う。検証方法は、次の優先順位に従う。

1. Godot AI MCP
2. GodotのCLIコマンド
3. 静的なファイル確認

CLI検証は、プロジェクトルートから、Godotコマンドに限り通常ユーザー権限のサンドボックス外で実行する。

インポート検証:

```powershell
cmd.exe /d /c 'set "APPDATA=%TEMP%\codex-godot-validation\Roaming" && set "LOCALAPPDATA=%TEMP%\codex-godot-validation\Local" && call godot.cmd --headless --path . --import'
```

> [!WARNING]
> PowerShell の外側の単一引用符を二重引用符へ変更したり、`\"` でエスケープしたりしてはならない。

シーン実行検証:

```powershell
godot --headless --path . "res://検証対象シーン.tscn" --quit-after 60
```

## 実装後の報告

実装が終了した後は、次の内容を報告する。

- 実装: どこをどのように変更・追加したのかを文章で簡潔に。
- エラー: 作業中に発生したものも含めて、解決済みと未解決に分け列挙する。

ゲーム、エディタには影響しない、かつ、無視しても問題のないエラーは報告しなくて良い。
