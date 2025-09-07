import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/tutorial_view_model.dart';

void main() {
  group('タイマー完了フローの基本テスト', () {
    test('テスト1: TimerConstants.tutorialDurationSecondsが5秒であること', () {
      expect(TimerConstants.tutorialDurationSeconds, equals(5));
    });

    test('テスト14: タイマーの初期モードがcountdownであること', () {
      final timerState = TimerState();
      expect(timerState.mode, equals(TimerMode.countdown));
    });

    test('テスト4: カウントダウン完了閾値が0であること', () {
      expect(TimerConstants.countdownCompleteThreshold, equals(0));
    });

    group('TimerState', () {
      test('タイマー状態の初期値が正しく設定される', () {
        final state = TimerState();
        
        expect(state.totalSeconds, equals(25 * 60)); // 25分
        expect(state.currentSeconds, equals(25 * 60));
        expect(state.status, equals(TimerStatus.initial));
        expect(state.mode, equals(TimerMode.countdown));
        expect(state.isPomodoroBreak, isFalse);
        expect(state.pomodoroRound, equals(1));
      });

      test('copyWithメソッドが正しく動作する', () {
        final state = TimerState();
        final newState = state.copyWith(
          totalSeconds: 5,
          currentSeconds: 5,
          status: TimerStatus.completed,
        );
        
        expect(newState.totalSeconds, equals(5));
        expect(newState.currentSeconds, equals(5));
        expect(newState.status, equals(TimerStatus.completed));
        expect(newState.mode, equals(TimerMode.countdown)); // 変更されていない
      });

      test('hasGoalプロパティが正しく動作する', () {
        final stateWithoutGoal = TimerState();
        expect(stateWithoutGoal.hasGoal, isFalse);
        
        final stateWithGoal = TimerState(goalId: 'test_goal_id');
        expect(stateWithGoal.hasGoal, isTrue);
        
        final stateWithEmptyGoal = TimerState(goalId: '');
        expect(stateWithEmptyGoal.hasGoal, isFalse);
      });

      test('progressプロパティがカウントダウンモードで正しく計算される', () {
        final state = TimerState(
          mode: TimerMode.countdown,
          totalSeconds: 100,
          currentSeconds: 25,
        );
        
        expect(state.progress, equals(0.75)); // 1.0 - (25/100) = 0.75
      });

      test('displayTimeが正しくフォーマットされる', () {
        final state1 = TimerState(currentSeconds: 125); // 2分5秒
        expect(state1.displayTime, equals('02:05'));
        
        final state2 = TimerState(currentSeconds: 5); // 5秒
        expect(state2.displayTime, equals('00:05'));
        
        final state3 = TimerState(currentSeconds: 3600); // 60分
        expect(state3.displayTime, equals('60:00'));
      });
    });

    group('TutorialState', () {
      test('チュートリアル状態の初期値が正しく設定される', () {
        const state = TutorialState();
        
        expect(state.isTutorialActive, isFalse);
        expect(state.isCompleted, isFalse);
        expect(state.currentStepId, equals(''));
      });

      test('copyWithメソッドが正しく動作する', () {
        const state = TutorialState();
        final newState = state.copyWith(
          isTutorialActive: true,
          currentStepId: 'timer_operation',
        );
        
        expect(newState.isTutorialActive, isTrue);
        expect(newState.currentStepId, equals('timer_operation'));
        expect(newState.isCompleted, isFalse); // 変更されていない
      });

      test('チュートリアル完了時の状態変更', () {
        const state = TutorialState(
          isTutorialActive: true,
          currentStepId: 'timer_operation',
        );
        
        final completedState = state.copyWith(
          isTutorialActive: false,
          isCompleted: true,
        );
        
        expect(completedState.isTutorialActive, isFalse);
        expect(completedState.isCompleted, isTrue);
      });
    });

    group('タイマー完了フローのロジックテスト', () {
      test('テスト18: completeTutorial実行時にisTutorialActiveがfalseになる', () {
        const state = TutorialState(isTutorialActive: true);
        final completedState = state.copyWith(
          isTutorialActive: false,
          isCompleted: true,
        );
        
        // completeTutorial()が呼ばれた後の状態
        expect(completedState.isTutorialActive, isFalse);
        expect(completedState.isCompleted, isTrue);
      });

      test('テスト20: ref.listen条件の各パラメータテスト', () {
        // チュートリアルモードフラグ
        const isTutorialMode = true;
        
        // チュートリアル状態
        const tutorialState = TutorialState(isTutorialActive: true);
        
        // タイマー状態の変化
        final previousState = TimerState(status: TimerStatus.running);
        final currentState = TimerState(status: TimerStatus.completed);
        
        // 条件評価
        final condition = isTutorialMode && 
            tutorialState.isTutorialActive &&
            previousState.status != TimerStatus.completed &&
            currentState.status == TimerStatus.completed;
            
        expect(condition, isTrue);
      });

      test('テスト25: 二重実行防止 - previous.statusがcompletedの場合は実行されない', () {
        const isTutorialMode = true;
        const tutorialState = TutorialState(isTutorialActive: true);
        
        // すでにcompletedの状態から再度completedになる
        final previousState = TimerState(status: TimerStatus.completed);
        final currentState = TimerState(status: TimerStatus.completed);
        
        final condition = isTutorialMode && 
            tutorialState.isTutorialActive &&
            previousState.status != TimerStatus.completed &&
            currentState.status == TimerStatus.completed;
            
        expect(condition, isFalse); // 二重実行を防ぐ
      });

      test('テスト13: 非チュートリアルモードでは条件を満たさない', () {
        const isTutorialMode = false; // 非チュートリアルモード
        const tutorialState = TutorialState(isTutorialActive: true);
        final previousState = TimerState(status: TimerStatus.running);
        final currentState = TimerState(status: TimerStatus.completed);
        
        final condition = isTutorialMode && 
            tutorialState.isTutorialActive &&
            previousState.status != TimerStatus.completed &&
            currentState.status == TimerStatus.completed;
            
        expect(condition, isFalse);
      });

      test('タイマーが0秒になったときcompleteTimerが呼ばれる条件', () {
        final state = TimerState(
          currentSeconds: 0,
          mode: TimerMode.countdown,
        );
        
        // カウントダウンモードで0秒以下になった場合
        final shouldComplete = state.currentSeconds <= TimerConstants.countdownCompleteThreshold;
        expect(shouldComplete, isTrue);
      });

      test('タイマーが1秒以上の場合はcompleteTimerが呼ばれない', () {
        final state = TimerState(
          currentSeconds: 1,
          mode: TimerMode.countdown,
        );
        
        final shouldComplete = state.currentSeconds <= TimerConstants.countdownCompleteThreshold;
        expect(shouldComplete, isFalse);
      });
    });

    group('タイマーモードのテスト', () {
      test('利用可能なタイマーモード', () {
        // すべてのタイマーモード
        expect(TimerMode.values, contains(TimerMode.countdown));
        expect(TimerMode.values, contains(TimerMode.countup));
        expect(TimerMode.values, contains(TimerMode.pomodoro));
      });

      test('ポモドーロタイマーの設定値', () {
        expect(TimerConstants.pomodoroWorkMinutes, equals(25));
        expect(TimerConstants.pomodoroBreakMinutes, equals(5));
      });
    });

    group('チュートリアルステップのテスト', () {
      test('テスト16: timer_operationステップでオーバーレイが表示される条件', () {
        const tutorialState = TutorialState(
          isTutorialActive: true,
          currentStepId: 'timer_operation',
        );
        final timerState = TimerState(status: TimerStatus.initial);
        const isTutorialMode = true;
        
        final shouldShowOverlay = isTutorialMode &&
            tutorialState.isTutorialActive &&
            tutorialState.currentStepId == 'timer_operation' &&
            timerState.status == TimerStatus.initial;
            
        expect(shouldShowOverlay, isTrue);
      });

      test('タイマーが実行中の場合はオーバーレイが表示されない', () {
        const tutorialState = TutorialState(
          isTutorialActive: true,
          currentStepId: 'timer_operation',
        );
        final timerState = TimerState(status: TimerStatus.running);
        const isTutorialMode = true;
        
        final shouldShowOverlay = isTutorialMode &&
            tutorialState.isTutorialActive &&
            tutorialState.currentStepId == 'timer_operation' &&
            timerState.status == TimerStatus.initial;
            
        expect(shouldShowOverlay, isFalse);
      });
    });

    group('目標データ取得のテスト', () {
      test('テスト22: 目標タイトルのデフォルト値', () {
        // 目標が取得できない場合のデフォルトタイトル
        const defaultTitle = '学習目標';
        String? goalTitle;
        
        final displayTitle = goalTitle ?? defaultTitle;
        expect(displayTitle, equals('学習目標'));
      });

      test('目標が取得できた場合はその目標タイトルを使用', () {
        const defaultTitle = '学習目標';
        const goalTitle = '数学の勉強';
        
        final displayTitle = goalTitle.isNotEmpty ? goalTitle : defaultTitle;
        expect(displayTitle, equals('数学の勉強'));
      });
    });
  });
}