# GDSCRIPT

## 基本原則

- インデントにはタブを使用する。
- 改行を多用しない。
    - 引数の数が4つ以上であれば、基本的に改行を使用する。
    - 文字数は100文字を目安とする。
    - `assert`、`push_error`、`push_warning` は120文字を目安とする。
- 関数間には2行の空行を置く。
- カンマの後には1つの空白を入れる。
- 演算子の前後には1つの空白を入れる。
- 関数内部では、論理的に異なる処理のまとまりを分けるために空行を使用する。
- `@export_range` では、必要以上に広い範囲の値を設定しない。

## 命名

### ファイル

`snake_case` を使用する。

### Node

`PascalCase`を使用する。

### Class

`PascalCase`を使用する。

### Signal

`snake_case`を使用する。

- 何らかの出来事が発生したことを通知するSignalは、`changed`、`finished`、`died` など、過去形で何が起きたかを明示する。

### Enum

Enum名は `PascalCase`を使用し、メンバには `CONSTANT_CASE` を使用する。

- 各メンバーは1行ずつ記述する。

### 定数

`CONSTANT_CASE`を使用する。

### 関数・変数

`snake_case`を使用する。

- スクリプト内部でのみ使用することを意図した関数・変数は、名前の先頭に `_` を付ける。
- `bool` 型の変数や真偽値を返す関数には、必要に応じて `is_`、`has_`、`can_` などの接頭辞を使用し、状態や判定内容が分かる名前にする。
- Signalを受け取って呼び出されるコールバック関数は、名前の先頭に `_on_` を付ける。

## 順序

スクリプト内の要素は、次の順序を基本とする。

```text
01. @tool, @icon, @static_unload
02. class_name
03. extends
04. ## doc comment

05. signals
06. enums
07. constants
08. static variables
09. @export variables
10. remaining regular variables
11. @onready variables

12. _static_init()
13. remaining static methods
14. overridden built-in virtual methods
    1. _init()
	2. _enter_tree()
	3. _ready()
	4. _process()
	5. _physics_process()
	6. remaining virtual methods
15. overridden custom methods
16. remaining methods
17. inner classes
```

- ユーザー定義の変数・関数では、外部からの利用を意図したものを先に、スクリプト内部でのみ使用する `_` 付きのものを後に記述する。
    - 関数では、外部から呼び出す関数、Signalのコールバック関数、その他の内部用関数の順を基本とする。
- 同じ役割や機能に関係するものは、できるだけ近くにまとめる。必ずしも基本順序を守る必要はない。
- 名前順ではなく、コードの役割や処理の流れが理解しやすい順序を優先する。

## 型

静的型付けを基本とし、型が明確な場合のみ型推論を使用する。

### 型を明示する場合

次の場合は型を明示する。

- メンバー変数
- 関数の引数
- 関数の戻り値
- 型推論の結果が `Variant` になる場合
- 型推論だけでは意図が不明確になる場合

戻り値がない関数には `-> void` を記述する。

### 型推論を使用する場合

次の場合は `:=` による型推論を使用してよい。

- ローカル変数の型が右辺から明白な場合
- 具体的な型が確定し、可読性を損なわない場合

### 型キャスト

- 型が異なる可能性のある値を、特定の型として扱えるか確認する必要がある場合は、`as` による型キャストを使用してよい。

    ```gdscript
    var player := body as Player
    if player == null:
        return
    ```

## Godot 固有の実装

### Node の参照

Scene内のNodeをメンバー変数として参照する場合は、原則として `@onready` を使用する。

```gdscript
@onready var sprite: Sprite2D = $Sprite2D
```

- スクリプトを持つ Node からの相対的な位置関係が明確で、Scene構造の一部として扱うNodeは `$` で参照する。
- Scene 内で位置が変わる可能性があるNode や、階層構造に依存せず参照したい重要な Node にはScene Unique Nameを設定し、`%` で参照する。
- 単にパスを短くする目的でScene Unique Nameを使用しない。

```gdscript
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var health_bar: ProgressBar = %HealthBar
```

## エラーハンドリング

- 実際に発生し得る失敗のみ処理し、設計上保証される条件に過剰な防御処理を追加しない。
- Godot APIが返す `Error` や `null` をその契約に従って処理し、欠如が正常に起こり得る場合のみ nullable な取得方法を使用する。
- 成立すべき前提条件の検証には `assert`、実行を継続しながら異常を報告する場合は `push_error` または `push_warning` を使用する。
- 異常を黙って無視したり、不適切なフォールバックや早期 return で隠したりしない。

## コメント

コメントは最低限にする。

内容に応じて次を使用する。

- NOTE: 実装の意図・想定用途・背景
- TODO: 未実装の作業が残っている
- FIXME: 問題があり、修正が必要

### セクション区切り

ファイル内の変数や関数が多く、役割ごとに分けた方が読みやすい場合のみ、`# --- セクション名 ---` の形式で区切る。

- セクション名には、その範囲の役割を簡潔に表す名前を付ける。
- 小規模なスクリプトでは、不要なセクション区切りを追加しない。
