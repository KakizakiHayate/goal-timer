import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 定期的な同期を行うサービス
class SyncService {
  final Ref _ref;
  Timer? _syncTimer;
  static const Duration syncInterval = Duration(minutes: 5); // 5分ごとに同期

  SyncService(this._ref);

  /// 同期サービスを開始
  void startSync() {
    AppLogger.instance.i('定期同期サービスを開始します: 間隔=${syncInterval.inMinutes}分');

    // 既存のタイマーがあればキャンセル
    _syncTimer?.cancel();

    // 初回は即時実行
    _syncAllData();

    // 定期的な同期タイマーを設定
    _syncTimer = Timer.periodic(syncInterval, (_) => _syncAllData());
  }

  /// 同期サービスを停止
  void stopSync() {
    AppLogger.instance.i('定期同期サービスを停止します');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// すべてのデータを同期
  Future<void> _syncAllData() async {
    AppLogger.instance.i('データ同期を開始します...');

    try {
      // Goals同期
      await _ref.read(hybridGoalsRepositoryProvider).syncWithRemote();

      // ユーザー同期
      await _ref.read(hybridUsersRepositoryProvider).syncWithRemote();

      // 学習記録同期
      await _ref.read(hybridDailyStudyLogsRepositoryProvider).syncWithRemote();

      AppLogger.instance.i('データ同期が完了しました');
    } catch (e, stackTrace) {
      AppLogger.instance.e('データ同期中にエラーが発生しました', e, stackTrace);
    }
  }

  /// 手動で同期を実行
  Future<void> syncManually() async {
    AppLogger.instance.i('手動同期を開始します...');
    await _syncAllData();
  }
}

/// SyncServiceのプロバイダー
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// アプリの起動時に同期サービスを開始するプロバイダー
final syncServiceInitializerProvider = Provider<void>((ref) {
  // アプリ起動時に同期サービスを開始
  final syncService = ref.read(syncServiceProvider);
  syncService.startSync();

  // プロバイダーが破棄されるときに同期サービスを停止
  ref.onDispose(() {
    syncService.stopSync();
  });
});
