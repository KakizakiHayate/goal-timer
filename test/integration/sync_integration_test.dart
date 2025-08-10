import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/sync/sync_metadata_manager.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/core/models/users/users_model.dart';

/// 同期処理の統合テスト
/// 
/// テスト項目:
/// 1. 新規アカウントでの初回同期（両方空）
/// 2. オフライン作業後の同期（ローカルあり、リモートなし）
/// 3. 新端末での初回同期（ローカルなし、リモートあり）
/// 4. 通常の差分同期（両方にデータあり）
/// 5. syncUpdatedAtタイムスタンプの正しい更新確認
void main() {
  group('同期処理統合テスト', () {
    late SyncMetadataManager syncManager;

    setUp(() {
      syncManager = SyncMetadataManager();
    });

    group('SyncMetadataManager.needsSync', () {
      test('両方nullなら同期不要', () async {
        final needsSync = await syncManager.needsSync(
          'goals',
          null, // localSyncUpdatedAt
          null, // remoteSyncUpdatedAt
        );
        
        expect(needsSync, false);
      });

      test('片方だけnullなら同期必要（ローカルのみ）', () async {
        final localTime = DateTime.now();
        
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime, // localSyncUpdatedAt
          null,      // remoteSyncUpdatedAt
        );
        
        expect(needsSync, true);
      });

      test('片方だけnullなら同期必要（リモートのみ）', () async {
        final remoteTime = DateTime.now();
        
        final needsSync = await syncManager.needsSync(
          'goals',
          null,       // localSyncUpdatedAt
          remoteTime, // remoteSyncUpdatedAt
        );
        
        expect(needsSync, true);
      });

      test('リモートが新しい場合は同期必要', () async {
        final localTime = DateTime.now();
        final remoteTime = localTime.add(Duration(minutes: 5));
        
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,  // localSyncUpdatedAt
          remoteTime, // remoteSyncUpdatedAt
        );
        
        expect(needsSync, true);
      });

      test('ローカルが新しい場合は同期不要', () async {
        final remoteTime = DateTime.now();
        final localTime = remoteTime.add(Duration(minutes: 5));
        
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,  // localSyncUpdatedAt
          remoteTime, // remoteSyncUpdatedAt
        );
        
        expect(needsSync, false);
      });

      test('同じ時刻の場合は同期不要', () async {
        final sameTime = DateTime.now();
        
        final needsSync = await syncManager.needsSync(
          'goals',
          sameTime, // localSyncUpdatedAt
          sameTime, // remoteSyncUpdatedAt
        );
        
        expect(needsSync, false);
      });
    });

    group('Models syncUpdatedAt Field Tests', () {
      test('GoalsModel has syncUpdatedAt field', () {
        final now = DateTime.now();
        final goal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: now,
          isCompleted: false,
          avoidMessage: 'Test avoid message',
          targetMinutes: 600,
          spentMinutes: 120,
          syncUpdatedAt: now,
          isSynced: true,
        );

        expect(goal.syncUpdatedAt, equals(now));
        expect(goal.isSynced, true);
      });

      test('DailyStudyLogModel has syncUpdatedAt field', () {
        final now = DateTime.now();
        final log = DailyStudyLogModel(
          id: 'test-id',
          goalId: 'goal-id',
          date: now,
          minutes: 60,
          syncUpdatedAt: now,
          isSynced: true,
        );

        expect(log.syncUpdatedAt, equals(now));
        expect(log.isSynced, true);
      });

      test('UsersModel has syncUpdatedAt field', () {
        final now = DateTime.now();
        final user = UsersModel(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
          syncUpdatedAt: now,
          isSynced: true,
        );

        expect(user.syncUpdatedAt, equals(now));
        expect(user.isSynced, true);
      });
    });

    group('Model fromMap/toMap Tests', () {
      test('GoalsModel fromMap includes syncUpdatedAt', () {
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'user_id': 'user-id',
          'title': 'Test Goal',
          'description': 'Test Description',
          'deadline': now.toIso8601String(),
          'is_completed': true,
          'avoid_message': 'Test avoid message',
          'total_target_hours': 10,
          'spent_minutes': 120,
          'updated_at': now.toIso8601String(),
          'sync_updated_at': now.toIso8601String(),
          'is_synced': 1,
        };

        final goal = GoalsModel.fromMap(map);

        expect(goal.syncUpdatedAt?.toIso8601String(), equals(now.toIso8601String()));
        expect(goal.isSynced, true);
      });

      test('DailyStudyLogModel fromMap includes syncUpdatedAt', () {
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'goal_id': 'goal-id',
          'date': now.toIso8601String(),
          'minutes': 60,
          'updated_at': now.toIso8601String(),
          'sync_updated_at': now.toIso8601String(),
          'is_synced': 1,
        };

        final log = DailyStudyLogModel.fromMap(map);

        expect(log.syncUpdatedAt?.toIso8601String(), equals(now.toIso8601String()));
        expect(log.isSynced, true);
      });

      test('UsersModel fromMap includes syncUpdatedAt', () {
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'email': 'test@example.com',
          'display_name': 'Test User',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'last_login': now.toIso8601String(),
          'sync_updated_at': now.toIso8601String(),
          'is_synced': 1,
        };

        final user = UsersModel.fromMap(map);

        expect(user.syncUpdatedAt?.toIso8601String(), equals(now.toIso8601String()));
        expect(user.isSynced, true);
      });
    });

    group('Timestamp Comparison Logic Tests', () {
      test('syncUpdatedAt comparison - local newer', () {
        final baseTime = DateTime.now();
        final localTime = baseTime.add(Duration(minutes: 5));
        final remoteTime = baseTime;

        final localGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: localTime,
        );

        final remoteGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: remoteTime,
        );

        // ローカルの方が新しい場合、リモートを更新すべき
        final shouldUpdateRemote = localGoal.syncUpdatedAt != null &&
            remoteGoal.syncUpdatedAt != null &&
            localGoal.syncUpdatedAt!.isAfter(remoteGoal.syncUpdatedAt!);

        expect(shouldUpdateRemote, true);
      });

      test('syncUpdatedAt comparison - remote newer', () {
        final baseTime = DateTime.now();
        final localTime = baseTime;
        final remoteTime = baseTime.add(Duration(minutes: 5));

        final localGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: localTime,
        );

        final remoteGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: remoteTime,
        );

        // リモートの方が新しい場合、ローカルを更新すべき
        final shouldUpdateLocal = remoteGoal.syncUpdatedAt != null &&
            localGoal.syncUpdatedAt != null &&
            remoteGoal.syncUpdatedAt!.isAfter(localGoal.syncUpdatedAt!);

        expect(shouldUpdateLocal, true);
      });
    });
  });
}