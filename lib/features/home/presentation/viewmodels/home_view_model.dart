import 'package:flutter_riverpod/flutter_riverpod.dart';

// ホーム画面の状態を管理するプロバイダー
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel();
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
}

// ホーム画面のビューモデル
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel() : super(HomeState()) {
    // 初期データの読み込み
    _loadGoals();
  }

  // 目標データの読み込み（ダミーデータ）
  void _loadGoals() {
    state = state.copyWith(isLoading: true);

    // ダミーデータを作成
    final mockGoals = [
      GoalItem(
        id: '1',
        title: 'Flutterの基礎を完全に理解する',
        avoidMessage: '今すぐやらないと後悔するぞ！',
        progressPercent: 0.45,
        remainingDays: 30,
      ),
      GoalItem(
        id: '2',
        title: 'TOEIC 800点を達成する',
        avoidMessage: '英語ができないと昇進できないぞ',
        progressPercent: 0.68,
        remainingDays: 45,
      ),
      GoalItem(
        id: '3',
        title: '毎日の運動習慣を身につける',
        avoidMessage: '健康を失うと全てを失う',
        progressPercent: 0.15,
        remainingDays: 60,
      ),
    ];

    state = state.copyWith(goals: mockGoals, isLoading: false);
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
