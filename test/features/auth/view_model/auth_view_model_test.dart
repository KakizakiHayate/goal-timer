import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/data/supabase/auth_result.dart';
import 'package:goal_timer/core/data/supabase/supabase_auth_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_users_datasource.dart';
import 'package:goal_timer/features/auth/view_model/auth_view_model.dart';

// モッククラス
class MockSupabaseAuthDatasource extends Mock
    implements SupabaseAuthDatasource {}

class MockLocalUsersDatasource extends Mock implements LocalUsersDatasource {}

class MockSupabaseUsersDatasource extends Mock
    implements SupabaseUsersDatasource {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseAuthDatasource mockAuthDatasource;
  late MockLocalUsersDatasource mockUsersDatasource;
  late MockSupabaseUsersDatasource mockSupabaseUsersDatasource;
  late MockUser mockUser;
  late AuthViewModel viewModel;

  setUp(() {
    mockAuthDatasource = MockSupabaseAuthDatasource();
    mockUsersDatasource = MockLocalUsersDatasource();
    mockSupabaseUsersDatasource = MockSupabaseUsersDatasource();
    mockUser = MockUser();
    Get.testMode = true;

    // デフォルトのスタブ
    when(() => mockAuthDatasource.isAnonymous).thenReturn(true);
    when(() => mockAuthDatasource.currentUser).thenReturn(null);
    when(() => mockUser.id).thenReturn('test-user-id');
    when(
      () => mockUsersDatasource.updateDisplayName(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockUsersDatasource.resetDisplayName(),
    ).thenAnswer((_) async {});
    when(
      () => mockSupabaseUsersDatasource.updateDisplayName(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSupabaseUsersDatasource.getDisplayName(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockSupabaseUsersDatasource.checkAccountExists(
        email: any(named: 'email'),
        provider: any(named: 'provider'),
      ),
    ).thenAnswer((_) async => false);
    when(
      () => mockSupabaseUsersDatasource.upsertEmailAndProvider(
        userId: any(named: 'userId'),
        email: any(named: 'email'),
        provider: any(named: 'provider'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockAuthDatasource.clearGoogleSession(),
    ).thenAnswer((_) async {});

    viewModel = AuthViewModel(
      authDatasource: mockAuthDatasource,
      usersDatasource: mockUsersDatasource,
      supabaseUsersDatasource: mockSupabaseUsersDatasource,
    );
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

      test('初期状態でerrorTypeはnoneである', () {
        expect(viewModel.errorType, AuthErrorType.none);
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

        final linkedViewModel = AuthViewModel(
          authDatasource: mockAuthDatasource,
          usersDatasource: mockUsersDatasource,
          supabaseUsersDatasource: mockSupabaseUsersDatasource,
        );

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

        final linkedViewModel = AuthViewModel(
          authDatasource: mockAuthDatasource,
          usersDatasource: mockUsersDatasource,
          supabaseUsersDatasource: mockSupabaseUsersDatasource,
        );

        expect(linkedViewModel.showLinkButton, isFalse);
      });
    });

    group('linkWithGoogle', () {
      test('連携成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'test@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );
        when(() => mockAuthDatasource.completeSignInWithGoogle(any()))
            .thenAnswer((_) async {});
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);

        final result = await viewModel.linkWithGoogle();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
        verify(
          () => mockSupabaseUsersDatasource.upsertEmailAndProvider(
            userId: 'test-user-id',
            email: 'test@example.com',
            provider: AuthProvider.google,
          ),
        ).called(1);
      });

      test('連携キャンセル時はinitial状態のままである', () async {
        when(() => mockAuthDatasource.authenticateGoogle())
            .thenAnswer((_) async => AuthResult.cancelled());

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.initial);
      });

      test('emailがnullの場合はemailNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: null,
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.emailNotFound);
        verify(() => mockAuthDatasource.clearGoogleSession()).called(1);
      });

      test('アカウントが既に存在する場合はaccountAlreadyExistsエラーになる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'existing@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'existing@example.com',
            provider: AuthProvider.google,
          ),
        ).thenAnswer((_) async => true);

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.accountAlreadyExists);
        verify(() => mockAuthDatasource.clearGoogleSession()).called(1);
        verifyNever(() => mockAuthDatasource.completeSignInWithGoogle(any()));
      });

      test('連携失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.authenticateGoogle())
            .thenThrow(Exception('Google連携エラー'));

        final result = await viewModel.linkWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.other);
        expect(viewModel.errorMessage, isNotEmpty);
      });
    });

    group('linkWithApple', () {
      test('連携成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'test@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );
        when(
          () => mockAuthDatasource.completeSignInWithApple(
            idToken: any(named: 'idToken'),
            rawNonce: any(named: 'rawNonce'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);

        final result = await viewModel.linkWithApple();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
        verify(
          () => mockSupabaseUsersDatasource.upsertEmailAndProvider(
            userId: 'test-user-id',
            email: 'test@example.com',
            provider: AuthProvider.apple,
          ),
        ).called(1);
      });

      test('連携キャンセル時はinitial状態のままである', () async {
        when(() => mockAuthDatasource.authenticateApple())
            .thenAnswer((_) async => AuthResult.cancelled());

        final result = await viewModel.linkWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.initial);
      });

      test('emailがnullの場合はemailNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: null,
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );

        final result = await viewModel.linkWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.emailNotFound);
      });

      test('アカウントが既に存在する場合はaccountAlreadyExistsエラーになる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'existing@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'existing@example.com',
            provider: AuthProvider.apple,
          ),
        ).thenAnswer((_) async => true);

        final result = await viewModel.linkWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.accountAlreadyExists);
        verifyNever(
          () => mockAuthDatasource.completeSignInWithApple(
            idToken: any(named: 'idToken'),
            rawNonce: any(named: 'rawNonce'),
          ),
        );
      });
    });

    group('loginWithGoogle', () {
      test('ログイン成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'test@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'test@example.com',
            provider: AuthProvider.google,
          ),
        ).thenAnswer((_) async => true);
        when(() => mockAuthDatasource.completeSignInWithGoogle(any()))
            .thenAnswer((_) async {});
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);

        final result = await viewModel.loginWithGoogle();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
      });

      test('アカウントが存在しない場合はaccountNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'new@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'new@example.com',
            provider: AuthProvider.google,
          ),
        ).thenAnswer((_) async => false);

        final result = await viewModel.loginWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.accountNotFound);
        verify(() => mockAuthDatasource.clearGoogleSession()).called(1);
        verifyNever(() => mockAuthDatasource.completeSignInWithGoogle(any()));
      });

      test('emailがnullの場合はemailNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateGoogle()).thenAnswer(
          (_) async => AuthResult.success(
            email: null,
            displayName: 'Test User',
            idToken: 'test-id-token',
          ),
        );

        final result = await viewModel.loginWithGoogle();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.emailNotFound);
        verify(() => mockAuthDatasource.clearGoogleSession()).called(1);
      });
    });

    group('loginWithApple', () {
      test('ログイン成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'test@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'test@example.com',
            provider: AuthProvider.apple,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockAuthDatasource.completeSignInWithApple(
            idToken: any(named: 'idToken'),
            rawNonce: any(named: 'rawNonce'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockAuthDatasource.currentUser).thenReturn(mockUser);

        final result = await viewModel.loginWithApple();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
      });

      test('アカウントが存在しない場合はaccountNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: 'new@example.com',
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );
        when(
          () => mockSupabaseUsersDatasource.checkAccountExists(
            email: 'new@example.com',
            provider: AuthProvider.apple,
          ),
        ).thenAnswer((_) async => false);

        final result = await viewModel.loginWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.accountNotFound);
        verifyNever(
          () => mockAuthDatasource.completeSignInWithApple(
            idToken: any(named: 'idToken'),
            rawNonce: any(named: 'rawNonce'),
          ),
        );
      });

      test('emailがnullの場合はemailNotFoundエラーになる', () async {
        when(() => mockAuthDatasource.authenticateApple()).thenAnswer(
          (_) async => AuthResult.success(
            email: null,
            displayName: 'Test User',
            idToken: 'test-id-token',
            rawNonce: 'test-raw-nonce',
          ),
        );

        final result = await viewModel.loginWithApple();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.emailNotFound);
      });
    });

    group('clearError', () {
      test('エラー状態をクリアできる', () async {
        when(() => mockAuthDatasource.authenticateGoogle())
            .thenThrow(Exception('エラー'));

        await viewModel.linkWithGoogle();
        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorType, AuthErrorType.other);

        viewModel.clearError();

        expect(viewModel.status, AuthStatus.initial);
        expect(viewModel.errorMessage, isEmpty);
        expect(viewModel.errorType, AuthErrorType.none);
      });
    });

    group('signOut', () {
      test('サインアウト成功時はinitial状態になる', () async {
        when(() => mockAuthDatasource.signOut()).thenAnswer((_) async {});

        await viewModel.signOut();

        expect(viewModel.status, AuthStatus.initial);
        expect(viewModel.errorType, AuthErrorType.none);
      });

      test('サインアウト失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.signOut())
            .thenAnswer((_) async => throw Exception('サインアウトエラー'));

        await viewModel.signOut();

        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.other);
        expect(viewModel.errorMessage, isNotEmpty);
      });
    });

    group('deleteAccount', () {
      test('アカウント削除成功時はsuccess状態になる', () async {
        when(() => mockAuthDatasource.deleteAccount()).thenAnswer((_) async {});

        final result = await viewModel.deleteAccount();

        expect(result, isTrue);
        expect(viewModel.status, AuthStatus.success);
        verify(() => mockUsersDatasource.resetDisplayName()).called(1);
      });

      test('アカウント削除失敗時はerror状態になる', () async {
        when(() => mockAuthDatasource.deleteAccount())
            .thenThrow(Exception('削除エラー'));

        final result = await viewModel.deleteAccount();

        expect(result, isFalse);
        expect(viewModel.status, AuthStatus.error);
        expect(viewModel.errorType, AuthErrorType.other);
      });
    });
  });
}
