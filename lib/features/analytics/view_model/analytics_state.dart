import 'package:flutter/material.dart';

import '../../../core/models/goals/goals_model.dart';

/// 分析画面の期間タイプ
enum AnalyticsPeriodType { week, month }

/// 分析画面のグラフ用カラーパレット（固定8色）
///
/// 色覚多様性を考慮し、隣り合う色のコントラストを確保
class AnalyticsColors {
  static const int paletteSize = 8;

  static const List<Color> lightPalette = [
    Color(0xFF3B82F6), // 青
    Color(0xFF10B981), // 緑
    Color(0xFFF97316), // オレンジ
    Color(0xFF8B5CF6), // 紫
    Color(0xFFEC4899), // ピンク
    Color(0xFFEAB308), // 黄
    Color(0xFF06B6D4), // シアン
    Color(0xFFEF4444), // 赤
  ];

  static const List<Color> darkPalette = [
    Color(0xFF60A5FA), // 青（明るめ）
    Color(0xFF34D399), // 緑（明るめ）
    Color(0xFFFB923C), // オレンジ（明るめ）
    Color(0xFFA78BFA), // 紫（明るめ）
    Color(0xFFF472B6), // ピンク（明るめ）
    Color(0xFFFACC15), // 黄（明るめ）
    Color(0xFF22D3EE), // シアン（明るめ）
    Color(0xFFF87171), // 赤（明るめ）
  ];

  /// 目標のインデックスに対応する色を取得（循環）
  static Color getColor(int index, {bool isDarkMode = false}) {
    final palette = isDarkMode ? darkPalette : lightPalette;
    return palette[index % paletteSize];
  }
}

/// 日別の目標ごとの学習時間データ
class DailyStudyData {
  final DateTime date;

  /// goalId → totalSeconds
  final Map<String, int> goalSeconds;

  const DailyStudyData({required this.date, required this.goalSeconds});

  /// その日の合計学習時間（秒）
  int get totalSeconds =>
      goalSeconds.values.fold(0, (sum, seconds) => sum + seconds);

  /// 学習記録があるか
  bool get hasStudy => totalSeconds > 0;
}

/// 分析画面の状態
class AnalyticsState {
  final AnalyticsPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyStudyData> dailyData;
  final List<GoalsModel> activeGoals;
  final bool isLoading;

  const AnalyticsState({
    this.periodType = AnalyticsPeriodType.week,
    required this.startDate,
    required this.endDate,
    this.dailyData = const [],
    this.activeGoals = const [],
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    AnalyticsPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<DailyStudyData>? dailyData,
    List<GoalsModel>? activeGoals,
    bool? isLoading,
  }) {
    return AnalyticsState(
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyData: dailyData ?? this.dailyData,
      activeGoals: activeGoals ?? this.activeGoals,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 選択期間内の合計学習時間（秒）
  int get totalSeconds =>
      dailyData.fold(0, (sum, day) => sum + day.totalSeconds);

  /// 選択期間の日数
  int get periodDays => endDate.difference(startDate).inDays + 1;

  /// 1日平均の学習時間（秒）：期間全日で割る
  int get dailyAverageSeconds =>
      periodDays > 0 ? totalSeconds ~/ periodDays : 0;

  /// 学習した日数（1秒以上の学習がある日）
  int get studyDaysCount => dailyData.where((d) => d.hasStudy).length;

  /// 学習データが空か
  bool get isEmpty => dailyData.every((d) => !d.hasStudy);

  /// Y軸の最大値（秒）
  int get maxDailySeconds {
    if (dailyData.isEmpty) return 0;
    return dailyData
        .map((d) => d.totalSeconds)
        .fold(0, (max, val) => val > max ? val : max);
  }

  /// Y軸を時間単位で表示するか（最大値が1時間以上ならtrue）
  bool get useHoursUnit => maxDailySeconds >= 3600;

  /// 現在の週/月より未来に進めるか
  bool get canGoForward {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return endDate.isBefore(today);
  }
}
