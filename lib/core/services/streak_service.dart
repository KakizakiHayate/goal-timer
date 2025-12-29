import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// ストリーク関連の処理を担当するサービスクラス
/// 複数のデータソースをまたぐロジックを集約し、関心を分離する
class StreakService {
  final LocalStudyDailyLogsDatasource _logsDatasource;
  final LocalUsersDatasource _usersDatasource;

  StreakService({
    required LocalStudyDailyLogsDatasource logsDatasource,
    required LocalUsersDatasource usersDatasource,
  })  : _logsDatasource = logsDatasource,
        _usersDatasource = usersDatasource;

  /// 現在のストリークが最長を超えていれば更新する
  /// 更新した場合はtrueを返す
  Future<bool> updateLongestStreakIfNeeded() async {
    try {
      // 現在のストリークを計算
      final currentStreak = await _logsDatasource.calculateCurrentStreak();

      // 最長ストリークと比較して必要なら更新
      final updated =
          await _usersDatasource.updateLongestStreakIfNeeded(currentStreak);

      if (updated) {
        AppLogger.instance.i('最長ストリークを更新しました: $currentStreak日');
      }

      return updated;
    } catch (error, stackTrace) {
      // 最長ストリーク更新の失敗は呼び出し元に伝えるが、
      // 致命的エラーとしては扱わない
      AppLogger.instance.e('最長ストリークの更新に失敗しました', error, stackTrace);
      return false;
    }
  }

  /// 最長ストリークを取得する
  /// データがない場合は現在のストリークを計算して保存し、その値を返す
  Future<int> getOrCalculateLongestStreak() async {
    try {
      // 最長ストリークを取得
      final longestStreak = await _usersDatasource.getLongestStreak();

      // 最長ストリークが0の場合、現在のストリークを計算して設定
      if (longestStreak == 0) {
        final currentStreak = await _logsDatasource.calculateCurrentStreak();

        if (currentStreak > 0) {
          // 現在のストリークがあれば最長として保存
          await _usersDatasource.updateLongestStreak(currentStreak);
          AppLogger.instance
              .i('最長ストリークを初期化しました: $currentStreak日');
          return currentStreak;
        }
      }

      return longestStreak;
    } catch (error, stackTrace) {
      AppLogger.instance.e('最長ストリークの取得に失敗しました', error, stackTrace);
      return 0;
    }
  }

  /// 現在のストリークを取得する
  Future<int> getCurrentStreak() async {
    try {
      return await _logsDatasource.calculateCurrentStreak();
    } catch (error, stackTrace) {
      AppLogger.instance.e('現在のストリークの取得に失敗しました', error, stackTrace);
      return 0;
    }
  }
}
