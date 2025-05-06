import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/widgets/timer_progress_ring.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: _getBackgroundColor(timerState.mode),
      appBar: AppBar(
        title: const Text(
          'タイマー',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getAppBarColor(timerState.mode),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildModeSelector(context, timerState, timerViewModel),
            Expanded(
              child: _buildTimerContent(context, timerState, timerViewModel),
            ),
            _buildTimerControls(context, timerState, timerViewModel),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // モード選択ウィジェット
  Widget _buildModeSelector(
    BuildContext context,
    TimerState state,
    TimerViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _buildModeButton(
            context,
            'カウントダウン',
            state.mode == TimerMode.countdown,
            () => viewModel.changeMode(TimerMode.countdown),
          ),
          _buildModeButton(
            context,
            'カウントアップ',
            state.mode == TimerMode.countup,
            () => viewModel.changeMode(TimerMode.countup),
          ),
        ],
      ),
    );
  }

  // モード選択ボタン
  Widget _buildModeButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // タイマーコンテンツ
  Widget _buildTimerContent(
    BuildContext context,
    TimerState state,
    TimerViewModel viewModel,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 残り時間の表示（大きな文字）
          Text(
            state.displayTime,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // カスタムプログレスリング
          TimerProgressRing(
            progress: state.progress,
            size: 280,
            strokeWidth: 12,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getModeLabel(state.mode),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.mode == TimerMode.countdown)
                  Text(
                    '${(state.totalSeconds / 60).round()}分タイマー',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // タイマー操作のボタン
  Widget _buildTimerControls(
    BuildContext context,
    TimerState state,
    TimerViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // リセットボタン
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
            onPressed: () => viewModel.resetTimer(),
          ),
          // 開始/一時停止ボタン
          FloatingActionButton.large(
            backgroundColor: Colors.white,
            onPressed: () {
              if (state.status == TimerStatus.running) {
                viewModel.pauseTimer();
              } else {
                viewModel.startTimer();
              }
            },
            child: Icon(
              state.status == TimerStatus.running
                  ? Icons.pause
                  : Icons.play_arrow,
              color: _getAppBarColor(state.mode),
              size: 40,
            ),
          ),
          // 設定ボタン（カウントダウンモードの場合のみ表示）
          state.mode == TimerMode.countdown
              ? IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                onPressed: () {
                  _showTimeSettingDialog(context, state, viewModel);
                },
              )
              : const SizedBox(width: 48), // スペースを確保
        ],
      ),
    );
  }

  // 時間設定ダイアログ
  void _showTimeSettingDialog(
    BuildContext context,
    TimerState state,
    TimerViewModel viewModel,
  ) {
    final currentMinutes = (state.totalSeconds / 60).round();
    int selectedMinutes = currentMinutes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タイマー時間設定'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$selectedMinutes 分'),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (value) {
                      setState(() {
                        selectedMinutes = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                viewModel.setTime(selectedMinutes);
                Navigator.pop(context);
              },
              child: const Text('設定'),
            ),
          ],
        );
      },
    );
  }

  // モードによって背景色を変更
  Color _getBackgroundColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return const Color(0xFF2563EB); // カウントダウン: 青
      case TimerMode.countup:
        return const Color(0xFF10B981); // カウントアップ: 緑
    }
  }

  // モードによってアプリバーの色を変更
  Color _getAppBarColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return const Color(0xFF1D4ED8); // カウントダウン: 濃い青
      case TimerMode.countup:
        return const Color(0xFF059669); // カウントアップ: 濃い緑
    }
  }

  // モードのラベル文字列を取得
  String _getModeLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return 'カウントダウン';
      case TimerMode.countup:
        return 'カウントアップ';
    }
  }
}
