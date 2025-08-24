import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/premium_restriction_service.dart';
import '../view_models/billing_view_model.dart';

/// PremiumRestrictionServiceプロバイダー
final premiumRestrictionServiceProvider = Provider<PremiumRestrictionService>((
  ref,
) {
  final repository = ref.watch(billingRepositoryProvider);
  return PremiumRestrictionService(repository);
});

/// 目標作成可能チェックプロバイダー
final canCreateGoalProvider = FutureProvider.family<bool, int>((
  ref,
  currentGoalCount,
) async {
  final service = ref.watch(premiumRestrictionServiceProvider);
  return await service.canCreateGoal(currentGoalCount);
});

/// ポモドーロ使用可能チェックプロバイダー
final canUsePomodoroProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(premiumRestrictionServiceProvider);
  return await service.canUsePomodoro();
});

/// CSV エクスポート使用可能チェックプロバイダー
final canExportCsvProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(premiumRestrictionServiceProvider);
  return await service.canExportCsv();
});

/// 残りの目標数プロバイダー
final remainingGoalsProvider = FutureProvider.family<int, int>((
  ref,
  currentGoalCount,
) async {
  final service = ref.watch(premiumRestrictionServiceProvider);
  return await service.getRemainingGoals(currentGoalCount);
});

/// 目標制限メッセージプロバイダー
final goalLimitMessageProvider = FutureProvider.family<String, int>((
  ref,
  currentGoalCount,
) async {
  final service = ref.watch(premiumRestrictionServiceProvider);
  return await service.getGoalLimitMessage(currentGoalCount);
});
