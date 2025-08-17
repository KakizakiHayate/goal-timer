import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_result.freezed.dart';
part 'purchase_result.g.dart';

/// 購入処理の結果
enum PurchaseResultType {
  /// 成功
  success,
  /// キャンセル
  cancelled,
  /// 保留中（決済処理中）
  pending,
  /// エラー
  error,
  /// 不明
  unknown,
}

/// 購入エラーの種類
enum PurchaseErrorType {
  /// ネットワークエラー
  network,
  /// 支払い拒否
  paymentDeclined,
  /// 商品が見つからない
  productNotFound,
  /// すでに所有している
  alreadyOwned,
  /// サーバーエラー
  server,
  /// システムエラー
  system,
  /// 不明なエラー
  unknown,
}

/// 購入処理の結果
@freezed
class PurchaseResult with _$PurchaseResult {
  const factory PurchaseResult({
    required PurchaseResultType type,
    required String? transactionId,
    required String? productId,
    required DateTime? purchaseDate,
    required PurchaseErrorType? errorType,
    required String? errorMessage,
    @Default(false) bool needsFinalization,
  }) = _PurchaseResult;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResultFromJson(json);

  /// 成功結果を作成
  factory PurchaseResult.success({
    required String transactionId,
    required String productId,
    DateTime? purchaseDate,
    bool needsFinalization = false,
  }) =>
      PurchaseResult(
        type: PurchaseResultType.success,
        transactionId: transactionId,
        productId: productId,
        purchaseDate: purchaseDate ?? DateTime.now(),
        errorType: null,
        errorMessage: null,
        needsFinalization: needsFinalization,
      );

  /// キャンセル結果を作成
  factory PurchaseResult.cancelled() => const PurchaseResult(
        type: PurchaseResultType.cancelled,
        transactionId: null,
        productId: null,
        purchaseDate: null,
        errorType: null,
        errorMessage: null,
      );

  /// エラー結果を作成
  factory PurchaseResult.error({
    required PurchaseErrorType errorType,
    required String errorMessage,
    String? productId,
  }) =>
      PurchaseResult(
        type: PurchaseResultType.error,
        transactionId: null,
        productId: productId,
        purchaseDate: null,
        errorType: errorType,
        errorMessage: errorMessage,
      );
}

/// 購入復元の結果
@freezed
class RestoreResult with _$RestoreResult {
  const factory RestoreResult({
    required bool success,
    required int restoredCount,
    required String? errorMessage,
    required List<String> restoredProductIds,
  }) = _RestoreResult;

  factory RestoreResult.fromJson(Map<String, dynamic> json) =>
      _$RestoreResultFromJson(json);

  /// 成功結果を作成
  factory RestoreResult.success({
    required int restoredCount,
    required List<String> restoredProductIds,
  }) =>
      RestoreResult(
        success: true,
        restoredCount: restoredCount,
        errorMessage: null,
        restoredProductIds: restoredProductIds,
      );

  /// 失敗結果を作成
  factory RestoreResult.failure(String errorMessage) => RestoreResult(
        success: false,
        restoredCount: 0,
        errorMessage: errorMessage,
        restoredProductIds: const [],
      );
}