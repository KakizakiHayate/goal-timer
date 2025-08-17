// test/billing/purchase/purchase_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../billing_service_test.dart';

void main() {
  group('1. 購入フローテスト', () {
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

    test('TC-PUR-001: 初回購入（トライアル開始）', () async {
      // Arrange - 新規ユーザー、インターネット接続あり、未購入状態
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act - 購入実行
      final result = await billingService.purchasePremium();

      // Assert - 期待結果の検証
      expect(result, true, reason: 'トライアル購入が成功すること');
      expect(billingService.isPremium, true, reason: 'プレミアム機能が即座に有効化されること');
      expect(billingService.isTrial, true, reason: 'トライアル期間が開始されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(6), 
             reason: '7日間のトライアル期間が残っていること');
      expect(billingService.planDisplay, contains('トライアル中'), 
             reason: '「トライアル中（残り7日）」と表示されること');
      
      // 追加検証: 目標作成とCSVエクスポートが可能
      expect(await billingService.canCreateGoal(5), true, 
             reason: '目標を4個以上作成可能であること');
    });

    test('TC-PUR-002: 初回月割引購入', () async {
      // Arrange - トライアル期間終了後のユーザー、インターネット接続あり
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true,
            periodType: PeriodType.intro, // 初回割引期間
          )
        }),
      );
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 初回割引購入実行
      final result = await billingService.purchasePremium();

      // Assert - 期待結果の検証
      expect(result, true, reason: '初回割引購入が成功すること');
      expect(billingService.isPremium, true, reason: 'プレミアム機能が継続利用可能であること');
      expect(billingService.isTrial, false, reason: 'トライアル期間ではないこと');
    });

    test('TC-PUR-003: 購入キャンセル', () async {
      // Arrange - 未購入状態、アップグレード画面表示中
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true, errorCode: 'UserCancelled');
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);

      // Act - 購入キャンセル
      final result = await billingService.purchasePremium();

      // Assert - 期待結果の検証
      expect(result, false, reason: 'エラーなくアプリに戻ること');
      expect(billingService.isPremium, false, reason: '無料プランのままであること');
      expect(await billingService.canCreateGoal(3), false, 
             reason: '制限機能は引き続き制限されること');
    });

    test('TC-PUR-004: ネットワークエラー時の購入試行', () async {
      // Arrange - ネットワークエラー発生
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act & Assert - ネットワークエラーの検証
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<Exception>()),
        reason: 'ネットワークエラーが適切にスローされること',
      );
    });

    test('TC-PUR-005: 購入成功後の状態確認', () async {
      // Arrange - 購入成功設定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 購入実行
      await billingService.purchasePremium();

      // Assert - 購入後の状態検証
      expect(billingService.isPremium, true, reason: 'プレミアム状態になること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示が正しく更新されること');
      expect(billingService.getGoalLimitMessage(10), '', 
             reason: '目標制限メッセージが表示されないこと');
    });

    test('TC-PUR-006: 商品取得失敗時の処理', () async {
      // Arrange - 商品取得に失敗
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act & Assert - 商品取得失敗の処理確認
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<Exception>()),
        reason: '商品取得失敗時に適切にエラーがスローされること',
      );
    });

    test('TC-PUR-007: 購入処理中のタイムアウト確認', () async {
      // Arrange - 長時間の処理をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 購入実行
      await billingService.purchasePremium();
      stopwatch.stop();

      // Assert - 処理時間の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
             reason: '購入処理が5秒以内に完了すること');
    });

    test('TC-PUR-008: 複数回購入試行の防止', () async {
      // Arrange - プレミアム状態のユーザー
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - 二重購入チェック
      final alreadyPurchased = await billingService.checkDoublePurchase();

      // Assert - 二重購入防止の確認
      expect(alreadyPurchased, true, 
             reason: 'すでに購入済みであることが検出されること');
    });
  });

  group('購入フロー - エラーシナリオ', () {
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

    test('TC-PUR-E001: プラットフォーム固有エラーの処理', () async {
      // Arrange - プラットフォーム固有エラー
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true, errorCode: 'BILLING_UNAVAILABLE');

      // Act & Assert - プラットフォームエラーの処理確認
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<PlatformException>()),
        reason: 'プラットフォーム固有エラーが適切に処理されること',
      );
    });

    test('TC-PUR-E002: 決済サービス一時停止時の処理', () async {
      // Arrange - 決済サービス停止
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true, errorCode: 'SERVICE_UNAVAILABLE');

      // Act & Assert - サービス停止エラーの処理確認
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<PlatformException>()),
        reason: 'サービス停止時に適切なエラーが返されること',
      );
    });

    test('TC-PUR-E003: 不正な商品ID指定時の処理', () async {
      // Arrange - 商品が見つからない状況をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act & Assert - 商品未検出エラーの処理確認
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Mock error'),
        )),
        reason: '商品が見つからない場合に適切にエラーが処理されること',
      );
    });
  });
}