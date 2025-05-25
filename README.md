# goal_timer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 環境変数の設定

このプロジェクトでは環境変数を使用して設定を管理しています。以下の手順に従って設定してください：

1. プロジェクトルートに `.env` ファイルを作成します（`.env.example` をコピーして使用可能）
2. 以下の環境変数を設定します：

```
# Supabase設定
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# アプリケーション設定
APP_ENV=development  # または production

# その他の設定
DEBUG_MODE=true  # または false
```

**注意**: `.env` ファイルはバージョン管理対象外です。秘密鍵などの機密情報を含む場合があるため、gitignoreに追加されています。
