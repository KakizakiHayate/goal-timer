import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/goal_view_model.dart';
import 'package:intl/intl.dart';

class GoalAddScreen extends ConsumerStatefulWidget {
  const GoalAddScreen({super.key});

  @override
  ConsumerState<GoalAddScreen> createState() => _GoalAddScreenState();
}

class _GoalAddScreenState extends ConsumerState<GoalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ゴールを保存
  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    // 新しいゴールを作成
    final newGoal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 簡易的なID生成
      title: _titleController.text,
      description: _descriptionController.text,
      deadline: _selectedDate,
    );

    // リポジトリを通じてゴールを保存
    final repository = ref.read(goalRepositoryProvider);
    repository.addGoal(newGoal).then((_) {
      // ゴールリストの状態を更新するために、プロバイダーを無効化
      ref.invalidate(goalListProvider);

      // 前の画面に戻る
      Navigator.of(context).pop();

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ゴールが追加されました')),
      );
    }).catchError((error) {
      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      appBar: AppBar(
        title: const Text('新しいゴール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // タイトル入力
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明入力
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 期限日設定
              ListTile(
                title: const Text('期限日'),
                subtitle: Text(dateFormatter.format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),

              const SizedBox(height: 32),

              // 保存ボタン
              ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('ゴールを保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
