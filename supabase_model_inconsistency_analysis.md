# Supabaseモデル不整合分析

## 問題の概要

現在のFlutter実装とSupabaseスキーマに重大な不整合があります。

## 詳細分析

### 1. 時間単位の不整合
**Supabaseスキーマ**: `minutes INTEGER` (分単位)
**Flutter送信**: `total_seconds: totalSeconds` (秒単位)

### 2. フィールド名の不整合
**Supabaseスキーマ**: `date DATE`
**Flutter送信**: `study_date`

### 3. 存在しないフィールド送信
Flutterが送信しているが、Supabaseテーブルに存在しないフィールド：
- `total_seconds` (スキーマでは`minutes`)
- `created_at` (スキーマには存在しない)
- `is_temp` (ローカル専用、スキーマに存在しない)
- `temp_user_id` (ローカル専用、スキーマに存在しない)

## 修正案

### Option 1: Supabaseスキーマを更新
```sql
-- Supabaseスキーマを修正
ALTER TABLE public.daily_study_logs 
ADD COLUMN total_seconds INTEGER,
ADD COLUMN created_at TIMESTAMPTZ;

-- study_dateフィールドを追加するか、dateをstudy_dateにリネーム

-- 既存のminutesフィールドから変換
UPDATE public.daily_study_logs 
SET total_seconds = minutes * 60;
```

### Option 2: Flutter側のtoMap()を修正
```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'goal_id': goalId,
    'date': date.toIso8601String().split('T')[0], // study_date → date
    'minutes': totalSeconds ~/ 60,                // seconds → minutes変換
    'updated_at': updatedAt?.toIso8601String(),
    'sync_updated_at': syncUpdatedAt?.toIso8601String(),
    // is_temp, temp_user_idは送信しない（ローカル専用）
  };
}
```

### Option 3: 新しいスキーマに移行
最新の要件に合わせてスキーマを再設計：

```sql
CREATE TABLE IF NOT EXISTS public.study_daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    study_date DATE NOT NULL,               -- Flutter側と合わせる
    total_seconds INTEGER NOT NULL DEFAULT 0, -- 秒単位で統一
    created_at TIMESTAMPTZ DEFAULT NOW(),   -- Flutter側で使用
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sync_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(goal_id, study_date)
);
```

## 推奨解決策

**Option 2（Flutter側修正）** を推奨：
1. 既存のSupabaseデータを保護
2. 修正範囲が限定的
3. 即座に適用可能

## 影響範囲

- `SupabaseDailyStudyLogsDatasource`
- `DailyStudyLogModel.toMap()`
- `DailyStudyLogModel.fromMap()`
- テーブル名の統一（`daily_study_logs` vs `study_daily_logs`）




