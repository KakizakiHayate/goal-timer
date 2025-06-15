import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/data/datasources/local/goals/local_goals_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/features/shared/widgets/sync_status_indicator.dart';

class SyncDebugView extends ConsumerStatefulWidget {
  const SyncDebugView({super.key});

  @override
  ConsumerState<SyncDebugView> createState() => _SyncDebugViewState();
}

class _SyncDebugViewState extends ConsumerState<SyncDebugView> {
  bool isLoading = false;
  List<GoalsModel> localGoals = [];
  List<GoalsModel> remoteGoals = [];
  String syncStatus = "未確認";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // ローカルデータの取得
      final localDataSource = LocalGoalsDatasource();
      localGoals = await localDataSource.getGoals();

      // リモートデータの取得
      final remoteDataSource = ref.read(goalsRepositoryProvider);
      remoteGoals = await remoteDataSource.getGoals();

      // 同期状態の確認
      ref.read(hybridGoalsRepositoryProvider);
      syncStatus = "ハイブリッドリポジトリ準備完了";
    } catch (e) {
      setState(() {
        errorMessage = "データ取得エラー: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> performManualSync() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final syncNotifier = ref.read(syncStateProvider.notifier);
      syncNotifier.setSyncing();

      // 手動同期を実行
      final hybridRepo = ref.read(hybridGoalsRepositoryProvider);
      await hybridRepo.syncWithRemote();

      syncNotifier.setSynced();

      // データを再読み込み
      await loadData();
    } catch (e) {
      setState(() {
        errorMessage = "同期エラー: $e";
      });

      final syncNotifier = ref.read(syncStateProvider.notifier);
      syncNotifier.setError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同期デバッグ'),
        actions: const [SyncStatusIndicator()],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.red.shade100,
                          width: double.infinity,
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildSyncStatusSection(syncState),
                      const SizedBox(height: 16),
                      _buildDataSection('ローカルデータ', localGoals),
                      const SizedBox(height: 24),
                      _buildDataSection('リモートデータ', remoteGoals),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : loadData,
                  child: const Text('データ再読込'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : performManualSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('手動同期実行'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection(SyncState state) {
    String statusText;
    Color statusColor;

    switch (state.status) {
      case SyncStatus.synced:
        statusText = '同期済み';
        statusColor = Colors.green;
        break;
      case SyncStatus.syncing:
        statusText = '同期中...';
        statusColor = Colors.blue;
        break;
      case SyncStatus.unsynced:
        statusText = '未同期あり';
        statusColor = Colors.orange;
        break;
      case SyncStatus.error:
        statusText = 'エラー: ${state.errorMessage}';
        statusColor = Colors.red;
        break;
      case SyncStatus.offline:
        statusText = 'オフライン';
        statusColor = Colors.grey;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同期状態', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (state.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text('最終同期: ${_formatDateTime(state.lastSyncTime!)}'),
            ],
            const SizedBox(height: 8),
            Text('ハイブリッドリポジトリ: $syncStatus'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, List<GoalsModel> goals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${goals.length}件)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            if (goals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('データがありません')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return ListTile(
                    title: Text(goal.title),
                    subtitle: Text(
                      'ID: ${goal.id}\n'
                      '更新: ${goal.updatedAt?.toString() ?? "未設定"}\n'
                      '同期: ${goal.isSynced ? "済" : "未"}',
                    ),
                    trailing: const Text('同期状態'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }
}
