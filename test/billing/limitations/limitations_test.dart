// test/billing/limitations/limitations_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('3. 制限機能テスト', () {
    late BillingService billingService;
    late MockPurchases mockPurchases;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockPurchases = MockPurchases();
      mockConnectivity = MockConnectivity();
      billingService = BillingService(
        purchases: mockPurchases,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      billingService.dispose();
    });

    test('TC-LIM-001: 目標作成制限（3個）', () async {
      // Arrange - 無料プランユーザー、目標が2個作成済み
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // Act & Assert - 3個目の目標作成
      expect(await billingService.canCreateGoal(2), true, 
             reason: '3個目の目標作成は可能であること');
      expect(billingService.getGoalLimitMessage(2), 'これが最後の無料目標です',
             reason: '3個目作成時：「これが最後の無料目標です」警告表示');

      // Act & Assert - 4個目の目標作成試行
      expect(await billingService.canCreateGoal(3), false, 
             reason: '4個目の目標作成はアップグレードが必要であること');

      // Additional checks for progressive warnings
      expect(billingService.getGoalLimitMessage(1), 'あと1個で上限です',
             reason: '2個目作成時：「あと1個で上限」警告');
      expect(billingService.getGoalLimitMessage(0), '',
             reason: '1個目作成時：警告なし');
    });

    test('TC-LIM-002: ポモドーロタイマー制限', () async {
      // Arrange - 無料プランユーザー、目標詳細画面
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // Act & Assert - ポモドーロタイマーのアクセス制限確認
      expect(billingService.isPremium, false, 
             reason: '無料プランではプレミアム機能が無効であること');
      
      // UI would show premium badge and upgrade screen on tap
      // This is a business logic test - UI behavior would be tested separately
    });

    test('TC-LIM-003: CSVエクスポート制限', () async {
      // Arrange - 無料プランユーザー、統計画面
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // Act & Assert - CSVエクスポート機能の制限確認
      expect(billingService.isPremium, false, 
             reason: '無料プランではCSVエクスポートが制限されること');
      
      // UI would show upgrade screen when export button is tapped
      // This is a business logic test - UI behavior would be tested separately
    });

    test('TC-LIM-004: プレミアムユーザーの制限解除確認', () async {
      // Arrange - プレミアムユーザー
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act & Assert - すべての制限が解除されること
      expect(await billingService.canCreateGoal(100), true, 
             reason: 'プレミアムユーザーは目標を無制限で作成可能');
      expect(billingService.getGoalLimitMessage(50), '', 
             reason: 'プレミアムユーザーには制限メッセージが表示されない');
      expect(billingService.isPremium, true, 
             reason: 'すべてのプレミアム機能が利用可能');
    });

    test('TC-LIM-005: トライアルユーザーの制限解除確認', () async {
      // Arrange - トライアル期間中のユーザー
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(5);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      // Act & Assert - トライアル期間中はすべての機能が利用可能
      expect(await billingService.canCreateGoal(20), true, 
             reason: 'トライアル期間中は目標を無制限で作成可能');
      expect(billingService.isPremium, true, 
             reason: 'トライアル期間中はプレミアム機能が利用可能');
      expect(billingService.getGoalLimitMessage(10), '', 
             reason: 'トライアル期間中は制限メッセージが表示されない');
    });
  });

  group('制限機能 - 境界値テスト', () {
    late BillingService billingService;
    late MockPurchases mockPurchases;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockPurchases = MockPurchases();
      mockConnectivity = MockConnectivity();
      billingService = BillingService(
        purchases: mockPurchases,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      billingService.dispose();
    });

    test('TC-LIM-B001: 目標数の境界値テスト', () async {
      // Arrange - 無料プランユーザー
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // Act & Assert - 境界値での動作確認
      expect(await billingService.canCreateGoal(0), true, reason: '0個→1個目は作成可能');
      expect(await billingService.canCreateGoal(1), true, reason: '1個→2個目は作成可能');
      expect(await billingService.canCreateGoal(2), true, reason: '2個→3個目は作成可能');
      expect(await billingService.canCreateGoal(3), false, reason: '3個→4個目は作成不可');
      expect(await billingService.canCreateGoal(4), false, reason: '4個→5個目は作成不可');
    });

    test('TC-LIM-B002: 負の値での目標数テスト', () async {
      // Arrange - 無料プランユーザー
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // Act & Assert - 負の値での動作確認
      expect(await billingService.canCreateGoal(-1), true, 
             reason: '負の値でも制限チェックが正常動作すること');
      expect(billingService.getGoalLimitMessage(-1), '', 
             reason: '負の値では警告メッセージが表示されないこと');
    });

    test('TC-LIM-B003: 極端に大きな値での目標数テスト', () async {
      // Arrange - プレミアムユーザー
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act & Assert - 極端に大きな値での動作確認
      expect(await billingService.canCreateGoal(999999), true, 
             reason: 'プレミアムユーザーは極端に大きな値でも制限なし');
      expect(billingService.getGoalLimitMessage(999999), '', 
             reason: '大きな値でも警告メッセージが表示されないこと');
    });
  });

  group('制限機能 - 状態変更テスト', () {
    late BillingService billingService;
    late MockPurchases mockPurchases;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockPurchases = MockPurchases();
      mockConnectivity = MockConnectivity();
      billingService = BillingService(
        purchases: mockPurchases,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      billingService.dispose();
    });

    test('TC-LIM-S001: 無料→プレミアム状態変更時の制限解除', () async {
      // Arrange - 初期状態は無料プラン
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      // 無料プランでの制限確認
      expect(await billingService.canCreateGoal(3), false);

      // Act - プレミアムにアップグレード
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - 制限が解除されることを確認
      expect(await billingService.canCreateGoal(3), true, 
             reason: 'プレミアム移行後は制限が解除されること');
      expect(billingService.getGoalLimitMessage(10), '', 
             reason: '制限メッセージが表示されなくなること');
    });

    test('TC-LIM-S002: トライアル期間終了時の制限復活', () async {
      // Arrange - トライアル期間中
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(1);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      // トライアル期間中の制限なし確認
      expect(await billingService.canCreateGoal(5), true);

      // Act - トライアル期間終了（無料プランに戻る）
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - 制限が復活することを確認
      expect(await billingService.canCreateGoal(3), false, 
             reason: 'トライアル終了後は制限が復活すること');
      expect(billingService.getGoalLimitMessage(2), 'これが最後の無料目標です', 
             reason: '制限メッセージが再び表示されること');
    });
  });
}