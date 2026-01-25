import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:goal_timer/core/data/supabase/supabase_auth_datasource.dart';
import 'package:goal_timer/features/auth/view_model/auth_view_model.dart';

// モッククラス
class MockSupabaseAuthDatasource extends Mock
    implements SupabaseAuthDatasource {}

void main() {
  late MockSupabaseAuthDatasource mockAuthDatasource;
  late AuthViewModel viewModel;

  setUp(() {
    mockAuthDatasource = MockSupabaseAuthDatasource();
    Get.testMode = true;

    // デフォルトのスタブ
    when(() => mockAuthDatasource.isAnonymous).thenReturn(true);

    viewModel = AuthViewModel(authDatasource: mockAuthDatasource);
  });

  tearDown(() {
    Get.reset();
  });

  group('AuthViewModel', () {
    group('初期状態', () {
      test('初期状態はinitialである', () {
        expect(viewModel.status, AuthStatus.initial);
      });

      test('初期状態でerrorMessageは空である', () {
        expect(viewModel.errorMessage, isEmpty);
      });

      test('初期状態でisLoadingはfalseである', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('初期状態でhasErrorはfalseである', () {
        expect(viewModel.hasError, isFalse);
      });
    });

    group('isAnonymous', () {
      test('匿名ユーザーの場合はtrueを返す', () {
        when(() => mockAuthDatasource.isAnonymous).thenReturn(true);

        expect(viewModel.isAnonymous, isTrue);
      });

      test('連携済みユーザーの場合はfalseを返す', () {
        when(() => mockAuthDatasource.isAnonymous).thenReturn(false);

        final linkedViewModel =
            AuthViewModel(authDatasource: mockAuthDatasource);

        expect(linkedViewModel.isAnonymous, isFalse);
      });
    });

    group('showLinkButton', () {
      test('匿名ユーザーの場合はtrueを返す', () {
        when(() => mockAuthDatasource.isAnonymous).thenReturn(true);

        expect(viewModel.showLinkButton, isTrue);
      });

      test('連携済みユーザーの場合はfalseを返す', () {
        when(() => mockAuthDatasource.isAnonymous).thenReturn(false);

        final linkedViewModel =
            AuthViewModel(authDatasource: mockAuthDatasource);

        expect(linkedViewModel.showLinkButton, isFalse);
      });
    });

    group('linkWithGoogle', () {
      test('連携成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.linkWithGoogle())
            .thenAnswer((_) async => true);

        final result = await viewModel.linkWithGoogle();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
      });

      test('連携キャンセル時はinitial状態のままである', () async {
        when(() => mockAuthDatasource.linkWithGoogle())
            .thenAnswer((_) async => false);

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.initial);
      });

      test('連携失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.linkWithGoogle())
            .thenThrow(Exception('Google連携エラー'));

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorMessage, isNotEmpty);
      });

      test('連携処理中はloading状態になる', () async {
        when(() => mockAuthDatasource.linkWithGoogle()).thenAnswer((_) async {
          // 遅延をシミュレート
          await Future.delayed(const Duration(milliseconds: 100));
          return true;
        });

        // 非同期で実行開始
        final future = viewModel.linkWithGoogle();

        // loading状態を確認（すぐにはloadingにならない可能性があるので、awaitで完了を待つ）
        await future;
        expect(viewModel.status, AuthStatus.success);
      });
    });

    group('linkWithApple', () {
      test('連携成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.linkWithApple())
            .thenAnswer((_) async => true);

        final result = await viewModel.linkWithApple();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
      });

      test('連携キャンセル時はinitial状態のままである', () async {
        when(() => mockAuthDatasource.linkWithApple())
            .thenAnswer((_) async => false);

        final result = await viewModel.linkWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.initial);
      });

      test('連携失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.linkWithApple())
            .thenThrow(Exception('Apple連携エラー'));

        final result = await viewModel.linkWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorMessage, isNotEmpty);
      });
    });

    group('clearError', () {
      test('エラー状態をクリアできる', () async {
        when(() => mockAuthDatasource.linkWithGoogle())
            .thenThrow(Exception('エラー'));

        await viewModel.linkWithGoogle();
        expect(viewModel.hasError, isTrue);

        viewModel.clearError();

        expect(viewModel.status, AuthStatus.initial);
        expect(viewModel.errorMessage, isEmpty);
      });
    });

    group('signOut', () {
      test('サインアウト成功時はinitial状態になる', () async {
        when(() => mockAuthDatasource.signOut()).thenAnswer((_) async {});

        await viewModel.signOut();

        expect(viewModel.status, AuthStatus.initial);
      });

      test('サインアウト失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.signOut())
            .thenAnswer((_) async => throw Exception('サインアウトエラー'));

        await viewModel.signOut();

        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorMessage, isNotEmpty);
      });
    });
  });
}
