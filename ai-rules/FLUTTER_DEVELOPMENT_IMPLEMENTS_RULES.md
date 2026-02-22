以下を**厳守**して実装してください。出力は「変更ファイル一覧・差分・説明・セルフレビュー」を含む完全なPR草案にしてください。

---

## 1) ロール & 目標
- **あなたのロール**：Flutter/Dartエンジニア（設計〜実装〜セルフレビューまで担当）
- **最優先目標**：UI/ロジックの**重複排除**と**共通コンポーネント化**。既存画面に安全に適用し、変更影響を最小化して可読性と再利用性を最大化する。

---

## 2) コードスタイル

### 3.1 プロジェクト構成
- **Must**: ファイルは適切なレイヤ/機能配下に配置する  
- **レビュー観点**: 適切な層に置かれているか

### 3.2 命名規則
- **Must**: クラス=PascalCase、メソッド/変数=camelCase  
- **Must**: ファイル=snake_case、主要クラス名と一致（例：`UserProfile` → `user_profile.dart`）

### 3.3 Lint
- **Must**: `analysis_options.yaml` に準拠し、警告/エラー0  
- **Should**: 無効化コメントは必要最小限＋期限コメントを必ずつける

### 3.5 コメント
- **Must**: 実装予定/修正は `// TODO:` 形式で（期日＋担当必須）  
- **Should**: クラス/プロパティ/メソッドの役割を説明  
- **Must**: 複雑な処理は「意図」を明記する

### 3.6 インポート順序
3セクションに分割し、空行で区切る：
1. Flutter/Dart 標準  
2. サードパーティ  
3. プロジェクト内ファイル

```dart
// Flutter/Dart標準ライブラリ
import 'package:flutter/material.dart';

// サードパーティライブラリ
import 'package:hooks_riverpod/hooks_riverpod.dart';

// プロジェクト内ファイル
import '../../../core/constants/app_colors.dart';
```

### 3.7 マジックナンバー
- **Must**: 機能ロジックでの直値禁止 → `core/constants/` に定義  
- **Should**: UI値は1回ならOK、複数回出たら定数化

### 3.8 if文ネスト制限
- **Must**: ネストは2段まで  
- **Should**: 超える場合は早期returnまたは小関数抽出で解消

### 3.9 その他
- **Must**: 未使用インポート/コード削除  
- **Should**: メソッドは30行以内を目安に分割  
- **Must**: 変数スコープは最小化  
- **Must**: カラーコード/画像は共通定数で集中管理  
- コメントは `// ...` 形式  
- 強制アンラップ禁止

---

## 3) ディレクトリ構造の設計思想

### 4.1 `core`
- `constants` — 定数  
- `common_widgets` — 再利用ウィジェット  
- `extensions` — 拡張メソッド  
- `exceptions` — カスタム例外  
- `native_bridge` — ネイティブ連携  
- `utils` — 汎用処理  

### 4.2 `routes.dart`
- アプリ全体のルーティング定義を集中管理

### 4.3 ネイティブとのブリッジ
- **Must**: ネイティブ実装は `lib/core/native_bridge/{機能名}` に配置

---

## 4) 共通化の実装方針
1. 同一/類似UI・カラー・数値が2回以上出たら共通化対象  
2. `core/common_widgets/` へ抽出 → 既存画面置換  
3. 後方互換を維持（Propsはデフォルト値つきで柔軟に）  
4. テーマや定数を活用し、直値は避ける  
5. コメント/TODOに意図・期限を必ず記載  
6. Widgetテスト/ゴールデンテストを追加（最低1本）

---

## 5) 受け入れ基準（DoD）
- 重複が削減され、単一の出所に統合  
- Lint/CIエラー0  
- ifネスト≦2、メソッド長≦30  
- 命名規約とファイル名=クラス名の一致  
- マジックナンバー定数化（ロジック）、UIは共通化検討済み  
- コメントに意図とTODOの期限あり  
- インポート順守、未使用インポートなし  

---

## 6) 出力フォーマット（PR草案）
1. 概要（Why/What/How）  
2. 変更ファイル一覧（新規/更新/削除を明記）  
3. 差分（主要抜粋）  
4. セルフレビュー（チェックリスト全項目に回答）  
5. テスト/検証内容  
6. リスクとロールバック方法  

---

## 7) 実装テンプレ（例）

**共通ボタン**
```dart
// Flutter/Dart標準ライブラリ
import 'package:flutter/material.dart';

// サードパーティライブラリ
// （空）

// プロジェクト内ファイル
import 'package:project/core/constants/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isBusy = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isBusy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = enabled && !isBusy ? onPressed : null;
    return ElevatedButton(
      onPressed: effectiveOnPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: kSpacingSm)],
          if (isBusy) const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (isBusy) const SizedBox(width: kSpacingSm),
          Text(label),
          if (trailing != null) ...[const SizedBox(width: kSpacingSm), trailing!],
        ],
      ),
    );
  }
}
```

**定数の例**
```dart
// lib/core/constants/app_spacing.dart
const double kSpacingSm = 8;
const double kSpacingLg = 16;
```

**TODOの書き方**
```dart
// TODO(2025-09-10 @hayate): iPadの余白最適化
```