#!/usr/bin/env bash
set -e

echo "[Devin] === Maintain dependencies (Flutter) ==="

# Flutter を置くディレクトリ
FLUTTER_DIR="$HOME/flutter"
FLUTTER_REPO="https://github.com/flutter/flutter.git"
FLUTTER_CHANNEL="stable"

# 1. Flutter 本体の準備（なければ clone、あれば pull）
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "[Devin] Flutter not found. Cloning Flutter ($FLUTTER_CHANNEL)..."
  git clone --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_REPO" "$FLUTTER_DIR"
else
  echo "[Devin] Flutter already installed. Updating (git pull)..."
  git -C "$FLUTTER_DIR" pull
fi

# 2. PATH を通す
export PATH="$PATH:$FLUTTER_DIR/bin"
echo "[Devin] Flutter path: $(command -v flutter || echo 'not found')"

# 3. Flutter / Dart プロジェクトなら依存関係を解決
if [ -f "pubspec.yaml" ]; then
  echo "[Devin] pubspec.yaml detected. Running 'flutter pub get'..."
  # Flutter プロジェクトでないケースでも全体が落ちないようにする場合は || true を付けてもOK
  flutter pub get || echo "[Devin] 'flutter pub get' failed, please check manually."
else
  echo "[Devin] No pubspec.yaml in current directory. Skipping 'flutter pub get'."
fi

echo "[Devin] === Maintain dependencies finished ==="
