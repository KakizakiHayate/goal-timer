### UI/UXデザインガイドライン

#### カラーパレット

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

#### スペーシングシステム

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

#### タイポグラフィ

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

#### 主要コンポーネント

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

#### アニメーション定数

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