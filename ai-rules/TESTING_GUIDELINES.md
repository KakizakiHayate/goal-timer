# テスト戦略・テストコード規約

このドキュメントは、Goal Timerプロジェクトでのテスト実装の統一基準を定めます。

---

## 🎯 テスト戦略

### テストピラミッド

```
        ┌───────────────┐
        │  E2E/統合     │ ← 少数（画面遷移、データフロー全体）
        ├───────────────┤
        │  Widget       │ ← 中程度（UI、ユーザーインタラクション）
        ├───────────────┤
        │  単体テスト    │ ← 多数（UseCase、Entity、ビジネスロジック）
        └───────────────┘
```

### 各層のテスト責務

| 層 | テスト種類 | 責務 | カバレッジ目標 |
|----|----------|------|--------------|
| **Entity** | 単体テスト | ファクトリーメソッド、fromMap/toMap | 100% |
| **UseCase** | 単体テスト | ビジネスロジック、バリデーション | 90%以上 |
| **ViewModel** | 単体テスト（モック使用） | 状態管理、エラーハンドリング | 80%以上 |
| **Repository** | 統合テスト | ローカル/リモート統合、同期ロジック | 70%以上 |
| **View** | Widgetテスト | UI表示、ユーザーインタラクション | 60%以上 |
| **全体** | E2Eテスト | 画面遷移、データフロー全体 | 主要フロー |

---

## 1️⃣ 単体テスト（Unit Test）

### Entity層のテスト

**目的**: ファクトリーメソッド、fromMap/toMap、ビジネスロジックの検証

#### ✅ DO: Entityのテスト実装

```dart
// test/unit/models/daily_study_log_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';

void main() {
  group('DailyStudyLogModel', () {
    group('create factory', () {
      test('should create model with correct default values', () {
        // Arrange
        const goalId = 'goal-123';
        const totalSeconds = 3600;

        // Act
        final log = DailyStudyLogModel.create(
          goalId: goalId,
          totalSeconds: totalSeconds,
        );

        // Assert
        expect(log.id, isNotEmpty);
        expect(log.goalId, equals(goalId));
        expect(log.totalSeconds, equals(totalSeconds));
        expect(log.isSynced, equals(false)); // デフォルト値
        expect(log.date.day, equals(DateTime.now().day)); // 日付正規化
      });

      test('should normalize date to start of day', () {
        // Arrange
        final now = DateTime.now();
        final expected = DateTime(now.year, now.month, now.day);

        // Act
        final log = DailyStudyLogModel.create(
          goalId: 'goal-123',
          totalSeconds: 60,
        );

        // Assert
        expect(log.date, equals(expected));
      });
    });

    group('fromMap/toMap', () {
      test('should convert from map correctly', () {
        // Arrange
        final now = DateTime.now();
        final map = {
          'id': 'test-id',
          'goal_id': 'goal-id',
          'date': now.toIso8601String(),
          'total_seconds': 3600,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'sync_updated_at': now.toIso8601String(),
          'is_synced': 1,
        };

        // Act
        final log = DailyStudyLogModel.fromMap(map);

        // Assert
        expect(log.id, equals('test-id'));
        expect(log.goalId, equals('goal-id'));
        expect(log.totalSeconds, equals(3600));
        expect(log.isSynced, equals(true));
      });

      test('should convert to map correctly', () {
        // Arrange
        final now = DateTime.now();
        final log = DailyStudyLogModel(
          id: 'test-id',
          goalId: 'goal-id',
          date: now,
          totalSeconds: 3600,
          createdAt: now,
          updatedAt: now,
          syncUpdatedAt: now,
          isSynced: true,
        );

        // Act
        final map = log.toMap();

        // Assert
        expect(map['id'], equals('test-id'));
        expect(map['goal_id'], equals('goal-id'));
        expect(map['total_seconds'], equals(3600));
        expect(map['is_synced'], equals(1));
      });
    });
  });
}
```

### UseCase層のテスト

**目的**: ビジネスロジック、バリデーション、エラーハンドリングの検証

#### ✅ DO: UseCaseのテスト実装（モック使用）

```dart
// test/unit/usecases/save_study_log_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goal_timer/core/usecases/daily_study_logs/save_study_log_usecase.dart';
import 'package:goal_timer/core/data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';

import 'save_study_log_usecase_test.mocks.dart';

// ✅ Mockitoでモック生成
@GenerateMocks([DailyStudyLogsRepository])
void main() {
  group('SaveStudyLogUseCase', () {
    late MockDailyStudyLogsRepository mockRepository;
    late SaveStudyLogUseCase useCase;

    setUp(() {
      mockRepository = MockDailyStudyLogsRepository();
      useCase = SaveStudyLogUseCase(repository: mockRepository);
    });

    group('execute', () {
      test('should save study log successfully', () async {
        // Arrange
        const goalId = 'goal-123';
        const totalSeconds = 3600;
        final expectedLog = DailyStudyLogModel.create(
          goalId: goalId,
          totalSeconds: totalSeconds,
        );

        when(mockRepository.upsertDailyLog(any))
            .thenAnswer((_) async => expectedLog);

        // Act
        final result = await useCase.execute(
          goalId: goalId,
          studyDurationInSeconds: totalSeconds,
        );

        // Assert
        expect(result.goalId, equals(goalId));
        expect(result.totalSeconds, equals(totalSeconds));
        verify(mockRepository.upsertDailyLog(any)).called(1);
      });

      test('should throw ArgumentError when studyDurationInSeconds <= 0', () async {
        // Arrange
        const goalId = 'goal-123';
        const invalidSeconds = 0;

        // Act & Assert
        expect(
          () => useCase.execute(
            goalId: goalId,
            studyDurationInSeconds: invalidSeconds,
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Repositoryが呼ばれていないことを確認
        verifyNever(mockRepository.upsertDailyLog(any));
      });

      test('should throw ArgumentError when studyDurationInSeconds < 0', () async {
        // Arrange
        const goalId = 'goal-123';
        const invalidSeconds = -100;

        // Act & Assert
        expect(
          () => useCase.execute(
            goalId: goalId,
            studyDurationInSeconds: invalidSeconds,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should propagate repository errors', () async {
        // Arrange
        const goalId = 'goal-123';
        const totalSeconds = 3600;

        when(mockRepository.upsertDailyLog(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase.execute(
            goalId: goalId,
            studyDurationInSeconds: totalSeconds,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
```

### ViewModel層のテスト

**目的**: 状態管理、エラーハンドリング、UseCaseとの統合の検証

#### ✅ DO: ViewModelのテスト実装

```dart
// test/unit/timer/timer_view_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goal_timer/features/timer/presentation/timer_view_model.dart';
import 'package:goal_timer/core/usecases/daily_study_logs/save_study_log_usecase.dart';

import 'timer_view_model_test.mocks.dart';

@GenerateMocks([SaveStudyLogUseCase, Ref])
void main() {
  group('TimerViewModel', () {
    late MockSaveStudyLogUseCase mockSaveStudyLogUseCase;
    late MockRef<TimerState> mockRef;
    late TimerViewModel viewModel;

    setUp(() {
      mockSaveStudyLogUseCase = MockSaveStudyLogUseCase();
      mockRef = MockRef<TimerState>();

      viewModel = TimerViewModel(
        ref: mockRef,
        saveStudyLogUseCase: mockSaveStudyLogUseCase,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('completeSession', () {
      test('should save study log successfully', () async {
        // Arrange
        const goalId = 'goal-123';
        const studyTimeInSeconds = 3600;
        viewModel.setGoalId(goalId);

        final expectedLog = DailyStudyLogModel.create(
          goalId: goalId,
          totalSeconds: studyTimeInSeconds,
        );

        when(mockSaveStudyLogUseCase.execute(
          goalId: goalId,
          studyDurationInSeconds: studyTimeInSeconds,
        )).thenAnswer((_) async => expectedLog);

        // Act
        await viewModel.completeSession(
          studyTimeInSeconds: studyTimeInSeconds,
        );

        // Assert
        verify(mockSaveStudyLogUseCase.execute(
          goalId: goalId,
          studyDurationInSeconds: studyTimeInSeconds,
        )).called(1);
        expect(viewModel.state.status, equals(TimerStatus.completed));
      });

      test('should handle error when save fails', () async {
        // Arrange
        const goalId = 'goal-123';
        const studyTimeInSeconds = 3600;
        viewModel.setGoalId(goalId);

        when(mockSaveStudyLogUseCase.execute(
          goalId: any,
          studyDurationInSeconds: any,
        )).thenThrow(Exception('Save failed'));

        // Act & Assert
        expect(
          () => viewModel.completeSession(
            studyTimeInSeconds: studyTimeInSeconds,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should not save when studyTimeInSeconds <= 0', () async {
        // Arrange
        const goalId = 'goal-123';
        const invalidSeconds = 0;
        viewModel.setGoalId(goalId);

        // Act
        await viewModel.completeSession(
          studyTimeInSeconds: invalidSeconds,
        );

        // Assert
        verifyNever(mockSaveStudyLogUseCase.execute(
          goalId: any,
          studyDurationInSeconds: any,
        ));
      });
    });
  });
}
```

---

## 2️⃣ Widgetテスト

### 目的

UI表示、ユーザーインタラクション、状態変化の検証

### ✅ DO: Widgetテストの実装

```dart
// test/widget/timer_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/timer/presentation/timer_screen.dart';

void main() {
  testWidgets('should display timer with initial time', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TimerScreen(),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('should start timer when play button is tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TimerScreen(),
        ),
      ),
    );

    // Act
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
```

---

## 3️⃣ 統合テスト（Integration Test）

### 目的

Repository〜DataSource間の同期ロジック、データフロー全体の検証

### ✅ DO: 統合テストの実装

```dart
// test/integration/sync_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/sync/sync_metadata_manager.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';

void main() {
  group('同期処理統合テスト', () {
    late SyncMetadataManager syncManager;

    setUp(() {
      syncManager = SyncMetadataManager();
    });

    group('SyncMetadataManager.needsSync', () {
      test('両方nullなら同期不要', () async {
        // Act
        final needsSync = await syncManager.needsSync(
          'goals',
          null, // localSyncUpdatedAt
          null, // remoteSyncUpdatedAt
        );

        // Assert
        expect(needsSync, false);
      });

      test('片方だけnullなら同期必要（ローカルのみ）', () async {
        // Arrange
        final localTime = DateTime.now();

        // Act
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime, // localSyncUpdatedAt
          null,      // remoteSyncUpdatedAt
        );

        // Assert
        expect(needsSync, true);
      });

      test('リモートが新しい場合は同期必要', () async {
        // Arrange
        final localTime = DateTime.now();
        final remoteTime = localTime.add(const Duration(minutes: 5));

        // Act
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,  // localSyncUpdatedAt
          remoteTime, // remoteSyncUpdatedAt
        );

        // Assert
        expect(needsSync, true);
      });

      test('ローカルが新しい場合は同期不要', () async {
        // Arrange
        final remoteTime = DateTime.now();
        final localTime = remoteTime.add(const Duration(minutes: 5));

        // Act
        final needsSync = await syncManager.needsSync(
          'goals',
          localTime,  // localSyncUpdatedAt
          remoteTime, // remoteSyncUpdatedAt
        );

        // Assert
        expect(needsSync, false);
      });
    });
  });
}
```

---

## 4️⃣ Mockitoの使い方

### @GenerateM ocks アノテーション

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// ✅ モック生成対象を指定
@GenerateMocks([
  DailyStudyLogsRepository,
  SaveStudyLogUseCase,
  Ref,
])
void main() {
  // ...
}
```

### モック生成コマンド

```bash
# モッククラスを生成
flutter pub run build_runner build --delete-conflicting-outputs
```

### ✅ DO: Mockitoの基本的な使い方

```dart
// Arrange（モックの振る舞いを定義）
when(mockRepository.upsertDailyLog(any))
    .thenAnswer((_) async => expectedLog);

// Act（テスト対象のメソッドを実行）
final result = await useCase.execute(...);

// Assert（結果とモックの呼び出しを検証）
expect(result.goalId, equals('goal-123'));
verify(mockRepository.upsertDailyLog(any)).called(1);
verifyNever(mockRepository.deleteDailyLog(any));
```

---

## 5️⃣ テストデータ管理

### StatisticsTestData パターン

テストデータを一元管理するヘルパークラスを作成します。

```dart
// test/helpers/statistics_test_data.dart

class StatisticsTestData {
  static const String goal1Id = 'goal-1';
  static const String goal2Id = 'goal-2';

  /// テスト用の目標データ
  static List<GoalsModel> get mockGoals => [
    GoalsModel(
      id: goal1Id,
      userId: 'user-1',
      title: '英語学習',
      targetMinutes: 420,
      spentMinutes: 420,
      deadline: DateTime(2025, 12, 31),
      isCompleted: false,
    ),
    GoalsModel(
      id: goal2Id,
      userId: 'user-1',
      title: 'プログラミング',
      targetMinutes: 300,
      spentMinutes: 225,
      deadline: DateTime(2025, 12, 31),
      isCompleted: false,
    ),
  ];

  /// 今週の学習記録データ
  static List<DailyStudyLogModel> get thisWeekStudyLogs {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return [
      ...List.generate(7, (index) => DailyStudyLogModel(
        id: 'log-week-goal1-$index',
        goalId: goal1Id,
        totalSeconds: 60 * 60,
        date: startOfWeek.add(Duration(days: index)),
      )),
    ];
  }
}
```

### 使用例

```dart
test('should calculate total study time correctly', () {
  // Arrange
  final goals = StatisticsTestData.mockGoals;
  final logs = StatisticsTestData.thisWeekStudyLogs;

  // Act
  final totalMinutes = calculateTotalMinutes(logs);

  // Assert
  expect(totalMinutes, equals(420)); // 60分 × 7日
});
```

---

## 6️⃣ テストファイル命名規則・配置ルール

### ディレクトリ構造

```
test/
├── unit/                      # 単体テスト
│   ├── models/               # Entity
│   ├── usecases/             # UseCase
│   ├── timer/                # ViewModel
│   └── services/             # Service
│
├── widget/                    # Widgetテスト
│   └── timer_screen_test.dart
│
├── integration/               # 統合テスト
│   ├── sync_integration_test.dart
│   └── onboarding_flow_test.dart
│
├── e2e/                       # E2Eテスト
│   └── onboarding_flow_e2e_test.dart
│
└── helpers/                   # テストヘルパー
    ├── test_helpers.dart
    └── statistics_test_data.dart
```

### ファイル命名規則

| テスト対象 | ファイル名 |
|----------|-----------|
| Entity | `[モデル名]_model_test.dart` |
| UseCase | `[ユースケース名]_usecase_test.dart` |
| ViewModel | `[機能名]_view_model_test.dart` |
| Screen | `[画面名]_screen_test.dart` |
| Repository | `[機能名]_repository_test.dart` |

---

## 7️⃣ テストカバレッジ目標

### カバレッジ測定コマンド

```bash
# カバレッジを測定
flutter test --coverage

# HTMLレポート生成
genhtml coverage/lcov.info -o coverage/html

# レポートを開く
open coverage/html/index.html
```

### カバレッジ目標

| 層 | 目標 |
|----|------|
| **Entity** | 100% |
| **UseCase** | 90%以上 |
| **ViewModel** | 80%以上 |
| **Repository** | 70%以上 |
| **View** | 60%以上 |
| **全体** | 70%以上 |

---

## 8️⃣ テスト実装チェックリスト

### 単体テスト
- [ ] Entityのファクトリーメソッドをテストしている
- [ ] fromMap/toMapをテストしている
- [ ] UseCaseのバリデーションをテストしている
- [ ] UseCaseのエラーハンドリングをテストしている
- [ ] ViewModelの状態変化をテストしている
- [ ] Mockitoでモックを作成している

### Widgetテスト
- [ ] UI表示をテストしている
- [ ] ユーザーインタラクションをテストしている
- [ ] 状態変化に応じたUI更新をテストしている

### 統合テスト
- [ ] Repository〜DataSource間の統合をテストしている
- [ ] 同期ロジックをテストしている
- [ ] データフロー全体をテストしている

### テストデータ
- [ ] テストデータヘルパーを作成している
- [ ] テストデータを再利用している

---

## まとめ

### テストの5原則

1. **テストピラミッドに従う**: 単体テスト > Widgetテスト > 統合テスト
2. **Pure Dartテスト優先**: UseCaseは純粋な単体テストで検証
3. **モックを活用**: Mockitoで依存関係を注入
4. **テストデータ一元管理**: ヘルパークラスで再利用
5. **カバレッジ目標を達成**: 全体70%以上

### 必須実装項目

- [ ] Entityのテスト（ファクトリー、fromMap/toMap）
- [ ] UseCaseのテスト（ビジネスロジック、バリデーション）
- [ ] ViewModelのテスト（状態管理、エラーハンドリング）
- [ ] 統合テスト（同期ロジック、データフロー）
- [ ] テストデータヘルパーの作成

**このガイドラインに従うことで、品質の高いテストコードを書くことができます。**
