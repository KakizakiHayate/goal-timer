# マジックナンバー禁止ガイドライン

コード内でのマジックナンバー（意味が不明確なリテラル値）の使用を禁止し、定数化するためのガイドラインです。

---

## 1. マジックナンバーとは

**マジックナンバー**とは、コード内に直接記述された数値リテラルで、その意味や目的が明確でないものを指します。

```dart
// ❌ マジックナンバーの例
final hours = totalSeconds ~/ 3600;
if (totalMinutes > 0) { ... }
_state.value = state.copyWith(totalSeconds: 60 * 60);
```

---

## 2. 定数化が必要なケース

### 2.1 ビジネスロジックで使用する数値

**必ず定数化が必要:**

| カテゴリ | 例 | 定数化方法 |
|----------|-----|-----------|
| 時間変換 | `60`（秒→分）, `3600`（秒→時間） | `TimeUtils.secondsPerMinute`, `TimeUtils.secondsPerHour` |
| バリデーション閾値 | `> 0`, `<= 0` | `> TimeUtils.minValidSeconds`, `<= TimeUtils.minValidMinutes` |
| ビジネスルール | 最小値、最大値、デフォルト値 | 専用の定数クラスで定義 |
| 状態判定 | 初期値、完了条件 | `TimerConstants.countdownCompleteThreshold` |

```dart
// ✅ 正しい例
final hours = totalSeconds ~/ TimeUtils.secondsPerHour;
if (totalMinutes > TimeUtils.minValidMinutes) { ... }
final countupSeconds = TimerConstants.countupMaxHours * TimeUtils.secondsPerHour;
```

### 2.2 UIロジックで使用する数値

**必ず定数化が必要:**

| カテゴリ | 例 | 定数化方法 |
|----------|-----|-----------|
| 表示形式の切り替え条件 | `if (hours > 0)` → HH:MM:SS表示 | `if (hours >= TimeUtils.hoursThresholdForExtendedFormat)` |
| 計算に使う変換係数 | `_selectedHours * 60` | `_selectedHours * TimeUtils.minutesPerHour` |

```dart
// ✅ 正しい例
if (hours >= TimeUtils.hoursThresholdForExtendedFormat) {
  return '$hours:$minutes:$seconds';
}

final totalMinutes = _selectedHours * TimeUtils.minutesPerHour + _selectedMinutes;
```

---

## 3. 定数化が不要なケース（許容されるマジックナンバー）

### 3.1 UI表示専用の数値

**定数化不要:**

| カテゴリ | 例 | 理由 |
|----------|-----|------|
| ウィジェットのサイズ | `width: 280`, `height: 200` | レイアウト調整用でビジネスロジックに影響しない |
| パディング・マージン | `EdgeInsets.all(16)` | SpacingConstsで定義済みならそちらを使用 |
| 角丸の半径 | `BorderRadius.circular(20)` | デザイン定数として許容 |
| アニメーション時間 | `Duration(milliseconds: 300)` | AnimationConstsで定義済みならそちらを使用 |
| リストの件数表示 | `childCount: 24`, `childCount: 60` | ピッカーの選択肢数など |
| 文字列のパディング | `padLeft(2, '0')` | フォーマット用 |

```dart
// ✅ 許容される例（UI表示専用）
Container(
  width: 280,
  height: 280,
  child: ListWheelScrollView.useDelegate(
    itemExtent: 40,
    childDelegate: ListWheelChildBuilderDelegate(
      childCount: 24,  // 0〜23時の選択肢
      ...
    ),
  ),
)
```

### 3.2 その他許容されるケース

| カテゴリ | 例 | 理由 |
|----------|-----|------|
| インデックス | `index == 0`, `substring(0, 8)` | 配列操作の基本 |
| 増減値 | `count + 1`, `count - 1` | 単純なインクリメント/デクリメント |
| 比率・割合 | `0.0`, `1.0`, `0.5` | 進捗率などの標準的な範囲 |
| 空文字列判定 | `string.isEmpty`, `list.length == 0` | 標準的なnull/empty判定 |

---

## 4. 定数の定義場所

### 4.1 時間関連の定数

**ファイル:** `lib/core/utils/time_utils.dart`

```dart
class TimeUtils {
  // 時間変換の定数
  static const int secondsPerMinute = 60;
  static const int minutesPerHour = 60;
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;

  // しきい値の定数
  static const int hoursThresholdForExtendedFormat = 1;
  static const int minutesThresholdForExtendedFormat = 60;

  // バリデーション用の定数
  static const int minValidMinutes = 0;
  static const int minValidSeconds = 0;
}
```

### 4.2 機能固有の定数

**ファイル:** 各機能のViewModel内またはconstantsファイル

```dart
// lib/features/timer/view_model/timer_view_model.dart
class TimerConstants {
  static const int tutorialDurationSeconds = 5;
  static const int countdownCompleteThreshold = 0;
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
  static const int countupMaxHours = 1;
  static const int initialPomodoroRound = 1;
}
```

### 4.3 設定関連の定数

**ファイル:** `lib/core/data/local/local_settings_datasource.dart`

```dart
class LocalSettingsDataSource {
  // タイマー設定の定数
  static const int _defaultTimerMinutes = 25;
  static const int _minTimerMinutes = 1;
  static const int _maxTimerHours = 24;

  // 秒単位に変換した定数（外部公開用）
  static const int defaultTimerSeconds =
      _defaultTimerMinutes * TimeUtils.secondsPerMinute;
  static const int minTimerSeconds =
      _minTimerMinutes * TimeUtils.secondsPerMinute;
  static const int maxTimerSeconds =
      _maxTimerHours * TimeUtils.secondsPerHour;
}
```

### 4.4 アプリ全体の定数

**ファイル:** `lib/core/utils/app_consts.dart`

```dart
class AppConsts {
  // 外部リンク
  static const String privacyPolicyUrl = 'https://...';
  static const String contactFormUrl = 'https://...';

  // アプリ情報
  static const String appName = 'Goal Timer';
  static const String appVersion = '1.0.0';
}
```

---

## 5. 定数の命名規則

### 5.1 命名パターン

| パターン | 用途 | 例 |
|----------|------|-----|
| `xxxPerYyy` | 変換係数 | `secondsPerMinute`, `minutesPerHour` |
| `xxxThreshold` | しきい値 | `hoursThresholdForExtendedFormat` |
| `minXxx` / `maxXxx` | 最小値/最大値 | `minTimerSeconds`, `maxTimerHours` |
| `defaultXxx` | デフォルト値 | `defaultTimerSeconds`, `defaultTimerMinutes` |
| `xxxCount` | 件数 | `maxGoalCount` |
| `initialXxx` | 初期値 | `initialPomodoroRound` |

### 5.2 プライベート定数

内部でのみ使用する定数はアンダースコアプレフィックスを付ける:

```dart
static const int _defaultTimerMinutes = 25;  // 内部用
static const int defaultTimerSeconds = ...;   // 外部公開用
```

---

## 6. チェックリスト

コードレビュー時に以下を確認:

- [ ] ビジネスロジック内に数値リテラルがないか
- [ ] 条件分岐で `> 0`, `< 0`, `== 0` などを直接使用していないか
- [ ] 時間変換で `* 60`, `/ 60`, `* 3600` などを直接使用していないか
- [ ] バリデーション条件がハードコードされていないか
- [ ] 定数の命名が意味を正しく表しているか
- [ ] 定数の定義場所が適切か（汎用 → TimeUtils、機能固有 → 各Constantsクラス）

---

## 7. よくある修正パターン

### Before → After

```dart
// ❌ Before
final hours = totalSeconds ~/ 3600;
final minutes = (totalSeconds % 3600) ~/ 60;

// ✅ After
final hours = totalSeconds ~/ TimeUtils.secondsPerHour;
final minutes = (totalSeconds % TimeUtils.secondsPerHour) ~/ TimeUtils.secondsPerMinute;
```

```dart
// ❌ Before
if (totalMinutes > 0) { ... }

// ✅ After
if (totalMinutes > TimeUtils.minValidMinutes) { ... }
```

```dart
// ❌ Before
_selectedHours = widget.initialMinutes ~/ 60;
final totalMinutes = _selectedHours * 60 + _selectedMinutes;

// ✅ After
_selectedHours = widget.initialMinutes ~/ TimeUtils.minutesPerHour;
final totalMinutes = _selectedHours * TimeUtils.minutesPerHour + _selectedMinutes;
```

```dart
// ❌ Before
_state.value = state.copyWith(totalSeconds: 60 * 60, currentSeconds: 0);

// ✅ After
final countupSeconds = TimerConstants.countupMaxHours * TimeUtils.secondsPerHour;
_state.value = state.copyWith(
  totalSeconds: countupSeconds,
  currentSeconds: TimerConstants.countdownCompleteThreshold,
);
```

---

## 8. 例外と判断基準

マジックナンバーかどうか迷った場合の判断基準:

1. **その数値を変更したら、他の箇所も変更が必要か？** → Yes なら定数化
2. **その数値の意味を説明できるか？** → 説明が必要なら定数化
3. **同じ数値が複数箇所で使われているか？** → Yes なら定数化
4. **ビジネスルールに関わる数値か？** → Yes なら定数化
5. **UIのレイアウト調整のみに使う数値か？** → Yes なら定数化不要（許容）

---

## 9. 関連ファイル

- `lib/core/utils/time_utils.dart` - 時間関連の定数とユーティリティ
- `lib/core/utils/app_consts.dart` - アプリ全体の定数
- `lib/core/utils/spacing_consts.dart` - スペーシング定数
- `lib/core/utils/animation_consts.dart` - アニメーション定数
- `lib/core/utils/color_consts.dart` - カラー定数
