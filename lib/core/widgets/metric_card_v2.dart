import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';
import 'pressable_card.dart';

/// 改善されたメトリクスカードウィジェット
/// 数値指標をビジュアルに表示
class MetricCardV2 extends StatefulWidget {
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final String? changeText;
  final Color? changeColor;
  final VoidCallback? onTap;

  const MetricCardV2({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.changeText,
    this.changeColor,
    this.onTap,
  });

  @override
  State<MetricCardV2> createState() => _MetricCardV2State();
}

class _MetricCardV2State extends State<MetricCardV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: PressableCard(
          onTap: widget.onTap,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(SpacingConsts.l),
          backgroundColor: ColorConsts.cardBackground,
          borderRadius: 16.0,
          elevation: 1.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイコンとタイトル
              _buildHeader(),
              
              const SizedBox(height: SpacingConsts.m),
              
              // 値表示
              _buildValue(),
              
              // 変化量表示
              if (widget.changeText != null) ...[
                const SizedBox(height: SpacingConsts.s),
                _buildChange(),
              ],
              
              // サブタイトル
              if (widget.subtitle != null) ...[
                const SizedBox(height: SpacingConsts.s),
                _buildSubtitle(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (widget.iconColor ?? ColorConsts.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? ColorConsts.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: SpacingConsts.m),
        Expanded(
          child: Text(
            widget.title,
            style: TextConsts.body.copyWith(
              color: ColorConsts.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: ColorConsts.textTertiary,
          ),
      ],
    );
  }

  Widget _buildValue() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          widget.value,
          style: TextConsts.h2.copyWith(
            color: widget.valueColor ?? ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.unit != null) ...[
          const SizedBox(width: SpacingConsts.xs),
          Text(
            widget.unit!,
            style: TextConsts.body.copyWith(
              color: ColorConsts.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChange() {
    final isPositive = widget.changeText!.startsWith('+');
    final defaultColor = isPositive ? ColorConsts.success : ColorConsts.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.s,
        vertical: SpacingConsts.xs,
      ),
      decoration: BoxDecoration(
        color: (widget.changeColor ?? defaultColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: widget.changeColor ?? defaultColor,
          ),
          const SizedBox(width: SpacingConsts.xs),
          Text(
            widget.changeText!,
            style: TextConsts.caption.copyWith(
              color: widget.changeColor ?? defaultColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.subtitle!,
      style: TextConsts.caption.copyWith(
        color: ColorConsts.textTertiary,
        height: 1.3,
      ),
    );
  }
}