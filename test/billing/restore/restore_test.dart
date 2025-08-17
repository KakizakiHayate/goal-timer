// test/billing/restore/restore_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../billing_service_test.dart';

void main() {
  group('2. 復元機能テスト', () {
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

    test('TC-RES-001: 購入復元（成功）', () async {
      // Arrange - 過去にプレミアム購入済み、同じApple ID/Google アカウント
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 購入復元実行
      final result = await billingService.restorePurchases();

      // Assert - 期待結果の検証
      expect(result, true, reason: '購入復元が成功すること');
      expect(billingService.isPremium, true, reason: 'プレミアム機能が有効化されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: '設定画面に「プレミアムプラン」と表示されること');
      
      // 追加検証: 復元後の機能利用確認
      expect(await billingService.canCreateGoal(10), true, 
             reason: '復元後は目標を無制限で作成可能であること');
    });

    test('TC-RES-002: 購入復元（購入履歴なし）', () async {
      // Arrange - 購入履歴のないアカウント
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);

      // Act & Assert - 購入履歴なしの処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>().having(
          (e) => e.message,
          'message',
          '復元する購入が見つかりません',
        )),
        reason: '「復元する購入が見つかりません」と表示されること',
      );
      expect(billingService.isPremium, false, reason: '無料プランのままであること');
    });

    test('TC-RES-003: 復元処理中のネットワークエラー', () async {
      // Arrange - ネットワークエラー発生設定
      mockPurchases.setShouldThrowError(true);

      // Act & Assert - ネットワークエラー処理の確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<Exception>()),
        reason: 'ネットワークエラー時に適切にエラーがスローされること',
      );
    });

    test('TC-RES-004: トライアル期間中の復元', () async {
      // Arrange - トライアル期間中のユーザー
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(3);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act - 復元実行
      final result = await billingService.restorePurchases();

      // Assert - トライアル復元の確認
      expect(result, true, reason: 'トライアル購入の復元が成功すること');
      expect(billingService.isTrial, true, reason: 'トライアル状態が復元されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(2), 
             reason: '残りトライアル日数が正しく復元されること');
      expect(billingService.planDisplay, contains('トライアル中'), 
             reason: 'トライアル期間の表示が正しくされること');
    });

    test('TC-RES-005: 期限切れサブスクリプションの復元試行', () async {
      // Arrange - 期限切れのサブスクリプション
      final expiredCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: false, // 期限切れ
            periodType: PeriodType.normal,
            expirationDate: DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          )
        }),
      );
      mockPurchases.setCustomerInfo(expiredCustomerInfo);

      // Act & Assert - 期限切れサブスクリプションの処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>().having(
          (e) => e.message,
          'message',
          '復元する購入が見つかりません',
        )),
        reason: '期限切れサブスクリプションは復元対象外であること',
      );
    });

    test('TC-RES-006: 復元後の状態同期確認', () async {
      // Arrange - プレミアム購入済み設定
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 復元実行
      await billingService.restorePurchases();

      // Assert - 状態同期の確認
      expect(billingService.isPremium, true, reason: '内部状態が正しく更新されること');
      expect(billingService.getGoalLimitMessage(5), '', 
             reason: '制限メッセージが非表示になること');
      
      // 別の操作での状態確認
      expect(await billingService.canCreateGoal(100), true, 
             reason: '大量の目標作成が可能になること');
    });

    test('TC-RES-007: 複数デバイス間での復元', () async {
      // Arrange - 別デバイスでの復元シミュレート
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // 初期状態確認
      expect(billingService.isPremium, false, reason: '初期状態は無料プラン');

      // Act - デバイス間復元実行
      final result = await billingService.restorePurchases();

      // Assert - 復元成功の確認
      expect(result, true, reason: 'デバイス間復元が成功すること');
      expect(billingService.isPremium, true, reason: '新しいデバイスでプレミアム状態になること');
    });

    test('TC-RES-008: 復元処理のパフォーマンス確認', () async {
      // Arrange - 復元処理の準備
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      
      final stopwatch = Stopwatch()..start();

      // Act - 復元実行
      await billingService.restorePurchases();
      stopwatch.stop();

      // Assert - パフォーマンス確認
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
             reason: '復元処理が3秒以内に完了すること');
    });
  });

  group('復元機能 - エラーシナリオ', () {
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

    test('TC-RES-E001: App Store/Google Playサーバーエラー', () async {
      // Arrange - サーバーエラー設定
      mockPurchases.setShouldThrowError(true, errorCode: 'SERVER_ERROR');

      // Act & Assert - サーバーエラー処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>()),
        reason: 'サーバーエラー時に適切にエラーがスローされること',
      );
    });

    test('TC-RES-E002: 認証エラー時の処理', () async {
      // Arrange - 認証エラー設定
      mockPurchases.setShouldThrowError(true, errorCode: 'AUTHENTICATION_ERROR');

      // Act & Assert - 認証エラー処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>()),
        reason: '認証エラー時に適切にエラーが処理されること',
      );
    });

    test('TC-RES-E003: タイムアウトエラーの処理', () async {
      // Arrange - タイムアウト設定（長時間処理をシミュレート）
      mockPurchases.setShouldThrowError(true, errorCode: 'TIMEOUT');

      // Act & Assert - タイムアウトエラー処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>()),
        reason: 'タイムアウト時に適切にエラーが処理されること',
      );
    });

    test('TC-RES-E004: 複数アカウント混在時の処理', () async {
      // Arrange - 複数アカウント（混在状態をシミュレート）
      final mixedCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: false, // アクティブでない状態
            periodType: PeriodType.normal,
          )
        }),
      );
      mockPurchases.setCustomerInfo(mixedCustomerInfo);

      // Act & Assert - 混在状態の処理確認
      expect(
        () async => await billingService.restorePurchases(),
        throwsA(isA<PlatformException>().having(
          (e) => e.message,
          'message',
          '復元する購入が見つかりません',
        )),
        reason: '非アクティブなサブスクリプションは復元対象外であること',
      );
    });

    test('TC-RES-E005: 部分的復元失敗時の状態管理', () async {
      // Arrange - 部分的な復元失敗をシミュレート
      mockPurchases.setShouldThrowError(true);

      // 初期状態設定
      final initialState = billingService.isPremium;

      // Act - 復元試行（失敗する）
      try {
        await billingService.restorePurchases();
      } catch (e) {
        // エラーを期待
      }

      // Assert - 失敗後の状態確認
      expect(billingService.isPremium, initialState, 
             reason: '復元失敗時は元の状態を維持すること');
    });
  });

  group('復元機能 - 統合テスト', () {
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

    test('TC-RES-I001: アプリ再インストール後の完全復元フロー', () async {
      // Arrange - アプリ再インストール後の状態をシミュレート
      expect(billingService.isPremium, false, reason: '初期状態は無料プラン');

      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 復元実行
      final restored = await billingService.restorePurchases();

      // Assert - 完全復元の確認
      expect(restored, true, reason: '復元処理が成功すること');
      expect(billingService.isPremium, true, reason: 'プレミアム状態が復元されること');
      expect(await billingService.canCreateGoal(50), true, 
             reason: 'すべての機能が利用可能になること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示が正しく更新されること');
    });

    test('TC-RES-I002: 機種変更時の復元フロー', () async {
      // Arrange - 機種変更後の初回起動をシミュレート
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(2);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act - 機種変更後の復元
      await billingService.restorePurchases();

      // Assert - 機種変更復元の確認
      expect(billingService.isTrial, true, reason: 'トライアル状態が復元されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(1), 
             reason: '残りトライアル期間が維持されること');
    });
  });
}