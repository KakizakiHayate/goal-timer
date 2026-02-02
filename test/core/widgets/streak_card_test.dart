import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/widgets/streak_card.dart';
import 'package:goal_timer/core/widgets/mini_heatmap.dart';
import 'package:goal_timer/core/utils/color_consts.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime daysAgo(int days) {
    return today().subtract(Duration(days: days));
  }

  group('StreakCard', () {
    testWidgets('ストリーク0日 → 「今日から始めよう！」表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StreakCard(streakDays: 0, studyDates: [])),
        ),
      );

      // フォールバック値（英語）が表示される
      expect(find.text("Let's start today!"), findsOneWidget);
    });

    testWidgets('ストリーク1日 → 「1日連続学習中！」表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(streakDays: 1, studyDates: [today()]),
          ),
        ),
      );

      // フォールバック値（英語）が表示される
      expect(find.text('1 day streak!'), findsOneWidget);
    });

    testWidgets('ストリーク5日 → 「5日連続学習中！」表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakDays: 5,
              studyDates: [
                today(),
                daysAgo(1),
                daysAgo(2),
                daysAgo(3),
                daysAgo(4),
              ],
            ),
          ),
        ),
      );

      // フォールバック値（英語）が表示される
      expect(find.text('5 day streak!'), findsOneWidget);
    });

    testWidgets('ストリーク7日 → 「🎉 1週間達成！」表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakDays: 7,
              studyDates: List.generate(7, (i) => daysAgo(i)),
            ),
          ),
        ),
      );

      // フォールバック値（英語）が表示される
      expect(
        find.textContaining('1 week achieved!'),
        findsOneWidget,
      );
    });

    testWidgets('ストリーク30日 → 「🏆 1ヶ月達成！」表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakDays: 30,
              studyDates: List.generate(7, (i) => daysAgo(i)),
            ),
          ),
        ),
      );

      // フォールバック値（英語）が表示される
      expect(
        find.textContaining('1 month achieved!'),
        findsOneWidget,
      );
    });

    testWidgets('カードにミニヒートマップが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakDays: 3,
              studyDates: [today(), daysAgo(1), daysAgo(2)],
            ),
          ),
        ),
      );

      expect(find.byType(MiniHeatmap), findsOneWidget);
    });

    testWidgets('onTapコールバックが呼ばれる', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakDays: 1,
              studyDates: [today()],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StreakCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('MiniHeatmap', () {
    testWidgets('7つのドットが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MiniHeatmap(studyDates: []))),
      );

      final containers = find.byType(Container);
      expect(containers.evaluate().length, greaterThanOrEqualTo(7));
    });

    testWidgets('今日学習済み → 今日のドットが濃い緑', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MiniHeatmap(studyDates: [today()]))),
      );

      await tester.pumpAndSettle();

      final todayDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == ColorConsts.success;
        }
        return false;
      });

      expect(todayDotFinder, findsOneWidget);
    });

    testWidgets('今日未学習 → 今日のドットが青枠線のみ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MiniHeatmap(studyDates: []))),
      );

      await tester.pumpAndSettle();

      final todayDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.border != null && decoration.color == null;
        }
        return false;
      });

      expect(todayDotFinder, findsOneWidget);
    });

    testWidgets('過去の日・学習あり → 緑のドット', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MiniHeatmap(studyDates: [daysAgo(1)])),
        ),
      );

      await tester.pumpAndSettle();

      final studiedDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == ColorConsts.success;
        }
        return false;
      });

      expect(studiedDotFinder, findsOneWidget);
    });

    testWidgets('過去の日・学習なし → グレーのドット', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MiniHeatmap(studyDates: []))),
      );

      await tester.pumpAndSettle();

      final notStudiedDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == ColorConsts.disabled;
        }
        return false;
      });

      expect(notStudiedDotFinder.evaluate().length, greaterThanOrEqualTo(6));
    });
  });
}
