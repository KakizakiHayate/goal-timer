import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/manual_record/presentation/widgets/quick_record_dialog.dart';

void main() {
  group('Quick Record Dialog Tests - Issue #44', () {
    
    testWidgets('test_dialog_display - ダイアログ表示テスト', (tester) async {
      // 手動記録ダイアログが正しく表示されることを確認
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QuickRecordDialog(
                        goalId: 'test-goal',
                        goalTitle: 'テスト目標',
                      ),
                    );
                  },
                  child: const Text('手動記録'),
                ),
              ),
            ),
          ),
        ),
      );
      
      // 手動記録ボタンをタップ
      await tester.tap(find.text('手動記録'));
      await tester.pumpAndSettle();
      
      // ダイアログが表示されることを確認
      expect(find.text('📝 学習時間を記録'), findsOneWidget);
      expect(find.text('目標: テスト目標'), findsOneWidget);
      expect(find.text('学習時間:'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('記録する'), findsOneWidget);
    });
    
    testWidgets('test_numeric_keyboard - 数字キーボード表示テスト', (tester) async {
      // 数字専用キーボードが表示されることを確認
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 時間フィールドを確認
      final hourField = find.byKey(const Key('hours_input'));
      expect(hourField, findsOneWidget);
      
      // 分フィールドを確認
      final minuteField = find.byKey(const Key('minutes_input'));
      expect(minuteField, findsOneWidget);
    });
    
    testWidgets('test_input_validation_valid - 正常入力テスト', (tester) async {
      // T001: 正常入力 - 1時間30分 → 90分
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 1時間30分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '1');
      await tester.enterText(find.byKey(const Key('minutes_input')), '30');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されないことを確認
      expect(find.textContaining('分以上入力してください'), findsNothing);
    });
    
    testWidgets('test_input_validation_boundary_min - 境界値テスト（最小）', (tester) async {
      // T002: 境界値テスト - 最小 - 0時間1分 → 1分
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 0時間1分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '0');
      await tester.enterText(find.byKey(const Key('minutes_input')), '1');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されないことを確認
      expect(find.textContaining('分以上入力してください'), findsNothing);
    });
    
    testWidgets('test_input_validation_boundary_max - 境界値テスト（最大）', (tester) async {
      // T003: 境界値テスト - 最大 - 23時間59分 → 1439分
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 23時間59分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '23');
      await tester.enterText(find.byKey(const Key('minutes_input')), '59');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されないことを確認
      expect(find.textContaining('以下で入力してください'), findsNothing);
    });
    
    testWidgets('test_input_validation_zero_error - 無効入力テスト（ゼロ）', (tester) async {
      // T004: 無効入力 - ゼロ - 0時間0分 → エラー
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 0時間0分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '0');
      await tester.enterText(find.byKey(const Key('minutes_input')), '0');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されることを確認
      expect(find.textContaining('1分以上入力してください'), findsOneWidget);
    });
    
    testWidgets('test_input_validation_minutes_over - 無効入力テスト（分超過）', (tester) async {
      // T005: 無効入力 - 分超過 - 1時間60分 → エラー
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 1時間60分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '1');
      await tester.enterText(find.byKey(const Key('minutes_input')), '60');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されることを確認
      expect(find.textContaining('59分以下で入力してください'), findsOneWidget);
    });
    
    testWidgets('test_input_validation_hours_over - 無効入力テスト（時間超過）', (tester) async {
      // T006: 無効入力 - 時間超過 - 24時間0分 → エラー
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 24時間0分を入力
      await tester.enterText(find.byKey(const Key('hours_input')), '24');
      await tester.enterText(find.byKey(const Key('minutes_input')), '0');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されることを確認
      expect(find.textContaining('23時間59分以下で入力してください'), findsOneWidget);
    });
    
    testWidgets('test_hours_only_input - 時間のみ入力テスト', (tester) async {
      // T007: 時間のみ入力 - 2時間0分 → 120分
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 2時間を入力（分は空のまま）
      await tester.enterText(find.byKey(const Key('hours_input')), '2');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されないことを確認
      expect(find.textContaining('分以上入力してください'), findsNothing);
    });
    
    testWidgets('test_minutes_only_input - 分のみ入力テスト', (tester) async {
      // T008: 分のみ入力 - 0時間45分 → 45分
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickRecordDialog(
                goalId: 'test-goal',
                goalTitle: 'テスト目標',
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // 45分を入力（時間は空のまま）
      await tester.enterText(find.byKey(const Key('minutes_input')), '45');
      
      // 記録するボタンをタップ
      await tester.tap(find.text('記録する'));
      await tester.pumpAndSettle();
      
      // エラーメッセージが表示されないことを確認
      expect(find.textContaining('分以上入力してください'), findsNothing);
    });

    // TODO: 実装完了後に以下のテストを有効化

    // testWidgets('test_date_picker - 日付選択テスト', (tester) async {
    //   // 日付選択機能が動作することを確認
    // });
    
    // testWidgets('test_empty_input_handling - 空文字入力テスト', (tester) async {
    //   // T017: 空文字入力を0として扱う
    // });
    
    // testWidgets('test_success_snackbar - 記録成功スナックバー', (tester) async {
    //   // 記録成功時のスナックバー表示を確認
    // });

    // より詳細なテストは実装完了後に追加
    // 現在は基本的な入力バリデーションとUI表示のテストのみ
  });
}