import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/core/usecases/supabase/goals/fetch_goals_usecase.dart';

// ホーム画面の状態を管理するプロバイダー
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(ref);
});

// ホーム画面の状態を表すクラス
class HomeState {
  final List<GoalItem> goals;
  final String filterType;
  final bool isLoading;

  HomeState({
    this.goals = const [],
    this.filterType = '全て',
    this.isLoading = false,
  });

  HomeState copyWith({
    List<GoalItem>? goals,
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

// 目標項目を表すモデルクラス
class GoalItem {
  final String id;
  final String title;
  final String avoidMessage;
  final double progressPercent;
  final int remainingDays;

  GoalItem({
    required this.id,
    required this.title,
    required this.avoidMessage,
    required this.progressPercent,
    required this.remainingDays,
  });

  // GoalDetailからGoalItemを作成するファクトリメソッド
  factory GoalItem.fromGoalDetail(GoalDetail goalDetail) {
    return GoalItem(
      id: goalDetail.id,
      title: goalDetail.title,
      avoidMessage: goalDetail.avoidMessage,
      progressPercent: goalDetail.progressPercent,
      remainingDays: goalDetail.remainingDays,
    );
  }

  // GoalsModelからGoalItemを作成するファクトリメソッド
  factory GoalItem.fromGoalsModel(GoalsModel model) {
    final now = DateTime.now();
    final remainingDays = model.deadline.difference(now).inDays;

    return GoalItem(
      id: model.id,
      title: model.title,
      avoidMessage: model.avoidMessage,
      progressPercent: model.progressPercent,
      remainingDays: remainingDays > 0 ? remainingDays : 0,
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

    // モックデータが必要な場合はgoalDetailListProviderを使用
    if (_shouldUseMockData()) {
      _loadGoalsFromMockData();
      return;
    }

    // 実際のデータ（Supabase）から取得
    _loadGoalsFromSupabase();
  }

  // モックデータを使うべきかどうかを判断
  bool _shouldUseMockData() {
    // TODO: 開発環境や設定に応じて判断するロジックを追加
    // return true; // 常にモックデータを使用する場合
    return false; // 常に実際のデータを使用する場合
  }

  // モックデータから目標を読み込む
  void _loadGoalsFromMockData() {
    // goalDetailListProviderを監視して、データが変更されたら目標リストを更新
    _ref.listen(goalDetailListProvider, (previous, next) {
      next.whenData((goalDetails) {
        final goals =
            goalDetails
                .map((detail) => GoalItem.fromGoalDetail(detail))
                .toList();
        state = state.copyWith(goals: goals, isLoading: false);
      });
    });

    // 初回のデータ読み込み
    _ref.read(goalDetailListProvider).whenData((goalDetails) {
      final goals =
          goalDetails.map((detail) => GoalItem.fromGoalDetail(detail)).toList();
      state = state.copyWith(goals: goals, isLoading: false);
    });
  }

  // Supabaseから目標を読み込む
  void _loadGoalsFromSupabase() {
    state = state.copyWith(isLoading: true);

    // 1. ユースケースのインスタンスを取得
    final fetchGoalsUsecase = _ref.read(fetchGoalsUsecaseProvider);

    // 2. goalsListProviderの監視を設定
    _ref.listen(goalsListProvider, (previous, next) {
      // ユースケースを呼び出してGoalsModelのリストを取得
      fetchGoalsUsecase(next).then((goalsModels) {
        // ViewModelでGoalItemへの変換処理を行う
        final goalItems =
            goalsModels.map((goal) => GoalItem.fromGoalsModel(goal)).toList();
        state = state.copyWith(goals: goalItems, isLoading: false);
      });
    });

    // 3. 初回データ読み込み
    final initialGoalsData = _ref.read(goalsListProvider);
    fetchGoalsUsecase(initialGoalsData).then((goalsModels) {
      // ViewModelでGoalItemへの変換処理を行う
      final goalItems =
          goalsModels.map((goal) => GoalItem.fromGoalsModel(goal)).toList();
      state = state.copyWith(goals: goalItems, isLoading: false);
    });
  }

  // フィルター変更処理
  void changeFilter(String filterType) {
    state = state.copyWith(filterType: filterType);
  }

  // フィルター済みの目標リストを取得
  List<GoalItem> get filteredGoals {
    if (state.filterType == '全て') {
      return state.goals;
    } else if (state.filterType == '進行中') {
      return state.goals.where((goal) => goal.progressPercent < 1.0).toList();
    } else {
      return state.goals.where((goal) => goal.progressPercent >= 1.0).toList();
    }
  }
}
