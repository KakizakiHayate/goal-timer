# Claude Code Configuration

## YOU MUST:
- 全てのTODO完了またはユーザーのアクションが必要な際は最後に一度だけ `afplay /System/Library/Sounds/Sosumi.aiff` コマンドを実行して通知する
- 回答は日本語で行ってください
- TODOには必ずブランチ作成・実装内容のテスト・コミット・push・PR作成（まだ作成されていない場合）が含まれるべきです

---

## 1. プロジェクト概要

### アプリケーション名
**Goal Timer** - 目標管理と学習時間記録アプリケーション

### 目的
学習者が目標を設定し、学習時間を記録・管理することで、効率的な学習習慣の形成と目標達成をサポートするモバイルアプリケーション。

### 主要機能
- **目標管理**: 学習目標の作成・編集・削除・達成状況の追跡
- **タイマー機能**: 学習時間の計測と記録（カウントダウン/カウントアップ/ポモドーロ）
- **学習ログ**: 日々の学習記録（Daily Study Logs）の管理
- **ストリーク**: 継続日数の追跡とリマインダー通知
- **設定**: タイマー設定、通知設定など

### ターゲットユーザー
- 資格試験や受験勉強に取り組む学習者
- スキルアップを目指す社会人
- 学習習慣を身につけたい人

詳細は **@ai-rules/PROJECT_OVERVIEW.md** を参照してください。

---

## 2. 技術スタック

### 言語・フレームワーク
- **Flutter**: 3.29.0
- **Dart SDK**: >=3.7.0 <4.0.0

### 状態管理
- **GetX**: 4.7.2（`GetxController` + `update()`）
- ※ Riverpodは使用しません

### 主要ライブラリ
| カテゴリ | ライブラリ | 用途 |
|---------|-----------|------|
| ローカルDB | sqflite | SQLiteデータベース |
| モデル生成 | freezed, json_serializable | 不変モデル定義 |
| ログ | logger | AppLoggerで使用 |
| 認証 | google_sign_in, sign_in_with_apple | ソーシャルログイン |
| 課金 | purchases_flutter | RevenueCat連携 |
| 通知 | flutter_local_notifications | ローカル通知 |
| Supabase | supabase_flutter | バックエンド連携（将来） |

---

## 3. ディレクトリ構造

```
lib/
├── core/
│   ├── data/local/           # DataSource（SQLite操作）
│   │   ├── app_database.dart
│   │   ├── database_consts.dart
│   │   ├── local_goals_datasource.dart
│   │   ├── local_study_daily_logs_datasource.dart
│   │   ├── local_users_datasource.dart
│   │   └── local_settings_datasource.dart
│   │
│   ├── models/               # Model（freezed、データ定義のみ）
│   │   ├── goals/
│   │   ├── study_daily_logs/
│   │   └── users/
│   │
│   ├── services/             # サービス（通知など）
│   │   ├── notification_service.dart
│   │   └── att_service.dart
│   │
│   ├── utils/                # ユーティリティ・定数
│   │   ├── app_logger.dart
│   │   ├── color_consts.dart
│   │   ├── spacing_consts.dart
│   │   ├── text_consts.dart
│   │   ├── time_utils.dart
│   │   └── ...
│   │
│   └── widgets/              # 共通ウィジェット
│       ├── common_button.dart
│       ├── goal_card.dart
│       └── ...
│
├── features/                 # 機能別モジュール（Feature-First）
│   ├── home/
│   │   ├── view/
│   │   │   └── home_screen.dart
│   │   └── view_model/
│   │       └── home_view_model.dart
│   │
│   ├── timer/
│   │   ├── view/
│   │   │   └── timer_screen.dart
│   │   └── view_model/
│   │       └── timer_view_model.dart
│   │
│   ├── settings/
│   ├── study_records/
│   └── goal_detail/
│
├── backup/                   # 過去の実装（参考用、変更禁止）
│
└── main.dart
```

---

## 4. アーキテクチャ・設計パターン

### MVVM（MVP版: シンプル構造）

```
View → ViewModel → DataSource → SQLite
```

- **View**: UI表示、ユーザー入力、GetBuilderで状態購読
- **ViewModel**: 状態管理、ビジネスロジック、DataSource呼び出し
- **DataSource**: 実際のDB操作（SQLite）、Map⇄Model変換
- **Model**: データ定義のみ（freezed）

※ Repository層はMVP版では省略。将来Supabase同期が必要になったら追加。

詳細は **@ai-rules/Architecture.md** を参照してください。

---

## 5. Repository設定

- **リポジトリ名**: `KakizakiHayate/goal-timer`
- **GitHub操作**: ghコマンドを使用

---

## 6. backupフォルダについて（重要）

- **backupフォルダ内のコードは一切変更してはいけません**
- backupフォルダは過去の実装を参考にするためだけに存在します
- 実装の参考として読み取ることは許可されていますが、編集・削除・移動は禁止です

---

## 7. ブランチ戦略・作業フロー

### ブランチ命名規則
- `feature/add-{機能名}` - 新機能追加
- `feature/fix-{修正内容}` - バグ修正
- 例: `feature/add-login-screen`, `feature/fix-timer-bug`

### 作業開始時（必須）
1. **基本**: `develop`ブランチから新しいブランチを作成
2. **例外**: 既存のfeatureブランチの作業を引き継ぐ場合は、そのfeatureブランチから派生可能
   - この場合、PRのベースブランチを派生元のfeatureブランチに設定

```bash
# developから作成（基本）
git checkout develop && git pull origin develop
git checkout -b feature/add-new-feature

# featureブランチから作成（引き継ぎの場合）
git checkout feature/existing-feature && git pull origin feature/existing-feature
git checkout -b feature/add-related-feature
```

### 作業終了時（必須）
1. 作業内容をコミット
2. リモートブランチにpush (`git push -u origin <ブランチ名>`)
3. PR作成（ghコマンド使用）
   - マージ先: `develop`（または派生元のfeatureブランチ）

### 禁止事項
- **developブランチでの直接作業は絶対禁止**
- いかなる変更もdevelopブランチに直接コミットしない

詳細は **@ai-rules/GIT_BRANCH_RULES.md** と **@ai-rules/COMMIT_AND_PR_GUIDELINES.md** を参照してください。

---

## 8. 修正の際の注意点

- 該当修正によって他の処理に問題がないか慎重に確認を行う
- 他の動作に関しても修正が必要な場合は既存の期待値の動作が正常に起動するように修正する

---

## 9. コミット前に確認すること（必ず実施）

- **コミット・pushを実行する前には必ずユーザーに許可を求めてください**
  - ユーザーの明示的な許可なしに、コミットやpushを実行してはいけません
  - 動作確認が完了したら、コミット内容を説明してユーザーの許可を得てください
- コミット前には必ず動作確認を行って動作が問題ないかを確認してください
  - 動作確認中にエラーが発見された際はタスクを更新してください
  - コミットする際はエラーがない状態で行ってください

---

## 10. ファイル作成時の注意点

- ファイル作成時に、そのファイルがGithubに挙げられるべきではないと判断した場合には、必ず.gitignoreに指定してください

---

## 11. 計画書（タスク）作成時のチェック観点

計画書を作成する際は、以下の項目を必ず含めること：

### 1. ユニットテストのテストケース
- 新規・改修する機能のテストケースを事前に定義する
- テストファイルのパスと、各テストケースの概要を記載する

### 2. 品質チェック項目
以下のコマンドを実行し、成功することを確認する項目を含める：

| チェック項目 | コマンド |
|-------------|---------|
| Lintチェック | `flutter analyze` / `dart run custom_lint` |
| テスト実行 | `flutter test` |
| IPAビルドチェック | `flutter build ios --release --no-codesign` |

### 3. PR作成手順
- gh認証確認（`gh auth status`）
- 失敗時の対応（`gh auth login` または `gh auth switch`）
- コミット・プッシュ・PR作成の手順

---

## 12. 実装完了時のチェックリスト（コミット前に必ず実施）

### 1. Lintチェック（必須）
```bash
flutter analyze
dart run custom_lint
```
Lintエラーがある場合は、**自動的に修正してOK**（ユーザー確認不要）

### 2. ユニットテスト（必須）
```bash
flutter test
```
すべてのテストが通ることを確認してからコミット・PR作成を行う。

### 3. IPAビルドチェック（必須）
```bash
flutter build ios --release --no-codesign
```

### 4. gh認証確認（必須）
```bash
gh auth status
```
**失敗した場合**:
```bash
gh auth login
# または
gh auth switch
```

### 5. PR作成後のレビューチェック（必須）
```bash
gh pr view <PR番号> --comments
```
- Gemini Code Assist等のレビューコメントがある場合：
  - **必ずユーザーに内容を報告する**
  - **修正内容を説明し、ユーザーの承認を得てから修正を行う**

---

## 13. PRマージ手順（「PR #XXをマージして」と言われた場合）

```bash
# 1. ローカル変更があればstash
git stash

# 2. PRをsquashマージしてブランチ削除
gh pr merge <PR番号> --squash --delete-branch

# 3. developブランチに切り替えて最新を取得
git checkout develop && git pull origin develop

# 4. マージ済みブランチの削除確認
git branch -d <ブランチ名> 2>/dev/null || echo "ローカルブランチは既に削除済み"
git push origin --delete <ブランチ名> 2>/dev/null || echo "リモートブランチは既に削除済み"
```

---

## 14. 参照すべきai-rulesファイル

| ファイル | 内容 | 参照タイミング |
|---------|------|---------------|
| `Architecture.md` | MVVM + GetX アーキテクチャ | コード実装・修正時 |
| `Design.md` | UI/UXデザインガイドライン | デザイン作業時 |
| `PROJECT_OVERVIEW.md` | プロジェクト概要 | 設計提案時 |
| `FLUTTER_DEVELOPMENT_IMPLEMENTS_RULES.md` | 命名規則・コードスタイル | 関数・クラス作成時 |
| `COMMIT_AND_PR_GUIDELINES.md` | コミット・PRルール | コミット・PR作成時 |
| `GIT_BRANCH_RULES.md` | ブランチ命名規則 | ブランチ作成時 |
| `MAGIC_NUMBER_GUIDELINES.md` | マジックナンバー禁止 | 定数使用時 |
| `ERROR_HANDLING_GUIDELINES.md` | エラーハンドリング | try-catch実装時 |
| `TESTING_GUIDELINES.md` | テスト戦略 | テスト作成時 |

---

## 15. コーディング規約

### 命名規則
- **クラス名**: PascalCase（例: `TimerViewModel`）
- **メソッド/変数名**: camelCase（例: `onTappedStartButton`）
- **ファイル名**: snake_case（例: `timer_view_model.dart`）
- **ファイル名とクラス名は一致させる**

### インポート順序（3セクションに分割、空行で区切る）
```dart
// Flutter/Dart標準ライブラリ
import 'package:flutter/material.dart';

// サードパーティライブラリ
import 'package:get/get.dart';

// プロジェクト内ファイル
import '../../../core/utils/app_logger.dart';
```

### マジックナンバー禁止
- ビジネスロジックでの直値禁止 → 定数化
- 詳細は **@ai-rules/MAGIC_NUMBER_GUIDELINES.md** を参照

### エラーハンドリング
- エラーログには必ず`stackTrace`を含める
```dart
try {
  await someOperation();
} catch (error, stackTrace) {
  AppLogger.instance.e('エラーメッセージ', error, stackTrace);
  rethrow;
}
```
- 詳細は **@ai-rules/ERROR_HANDLING_GUIDELINES.md** を参照

### その他
- 未使用インポート/コード削除
- メソッドは30行以内を目安に分割
- if文のネストは2段まで
