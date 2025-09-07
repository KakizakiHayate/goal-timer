import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goal_timer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('設定画面 統合テスト - 不要機能削除後', () {
    // 共通のセットアップメソッド
    Future<void> navigateToSettings(WidgetTester tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 設定画面に遷移（実際のナビゲーション方法に応じて調整）
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }
    }

    // 削除対象機能の確認メソッド
    void verifyRemovedFeatures() {
      expect(find.text('通知設定'), findsNothing);
      expect(find.text('通知を有効にする'), findsNothing);
      expect(find.text('サウンド'), findsNothing);
      expect(find.text('バイブレーション'), findsNothing);
      expect(find.text('テーマ'), findsNothing);
      expect(find.text('週の開始日'), findsNothing);
      expect(find.text('ヘルプ・FAQ'), findsNothing);
    }

    // 残存機能の確認メソッド
    void verifyRemainingFeatures() {
      expect(find.text('ユーザー名'), findsAtLeastNWidgets(1));
      expect(find.text('プレミアム'), findsAtLeastNWidgets(1));
      expect(find.text('デフォルトタイマー時間'), findsOneWidget);
      expect(find.text('お問い合わせ'), findsOneWidget);
      expect(find.text('サインアウト'), findsOneWidget);
    }

    testWidgets('設定画面への遷移と削除機能の確認', (tester) async {
      await navigateToSettings(tester);

      // 設定画面が表示されることを確認
      expect(find.text('設定'), findsOneWidget);

      // 削除対象の機能が表示されていないことを確認
      verifyRemovedFeatures();

      // 残存機能が正常に表示されることを確認
      verifyRemainingFeatures();

      // AppBarに戻るボタンが存在しないことを確認
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('残存機能のタップ動作確認', (tester) async {
      await navigateToSettings(tester);

      // ユーザー名項目をタップ（プロフィール項目の代替）
      final usernameTile = find.text('ユーザー名');
      if (usernameTile.evaluate().isNotEmpty) {
        await tester.tap(usernameTile);
        await tester.pumpAndSettle();
        
        // タップ後の状態を確認（設定画面が維持されることを確認）
        expect(find.text('設定'), findsOneWidget);
      }

      // デフォルトタイマー時間設定をタップ
      final timerTile = find.text('デフォルトタイマー時間');
      if (timerTile.evaluate().isNotEmpty) {
        await tester.tap(timerTile);
        await tester.pumpAndSettle();
        
        // タップ後の状態を確認
        expect(find.text('設定'), findsOneWidget);
      }
    });

    testWidgets('画面スクロール動作確認', (tester) async {
      await navigateToSettings(tester);

      // スクロール動作をテスト
      final scrollView = find.byType(Scrollable).first;
      
      // 下方向にスクロール
      await tester.fling(scrollView, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      // 上方向にスクロール
      await tester.fling(scrollView, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // スクロール後も必要な要素が表示されることを確認
      verifyRemainingFeatures();
    });

    testWidgets('ナビゲーション整合性確認', (tester) async {
      await navigateToSettings(tester);

      // 設定画面が表示されることを確認
      expect(find.text('設定'), findsOneWidget);
      
      // 削除機能が確実に表示されていないことを再確認
      verifyRemovedFeatures();

      // システムの戻る操作をシミュレート
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 設定画面から離れたことを確認（設定画面のタイトルが見つからない）
      expect(find.text('設定'), findsNothing);
    });
  });
}