import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/spacing_consts.dart';
import 'package:goal_timer/core/utils/text_consts.dart';
import 'package:goal_timer/core/utils/time_utils.dart';
import 'package:goal_timer/features/study_records/view_model/study_records_view_model.dart';

/// 日別学習記録のボトムシート
class DailyRecordBottomSheet extends StatelessWidget {
  final DateTime date;
  final List<DailyRecord> records;

  const DailyRecordBottomSheet({
    super.key,
    required this.date,
    required this.records,
  });

  /// ボトムシートを表示
  static Future<void> show({
    required BuildContext context,
    required DateTime date,
    required List<DailyRecord> records,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DailyRecordBottomSheet(
        date: date,
        records: records,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1),
            _buildRecordsList(),
            const SizedBox(height: SpacingConsts.m),
          ],
        ),
      ),
    );
  }

  /// ドラッグハンドル
  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: SpacingConsts.s),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: ColorConsts.disabled,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// ヘッダー（日付と合計時間）
  Widget _buildHeader() {
    final totalSeconds = records.fold<int>(
      0,
      (sum, record) => sum + record.totalSeconds,
    );

    return Padding(
      padding: const EdgeInsets.all(SpacingConsts.m),
      child: Column(
        children: [
          Text(
            _formatDate(date),
            style: TextConsts.h4,
          ),
          const SizedBox(height: SpacingConsts.xs),
          Text(
            '合計: ${TimeUtils.formatSecondsToHoursAndMinutes(totalSeconds)}',
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 学習記録リスト
  Widget _buildRecordsList() {
    return Builder(
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.4;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConsts.m,
              vertical: SpacingConsts.s,
            ),
            itemCount: records.length,
            separatorBuilder: (context, index) => const SizedBox(
              height: SpacingConsts.s,
            ),
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildRecordItem(record);
            },
          ),
        );
      },
    );
  }

  /// 個別の学習記録アイテム
  Widget _buildRecordItem(DailyRecord record) {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              record.goalTitle,
              style: TextConsts.bodyMedium.copyWith(
                color: record.isDeleted
                    ? ColorConsts.textTertiary
                    : ColorConsts.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: SpacingConsts.m),
          Text(
            TimeUtils.formatSecondsToHoursAndMinutes(record.totalSeconds),
            style: TextConsts.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConsts.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日（$weekday）';
  }
}
