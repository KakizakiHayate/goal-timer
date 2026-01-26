import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/firebase_service.dart';

void main() {
  group('FirebaseService Tests', () {
    group('シングルトンパターン', () {
      test('同じインスタンスが返されること', () {
        final instance1 = FirebaseService();
        final instance2 = FirebaseService();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('初期化前の状態', () {
      test('初期化前はanalyticsがnullであること', () {
        final service = FirebaseService();

        // 初期化前の状態では analytics は null
        // 注: 実際のFirebase初期化は統合テストで確認
        expect(service.analytics, isNull);
      });
    });

    // Note: Firebase.initializeApp() のテストは統合テストで実施
    // ユニットテストではFirebaseプラットフォームのモック化が困難なため
    //
    // 手動テスト項目:
    // 1. アプリ起動時にログ「FirebaseService: Firebase初期化が完了しました」が出力される
    // 2. デバッグビルドでは「Crashlyticsはデバッグモードのため無効化」が出力される
    // 3. Firebase Console > Analytics > DebugView でイベントが確認できる

    group('マイグレーションイベント', () {
      // Note: analyticsが初期化されていない状態でもエラーなく動作することを確認
      // 実際のイベント送信は統合テストで確認

      test('logMigrationCompletedがエラーなく呼び出せること', () async {
        final service = FirebaseService();

        // analyticsがnullの状態でも例外が発生しないこと
        await expectLater(
          service.logMigrationCompleted(
            userId: 'test-user',
            goalCount: 5,
            studyLogCount: 10,
          ),
          completes,
        );
      });

      test('logMigrationFailedがエラーなく呼び出せること', () async {
        final service = FirebaseService();

        await expectLater(
          service.logMigrationFailed(
            userId: 'test-user',
            errorMessage: 'Test error',
          ),
          completes,
        );
      });
    });
  });
}
