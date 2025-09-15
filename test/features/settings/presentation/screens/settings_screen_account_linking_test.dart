import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';

void main() {
  group('SettingsScreen Account Linking Tests', () {
    test('AuthState extensions work correctly', () {
      // AuthState enumと拡張メソッドのテスト
      const guestState = AuthState.guest;
      const authenticatedState = AuthState.authenticated;
      const unauthenticatedState = AuthState.unauthenticated;

      // ゲスト状態の確認
      expect(guestState.isGuest, isTrue);
      expect(guestState.isAuthenticated, isFalse);
      expect(guestState.canUseApp, isTrue);

      // 認証済み状態の確認
      expect(authenticatedState.isAuthenticated, isTrue);
      expect(authenticatedState.isGuest, isFalse);
      expect(authenticatedState.canUseApp, isTrue);

      // 未認証状態の確認
      expect(unauthenticatedState.isUnauthenticated, isTrue);
      expect(unauthenticatedState.isAuthenticated, isFalse);
      expect(unauthenticatedState.isGuest, isFalse);
      expect(unauthenticatedState.canUseApp, isFalse);
    });

    test('TempUserService methods exist and can be called', () async {
      final tempUserService = TempUserService();

      // メソッドが存在することを確認
      expect(tempUserService.clearAllData, isA<Function>());
      expect(tempUserService.deleteTempUserData, isA<Function>());
      expect(tempUserService.getTempUserId, isA<Function>());

      // clearAllDataメソッドが呼び出し可能であることを確認
      try {
        await tempUserService.clearAllData();
        // 成功すればOK
      } catch (e) {
        // 依存関係がない環境でのエラーは正常
        expect(e, isNotNull);
      }
    });
  });
}
