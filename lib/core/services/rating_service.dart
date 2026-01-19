import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// 評価サービス
/// アプリの評価を促すモーダルを管理するサービス
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  /// SharedPreferencesのキー
  static const String _studyCompletionCountKey = 'study_completion_count';
  static const String _hasRatedAppKey = 'has_rated_app';

  /// 評価を促す学習完了回数の間隔
  static const int _ratingIntervalCount = 5;

  final InAppReview _inAppReview = InAppReview.instance;

  /// 学習完了時に呼び出す
  /// 5回ごとに評価モーダルを表示する
  Future<void> onStudyCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_studyCompletionCountKey) ?? 0;
      final hasRated = prefs.getBool(_hasRatedAppKey) ?? false;

      // 完了回数をインクリメント
      final newCount = count + 1;
      await prefs.setInt(_studyCompletionCountKey, newCount);

      AppLogger.instance.i('RatingService: 学習完了回数 $newCount 回目');

      // 評価済みなら表示しない
      if (hasRated) {
        AppLogger.instance.i('RatingService: 評価済みのためスキップ');
        return;
      }

      // 5回ごとに表示
      if (shouldShowRatingDialog(newCount, hasRated)) {
        await _requestReview();
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('RatingService: 学習完了処理に失敗しました', error, stackTrace);
    }
  }

  /// 評価モーダルを表示すべきかどうか判定する
  bool shouldShowRatingDialog(int completionCount, bool hasRated) {
    if (hasRated) return false;
    return completionCount % _ratingIntervalCount == 0;
  }

  /// 評価モーダルを表示する
  Future<void> _requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        AppLogger.instance.i('RatingService: 評価モーダルを表示します');
        await _inAppReview.requestReview();
      } else {
        AppLogger.instance.w('RatingService: 評価モーダルは利用できません');
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('RatingService: 評価モーダルの表示に失敗しました', error, stackTrace);
    }
  }

  /// 評価済みとしてマークする
  Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRatedAppKey, true);
      AppLogger.instance.i('RatingService: 評価済みとしてマークしました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('RatingService: 評価済みマークに失敗しました', error, stackTrace);
    }
  }

  /// 学習完了回数を取得する（テスト用）
  Future<int> getStudyCompletionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_studyCompletionCountKey) ?? 0;
  }

  /// 評価済みかどうかを取得する（テスト用）
  Future<bool> hasRatedApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasRatedAppKey) ?? false;
  }
}
