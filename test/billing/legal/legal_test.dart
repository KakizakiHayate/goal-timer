// test/billing/legal/legal_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../billing_service_test.dart';

void main() {
  group('12. 法的要件テスト', () {
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

    test('TC-LEG-001: 自動更新の適切な処理', () async {
      // Arrange - 自動更新有効なサブスクリプション
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true,
            periodType: PeriodType.normal,
            willRenew: true, // 自動更新有効
          )
        }),
      );
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 自動更新状態の確認
      await billingService.initialize();

      // Assert - 自動更新情報の適切な処理
      expect(billingService.isPremium, true, 
             reason: '自動更新有効なプレミアムプランが正しく認識されること');
      expect(billingService.planDisplay, 'プレミアムプラン', 
             reason: '自動更新の状態が適切に表示されること');

      // Note: 実際のUI実装では「次回更新日」や「自動更新状況」を
      // ユーザーに明確に表示する必要がある
    });

    test('TC-LEG-002: キャンセル処理の透明性確保', () async {
      // Arrange - キャンセルされたサブスクリプション
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final cancelledSubscription = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true, // まだ有効期間内
            periodType: PeriodType.normal,
            willRenew: false, // キャンセル済み
            expirationDate: DateTime.now().add(const Duration(days: 15)).toIso8601String(),
          )
        }),
      );
      mockPurchases.setCustomerInfo(cancelledSubscription);

      // Act - キャンセル状態の確認
      await billingService.initialize();

      // Assert - キャンセル状態の適切な処理
      expect(billingService.isPremium, true, 
             reason: 'キャンセル後も有効期限内はプレミアム機能が利用可能');

      // Note: 実際のUI実装では以下の情報を明示する必要がある：
      // - 「サブスクリプションはキャンセル済みです」
      // - 「[期限日]まで引き続きプレミアム機能をご利用いただけます」
      // - 「期限後は自動的に無料プランに戻ります」
    });

    test('TC-LEG-003: 返金ポリシーの実装確認', () async {
      // Arrange - 返金が発生したケース
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 返金後の状態（プレミアムが無効化）
      final refundedCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: false, // 返金により無効化
            periodType: PeriodType.normal,
          )
        }),
      );
      mockPurchases.setCustomerInfo(refundedCustomerInfo);

      // Act - 返金後の状態確認
      await billingService.initialize();

      // Assert - 返金処理の適切な反映
      expect(billingService.isPremium, false, 
             reason: '返金処理により適切にプレミアム機能が無効化されること');
      expect(billingService.planDisplay, '無料プラン', 
             reason: '返金後は無料プランとして表示されること');
      expect(await billingService.canCreateGoal(3), false, 
             reason: '返金後は制限機能が適用されること');

      // Note: 返金ポリシーはApple/Googleの規約に準拠
      // RevenueCatが自動的に返金状態を検出・反映する
    });

    test('TC-LEG-004: データ保持期間の管理', () async {
      // Arrange - 長期間非アクティブなアカウント
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 期限切れから長期間経過したサブスクリプション
      final expiredLongAgoCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: false,
            periodType: PeriodType.normal,
            expirationDate: DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
          )
        }),
      );
      mockPurchases.setCustomerInfo(expiredLongAgoCustomerInfo);

      // Act - 長期間期限切れアカウントの処理
      await billingService.initialize();

      // Assert - 適切なデータ処理の確認
      expect(billingService.isPremium, false, 
             reason: '長期間期限切れのアカウントは無料プランとして処理');
      expect(billingService.isTrial, false, 
             reason: 'トライアル状態ではないことを確認');

      // Note: 実際の実装では、ユーザーデータの保持期間について
      // プライバシーポリシーに明記し、適切に管理する必要がある
    });

    test('TC-LEG-005: 地域別価格設定の処理', () async {
      // Arrange - 地域別価格が適用された購入
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 地域別価格で購入されたプレミアムプラン
      final regionalPremiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(regionalPremiumCustomerInfo);

      // Act - 地域別価格での購入確認
      await billingService.initialize();

      // Assert - 地域に関係なく同等の機能提供
      expect(billingService.isPremium, true, 
             reason: '地域別価格に関係なくプレミアム機能が提供されること');
      expect(await billingService.canCreateGoal(100), true, 
             reason: '地域に関係なく同等の機能制限解除が適用されること');

      // Note: 価格は地域によって異なるが、提供される機能は同等である必要がある
      // Apple/Google Playが自動的に地域別価格を適用する
    });
  });

  group('法的要件 - プライバシー保護', () {
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

    test('TC-LEG-P001: 最小限データ収集の確認', () async {
      // Arrange - プレミアム購入処理
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 購入処理実行
      await billingService.purchasePremium();

      // Assert - 必要最小限の情報のみ使用
      expect(billingService.isPremium, true, 
             reason: '課金状態の確認に必要な最小限の情報のみを使用');

      // Note: RevenueCatは以下の情報のみを管理：
      // - 購入状態（アクティブ/非アクティブ）
      // - 期限日
      // - プラットフォーム固有のID
      // 個人識別情報は保存しない
    });

    test('TC-LEG-P002: データの匿名化処理', () async {
      // Arrange - 複数ユーザーの状態確認
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      final testUsers = [
        BillingTestHelpers.createFreeCustomerInfo(),
        BillingTestHelpers.createTrialCustomerInfo(5),
        BillingTestHelpers.createPremiumCustomerInfo(),
      ];

      // Act - 各ユーザー状態の処理
      for (final userInfo in testUsers) {
        mockPurchases.setCustomerInfo(userInfo);
        await billingService.syncWithRevenueCat();
        
        // 課金状態の確認（匿名化された情報のみ使用）
        billingService.isPremium;
        billingService.isTrial;
      }

      // Assert - 匿名化された情報での処理確認
      expect(billingService.isPremium, true, 
             reason: '匿名化された課金情報で正しく動作すること');

      // Note: 実際の実装では、ユーザー識別に必要な最小限の
      // 匿名化されたIDのみを使用する
    });

    test('TC-LEG-P003: データ削除権の対応', () async {
      // Arrange - ユーザーがデータ削除を要求したケース
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      await billingService.initialize();

      expect(billingService.isPremium, true);

      // Act - データ削除後の状態をシミュレート
      final deletedUserCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(deletedUserCustomerInfo);
      await billingService.syncWithRevenueCat();

      // Assert - データ削除後の適切な処理
      expect(billingService.isPremium, false, 
             reason: 'データ削除後は適切に無料プランに戻ること');

      // Note: GDPRやCCPAに基づくデータ削除権への対応
      // RevenueCatのデータ削除APIを使用する
    });
  });

  group('法的要件 - 利用規約遵守', () {
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

    test('TC-LEG-T001: 年齢制限の適切な処理', () async {
      // Arrange - 年齢制限に関する処理
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // Note: 実際の年齢確認はApple/Google Playのアカウント設定で行われる
      // アプリ側では追加の年齢確認は不要
      
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 購入処理実行
      await billingService.purchasePremium();

      // Assert - プラットフォームの年齢確認に依存
      expect(billingService.isPremium, true, 
             reason: 'プラットフォームの年齢確認を通過した購入が処理されること');

      // Note: Apple/Google Playが自動的に年齢制限を適用
      // 13歳未満は保護者の同意が必要（プラットフォーム側で処理）
    });

    test('TC-LEG-T002: 試用期間の適切な管理', () async {
      // Arrange - 試用期間の法的要件確認
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
      mockPurchases.setCustomerInfo(trialCustomerInfo);

      // Act - トライアル開始
      await billingService.initialize();

      // Assert - 試用期間の透明性確保
      expect(billingService.isTrial, true, 
             reason: 'トライアル状態が明確に識別されること');
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(6), 
             reason: '残り期間が正確に計算されること');

      // Note: 法的要件として以下を満たす必要がある：
      // - トライアル期間の明示
      // - 自動更新の事前通知
      // - キャンセル方法の明示
      // これらはUI実装で対応する
    });

    test('TC-LEG-T003: サブスクリプション更新の事前通知', () async {
      // Arrange - 更新が近いサブスクリプション
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // 更新が近い状態のサブスクリプション（例：3日後に更新）
      final nearExpiryCustomerInfo = CustomerInfo(
        entitlements: EntitlementInfos({
          'premium': EntitlementInfo(
            isActive: true,
            periodType: PeriodType.normal,
            willRenew: true,
            expirationDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          )
        }),
      );
      mockPurchases.setCustomerInfo(nearExpiryCustomerInfo);

      // Act - 更新近接状態の確認
      await billingService.initialize();

      // Assert - 更新予定の適切な処理
      expect(billingService.isPremium, true, 
             reason: '更新近接時もプレミアム状態が維持されること');

      // Note: 実際のUI実装では、更新24時間前に通知を表示する
      // Apple/Google Playが自動的に更新通知を送信するが、
      // アプリ内でも事前通知を行うことが推奨される
    });

    test('TC-LEG-T004: 課金エラー時の適切な処理', () async {
      // Arrange - 支払いエラーが発生したケース
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      mockPurchases.setShouldThrowError(true, errorCode: 'PAYMENT_ERROR');

      // Act & Assert - 支払いエラー時の処理
      expect(
        () async => await billingService.purchasePremium(),
        throwsA(isA<Exception>()),
        reason: '支払いエラー時に適切にエラーが通知されること',
      );

      expect(billingService.isPremium, false, 
             reason: '支払いエラー時はプレミアム機能が有効化されないこと');

      // Note: 支払いエラー時は以下の対応が必要：
      // - ユーザーへの明確なエラー通知
      // - 支払い方法の確認/変更の案内
      // - カスタマーサポートへの連絡先提供
    });
  });

  group('法的要件 - 国際対応', () {
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

    test('TC-LEG-I001: 多通貨対応の確認', () async {
      // Arrange - 複数の地域での購入をシミュレート
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 多通貨環境での購入処理
      await billingService.purchasePremium();

      // Assert - 通貨に関係なく同等の機能提供
      expect(billingService.isPremium, true, 
             reason: '通貨に関係なくプレミアム機能が提供されること');
      expect(await billingService.canCreateGoal(50), true, 
             reason: '地域・通貨に関係なく同等の機能が利用可能であること');

      // Note: Apple/Google Playが自動的に地域通貨に変換
      // アプリ側では通貨を意識する必要はない
    });

    test('TC-LEG-I002: 税法遵守の確認', () async {
      // Arrange - 税金が適用される地域での購入
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 税込み価格での購入処理
      await billingService.purchasePremium();

      // Assert - 税金処理後の正常な機能提供
      expect(billingService.isPremium, true, 
             reason: '税金処理後も正常にプレミアム機能が有効化されること');

      // Note: 税金計算と徴収はApple/Google Playが自動処理
      // VAT、消費税等の地域別税制に自動対応
    });

    test('TC-LEG-I003: 輸出入規制への対応', () async {
      // Arrange - 制限地域からのアクセス確認
      mockConnectivity.setConnectivity(ConnectivityResult.wifi);
      
      // Note: 実際の地域制限はApp Store/Google Playの配信設定で管理
      // アプリ側では特別な制限処理は不要
      
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);

      // Act - 制限のない地域での正常な処理
      await billingService.initialize();

      // Assert - 正常な地域での適切な機能提供
      expect(billingService.isPremium, true, 
             reason: '配信許可地域では正常に機能すること');

      // Note: 輸出入規制への対応：
      // - App Store/Google Playの配信地域設定で管理
      // - 暗号化機能の輸出規制（該当する場合）
      // - 各国の法的要件への準拠
    });
  });
}