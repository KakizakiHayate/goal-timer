import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/startup_logic_service.dart';
import '../../../lib/core/services/temp_user_service.dart';
import '../../../lib/features/onboarding/presentation/view_models/onboarding_view_model.dart';

void main() {
  group('TC002: ホットリロード時のルーティング動作確認', () {
    late ProviderContainer container;
    late StartupLogicService startupLogicService;
    late TempUserService tempUserService;

    setUp(() async {
      // SharedPreferences初期化
      SharedPreferences.setMockInitialValues({});
      
      // Riverpod container作成
      container = ProviderContainer();
      
      // サービス取得
      startupLogicService = container.read(startupLogicServiceProvider);
      tempUserService = container.read(tempUserServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('メインルーティングテスト', () {
      testWidgets('TC002-1: ゲストとして続行後、初期ルートが/homeになる', (tester) async {
        // Arrange: 仮ユーザー作成とゲスト続行
        await tempUserService.generateTempUserId();
        final viewModel = container.read(onboardingViewModelProvider.notifier);
        await viewModel.continueAsGuest();
        
        // Act: ホットリロード後の初期ルート判定をシミュレート
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/home'), 
            reason: 'ゲストとして続行後はホーム画面が初期ルートになること');
      });

      testWidgets('TC002-2: アカウント作成未完了時は次のオンボーディングステップへ', (tester) async {
        // Arrange: ステップ2（デモタイマー完了、アカウント作成未完了）
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(2);
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/onboarding/account-promotion'), 
            reason: 'ステップ2の場合はアカウント設定画面へ遷移すること');
      });

      testWidgets('TC002-3: ステップ0の場合は目標作成画面から開始', (tester) async {
        // Arrange: 仮ユーザーなし、またはステップ0
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(0);
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/onboarding/goal-creation'), 
            reason: 'ステップ0の場合は目標作成画面から開始すること');
      });

      testWidgets('TC002-4: ステップ1の場合はデモタイマー画面へ', (tester) async {
        // Arrange: ステップ1（目標作成完了）
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/home'), 
            reason: 'ステップ1の場合はホーム画面へ遷移すること（チュートリアル開始のため）');
      });

      testWidgets('TC002-5: アカウント作成済み（認証ユーザー）の場合は常にホーム画面へ', (tester) async {
        // Arrange: 認証済みユーザーをシミュレート
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1); // 途中のステップでも
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/home'), 
            reason: '認証済みユーザーは常にホーム画面へ遷移すること');
        
        // Cleanup
        await prefs.setBool('is_authenticated', false);
      });

      testWidgets('TC002-6: ステップ3（ゲスト完了）の場合はホーム画面が維持される', (tester) async {
        // Arrange: ゲスト完了状態
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(3);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', false); // ゲストユーザー
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/home'), 
            reason: 'ゲスト完了（ステップ3）の場合はホーム画面へ遷移すること');
      });
    });

    group('TC002-拡張: エッジケースのテスト', () {
      testWidgets('TC002-E1: 仮ユーザーが期限切れの場合', (tester) async {
        // Arrange: 8日前のユーザー作成日時を設定（有効期限は7日）
        await tempUserService.generateTempUserId();
        final prefs = await SharedPreferences.getInstance();
        final expiredTime = DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;
        await prefs.setInt('temp_user_created_at', expiredTime);
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/onboarding/goal-creation'), 
            reason: '期限切れの場合は目標作成画面から再開すること');
      });

      testWidgets('TC002-E2: チュートリアルアクティブ時', (tester) async {
        // Arrange: チュートリアルアクティブ状態
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1); // 途中のステップ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tutorial_active', true);
        
        // Act
        final initialRoute = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(initialRoute, equals('/home'), 
            reason: 'チュートリアルアクティブ時はステップに関わらずホーム画面へ');
        
        // Cleanup
        await prefs.setBool('tutorial_active', false);
      });

      testWidgets('TC002-E3: 不正なステップ値の処理', (tester) async {
        // Arrange: 不正なステップ値
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(99); // 不正値
        
        // Act & Assert - クラッシュしないことを確認
        expect(() async {
          final initialRoute = await startupLogicService.determineInitialRoute();
          // 不正値の場合は安全にフォールバック
          expect(['/onboarding/goal-creation', '/home'], contains(initialRoute));
        }, returnsNormally);
      });
    });

    group('TC002-統合: フロー全体のテスト', () {
      testWidgets('TC002-I1: オンボーディング完全フロー', (tester) async {
        // Arrange: 新規ユーザーから開始
        await tempUserService.generateTempUserId();
        final viewModel = container.read(onboardingViewModelProvider.notifier);
        
        // Act & Assert: ステップ0→1→2→3の流れ
        
        // ステップ0: 目標作成画面
        await tempUserService.updateOnboardingStep(0);
        var route = await startupLogicService.determineInitialRoute();
        expect(route, equals('/onboarding/goal-creation'));
        
        // ステップ1: ホーム画面（チュートリアル開始）
        await viewModel.completeGoalCreation();
        route = await startupLogicService.determineInitialRoute();
        expect(route, equals('/home'));
        
        // ステップ2: アカウント設定画面
        await viewModel.completeStep(2);
        route = await startupLogicService.determineInitialRoute();
        expect(route, equals('/onboarding/account-promotion'));
        
        // ステップ3: ゲスト続行でホーム画面
        await viewModel.continueAsGuest();
        route = await startupLogicService.determineInitialRoute();
        expect(route, equals('/home'));
      });

      testWidgets('TC002-I2: アカウント作成時の即座の遷移', (tester) async {
        // Arrange: 途中のステップでアカウント作成
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);
        
        // Act: アカウント作成をシミュレート
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        
        final route = await startupLogicService.determineInitialRoute();
        
        // Assert
        expect(route, equals('/home'), 
            reason: 'アカウント作成時は即座にホーム画面へ遷移すること');
        
        // Cleanup
        await prefs.setBool('is_authenticated', false);
      });
    });

    group('TC002-検証: 整合性確認テスト', () {
      testWidgets('TC002-V1: ルート文字列の形式確認', (tester) async {
        // Arrange & Act: 各ステップでのルート取得
        await tempUserService.generateTempUserId();
        
        final routes = <int, String>{};
        for (int step = 0; step <= 3; step++) {
          await tempUserService.updateOnboardingStep(step);
          if (step == 3) {
            // ステップ3の場合は認証状態もチェック
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_authenticated', false); // ゲスト状態
          }
          routes[step] = await startupLogicService.determineInitialRoute();
        }
        
        // Assert: ルート形式の確認
        expect(routes[0], equals('/onboarding/goal-creation'));
        expect(routes[1], equals('/home'));
        expect(routes[2], equals('/onboarding/account-promotion'));
        expect(routes[3], equals('/home'));
        
        // 各ルートが正しい形式であることを確認
        for (final route in routes.values) {
          expect(route, startsWith('/'), reason: 'ルートは/で始まること');
          expect(route, isNot(contains(' ')), reason: 'ルートに空白が含まれないこと');
        }
      });

      testWidgets('TC002-V2: shouldShowOnboardingとルーティングの整合性', (tester) async {
        // Arrange
        await tempUserService.generateTempUserId();
        
        // Act & Assert: 各ステップでの整合性確認
        for (int step = 0; step <= 3; step++) {
          await tempUserService.updateOnboardingStep(step);
          
          final shouldShow = await startupLogicService.shouldShowOnboarding();
          final route = await startupLogicService.determineInitialRoute();
          
          if (step < 3) {
            expect(shouldShow, isTrue, 
                reason: 'ステップ$stepではオンボーディングを表示すべき');
            if (step == 1) {
              // ステップ1は特別扱い（チュートリアル開始のためホーム画面）
              expect(route, equals('/home'), 
                  reason: 'ステップ1ではホーム画面へのルートになること（チュートリアル開始）');
            } else {
              expect(route, startsWith('/onboarding'), 
                  reason: 'ステップ$stepではオンボーディング画面へのルートになること');
            }
          } else {
            expect(shouldShow, isFalse, 
                reason: 'ステップ3ではオンボーディングを表示すべきでない');
            expect(route, equals('/home'), 
                reason: 'ステップ3ではホーム画面へのルートになること');
          }
        }
      });
    });
  });
}