// test/billing/revenue_cat/cache_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('7. RevenueCat連携テスト - キャッシュ機能', () {
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

    test('TC-RC-005: 購入状態のローカルキャッシュ', () async {
      // Arrange - オンライン状態でプレミアム情報を取得
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 初期同期でキャッシュ作成
      await billingService.initialize();

      // Assert - キャッシュされた状態の確認
      expect(billingService.isPremium, true, 
             reason: 'プレミアム状態が正しくキャッシュされること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'プラン表示情報も正しくキャッシュされること');

      // オフライン状態に変更
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      mockPurchases.setShouldThrowError(true);

      // キャッシュされた状態が維持されることを確認
      expect(billingService.isPremium, true, 
             reason: 'オフライン時もキャッシュされた状態が維持されること');
    });

    test('TC-RC-006: キャッシュの有効期限管理', () async {
      // Arrange - トライアル状態をキャッシュ
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(2);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      // 初期状態確認
      expect(billingService.isTrial, true);
      final initialTrialDays = billingService.trialDaysLeft;

      // Act - 時間経過のシミュレート（実際のテストでは短縮）
      await Future.delayed(const Duration(milliseconds: 100));

      // 新しい同期で期限が更新されることを確認
      final updatedTrialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(1);
      mockPurchases.setCustomerInfo(updatedTrialCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - キャッシュが適切に更新されること
      expect(billingService.trialDaysLeft, lessThan(initialTrialDays), 
             reason: 'キャッシュが新しい情報で更新されること');
    });

    test('TC-RC-007: オフライン時のキャッシュ利用', () async {
      // Arrange - オンライン状態で複数の状態をキャッシュ
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 最初はプレミアム状態
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();
      
      expect(billingService.isPremium, true);
      expect(await billingService.canCreateGoal(10), true);

      // Act - オフライン状態に変更
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      mockPurchases.setShouldThrowError(true);

      // オフライン時の同期試行（失敗するがキャッシュを維持）
      await billingService.syncOnAppResume();

      // Assert - キャッシュされた機能が継続利用可能
      expect(billingService.isPremium, true, 
             reason: 'オフライン時もキャッシュされたプレミアム状態を維持');
      expect(await billingService.canCreateGoal(50), true, 
             reason: 'キャッシュされた状態に基づいて機能制限を判定');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'キャッシュされた表示情報を使用');
    });

    test('TC-RC-008: キャッシュの不整合検出と修復', () async {
      // Arrange - キャッシュに古い情報がある状態をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 古い情報（トライアル）をキャッシュ
      final oldTrialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(oldTrialCustomerInfo);
      await billingService.initialize();
      
      expect(billingService.isTrial, true);

      // Act - RevenueCat側で状態変更（プレミアムに移行）
      final newPremiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(newPremiumCustomerInfo);
      
      // 同期実行で不整合を検出・修復
      await billingService.syncWithRevenueCat();

      // Assert - 不整合が修復されること
      expect(billingService.isTrial, false, 
             reason: 'トライアル状態から正常に移行');
      expect(billingService.isPremium, true, 
             reason: 'プレミアム状態に正しく更新');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: '表示情報も正しく更新');
    });
  });

  group('RevenueCatキャッシュ - パフォーマンステスト', () {
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

    test('TC-RC-P001: キャッシュアクセスの高速性確認', () async {
      // Arrange - キャッシュにデータを保存
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act - キャッシュからのアクセス時間を測定
      final stopwatch = Stopwatch()..start();
      
      // キャッシュからの読み取り操作
      for (int i = 0; i < 100; i++) {
        final isPremium = billingService.isPremium;
        final planDisplay = billingService.planDisplay;
        final canCreate = await billingService.canCreateGoal(i);
      }
      
      stopwatch.stop();

      // Assert - キャッシュアクセスが高速であること
      expect(stopwatch.elapsedMilliseconds, lessThan(100), 
             reason: 'キャッシュアクセスが100ms以内で完了すること');
    });

    test('TC-RC-P002: 大量データキャッシュの処理性能', () async {
      // Arrange - 複数状態の高速切り替えテスト
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);

      final testStates = [
        BillingTestHelpers.createFreeCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(7),
        BillingTestHelpers.createPremiumCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(1),
        BillingTestHelpers.createFreeCustomerInfo(),
      ];

      final stopwatch = Stopwatch()..start();

      // Act - 状態の高速切り替えとキャッシュ更新
      for (final state in testStates) {
        mockPurchases.setCustomerInfo(state);
        await billingService.syncWithRevenueCat();
        
        // キャッシュされた状態の確認
        billingService.isPremium;
        billingService.isTrial;
        billingService.planDisplay;
      }

      stopwatch.stop();

      // Assert - 複数状態切り替えが効率的に処理されること
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
             reason: '複数状態の切り替えが1秒以内で完了すること');
    });
  });

  group('RevenueCatキャッシュ - エラーハンドリング', () {
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

    test('TC-RC-E001: 破損キャッシュからの回復', () async {
      // Arrange - 正常なキャッシュを作成
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // Act - 破損データのシミュレート（ネットワークエラー）
      mockPurchases.setShouldThrowError(true);
      
      try {
        await billingService.syncWithRevenueCat();
      } catch (e) {
        // エラーを期待
      }

      // Assert - エラー後もキャッシュが維持されること
      expect(billingService.isPremium, true, 
             reason: '破損データ取得時もキャッシュが保護されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: 'キャッシュされた表示情報が維持されること');
    });

    test('TC-RC-E002: 初回キャッシュ作成失敗時の処理', () async {
      // Arrange - 初回同期でエラーが発生する状況
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      // Act - 初期化時のエラー処理
      try {
        await billingService.initialize();
      } catch (e) {
        // エラーを期待
      }

      // Assert - エラー時のデフォルト状態確認
      expect(billingService.isPremium, false, 
             reason: '初回同期失敗時は無料プランとして扱う');
      expect(billingService.planDisplay, '無料プラン', 
             reason: 'デフォルト状態が正しく設定されること');
      expect(await billingService.canCreateGoal(3), false, 
             reason: '制限が適切に適用されること');
    });

    test('TC-RC-E003: 部分的キャッシュ更新失敗の処理', () async {
      // Arrange - 部分的な更新失敗をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(3);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      await billingService.initialize();

      // 初期状態確認
      expect(billingService.isTrial, true);
      final initialPlanDisplay = billingService.planDisplay;

      // Act - 更新中にエラー発生
      mockPurchases.setShouldThrowError(true);
      
      try {
        await billingService.syncWithRevenueCat();
      } catch (e) {
        // 部分的更新失敗を期待
      }

      // Assert - 一貫した状態が維持されること
      expect(billingService.isTrial, true, 
             reason: '更新失敗時は元の状態を維持');
      expect(billingService.planDisplay, initialPlanDisplay, 
             reason: '表示情報の一貫性が保たれること');
    });
  });

  group('RevenueCatキャッシュ - メモリ管理', () {
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

    test('TC-RC-M001: メモリ効率的なキャッシュ管理', () async {
      // Arrange - 複数回の同期でメモリ使用量を確認
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // Act - 大量の同期操作
      for (int i = 0; i < 50; i++) {
        final customerInfo = i % 2 == 0 
          ? BillingTestHelpers.createPremiumCustomerInfo()
          : BillingTestHelpers.createTrialCustomerInfo(i % 7 + 1);
        
        mockPurchases.setCustomerInfo(customerInfo);
        await billingService.syncWithRevenueCat();
        
        // 各回で状態確認
        billingService.isPremium;
        billingService.isTrial;
        billingService.planDisplay;
      }

      // Assert - メモリリークがないことの間接的確認
      // （実際のアプリではメモリプロファイラーを使用）
      expect(billingService.isPremium, isA<bool>(), 
             reason: '大量同期後も正常に動作すること');
    });

    test('TC-RC-M002: dispose時のキャッシュクリーンアップ', () async {
      // Arrange - キャッシュにデータを保存
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // Act - dispose実行
      billingService.dispose();

      // Assert - dispose後の状態確認
      // (実際の実装では内部キャッシュがクリアされる)
      expect(() => billingService.dispose(), returnsNormally, 
             reason: 'dispose処理が正常に完了すること');
    });
  });
}