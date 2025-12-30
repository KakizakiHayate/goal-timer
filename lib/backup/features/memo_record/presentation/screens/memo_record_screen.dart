import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/backup/core/utils/color_consts.dart';
import 'package:goal_timer/backup/core/utils/text_consts.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/features/memo_record/presentation/viewmodels/memo_view_model.dart';
import 'package:goal_timer/backup/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';

class MemoRecordScreen extends ConsumerStatefulWidget {
  final String? goalId; // 特定の目標IDが渡されたら、その目標のメモを表示

  const MemoRecordScreen({super.key, this.goalId});

  @override
  ConsumerState<MemoRecordScreen> createState() => _MemoRecordScreenState();
}

class _MemoRecordScreenState extends ConsumerState<MemoRecordScreen> {
  final TextEditingController _memoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    // 引数で渡された目標IDがあればそれを選択
    _selectedGoalId = widget.goalId;

    // 次のフレームで目標IDを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedGoalId != null) {
        ref
            .read(memoViewModelProvider.notifier)
            .setCurrentGoal(_selectedGoalId!);
      }
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 目標一覧を取得
    final goalListAsync = ref.watch(goalDetailListProvider);

    // メモの状態を購読
    final memoState = ref.watch(memoViewModelProvider);

    // フィルタリングされたメモリスト
    final filteredMemos = memoState.getMemosByGoalId(_selectedGoalId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'メモ記録',
          style: TextConsts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConsts.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: goalListAsync.when(
        data: (goals) {
          // 目標がない場合
          if (goals.isEmpty) {
            return const Center(child: Text('目標が登録されていません。先に目標を追加してください。'));
          }

          // 目標IDが選択されていない場合、最初の目標を選択
          if (_selectedGoalId == null && goals.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedGoalId = goals.first.id;
                ref
                    .read(memoViewModelProvider.notifier)
                    .setCurrentGoal(goals.first.id);
              });
            });
          }

          // 選択されている目標を取得
          final selectedGoal = goals.firstWhere(
            (goal) => goal.id == _selectedGoalId,
            orElse: () => goals.first,
          );

          return Column(
            children: [
              // 目標選択エリア
              _buildGoalSelector(goals, selectedGoal),

              // 目標情報エリア
              _buildGoalInfoSection(selectedGoal),

              // メモリスト表示エリア
              Expanded(child: _buildMemoList(filteredMemos)),

              // メモ入力エリア
              _buildMemoInputSection(selectedGoal.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  // 目標選択ドロップダウン
  Widget _buildGoalSelector(List<GoalsModel> goals, GoalsModel selectedGoal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.flag, color: ColorConsts.primary),
          const SizedBox(width: 8),
          const Text('目標:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selectedGoal.id,
              isExpanded: true,
              underline: Container(height: 1, color: Colors.grey.shade400),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGoalId = newValue;
                    ref
                        .read(memoViewModelProvider.notifier)
                        .setCurrentGoal(newValue);
                  });
                }
              },
              items:
                  goals.map<DropdownMenuItem<String>>((GoalsModel goal) {
                    return DropdownMenuItem<String>(
                      value: goal.id,
                      child: Text(goal.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 目標情報セクション
  Widget _buildGoalInfoSection(GoalsModel goalDetail) {
    // 残り時間を計算
    final remainingTimeText = goalDetail.getRemainingTimeText();
    final isAlmostOutOfTime =
        goalDetail.getRemainingMinutes() < 60; // 残り1時間未満は警告色

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目標名
          Text(
            goalDetail.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorConsts.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // 進捗バー
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: goalDetail.getProgressRate(),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ColorConsts.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(goalDetail.getProgressRate() * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.primary,
                ),
              ),
            ],
          ),

          // 残り時間情報
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '残り$remainingTimeText',
                style: TextStyle(
                  color: isAlmostOutOfTime ? Colors.red : Colors.grey,
                  fontWeight:
                      isAlmostOutOfTime ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // メモリスト表示エリア
  Widget _buildMemoList(List<MemoItem> memos) {
    if (memos.isEmpty) {
      return const Center(
        child: Text(
          'メモはありません\n下のフォームから入力してください',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: memos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return _buildMemoCard(memo);
      },
    );
  }

  // メモカード
  Widget _buildMemoCard(MemoItem memo) {
    final memoViewModel = ref.read(memoViewModelProvider.notifier);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // メモ本文
            Text(
              memo.content,
              style: const TextStyle(
                fontSize: 16,
                color: ColorConsts.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // 日時とアクション
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 日時
                Text(
                  _formatTimestamp(memo.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                // アクション
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.grey,
                      onPressed: () {
                        _showEditDialog(memo);
                      },
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.grey,
                      onPressed: () {
                        memoViewModel.deleteMemo(memo.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('メモを削除しました'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 編集ダイアログの表示
  void _showEditDialog(MemoItem memo) {
    final TextEditingController editController = TextEditingController(
      text: memo.content,
    );
    final memoViewModel = ref.read(memoViewModelProvider.notifier);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('メモを編集'),
            content: TextField(
              controller: editController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'メモを入力してください',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newContent = editController.text.trim();
                  if (newContent.isNotEmpty) {
                    memoViewModel.updateMemo(memo.id, newContent);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('メモを更新しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConsts.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('更新'),
              ),
            ],
          ),
    ).then((_) => editController.dispose());
  }

  // メモ入力エリア
  Widget _buildMemoInputSection(String goalId) {
    final memoViewModel = ref.read(memoViewModelProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // メモ入力フィールド
          TextField(
            controller: _memoController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '今日の学習内容や気づきをメモしましょう',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 12),

          // 保存ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // ビューモデルを使ってメモを保存
                final content = _memoController.text.trim();
                if (content.isNotEmpty) {
                  memoViewModel.addMemo(content, goalId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('メモを保存しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _memoController.clear();
                  // 新しいメモが追加されたらスクロールを一番上に
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('保存する'),
            ),
          ),
        ],
      ),
    );
  }

  // タイムスタンプのフォーマット
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
