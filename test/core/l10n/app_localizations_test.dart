import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    // L10N-001: flutter gen-l10nでコード生成が成功する
    // （このテストはビルド時に確認されるため、ファイルの存在を確認）
    test('L10N-001: AppLocalizations class exists', () {
      expect(AppLocalizations, isNotNull);
      expect(AppLocalizations.delegate, isNotNull);
    });

    // L10N-002: 日本語ロケール(ja)でAppLocalizationsが取得できる
    testWidgets('L10N-002: Japanese locale returns AppLocalizations instance',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isNotNull);
    });

    // L10N-003: 英語ロケール(en)でAppLocalizationsが取得できる
    testWidgets('L10N-003: English locale returns AppLocalizations instance',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isNotNull);
    });

    // L10N-004: サポート外ロケール(zh)で英語にフォールバックする
    // Flutterのデフォルトのロケール解決メカニズムにより、
    // サポートされていないロケールはsupportedLocalesの最初の言語（en）にフォールバック
    testWidgets(
        'L10N-004: Unsupported locale (zh) falls back to English',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // フォールバックにより英語のテキストが返る
      expect(l10n, isNotNull);
      expect(l10n!.defaultGuestName, 'Guest');
    });

    // L10N-005: 日本語ロケールで日本語テキストが返る
    testWidgets('L10N-005: Japanese locale returns Japanese text',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.appName, 'Goal Timer');
      expect(l10n!.defaultGuestName, 'ゲスト');
      expect(l10n!.commonBtnCancel, 'キャンセル');
      expect(l10n!.commonBtnSave, '保存');
    });

    // L10N-006: 英語ロケールで英語テキストが返る
    testWidgets('L10N-006: English locale returns English text',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.appName, 'Goal Timer');
      expect(l10n!.defaultGuestName, 'Guest');
      expect(l10n!.commonBtnCancel, 'Cancel');
      expect(l10n!.commonBtnSave, 'Save');
    });

    // L10N-007: supportedLocalesにja, enが含まれる
    test('L10N-007: supportedLocales contains ja and en', () {
      final supportedLocales = AppLocalizations.supportedLocales;

      expect(supportedLocales, contains(const Locale('en')));
      expect(supportedLocales, contains(const Locale('ja')));
    });

    // L10N-008: localizationsDelegatesが正しく設定される
    test('L10N-008: localizationsDelegates are correctly configured', () {
      expect(AppLocalizations.delegate, isNotNull);
      expect(AppLocalizations.localizationsDelegates, isNotEmpty);
      // AppLocalizations.localizationsDelegatesには4つのデリゲートが含まれる
      // (AppLocalizations.delegate, GlobalMaterial, GlobalCupertino, GlobalWidgets)
      expect(AppLocalizations.localizationsDelegates.length, 4);
    });
  });

  group('AppLocalizations - Time Format', () {
    testWidgets('Japanese time format with hours and minutes',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.timeFormatHoursMinutes(1, 30), '1時間30分');
      expect(l10n!.timeFormatMinutes(30), '30分');
    });

    testWidgets('English time format with hours and minutes',
        (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.timeFormatHoursMinutes(1, 30), '1h 30m');
      expect(l10n!.timeFormatMinutes(30), '30m');
    });
  });

  group('AppLocalizations - Plural', () {
    testWidgets('Japanese days suffix (no plural)', (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.daysSuffix(1), '1日');
      expect(l10n!.daysSuffix(5), '5日');
    });

    testWidgets('English days suffix (with plural)', (WidgetTester tester) async {
      late AppLocalizations? l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n!.daysSuffix(1), '1 day');
      expect(l10n!.daysSuffix(5), '5 days');
    });
  });
}
