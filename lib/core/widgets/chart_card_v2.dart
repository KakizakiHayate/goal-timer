import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';
import 'pressable_card.dart';

/// 改善されたチャートカードウィジェット
/// 統計情報をグラフィカルに表示
class ChartCardV2 extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final List<ChartLegendItem>? legendItems;
  final VoidCallback? onTap;

  const ChartCardV2({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.legendItems,
    this.onTap,
  });

  @override
  State<ChartCardV2> createState() => _ChartCardV2State();
}

class _ChartCardV2State extends State<ChartCardV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.slow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
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
      child: PressableCard(
        onTap: widget.onTap,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(SpacingConsts.l),
        backgroundColor: ColorConsts.cardBackground,
        borderRadius: 20.0,
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(),
            
            const SizedBox(height: SpacingConsts.l),
            
            // チャート
            SizedBox(
              height: 200,
              child: widget.chart,
            ),
            
            // 凡例
            if (widget.legendItems != null) ...[
              const SizedBox(height: SpacingConsts.l),
              _buildLegend(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextConsts.h4.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ColorConsts.textTertiary,
              ),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: SpacingConsts.xs),
          Text(
            widget.subtitle!,
            style: TextConsts.body.copyWith(
              color: ColorConsts.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: SpacingConsts.m,
      runSpacing: SpacingConsts.s,
      children: widget.legendItems!.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: SpacingConsts.s),
            Text(
              item.label,
              style: TextConsts.caption.copyWith(
                color: ColorConsts.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ChartLegendItem {
  final String label;
  final Color color;

  const ChartLegendItem({
    required this.label,
    required this.color,
  });
}