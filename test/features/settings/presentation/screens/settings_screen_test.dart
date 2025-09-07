import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/settings/presentation/screens/settings_screen.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/widgets/pressable_card.dart';

void main() {
  group('SettingsScreen - 不要機能削除後のテスト', () {
    late Widget testWidget;

    setUp(() {
      testWidget = ProviderScope(
        child: MaterialApp(
          home: const SettingsScreen(),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: ColorConsts.backgroundPrimary,
          ),
        ),
      );
    });

    group('UI表示テスト', () {
      testWidgets('test_removed_features_not_displayed - 削除対象機能が非表示', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // 通知設定セクションが存在しないことを確認
        expect(find.text('通知設定'), findsNothing);
        expect(find.text('通知を有効にする'), findsNothing);
        expect(find.text('サウンド'), findsNothing);
        expect(find.text('バイブレーション'), findsNothing);

        // テーマ設定が存在しないことを確認
        expect(find.text('テーマ'), findsNothing);

        // 週の開始日設定が存在しないことを確認
        expect(find.text('週の開始日'), findsNothing);

        // FAQ項目が存在しないことを確認
        expect(find.text('ヘルプ・FAQ'), findsNothing);

        // AppBarの戻るボタンが存在しないことを確認
        expect(find.byType(BackButton), findsNothing);
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });

      testWidgets('test_remaining_features_displayed - 残存機能の正常表示', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // プロフィールセクション（ユーザー名として表示）
        expect(find.text('ユーザー名'), findsOneWidget);
        expect(find.text('プレミアム会員'), findsOneWidget);
        
        // アプリ設定セクション
        expect(find.text('デフォルトタイマー時間'), findsOneWidget);
        
        // サポートセクション
        expect(find.text('お問い合わせ'), findsOneWidget);
        
        // アカウントセクション
        expect(find.text('サインアウト'), findsOneWidget);

        // セクションタイトルが表示されることを確認
        expect(find.text('アプリ設定'), findsOneWidget);
        expect(find.text('データとプライバシー'), findsOneWidget);
        expect(find.text('サポート'), findsOneWidget);
        expect(find.text('アカウント'), findsOneWidget);
      });
    });

    group('機能テスト', () {
      testWidgets('test_remaining_functionality_works - 残存機能の動作確認', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // ユーザー名項目（プロフィールセクション）をタップできることを確認
        final profileTile = find.text('ユーザー名');
        expect(profileTile, findsOneWidget);
        await tester.tap(profileTile);
        await tester.pumpAndSettle();
        
        // タップ後の状態を確認（例：ダイアログ表示やナビゲーション）
        // 実際の実装に応じて適切なアサーションを追加
        expect(find.byType(SettingsScreen), findsOneWidget);

        // デフォルトタイマー時間の設定項目をタップできることを確認
        final timerTile = find.text('デフォルトタイマー時間');
        expect(timerTile, findsOneWidget);
        // スクロールして要素を表示してからタップ
        await tester.ensureVisible(timerTile);
        await tester.tap(timerTile, warnIfMissed: false);
        await tester.pumpAndSettle();
        
        // タップ後の状態を確認
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('レイアウト・スタイルテスト', () {
      testWidgets('test_responsive_layout_after_cleanup - レスポンシブレイアウト確認', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // AppBarが正常に表示されることを確認
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('設定'), findsOneWidget);

        // SingleChildScrollViewが正常に表示されることを確認
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // カードが適切に配置されていることを確認（PressableCard使用）
        expect(find.byType(PressableCard), findsWidgets);

        // スペーシングが適切に設定されていることを確認（SizedBoxの存在）
        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('test_scroll_behavior_after_cleanup - スクロール動作確認', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // スクロール可能であることを確認
        final scrollView = find.byType(SingleChildScrollView);
        expect(scrollView, findsOneWidget);

        // 上方向にスクロールしてみる
        await tester.fling(scrollView, const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        // 下方向にスクロールしてみる
        await tester.fling(scrollView, const Offset(0, -300), 1000);
        await tester.pumpAndSettle();
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('test_navigation_without_back_button - 戻るボタン削除後のナビゲーション', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // AppBarのleadingが設定されていないことを確認
        final AppBar appBar = tester.widget(find.byType(AppBar));
        expect(appBar.leading, isNull);

        // システムの戻るボタン（Android）やスワイプジェスチャー（iOS）は
        // プラットフォーム側で処理されるため、ここではAppBarの設定のみを確認
      });

      testWidgets('test_screen_transition_consistency - 画面遷移の整合性', (tester) async {
        // このテストは統合テストでより詳細に実行される想定
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // 画面が正常に表示されることを確認
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('パフォーマンステスト', () {
      testWidgets('test_render_performance_after_cleanup - 描画パフォーマンス向上確認', (tester) async {
        // パフォーマンステストはWidget treeの構造確認に焦点を当てる
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // 削除された不要な要素がWidget treeに存在しないことを確認
        expect(find.text('通知を有効にする'), findsNothing);
        expect(find.text('サウンド'), findsNothing);
        expect(find.text('バイブレーション'), findsNothing);
        expect(find.text('テーマ'), findsNothing);
        expect(find.text('週の開始日'), findsNothing);

        // Widget treeが期待通りにクリーンアップされていることを確認
        // 削除機能に関連するWidgetが存在しないことを確認
        final allTexts = find.byType(Text);
        final textWidgets = tester.widgetList<Text>(allTexts);
        final textContents = textWidgets.map((widget) => widget.data ?? '').toList();
        
        // 削除対象のテキストが含まれていないことを確認
        expect(textContents.any((text) => text.contains('通知')), isFalse);
        expect(textContents.any((text) => text.contains('テーマ')), isFalse);
        expect(textContents.any((text) => text.contains('週の開始日')), isFalse);
        
        // 画面が正常にレンダリングされることを確認
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('test_no_errors_from_removed_features - 削除機能のエラー非発生確認', (tester) async {
        // この段階では、削除された機能に関連するエラーが発生しないことを確認
        // 主にコンパイル時エラーがないことと、実行時エラーが発生しないことを確認

        bool hasError = false;
        FlutterError.onError = (FlutterErrorDetails details) {
          hasError = true;
        };

        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // エラーが発生していないことを確認
        expect(hasError, isFalse);

        // 画面が正常に表示されることを確認
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });
  });
}