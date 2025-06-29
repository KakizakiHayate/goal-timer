#!/bin/bash

echo "=== Debug SHA-1 証明書情報 ==="
echo

# デバッグ証明書のSHA-1を取得
DEBUG_SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | awk '{print $2}')

if [ -n "$DEBUG_SHA1" ]; then
    echo "🔑 Debug SHA-1: $DEBUG_SHA1"
    echo
    echo "📋 Firebase Console設定手順:"
    echo "1. Firebase Console (https://console.firebase.google.com) にアクセス"
    echo "2. プロジェクト 'goal-timer-dev' を選択"
    echo "3. プロジェクト設定 → 全般 → マイアプリ"
    echo "4. Android アプリを選択"
    echo "5. SHA証明書フィンガープリント に以下を追加:"
    echo "   $DEBUG_SHA1"
    echo
    echo "📱 Release SHA-1も必要な場合は、リリース用keystoreから取得してください"
    echo
else
    echo "❌ デバッグ証明書が見つかりません"
    echo "以下のコマンドで手動確認してください:"
    echo "keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
fi

echo "=== パッケージ名確認 ==="
echo "📦 現在のパッケージ名: com.example.goal_timer"
echo "   Firebase Consoleでも同じパッケージ名が設定されているか確認してください"
echo