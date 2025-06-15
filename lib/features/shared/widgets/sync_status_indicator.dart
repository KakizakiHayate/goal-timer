import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    Widget icon;
    Color color;
    String tooltip;

    switch (syncState.status) {
      case SyncStatus.synced:
        icon = const Icon(Icons.cloud_done);
        color = Colors.green;
        tooltip = '同期済み: ${_formatDateTime(syncState.lastSyncTime)}';
        break;
      case SyncStatus.syncing:
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
        color = Colors.blue;
        tooltip = '同期中...';
        break;
      case SyncStatus.unsynced:
        icon = const Icon(Icons.cloud_upload);
        color = Colors.orange;
        tooltip = '未同期のデータがあります';
        break;
      case SyncStatus.error:
        icon = const Icon(Icons.error_outline);
        color = Colors.red;
        tooltip = '同期エラー: ${syncState.errorMessage}';
        break;
      case SyncStatus.offline:
        icon = const Icon(Icons.cloud_off);
        color = Colors.grey;
        tooltip = 'オフラインモード';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: icon,
        color: color,
        onPressed:
            syncState.status == SyncStatus.syncing
                ? null
                : () => _manualSync(ref),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '不明';
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }

  Future<void> _manualSync(WidgetRef ref) async {
    // 実際の同期コードは準備ができたら有効化する
    // final hybridRepo = ref.read(hybridGoalsRepositoryProvider);
    final notifier = ref.read(syncStateProvider.notifier);

    notifier.setSyncing();
    try {
      // await hybridRepo.syncWithRemote();
      // テスト用に少し待機
      await Future.delayed(const Duration(seconds: 2));
      notifier.setSynced();
    } catch (e) {
      notifier.setError(e.toString());
    }
  }
}
