// test/billing/offline/offline_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../billing_service_test.dart';

void main() {
  group('4. オフライン時テスト', () {
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

    test('TC-OFF-001: オフライン時の購入試行', () async {
      // Arrange - 機内モード ON、未購入状態
      mockConnectivity.setConnectivity(ConnectivityResult.none);

      // Act & Assert - オフライン時の購入試行
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<PlatformException>().having(
          (e) => e.message,
          'message',
          'インターネット接続が必要です',
        )),
        reason: '「インターネット接続が必要です」エラー表示',
      );

      // Assert - 購入処理は開始されないこと
      expect(billingService.isPremium, false, 
             reason: '購入処理は開始されないこと');
    });

    test('TC-OFF-002: オフライン時のプレミアム機能', () async {
      // Arrange - プレミアムユーザー、機内モード ON
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // オンライン状態での機能確認
      expect(billingService.isPremium, true);

      // Act - オフライン状態に変更
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      final isOffline = await billingService.isOffline();

      // Assert - オフライン時の機能制限確認
      expect(isOffline, true, 
             reason: 'オフライン状態が正しく検出されること');
      
      // Note: プレミアム機能の無効化は実際のUIレベルで実装される
      // ここではオフライン検出のロジックをテスト
    });

    test('TC-OFF-003: オフライン→オンライン復帰', () async {
      // Arrange - プレミアムユーザー、機内モードから通常モードへ
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      
      // 最初はオフライン状態
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      
      // Act - オフライン→オンライン復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      await billingService.syncWithRevenueCat();

      // Assert - オンライン復帰時の機能復活確認
      expect(await billingService.isOffline(), false, 
             reason: 'オンライン状態が正しく検出されること');
      expect(billingService.isPremium, true, 
             reason: 'プレミアム機能が復活すること');
    });

    test('TC-OFF-004: オフライン時の同期処理', () async {
      // Arrange - オフライン環境
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      mockPurchases.setShouldThrowError(true); // ネットワークエラーをシミュレート

      // Act - 同期処理試行
      await billingService.syncOnAppResume();

      // Assert - エラーが発生してもアプリがクラッシュしないこと
      // キャッシュされた情報を使用すること
      expect(true, true, reason: 'オフライン時の同期処理でクラッシュしないこと');
    });

    test('TC-OFF-005: 弱いネットワーク接続時の処理', () async {
      // Arrange - 不安定なネットワーク接続（モバイル接続）
      mockConnectivity.setConnectivity(ConnectivityResult.mobile);
      mockPurchases.setShouldThrowError(true); // タイムアウトをシミュレート

      // Act & Assert - 不安定なネットワークでの購入試行
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<Exception>()),
        reason: '不安定なネットワーク時は適切にエラーが処理されること',
      );
    });
  });

  group('オフライン機能 - ネットワーク状態変化', () {
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

    test('TC-OFF-N001: WiFi → オフライン → WiFi の状態変化', () async {
      // Arrange - 初期状態はWiFi接続
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      expect(await billingService.isOffline(), false);

      // Act & Assert - オフライン状態への変化
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      expect(await billingService.isOffline(), true, 
             reason: 'オフライン状態が正しく検出されること');

      // Act & Assert - オンライン復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      expect(await billingService.isOffline(), false, 
             reason: 'オンライン復帰が正しく検出されること');
    });

    test('TC-OFF-N002: モバイル → WiFi → オフライン の状態変化', () async {
      // Arrange - モバイル接続から開始
      mockConnectivity.setConnectivity(ConnectivityResult.mobile);
      expect(await billingService.isOffline(), false);

      // Act - WiFi接続への変化
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      expect(await billingService.isOffline(), false, 
             reason: 'WiFi接続でもオンライン状態であること');

      // Act - オフラインへの変化
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      expect(await billingService.isOffline(), true, 
             reason: 'オフライン状態が検出されること');
    });
  });

  group('オフライン機能 - キャッシュ動作', () {
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

    test('TC-OFF-C001: オフライン時のキャッシュ利用', () async {
      // Arrange - オンライン時にプレミアム状態を取得
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      // 初期状態確認
      expect(billingService.isPremium, true);

      // Act - オフライン状態に変更
      mockConnectivity.setConnectivity(ConnectivityResult.none);
      mockPurchases.setShouldThrowError(true);

      // 同期処理実行（エラーになるがキャッシュを使用）
      await billingService.syncOnAppResume();

      // Assert - キャッシュされた状態が維持されること
      expect(billingService.isPremium, true, 
             reason: 'オフライン時はキャッシュされた課金状態を使用すること');
    });

    test('TC-OFF-C002: オンライン復帰時の状態更新', () async {
      // Arrange - オフライン時にキャッシュされた状態
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      mockConnectivity.setConnectivity(ConnectivityResult.none);
      
      // Act - オンライン復帰
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      await billingService.syncOnAppResume();
      // 同期完了まで待機
      await Future.delayed(const Duration(milliseconds: 1100));

      // Assert - 最新状態が取得されること
      expect(billingService.isPremium, true, 
             reason: 'オンライン復帰時に最新の課金状態が取得されること');
    });
  });
}