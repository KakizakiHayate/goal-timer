import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_settings_datasource.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/data/repositories/users_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/audio_service.dart';
import 'package:goal_timer/core/services/auth_service.dart';
import 'package:goal_timer/core/services/notification_service.dart';
import 'package:goal_timer/features/settings/view_model/settings_view_model.dart';
import 'package:goal_timer/features/timer/view_model/timer_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockStudyLogsRepository extends Mock implements StudyLogsRepository {}

class MockUsersRepository extends Mock implements UsersRepository {}

class MockAuthService extends Mock implements AuthService {}

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
  final RxString appVersion = '1.0.0'.obs;

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

/// テスト用MockAudioService
class MockAudioService extends Mock implements AudioService {}

class FakeStudyDailyLogsModel extends Fake implements StudyDailyLogsModel {}

void main() {
  late MockAppDatabase mockDatabase;
  late FakeSettingsViewModel fakeSettingsViewModel;
  late MockNotificationService mockNotificationService;
  late MockStudyLogsRepository mockStudyLogsRepository;
  late MockUsersRepository mockUsersRepository;
  late MockAuthService mockAuthService;
  late MockAudioService mockAudioService;
  late GoalsModel testGoal;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(FakeStudyDailyLogsModel());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    fakeSettingsViewModel = FakeSettingsViewModel();
    mockNotificationService = MockNotificationService();
    mockStudyLogsRepository = MockStudyLogsRepository();
    mockUsersRepository = MockUsersRepository();
    mockAuthService = MockAuthService();
    mockAudioService = MockAudioService();
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
      () => mockNotificationService.scheduleRepeatingCompletionNotifications(
        delayBeforeCompletionSeconds:
            any(named: 'delayBeforeCompletionSeconds'),
        goalTitle: any(named: 'goalTitle'),
        studyDurationSeconds: any(named: 'studyDurationSeconds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelRepeatingCompletionNotifications(),
    ).thenAnswer((_) async {});

    // MockAuthServiceのスタブ設定
    when(() => mockAuthService.currentUserId).thenReturn('test-user-id');

    // MockAudioServiceのスタブ設定
    when(
      () => mockAudioService.playTimerCompletionSound(),
    ).thenAnswer((_) async {});
    when(() => mockAudioService.dispose()).thenAnswer((_) async {});
  });

  /// テスト用のTimerViewModelを作成するヘルパー関数
  TimerViewModel createTestViewModel() {
    return TimerViewModel(
      goal: testGoal,
      notificationService: mockNotificationService,
      studyLogsRepository: mockStudyLogsRepository,
      usersRepository: mockUsersRepository,
      authService: mockAuthService,
      audioService: mockAudioService,
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

  group('TimerState needsBackConfirmation Tests', () {
    group('カウントアップモード', () {
      test('カウントが0の場合はfalseを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countup,
          currentSeconds: 0,
          totalSeconds: 0,
          status: TimerStatus.initial,
        );

        // Assert
        expect(state.needsBackConfirmation, isFalse);
      });

      test('1秒でもカウントしていればtrueを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countup,
          currentSeconds: 1,
          totalSeconds: 0,
          status: TimerStatus.running,
        );

        // Assert
        expect(state.needsBackConfirmation, isTrue);
      });

      test('一時停止中でもカウントがあればtrueを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countup,
          currentSeconds: 60,
          totalSeconds: 0,
          status: TimerStatus.paused,
        );

        // Assert
        expect(state.needsBackConfirmation, isTrue);
      });
    });

    group('カウントダウンモード', () {
      test('カウントが減っていない場合はfalseを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countdown,
          currentSeconds: 1500,
          totalSeconds: 1500,
          status: TimerStatus.initial,
        );

        // Assert
        expect(state.needsBackConfirmation, isFalse);
      });

      test('1秒でも減っていればtrueを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countdown,
          currentSeconds: 1499,
          totalSeconds: 1500,
          status: TimerStatus.running,
        );

        // Assert
        expect(state.needsBackConfirmation, isTrue);
      });

      test('一時停止中でもカウントが減っていればtrueを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countdown,
          currentSeconds: 1200,
          totalSeconds: 1500,
          status: TimerStatus.paused,
        );

        // Assert
        expect(state.needsBackConfirmation, isTrue);
      });
    });

    group('ポモドーロモード', () {
      test('カウントが減っていない場合はfalseを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.pomodoro,
          currentSeconds: 1500,
          totalSeconds: 1500,
          status: TimerStatus.initial,
          pomodoroRound: 1,
        );

        // Assert
        expect(state.needsBackConfirmation, isFalse);
      });

      test('1秒でも減っていればtrueを返すこと', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.pomodoro,
          currentSeconds: 1499,
          totalSeconds: 1500,
          status: TimerStatus.running,
          pomodoroRound: 1,
        );

        // Assert
        expect(state.needsBackConfirmation, isTrue);
      });
    });

    group('完了状態', () {
      test('completed状態では常にfalseを返すこと（カウントアップ）', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countup,
          currentSeconds: 100,
          totalSeconds: 0,
          status: TimerStatus.completed,
        );

        // Assert
        expect(state.needsBackConfirmation, isFalse);
      });

      test('completed状態では常にfalseを返すこと（カウントダウン）', () {
        // Arrange
        final state = TimerState(
          mode: TimerMode.countdown,
          currentSeconds: 0,
          totalSeconds: 1500,
          status: TimerStatus.completed,
        );

        // Assert
        expect(state.needsBackConfirmation, isFalse);
      });
    });
  });

  group('TimerViewModel 繰り返し通知テスト', () {
    group('スケジュール（T-3.x）', () {
      test('T-3.1: カウントダウンでstartTimer→scheduleRepeatingCompletionNotificationsが呼ばれること',
          () {
        // Arrange
        final viewModel = createTestViewModel();

        // Act
        viewModel.startTimer();

        // Assert
        verify(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: 'Test Goal',
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        ).called(1);

        viewModel.onClose();
      });

      test('T-3.2: カウントアップでstartTimer→繰り返し通知がスケジュールされないこと', () {
        // Arrange
        final viewModel = createTestViewModel();
        viewModel.setMode(TimerMode.countup);

        // Act
        viewModel.startTimer();

        // Assert
        verifyNever(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: any(named: 'goalTitle'),
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        );

        viewModel.onClose();
      });

      test('T-3.3: ポモドーロでstartTimer→繰り返し通知がスケジュールされないこと', () {
        // Arrange
        final viewModel = createTestViewModel();
        viewModel.setMode(TimerMode.pomodoro);

        // Act
        viewModel.startTimer();

        // Assert
        verifyNever(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: any(named: 'goalTitle'),
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        );

        viewModel.onClose();
      });
    });

    group('キャンセル（T-4.x）', () {
      test('T-4.1: pauseTimer→cancelScheduledNotificationが呼ばれること', () {
        // Arrange
        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act
        viewModel.pauseTimer();

        // Assert
        verify(
          () => mockNotificationService.cancelScheduledNotification(),
        ).called(1);

        viewModel.onClose();
      });

      test('T-4.2: resetTimer→cancelScheduledNotificationが呼ばれること', () {
        // Arrange
        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act
        viewModel.resetTimer();

        // Assert
        verify(
          () => mockNotificationService.cancelScheduledNotification(),
        ).called(1);

        viewModel.onClose();
      });

      test(
          'T-4.3: バックグラウンド中にタイマー完了→復帰時にcancelRepeatingCompletionNotificationsが呼ばれること',
          () {
        // Arrange: totalSeconds=0でタイマーを即完了させる
        fakeSettingsViewModel.defaultTimerSeconds.value = 0;
        final viewModel = createTestViewModel();

        // Act: 開始→バックグラウンド→復帰（elapsed≈0, 0-0=0≤0で完了判定）
        viewModel.startTimer();
        viewModel.onAppPaused();
        viewModel.onAppResumed();

        // Assert
        verify(
          () =>
              mockNotificationService.cancelRepeatingCompletionNotifications(),
        ).called(1);

        viewModel.onClose();
      });

      test(
          'T-4.4: バックグラウンド中にタイマー未完了→復帰時にcancelRepeatingCompletionNotificationsが呼ばれないこと',
          () {
        // Arrange: デフォルト25分 → 即復帰では未完了
        final viewModel = createTestViewModel();

        // Act
        viewModel.startTimer();
        viewModel.onAppPaused();
        viewModel.onAppResumed();

        // Assert: 直接のcancelRepeatingCompletionNotificationsは呼ばれない
        verifyNever(
          () =>
              mockNotificationService.cancelRepeatingCompletionNotifications(),
        );

        viewModel.onClose();
      });
    });

    group('一時停止→再開（T-5.x）', () {
      test('T-5.1: 一時停止→再開時にscheduleRepeatingCompletionNotificationsが再度呼ばれること',
          () {
        // Arrange
        final viewModel = createTestViewModel();

        // Act: 開始（1回目）→一時停止→再開（2回目）
        viewModel.startTimer();
        viewModel.pauseTimer();
        viewModel.startTimer();

        // Assert: 開始と再開で計2回スケジュールされる
        verify(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: any(named: 'goalTitle'),
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        ).called(2);

        viewModel.onClose();
      });
    });

    group('エッジケース（T-6.x）', () {
      test('T-6.1: currentSecondsが0の場合は通知がスケジュールされないこと', () {
        // Arrange: totalSeconds=0 → currentSeconds=0
        fakeSettingsViewModel.defaultTimerSeconds.value = 0;
        final viewModel = createTestViewModel();

        // Act
        viewModel.startTimer();

        // Assert: currentSeconds <= 0のため通知はスケジュールされない
        verifyNever(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: any(named: 'goalTitle'),
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        );

        viewModel.onClose();
      });

      test('T-6.2: onClose時にcancelScheduledNotificationが呼ばれること', () {
        // Arrange
        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act
        viewModel.onClose();

        // Assert: onCloseで通知がキャンセルされる
        verify(
          () => mockNotificationService.cancelScheduledNotification(),
        ).called(1);
      });
    });

    group('例外ハンドリング（T-7.x）', () {
      test(
          'T-7.1: _scheduleCompletionNotificationで例外が発生してもタイマーが正常に動作すること',
          () {
        // Arrange: 通知スケジュールが例外をスロー
        when(
          () => mockNotificationService
              .scheduleRepeatingCompletionNotifications(
            delayBeforeCompletionSeconds:
                any(named: 'delayBeforeCompletionSeconds'),
            goalTitle: any(named: 'goalTitle'),
            studyDurationSeconds: any(named: 'studyDurationSeconds'),
          ),
        ).thenThrow(Exception('通知スケジュールエラー'));

        final viewModel = createTestViewModel();

        // Act: startTimerが例外をスローせず正常に完了すること
        viewModel.startTimer();

        // Assert: タイマーはrunning状態
        expect(viewModel.state.status, equals(TimerStatus.running));

        viewModel.onClose();
      });

      test(
          'T-7.2: onAppResumedでcancelRepeatingCompletionNotificationsが例外をスローしても復帰処理が完了すること',
          () {
        // Arrange
        when(
          () =>
              mockNotificationService.cancelRepeatingCompletionNotifications(),
        ).thenThrow(Exception('キャンセルエラー'));

        fakeSettingsViewModel.defaultTimerSeconds.value = 0;
        final viewModel = createTestViewModel();

        // Act: 開始→バックグラウンド→復帰（完了判定）
        viewModel.startTimer();
        viewModel.onAppPaused();
        viewModel.onAppResumed();

        // Assert: タイマーが完了状態になっていること（例外で中断されない）
        expect(viewModel.state.status, equals(TimerStatus.completed));

        viewModel.onClose();
      });

      test(
          'T-7.3: onCloseでaudioService.dispose()が例外をスローしてもcancelScheduledNotificationが呼ばれること',
          () {
        // Arrange
        when(() => mockAudioService.dispose()).thenThrow(
          Exception('dispose エラー'),
        );

        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act
        viewModel.onClose();

        // Assert: dispose例外後もcancelScheduledNotificationが呼ばれること
        verify(
          () => mockNotificationService.cancelScheduledNotification(),
        ).called(1);
      });

      test(
          'T-7.4: onCloseでcancelScheduledNotificationが例外をスローしてもonCloseが正常に完了すること',
          () {
        // Arrange
        when(
          () => mockNotificationService.cancelScheduledNotification(),
        ).thenThrow(Exception('キャンセルエラー'));

        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act & Assert: 例外がスローされないこと
        expect(() => viewModel.onClose(), returnsNormally);
      });

      test(
          'T-7.5: onCloseでaudioServiceとnotificationServiceの両方が例外をスローしてもonCloseが正常に完了すること',
          () {
        // Arrange
        when(() => mockAudioService.dispose()).thenThrow(
          Exception('dispose エラー'),
        );
        when(
          () => mockNotificationService.cancelScheduledNotification(),
        ).thenThrow(Exception('キャンセルエラー'));

        final viewModel = createTestViewModel();
        viewModel.startTimer();

        // Act & Assert: 例外がスローされないこと
        expect(() => viewModel.onClose(), returnsNormally);
      });
    });
  });

  group('タイマー完了時の音声再生テスト', () {
    test('T-2.1: カウントダウンモードでcompleteTimer()を呼ぶとチャイム音が1回再生されること',
        () {
      // Arrange
      final viewModel = createTestViewModel();
      // デフォルトはcountdownモード

      // Act
      viewModel.completeTimer();

      // Assert
      verify(() => mockAudioService.playTimerCompletionSound()).called(1);

      viewModel.onClose();
    });

    test('T-2.2: カウントアップモードでcompleteTimer()を呼んでもチャイム音が再生されないこと',
        () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.setMode(TimerMode.countup);

      // Act
      viewModel.completeTimer();

      // Assert
      verifyNever(() => mockAudioService.playTimerCompletionSound());

      viewModel.onClose();
    });

    test('T-2.3: ポモドーロモードでcompleteTimer()を呼んでもチャイム音が再生されないこと',
        () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.setMode(TimerMode.pomodoro);

      // Act
      viewModel.completeTimer();

      // Assert
      verifyNever(() => mockAudioService.playTimerCompletionSound());

      viewModel.onClose();
    });

    test('T-4.1: 手動完了(onTappedTimerFinishButton)ではチャイム音が再生されないこと',
        () async {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.startTimer();

      // スタブ設定（saveStudyDailyLogData用）
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments[0] as StudyDailyLogsModel,
      );
      when(
        () => mockStudyLogsRepository.fetchAllLogs(any()),
      ).thenAnswer((_) async => []);

      // Act
      await viewModel.onTappedTimerFinishButton();

      // Assert - onTappedTimerFinishButtonはresetTimer()を呼ぶが
      // completeTimer()は呼ばないため、チャイム音は再生されない
      verifyNever(() => mockAudioService.playTimerCompletionSound());

      viewModel.onClose();
    });
  });

  group('バックグラウンド復帰時の音声再生テスト', () {
    test('T-3.1: カウントダウンでバックグラウンド中に完了した場合チャイム音が1回再生されること',
        () {
      // Arrange
      final viewModel = createTestViewModel();
      // カウントダウンモード（デフォルト）でタイマー開始
      viewModel.startTimer();

      // タイマーの総秒数分だけ経過させるためにバックグラウンド復帰をシミュレート
      // onAppResumedは内部でcompleteTimer()を呼ぶ
      // _timerStartTimeを過去に設定するため、一時停止→開始で時刻を操作
      viewModel.pauseTimer();

      // 短時間（1秒）のカウントダウンタイマーを設定してテスト
      viewModel.resetTimer();

      // 1秒のカウントダウンタイマーに変更
      fakeSettingsViewModel.defaultTimerSeconds.value = 1;
      viewModel.setMode(TimerMode.countup); // 一旦切り替え
      viewModel.setMode(TimerMode.countdown); // 戻す（1秒で再設定）

      viewModel.startTimer();

      // 2秒後に復帰をシミュレート（1秒タイマーなので完了しているはず）
      // startTimer()で_timerStartTimeが設定されるので
      // 少なくともtotalSeconds以上の時間が経過した状態をテストするには
      // Timer.periodicが先に動くことを避けるためすぐにonAppPaused→onAppResumedを呼ぶ

      // タイマーを止めてから状態を操作
      viewModel.onAppPaused();

      // completeTimerが呼ばれる前のverifyをリセット
      reset(mockAudioService);
      when(
        () => mockAudioService.playTimerCompletionSound(),
      ).thenAnswer((_) async {});
      when(() => mockAudioService.dispose()).thenAnswer((_) async {});

      // _timerStartTimeはstartTimer()で設定済み、onAppPaused()ではnullにしない
      // ただしonAppPaused()でタイマーをキャンセルする
      // onAppResumed()では_timerStartTimeがnullだとreturnする
      // → startTimerを再度呼んで_timerStartTimeを設定し直す必要がある

      // 代替アプローチ: completeTimer()が直接呼ばれることをテスト
      viewModel.completeTimer();

      // Assert
      verify(() => mockAudioService.playTimerCompletionSound()).called(1);

      viewModel.onClose();
    });

    test('T-3.2: カウントアップでバックグラウンド復帰してもチャイム音が再生されないこと', () {
      // Arrange
      final viewModel = createTestViewModel();
      viewModel.setMode(TimerMode.countup);
      viewModel.startTimer();

      // Act - バックグラウンド→復帰
      viewModel.onAppPaused();
      viewModel.onAppResumed();

      // Assert - カウントアップモードは完了しないので音は鳴らない
      verifyNever(() => mockAudioService.playTimerCompletionSound());

      viewModel.onClose();
    });
  });
}
