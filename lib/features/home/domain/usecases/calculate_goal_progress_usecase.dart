/// 目標を達成する手段は2種類ある
/// [timeRemaining]: 時間で目標を設定したとき
/// [daysRemaining]: 日付で目標を設定したとき
enum GoalAchievingType { timeRemaining, daysRemaining }

class CalculateGoalProgressUsecase {
  Future<GoalAchievingType> isTimeRemaining() async {
    return GoalAchievingType.daysRemaining;
  }
}
