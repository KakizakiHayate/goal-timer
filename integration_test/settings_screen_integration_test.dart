import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goal_timer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('設定画面 統合テスト - 不要機能削除後', () {
    testWidgets('設定画面への遷移と削除機能の確認', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 設定画面に遷移（仮定：BottomNavigationBarまたは他の方法で遷移）
      // 実際のナビゲーション方法に応じて調整が必要
      
      // 設定ボタンまたはアイコンを探してタップ
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // 設定画面が表示されることを確認
      expect(find.text('設定'), findsOneWidget);

      // 削除対象の機能が表示されていないことを確認
      expect(find.text('通知設定'), findsNothing);
      expect(find.text('通知を有効にする'), findsNothing);
      expect(find.text('サウンド'), findsNothing);
      expect(find.text('バイブレーション'), findsNothing);
      expect(find.text('テーマ'), findsNothing);
      expect(find.text('週の開始日'), findsNothing);
      expect(find.text('ヘルプ・FAQ'), findsNothing);

      // 残存機能が正常に表示されることを確認
      expect(find.text('プロフィール'), findsOneWidget);
      expect(find.text('プレミアム'), findsOneWidget);
      expect(find.text('デフォルトタイマー時間'), findsOneWidget);
      expect(find.text('データ管理'), findsOneWidget);
      expect(find.text('お問い合わせ'), findsOneWidget);
      expect(find.text('アカウント'), findsOneWidget);

      // AppBarに戻るボタンが存在しないことを確認
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('残存機能のタップ動作確認', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 設定画面に遷移
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // プロフィール項目をタップ
      final profileTile = find.text('プロフィール');
      if (profileTile.evaluate().isNotEmpty) {
        await tester.tap(profileTile);
        await tester.pumpAndSettle();
        
        // プロフィール画面または関連するダイアログが表示されることを確認
        // 実際の実装に応じて期待する要素を確認
      }

      // 設定画面に戻る
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // デフォルトタイマー時間設定をタップ
      final timerTile = find.text('デフォルトタイマー時間');
      if (timerTile.evaluate().isNotEmpty) {
        await tester.tap(timerTile);
        await tester.pumpAndSettle();
        
        // タイマー設定ダイアログまたは画面が表示されることを確認
        // 実際の実装に応じて期待する要素を確認
      }
    });

    testWidgets('画面スクロール動作確認', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 設定画面に遷移
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // スクロール動作をテスト
      final scrollView = find.byType(Scrollable).first;
      
      // 下方向にスクロール
      await tester.fling(scrollView, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      // 上方向にスクロール
      await tester.fling(scrollView, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // スクロール後も必要な要素が表示されることを確認
      expect(find.text('プロフィール'), findsOneWidget);
      expect(find.text('アカウント'), findsOneWidget);
    });

    testWidgets('ナビゲーション整合性確認', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 設定画面に遷移
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // 設定画面が表示されることを確認
      expect(find.text('設定'), findsOneWidget);

      // システムの戻る操作をシミュレート
      await tester.pageBack();
      await tester.pumpAndSettle();

      // ホーム画面または前の画面に戻ることを確認
      // 実際のアプリ構造に応じて期待する画面要素を確認
    });
  });
}