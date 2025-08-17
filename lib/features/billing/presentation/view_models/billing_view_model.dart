import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../../data/repositories/billing_repository_impl.dart';
import 'billing_state.dart';

/// BillingRepositoryプロバイダー
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl();
});

/// BillingViewModelプロバイダー
final billingViewModelProvider =
    StateNotifierProvider<BillingViewModel, BillingState>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return BillingViewModel(repository);
});

/// サブスクリプション状態のストリームプロバイダー
final subscriptionStatusStreamProvider = StreamProvider<SubscriptionStatus>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.subscriptionStatusStream();
});

/// プレミアム状態のプロバイダー
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  return await repository.isPremiumAvailable();
});

/// 課金機能のViewModel
class BillingViewModel extends StateNotifier<BillingState> {
  final BillingRepository _repository;
  final GetSubscriptionStatusUseCase _getSubscriptionStatus;
  final PurchaseProductUseCase _purchaseProduct;
  final RestorePurchasesUseCase _restorePurchases;
  final GetAvailableProductsUseCase _getAvailableProducts;
  final CheckPremiumStatusUseCase _checkPremiumStatus;
  
  StreamSubscription<SubscriptionStatus>? _statusSubscription;

  BillingViewModel(this._repository)
      : _getSubscriptionStatus = GetSubscriptionStatusUseCase(_repository),
        _purchaseProduct = PurchaseProductUseCase(_repository),
        _restorePurchases = RestorePurchasesUseCase(_repository),
        _getAvailableProducts = GetAvailableProductsUseCase(_repository),
        _checkPremiumStatus = CheckPremiumStatusUseCase(_repository),
        super(const BillingState()) {
    _initialize();
  }

  /// 初期化
  Future<void> _initialize() async {
    await loadSubscriptionStatus();
    await loadAvailableProducts();
    _listenToStatusChanges();
  }

  /// サブスクリプション状態を読み込み
  Future<void> loadSubscriptionStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final status = await _getSubscriptionStatus();
      state = state.copyWith(
        subscriptionStatus: status,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.instance.e('Failed to load subscription status: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'サブスクリプション状態の取得に失敗しました',
      );
    }
  }

  /// 利用可能な商品を読み込み
  Future<void> loadAvailableProducts() async {
    try {
      final products = await _getAvailableProducts();
      state = state.copyWith(availableProducts: products);
    } catch (e) {
      AppLogger.instance.e('Failed to load available products: $e');
    }
  }

  /// サブスクリプション状態の変更を監視
  void _listenToStatusChanges() {
    _statusSubscription?.cancel();
    _statusSubscription = _getSubscriptionStatus.stream().listen(
      (status) {
        state = state.copyWith(subscriptionStatus: status);
      },
      onError: (error) {
        AppLogger.instance.e('Subscription status stream error: $error');
      },
    );
  }

  /// 商品を選択
  void selectProduct(String productId) {
    state = state.copyWith(selectedProductId: productId);
  }

  /// 商品を購入
  Future<void> purchaseProduct(String productId) async {
    if (state.isPurchasing) return;
    
    state = state.copyWith(
      isPurchasing: true,
      errorMessage: null,
      lastPurchaseResult: null,
    );
    
    try {
      final result = await _purchaseProduct(productId);
      
      state = state.copyWith(
        isPurchasing: false,
        lastPurchaseResult: result,
      );
      
      // 購入成功時は状態を更新
      if (result.type == PurchaseResultType.success) {
        await loadSubscriptionStatus();
      } else if (result.type == PurchaseResultType.error) {
        state = state.copyWith(
          errorMessage: result.errorMessage ?? '購入に失敗しました',
        );
      }
    } catch (e) {
      AppLogger.instance.e('Purchase failed: $e');
      state = state.copyWith(
        isPurchasing: false,
        errorMessage: '購入処理中にエラーが発生しました',
        lastPurchaseResult: PurchaseResult.error(
          errorType: PurchaseErrorType.system,
          errorMessage: e.toString(),
          productId: productId,
        ),
      );
    }
  }

  /// 購入を復元
  Future<void> restorePurchases() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      lastRestoreResult: null,
    );
    
    try {
      final result = await _restorePurchases();
      
      state = state.copyWith(
        isLoading: false,
        lastRestoreResult: result,
      );
      
      // 復元成功時は状態を更新
      if (result.success) {
        await loadSubscriptionStatus();
        if (result.restoredCount == 0) {
          state = state.copyWith(
            errorMessage: '復元可能な購入が見つかりませんでした',
          );
        }
      } else {
        state = state.copyWith(
          errorMessage: result.errorMessage ?? '購入の復元に失敗しました',
        );
      }
    } catch (e) {
      AppLogger.instance.e('Restore failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '復元処理中にエラーが発生しました',
        lastRestoreResult: RestoreResult.failure(e.toString()),
      );
    }
  }

  /// プレミアム機能が利用可能かチェック
  Future<bool> isPremiumAvailable() async {
    return await _checkPremiumStatus();
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}