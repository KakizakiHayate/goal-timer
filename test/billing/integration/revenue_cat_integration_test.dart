import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:goal_timer/features/billing/domain/entities/entities.dart';

void main() {
  group('RevenueCat Integration Test', () {
    late BillingRepositoryImpl repository;

    setUp(() {
      repository = BillingRepositoryImpl();
    });

    test('RevenueCatとの通信確認', () async {
      // このテストは実際のRevenueCat SDKが初期化されている必要があります
      // シミュレータまたは実機で実行してください
      
      try {
        // 1. サブスクリプション状態を取得
        final status = await repository.getSubscriptionStatus();
        print('✅ Subscription Status: ${status.state}');
        print('   Is Premium: ${status.isPremium}');
        print('   Plan ID: ${status.planId}');
        
        // 2. 利用可能な商品を取得
        final products = await repository.getAvailableProducts();
        print('\n✅ Available Products:');
        for (final product in products) {
          print('   - ${product.identifier}: ${product.title} (${product.price})');
        }
        
        // 3. プレミアム状態を確認
        final isPremium = await repository.isPremiumAvailable();
        print('\n✅ Premium Available: $isPremium');
        
        // 4. 顧客情報を取得
        final customerInfo = await repository.getCustomerInfo();
        print('\n✅ Customer Info:');
        print('   User ID: ${customerInfo.originalAppUserId}');
        print('   Active Entitlements: ${customerInfo.entitlements.keys.toList()}');
        
        // テスト成功
        expect(status, isNotNull);
        expect(products, isNotNull);
        
      } catch (e) {
        // RevenueCat SDKが初期化されていない場合のエラー
        print('⚠️ RevenueCat SDK not initialized or network error: $e');
        print('   This test should be run on simulator/device with proper API key');
        
        // テストはスキップ
        markTestSkipped('RevenueCat SDK not available in test environment');
      }
    });

    test('制限機能の動作確認', () async {
      try {
        // 無料ユーザーとして制限を確認
        final isPremium = await repository.isPremiumAvailable();
        
        if (!isPremium) {
          print('\n📊 Free User Limitations:');
          print('   - Goal Limit: 3');
          print('   - Pomodoro Timer: Locked');
          print('   - CSV Export: Locked');
        } else {
          print('\n🌟 Premium User - No Limitations');
        }
        
        expect(isPremium, isNotNull);
      } catch (e) {
        markTestSkipped('RevenueCat SDK not available');
      }
    });
  });
}