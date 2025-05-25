import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/viewmodels/goal_detail_view_model.dart';

class GoalEditModal extends ConsumerStatefulWidget {
  final GoalsModel? goalDetail; // 編集時は目標データを渡す、新規追加時はnull
  final String title; // モーダルのタイトル（「目標を追加」または「目標を編集」）

  const GoalEditModal({super.key, this.goalDetail, required this.title});

  @override
  ConsumerState<GoalEditModal> createState() => _GoalEditModalState();
}

class _GoalEditModalState extends ConsumerState<GoalEditModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _avoidMessageController;
  late int _targetMinutesPerDay;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();

    // 編集時は既存データで初期化、新規追加時はデフォルト値を設定
    final goalDetail = widget.goalDetail;
    if (goalDetail != null) {
      // 編集モード
      _titleController = TextEditingController(text: goalDetail.title);
      _avoidMessageController = TextEditingController(
        text: goalDetail.avoidMessage,
      );

      // 1日あたりの目標時間を計算（残り日数から逆算）
      final remainingDays = goalDetail.deadline
          .difference(DateTime.now())
          .inDays
          .clamp(1, 365);
      _targetMinutesPerDay =
          ((goalDetail.totalTargetHours * 60) ~/ remainingDays).clamp(5, 240);

      _targetDate = goalDetail.deadline;
    } else {
      // 新規追加モード
      _titleController = TextEditingController();
      _avoidMessageController = TextEditingController();
      _targetMinutesPerDay = 60; // デフォルト：1時間
      _targetDate = DateTime.now().add(const Duration(days: 30)); // デフォルト：30日後
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _avoidMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveGoal(context),
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目標名入力
              const Text(
                '① 目標名',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例：TOEIC 800点取得',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '目標名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 回避したい未来
              const Text(
                '② 回避したい未来',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _avoidMessageController,
                decoration: const InputDecoration(
                  hintText: '例：不合格になる',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '回避したい未来を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 1日の目標時間
              const Text(
                '③ 1日の目標時間',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _targetMinutesPerDay.toDouble(),
                      min: 5,
                      max: 240,
                      divisions: 47,
                      activeColor: ColorConsts.primary,
                      label:
                          '${_targetMinutesPerDay ~/ 60}時間${_targetMinutesPerDay % 60}分',
                      onChanged: (value) {
                        setState(() {
                          _targetMinutesPerDay = value.round();
                        });
                      },
                    ),
                  ),
                  Text(
                    '${_targetMinutesPerDay ~/ 60}時間${_targetMinutesPerDay % 60}分',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 目標達成日
              const Text(
                '④ 目標達成予定日',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConsts.textDark,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null && picked != _targetDate) {
                    setState(() {
                      _targetDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_targetDate.year}年${_targetDate.month}月${_targetDate.day}日',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 残り日数の表示（参考情報）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '目標達成まで: ${_targetDate.difference(DateTime.now()).inDays}日',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoal(BuildContext context) {
    _saveGoalData(context, ref);
  }

  // 目標データを保存するメソッド
  Future<void> _saveGoalData(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 非同期処理のために最初にcontextを保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final goalRepository = ref.read(goalDetailRepositoryProvider);

    // 新しい目標の期間（日数）
    final durationDays = _targetDate.difference(DateTime.now()).inDays;

    // 目標の総時間を計算（1日の目標時間 × 期間日数）
    final int targetHours = (_targetMinutesPerDay * durationDays) ~/ 60;

    try {
      // 編集モードか新規追加モードかに応じて処理を分ける
      if (widget.goalDetail != null) {
        // 編集モード: 既存データを更新
        final updatedGoal = widget.goalDetail!.copyWith(
          title: _titleController.text.trim(),
          description:
              '毎日${_targetMinutesPerDay ~/ 60}時間${_targetMinutesPerDay % 60}分の学習',
          deadline: _targetDate,
          avoidMessage: _avoidMessageController.text.trim(),
          totalTargetHours: targetHours,
        );

        // リポジトリを使って目標を更新
        await goalRepository.updateGoalDetail(updatedGoal);

        // リストを更新するためにプロバイダーを更新
        // ignore: unused_result
        ref.refresh(goalDetailListProvider);
        // ignore: unused_result
        ref.refresh(goalDetailProvider(updatedGoal.id));

        // 成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('目標が更新されました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 新規追加モード: 新しいデータを作成
        final newGoal = GoalsModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // 仮のID生成
          userId: 'user1', // ユーザーIDは仮の値
          title: _titleController.text.trim(),
          description:
              '毎日${_targetMinutesPerDay ~/ 60}時間${_targetMinutesPerDay % 60}分の学習',
          deadline: _targetDate,
          isCompleted: false,
          avoidMessage: _avoidMessageController.text.trim(),
          progressPercent: 0.0, // 初期進捗率は0
          totalTargetHours: targetHours,
          spentMinutes: 0, // 初期経過時間は0
        );

        // リポジトリを使って目標を追加
        await goalRepository.addGoalDetail(newGoal);

        // リストを更新するためにプロバイダーを更新
        // ignore: unused_result
        ref.refresh(goalDetailListProvider);

        // 成功メッセージを表示
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('目標が追加されました'),
            backgroundColor: ColorConsts.success,
          ),
        );
      }

      // モーダルを閉じる
      navigator.pop();
    } catch (error) {
      // エラーメッセージを表示
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
