import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus {
  synced, // 同期済み
  syncing, // 同期中
  unsynced, // 未同期あり
  error, // エラー
  offline, // オフライン
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  SyncState({required this.status, this.lastSyncTime, this.errorMessage});
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier() : super(SyncState(status: SyncStatus.unsynced));

  void setSyncing() {
    state = SyncState(status: SyncStatus.syncing);
  }

  void setSynced() {
    state = SyncState(status: SyncStatus.synced, lastSyncTime: DateTime.now());
  }

  void setUnsynced() {
    state = SyncState(status: SyncStatus.unsynced);
  }

  void setError(String message) {
    state = SyncState(status: SyncStatus.error, errorMessage: message);
  }

  void setOffline() {
    state = SyncState(status: SyncStatus.offline);
  }
}

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((
  ref,
) {
  return SyncStateNotifier();
});
