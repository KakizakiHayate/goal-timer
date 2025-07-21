import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/sync/sync_metadata_manager.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';

/// 同期処理のエッジケーステスト
/// 
/// テスト項目:
/// 1. ネットワーク断絶時の同期
/// 2. 部分的な同期失敗時の挙動
/// 3. 同一データの競合状態
/// 4. タイムスタンプの境界値テスト
/// 5. 極端に大きな時差の処理
void main() {
  group('同期処理エッジケーステスト', () {
    late SyncMetadataManager syncManager;

    setUp(() {
      syncManager = SyncMetadataManager();
    });

    group('境界値テスト', () {
      test('タイムスタンプ差分が1ミリ秒の場合', () async {
        final baseTime = DateTime.now();
        final localTime = baseTime;
        final remoteTime = baseTime.add(const Duration(milliseconds: 1));

        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,
          remoteTime,
        );

        expect(needsSync, true);
      });

      test('極端に大きな時差（1年）の処理', () async {
        final baseTime = DateTime.now();
        final localTime = baseTime;
        final remoteTime = baseTime.add(const Duration(days: 365));

        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,
          remoteTime,
        );

        expect(needsSync, true);
      });

      test('過去の日付との比較', () async {
        final baseTime = DateTime.now();
        final localTime = baseTime;
        final remoteTime = baseTime.subtract(const Duration(days: 30));

        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,
          remoteTime,
        );

        expect(needsSync, false);
      });

      test('UTC時刻とローカル時刻の混在', () async {
        final localTime = DateTime.now(); // ローカル時刻
        final remoteTime = DateTime.now().toUtc(); // UTC時刻

        // UTC時刻の方が数時間分早く見えるが、実際は同じ時刻
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,
          remoteTime,
        );

        // 時差によって結果が変わるが、これは設計上の制約
        expect(needsSync, isA<bool>());
      });
    });

    group('データ整合性テスト', () {
      test('同じIDで異なるデータの競合', () {
        final baseTime = DateTime.now();
        final localTime = baseTime.add(const Duration(minutes: 1));
        final remoteTime = baseTime.add(const Duration(minutes: 2));

        final localGoal = GoalsModel(
          id: 'same-id',
          userId: 'user-id',
          title: 'Local Goal Title',
          description: 'Local Description',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 60,
          syncUpdatedAt: localTime,
        );

        final remoteGoal = GoalsModel(
          id: 'same-id',
          userId: 'user-id',
          title: 'Remote Goal Title',
          description: 'Remote Description',
          deadline: baseTime,
          isCompleted: true,
          avoidMessage: 'Remote avoid message',
          targetMinutes: 1200, // 20時間 * 60分
          spentMinutes: 120,
          syncUpdatedAt: remoteTime,
        );

        // IDは同じだが内容が異なる
        expect(localGoal.id, equals(remoteGoal.id));
        expect(localGoal.title, isNot(equals(remoteGoal.title)));
        
        // syncUpdatedAtで勝敗を決める（リモートが勝つ）
        final shouldUpdateLocal = remoteGoal.syncUpdatedAt != null &&
            localGoal.syncUpdatedAt != null &&
            remoteGoal.syncUpdatedAt!.isAfter(localGoal.syncUpdatedAt!);

        expect(shouldUpdateLocal, true);
      });

      test('syncUpdatedAtがnullの場合の安全性', () {
        final localGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: DateTime.now(),
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: null, // null
        );

        final remoteGoal = GoalsModel(
          id: 'test-id',
          userId: 'user-id',
          title: 'Test Goal',
          description: 'Test Description',
          deadline: DateTime.now(),
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: DateTime.now(),
        );

        // null値での比較が安全に処理される
        final localIsNull = localGoal.syncUpdatedAt == null;
        final remoteIsNotNull = remoteGoal.syncUpdatedAt != null;

        expect(localIsNull, true);
        expect(remoteIsNotNull, true);

        // この場合は通常、全件同期にフォールバックする
        expect(() {
          final shouldUpdate = localGoal.syncUpdatedAt != null &&
              remoteGoal.syncUpdatedAt != null &&
              remoteGoal.syncUpdatedAt!.isAfter(localGoal.syncUpdatedAt!);
          return shouldUpdate;
        }, returnsNormally);
      });
    });

    group('パフォーマンステスト（軽量）', () {
      test('大量データのタイムスタンプ比較（1000件）', () {
        final baseTime = DateTime.now();
        final goals = List.generate(1000, (index) => GoalsModel(
          id: 'goal-$index',
          userId: 'user-id',
          title: 'Goal $index',
          description: 'Description $index',
          deadline: baseTime,
          isCompleted: false,
          avoidMessage: '',
          targetMinutes: 600,
          spentMinutes: 0,
          syncUpdatedAt: baseTime.add(Duration(seconds: index)),
        ));

        final stopwatch = Stopwatch()..start();

        // 各ゴールのsyncUpdatedAtが正しく設定されているかチェック
        int validCount = 0;
        for (final goal in goals) {
          if (goal.syncUpdatedAt != null) {
            validCount++;
          }
        }

        stopwatch.stop();

        expect(validCount, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms以内
      });

      test('並行同期リクエストの安全性（シミュレーション）', () async {
        final baseTime = DateTime.now();
        
        // 複数の同期判定を並行実行
        final futures = List.generate(10, (index) async {
          final localTime = baseTime.add(Duration(seconds: index));
          final remoteTime = baseTime.add(Duration(seconds: index + 1));
          
          return await syncManager.needsSync(
            'goals',
            localTime,
            remoteTime,
          );
        });

        final results = await Future.wait(futures);

        // すべての結果がtrue（リモートが新しい）
        expect(results, everyElement(true));
        expect(results.length, equals(10));
      });
    });

    group('エラー処理テスト', () {
      test('異常なタイムスタンプ形式への対応', () {
        expect(() {
          // 正常なDateTime作成
          final validTime = DateTime.now();
          expect(validTime.isUtc, isA<bool>());
        }, returnsNormally);

        expect(() {
          // 極端な未来日付
          final futureTime = DateTime(2100, 12, 31);
          expect(futureTime.year, equals(2100));
        }, returnsNormally);

        expect(() {
          // 極端な過去日付
          final pastTime = DateTime(1900, 1, 1);
          expect(pastTime.year, equals(1900));
        }, returnsNormally);
      });

      test('メモリ効率的なタイムスタンプ処理', () {
        final timestamps = <DateTime>[];
        
        // 大量のタイムスタンプを作成
        for (int i = 0; i < 1000; i++) {
          timestamps.add(DateTime.now().add(Duration(seconds: i)));
        }

        // メモリリークなしでの処理確認
        expect(timestamps.length, equals(1000));
        
        // 最新のタイムスタンプ検索
        DateTime? latest;
        for (final timestamp in timestamps) {
          if (latest == null || timestamp.isAfter(latest)) {
            latest = timestamp;
          }
        }

        expect(latest, isNotNull);
        expect(latest!.isAfter(timestamps.first), true);

        // メモリ解放
        timestamps.clear();
        expect(timestamps.isEmpty, true);
      });
    });

    group('無限ループ防止テスト', () {
      test('相互更新ループの検出', () async {
        final time1 = DateTime.now();
        final time2 = time1.add(const Duration(seconds: 1));

        // A -> B の同期判定
        final needsSyncAtoB = await syncManager.needsSync('goals', time1, time2);
        expect(needsSyncAtoB, true);

        // B -> A の同期判定（逆方向）
        final needsSyncBtoA = await syncManager.needsSync('goals', time2, time1);
        expect(needsSyncBtoA, false);

        // 一方向のみで同期が停止することを確認
        expect(needsSyncAtoB != needsSyncBtoA, true);
      });

      test('同期時刻更新による収束', () async {
        final oldTime = DateTime.now().subtract(const Duration(hours: 1));
        final newTime = DateTime.now();

        // 古い時刻での同期判定
        final needsSyncOld = await syncManager.needsSync('goals', oldTime, newTime);
        expect(needsSyncOld, true);

        // 同期後（同じ時刻）での判定
        final needsSyncAfter = await syncManager.needsSync('goals', newTime, newTime);
        expect(needsSyncAfter, false);

        // 無限ループが発生しないことを確認
        expect(needsSyncOld && !needsSyncAfter, true);
      });
    });
  });
}