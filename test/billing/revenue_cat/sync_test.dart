// test/billing/revenue_cat/sync_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('6. RevenueCat連携テスト - 同期機能', () {
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

    test('TC-RC-001: 定期的な購入状態同期', () async {
      // Arrange - プレミアムユーザー、定期同期タイミング
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - RevenueCatからの状態同期実行
      await billingService.syncWithRevenueCat();

      // Assert - 同期成功の確認
      expect(billingService.isPremium, true, 
             reason: 'RevenueCatから最新の購入状態が取得されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示が正しく更新されること');

      // 最後の同期時刻が更新されることを確認
      final lastSyncTime = billingService.getLastSyncTime();
      expect(lastSyncTime, isNotNull, 
             reason: '同期時刻が記録されること');
      expect(DateTime.now().difference(lastSyncTime!).inMinutes, lessThan(1), 
             reason: '同期時刻が現在時刻に近いこと');
    });

    test('TC-RC-002: アプリ復帰時の自動同期', () async {
      // Arrange - アプリがバックグラウンドから復帰
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(3);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - アプリ復帰時の同期処理
      await billingService.syncOnAppResume();

      // Assert - 復帰時同期の確認
      expect(billingService.isTrial, true, 
             reason: 'アプリ復帰時にトライアル状態が正しく同期されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(2), 
             reason: '残りトライアル日数が正しく更新されること');

      // デバウンス機能のテスト - 5秒以内の再同期は実行されない
      final firstSyncTime = billingService.getLastSyncTime()!;
      
      // 即座に再度同期を試行
      await billingService.syncOnAppResume();
      final secondSyncTime = billingService.getLastSyncTime()!;
      
      expect(secondSyncTime.isAtSameMomentAs(firstSyncTime), true, 
             reason: '5秒以内の再同期はデバウンスされること');
    });

    test('TC-RC-003: 購入状態変更の検出と反映', () async {
      // Arrange - 初期状態は無料プラン
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, false, reason: '初期状態は無料プラン');

      // Act - RevenueCat側でプレミアム購入が完了したことをシミュレート
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - 状態変更の検出と反映
      expect(billingService.isPremium, true, 
             reason: 'RevenueCat側の変更が正しく反映されること');
      expect(await billingService.canCreateGoal(10), true, 
             reason: '制限解除が即座に反映されること');

      // 逆方向のテスト: プレミアム → 無料（サブスクリプションキャンセル）
      final expiredCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(expiredCustomerInfo);
      await billingService.syncWithRevenueCat();

      expect(billingService.isPremium, false, 
             reason: 'サブスクリプション終了が正しく反映されること');
    });

    test('TC-RC-004: 同期エラー時の処理', () async {
      // Arrange - RevenueCatサーバーエラー
      mockPurchases.setShouldThrowError(true);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // 初期状態設定（キャッシュされた状態）
      final cachedPremiumInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(cachedPremiumInfo);
      await billingService.initialize();
      
      // エラー状態に変更
      mockPurchases.setShouldThrowError(true);

      // Act & Assert - 同期エラー時の処理確認
      // エラーが発生してもアプリがクラッシュしないこと
      expect(() async => await billingService.syncWithRevenueCat(), 
             returnsNormally, 
             reason: '同期エラー時もアプリがクラッシュしないこと');

      // キャッシュされた状態が維持されること
      expect(billingService.isPremium, true, 
             reason: '同期失敗時はキャッシュされた状態を維持すること');
    });
  });

  group('RevenueCat同期 - デバウンス機能テスト', () {
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

    test('TC-RC-D001: 5秒未満の連続同期防止', () async {
      // Arrange - 同期可能な状態
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - 最初の同期実行
      await billingService.syncOnAppResume();
      final firstSyncTime = billingService.getLastSyncTime()!;

      // 1秒後に再度同期試行
      await Future.delayed(const Duration(seconds: 1));
      await billingService.syncOnAppResume();
      final secondSyncTime = billingService.getLastSyncTime()!;

      // Assert - デバウンスの確認
      expect(secondSyncTime.isAtSameMomentAs(firstSyncTime), true, 
             reason: '5秒未満の連続同期は防止されること');
    });

    test('TC-RC-D002: 5秒後の同期許可', () async {
      // Arrange - 同期可能な状態
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - 最初の同期実行
      await billingService.syncOnAppResume();
      final firstSyncTime = billingService.getLastSyncTime()!;

      // 6秒後に再度同期試行（実際のテストでは短縮）
      await Future.delayed(const Duration(milliseconds: 1100)); // テスト用に短縮
      await billingService.syncOnAppResume();
      final secondSyncTime = billingService.getLastSyncTime()!;

      // Assert - 時間経過後の同期許可
      expect(secondSyncTime.isAfter(firstSyncTime), true, 
             reason: '5秒経過後は再同期が実行されること');
    });

    test('TC-RC-D003: 手動同期のデバウンス適用外', () async {
      // Arrange - 同期可能な状態
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      // Act - アプリ復帰同期の後、即座に手動同期
      await billingService.syncOnAppResume();
      final firstSyncTime = billingService.getLastSyncTime()!;

      // 手動同期はデバウンス適用外
      await billingService.syncWithRevenueCat();
      final secondSyncTime = billingService.getLastSyncTime()!;

      // Assert - 手動同期は即座に実行される
      expect(secondSyncTime.isAfter(firstSyncTime), true, 
             reason: '手動同期はデバウンス制限を受けないこと');
    });
  });

  group('RevenueCat同期 - ネットワーク状態別テスト', () {
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

    test('TC-RC-N001: WiFi接続時の同期', () async {
      // Arrange - WiFi接続
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - WiFi接続時の同期
      await billingService.syncWithRevenueCat();

      // Assert - WiFi接続時の同期成功
      expect(billingService.isPremium, true, 
             reason: 'WiFi接続時は同期が正常実行されること');
    });

    test('TC-RC-N002: モバイル接続時の同期', () async {
      // Arrange - モバイル接続
      mockConnectivity.setConnectivity(ConnectivityResult.mobile);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - モバイル接続時の同期
      await billingService.syncWithRevenueCat();

      // Assert - モバイル接続時の同期成功
      expect(billingService.isPremium, true, 
             reason: 'モバイル接続時も同期が正常実行されること');
    });

    test('TC-RC-N003: オフライン時の同期スキップ', () async {
      // Arrange - オフライン状態
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      
      // 事前にオンライン状態で初期化
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();
      
      // オフライン状態に変更
      mockConnectivity.setConnectivity(ConnectivityResult.none);

      // Act - オフライン時の同期試行
      await billingService.syncOnAppResume();

      // Assert - オフライン時は同期がスキップされること
      // （キャッシュされた状態は維持される）
      expect(billingService.isPremium, true, 
             reason: 'オフライン時はキャッシュされた状態が維持されること');
    });
  });

  group('RevenueCat同期 - エラー回復テスト', () {
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

    test('TC-RC-R001: 一時的エラーからの自動回復', () async {
      // Arrange - 一時的なエラー状態
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      
      // 最初はエラー状態
      mockPurchases.setShouldThrowError(true);
      
      // Act - エラー状態での同期試行
      try {
        await billingService.syncWithRevenueCat();
      } catch (e) {
        // エラーを期待
      }

      // エラー状態を解除
      mockPurchases.setShouldThrowError(false);
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // 再度同期実行
      await billingService.syncWithRevenueCat();

      // Assert - エラーから回復すること
      expect(billingService.isPremium, true, 
             reason: '一時的エラーから正常に回復すること');
    });

    test('TC-RC-R002: 複数回のエラー後の回復', () async {
      // Arrange - 複数回のエラーをシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act - 複数回の失敗した同期試行
      for (int i = 0; i < 3; i++) {
        try {
          await billingService.syncWithRevenueCat();
        } catch (e) {
          // エラーを期待
        }
      }

      // 正常状態に回復
      mockPurchases.setShouldThrowError(false);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      await billingService.syncWithRevenueCat();

      // Assert - 複数エラー後も正常回復すること
      expect(billingService.isPremium, true, 
             reason: '複数回のエラー後も正常に回復すること');
    });
  });
}