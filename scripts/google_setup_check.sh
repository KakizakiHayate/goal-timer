#!/bin/bash

echo "=== Googleログイン設定診断 ==="
echo

# 1. パッケージ名確認
echo "📦 アプリケーション設定:"
PACKAGE_NAME=$(grep 'applicationId' android/app/build.gradle | sed 's/.*= *"//' | sed 's/".*//')
echo "   パッケージ名: $PACKAGE_NAME"
echo

# 2. SHA-1証明書確認
echo "🔑 SHA-1証明書:"
DEBUG_SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | awk '{print $2}')
if [ -n "$DEBUG_SHA1" ]; then
    echo "   Debug SHA-1: $DEBUG_SHA1"
else
    echo "   ❌ Debug証明書が見つかりません"
fi
echo

# 3. google-services.json確認
echo "🔧 google-services.json設定:"
if [ -f "android/app/google-services.json" ]; then
    echo "   ✅ ファイル存在"
    PROJECT_ID=$(grep '"project_id"' android/app/google-services.json | sed 's/.*": *"//' | sed 's/".*//')
    echo "   Project ID: $PROJECT_ID"
    
    # パッケージ名確認
    JSON_PACKAGE=$(grep '"package_name"' android/app/google-services.json | head -1 | sed 's/.*": *"//' | sed 's/".*//')
    echo "   JSON内パッケージ名: $JSON_PACKAGE"
    
    if [ "$PACKAGE_NAME" = "$JSON_PACKAGE" ]; then
        echo "   ✅ パッケージ名一致"
    else
        echo "   ❌ パッケージ名不一致"
    fi
    
    # 証明書ハッシュ確認
    CERT_HASH=$(grep '"certificate_hash"' android/app/google-services.json | sed 's/.*": *"//' | sed 's/".*//')
    echo "   JSON内証明書ハッシュ: $CERT_HASH"
    
    # SHA-1の小文字版（コロンなし）と比較
    DEBUG_SHA1_CLEAN=$(echo $DEBUG_SHA1 | tr -d ':' | tr '[:upper:]' '[:lower:]')
    if [ "$CERT_HASH" = "$DEBUG_SHA1_CLEAN" ]; then
        echo "   ✅ 証明書ハッシュ一致"
    else
        echo "   ❌ 証明書ハッシュ不一致"
        echo "   期待値: $DEBUG_SHA1_CLEAN"
        echo "   実際値: $CERT_HASH"
    fi
else
    echo "   ❌ google-services.jsonが見つかりません"
fi
echo

# 4. 推奨解決策
echo "🔧 解決手順:"
echo "1. Firebase Console (https://console.firebase.google.com) で以下を確認:"
echo "   - プロジェクト: $PROJECT_ID"
echo "   - SHA-1証明書: $DEBUG_SHA1 が登録されているか"
echo "   - パッケージ名: $PACKAGE_NAME が正しく設定されているか"
echo
echo "2. 設定修正後は必ず最新のgoogle-services.jsonをダウンロード"
echo
echo "3. アプリを完全に削除してから再インストール:"
echo "   flutter clean && flutter run"
echo

# 5. Google Play Console設定確認
echo "📱 Google Play Console確認事項:"
echo "1. 内部テストトラックが設定されているか"
echo "2. テスターアカウントが登録されているか"
echo "3. OAuth同意画面が設定されているか"
echo