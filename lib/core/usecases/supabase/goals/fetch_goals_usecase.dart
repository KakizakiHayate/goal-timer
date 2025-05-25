import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';

// UseCase: 目標データの取得処理を担当
class FetchGoalsUsecase {
  // 初回データ取得用メソッド
  Future<List<GoalsModel>> call(AsyncValue<List<GoalsModel>> goalsData) async {
    // AsyncValueからデータを取り出す
    return goalsData.when(
      data: (goals) => goals,
      error: (_, __) => [],
      loading: () => [],
    );
  }
}
