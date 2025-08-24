import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';

/// デモタイマーウィジェット（5秒間のカウントダウン）
class DemoTimerWidget extends StatefulWidget {
  const DemoTimerWidget({super.key, required this.onTimerComplete});

  final VoidCallback onTimerComplete;

  @override
  State<DemoTimerWidget> createState() => _DemoTimerWidgetState();
}

class _DemoTimerWidgetState extends State<DemoTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _countdownTimer;
  int _remainingSeconds = 5;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 自動開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _progressController.forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _completeTimer();
      }
    });
  }

  void _completeTimer() {
    if (_isCompleted) return;

    setState(() {
      _remainingSeconds = 0;
      _isCompleted = true;
    });

    _scaleController.forward();

    // 少し遅らせてコールバック実行
    Timer(const Duration(milliseconds: 500), () {
      widget.onTimerComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // タイマー説明
          Text(
            'タイマーが自動で開始されます',
            style: TextConsts.bodyLarge.copyWith(
              color: ColorConsts.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: SpacingConsts.xl),

          // プログレス付きタイマー表示
          Stack(
            alignment: Alignment.center,
            children: [
              // プログレスリング
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 8.0,
                      backgroundColor: ColorConsts.backgroundSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompleted
                            ? ColorConsts.success
                            : ColorConsts.primary,
                      ),
                    );
                  },
                ),
              ),

              // カウントダウン数字
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCompleted) ...[
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: ColorConsts.success,
                          ),
                          const SizedBox(height: SpacingConsts.sm),
                          Text(
                            '完了！',
                            style: TextConsts.h3.copyWith(
                              color: ColorConsts.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '$_remainingSeconds',
                            style: TextConsts.timer.copyWith(
                              color: ColorConsts.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: SpacingConsts.xs),
                          Text(
                            '秒',
                            style: TextConsts.bodyLarge.copyWith(
                              color: ColorConsts.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: SpacingConsts.xl),

          // 機能説明
          Container(
            padding: const EdgeInsets.all(SpacingConsts.md),
            decoration: BoxDecoration(
              color: ColorConsts.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'タイマー機能について',
                  style: TextConsts.labelLarge.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingConsts.sm),
                _buildFeatureItem('集中時間の計測と記録'),
                _buildFeatureItem('複数のタイマーモード'),
                _buildFeatureItem('学習ログの自動保存'),
                _buildFeatureItem('進捗状況の可視化'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConsts.xs),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: ColorConsts.primary,
          ),
          const SizedBox(width: SpacingConsts.sm),
          Expanded(
            child: Text(
              text,
              style: TextConsts.bodySmall.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
