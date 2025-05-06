import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/repositories/goal_detail_repository.dart';

// 目標詳細リポジトリの実装クラス（モックデータ）
class GoalDetailRepositoryImpl implements GoalDetailRepository {
  // モックデータ
  final List<GoalDetail> _goalDetails = [
    GoalDetail(
      id: '1',
      title: 'Flutterの基礎を完全に理解する',
      description: 'FlutterとDartの基本的な概念を理解し、簡単なアプリを開発できるようになる',
      deadline: DateTime.now().add(const Duration(days: 30)),
      avoidMessage: '今すぐやらないと後悔するぞ！',
      progressPercent: 0.45,
      targetHours: 40,
      spentMinutes: 1080, // 18時間
    ),
    GoalDetail(
      id: '2',
      title: 'TOEIC 800点を達成する',
      description: 'リスニングとリーディングを集中的に勉強し、TOEIC 800点以上を取得する',
      deadline: DateTime.now().add(const Duration(days: 45)),
      avoidMessage: '英語ができないと昇進できないぞ',
      progressPercent: 0.68,
      targetHours: 60,
      spentMinutes: 2448, // 40.8時間
    ),
    GoalDetail(
      id: '3',
      title: '毎日の運動習慣を身につける',
      description: '毎日30分以上の運動を3ヶ月間続ける',
      deadline: DateTime.now().add(const Duration(days: 60)),
      avoidMessage: '健康を失うと全てを失う',
      progressPercent: 0.15,
      targetHours: 45,
      spentMinutes: 405, // 6.75時間
    ),
  ];

  @override
  Future<List<GoalDetail>> getAllGoalDetails() async {
    // モックデータなので遅延を模倣
    await Future.delayed(const Duration(milliseconds: 500));
    return _goalDetails;
  }

  @override
  Future<GoalDetail?> getGoalDetailById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _goalDetails.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<GoalDetail> addGoalDetail(GoalDetail goalDetail) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goalDetails.add(goalDetail);
    return goalDetail;
  }

  @override
  Future<GoalDetail> updateGoalDetail(GoalDetail goalDetail) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goalDetails.indexWhere((g) => g.id == goalDetail.id);
    if (index >= 0) {
      _goalDetails[index] = goalDetail;
      return goalDetail;
    }
    throw Exception('GoalDetail not found');
  }

  @override
  Future<void> deleteGoalDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goalDetails.removeWhere((goal) => goal.id == id);
  }

  @override
  Future<GoalDetail> updateGoalProgress(
    String id,
    double progressPercent,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goalDetails.indexWhere((g) => g.id == id);
    if (index >= 0) {
      final updatedGoal = _goalDetails[index].copyWith(
        progressPercent: progressPercent,
      );
      _goalDetails[index] = updatedGoal;
      return updatedGoal;
    }
    throw Exception('GoalDetail not found');
  }

  @override
  Future<GoalDetail> updateGoalSpentTime(
    String id,
    int additionalMinutes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goalDetails.indexWhere((g) => g.id == id);
    if (index >= 0) {
      final current = _goalDetails[index];
      final newSpentMinutes = current.spentMinutes + additionalMinutes;

      // 進捗率も更新
      final totalMinutes = current.targetHours * 60;
      final newProgressPercent = (newSpentMinutes / totalMinutes).clamp(
        0.0,
        1.0,
      );

      final updatedGoal = current.copyWith(
        spentMinutes: newSpentMinutes,
        progressPercent: newProgressPercent,
      );

      _goalDetails[index] = updatedGoal;
      return updatedGoal;
    }
    throw Exception('GoalDetail not found');
  }
}
