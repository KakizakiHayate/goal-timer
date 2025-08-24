import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal_timer/main.dart';
import 'package:goal_timer/features/onboarding/presentation/screens/goal_creation_screen.dart';
import 'package:goal_timer/features/onboarding/presentation/screens/demo_timer_screen.dart';
import 'package:goal_timer/features/onboarding/presentation/screens/account_promotion_screen.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('E2E: オンボーディングフロー', () {
    late SharedPreferences prefs;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await prefs.clear();
    });

    testWidgets('完全なオンボーディングフローが正常に動作すること', (tester) async {
      // アプリを起動
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestHelpers.createTestProviderOverrides(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // ステップ1: 目標作成画面が表示される
      expect(find.byType(GoalCreationScreen), findsOneWidget);
      expect(find.text('目標を設定'), findsOneWidget);
      
      // プログレスバーが33%を表示
      expect(find.text('ステップ 1/3'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);

      // 目標情報を入力
      await tester.enterText(
        find.byKey(const Key('goal_name_field')),
        'TOEIC 800点を取る',
      );
      await tester.enterText(
        find.byKey(const Key('goal_reason_field')),
        'キャリアアップのため',
      );
      await tester.enterText(
        find.byKey(const Key('goal_negative_field')),
        '昇進のチャンスを逃す',
      );
      
      // 次へボタンをタップ
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      // ステップ2: デモタイマー画面が表示される
      expect(find.byType(DemoTimerScreen), findsOneWidget);
      expect(find.text('タイマーを体験'), findsOneWidget);
      
      // プログレスバーが66%を表示
      expect(find.text('ステップ 2/3'), findsOneWidget);
      expect(find.text('66%'), findsOneWidget);

      // デモタイマーが自動的に開始される
      expect(find.text('タイマーを体験してみましょう'), findsOneWidget);
      
      // 5秒待機（デモタイマーの完了を待つ）
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      
      // 完了ダイアログが表示される
      expect(find.text('お疲れさまでした！'), findsOneWidget);
      
      // 次へボタンをタップ
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      // ステップ3: アカウント作成促進画面が表示される
      expect(find.byType(AccountPromotionScreen), findsOneWidget);
      expect(find.text('アカウント設定'), findsOneWidget);
      
      // プログレスバーが100%を表示
      expect(find.text('ステップ 3/3'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      
      // アカウント作成オプションが表示される
      expect(find.text('アカウントを作成'), findsOneWidget);
      expect(find.text('Googleで続ける'), findsOneWidget);
      expect(find.text('メールアドレスで続ける'), findsOneWidget);
      expect(find.text('ゲストとして続行'), findsOneWidget);
    });

    testWidgets('ゲストとして続行する場合の動作', (tester) async {
      // オンボーディングの最終画面まで進む
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestHelpers.createTestProviderOverrides(),
          child: const MyApp(),
        ),
      );
      
      // 最終画面まで素早く進める
      await _skipToAccountPromotionScreen(tester);
      
      // ゲストとして続行ボタンをタップ
      await tester.tap(find.byKey(const Key('continue_as_guest_button')));
      await tester.pumpAndSettle();
      
      // ホーム画面に遷移することを確認
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // 一時ユーザーが作成されていることを確認
      final tempUserId = prefs.getString('temp_user_id');
      expect(tempUserId, isNotNull);
      expect(tempUserId, startsWith('local_user_temp_'));
    });

    testWidgets('入力バリデーションが正しく動作すること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestHelpers.createTestProviderOverrides(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      
      // 何も入力せずに次へボタンをタップ
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pump();
      
      // 次へボタンが無効化されていることを確認
      final nextButton = tester.widget<Widget>(
        find.byKey(const Key('next_button')),
      );
      expect(nextButton, isNotNull);
      
      // 目標名だけ入力
      await tester.enterText(
        find.byKey(const Key('goal_name_field')),
        'テスト目標',
      );
      await tester.pump();
      
      // まだ次へボタンが無効化されていることを確認
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pump();
      expect(find.byType(GoalCreationScreen), findsOneWidget);
      
      // すべてのフィールドを入力
      await tester.enterText(
        find.byKey(const Key('goal_reason_field')),
        'テスト理由',
      );
      await tester.enterText(
        find.byKey(const Key('goal_negative_field')),
        'テストネガティブ',
      );
      await tester.pump();
      
      // 次へボタンが有効化され、タップできることを確認
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();
      expect(find.byType(DemoTimerScreen), findsOneWidget);
    });

    testWidgets('プログレスバーが正しく更新されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestHelpers.createTestProviderOverrides(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      
      // ステップ1: 33%
      expect(find.text('33%'), findsOneWidget);
      
      // ステップ2に進む
      await _fillGoalFormAndProceed(tester);
      expect(find.text('66%'), findsOneWidget);
      
      // ステップ3に進む
      await _completeTimerAndProceed(tester);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('オンボーディング状態が正しく保存されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestHelpers.createTestProviderOverrides(),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      
      // ステップ1で目標を入力
      await _fillGoalFormAndProceed(tester);
      
      // オンボーディング状態が保存されていることを確認
      final onboardingStep = prefs.getInt('onboarding_step');
      expect(onboardingStep, 2);
      
      // ステップ2からステップ3に進む
      await _completeTimerAndProceed(tester);
      
      // オンボーディング状態が更新されていることを確認
      final updatedStep = prefs.getInt('onboarding_step');
      expect(updatedStep, 3);
    });
  });
}

// ヘルパー関数
Future<void> _skipToAccountPromotionScreen(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // ステップ1: 目標作成
  await _fillGoalFormAndProceed(tester);
  
  // ステップ2: デモタイマー
  await _completeTimerAndProceed(tester);
}

Future<void> _fillGoalFormAndProceed(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('goal_name_field')),
    'テスト目標',
  );
  await tester.enterText(
    find.byKey(const Key('goal_reason_field')),
    'テスト理由',
  );
  await tester.enterText(
    find.byKey(const Key('goal_negative_field')),
    'テストネガティブ',
  );
  await tester.tap(find.byKey(const Key('next_button')));
  await tester.pumpAndSettle();
}

Future<void> _completeTimerAndProceed(WidgetTester tester) async {
  // デモタイマーの完了を待つ
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  
  // 次へボタンをタップ
  await tester.tap(find.byKey(const Key('next_button')));
  await tester.pumpAndSettle();
}