import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// メモのデータクラス
class MemoItem {
  final String id;
  final String content;
  final DateTime timestamp;
  final String goalId; // メモが関連付けられている目標のID

  MemoItem({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.goalId,
  });

  // コピーコンストラクタ
  MemoItem copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    String? goalId,
  }) {
    return MemoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      goalId: goalId ?? this.goalId,
    );
  }
}

// メモリストの状態クラス
class MemoState {
  final List<MemoItem> memos;
  final String? currentGoalId; // 現在選択されている目標ID

  const MemoState({this.memos = const [], this.currentGoalId});

  // 状態のコピーを作成
  MemoState copyWith({List<MemoItem>? memos, String? currentGoalId}) {
    return MemoState(
      memos: memos ?? this.memos,
      currentGoalId: currentGoalId ?? this.currentGoalId,
    );
  }

  // 特定の目標IDに関連するメモだけを取得するメソッド
  List<MemoItem> getMemosByGoalId(String? goalId) {
    if (goalId == null) return memos;
    return memos.where((memo) => memo.goalId == goalId).toList();
  }
}

// プロバイダー
final memoViewModelProvider = StateNotifierProvider<MemoViewModel, MemoState>((
  ref,
) {
  return MemoViewModel();
});

// メモのビューモデル
class MemoViewModel extends StateNotifier<MemoState> {
  MemoViewModel() : super(MemoState(memos: _getSampleMemos()));

  // 現在の目標を設定
  void setCurrentGoal(String goalId) {
    state = state.copyWith(currentGoalId: goalId);
  }

  // メモを追加
  void addMemo(String content, String goalId) {
    final newMemo = MemoItem(
      id: const Uuid().v4(),
      content: content,
      timestamp: DateTime.now(),
      goalId: goalId,
    );

    state = state.copyWith(memos: [newMemo, ...state.memos]);
  }

  // メモを更新
  void updateMemo(String id, String newContent) {
    final updatedMemos =
        state.memos.map((memo) {
          if (memo.id == id) {
            return memo.copyWith(
              content: newContent,
              timestamp: DateTime.now(),
            );
          }
          return memo;
        }).toList();

    state = state.copyWith(memos: updatedMemos);
  }

  // メモを削除
  void deleteMemo(String id) {
    final updatedMemos = state.memos.where((memo) => memo.id != id).toList();
    state = state.copyWith(memos: updatedMemos);
  }
}

// サンプルデータ
List<MemoItem> _getSampleMemos() {
  return [
    MemoItem(
      id: '1',
      content: 'Part 5の文法問題が苦手。特に時制について復習が必要。',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      goalId: 'goal_1', // TOEIC学習の目標ID
    ),
    MemoItem(
      id: '2',
      content: 'リスニングセクションで10問中8問正解。集中力が続かない課題がある。',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      goalId: 'goal_1', // TOEIC学習の目標ID
    ),
    MemoItem(
      id: '3',
      content: '新しい単語帳を購入。毎日30単語ずつ覚える計画を立てた。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      goalId: 'goal_1', // TOEIC学習の目標ID
    ),
    MemoItem(
      id: '4',
      content: 'Flutterのプロバイダーパターンについて学習。状態管理の基本を理解した。',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      goalId: 'goal_2', // プログラミング学習の目標ID
    ),
    MemoItem(
      id: '5',
      content: 'アプリのUI設計を完了。明日からコーディングを開始する。',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      goalId: 'goal_2', // プログラミング学習の目標ID
    ),
  ];
}
