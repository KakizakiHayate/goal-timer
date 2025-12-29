import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_statistics.dart';
import '../services/study_statistics_service.dart';
import '../services/sync_checker.dart';
import '../utils/app_logger.dart';

/// グローバル統計データを管理するNotifier
///
/// アプリ全体で統計データを共有し、重複取得を避ける。
/// 起動時にローカルDBから統計を計算し、必要に応じて手動でリフレッシュ可能。
class GlobalStatisticsNotifier extends StateNotifier<StudyStatistics> {
  final StudyStatisticsService _service;
  final SyncChecker _syncChecker;

  GlobalStatisticsNotifier(this._service, this._syncChecker)
    : super(StudyStatistics.empty()) {
    _loadStatistics();
  }

  /// 統計データを読み込み（ローカルDBから）
  Future<void> _loadStatistics() async {
    try {
      AppLogger.instance.d('グローバル統計データを読み込み中...');
      final statistics = await _service.getCurrentUserStatistics();
      state = statistics;
      AppLogger.instance.i(
        'グローバル統計データ読み込み完了: '
        '今日の学習時間=${statistics.totalMinutes}分, '
        '連続日数=${statistics.currentStreak}日',
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e('グローバル統計データの読み込みに失敗', e, stackTrace);
      // エラー時は空のデータを設定
      state = StudyStatistics.empty();
    }
  }

  /// 統計を手動で更新（同期 + 再読み込み）
  ///
  /// [forceSync] - trueの場合、同期チェックを実行してから再読み込み
  Future<void> refresh({bool forceSync = false}) async {
    try {
      AppLogger.instance.i('グローバル統計データをリフレッシュ中...');

      if (forceSync) {
        AppLogger.instance.d('同期チェックを実行します');
        await _syncChecker.checkAndSyncIfNeeded();
      }

      await _loadStatistics();
      AppLogger.instance.i('グローバル統計データのリフレッシュが完了しました');
    } catch (e, stackTrace) {
      AppLogger.instance.e('グローバル統計データのリフレッシュに失敗', e, stackTrace);
      // エラーでも現在の状態は保持（ユーザー体験を優先）
    }
  }
}
