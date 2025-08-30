# Goal Timer プロジェクトガイド

## 1. プロジェクト概要

### アプリケーション名
**Goal Timer** - 目標管理と学習時間記録アプリケーション

### 目的
学習者が目標を設定し、学習時間を記録・管理することで、効率的な学習習慣の形成と目標達成をサポートするモバイルアプリケーション。

### 主要機能
- **目標管理**: 学習目標の作成・編集・削除・達成状況の追跡
- **タイマー機能**: 学習時間の計測と記録
- **学習ログ**: 日々の学習記録（Daily Study Logs）の管理
- **統計情報**: 学習時間、達成率、継続日数などの可視化
- **メモ機能**: 学習内容や気づきの記録
- **認証システム**: メール/パスワード、Google、Apple Sign-In対応
- **オフライン対応**: ローカルDBとクラウドDBの自動同期

### ターゲットユーザー
- 資格試験や受験勉強に取り組む学習者
- スキルアップを目指す社会人
- 学習習慣を身につけたい人

## 2. アプリ設計

# ✅ アプリ設計ドキュメント：課題・ターゲット・価値の言語化

---

## 2.1. 🎯 解決する課題（ユーザーの根本的な悩み）

### ✅ 表面的な課題（他アプリも対応）

- 勉強や習慣の記録を残したい
- 時間を測って集中したい
- モチベーションを保ちたい

### ❗ 深層的な課題（このアプリが本質的に解決するもの）

- 「やりたいと思っているのに、続かない」
- 「目標はあるのに、行動できない」
- 「人間の意志力だけでは目標達成は無理だと感じている」
- 「目標が多すぎて、何を優先すべきか分からなくなる」

---

## 2.2. 👤 ターゲットユーザー

| 属性 | 内容 |
| --- | --- |
| 年齢層 | 18〜35歳の学生・若手社会人 |
| 特徴 | モチベはあるが、継続できずに自己嫌悪してしまう |
| 行動傾向 | 勉強・習慣化を繰り返し挫折している／YouTube・SNSを見てしまう |
| 求めているもの | 精神論ではなく、「仕組みで行動を支える」サポートツール |
| 使用目的 | 資格勉強／受験勉強／副業・スキルアップ／ダイエットなどの自己投資 |

---

## 2.3. 💎 このアプリの価値（バリュープロポジション）

> 「本気で目標を達成したい人のための、
> 
> モチベーションに頼らず続けられる"仕組み"を提供するアプリ」
> 

---

### ✅ 差別化ポイント

| 特徴 | 内容 |
| --- | --- |
| 🎯 ネガティブ回避設計 | 「これをやらないとどうなるか？」を明文化し、行動の動機を引き出す |
| 🎯 目標数の制限 | 無制限に目標を作れず、「本当に重要なこと」だけに集中できる |
| 🎯 タイマー3モード | 通常・カウントダウン・ポモドーロの3方式で目的に応じて選べる |
| 🎯 シンプルUI + 中性デザイン | 男性・女性問わず"努力する自分"が恥ずかしくない設計 |

---

## 2.4. ✨ 一言で表すアプリの価値

> 「人間の弱さ」を前提に設計された、
仕組みで自分を動かすための目標達成タイマーアプリ。
> 

---

## 2.5. 🧠 補足メッセージ（開発思想）

- このアプリは、精神力のある人のためではなく、**精神力に自信がない人が、"それでも続けられるようにする"ためのアプリ**です。
- 行動できないのは意志が弱いからではなく、「仕組みがないから」。
- このアプリが提供するのは、"意思の代わりになる仕組み"です。

## 3. 技術スタック

### フレームワーク
- **Flutter**: 3.29.0
- **Dart SDK**: 3.7.0

### 状態管理
- **flutter_riverpod**: 2.4.9 - アプリケーション全体の状態管理
- **riverpod_annotation**: コード生成による型安全な実装

### バックエンド・データベース
- **Supabase**: 2.3.4 - BaaS（認証、リアルタイムDB、ストレージ）
- **SQLite** (sqflite 2.4.2): ローカルデータベース
- **Dio**: 5.4.1 - HTTP通信

### 認証
- **google_sign_in**: 6.2.1
- **sign_in_with_apple**: 6.1.0
- **local_auth**: 2.1.8 - 生体認証
- **firebase_core**: 3.14.0 - Firebase統合

### UI/UX
- **fl_chart**: 0.71.0 - グラフ表示
- **cupertino_icons**: iOSスタイルアイコン

### 開発ツール
- **freezed**: イミュータブルモデルのコード生成
- **json_serializable**: JSONシリアライゼーション
- **build_runner**: コード生成の実行

### その他
- **connectivity_plus**: 5.0.2 - ネットワーク状態監視
- **shared_preferences**: 2.2.2 - 簡易データ保存
- **flutter_dotenv**: 5.1.0 - 環境変数管理
- **logger**: 2.0.2+1 - ログ出力

## 4. アーキテクチャ

### アーキテクチャパターン
**Feature-First Architecture** と **Clean Architecture** の組み合わせを採用。

### ディレクトリ構造
```
lib/
├── core/                    # 共通機能・基盤コード
│   ├── config/             # アプリ設定・環境設定
│   ├── data/               
│   │   ├── datasources/    # データソース抽象化
│   │   │   ├── local/      # SQLite実装
│   │   │   └── remote/     # Supabase実装
│   │   ├── local/          # ローカルDB詳細実装
│   │   └── repositories/   # リポジトリ実装
│   │       └── hybrid/     # ローカル・リモート統合
│   ├── models/             # 共通データモデル
│   ├── provider/           # グローバルプロバイダー
│   ├── services/           # 共通サービス（同期など）
│   ├── usecases/           # ビジネスロジック
│   ├── utils/              # ユーティリティ関数
│   └── widgets/            # 共通UIコンポーネント
│
├── features/               # 機能別モジュール
│   ├── auth/              # 認証機能
│   ├── goal_detail/       # 目標詳細
│   ├── goal_timer/        # タイマー機能
│   ├── home/              # ホーム画面
│   ├── memo_record/       # メモ記録
│   ├── settings/          # 設定
│   ├── splash/            # スプラッシュ画面
│   └── statistics/        # 統計情報
│
├── main.dart              # エントリーポイント
└── routes.dart            # ルーティング設定
```

### 各機能モジュールの構造
```
features/[機能名]/
├── domain/
│   ├── entities/          # ビジネスエンティティ
│   ├── repositories/      # リポジトリインターフェース
│   └── usecases/          # ユースケース
├── data/
│   ├── datasources/       # データソース実装
│   ├── models/            # データモデル
│   └── repositories/      # リポジトリ実装
└── presentation/
    ├── screens/           # 画面
    ├── view_models/       # ViewModel (StateNotifier)
    └── widgets/           # 機能固有のウィジェット
```

### データフロー
1. **UI層** → ViewModelにイベントを送信
2. **ViewModel** → UseCaseを呼び出し
3. **UseCase** → Repositoryを通じてデータ操作
4. **Repository** → DataSourceからデータ取得/更新
5. **DataSource** → ローカルDB/リモートAPIと通信

## 5. 開発ガイドライン

### コーディング規約
- **Linter**: `flutter_lints`パッケージの推奨ルールに準拠
- **コード分析**: `flutter analyze`でエラーがないこと
- **フォーマット**: `flutter format`を適用

### 命名規則
- **ファイル名**: snake_case (例: `goal_timer_screen.dart`)
- **クラス名**: PascalCase (例: `GoalTimerScreen`)
- **変数・関数名**: camelCase (例: `startTimer()`)
- **定数**: UPPER_SNAKE_CASE (例: `MAX_GOAL_COUNT`)
- **バージョン管理**: ファイル名にバージョン番号（v2, v3等）を使用しない

### ファイル構成のルール
- 1ファイル1クラスを原則とする
- モデルクラスはFreezedを使用してイミュータブルに
- ViewModelはStateNotifierを継承
- 画面ファイルは`_screen.dart`で終わる

### コード生成ファイル
- `*.freezed.dart`: Freezedが生成するファイル
- `*.g.dart`: json_serializableが生成するファイル
- これらは`.gitignore`に含め、コミットしない

### 5.1. UI/UXデザインガイドライン

#### 5.1.1. カラーパレット

##### プライマリカラー（ブランドカラー）
- **Primary**: `#3B82F6` - 集中を促す青色
  - **使用箇所**: AppBar背景、FloatingActionButton、プライマリボタン、進捗表示、フォーカス状態
  - **実装**: `ColorConsts.primary`
  - **使用頻度**: プロジェクト全体で105箇所
- **Primary Dark**: `#2563EB` - プライマリの濃い版
- **Primary Light**: `#60A5FA` - グラデーション用
- **Primary Extra Light**: `#DBEAFE` - 背景用

##### システムカラー
- **Success**: `#10B981` - 成功・完了状態（緑色）
- **Error**: `#EF4444` - エラー・警告状態（赤色）

##### ニュートラルカラー
- **Background Primary**: `#F8F9FA` - メイン背景
- **Background Secondary**: `#E9ECEF` - セカンダリ背景
- **Card Background**: `#FFFFFF` - カード背景
- **Text Primary**: `#111827` - メインテキスト
- **Text Secondary**: `#6B7280` - セカンダリテキスト
- **Text Tertiary**: `#9CA3AF` - 補助テキスト

##### 特殊用途色（ハードコード）
- **Timer Free Mode**: `#059669` - タイマーのフリーモード専用
- **Achievement Gold**: `#FFD700` - 実績表示用ゴールド
- **Achievement Orange**: `#FF6B35` - 実績表示用オレンジ

#### 5.1.2. スペーシングシステム

##### 基本スペーシング
```dart
SpacingConsts.xxs  // 2.0  - 極極小
SpacingConsts.xs   // 4.0  - 極小  
SpacingConsts.sm   // 8.0  - 小
SpacingConsts.md   // 16.0 - 中（基準）
SpacingConsts.lg   // 24.0 - 大
SpacingConsts.xl   // 32.0 - 特大
SpacingConsts.xxl  // 48.0 - 超特大

// 短縮エイリアス（旧V2互換）
SpacingConsts.s    // sm と同じ
SpacingConsts.m    // md と同じ
SpacingConsts.l    // lg と同じ
```

##### レイアウト専用
- **セクション間**: `SpacingConsts.xl` (32.0)
- **カードパディング**: `SpacingConsts.md` (16.0)
- **画面端余白**: 20.0

#### 5.1.3. タイポグラフィ

##### ヘッダー系
- **H1**: 32px, SemiBold (600) - 画面タイトル
- **H2**: 28px, SemiBold (600) - セクションタイトル
- **H3**: 24px, SemiBold (600) - サブセクション
- **H4**: 20px, SemiBold (600) - 小見出し

##### 本文系
- **bodyLarge**: 18px, Regular (400) - 重要な本文
- **bodyMedium**: 16px, Regular (400) - 標準本文
- **bodySmall**: 14px, Regular (400) - 補助本文

##### ラベル・キャプション系
- **labelLarge**: 16px, Medium (500)
- **labelMedium**: 14px, Medium (500)
- **labelSmall**: 12px, Medium (500)
- **caption**: 12px, Regular (400)

##### 特殊用途
- **timer**: 48px, Light (300) - タイマー表示用
- **number**: 24px, SemiBold (600) - 数値表示用

##### 使用例
```dart
// ヘッダー系
TextConsts.h1, h2, h3, h4

// 本文系
TextConsts.bodyLarge, bodyMedium, bodySmall

// エイリアス（旧V2互換）
TextConsts.body    // bodyMedium と同じ
```

#### 5.1.4. 主要コンポーネント

##### CommonButton
- **バリアント**: primary, secondary, outline, ghost, success, warning, error
- **サイズ**: small, medium, large
- **実装例**: `CommonButton(variant: ButtonVariant.primary)`
- **特徴**: アニメーション付きタップフィードバック

##### CommonCard
- **バリアント**: standard, elevated, outlined
- **タップ対応版**: PressableCard（スケールアニメーション付き）
- **実装**: マイクロインタラクション対応

##### CustomTextField
- **特徴**: フォーカス時にプライマリカラーでハイライト
- **機能**: バリデーション表示、文字数制限表示
- **アニメーション**: フォーカス時のボーダーアニメーション

##### 専用ウィジェット
- **AuthButton**: 認証用ボタン（Email/Google/Apple）
- **goal_card**: ゴール表示カード
- **metric_card**: メトリクス表示
- **circular_progress_indicator**: カスタム進捗表示

#### 5.1.5. アニメーション定数

##### 基本アニメーション
```dart
AnimationConsts.fast         // 200ms - 基本フェード
AnimationConsts.medium       // 300ms - 標準遷移
AnimationConsts.slow         // 500ms - ゆっくりした動き
AnimationConsts.extraSlow    // 800ms - 特殊効果
```

##### 用途別アニメーション
```dart
AnimationConsts.buttonTap      // 150ms - ボタンタップ
AnimationConsts.pageTransition // 350ms - 画面遷移
AnimationConsts.modalTransition // 250ms - モーダル表示
AnimationConsts.fadeTransition  // 200ms - フェード
AnimationConsts.scaleTransition // 300ms - スケール変更
```

##### マイクロインタラクション
- **スケールプレス**: 0.95（タップ時）
- **スケールホバー**: 1.02
- **オパシティ無効**: 0.5
- **オパシティプレス**: 0.8

#### 5.1.6. 実装ガイドライン

##### 色の使用ルール
- **定数使用**: ハードコードされた色を避け、`ColorConsts`を使用
- **プライマリカラー**: 重要なアクション・状態表示に限定使用
- **グラデーション**: `[ColorConsts.primary, ColorConsts.primaryLight]`を標準パターンとして使用
- **特殊色**: 機能固有の色のみハードコード許可

##### スペーシングのルール
- **基準値**: `SpacingConsts.md`（16.0）を基準とする
- **カードパディング**: `SpacingConsts.md`
- **セクション間**: `SpacingConsts.xl`（32.0）
- **画面端余白**: 20.0（固定値）

##### コンポーネント使用ルール
- **ボタン**: 新しいボタンは`CommonButton`を使用
- **カード**: 基本的に`CommonCard`または`PressableCard`を使用
- **入力フィールド**: `CustomTextField`を基本とする
- **作成前確認**: カスタムコンポーネント作成前に既存ウィジェットを確認
- **一貫性**: 既存パターンに準拠した実装を心がける

##### テーマシステム
- **現在**: Material 3 + `ColorScheme.fromSeed(Colors.blue)`
- **ダークモード**: 定数準備済み、実装は今後の課題
- **カスタマイズ**: `ColorConsts`経由での統一管理

## 6. 環境設定

### 必要な環境変数（.env ファイル）
```
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_ENV=development
DEBUG_MODE=true
```

### セットアップ手順
1. リポジトリのクローン
```bash
git clone [repository-url]
cd goal_timer
```

2. Flutter SDKの確認
```bash
flutter doctor
```

3. 依存関係のインストール
```bash
flutter pub get
```

4. 環境変数ファイルの作成
```bash
cp .env.example .env
# .envファイルを編集してSupabase情報を設定
```

5. コード生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 開発ツールの推奨設定
- **VSCode**: Flutter拡張機能をインストール
- **Android Studio**: Flutter/Dartプラグインをインストール
- **Xcode**: iOS開発用（Macのみ）

## 7. ビルド・実行方法

### 開発環境での実行
```bash
# デバッグモードで実行
flutter run

# 特定のデバイスを指定
flutter run -d [device_id]

# ホットリロード有効（実行中に'r'キー）
# ホットリスタート（実行中に'R'キー）
```

### ビルドコマンド
```bash
# iOS用ビルド
flutter build ios

# Android APKビルド
flutter build apk

# Android App Bundle（Google Play用）
flutter build appbundle

# リリースモードでのビルド
flutter build [platform] --release
```

### テストコマンド
```bash
# すべてのテストを実行
flutter test

# 特定のテストファイルを実行
flutter test test/integration/sync_integration_test.dart

# カバレッジレポート生成
flutter test --coverage
```

### その他の便利なコマンド
```bash
# コード分析
flutter analyze

# コードフォーマット
flutter format lib/

# 依存関係の更新確認
flutter pub outdated

# クリーンビルド
flutter clean
flutter pub get
```

## 8. 重要な機能の実装詳細

### 認証システム
**AuthViewModel** が中心となって認証状態を管理：
- メール/パスワード認証
- ソーシャルログイン（Google、Apple）
- 自動ログイン機能
- セッション管理

認証フロー：
1. ユーザーが認証情報を入力
2. AuthViewModelがAuthRepositoryを呼び出し
3. Supabase Authで認証処理
4. 成功時、ユーザープロファイルを自動作成
5. ローカルにもセッション情報を保存

### オフライン同期メカニズム
**HybridRepository** パターンによる実装：
- ローカル優先の読み取り（高速レスポンス）
- バックグラウンド同期
- コンフリクト解決（最新データ優先）

同期プロセス：
1. ネットワーク状態を監視
2. オンライン復帰時に自動同期開始
3. `sync_updated_at`タイムスタンプで差分検出
4. 双方向同期（ローカル→リモート、リモート→ローカル）

### 状態管理パターン
**Riverpod** による状態管理：
- `StateNotifier`: 複雑な状態管理
- `Provider`: 依存性注入
- `FutureProvider`: 非同期データ
- `StateProvider`: シンプルな状態

主要なプロバイダー：
```dart
// 認証状態
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>

// 目標データ
final hybridGoalsRepositoryProvider = Provider<HybridGoalsRepository>

// 同期状態
final syncStateProvider = StateProvider<SyncState>
```

## 9. トラブルシューティング

### よくある問題と解決方法

#### 環境変数エラー
```
エラー: Unable to load asset: .env
```
解決: プロジェクトルートに`.env`ファイルを作成し、必要な環境変数を設定

#### ビルドエラー
```
エラー: Conflicting outputs were detected
```
解決: `flutter pub run build_runner build --delete-conflicting-outputs`

#### 同期の問題
- ネットワーク接続を確認
- Supabaseのクォータ制限を確認
- ログで同期エラーの詳細を確認

### デバッグ方法
1. **ログ確認**: `Logger`インスタンスでログ出力
2. **Flutter Inspector**: UIの階層を視覚的に確認
3. **Network Inspector**: API通信の確認
4. **SQLite Browser**: ローカルDBの内容確認

## 10. リファクタリング履歴

### 2025年1月 - V2ファイル名の廃止
**背景**: ファイル名によるバージョン管理を廃止し、より整理されたコードベースを実現

**実施内容**:
- `v2_constants_adapter.dart`の内容を既存の定数ファイルに統合
- V2がついたファイル名をリネーム:
  - `goal_detail_screen_v2.dart` → `goal_detail_screen.dart`
  - `goal_edit_modal_v2.dart` → `goal_edit_modal.dart`
  - `goal_create_modal_v2.dart` → `goal_create_modal.dart`
- 全ファイルでV2定数の参照を標準定数に置換:
  - `SpacingConstsV2` → `SpacingConsts`
  - `TextConstsV2` → `TextConsts`

**結果**: 
- ファイル名によるバージョン管理を完全に廃止
- 定数の統一により保守性が向上
- コードベースの一貫性を確保

## 11. 今後の開発方針

### 新機能追加時の手順
1. `features/`配下に新しい機能モジュールを作成
2. Clean Architectureの層構造に従って実装
3. 必要なプロバイダーを`core/provider/`に追加
4. ルーティングを`routes.dart`に追加

### テスト作成のガイドライン
- Unit Test: ビジネスロジック、UseCase
- Widget Test: UIコンポーネント
- Integration Test: 機能全体の動作確認

### パフォーマンス最適化のポイント
- 不要な再ビルドを避ける（`const`ウィジェットの活用）
- 大きなリストには`ListView.builder`を使用
- 画像の遅延読み込み
- メモリリークの防止（適切なdispose）

### UI定数の使用方法

**SpacingConsts**: レイアウト用の余白・間隔定数
```dart
// 基本スペーシング
SpacingConsts.xxs  // 2.0 - 極極小
SpacingConsts.xs   // 4.0 - 極小  
SpacingConsts.sm   // 8.0 - 小
SpacingConsts.md   // 16.0 - 中（基準）
SpacingConsts.lg   // 24.0 - 大
SpacingConsts.xl   // 32.0 - 特大
SpacingConsts.xxl  // 48.0 - 超特大

// 短縮エイリアス（旧V2互換）
SpacingConsts.s    // sm と同じ
SpacingConsts.m    // md と同じ
SpacingConsts.l    // lg と同じ
```

**TextConsts**: テキストスタイル定数
```dart
// ヘッダー系
TextConsts.h1, h2, h3, h4

// 本文系
TextConsts.bodyLarge, bodyMedium, bodySmall

// エイリアス（旧V2互換）
TextConsts.body    // bodyMedium と同じ
```

### コントリビューション時の注意
- プルリクエスト前に`flutter analyze`と`flutter test`を実行
- コミットメッセージは明確に
- 新機能には適切なドキュメントを追加
- 破壊的変更は事前に相談
- ファイル名にバージョン番号（v2, v3等）を使用しない
- 常に説明的な変数名を使用する
- 「実装して」と言われたらコードを実装してください。
- 実装が終了したら、unitテストを行なってください。そのために、実装する前に要件に沿ってテストコードを書いてから実装を行ってください。実装が終了したらunitテストを行ってください
- 実装が終了してunitテストも成功したらipa --debugとapk --debugを実装して成功させてください