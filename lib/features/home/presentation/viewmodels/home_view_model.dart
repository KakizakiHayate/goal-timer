import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';
import 'package:goal_timer/core/usecases/supabase/goals/fetch_goals_usecase.dart';

// ホーム画面の状態を管理するプロバイダー
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(ref);
});

// ホーム画面の状態を表すクラス
class HomeState {
  final List<GoalsModel> goals;
  final String filterType;
  final bool isLoading;

  HomeState({
    this.goals = const [],
    this.filterType = '全て',
    this.isLoading = false,
  });

  HomeState copyWith({
    List<GoalsModel>? goals,
    String? filterType,
    bool? isLoading,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ホーム画面のビューモデル
class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeViewModel(this._ref) : super(HomeState()) {
    // 初期データの読み込み
    _loadGoals();
  }

  // 目標データの読み込み
  void _loadGoals() {
    state = state.copyWith(isLoading: true);

    // 実際のデータ（Supabase）から取得
    _loadGoalsFromSupabase();
  }

  // Supabaseから目標を読み込む
  void _loadGoalsFromSupabase() {
    state = state.copyWith(isLoading: true);

    // 1. ユースケースのインスタンスを取得
    final fetchGoalsUsecase = _ref.read(fetchGoalsUsecaseProvider);

    // 2. goalsListProviderの監視を設定
    _ref.listen(goalsListProvider, (previous, next) {
      fetchGoalsUsecase(next).then((goalsModels) {
        state = state.copyWith(goals: goalsModels, isLoading: false);
        // 残り%を計算する

        // 日付 or 時間どちらを選択したのかを送る
      });
    });

    // 3. 初回データ読み込み
    final initialGoalsData = _ref.read(goalsListProvider);
    fetchGoalsUsecase(initialGoalsData).then((goalsModels) {
      state = state.copyWith(goals: goalsModels, isLoading: false);
    });
  }

  // フィルター変更処理
  void changeFilter(String filterType) {
    state = state.copyWith(filterType: filterType);
  }

  // フィルター済みの目標リストを取得
  List<GoalsModel> get filteredGoals {
    if (state.filterType == '全て') {
      return state.goals;
    } else if (state.filterType == '進行中') {
      return state.goals.where((goal) => goal.getProgressRate() < 1.0).toList();
    } else {
      return state.goals
          .where((goal) => goal.getProgressRate() >= 1.0)
          .toList();
    }
  }
}
