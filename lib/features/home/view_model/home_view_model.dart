import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/goals/goals_model.dart';

// Home画面の状態を管理するプロバイダー
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel();
});

// Home画面の状態
class HomeState {
  final List<GoalsModel> goals;
  final bool isLoading;

  HomeState({
    this.goals = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    List<GoalsModel>? goals,
    bool? isLoading,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Home画面のViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel() : super(HomeState()) {
    _loadDummyGoals();
  }

  // ダミーデータをロード
  void _loadDummyGoals() {
    state = state.copyWith(isLoading: true);

    // 固定のダミー目標データ
    final dummyGoals = [
      GoalsModel(
        id: 'dummy-goal-1',
        userId: 'dummy-user-1',
        title: '英語学習',
        description: '毎日30分の英語学習',
        targetMinutes: 1500,
        spentMinutes: 750,
        avoidMessage: '',
        deadline: DateTime.now().add(const Duration(days: 30)),
        isCompleted: false,
        updatedAt: DateTime.now(),
      ),
      GoalsModel(
        id: 'dummy-goal-2',
        userId: 'dummy-user-1',
        title: 'プログラミング学習',
        description: 'Flutterアプリ開発',
        targetMinutes: 2000,
        spentMinutes: 400,
        avoidMessage: 'スマホを見すぎない',
        deadline: DateTime.now().add(const Duration(days: 40)),
        isCompleted: false,
        updatedAt: DateTime.now(),
      ),
    ];

    state = state.copyWith(
      goals: dummyGoals,
      isLoading: false,
    );
  }

  // 目標リストを再読み込み
  void reloadGoals() {
    _loadDummyGoals();
  }

  // フィルタリングされた目標リストを取得
  List<GoalsModel> get filteredGoals => state.goals;
}
