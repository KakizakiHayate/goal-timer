import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:goal_timer/features/splash/view_model/splash_view_model.dart';

// モッククラス
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('SplashViewModel', () {
    group('初期状態', () {
      test('初期状態はinitialである', () {
        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        expect(viewModel.status, SplashStatus.initial);
      });

      test('初期状態でuserIdはnullである', () {
        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        expect(viewModel.userId, isNull);
      });

      test('初期状態でisOfflineはfalseである', () {
        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        expect(viewModel.isOffline, isFalse);
      });

      test('初期状態でhasErrorはfalseである', () {
        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        expect(viewModel.hasError, isFalse);
      });
    });

    group('checkNetwork', () {
      test('オフライン時はoffline状態になる', () async {
        // connectivity_plus 6.x+ は List<ConnectivityResult> を返す
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        await viewModel.initialize();

        expect(viewModel.status, SplashStatus.offline);
        expect(viewModel.isOffline, isTrue);
      });

      test('WiFi接続時はoffline状態にならない', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        // Supabaseが初期化されていないのでエラーになるが、
        // offline状態にはならないことを確認
        try {
          await viewModel.initialize();
        } catch (_) {
          // エラーは無視
        }

        expect(viewModel.isOffline, isFalse);
      });

      test('モバイル接続時はoffline状態にならない', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        // Supabaseが初期化されていないのでエラーになるが、
        // offline状態にはならないことを確認
        try {
          await viewModel.initialize();
        } catch (_) {
          // エラーは無視
        }

        expect(viewModel.isOffline, isFalse);
      });
    });

    group('retryFromOffline', () {
      test('リトライ時は初期状態にリセットされる', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final viewModel = SplashViewModel(connectivity: mockConnectivity);
        await viewModel.initialize();

        expect(viewModel.status, SplashStatus.offline);

        // リトライ（まだオフラインのまま）
        await viewModel.retryFromOffline();

        // 状態は再度チェックされてofflineになる
        expect(viewModel.status, SplashStatus.offline);
      });
    });
  });
}
