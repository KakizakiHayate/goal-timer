// test/billing/revenue_cat/lifecycle_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('8. RevenueCat連携テスト - ライフサイクル管理', () {
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

    test('TC-RC-009: アプリ起動時の自動同期', () async {
      // Arrange - アプリ起動時の状態設定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - アプリ起動時の初期化処理
      await billingService.initialize();

      // Assert - 起動時の自動同期確認
      expect(billingService.isPremium, true, 
             reason: 'アプリ起動時にRevenueCatから状態が取得されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示が正しく初期化されること');

      // 同期時刻が記録されることを確認
      final syncTime = billingService.getLastSyncTime();
      expect(syncTime, isNotNull, 
             reason: '初期化時の同期時刻が記録されること');
    });

    test('TC-RC-010: アプリ復帰時の差分同期', () async {
      // Arrange - アプリがバックグラウンドにいる間に状態変更
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 初期状態：トライアル
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(5);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();
      
      expect(billingService.isTrial, true);
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(4));

      // バックグラウンド中の状態変更をシミュレート（プレミアムに移行）
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - アプリ復帰時の同期処理
      await billingService.syncOnAppResume();
      // デバウンス待機
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - 差分同期の確認
      expect(billingService.isTrial, false, 
             reason: 'アプリ復帰時にトライアル→プレミアム変更が検出されること');
      expect(billingService.isPremium, true, 
             reason: 'プレミアム状態に正しく更新されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示も更新されること');
    });

    test('TC-RC-011: バックグラウンド処理中の状態保持', () async {
      // Arrange - アクティブ状態でプレミアム
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // Act - バックグラウンド状態をシミュレート（ネットワークが不安定）
      mockConnectivity.setConnectivity(ConnectivityResult.mobile);
      mockPurchases.setShouldThrowError(true); // ネットワークエラー

      // バックグラウンド中の同期試行
      await billingService.syncOnAppResume();

      // Assert - エラー時も状態が保持されること
      expect(billingService.isPremium, true, 
             reason: 'バックグラウンド処理失敗時も状態が保持されること');
      expect(await billingService.canCreateGoal(10), true, 
             reason: 'プレミアム機能が継続利用可能であること');
    });

    test('TC-RC-012: 長時間バックグラウンド後の完全同期', () async {
      // Arrange - 長時間バックグラウンド状態をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 初期状態：トライアル（7日）
      final initialTrialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(initialTrialCustomerInfo);
      await billingService.initialize();
      
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(6));

      // 長時間経過をシミュレート（トライアル期間減少）
      final updatedTrialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(2);
      mockPurchases.setCustomerInfo(updatedTrialCustomerInfo);

      // Act - 長時間後のアプリ復帰同期
      await billingService.syncOnAppResume();
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - 完全同期の確認
      expect(billingService.isTrial, true, 
             reason: 'トライアル状態が維持されること');
      expect(billingService.trialDaysLeft, lessThan(6), 
             reason: '残り日数が正しく更新されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(1), 
             reason: '更新された残り日数が反映されること');
    });

    test('TC-RC-013: アプリ終了時のクリーンアップ', () async {
      // Arrange - アクティブな同期処理がある状態
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // 複数の同期処理を開始
      billingService.syncOnAppResume();
      billingService.syncOnAppResume();
      billingService.syncOnAppResume();

      // Act - アプリ終了時のクリーンアップ
      billingService.dispose();

      // Assert - クリーンアップが正常に実行されること
      expect(() => billingService.dispose(), returnsNormally, 
             reason: 'dispose処理が正常に完了すること');
      
      // 追加のdisposeも安全に実行できること
      expect(() => billingService.dispose(), returnsNormally, 
             reason: '重複dispose処理も安全に実行されること');
    });
  });

  group('RevenueCatライフサイクル - 復帰シナリオ', () {
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

    test('TC-RC-L001: コールドスタート復帰', () async {
      // Arrange - アプリが完全に終了された状態から復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - コールドスタート（完全初期化）
      await billingService.initialize();

      // Assert - コールドスタート時の状態確認
      expect(billingService.isPremium, true, 
             reason: 'コールドスタート時にRevenueCatから状態取得');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示が正しく初期化されること');

      // 初回同期時刻が記録されることを確認
      final syncTime = billingService.getLastSyncTime();
      expect(syncTime, isNotNull, 
             reason: 'コールドスタート時の同期時刻が記録されること');
    });

    test('TC-RC-L002: ウォームスタート復帰', () async {
      // Arrange - アプリが一時停止状態から復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(3);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      
      // 初期化（ウォーム状態を作成）
      await billingService.initialize();
      expect(billingService.isTrial, true);
      
      final firstSyncTime = billingService.getLastSyncTime()!;

      // バックグラウンド中の変更（トライアル期間減少）
      final updatedTrialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(2);
      mockPurchases.setCustomerInfo(updatedTrialCustomerInfo);

      // Act - ウォームスタート復帰（アプリ復帰同期）
      await billingService.syncOnAppResume();
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - ウォームスタート復帰の確認
      expect(billingService.isTrial, true, 
             reason: 'トライアル状態が維持されること');
      expect(billingService.trialDaysLeft, lessThan(3), 
             reason: '変更された残り日数が反映されること');
      
      final secondSyncTime = billingService.getLastSyncTime()!;
      expect(secondSyncTime.isAfter(firstSyncTime), true, 
             reason: '復帰時に新しい同期時刻が記録されること');
    });

    test('TC-RC-L003: 機内モード復帰時の処理', () async {
      // Arrange - 機内モードからの復帰をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // 機内モード状態
      mockConnectivity.setConnectivity(ConnectivityResult.none);

      // Act - 機内モードから復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      await billingService.syncOnAppResume();
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - 機内モード復帰後の同期確認
      expect(billingService.isPremium, true, 
             reason: '機内モード復帰時にプレミアム状態が維持されること');
      
      final syncTime = billingService.getLastSyncTime();
      expect(syncTime, isNotNull, 
             reason: 'オンライン復帰時に同期が実行されること');
    });
  });

  group('RevenueCatライフサイクル - エラー処理', () {
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

    test('TC-RC-E001: 起動時同期失敗の処理', () async {
      // Arrange - 起動時にRevenueCat接続失敗
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act - エラー状態での初期化
      try {
        await billingService.initialize();
      } catch (e) {
        // エラーを期待
      }

      // Assert - 初期化失敗時のフォールバック確認
      expect(billingService.isPremium, false, 
             reason: '初期化失敗時は無料プランとして動作');
      expect(billingService.planDisplay, '無料プラン', 
             reason: 'デフォルト状態が正しく設定されること');
      expect(await billingService.canCreateGoal(3), false, 
             reason: '制限機能が適切に適用されること');
    });

    test('TC-RC-E002: 復帰時同期失敗後の回復', () async {
      // Arrange - 正常な初期化後、復帰時にエラー
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // 復帰時のエラー設定
      mockPurchases.setShouldThrowError(true);

      // Act - エラー状態での復帰同期
      await billingService.syncOnAppResume();

      // Assert - エラー時も既存状態を維持
      expect(billingService.isPremium, true, 
             reason: '復帰時同期失敗でもキャッシュ状態を維持');

      // エラー解除後の自動回復確認
      mockPurchases.setShouldThrowError(false);
      await billingService.syncWithRevenueCat();

      expect(billingService.isPremium, true, 
             reason: 'エラー解除後に正常に回復すること');
    });

    test('TC-RC-E003: 長期間オフライン後の復帰', () async {
      // Arrange - 長期間オフライン状態をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      expect(billingService.isTrial, true);

      // 長期間オフライン（期間中に状態変更）
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      
      // オフライン中の状態変更（期限切れ）
      final expiredCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(expiredCustomerInfo);

      // Act - 長期オフライン後のオンライン復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      await billingService.syncOnAppResume();
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - 長期オフライン復帰時の状態更新確認
      expect(billingService.isTrial, false, 
             reason: 'オンライン復帰時に期限切れが検出されること');
      expect(billingService.isPremium, false, 
             reason: '無料プランに正しく戻ること');
      expect(billingService.planDisplay, '無料プラン', 
             reason: 'プラン表示も正しく更新されること');
    });
  });

  group('RevenueCatライフサイクル - パフォーマンス', () {
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

    test('TC-RC-P001: アプリ起動時の同期速度', () async {
      // Arrange - 起動時同期のパフォーマンステスト
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - アプリ起動時の初期化
      await billingService.initialize();
      stopwatch.stop();

      // Assert - 起動時同期が高速であること
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
             reason: 'アプリ起動時の初期化が1秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '高速初期化でも正しい状態が取得されること');
    });

    test('TC-RC-P002: 頻繁なアプリ復帰時のデバウンス効率', () async {
      // Arrange - 頻繁な復帰をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      final stopwatch = Stopwatch()..start();

      // Act - 頻繁な復帰同期（デバウンスでブロックされる）
      for (int i = 0; i < 10; i++) {
        await billingService.syncOnAppResume();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      stopwatch.stop();

      // Assert - デバウンス機能により効率的に処理されること
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
             reason: '頻繁な復帰処理がデバウンスにより効率化されること');
      expect(billingService.isPremium, true, 
             reason: 'デバウンス機能でも状態が正しく維持されること');
    });
  });
}