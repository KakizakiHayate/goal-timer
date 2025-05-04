import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/goal_detail_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/goal_view_model.dart';
import 'package:intl/intl.dart';

class GoalEditScreen extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalEditScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController =
        TextEditingController(text: widget.goal.description);
    _selectedDate = widget.goal.deadline;
    _isCompleted = widget.goal.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 日付選択ダイアログを表示
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate:
          DateTime.now().subtract(const Duration(days: 365)), // 過去の日付も選択可能
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ゴール更新を保存
  void _updateGoal() {
    // 既存のゴールを新しい値で更新
    final updatedGoal = widget.goal.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      deadline: _selectedDate,
      isCompleted: _isCompleted,
    );

    // リポジトリを通じてゴールを更新
    final repository = ref.read(goalRepositoryProvider);
    repository.updateGoal(updatedGoal).then((_) {
      // ゴールリストの状態を更新するために、プロバイダーを無効化
      ref.invalidate(goalListProvider);
      // 選択されたゴールの状態も更新
      ref.invalidate(selectedGoalProvider);

      // 前の画面に戻る
      Navigator.of(context).pop();

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ゴールが更新されました')),
      );
    }).catchError((error) {
      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $error')),
      );
    });
  }

  // ゴール削除
  void _deleteGoal() {
    // 削除確認ダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゴールを削除'),
        content: const Text('このゴールを削除してもよろしいですか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // リポジトリを通じてゴールを削除
              final repository = ref.read(goalRepositoryProvider);
              repository.deleteGoal(widget.goal.id).then((_) {
                // ゴールリストの状態を更新するために、プロバイダーを無効化
                ref.invalidate(goalListProvider);

                // ゴール詳細画面と編集画面の両方を閉じる
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                // 成功メッセージを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ゴールが削除されました')),
                );
              }).catchError((error) {
                // エラーメッセージを表示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラーが発生しました: $error')),
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゴールを編集'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 削除ボタン
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
            tooltip: 'ゴールを削除',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 説明入力
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // 期限日設定
            ListTile(
              title: const Text('期限日'),
              subtitle: Text(dateFormatter.format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),

            // 完了状態切り替え
            SwitchListTile(
              title: const Text('完了状態'),
              subtitle: Text(_isCompleted ? '完了済み' : '未完了'),
              value: _isCompleted,
              onChanged: (value) {
                setState(() {
                  _isCompleted = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // 保存ボタン
            ElevatedButton(
              onPressed: _updateGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('変更を保存'),
            ),
          ],
        ),
      ),
    );
  }
}
