// test/billing/billing_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Mock Classes for testing (simplified version without external dependencies)
class MockPurchases {
  CustomerInfo? _customerInfo;
  bool _shouldThrowError = false;
  String? _errorCode;
  
  void setCustomerInfo(CustomerInfo customerInfo) => _customerInfo = customerInfo;
  void setShouldThrowError(bool shouldThrow, {String? errorCode}) {
    _shouldThrowError = shouldThrow;
    _errorCode = errorCode;
  }
  
  Future<CustomerInfo> getCustomerInfo() async {
    if (_shouldThrowError) {
      if (_errorCode != null) {
        throw PlatformException(code: _errorCode!);
      }
      throw Exception('Mock error');
    }
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network delay
    return _customerInfo ?? CustomerInfo(entitlements: EntitlementInfos({}));
  }
  
  Future<CustomerInfo> purchasePackage(Package package) async {
    if (_shouldThrowError) {
      if (_errorCode == 'UserCancelled') {
        throw PlatformException(code: 'UserCancelled');
      }
      throw Exception('Purchase failed');
    }
    await Future.delayed(Duration(milliseconds: 500));
    return _customerInfo ?? CustomerInfo(entitlements: EntitlementInfos({}));
  }
  
  Future<CustomerInfo> restorePurchases() async {
    if (_shouldThrowError) throw Exception('Restore failed');
    return _customerInfo ?? CustomerInfo(entitlements: EntitlementInfos({}));
  }
  
  Future<Offerings> getOfferings() async {
    if (_shouldThrowError) throw Exception('Network error');
    return Offerings(current: Offering(availablePackages: [Package()]));
  }
}

class MockConnectivity {
  ConnectivityResult _result = ConnectivityResult.wifi;
  
  void setConnectivity(ConnectivityResult result) => _result = result;
  
  Future<ConnectivityResult> checkConnectivity() async {
    await Future.delayed(Duration(milliseconds: 50));
    return _result;
  }
}

// Data Models
enum ConnectivityResult { none, wifi, mobile }

enum PeriodType { intro, trial, normal }

class EntitlementInfo {
  final bool isActive;
  final PeriodType? periodType;
  final String? expirationDate;
  final bool? willRenew;
  
  EntitlementInfo({
    required this.isActive,
    this.periodType,
    this.expirationDate,
    this.willRenew,
  });
}

class EntitlementInfos {
  final Map<String, EntitlementInfo> all;
  EntitlementInfos(this.all);
}

class CustomerInfo {
  final EntitlementInfos entitlements;
  CustomerInfo({required this.entitlements});
}

class Package {
  final StoreProduct? storeProduct;
  Package({this.storeProduct});
}

class StoreProduct {
  final String priceString;
  StoreProduct({required this.priceString});
}

class Offering {
  final List<Package> availablePackages;
  Offering({required this.availablePackages});
}

class Offerings {
  final Offering? current;
  Offerings({this.current});
}

// BillingService Implementation
class BillingService {
  final MockPurchases _purchases;
  final MockConnectivity _connectivity;
  
  CustomerInfo? _customerInfo;
  DateTime? _lastSyncTime;
  static const _syncDebounceSeconds = 5;
  Timer? _syncDebounceTimer;
  
  BillingService({
    required MockPurchases purchases,
    required MockConnectivity connectivity,
  }) : _purchases = purchases,
       _connectivity = connectivity;
  
  // Getters
  bool get isPremium => _customerInfo?.entitlements.all['premium']?.isActive ?? false;
  
  bool get isTrial => _customerInfo?.entitlements.all['premium']?.periodType == PeriodType.trial;
  
  int get trialDaysLeft {
    if (!isTrial) return 0;
    final expirationDate = _customerInfo?.entitlements.all['premium']?.expirationDate;
    if (expirationDate == null) return 0;
    return DateTime.parse(expirationDate).difference(DateTime.now()).inDays;
  }
  
  String get planDisplay {
    if (isTrial) return 'トライアル中（残り${trialDaysLeft}日）';
    if (isPremium) return 'プレミアムプラン';
    return '無料プラン';
  }
  
  DateTime? getLastSyncTime() => _lastSyncTime;
  
  // Methods
  Future<void> initialize() async {
    _customerInfo = await _purchases.getCustomerInfo();
  }
  
  Future<bool> purchasePremium() async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw PlatformException(code: 'NO_INTERNET', message: 'インターネット接続が必要です');
      }
      
      final offerings = await _purchases.getOfferings();
      final package = offerings.current?.availablePackages.first;
      if (package == null) throw Exception('商品が見つかりません');
      
      final customerInfo = await _purchases.purchasePackage(package);
      _customerInfo = customerInfo;
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      if (e is PlatformException && e.code == 'UserCancelled') {
        return false;
      }
      rethrow;
    }
  }
  
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await _purchases.restorePurchases();
      _customerInfo = customerInfo;
      final hasActiveSubscription = customerInfo.entitlements.all['premium']?.isActive ?? false;
      if (!hasActiveSubscription) {
        throw PlatformException(code: 'NO_PURCHASES', message: '復元する購入が見つかりません');
      }
      return hasActiveSubscription;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> syncOnAppResume() async {
    // Debounce logic - skip if synced within last 5 seconds
    if (_lastSyncTime != null && 
        DateTime.now().difference(_lastSyncTime!).inSeconds < _syncDebounceSeconds) {
      return;
    }
    
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(Duration(seconds: 1), () async {
      try {
        _customerInfo = await _purchases.getCustomerInfo();
        _lastSyncTime = DateTime.now();
      } catch (e) {
        // Use cached info on error
      }
    });
  }
  
  Future<bool> canCreateGoal(int currentGoalCount) async {
    if (isPremium) return true;
    return currentGoalCount < 3;
  }
  
  String getGoalLimitMessage(int currentGoalCount) {
    if (isPremium) return '';
    if (currentGoalCount == 1) return 'あと1個で上限です';
    if (currentGoalCount == 2) return 'これが最後の無料目標です';
    return '';
  }
  
  Future<bool> checkDoublePurchase() async {
    final customerInfo = await _purchases.getCustomerInfo();
    return customerInfo.entitlements.all['premium']?.isActive ?? false;
  }
  
  Future<void> syncWithRevenueCat() async {
    _customerInfo = await _purchases.getCustomerInfo();
    _lastSyncTime = DateTime.now();
  }
  
  Future<bool> isOffline() async {
    final connectivity = await _connectivity.checkConnectivity();
    return connectivity == ConnectivityResult.none;
  }
  
  void dispose() {
    _syncDebounceTimer?.cancel();
  }
}

// Test Helper Functions
class BillingTestHelpers {
  static CustomerInfo createPremiumCustomerInfo() {
    return CustomerInfo(
      entitlements: EntitlementInfos({
        'premium': EntitlementInfo(
          isActive: true,
          periodType: PeriodType.normal,
        )
      }),
    );
  }
  
  static CustomerInfo createTrialCustomerInfo(int daysLeft) {
    return CustomerInfo(
      entitlements: EntitlementInfos({
        'premium': EntitlementInfo(
          isActive: true,
          periodType: PeriodType.trial,
          expirationDate: DateTime.now().add(Duration(days: daysLeft)).toIso8601String(),
        )
      }),
    );
  }
  
  static CustomerInfo createFreeCustomerInfo() {
    return CustomerInfo(entitlements: EntitlementInfos({}));
  }
}

// Basic tests for BillingService
void main() {
  group('BillingService Basic Tests', () {
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

    test('初期状態では無料プランである', () {
      // Arrange - No setup needed, default state
      
      // Act & Assert
      expect(billingService.isPremium, false);
      expect(billingService.isTrial, false);
      expect(billingService.planDisplay, '無料プラン');
    });

    test('プレミアム状態の確認', () async {
      // Arrange
      final premiumCustomerInfo = BillingTestHelpers.createPremiumCustomerInfo();
      mockPurchases.setCustomerInfo(premiumCustomerInfo);
      
      // Act
      await billingService.initialize();
      
      // Assert
      expect(billingService.isPremium, true);
      expect(billingService.isTrial, false);
      expect(billingService.planDisplay, 'プレミアムプラン');
    });

    test('トライアル状態の確認', () async {
      // Arrange
      final trialCustomerInfo = BillingTestHelpers.createTrialCustomerInfo(5);
      mockPurchases.setCustomerInfo(trialCustomerInfo);
      
      // Act
      await billingService.initialize();
      
      // Assert
      expect(billingService.isPremium, true);
      expect(billingService.isTrial, true);
      expect(billingService.trialDaysLeft, greaterThanOrEqualTo(4));
      expect(billingService.planDisplay, contains('トライアル中'));
    });

    test('目標作成制限の確認', () async {
      // Arrange - Free user
      final freeCustomerInfo = BillingTestHelpers.createFreeCustomerInfo();
      mockPurchases.setCustomerInfo(freeCustomerInfo);
      await billingService.initialize();
      
      // Act & Assert
      expect(await billingService.canCreateGoal(0), true);
      expect(await billingService.canCreateGoal(1), true);
      expect(await billingService.canCreateGoal(2), true);
      expect(await billingService.canCreateGoal(3), false);
      
      expect(billingService.getGoalLimitMessage(1), 'あと1個で上限です');
      expect(billingService.getGoalLimitMessage(2), 'これが最後の無料目標です');
    });
  });
}