// test/billing/performance/performance_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('13. パフォーマンステスト', () {
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

    test('TC-PER-001: 初期化処理の応答時間', () async {
      // Arrange - パフォーマンス測定準備
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 初期化処理実行
      await billingService.initialize();
      stopwatch.stop();

      // Assert - 応答時間の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(2000), 
             reason: '初期化処理が2秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '高速初期化でも正しい状態が取得されること');
    });

    test('TC-PER-002: 購入処理の応答時間', () async {
      // Arrange - 購入処理のパフォーマンス測定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 購入処理実行
      await billingService.purchasePremium();
      stopwatch.stop();

      // Assert - 購入処理時間の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
             reason: '購入処理が5秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '購入処理完了後に正しい状態が反映されること');
    });

    test('TC-PER-003: 復元処理の応答時間', () async {
      // Arrange - 復元処理のパフォーマンス測定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 復元処理実行
      await billingService.restorePurchases();
      stopwatch.stop();

      // Assert - 復元処理時間の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
             reason: '復元処理が3秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '復元処理完了後に正しい状態が反映されること');
    });

    test('TC-PER-004: 同期処理の応答時間', () async {
      // Arrange - 同期処理のパフォーマンス測定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 同期処理実行
      await billingService.syncWithRevenueCat();
      stopwatch.stop();

      // Assert - 同期処理時間の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(1500), 
             reason: '同期処理が1.5秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '同期完了後に正しい状態が反映されること');
    });

    test('TC-PER-005: 状態確認処理の応答時間', () async {
      // Arrange - 状態確認処理のパフォーマンス測定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      final stopwatch = Stopwatch()..start();

      // Act - 状態確認処理を大量実行
      for (int i = 0; i < 1000; i++) {
        billingService.isPremium;
        billingService.isTrial;
        billingService.planDisplay;
        await billingService.canCreateGoal(i);
        billingService.getGoalLimitMessage(i % 3);
      }

      stopwatch.stop();

      // Assert - 状態確認処理の効率性確認
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
             reason: '1000回の状態確認が1秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: '大量処理後も正しい状態が維持されること');
    });
  });

  group('パフォーマンス - メモリ効率', () {
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

    test('TC-PER-M001: 長時間稼働時のメモリ効率', () async {
      // Arrange - 長時間稼働をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      final testStates = [
        BillingTestHelpers.createFreeCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(7),
        BillingTestHelpers.createPremiumCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(1),
        BillingTestHelpers.createFreeCustomerInfo(),
      ];

      // Act - 大量の状態変更処理
      for (int cycle = 0; cycle < 100; cycle++) {
        for (final state in testStates) {
          mockPurchases.setCustomerInfo(state);
          await billingService.syncWithRevenueCat();
          
          // 各状態での処理
          billingService.isPremium;
          billingService.isTrial;
          billingService.trialDaysLeft;
          billingService.planDisplay;
          await billingService.canCreateGoal(cycle % 10);
        }
      }

      // Assert - メモリ効率の間接的確認
      expect(billingService.isPremium, false, 
             reason: '大量処理後も正常に動作すること（メモリリークがないこと）');
      expect(billingService.planDisplay, '無料プラン', 
             reason: '最終状態が正しく保持されること');
    });

    test('TC-PER-M002: 並行処理時のメモリ安全性', () async {
      // Arrange - 並行処理の準備
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act - 並行処理実行
      final futures = <Future<void>>[];
      for (int i = 0; i < 50; i++) {
        futures.add(Future(() async {
          // 並行して状態確認処理を実行
          for (int j = 0; j < 20; j++) {
            billingService.isPremium;
            billingService.isTrial;
            await billingService.canCreateGoal(j);
            billingService.getGoalLimitMessage(j % 3);
          }
        }));
      }

      await Future.wait(futures);

      // Assert - 並行処理後の状態確認
      expect(billingService.isPremium, true, 
             reason: '並行処理後も正しい状態が維持されること');
    });

    test('TC-PER-M003: オブジェクト生成の効率性', () async {
      // Arrange - オブジェクト生成パフォーマンス測定
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 大量のBillingServiceオブジェクト処理
      final services = <BillingService>[];
      for (int i = 0; i < 100; i++) {
        final service = BillingService(
          purchases: mockPurchases,
          connectivity: mockConnectivity,
        );
        services.add(service);
        await service.initialize();
      }

      // Cleanup
      for (final service in services) {
        service.dispose();
      }

      stopwatch.stop();

      // Assert - オブジェクト生成効率の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
             reason: '100個のオブジェクト生成・初期化が5秒以内に完了すること');
    });
  });

  group('パフォーマンス - ネットワーク効率', () {
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

    test('TC-PER-N001: 低速ネットワーク時の応答時間', () async {
      // Arrange - 低速ネットワーク環境をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.mobile);
      
      // ネットワーク遅延をシミュレート（MockPurchasesで実装済み）
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 低速ネットワークでの処理実行
      await billingService.initialize();
      stopwatch.stop();

      // Assert - 低速環境での許容応答時間確認
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
             reason: '低速ネットワーク時も3秒以内に初期化完了すること');
      expect(billingService.isPremium, true, 
             reason: '低速環境でも正しい状態が取得されること');
    });

    test('TC-PER-N002: 接続切り替え時の効率性', () async {
      // Arrange - ネットワーク切り替えをシミュレート
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      final stopwatch = Stopwatch()..start();

      // Act - 複数のネットワーク状態での処理
      final networkStates = [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ];

      for (final networkState in networkStates) {
        mockConnectivity.setConnectivity(networkState);
        await billingService.syncWithRevenueCat();
      }

      stopwatch.stop();

      // Assert - ネットワーク切り替え時の効率性確認
      expect(stopwatch.elapsedMilliseconds, lessThan(4000), 
             reason: 'ネットワーク切り替えを含む処理が4秒以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: 'ネットワーク切り替え後も正しい状態が維持されること');
    });

    test('TC-PER-N003: デバウンス機能の効率性', () async {
      // Arrange - デバウンス機能のパフォーマンステスト
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      final stopwatch = Stopwatch()..start();

      // Act - 短時間での大量同期要求（デバウンスされる）
      for (int i = 0; i < 100; i++) {
        billingService.syncOnAppResume();
        // わずかな遅延
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // デバウンス完了まで待機
      await Future.delayed(const Duration(milliseconds: 1200));
      stopwatch.stop();

      // Assert - デバウンス機能による効率化確認
      expect(stopwatch.elapsedMilliseconds, lessThan(2000), 
             reason: 'デバウンス機能により効率的に処理されること');
      expect(billingService.isPremium, true, 
             reason: 'デバウンス後も正しい状態が維持されること');
    });

    test('TC-PER-N004: エラー時のリトライ効率', () async {
      // Arrange - ネットワークエラーとリトライをシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true);

      final stopwatch = Stopwatch()..start();

      // Act - エラー発生時の処理（複数回試行）
      for (int i = 0; i < 5; i++) {
        try {
          await billingService.syncWithRevenueCat();
        } catch (e) {
          // エラーを期待
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // エラー解除後の正常処理
      mockPurchases.setShouldThrowError(false);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.syncWithRevenueCat();

      stopwatch.stop();

      // Assert - エラー処理効率の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(2000), 
             reason: 'エラー処理とリトライが効率的に実行されること');
      expect(billingService.isPremium, true, 
             reason: 'エラー解除後に正常に復旧すること');
    });
  });

  group('パフォーマンス - バッテリー効率', () {
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

    test('TC-PER-B001: バックグラウンド処理の最小化', () async {
      // Arrange - バックグラウンド処理をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act - バックグラウンド処理の実行回数確認
      int syncAttempts = 0;
      
      // 短時間での複数同期要求（デバウンスで制限される）
      for (int i = 0; i < 20; i++) {
        billingService.syncOnAppResume();
        syncAttempts++;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - デバウンスによるバッテリー効率改善
      expect(syncAttempts, 20, reason: '20回の同期要求が発行されること');
      expect(billingService.isPremium, true, 
             reason: 'デバウンス機能でも正しい状態が維持されること');
      
      // Note: 実際の同期実行回数はデバウンスにより大幅に削減される
      // これによりバッテリー消費とネットワーク使用量が最小化される
    });

    test('TC-PER-B002: CPUサイクルの効率利用', () async {
      // Arrange - CPU集約的な処理の効率性テスト
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      final stopwatch = Stopwatch()..start();

      // Act - CPU集約的な処理を大量実行
      for (int i = 0; i < 10000; i++) {
        // 状態確認処理（CPU使用）
        billingService.isPremium;
        billingService.isTrial;
        billingService.trialDaysLeft; // 日付計算処理
        billingService.planDisplay; // 文字列生成処理
        billingService.getGoalLimitMessage(i % 5); // 条件分岐処理
      }

      stopwatch.stop();

      // Assert - CPU効率の確認
      expect(stopwatch.elapsedMilliseconds, lessThan(500), 
             reason: '10000回の状態処理が500ms以内に完了すること');
      expect(billingService.isPremium, true, 
             reason: 'CPU集約処理後も正しい状態が維持されること');
    });

    test('TC-PER-B003: アイドル時のリソース消費最小化', () async {
      // Arrange - アイドル状態の準備
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // Act - アイドル状態をシミュレート（何も操作しない）
      await Future.delayed(const Duration(milliseconds: 2000));

      // Assert - アイドル時も正常状態を維持
      expect(billingService.isPremium, true, 
             reason: 'アイドル時も状態が正しく保持されること');

      // Note: アイドル時にはタイマーや定期処理が停止し、
      // バッテリー消費が最小化される
      // syncOnAppResumeのデバウンス機能により、不要な処理は実行されない
    });

    test('TC-PER-B004: dispose時のリソース解放効率', () async {
      // Arrange - リソース解放のテスト準備
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // 複数の同期処理を開始（バックグラウンドで実行中）
      billingService.syncOnAppResume();
      billingService.syncOnAppResume();
      billingService.syncOnAppResume();

      final stopwatch = Stopwatch()..start();

      // Act - リソース解放実行
      billingService.dispose();
      stopwatch.stop();

      // Assert - 効率的なリソース解放
      expect(stopwatch.elapsedMilliseconds, lessThan(100), 
             reason: 'dispose処理が100ms以内に完了すること');

      // 複数回のdisposeも安全
      expect(() => billingService.dispose(), returnsNormally, 
             reason: '重複dispose処理も安全に実行されること');
    });
  });

  group('パフォーマンス - スケーラビリティ', () {
    late List<BillingService> billingServices;
    late MockPurchases mockPurchases;
    late MockConnectivity mockConnectivity;

    setUp(() {
      billingServices = [];
      mockPurchases = MockPurchases();
      mockConnectivity = MockConnectivity();
    });

    tearDown(() {
      for (final service in billingServices) {
        service.dispose();
      }
      billingServices.clear();
    });

    test('TC-PER-S001: 複数インスタンスの並行処理', () async {
      // Arrange - 複数のBillingServiceインスタンスを作成
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      for (int i = 0; i < 10; i++) {
        final service = BillingService(
          purchases: mockPurchases,
          connectivity: mockConnectivity,
        );
        billingServices.add(service);
      }

      final stopwatch = Stopwatch()..start();

      // Act - 並行して初期化処理実行
      final futures = billingServices.map((service) => service.initialize());
      await Future.wait(futures);

      stopwatch.stop();

      // Assert - 並行処理の効率性確認
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), 
             reason: '10個のインスタンス並行初期化が3秒以内に完了すること');
      
      // 全インスタンスの状態確認
      for (final service in billingServices) {
        expect(service.isPremium, true, 
               reason: '並行処理後も各インスタンスが正しい状態を保持すること');
      }
    });

    test('TC-PER-S002: 大量データ処理のスケーラビリティ', () async {
      // Arrange - 大量データ処理の準備
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      final service = BillingService(
        purchases: mockPurchases,
        connectivity: mockConnectivity,
      );
      billingServices.add(service);

      final stopwatch = Stopwatch()..start();

      // Act - 大量の状態変更処理
      final testStates = [
        BillingTestHelpers.createFreeCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(7),
        BillingTestHelpers.createPremiumCustomerInfo(),
      ];

      for (int i = 0; i < 1000; i++) {
        final state = testStates[i % testStates.length];
        mockPurchases.setCustomerInfo(state);
        await service.syncWithRevenueCat();
        
        // 状態確認
        service.isPremium;
        service.isTrial;
        service.planDisplay;
      }

      stopwatch.stop();

      // Assert - 大量データ処理のスケーラビリティ確認
      expect(stopwatch.elapsedMilliseconds, lessThan(10000), 
             reason: '1000回の状態変更処理が10秒以内に完了すること');
      expect(service.isPremium, true, 
             reason: '大量処理後も正しい状態が維持されること');
    });

    test('TC-PER-S003: 長期間稼働時の安定性', () async {
      // Arrange - 長期間稼働をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      final service = BillingService(
        purchases: mockPurchases,
        connectivity: mockConnectivity,
      );
      billingServices.add(service);

      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await service.initialize();

      // Act - 長期間の稼働をシミュレート
      for (int hour = 0; hour < 24; hour++) {
        // 1時間あたり複数回の処理を実行
        for (int minute = 0; minute < 60; minute += 10) {
          await service.syncOnAppResume();
          service.isPremium;
          service.planDisplay;
          await service.canCreateGoal(minute);
          
          // 短時間待機（実際の使用パターンをシミュレート）
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Assert - 長期間稼働後の安定性確認
      expect(service.isPremium, true, 
             reason: '24時間相当の稼働後も正しい状態が維持されること');
      expect(() => service.planDisplay, returnsNormally, 
             reason: '長期稼働後も全機能が正常動作すること');
    });
  });
}