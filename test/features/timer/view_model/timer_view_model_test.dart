import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_settings_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/services/notification_service.dart';
import 'package:goal_timer/features/settings/view_model/settings_view_model.dart';
import 'package:goal_timer/features/timer/view_model/timer_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

/// GetxControllerを継承したFakeクラス（Mockではなく）
class FakeSettingsViewModel extends GetxController
    implements SettingsViewModel {
  @override
  final RxInt defaultTimerSeconds =
      LocalSettingsDataSource.defaultTimerSeconds.obs;

  @override
  final RxBool streakReminderEnabled = true.obs;

  @override
  final RxString displayName = 'テストユーザー'.obs;

  @override
  final RxBool isUpdatingDisplayName = false.obs;

  @override
  Future<void> init() async {}

  @override
  Future<void> updateDefaultTimerDuration(Duration duration) async {}

  @override
  Future<void> updateStreakReminderEnabled(bool enabled) async {
    streakReminderEnabled.value = enabled;
  }

  @override
  String get formattedDefaultTime => '25:00';

  @override
  Future<bool> checkNetworkConnection() async => true;

  @override
  Future<bool> updateDisplayName(String newName) async {
    displayName.value = newName;
    return true;
  }

  @override
  Future<void> refreshDisplayName() async {}
}

/// テスト用MockNotificationService
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAppDatabase mockDatabase;
  late FakeSettingsViewModel fakeSettingsViewModel;
  late MockNotificationService mockNotificationService;
  late GoalsModel testGoal;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    fakeSettingsViewModel = FakeSettingsViewModel();
    mockNotificationService = MockNotificationService();
    testGoal = GoalsModel(
      id: 'test-goal-id',
      userId: 'test-user-id',
      title: 'Test Goal',
      description: 'Test Description',
      targetMinutes: 1500,
      avoidMessage: 'Test avoid message',
      deadline: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Get.put<AppDatabase>(mockDatabase);
    Get.put<SettingsViewModel>(fakeSettingsViewModel);

    // MockNotificationServiceのスタブ設定
    when(() => mockNotificationService.init()).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelAllNotifications(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelScheduledNotification(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.requestPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationService.scheduleTimerCompletionNotification(
        seconds: any(named: 'seconds'),
        goalTitle: any(named: 'goalTitle'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showTimerCompletionNotification(
        goalTitle: any(named: 'goalTitle'),
      ),
    ).thenAnswer((_) async {});
  });

  /// テスト用のTimerViewModelを作成するヘルパー関数
  TimerViewModel createTestViewModel() {
    return TimerViewModel(
      goal: testGoal,
      notificationService: mockNotificationService,
    );
  }

  tearDown(() {
    Get.reset();
  });

  group('TimerState Tests', () {
    group('isModeSwitchable', () {
      test('initial状態ではisModeSwitchableがtrueを返すこと', () {
        // Arrange
        final state = TimerState(status: TimerStatus.initial);

        // Act & Assert
        expect(state.isModeSwitchable, isTrue);
      });

      test('running状態ではisModeSwitchableがfalseを返すこと', () {
        // Arrange
        final state = TimerState(status: TimerStatus.running);

        // Act & Assert
        expect(state.isModeSwitchable, isFalse);
      });

      test('paused状態ではisModeSwitchableがfalseを返すこと', () {
        // Arrange
        final state = TimerState(status: TimerStatus.paused);

        // Act & Assert
        expect(state.isModeSwitchable, isFalse);
      });

      test('completed状態ではisModeSwitchableがtrueを返すこと', () {
        // Arrange
        final state = TimerState(status: TimerStatus.completed);

        // Act & Assert
        expect(state.isModeSwitchable, isTrue);
      });
    });

    group('TimerState copyWith', () {
      test('statusをrunningに変更するとisModeSwitchableがfalseになること', () {
        // Arrange
        final initialState = TimerState(status: TimerStatus.initial);
        expect(initialState.isModeSwitchable, isTrue);

        // Act
        final runningState = initialState.copyWith(status: TimerStatus.running);

        // Assert
        expect(runningState.isModeSwitchable, isFalse);
      });

      test('statusをpausedに変更するとisModeSwitchableがfalseになること', () {
        // Arrange
        final runningState = TimerState(status: TimerStatus.running);

        // Act
        final pausedState = runningState.copyWith(status: TimerStatus.paused);

        // Assert
        expect(pausedState.isModeSwitchable, isFalse);
      });

      test('statusをinitialに戻すとisModeSwitchableがtrueになること', () {
        // Arrange
        final pausedState = TimerState(status: TimerStatus.paused);
        expect(pausedState.isModeSwitchable, isFalse);

        // Act
        final resetState = pausedState.copyWith(status: TimerStatus.initial);

        // Assert
        expect(resetState.isModeSwitchable, isTrue);
      });

      test('statusをcompletedに変更するとisModeSwitchableがtrueになること', () {
        // Arrange
        final runningState = TimerState(status: TimerStatus.running);
        expect(runningState.isModeSwitchable, isFalse);

        // Act
        final completedState = runningState.copyWith(
          status: TimerStatus.completed,
        );

        // Assert
        expect(completedState.isModeSwitchable, isTrue);
      });
    });
  });

  group('TimerState Mode Tests', () {
    test('デフォルトモードはcountdownであること', () {
      // Arrange & Act
      final state = TimerState();

      // Assert
      expect(state.mode, equals(TimerMode.countdown));
    });

    test('countdownモードからcountupモードに切り替えられること（initial状態）', () {
      // Arrange
      final state = TimerState(
        status: TimerStatus.initial,
        mode: TimerMode.countdown,
      );

      // Act
      final newState = state.copyWith(mode: TimerMode.countup);

      // Assert
      expect(newState.mode, equals(TimerMode.countup));
    });

    test('countupモードからcountdownモードに切り替えられること（initial状態）', () {
      // Arrange
      final state = TimerState(
        status: TimerStatus.initial,
        mode: TimerMode.countup,
      );

      // Act
      final newState = state.copyWith(mode: TimerMode.countdown);

      // Assert
      expect(newState.mode, equals(TimerMode.countdown));
    });
  });

  group('TimerViewModel setMode Tests', () {
    test('initial状態でsetModeを呼ぶとtrueを返しモードが変更されること', () {
      // Arrange
      final viewModel = createTestViewModel();
      expect(viewModel.state.mode, equals(TimerMode.countdown));
      expect(viewModel.state.status, equals(TimerStatus.initial));

      // Act
      final result = viewModel.setMode(TimerMode.countup);

      // Assert
      expect(result, isTrue);
      expect(viewModel.state.mode, equals(TimerMode.countup));

      viewModel.onClose();
    });

    test('running状態でsetModeを呼ぶとfalseを返しモードが変更されないこと', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.startTimer();
      expect(viewModel.state.status, equals(TimerStatus.running));
      final originalMode = viewModel.state.mode;

      // Act
      final result = viewModel.setMode(TimerMode.countup);

      // Assert
      expect(result, isFalse);
      expect(viewModel.state.mode, equals(originalMode));

      viewModel.onClose();
    });

    test('paused状態でsetModeを呼ぶとfalseを返しモードが変更されないこと', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.startTimer();
      viewModel.pauseTimer();
      expect(viewModel.state.status, equals(TimerStatus.paused));
      final originalMode = viewModel.state.mode;

      // Act
      final result = viewModel.setMode(TimerMode.countup);

      // Assert
      expect(result, isFalse);
      expect(viewModel.state.mode, equals(originalMode));

      viewModel.onClose();
    });

    test('completed状態でsetModeを呼ぶとtrueを返しモードが変更されること', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.completeTimer();
      expect(viewModel.state.status, equals(TimerStatus.completed));

      // Act
      final result = viewModel.setMode(TimerMode.countup);

      // Assert
      expect(result, isTrue);
      expect(viewModel.state.mode, equals(TimerMode.countup));

      viewModel.onClose();
    });

    test('resetTimer後にsetModeを呼ぶとtrueを返しモードが変更されること', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.startTimer();
      viewModel.pauseTimer();
      viewModel.resetTimer();
      expect(viewModel.state.status, equals(TimerStatus.initial));

      // Act
      final result = viewModel.setMode(TimerMode.countup);

      // Assert
      expect(result, isTrue);
      expect(viewModel.state.mode, equals(TimerMode.countup));

      viewModel.onClose();
    });
  });

  group('TimerViewModel Scenario Tests', () {
    test('タイマー開始後にモード切り替えを試みるとブロックされること', () {
      // Arrange
      final viewModel = createTestViewModel();
      expect(viewModel.state.mode, equals(TimerMode.countdown));

      // Act - タイマーを開始
      viewModel.startTimer();
      expect(viewModel.state.status, equals(TimerStatus.running));

      // Act - モード切り替えを試みる
      viewModel.setMode(TimerMode.countup);

      // Assert - モードは変更されていない
      expect(viewModel.state.mode, equals(TimerMode.countdown));

      viewModel.onClose();
    });

    test('タイマー開始→一時停止後にモード切り替えを試みるとブロックされること', () {
      // Arrange
      final viewModel = createTestViewModel();

      // Act - タイマーを開始して一時停止
      viewModel.startTimer();
      viewModel.pauseTimer();
      expect(viewModel.state.status, equals(TimerStatus.paused));

      // Act - モード切り替えを試みる
      viewModel.setMode(TimerMode.countup);

      // Assert - モードは変更されていない
      expect(viewModel.state.mode, equals(TimerMode.countdown));

      viewModel.onClose();
    });

    test('タイマー開始→リセット後にモード切り替えができること', () {
      // Arrange
      final viewModel = createTestViewModel();

      // Act - タイマーを開始してリセット
      viewModel.startTimer();
      viewModel.resetTimer();
      expect(viewModel.state.status, equals(TimerStatus.initial));

      // Act - モード切り替え
      viewModel.setMode(TimerMode.countup);

      // Assert - モードが変更されている
      expect(viewModel.state.mode, equals(TimerMode.countup));

      viewModel.onClose();
    });

    test('countdownからcountupへの切り替え（initial状態）が成功すること', () {
      // Arrange
      final viewModel = createTestViewModel();
      expect(viewModel.state.mode, equals(TimerMode.countdown));

      // Act
      viewModel.setMode(TimerMode.countup);

      // Assert
      expect(viewModel.state.mode, equals(TimerMode.countup));
      expect(viewModel.state.currentSeconds, equals(0));

      viewModel.onClose();
    });

    test('countupからcountdownへの切り替え（initial状態）が成功すること', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.setMode(TimerMode.countup);
      expect(viewModel.state.mode, equals(TimerMode.countup));

      // Act
      viewModel.setMode(TimerMode.countdown);

      // Assert
      expect(viewModel.state.mode, equals(TimerMode.countdown));
      expect(viewModel.state.currentSeconds, equals(25 * 60));

      viewModel.onClose();
    });
  });
}
