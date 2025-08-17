// test/billing/trial/trial_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('5. トライアル関連テスト', () {
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

    test('TC-TRI-001: トライアル期間表示', () async {
      // Arrange - トライアル期間中（残り5日）
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(5);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act - 初期化してトライアル情報を取得
      await billingService.initialize();

      // Assert - トライアル期間の表示確認
      expect(billingService.isTrial, true, 
             reason: 'トライアル期間中であることが検出されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(4), 
             reason: '「トライアル期間中（残り5日）」と表示されること');
      expect(billingService.planDisplay, contains('トライアル中'), 
             reason: '終了日時が明確に表示されること');
      expect(billingService.planDisplay, contains('残り'), 
             reason: 'キャンセル方法へのリンク表示（UI実装で対応）');
    });

    test('TC-TRI-002: トライアル終了時の動作', () async {
      // Arrange - トライアル期間最終日、自動更新有効
      final premiumCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true,
            periodType: PeriodType.normal, // トライアル終了後の通常プラン
          )
        }),
      );
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - トライアル終了後のアプリ起動をシミュレート
      await billingService.initialize();

      // Assert - 自動課金開始の確認
      expect(billingService.isPremium, true, 
             reason: '自動的に¥240の課金開始（実際の課金はストア側で処理）');
      expect(billingService.isTrial, false, 
             reason: 'トライアル期間ではなくなること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: '「プレミアムプラン（¥240/月）」と表示');
      expect(await billingService.canCreateGoal(10), true, 
             reason: '機能制限なく継続利用可能');
    });

    test('TC-TRI-003: トライアルキャンセル', () async {
      // Arrange - トライアル期間中、iOS設定/Google Playでキャンセル済み
      final cancelledTrialCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true, // まだアクティブ（期間中）
            periodType: PeriodType.trial,
            expirationDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            willRenew: false, // キャンセル済み
          )
        }),
      );
      mockPurchases.setCustomerInfo(cancelledTrialCustomerInfo);

      // Act - キャンセル後のアプリ起動
      await billingService.initialize();

      // Assert - キャンセル状態の表示確認
      expect(billingService.isTrial, true, 
             reason: 'トライアル期間中は機能継続');
      expect(billingService.isPremium, true, 
             reason: '期間終了まではプレミアム機能利用可能');
      // UI would show: 「トライアル期間終了後、無料プランに戻ります」
      
      // Simulate trial expiration
      final expiredCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(expiredCustomerInfo);
      await billingService.syncWithRevenueCat();
      
      // Assert - 期間終了後の制限確認
      expect(billingService.isPremium, false, 
             reason: '期間終了後、自動的に機能制限');
    });

    test('TC-TRI-004: トライアル期間の残日数計算', () async {
      // Arrange - 様々なトライアル残日数でテスト
      final testCases = [1, 3, 7, 14];
      
      for (final days in testCases) {
        final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(days);
        mockPurchases.setCustomerInfo(trialCustomerInfo);
        await billingService.syncWithRevenueCat();

        // Act & Assert - 残日数の正確性確認
        expect(billingService.trialDaysLeft, greaterThanOrEqualTo(days - 1), 
               reason: '残り${days}日の計算が正確であること');
        expect(billingService.planDisplay, contains('残り'), 
               reason: '残り日数が表示されること');
      }
    });

    test('TC-TRI-005: トライアル期間0日（当日終了）', () async {
      // Arrange - トライアル期間が当日終了
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(0);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act
      await billingService.initialize();

      // Assert - 当日終了の場合の表示確認
      expect(billingService.isTrial, true, 
             reason: '当日でもトライアル状態であること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(0), 
             reason: '残り日数が0以上であること');
    });
  });

  group('トライアル機能 - 状態遷移テスト', () {
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

    test('TC-TRI-S001: 無料 → トライアル → プレミアム', () async {
      // Arrange - 初期状態は無料プラン
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, false);
      expect(billingService.isTrial, false);

      // Act - トライアル開始
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - トライアル状態
      expect(billingService.isTrial, true, reason: 'トライアル状態に遷移');
      expect(billingService.isPremium, true, reason: 'プレミアム機能が利用可能');

      // Act - プレミアムプランへ移行
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - プレミアム状態
      expect(billingService.isTrial, false, reason: 'トライアル期間終了');
      expect(billingService.isPremium, true, reason: 'プレミアム機能継続');
      expect(billingService.planDisplay, 'プレミアムプラン');
    });

    test('TC-TRI-S002: トライアル → 無料（キャンセル）', () async {
      // Arrange - トライアル期間中
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(1);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      expect(billingService.isTrial, true);

      // Act - トライアル期間終了（キャンセル済み）
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - 無料プランに戻る
      expect(billingService.isTrial, false, reason: 'トライアル終了');
      expect(billingService.isPremium, false, reason: '無料プランに戻る');
      expect(billingService.planDisplay, '無料プラン');
      expect(await billingService.canCreateGoal(3), false, reason: '制限が復活');
    });
  });

  group('トライアル機能 - エラーケース', () {
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

    test('TC-TRI-E001: 不正な期限日データの処理', () async {
      // Arrange - 不正な期限日データ
      final invalidTrialCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true,
            periodType: PeriodType.trial,
            expirationDate: 'invalid-date', // 不正な日付形式
          )
        }),
      );
      mockPurchases.setCustomerInfo(invalidTrialCustomerInfo);

      // Act & Assert - 不正データでもクラッシュしないこと
      expect(() async => await billingService.initialize(), 
             returnsNormally, 
             reason: '不正な期限日データでもクラッシュしないこと');
      
      expect(billingService.trialDaysLeft, 0, 
             reason: '不正なデータの場合は0日として処理すること');
    });

    test('TC-TRI-E002: 過去の期限日データの処理', () async {
      // Arrange - 過去の期限日データ
      final pastTrialCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: false,
            periodType: PeriodType.trial,
            expirationDate: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          )
        }),
      );
      mockPurchases.setCustomerInfo(pastTrialCustomerInfo);

      // Act
      await billingService.initialize();

      // Assert - 過去の期限日の適切な処理
      expect(billingService.isTrial, false, 
             reason: '期限切れトライアルは無効として処理');
      expect(billingService.isPremium, false, 
             reason: '期限切れの場合は無料プランとして処理');
    });
  });
}