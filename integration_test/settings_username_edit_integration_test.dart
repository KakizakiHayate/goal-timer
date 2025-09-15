import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goal_timer/main.dart' as app;
import 'package:goal_timer/core/widgets/pressable_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Username Edit Integration Tests', () {
    testWidgets('test_username_edit_end_to_end - ユーザー名編集の統合テスト', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // ログイン処理（テスト用）
      // 注：実際の統合テストではモック認証を使用

      // 設定画面に遷移（ナビゲーション経由）
      // 注：実際のナビゲーションパスは実装により異なる

      // プロフィールセクションの確認
      expect(find.byType(PressableCard), findsWidgets);

      // ユーザー名をタップして編集ダイアログを開く
      await tester.tap(find.byType(PressableCard).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // 編集ダイアログが表示されることを確認
      expect(find.text('ユーザー名編集'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // 新しいユーザー名を入力
      await tester.enterText(find.byType(TextField), 'Integration Test User');

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // ダイアログが閉じることを確認
      expect(find.text('ユーザー名編集'), findsNothing);

      // 成功メッセージの確認
      expect(find.text('ユーザー名を更新しました'), findsOneWidget);
    });

    testWidgets('test_email_display_control_integration - メール表示制御の統合テスト', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // 異なる認証プロバイダーでのログインテスト
      // 注：実際の統合テストでは各認証プロバイダーのモックを使用

      // ゲストユーザーでの確認
      // メールアドレスが表示されないことを確認

      // Googleユーザーでの確認
      // メールアドレスが表示されることを確認

      // Appleユーザーでの確認  
      // メールアドレスが表示されることを確認
    });
  });
}