part of '../screens/home_screen.dart';

void _showAddGoalModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // フルスクリーンに近い高さで表示
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.95, // 画面の95%の高さ
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: const GoalEditModal(
            title: '目標を追加',
            goalDetail: null, // 新規追加なのでnull
          ),
        ),
      );
    },
  );
}