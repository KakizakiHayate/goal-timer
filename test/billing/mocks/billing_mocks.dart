// test/billing/mocks/billing_mocks.dart

import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

// Mock Classes
class MockPurchases extends Mock implements Purchases {}
class MockCustomerInfo extends Mock implements CustomerInfo {}
class MockEntitlementInfo extends Mock implements EntitlementInfo {}
class MockPackage extends Mock implements Package {}
class MockStoreProduct extends Mock implements StoreProduct {}
class MockOffering extends Mock implements Offering {}
class MockOfferings extends Mock implements Offerings {}
class MockConnectivity extends Mock implements Connectivity {}
class MockTransaction extends Mock implements StoreTransaction {}

// Fake Classes for registerFallbackValue
class FakeCustomerInfo extends Fake implements CustomerInfo {}
class FakePackage extends Fake implements Package {}

// Test Helper Functions
class BillingTestHelpers {
  /// Creates a mock CustomerInfo with premium entitlement
  static MockCustomerInfo createPremiumCustomerInfo() {
    final mockCustomerInfo = MockCustomerInfo();
    final mockEntitlementInfo = MockEntitlementInfo();
    
    when(() => mockEntitlementInfo.isActive).thenReturn(true);
    when(() => mockEntitlementInfo.periodType).thenReturn(PeriodType.normal);
    when(() => mockCustomerInfo.entitlements).thenReturn(
      EntitlementInfos({'premium': mockEntitlementInfo}),
    );
    
    return mockCustomerInfo;
  }
  
  /// Creates a mock CustomerInfo for trial user
  static MockCustomerInfo createTrialCustomerInfo(int daysLeft) {
    final mockCustomerInfo = MockCustomerInfo();
    final mockEntitlementInfo = MockEntitlementInfo();
    
    when(() => mockEntitlementInfo.isActive).thenReturn(true);
    when(() => mockEntitlementInfo.periodType).thenReturn(PeriodType.trial);
    when(() => mockEntitlementInfo.expirationDate)
        .thenReturn(DateTime.now().add(Duration(days: daysLeft)).toIso8601String());
    when(() => mockCustomerInfo.entitlements).thenReturn(
      EntitlementInfos({'premium': mockEntitlementInfo}),
    );
    
    return mockCustomerInfo;
  }
  
  /// Creates a mock CustomerInfo for free user
  static MockCustomerInfo createFreeCustomerInfo() {
    final mockCustomerInfo = MockCustomerInfo();
    when(() => mockCustomerInfo.entitlements).thenReturn(EntitlementInfos({}));
    return mockCustomerInfo;
  }
  
  /// Creates a mock Offering with package
  static MockOfferings createMockOfferings({String priceString = '¥480'}) {
    final mockOfferings = MockOfferings();
    final mockOffering = MockOffering();
    final mockPackage = MockPackage();
    final mockProduct = MockStoreProduct();
    
    when(() => mockProduct.priceString).thenReturn(priceString);
    when(() => mockPackage.storeProduct).thenReturn(mockProduct);
    when(() => mockOffering.availablePackages).thenReturn([mockPackage]);
    when(() => mockOfferings.current).thenReturn(mockOffering);
    
    return mockOfferings;
  }
  
  /// Sets up common mock responses for offline state
  static void setupOfflineState(MockConnectivity mockConnectivity) {
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => ConnectivityResult.none);
  }
  
  /// Sets up common mock responses for online state
  static void setupOnlineState(MockConnectivity mockConnectivity) {
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => ConnectivityResult.wifi);
  }
  
  /// Creates a delayed response for testing performance
  static Future<T> createDelayedResponse<T>(T response, {int milliseconds = 500}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    return response;
  }
  
  /// Registers all fallback values for mocktail
  static void registerFallbackValues() {
    registerFallbackValue(FakeCustomerInfo());
    registerFallbackValue(FakePackage());
  }
}

// Custom Matchers for better test assertions
class BillingMatchers {
  /// Matches premium entitlements
  static Matcher isPremiumEntitlement() => isA<EntitlementInfos>()
      .having((e) => e.all['premium']?.isActive, 'premium is active', true);
  
  /// Matches trial entitlements
  static Matcher isTrialEntitlement() => isA<EntitlementInfos>()
      .having((e) => e.all['premium']?.periodType, 'premium is trial', PeriodType.trial)
      .having((e) => e.all['premium']?.isActive, 'premium is active', true);
  
  /// Matches free user entitlements
  static Matcher isFreeEntitlement() => isA<EntitlementInfos>()
      .having((e) => e.all['premium']?.isActive ?? false, 'premium is inactive', false);
}

// Test Constants
class BillingTestConstants {
  static const String premiumEntitlementId = 'premium';
  static const String monthlyProductId = 'premium_monthly';
  static const String annualProductId = 'premium_annual';
  static const int freeGoalLimit = 3;
  static const int trialDays = 7;
  static const double regularPrice = 480.0;
  static const double introPrice = 240.0;
  static const int syncDebounceSeconds = 5;
  static const int maxRetryAttempts = 3;
  static const Duration performanceThreshold = Duration(seconds: 5);
  static const Duration syncThreshold = Duration(seconds: 1);
  static const Duration initThreshold = Duration(seconds: 2);
}

// Mock Behavior Presets
class MockBehaviorPresets {
  /// Sets up successful purchase flow
  static void setupSuccessfulPurchase(
    MockPurchases mockPurchases,
    MockConnectivity mockConnectivity,
  ) {
    BillingTestHelpers.setupOnlineState(mockConnectivity);
    
    final mockOfferings = BillingTestHelpers.createMockOfferings();
    final mockCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(7);
    
    when(() => mockPurchases.getOfferings())
        .thenAnswer((_) async => mockOfferings);
    when(() => mockPurchases.purchasePackage(any()))
        .thenAnswer((_) async => mockCustomerInfo);
  }
  
  /// Sets up successful restore flow
  static void setupSuccessfulRestore(MockPurchases mockPurchases) {
    final mockCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
    when(() => mockPurchases.restorePurchases())
        .thenAnswer((_) async => mockCustomerInfo);
  }
  
  /// Sets up failed restore (no purchases)
  static void setupFailedRestore(MockPurchases mockPurchases) {
    final mockCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
    when(() => mockPurchases.restorePurchases())
        .thenAnswer((_) async => mockCustomerInfo);
  }
  
  /// Sets up network error scenario
  static void setupNetworkError(MockPurchases mockPurchases) {
    when(() => mockPurchases.getOfferings())
        .thenThrow(Exception('Network error'));
    when(() => mockPurchases.purchasePackage(any()))
        .thenThrow(Exception('Network error'));
    when(() => mockPurchases.getCustomerInfo())
        .thenThrow(Exception('Network error'));
  }
  
  /// Sets up rate limiting error
  static void setupRateLimit(MockPurchases mockPurchases) {
    when(() => mockPurchases.getCustomerInfo())
        .thenThrow(PlatformException(code: 'RATE_LIMITED'));
  }
  
  /// Sets up user cancelled purchase
  static void setupUserCancelled(MockPurchases mockPurchases) {
    when(() => mockPurchases.purchasePackage(any()))
        .thenThrow(PlatformException(code: 'UserCancelled'));
  }
}