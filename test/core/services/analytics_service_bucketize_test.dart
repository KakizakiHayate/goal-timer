import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService.bucketize', () {
    test('returns "0" for non-positive values', () {
      expect(AnalyticsService.bucketize(0), '0');
      expect(AnalyticsService.bucketize(-1), '0');
    });

    test('returns "1-3" for boundaries 1 and 3', () {
      expect(AnalyticsService.bucketize(1), '1-3');
      expect(AnalyticsService.bucketize(3), '1-3');
    });

    test('returns "4-10" for boundaries 4 and 10', () {
      expect(AnalyticsService.bucketize(4), '4-10');
      expect(AnalyticsService.bucketize(10), '4-10');
    });

    test('returns "11-30" for boundaries 11 and 30', () {
      expect(AnalyticsService.bucketize(11), '11-30');
      expect(AnalyticsService.bucketize(30), '11-30');
    });

    test('returns "31+" for 31 and above', () {
      expect(AnalyticsService.bucketize(31), '31+');
      expect(AnalyticsService.bucketize(100), '31+');
    });
  });
}
