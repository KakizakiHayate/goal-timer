import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/timer_view_model.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/circular_progress_indicator.dart' as custom;
import '../../../../core/widgets/animated_check_icon.dart';
import '../../../../core/widgets/pressable_card.dart';

/// 改善されたタイマー画面
/// 集中力向上とモチベーション維持に焦点を当てたデザイン
class TimerScreen extends ConsumerStatefulWidget {
  final String goalId;

  const TimerScreen({super.key, required this.goalId});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  static final Set<String> _loggedGoalIds = {};
  
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  
  bool _showCompletionAnimation = false;

  @override
  void initState() {
    super.initState();
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: AnimationConsts.smoothCurve,
      ),
    );
    
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedGoalIds.contains(widget.goalId)) {
      AppLogger.instance.i('TimerScreenV2: goalId=${widget.goalId}');
      _loggedGoalIds.add(widget.goalId);
    }

    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);

    // 目標IDをタイマービューモデルに設定
    if (timerState.goalId != widget.goalId) {
      Future.microtask(() {
        timerViewModel.setGoalId(widget.goalId);
      });
    }

    // タイマー実行中のパルスアニメーション
    if (timerState.status == TimerStatus.running && !_pulseAnimationController.isAnimating) {
      _pulseAnimationController.repeat(reverse: true);
    } else if (timerState.status != TimerStatus.running) {
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(timerState),
      appBar: _buildAppBar(timerState),
      body: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            // メインコンテンツ
            _buildMainContent(context, timerState, timerViewModel),
            
            // 完了アニメーション
            if (_showCompletionAnimation)
              _buildCompletionOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TimerState timerState) {
    return AppBar(
      title: Text(
        'フォーカスタイム',
        style: TextConsts.h3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getThemeColor(timerState),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          if (timerState.status == TimerStatus.running) {
            _showExitConfirmDialog(context);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConsts.l),
        child: Column(
          children: [
            const SizedBox(height: SpacingConsts.l),
            
            // モード切り替え
            _buildModeSwitcher(timerState, timerViewModel),
            
            const SizedBox(height: SpacingConsts.l),
            
            // タイマー表示
            _buildTimerDisplay(timerState),
            
            const SizedBox(height: SpacingConsts.l),
            
            // コントロールボタン
            _buildControlButtons(timerState, timerViewModel),
            
            const SizedBox(height: SpacingConsts.l),
            
            // 統計情報
            _buildStatsCard(timerState),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(TimerState timerState, TimerViewModel timerViewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            'フォーカス',
            timerState.mode == TimerMode.countdown,
            () => timerViewModel.changeMode(TimerMode.countdown),
            Icons.timer_outlined,
          ),
          _buildModeButton(
            'フリー',
            timerState.mode == TimerMode.countup,
            () => timerViewModel.changeMode(TimerMode.countup),
            Icons.all_inclusive,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String text,
    bool isActive,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimationConsts.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.l,
          vertical: SpacingConsts.m,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? ColorConsts.textPrimary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: SpacingConsts.s),
            Text(
              text,
              style: TextConsts.body.copyWith(
                color: isActive ? ColorConsts.textPrimary : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(TimerState timerState) {
    final minutes = timerState.currentSeconds ~/ 60;
    final seconds = timerState.currentSeconds % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progressValue = timerState.mode == TimerMode.countdown
        ? timerState.currentSeconds / (25 * 60)
        : (timerState.currentSeconds % (60 * 60)) / (60 * 60);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: timerState.status == TimerStatus.running 
              ? _pulseAnimation.value 
              : 1.0,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // プログレスリング
                custom.CircularProgressIndicator(
                  progress: timerState.mode == TimerMode.countdown 
                      ? 1 - progressValue 
                      : progressValue,
                  size: 260.0,
                  strokeWidth: 12.0,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  showAnimation: false,
                  centerWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeText,
                        style: TextConsts.h1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 56,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: SpacingConsts.s),
                      Text(
                        timerState.mode == TimerMode.countdown 
                            ? 'フォーカス中' 
                            : 'フリータイム',
                        style: TextConsts.body.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(TimerState timerState, TimerViewModel timerViewModel) {
    final isRunning = timerState.status == TimerStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // リセットボタン
        _buildControlButton(
          icon: Icons.refresh_rounded,
          onPressed: () => timerViewModel.resetTimer(),
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
        
        const SizedBox(width: SpacingConsts.l),
        
        // メイン操作ボタン
        _buildMainControlButton(
          icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: () {
            if (isRunning) {
              timerViewModel.pauseTimer();
            } else {
              timerViewModel.startTimer();
            }
          },
        ),
        
        const SizedBox(width: SpacingConsts.l),
        
        // 設定ボタン
        _buildControlButton(
          icon: Icons.settings_rounded,
          onPressed: () => _showTimerSettingDialog(context, timerState, timerViewModel),
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 64.0,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: ColorConsts.textPrimary,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildStatsCard(TimerState timerState) {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: Colors.white.withOpacity(0.1),
      borderRadius: 20.0,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.schedule_rounded,
              label: '今日の総時間',
              value: '2時間 30分', // TODO: 実際のデータに置き換え
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.whatshot_rounded,
              label: '連続日数',
              value: '5日', // TODO: 実際のデータに置き換え
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextConsts.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: AnimatedCheckIcon(
          show: _showCompletionAnimation,
          size: 120.0,
          onComplete: () {
            setState(() {
              _showCompletionAnimation = false;
            });
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor(TimerState timerState) {
    if (timerState.mode == TimerMode.countdown) {
      return ColorConsts.primary;
    } else {
      return ColorConsts.success;
    }
  }

  Color _getThemeColor(TimerState timerState) {
    if (timerState.mode == TimerMode.countdown) {
      return ColorConsts.primaryDark;
    } else {
      return const Color(0xFF059669);
    }
  }

  void _showTimerSettingDialog(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    if (timerState.mode == TimerMode.countdown) {
      showDialog(
        context: context,
        builder: (context) {
          int minutes = 25;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'フォーカス時間設定',
              style: TextConsts.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '集中時間を設定してください',
                      style: TextConsts.body.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                    const SizedBox(height: SpacingConsts.l),
                    Container(
                      padding: const EdgeInsets.all(SpacingConsts.l),
                      decoration: BoxDecoration(
                        color: ColorConsts.primaryExtraLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$minutes分',
                            style: TextConsts.h2.copyWith(
                              color: ColorConsts.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: minutes.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            activeColor: ColorConsts.primary,
                            onChanged: (value) {
                              setState(() {
                                minutes = value.toInt();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'キャンセル',
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  timerViewModel.setTime(minutes);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConsts.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '設定',
                  style: TextConsts.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('タイマー終了'),
        content: const Text('タイマーが実行中です。\n本当に終了しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorConsts.error,
            ),
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }
}