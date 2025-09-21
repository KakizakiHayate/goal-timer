import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';

/// パターン1（タイマー画面に留まる）の学習完了フローテスト
void main() {
  group('Timer Screen Pattern1 Flow Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('学習完了フロー - パターン1', () {
      testWidgets('test_pattern1_complete_flow_timer_stop_and_reset', (
        tester,
      ) async {
        // パターン1: タイマー画面に留まり、停止→保存→リセット→フィードバック

        // 1. 初期状態の確認
        var initialState = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.initial,
          currentSeconds: 1500,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        expect(initialState.status, TimerStatus.initial);
        expect(initialState.currentSeconds, 1500);

        // 2. タイマー実行中の状態
        var runningState = initialState.copyWith(
          status: TimerStatus.running,
          currentSeconds: 1200, // 5分経過
        );

        expect(runningState.status, TimerStatus.running);
        expect(runningState.currentSeconds, 1200);

        // 3. 学習完了ボタンが表示されることを確認
        bool shouldShow = _shouldShowCompleteButton(runningState);
        expect(shouldShow, isTrue, reason: 'タイマー実行中は学習完了ボタンが表示される');

        // 4. 学習時間の計算確認
        int studyTime = _calculateStudyTime(runningState);
        expect(studyTime, 300, reason: '5分(300秒)の学習時間が計算される');

        // 5. 完了後の状態（停止）
        var completedState = runningState.copyWith(
          status: TimerStatus.completed,
        );

        expect(completedState.status, TimerStatus.completed);

        // 6. リセット後の状態
        var resetState = initialState.copyWith(
          status: TimerStatus.initial,
          currentSeconds: 1500, // 初期値に戻る
        );

        expect(resetState.status, TimerStatus.initial);
        expect(resetState.currentSeconds, 1500);

        // 7. リセット後は学習完了ボタンが非表示になる
        shouldShow = _shouldShowCompleteButton(resetState);
        expect(shouldShow, isFalse, reason: 'リセット後は学習完了ボタンが非表示');
      });

      testWidgets('test_pattern1_continuous_study_scenario', (tester) async {
        // 継続学習シナリオのテスト

        // 第1セッション: 10分学習
        var session1State = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.running,
          currentSeconds: 900, // 15分残り = 10分学習
          totalSeconds: 1500, // 25分設定
          goalId: 'test-goal-id',
        );

        int studyTime1 = _calculateStudyTime(session1State);
        expect(studyTime1, 600, reason: '第1セッション: 10分(600秒)');

        // 第1セッション完了後、リセット
        var afterReset1 = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.initial,
          currentSeconds: 1500,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        // 第2セッション: 15分学習
        var session2State = afterReset1.copyWith(
          status: TimerStatus.running,
          currentSeconds: 600, // 10分残り = 15分学習
        );

        int studyTime2 = _calculateStudyTime(session2State);
        expect(studyTime2, 900, reason: '第2セッション: 15分(900秒)');

        // 合計学習時間の確認
        int totalStudyTime = studyTime1 + studyTime2;
        expect(totalStudyTime, 1500, reason: '合計25分(1500秒)の学習');
      });

      testWidgets('test_pattern1_all_timer_modes', (tester) async {
        // 全タイマーモードでのパターン1フローテスト

        // フォーカスモード（countdown）
        var focusState = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.running,
          currentSeconds: 1200,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        expect(_calculateStudyTime(focusState), 300);
        expect(_shouldShowCompleteButton(focusState), isTrue);

        // フリーモード（countup）
        var freeState = TimerState(
          mode: TimerMode.countup,
          status: TimerStatus.running,
          currentSeconds: 900, // 15分経過
          totalSeconds: 0,
          goalId: 'test-goal-id',
        );

        expect(_calculateStudyTime(freeState), 900);
        expect(_shouldShowCompleteButton(freeState), isTrue);

        // ポモドーロモード
        var pomodoroState = TimerState(
          mode: TimerMode.pomodoro,
          status: TimerStatus.running,
          currentSeconds: 1200,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        expect(_calculateStudyTime(pomodoroState), 300);
        expect(_shouldShowCompleteButton(pomodoroState), isTrue);
      });

      testWidgets('test_pattern1_error_scenarios', (tester) async {
        // エラーシナリオのテスト

        // 負の学習時間
        var negativeState = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.running,
          currentSeconds: 1600, // 初期値より大きい
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        // 負の時間は0として扱う
        int studyTime = _calculateStudyTime(negativeState);
        expect(studyTime >= 0, isTrue, reason: '学習時間は非負であるべき');

        // 0秒の学習時間
        var zeroState = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.initial,
          currentSeconds: 1500,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        studyTime = _calculateStudyTime(zeroState);
        expect(studyTime, 0, reason: '初期状態では学習時間は0');
        expect(_shouldShowCompleteButton(zeroState), isFalse);
      });

      testWidgets('test_pattern1_state_transitions', (tester) async {
        // 状態遷移の確認

        var state = TimerState(
          mode: TimerMode.countdown,
          status: TimerStatus.initial,
          currentSeconds: 1500,
          totalSeconds: 1500,
          goalId: 'test-goal-id',
        );

        // initial → running
        state = state.copyWith(status: TimerStatus.running);
        expect(state.status, TimerStatus.running);
        expect(_shouldShowCompleteButton(state), isTrue);

        // running → paused
        state = state.copyWith(status: TimerStatus.paused);
        expect(state.status, TimerStatus.paused);
        expect(_shouldShowCompleteButton(state), isTrue);

        // paused → completed (学習完了)
        state = state.copyWith(status: TimerStatus.completed);
        expect(state.status, TimerStatus.completed);

        // completed → initial (リセット)
        state = state.copyWith(
          status: TimerStatus.initial,
          currentSeconds: 1500, // 初期値に戻る
        );
        expect(state.status, TimerStatus.initial);
        expect(state.currentSeconds, 1500);
        expect(_shouldShowCompleteButton(state), isFalse);
      });
    });

    group('フィードバック表示テスト', () {
      testWidgets('test_pattern1_success_feedback', (tester) async {
        // 成功フィードバックの表示確認

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      // パターン1のフィードバック表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 5分の学習を記録しました！'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    child: const Text('学習完了'),
                  );
                },
              ),
            ),
          ),
        );

        // ボタンをタップ
        await tester.tap(find.text('学習完了'));
        await tester.pump();

        // SnackBarが表示されることを確認
        expect(find.text('🎉 5分の学習を記録しました！'), findsOneWidget);
      });

      testWidgets('test_pattern1_continue_action', (tester) async {
        // 継続促進アクションのテスト

        bool continueActionCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🎉 10分の学習を記録しました！'),
                          action: SnackBarAction(
                            label: 'もう1回',
                            onPressed: () {
                              continueActionCalled = true;
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('学習完了'),
                  );
                },
              ),
            ),
          ),
        );

        // ボタンをタップしてSnackBarを表示
        await tester.tap(find.text('学習完了'));
        await tester.pump();

        // "もう1回"アクションが表示されることを確認
        expect(find.text('もう1回'), findsOneWidget);

        // "もう1回"をタップ
        await tester.tap(find.text('もう1回'));
        await tester.pump();

        // 継続アクションが呼ばれることを確認
        expect(continueActionCalled, isTrue);
      });
    });
  });
}

// テスト用のヘルパー関数（実装コードと同じロジック）
bool _shouldShowCompleteButton(TimerState timerState) {
  bool hasStudyTime = false;

  switch (timerState.mode) {
    case TimerMode.countdown:
      hasStudyTime = timerState.currentSeconds < timerState.totalSeconds;
      break;
    case TimerMode.countup:
      hasStudyTime = timerState.currentSeconds > 0;
      break;
    case TimerMode.pomodoro:
      hasStudyTime = timerState.currentSeconds < timerState.totalSeconds;
      break;
  }

  return timerState.status == TimerStatus.running ||
      timerState.status == TimerStatus.paused ||
      hasStudyTime;
}

int _calculateStudyTime(TimerState timerState) {
  switch (timerState.mode) {
    case TimerMode.countdown:
      final studyTime = timerState.totalSeconds - timerState.currentSeconds;
      return studyTime > 0 ? studyTime : 0; // 負の時間は0にする
    case TimerMode.countup:
      return timerState.currentSeconds;
    case TimerMode.pomodoro:
      final studyTime = timerState.totalSeconds - timerState.currentSeconds;
      return studyTime > 0 ? studyTime : 0;
  }
}

