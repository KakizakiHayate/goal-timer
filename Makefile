.PHONY: help lint lint-fix test test-coverage build-ios build-android build-aab run get clean upgrade check ci pod rebuild

# デフォルトターゲット
.DEFAULT_GOAL := help

# ===== Lintチェック =====

## dart analyze + custom_lint を一括実行
lint:
	@echo "🔍 Running dart analyze..."
	@dart analyze
	@echo ""
	@echo "🔍 Running custom_lint..."
	@dart run custom_lint

## 自動修正可能なものを修正
lint-fix:
	@echo "🔧 Running dart fix..."
	@dart fix --apply
	@echo ""
	@echo "🔍 Running lint check after fix..."
	@$(MAKE) lint

# ===== テスト =====

## ユニットテスト実行
test:
	@echo "🧪 Running tests..."
	@flutter test

## カバレッジ付きテスト実行
test-coverage:
	@echo "🧪 Running tests with coverage..."
	@flutter test --coverage
	@echo ""
	@echo "📊 Coverage report generated at coverage/lcov.info"

# ===== ビルド =====

## iOS リリースビルド
build-ios:
	@echo "🍎 Building iOS release..."
	@flutter build ios --release

## Android APKビルド
build-android:
	@echo "🤖 Building Android APK..."
	@flutter build apk --release

## Android App Bundle
build-aab:
	@echo "🤖 Building Android App Bundle..."
	@flutter build appbundle --release

# ===== 開発支援 =====

## デバッグ実行
run:
	@echo "🚀 Running app in debug mode..."
	@flutter run

## flutter pub get
get:
	@echo "📦 Getting dependencies..."
	@flutter pub get

## キャッシュクリア + pub get
clean:
	@echo "🧹 Cleaning project..."
	@flutter clean
	@echo ""
	@echo "📦 Getting dependencies..."
	@flutter pub get

## パッケージアップグレード
upgrade:
	@echo "⬆️  Upgrading packages..."
	@flutter pub upgrade

## CocoaPods インストール
pod:
	@echo "🍫 Installing CocoaPods dependencies..."
	@cd ios && pod install

## フルリビルド（clean + get + pod + build_runner）
rebuild:
	@echo "🔄 Full rebuild..."
	@$(MAKE) clean
	@$(MAKE) pod
	@echo ""
	@echo "🔧 Running build_runner..."
	@flutter pub run build_runner build --delete-conflicting-outputs

# ===== 品質チェック =====

## lint + test を一括実行
check:
	@echo "✅ Running full check..."
	@$(MAKE) lint
	@echo ""
	@$(MAKE) test

## CI用全チェック（lint + test + build）
ci:
	@echo "🔄 Running CI pipeline..."
	@$(MAKE) lint
	@echo ""
	@$(MAKE) test
	@echo ""
	@echo "📦 Building Android APK..."
	@flutter build apk --release
	@echo ""
	@echo "✅ CI pipeline completed!"

# ===== ヘルプ =====

## コマンド一覧表示
help:
	@echo "📖 Available commands:"
	@echo ""
	@echo "  Lint:"
	@echo "    make lint          - Run dart analyze + custom_lint"
	@echo "    make lint-fix      - Auto-fix lint issues"
	@echo ""
	@echo "  Test:"
	@echo "    make test          - Run unit tests"
	@echo "    make test-coverage - Run tests with coverage"
	@echo ""
	@echo "  Build:"
	@echo "    make build-ios     - Build iOS release"
	@echo "    make build-android - Build Android APK"
	@echo "    make build-aab     - Build Android App Bundle"
	@echo ""
	@echo "  Development:"
	@echo "    make run           - Run app in debug mode"
	@echo "    make get           - Get dependencies"
	@echo "    make clean         - Clean and get dependencies"
	@echo "    make upgrade       - Upgrade packages"
	@echo "    make pod           - Install CocoaPods"
	@echo "    make rebuild       - Full rebuild (clean + get + pod + build_runner)"
	@echo ""
	@echo "  Quality:"
	@echo "    make check         - Run lint + test"
	@echo "    make ci            - Run full CI pipeline"
