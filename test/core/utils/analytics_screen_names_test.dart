import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/utils/analytics_screen_names.dart';

void main() {
  group('AnalyticsScreenNames.fromRoute', () {
    test('returns null when input is null', () {
      expect(AnalyticsScreenNames.fromRoute(null), isNull);
    });

    test('returns null when input is empty', () {
      expect(AnalyticsScreenNames.fromRoute(''), isNull);
    });

    test('maps root path to splash', () {
      expect(AnalyticsScreenNames.fromRoute('/'), 'splash');
    });

    test('strips leading slash and converts hyphens to underscores', () {
      expect(AnalyticsScreenNames.fromRoute('/timer-with-goal'),
          'timer_with_goal');
    });

    test('flattens nested onboarding path', () {
      expect(AnalyticsScreenNames.fromRoute('/onboarding/goal-creation'),
          'onboarding_goal_creation');
    });

    test('flattens nested auth path', () {
      expect(AnalyticsScreenNames.fromRoute('/auth/signin'), 'auth_signin');
    });

    test('returns null for /debug subtree', () {
      expect(AnalyticsScreenNames.fromRoute('/debug/sync'), isNull);
      expect(AnalyticsScreenNames.fromRoute('/debug/sqlite-viewer'), isNull);
    });

    test('returns null for the bare /debug path', () {
      expect(AnalyticsScreenNames.fromRoute('/debug'), isNull);
    });

    test('handles a simple path without nesting', () {
      expect(AnalyticsScreenNames.fromRoute('/home'), 'home');
      expect(AnalyticsScreenNames.fromRoute('/settings'), 'settings');
      expect(AnalyticsScreenNames.fromRoute('/statistics'), 'statistics');
    });

    test('keeps camelCase route segments unchanged (only / and - are normalized)',
        () {
      // RouteNames は kebab-case 想定なので大文字は来ない前提だが、
      // 防御的に大文字混入時の挙動も固定しておく。
      expect(AnalyticsScreenNames.fromRoute('/MemoRecord'), 'MemoRecord');
    });
  });
}
