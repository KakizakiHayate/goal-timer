# Makefile

.PHONY: all run clean get build pod rebuild analyze

# デフォルトターゲット
rebuild: clean get pod build run

# 個別コマンド
clean:
	flutter clean

get:
	flutter pub get

pod:
	cd ios && pod install && cd ..

build:
	flutter pub run build_runner build --delete-conflicting-outputs

run:
	flutter run

analyze:
	flutter analyze

a: analyze

