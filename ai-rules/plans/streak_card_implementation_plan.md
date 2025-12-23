# ストリークカード機能要件

## 1. 機能概要

### 目的
ユーザーが「毎日続けている感」を実感できるよう、連続学習日数と直近の学習状況を可視化する。

### 解決する課題
- 進捗率だけでは「毎日続けている」実感が得られない
- 継続のモチベーションが維持しにくい

---

## 2. 機能要件

### 2.1 ストリーク（連続学習日数）

#### 定義
**ストリーク** = 今日から遡って、連続して学習記録がある日数

#### カウントルール

| シナリオ | ストリーク数 | 説明 |
|----------|-------------|------|
| 今日学習済み、昨日も学習済み、一昨日も学習済み | 3日 | 連続3日間学習 |
| 今日学習済み、昨日は未学習 | 1日 | 今日から再スタート |
| 今日未学習、昨日は学習済み | 1日 | 昨日までのカウント（まだ途切れていない） |
| 今日未学習、昨日も未学習 | 0日 | ストリーク途切れ |
| 学習記録が一切ない | 0日 | 初期状態 |

#### 補足ルール

| ルール | 定義 |
|--------|------|
| **1日の境界** | 端末のローカル時間で0:00〜23:59を1日とする |
| **学習の定義** | その日に合計1分以上の学習記録があれば「学習した」とみなす |
| **学習記録の条件** | タイマー完了時に「保存します」を選択した場合のみ記録される（途中キャンセルは記録されない） |
| **深夜0時またぎ** | 23:50開始→0:10終了の場合、開始時刻の日（前日）にカウント |
| **目標横断** | 全ての目標を合算してカウント（目標Aでも目標Bでも学習すればOK） |
| **削除された目標** | 削除した目標の過去の学習記録もカウントに含める |
| **ストリーク途切れ** | 端末の日付が変わった時点で、前日に学習記録がなければ0日にリセット |

---

### 2.2 ミニヒートマップ（直近7日間表示）

#### 定義
直近7日間の学習状況を7つのドットで表示する。

#### 表示ルール

| 日付 | 学習状況 | 表示 |
|------|---------|------|
| 過去の日 | 学習あり | 🟩 緑のドット |
| 過去の日 | 学習なし | ▪️ グレーのドット |
| 今日 | 学習あり | 🟢 濃い緑のドット |
| 今日 | 学習なし | ○ 青い枠線のみ（中は空白） |

#### 並び順
左から右へ: 6日前 → 5日前 → ... → 昨日 → 今日

```
例: 今日が12/23の場合
12/17  12/18  12/19  12/20  12/21  12/22  12/23
  ▪️     🟩     🟩     🟩     🟩     🟩     ○
                                        ↑今日（未学習）
```

---

### 2.3 ストリークカード

#### 表示内容

```
┌─────────────────────────────────────┐
│ 🔥 5日連続学習中！                  │
│                                     │
│ ▪️ 🟩 🟩 🟩 🟩 🟩 ○                  │
│                                     │
│              詳細を見る ▶           │
└─────────────────────────────────────┘
```

#### メッセージルール

| ストリーク数 | メッセージ |
|-------------|-----------|
| 0日 | 「今日から始めよう！」 |
| 1日 | 「1日連続学習中！」 |
| 2日以上 | 「{N}日連続学習中！」 |
| 7日達成 | 「🎉 1週間達成！」（特別表示） |
| 30日達成 | 「🏆 1ヶ月達成！」（特別表示） |

#### インタラクション

| アクション | 動作 |
|-----------|------|
| カードタップ | 統計詳細画面へ遷移（Phase 2で実装予定。Phase 1では何もしない） |

---

### 2.4 配置場所

**ホーム画面**の以下の位置に配置:

```
┌─────────────────────────────────────┐
│ 🌙 こんばんは                       │  ← 挨拶セクション
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔥 5日連続学習中！           │   │  ← ★ストリークカード（新規追加）
│  │ ▪️🟩🟩🟩🟩🟩○                 │   │
│  │              詳細を見る ▶    │   │
│  └─────────────────────────────┘   │
│                                     │
│ マイ目標                            │  ← 既存セクション
│ ┌─────────────────────────────────┐│
│ │ 🎯 英語学習              🔥 5  ││
│ └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

---

## 3. データ仕様

### 3.1 使用テーブル

**既存テーブル**: `study_daily_logs`

| カラム | 型 | 用途 |
|--------|-----|------|
| `id` | TEXT | 学習ログID |
| `goal_id` | TEXT | 目標ID |
| `study_date` | TEXT | 学習日（YYYY-MM-DD形式） |
| `total_seconds` | INTEGER | 学習時間（秒） |
| `created_at` | TEXT | 作成日時 |

### 3.2 ストリーク計算に必要なデータ

| データ | 取得方法 |
|--------|----------|
| 直近7日間の学習日リスト | `study_date` を日付でグループ化し、合計60秒以上の日を抽出 |
| 連続学習日数 | 今日/昨日から遡って連続した学習日をカウント |

### 3.3 計算ロジック（SQL例）

```sql
-- 直近7日間で学習した日を取得
SELECT DATE(study_date) as study_day, SUM(total_seconds) as total
FROM study_daily_logs
WHERE DATE(study_date) >= DATE('now', '-6 days')
GROUP BY DATE(study_date)
HAVING SUM(total_seconds) >= 60;  -- 1分以上
```

### 3.4 新規テーブル/カラム

**不要** - 既存テーブルのみで計算可能

※将来「最長ストリーク記録」を保存する場合は、別途テーブル追加を検討

---

## 4. UI詳細仕様

### 4.1 ストリークカード

既存の `GoalCard` と統一感のあるデザインを使用。

#### カードスタイル
| 項目 | 値 | 定数 |
|------|-----|------|
| 背景色 | `#FFFFFF` | `ColorConsts.cardBackground` |
| 角丸 | 20px | 直接指定（GoalCardと同じ） |
| 影 | elevation 2.0 | `SpacingConsts.elevationSm` |
| 内側パディング | 24px | `SpacingConsts.l` |
| 外側マージン（横） | 24px | `SpacingConsts.l` |
| 外側マージン（縦） | 8px | `SpacingConsts.s` |

#### テキストスタイル
| 要素 | スタイル | 定数 |
|------|---------|------|
| メインメッセージ（例: 「5日連続学習中！」） | 18px, SemiBold | `TextConsts.bodyLarge` + `FontWeight.w600` |
| 「詳細を見る」リンク | 14px, Medium | `TextConsts.bodySmall` + `FontWeight.w500` |

#### カラー
| 要素 | 色 | 定数 |
|------|-----|------|
| 🔥アイコン | `#F59E0B` | `ColorConsts.warning` |
| メインテキスト | `#111827` | `ColorConsts.textPrimary` |
| 「詳細を見る」テキスト | `#6B7280` | `ColorConsts.textSecondary` |
| 「詳細を見る」矢印 | `#6B7280` | `ColorConsts.textSecondary` |

### 4.2 ミニヒートマップ（ドット）

#### ドットスタイル
| 項目 | 値 |
|------|-----|
| ドットサイズ | 28px × 28px |
| ドット間隔 | 8px（`SpacingConsts.sm`） |
| 角丸 | 6px |

#### ドットの色
| 状態 | 色 | 定数 |
|------|-----|------|
| 過去の日・学習あり | `#10B981` | `ColorConsts.success` |
| 過去の日・学習なし | `#E5E7EB` | `ColorConsts.disabled` |
| 今日・学習あり | `#059669`（濃い緑） | 新規定数 `StreakConsts.todayStudiedColor` |
| 今日・学習なし | 枠線のみ `#3B82F6` | `ColorConsts.primary`（枠線2px、塗りなし） |

### 4.3 レイアウト構成

```
┌────────────────────────────────────────────┐
│ [24px上パディング]                          │
│                                            │
│  🔥 5日連続学習中！                         │  ← Row: アイコン + テキスト
│                                            │
│ [12px間隔]                                  │
│                                            │
│  ○ ● ● ● ● ● ○                            │  ← Row: 7つのドット（中央寄せ）
│                                            │
│ [12px間隔]                                  │
│                                            │
│                      詳細を見る ▶           │  ← Row: 右寄せ
│                                            │
│ [24px下パディング]                          │
└────────────────────────────────────────────┘
```

---

## 5. ファイル構成

### 5.1 新規作成ファイル

| ファイルパス | 説明 |
|-------------|------|
| `lib/core/widgets/streak_card.dart` | ストリークカードウィジェット |
| `lib/core/widgets/mini_heatmap.dart` | ミニヒートマップウィジェット |
| `lib/core/utils/streak_consts.dart` | ストリーク関連の定数 |
| `test/core/data/local/local_study_daily_logs_datasource_streak_test.dart` | DataSourceのテスト |
| `test/core/widgets/streak_card_test.dart` | ウィジェットのテスト |

### 5.2 修正ファイル

| ファイルパス | 修正内容 |
|-------------|----------|
| `lib/core/data/local/local_study_daily_logs_datasource.dart` | ストリーク計算メソッド追加 |
| `lib/features/home/view_model/home_view_model.dart` | state にストリーク状態追加、取得メソッド追加 |
| `lib/features/home/view/home_screen.dart` | ストリークカード配置 |

---

## 6. アーキテクチャ準拠

### 6.1 MVVMパターン

本プロジェクトのMVVMアーキテクチャに準拠する。

```
View (home_screen.dart)
  ↓ GetBuilder<HomeViewModel> で状態購読
ViewModel (home_view_model.dart)
  ↓ DataSource のメソッド呼び出し
DataSource (local_study_daily_logs_datasource.dart)
  ↓ SQLite クエリ実行
SQLite (study_daily_logs テーブル)
```

### 6.2 GetX の使い方

**ViewModel:**
```dart
class HomeViewModel extends GetxController {
  // 状態を保持
  HomeState _state = HomeState();
  HomeState get state => _state;

  // 状態更新時は update() を呼ぶ
  void _updateState(HomeState newState) {
    _state = newState;
    update();
  }
}
```

**View:**
```dart
GetBuilder<HomeViewModel>(
  builder: (viewModel) {
    return StreakCard(
      streakDays: viewModel.state.currentStreak,
      studyDates: viewModel.state.recentStudyDates,
    );
  },
)
```

### 6.3 DataSource メソッド追加

**追加するメソッド:**
```dart
/// 指定期間内の学習日リストを取得（合計1分以上の日のみ）
Future<List<DateTime>> fetchStudyDatesInRange({
  required DateTime startDate,
  required DateTime endDate,
})

/// 現在のストリーク（連続学習日数）を計算
Future<int> calculateCurrentStreak()
```

---

## 7. 既存コードとの統合

### 7.1 HomeState への追加

**ファイル:** `lib/features/home/view_model/home_view_model.dart`

```dart
class HomeState {
  // 既存フィールド
  final List<GoalsModel> goals;
  final Map<String, int> studiedSecondsByGoalId;
  final bool isLoading;

  // 新規追加フィールド
  final int currentStreak;              // 現在の連続学習日数
  final List<DateTime> recentStudyDates; // 直近7日間の学習日リスト

  // コンストラクタ・copyWithも更新
}
```

### 7.2 HomeViewModel への追加

**追加するメソッド:**
```dart
/// ストリークデータを読み込む
Future<void> _loadStreakData() async {
  final datasource = LocalStudyDailyLogsDatasource(database: _database);

  // 直近7日間の学習日を取得
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final endDate = DateTime(now.year, now.month, now.day);
  final studyDates = await datasource.fetchStudyDatesInRange(
    startDate: startDate,
    endDate: endDate,
  );

  // ストリークを計算
  final streak = await datasource.calculateCurrentStreak();

  _state = _state.copyWith(
    currentStreak: streak,
    recentStudyDates: studyDates,
  );
  update();
}
```

**onInit() で呼び出す:**
```dart
@override
void onInit() async {
  super.onInit();
  await _loadGoals();
  await _loadStudiedSeconds();
  await _loadStreakData();  // 追加
}
```

### 7.3 HomeScreen への配置

**ファイル:** `lib/features/home/view/home_screen.dart`

挨拶セクションの下、マイ目標セクションの上に配置:

```dart
// 挨拶セクション
_buildGreetingSection(),

const SizedBox(height: SpacingConsts.m),

// ★ ストリークカード（新規追加）
StreakCard(
  streakDays: viewModel.state.currentStreak,
  studyDates: viewModel.state.recentStudyDates,
  onTap: null, // Phase 2 で統計画面遷移を実装
),

const SizedBox(height: SpacingConsts.m),

// マイ目標セクション
_buildGoalsSection(),
```

---

## 8. エラーハンドリング

### 8.1 DBエラー時

| エラー | 対応 |
|--------|------|
| DBクエリ失敗 | ストリーク0、空の学習日リストを返す（UIは「今日から始めよう！」表示） |
| 例外発生 | AppLoggerでエラーログ出力、デフォルト値で継続 |

### 8.2 実装例

**DataSource:**
```dart
Future<int> calculateCurrentStreak() async {
  try {
    // 計算ロジック
  } catch (e, stackTrace) {
    AppLogger.instance.e('ストリーク計算エラー', e, stackTrace);
    return 0; // デフォルト値
  }
}
```

**ViewModel:**
```dart
Future<void> _loadStreakData() async {
  try {
    // 取得ロジック
  } catch (e, stackTrace) {
    AppLogger.instance.e('ストリークデータ取得エラー', e, stackTrace);
    // エラー時もUIは表示できるようにデフォルト値をセット
    _state = _state.copyWith(
      currentStreak: 0,
      recentStudyDates: [],
    );
    update();
  }
}
```

---

## 9. テストケース

### 9.1 DataSource テスト

| テストケース | 期待値 |
|-------------|--------|
| 学習記録なし | ストリーク = 0 |
| 今日のみ学習（1分以上） | ストリーク = 1 |
| 今日と昨日学習 | ストリーク = 2 |
| 今日未学習、昨日のみ学習 | ストリーク = 1 |
| 今日未学習、昨日も未学習、一昨日学習 | ストリーク = 0 |
| 7日連続学習 | ストリーク = 7 |
| 今日59秒学習（1分未満） | 学習日としてカウントしない |
| 今日30秒+30秒学習（合計1分） | 学習日としてカウントする |

### 9.2 ウィジェットテスト

| テストケース | 期待値 |
|-------------|--------|
| ストリーク0日 | 「今日から始めよう！」表示 |
| ストリーク1日 | 「1日連続学習中！」表示 |
| ストリーク5日 | 「5日連続学習中！」表示 |
| ストリーク7日 | 「🎉 1週間達成！」表示 |
| ストリーク30日 | 「🏆 1ヶ月達成！」表示 |
| ミニヒートマップ: 今日学習済み | 今日のドットが濃い緑 |
| ミニヒートマップ: 今日未学習 | 今日のドットが青枠線のみ |

### 9.3 統合テスト

| テストケース | 期待値 |
|-------------|--------|
| ホーム画面表示時 | ストリークカードが表示される |
| タイマー完了後にホームに戻る | ストリークが更新される |

---

## 10. 非機能要件

### パフォーマンス
- ホーム画面表示時に500ms以内でストリーク計算完了
- ローカルDB（SQLite）のみで計算（ネットワーク不要）

### データ更新タイミング
- ホーム画面を開いた時
- タイマー完了後にホーム画面に戻った時

---

## 11. 将来の拡張（今回スコープ外）

- 統計詳細画面（月間カレンダー、累計時間など）
- 目標別ストリーク
- 最長ストリーク記録
- ストリーク達成通知

---

## 12. 開発フロー

### 12.1 TDD（テスト駆動開発）で実装すること

以下の順序で開発を行う:

```
1. テストコードを先に書く
   ↓
2. テストが失敗することを確認（Red）
   ↓
3. テストが通る最小限の実装を行う（Green）
   ↓
4. リファクタリング（Refactor）
   ↓
5. 次のテストへ
```

### 12.2 要件が曖昧な場合

**テストコードを書いていて、要件が曖昧・不明確な箇所があった場合は、実装を進めずに必ず質問すること。**

例:
- 「○○の場合、どのような動作が期待されますか？」
- 「△△のエッジケースはどう扱いますか？」
- 「この仕様の解釈は □□ で合っていますか？」

**自己判断で実装を進めないこと。**

### 12.3 実装順序

| 順番 | 作業 | 詳細 |
|------|------|------|
| 1 | ブランチ作成 | `git checkout -b feat/streak-card` |
| 2 | DataSourceテスト作成 | `test/core/data/local/local_study_daily_logs_datasource_streak_test.dart` |
| 3 | DataSource実装 | テストが通るように実装 |
| 4 | ウィジェットテスト作成 | `test/core/widgets/streak_card_test.dart` |
| 5 | ウィジェット実装 | テストが通るように実装 |
| 6 | HomeViewModel修正 | ストリーク状態追加 |
| 7 | HomeScreen修正 | ストリークカード配置 |
| 8 | 全テスト実行 | `flutter test` |
| 9 | ビルド確認 | 下記コマンド実行 |
| 10 | PR作成 | 全て成功後にPR作成 |

### 12.4 PR作成前の必須チェック

**以下のコマンドが全て成功していることを確認してからPRを作成する:**

```bash
# 1. 静的解析
flutter analyze

# 2. 全テスト実行
flutter test

# 3. iOSビルド
flutter build ipa --debug

# 4. Androidビルド
flutter build apk --debug
```

**全て成功しない場合はPRを作成しないこと。**

---

## 13. 受け入れ条件

### 機能要件
- [ ] ホーム画面にストリークカードが表示される
- [ ] 正しい連続学習日数が表示される
- [ ] 直近7日間のヒートマップが正しく色分けされる
- [ ] 学習記録がない場合は「今日から始めよう！」と表示される
- [ ] タイマー完了後、ストリークが更新される

### 品質要件（PR作成前に必須）
- [ ] `flutter analyze` でエラーなし
- [ ] `flutter test` で全テストパス
- [ ] `flutter build ipa --debug` でビルド成功
- [ ] `flutter build apk --debug` でビルド成功

### テスト要件
- [ ] DataSourceのユニットテストが存在し、全てパス
- [ ] ウィジェットのユニットテストが存在し、全てパス
- [ ] テストはTDDで先に書かれていること
