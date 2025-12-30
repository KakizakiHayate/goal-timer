# タイマー学習記録保存 - Supabase修正プラン

## 🔍 問題の概要

タイマー学習完了時にSupabaseへの保存が失敗する問題の根本原因と修正プランを策定。

### 発生していたエラー
```
PostgrestException(message: Could not find the 'is_completed' column of 'goals' in the schema cache, code: PGRST204, details: Bad Request, hint: null)
```

## 🧩 根本原因の分析

### 1. **Supabaseスキーマ不一致問題**
FlutterのモデルからSupabaseに送信するフィールドが、実際のSupabaseスキーマに存在しない。

### 2. **設計上の根本的問題**
学習記録時に不要なgoalsテーブル更新を実行している。

## 📋 修正が必要な箇所

### **Priority 1: 緊急修正（エラー解決）**

#### 1.1 DailyStudyLogModel.toMap() 修正
**ファイル**: `lib/core/models/daily_study_logs/daily_study_log_model.dart`
**行**: 171-183

**現在（問題）:**
```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'goal_id': goalId,
    'study_date': date.toIso8601String().split('T')[0],
    'total_seconds': totalSeconds,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'sync_updated_at': syncUpdatedAt?.toIso8601String(),
    'is_temp': isTemp,              // ❌ Supabaseに存在しない
    'temp_user_id': tempUserId,     // ❌ Supabaseに存在しない
  };
}
```

**修正後:**
```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'goal_id': goalId,
    'study_date': date.toIso8601String().split('T')[0],
    'total_seconds': totalSeconds,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'sync_updated_at': syncUpdatedAt?.toIso8601String(),
    // is_temp, temp_user_idはローカル専用のため削除
  };
}
```

#### 1.2 GoalsModel.toMap() 修正
**ファイル**: `lib/core/models/goals/goals_model.dart`
**行**: 158-178

**現在（問題）:**
```dart
Map<String, dynamic> toMap() {
  final map = {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String(),
    'is_completed': isCompleted,        // ❌ Supabaseに存在しない
    'avoid_message': avoidMessage,
    'target_minutes': targetMinutes,
    'spent_minutes': spentMinutes,      // ❌ Supabaseに存在しない
  };
  
  if (updatedAt != null) {
    map['updated_at'] = updatedAt!.toIso8601String();
  }
  
  return map;
}
```

**修正後:**
```dart
Map<String, dynamic> toMap() {
  final map = {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String().split('T')[0], // 日付のみ
    'avoid_message': avoidMessage,
    'target_minutes': targetMinutes,
    // is_completed, spent_minutesは削除
  };

  // ✅ isCompleted → completed_at変換
  if (isCompleted) {
    map['completed_at'] = DateTime.now().toIso8601String();
  }

  if (updatedAt != null) {
    map['updated_at'] = updatedAt!.toIso8601String();
  }

  return map;
}
```

### **Priority 2: 設計修正（不要な処理削除）**

#### 2.1 TimerViewModel._recordStudyTime() 修正
**ファイル**: `lib/features/goal_timer/presentation/viewmodels/timer_view_model.dart`
**行**: 371-382

**修正内容**: goals テーブル更新処理を削除
```dart
// ❌ 削除: 以下のgoals更新処理をコメントアウト
// try {
//   final goalsRepository = _ref.read(hybridGoalsRepositoryProvider);
//   final currentGoal = await goalsRepository.getGoalById(state.goalId!);
//   if (currentGoal != null) {
//     final updatedGoal = currentGoal.copyWith(
//       spentMinutes: currentGoal.spentMinutes + studyMinutes,
//     );
//     await goalsRepository.updateGoal(updatedGoal);
//   }
// } catch (e) {
//   AppLogger.instance.w('目標の累計時間更新に失敗しました（記録は保存済み）: $e');
// }

// ✅ 保持: キャッシュクリアのみ実行
_ref.invalidate(goalDetailListProvider);
```

#### 2.2 TimerScreen._saveStudyTimeManually() 修正
**ファイル**: `lib/features/goal_timer/presentation/screens/timer_screen.dart`
**行**: 1140-1155

**修正内容**: goals テーブル更新処理を削除
```dart
// ❌ 削除: 以下のgoals更新処理をコメントアウト
// try {
//   final goalsRepository = ref.read(hybridGoalsRepositoryProvider);
//   final currentGoal = await goalsRepository.getGoalById(timerState.goalId!);
//   if (currentGoal != null) {
//     final studyMinutes = studyTimeInSeconds ~/ 60;
//     final updatedGoal = currentGoal.copyWith(
//       spentMinutes: currentGoal.spentMinutes + studyMinutes,
//     );
//     await goalsRepository.updateGoal(updatedGoal);
//   }
// } catch (e) {
//   AppLogger.instance.w('目標の累計時間更新に失敗しました（記録は保存済み）: $e');
// }

// ✅ 保持: キャッシュクリアのみ実行
ref.invalidate(goalDetailListProvider);
```

### **Priority 3: 後方互換性確保**

#### 3.1 GoalsModel.fromMap() 修正
**ファイル**: `lib/core/models/goals/goals_model.dart`
**行**: 65-72

**修正内容**: completed_at → isCompleted変換を追加
```dart
// completed_at → isCompleted変換
bool parsedIsCompleted;
final completedAtValue = map['completed_at'];
if (completedAtValue != null) {
  parsedIsCompleted = true; // completed_atに値があれば完了
} else {
  // 後方互換性: 古いis_completedフィールドもサポート
  final isCompletedValue = map['is_completed'];
  if (isCompletedValue is bool) {
    parsedIsCompleted = isCompletedValue;
  } else if (isCompletedValue is String) {
    parsedIsCompleted = isCompletedValue == 'true';
  } else {
    parsedIsCompleted = false;
  }
}
```

### **Priority 4: 表示ロジック改善**

#### 4.1 累計時間の集計計算実装
**新規実装**: study_daily_logsから累計時間を計算する関数

**実装箇所**: 目標詳細画面や統計画面での表示時
```dart
// 例: GoalDetailViewModelで累計時間を計算
Future<int> getTotalStudyMinutes(String goalId) async {
  final logs = await _dailyStudyLogsRepository.getLogsByGoalId(goalId);
  final totalSeconds = logs.fold<int>(0, (sum, log) => sum + log.totalSeconds);
  return totalSeconds ~/ 60; // 分単位で返す
}
```

## 🚀 実装手順

### Step 1: 緊急修正（即座実行）
1. ✅ **DailyStudyLogModel.toMap()修正** - 完了済み
2. **GoalsModel.toMap()修正**
3. **TimerViewModel._recordStudyTime()修正**
4. **TimerScreen._saveStudyTimeManually()修正**

### Step 2: 動作確認
1. タイマー学習完了テスト
2. 手動学習完了テスト  
3. Supabaseデータ保存確認

### Step 3: 後方互換性確保
1. **GoalsModel.fromMap()修正**
2. 既存データの表示確認

### Step 4: 表示ロジック改善
1. 累計時間計算関数実装
2. UI表示の動作確認

## 📊 影響範囲

### **直接影響**
- タイマー学習記録保存機能
- 目標管理機能（累計時間表示）

### **間接影響**
- 統計画面での累計時間表示
- 進捗表示機能

## 🧪 テスト項目

### **必須テスト**
1. **学習記録保存**
   - [ ] 自動タイマー完了時の保存
   - [ ] 手動学習完了時の保存
   - [ ] オフライン時の保存
   - [ ] オンライン同期の確認

2. **データ整合性**
   - [ ] study_daily_logsの正常保存
   - [ ] goalsテーブルの不要更新が削除されたこと
   - [ ] Supabaseエラーが解消されたこと

3. **表示確認**
   - [ ] 目標詳細画面での累計時間表示
   - [ ] 統計画面での集計値表示

### **回帰テスト**
1. **既存機能**
   - [ ] 目標作成・編集・削除
   - [ ] 学習記録の表示
   - [ ] オフライン/オンライン同期

## 🎯 期待される結果

1. **🔥 即座解決**: PostgrestExceptionエラーの解消
2. **📐 設計改善**: 正しいデータフロー（学習記録→study_daily_logsのみ）
3. **🔧 保守性向上**: Supabaseスキーマとの完全互換性
4. **⚡ パフォーマンス**: 不要なgoalsテーブル更新の削除

## 📝 注意事項

1. **データ移行**: 既存のgoals.spent_minutesデータの扱い
2. **後方互換性**: 古いis_completedフィールドへの対応
3. **キャッシュクリア**: 修正後のプロバイダー無効化の確認

---

**作成日**: 2025-09-23
**優先度**: 🔥 Critical - 即座修正必要
**推定工数**: 2-4時間
