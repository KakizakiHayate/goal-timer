-- Goal Timer App - Supabase Database Schema
-- 認証機能と連携したデータベース設計

-- ===========================================
-- 1. 拡張機能の有効化
-- ===========================================

-- UUID生成用の拡張機能を有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Row Level Security用のauthスキーマを使用可能にする
-- (Supabaseでは標準で利用可能)

-- ===========================================
-- 2. usersテーブル (ユーザープロファイル)
-- ===========================================

CREATE TABLE IF NOT EXISTS public.users (
    -- 主キー (auth.usersのidと同じ値を使用)
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- ユーザーのメールアドレス (auth.usersから参照、表示用)
    email TEXT,
    
    -- ユーザーの表示名
    display_name TEXT,
    
    -- アカウント作成日時
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 最終更新日時 (プロファイル更新時)
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 最終ログイン日時
    last_login TIMESTAMPTZ,
    
    -- 同期更新時刻 (オフライン同期用)
    sync_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================================
-- 3. goalsテーブル (目標管理)
-- ===========================================

CREATE TABLE IF NOT EXISTS public.goals (
    -- 主キー
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- ユーザーID (外部キー)
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- 目標名
    title TEXT NOT NULL,
    
    -- 目標の詳細説明
    description TEXT DEFAULT '',
    
    -- 達成期限
    deadline DATE,
    
    -- 完了フラグ
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ネガティブ回避メッセージ
    avoid_message TEXT NOT NULL DEFAULT '',
    
    -- 目標達成に必要な時間（分単位）
    target_minutes INTEGER NOT NULL DEFAULT 0,
    
    -- 実際に使った時間（分単位）
    spent_minutes INTEGER NOT NULL DEFAULT 0,
    
    -- 最終更新日時
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 同期更新時刻
    sync_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================================
-- 4. daily_study_logsテーブル (日次学習記録)
-- ===========================================

CREATE TABLE IF NOT EXISTS public.daily_study_logs (
    -- 主キー
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 目標ID (外部キー)
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    
    -- 記録日付
    date DATE NOT NULL,
    
    -- 学習時間（分単位）
    minutes INTEGER NOT NULL DEFAULT 0,
    
    -- 最終更新日時
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 同期更新時刻
    sync_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 同一目標・同一日付の重複を防ぐ一意制約
    UNIQUE(goal_id, date)
);

-- ===========================================
-- 5. インデックスの作成
-- ===========================================

-- goalsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_is_completed ON public.goals(is_completed);
CREATE INDEX IF NOT EXISTS idx_goals_deadline ON public.goals(deadline);
CREATE INDEX IF NOT EXISTS idx_goals_sync_updated_at ON public.goals(sync_updated_at);

-- daily_study_logsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_daily_study_logs_goal_id ON public.daily_study_logs(goal_id);
CREATE INDEX IF NOT EXISTS idx_daily_study_logs_date ON public.daily_study_logs(date);
CREATE INDEX IF NOT EXISTS idx_daily_study_logs_sync_updated_at ON public.daily_study_logs(sync_updated_at);

-- usersテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_sync_updated_at ON public.users(sync_updated_at);

-- ===========================================
-- 6. トリガー関数 (updated_atとsync_updated_atの自動更新)
-- ===========================================

-- updated_atを自動更新するトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.sync_updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 各テーブルにトリガーを設定
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_goals_updated_at ON public.goals;
CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON public.goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_study_logs_updated_at ON public.daily_study_logs;
CREATE TRIGGER update_daily_study_logs_updated_at
    BEFORE UPDATE ON public.daily_study_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- 7. Row Level Security (RLS) の設定
-- ===========================================

-- 各テーブルでRLSを有効化
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_study_logs ENABLE ROW LEVEL SECURITY;

-- usersテーブルのRLSポリシー
-- 自分のプロファイルのみアクセス可能
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- goalsテーブルのRLSポリシー
-- 自分の目標のみアクセス可能
DROP POLICY IF EXISTS "Users can view own goals" ON public.goals;
CREATE POLICY "Users can view own goals" ON public.goals
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own goals" ON public.goals;
CREATE POLICY "Users can insert own goals" ON public.goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own goals" ON public.goals;
CREATE POLICY "Users can update own goals" ON public.goals
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own goals" ON public.goals;
CREATE POLICY "Users can delete own goals" ON public.goals
    FOR DELETE USING (auth.uid() = user_id);

-- daily_study_logsテーブルのRLSポリシー
-- 自分の目標に関連する記録のみアクセス可能
DROP POLICY IF EXISTS "Users can view own study logs" ON public.daily_study_logs;
CREATE POLICY "Users can view own study logs" ON public.daily_study_logs
    FOR SELECT USING (
        auth.uid() = (SELECT user_id FROM public.goals WHERE id = goal_id)
    );

DROP POLICY IF EXISTS "Users can insert own study logs" ON public.daily_study_logs;
CREATE POLICY "Users can insert own study logs" ON public.daily_study_logs
    FOR INSERT WITH CHECK (
        auth.uid() = (SELECT user_id FROM public.goals WHERE id = goal_id)
    );

DROP POLICY IF EXISTS "Users can update own study logs" ON public.daily_study_logs;
CREATE POLICY "Users can update own study logs" ON public.daily_study_logs
    FOR UPDATE USING (
        auth.uid() = (SELECT user_id FROM public.goals WHERE id = goal_id)
    );

DROP POLICY IF EXISTS "Users can delete own study logs" ON public.daily_study_logs;
CREATE POLICY "Users can delete own study logs" ON public.daily_study_logs
    FOR DELETE USING (
        auth.uid() = (SELECT user_id FROM public.goals WHERE id = goal_id)
    );

-- ===========================================
-- 8. Real-time subscriptions (リアルタイム更新)
-- ===========================================

-- テーブルのReal-time機能を有効化
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.goals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_study_logs;

-- ===========================================
-- 9. 関数: 新規ユーザー作成時の自動プロファイル作成
-- ===========================================

-- 認証時に自動でプロファイルを作成する関数
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, display_name, created_at, updated_at, last_login)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
        NEW.created_at,
        NEW.created_at,
        NEW.created_at
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- auth.users に新規ユーザーが追加された時にトリガーを実行
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ===========================================
-- 10. 関数: ユーザーのログイン時刻更新
-- ===========================================

-- ログイン時刻を更新する関数
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    -- セッションが作成された時のみ実行（ログイン時）
    IF TG_OP = 'INSERT' AND NEW.user_id IS NOT NULL THEN
        UPDATE public.users 
        SET last_login = NOW() 
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- auth.sessions テーブルにトリガーを設定
DROP TRIGGER IF EXISTS on_auth_session_created ON auth.sessions;
CREATE TRIGGER on_auth_session_created
    AFTER INSERT ON auth.sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_last_login();

-- ===========================================
-- 11. サンプルデータ（開発用）
-- ===========================================

-- 開発環境でのサンプルデータ投入例
-- COMMENT: 本番環境では以下のサンプルデータは使用しない

/*
-- サンプルユーザー（実際の認証は auth.users で管理）
INSERT INTO public.users (id, email, display_name, created_at, updated_at) VALUES
(
    '550e8400-e29b-41d4-a716-446655440000'::UUID,
    'sample@example.com',
    'サンプルユーザー',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- サンプル目標
INSERT INTO public.goals (id, user_id, title, description, deadline, avoid_message, total_target_hours) VALUES
(
    uuid_generate_v4(),
    '550e8400-e29b-41d4-a716-446655440000'::UUID,
    'Flutter開発スキル向上',
    '毎日コーディング練習をして、アプリ開発能力を高める',
    CURRENT_DATE + INTERVAL '30 days',
    'スキルアップが遅れて転職活動で不利になる',
    30
) ON CONFLICT DO NOTHING;
*/

-- ===========================================
-- 12. パフォーマンス最適化のためのビュー（オプション）
-- ===========================================

-- 目標と進捗状況を統合して表示するビュー
CREATE OR REPLACE VIEW public.goals_with_progress AS
SELECT 
    g.id,
    g.user_id,
    g.title,
    g.description,
    g.deadline,
    g.is_completed,
    g.avoid_message,
    g.total_target_hours,
    g.spent_minutes,
    g.updated_at,
    -- 進捗率の計算（分を時間に変換して計算）
    CASE 
        WHEN g.total_target_hours > 0 
        THEN ROUND((g.spent_minutes::NUMERIC / 60.0 / g.total_target_hours) * 100, 2)
        ELSE 0 
    END AS progress_percentage,
    -- 残り時間（分単位）
    GREATEST(0, (g.total_target_hours * 60) - g.spent_minutes) AS remaining_minutes,
    -- 今日の学習時間
    COALESCE(today_logs.today_minutes, 0) AS today_minutes,
    -- 継続日数
    streak.consecutive_days
FROM public.goals g
LEFT JOIN (
    -- 今日の学習時間を取得
    SELECT 
        goal_id,
        SUM(minutes) AS today_minutes
    FROM public.daily_study_logs 
    WHERE date = CURRENT_DATE
    GROUP BY goal_id
) today_logs ON g.id = today_logs.goal_id
LEFT JOIN (
    -- 継続日数を計算（簡易版）
    SELECT 
        goal_id,
        COUNT(*) AS consecutive_days
    FROM public.daily_study_logs
    WHERE minutes > 0
    GROUP BY goal_id
) streak ON g.id = streak.goal_id;

-- ===========================================
-- 完了
-- ===========================================

-- スキーマ作成完了のログ
SELECT 'Goal Timer Database Schema Created Successfully' AS status; 