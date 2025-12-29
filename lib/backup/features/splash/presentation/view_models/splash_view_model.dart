import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/backup/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

import 'package:goal_timer/backup/core/provider/providers.dart';

// スプラッシュ画面の状態
class SplashState {
  final bool isLoading;
  final String? errorMessage;
  final String? errorDetails;
  final bool isConnectionOk;
  final bool isAuthReady;

  SplashState({
    this.isLoading = true,
    this.errorMessage,
    this.errorDetails,
    this.isConnectionOk = false,
    this.isAuthReady = false,
  });

  SplashState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? errorDetails,
    bool? isConnectionOk,
    bool? isAuthReady,
  }) {
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      isConnectionOk: isConnectionOk ?? this.isConnectionOk,
      isAuthReady: isAuthReady ?? this.isAuthReady,
    );
  }

  // 初期化が完了しているかどうか
  bool get isReady => isConnectionOk && isAuthReady;
}

// スプラッシュ画面のViewModel
class SplashViewModel extends StateNotifier<SplashState> {
  final Ref _ref;

  SplashViewModel(this._ref) : super(SplashState()) {
    _initialize();
  }

  // StateNotifierがdisposeされているかどうかを追跡
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // 安全に状態を更新するヘルパーメソッド
  void _safeUpdateState(SplashState Function(SplashState) updater) {
    if (!_isDisposed) {
      state = updater(state);
    } else {
      AppLogger.instance.w('SplashViewModel: disposeされた後に状態更新が試みられました');
    }
  }

  // 初期化処理
  Future<void> _initialize() async {
    try {
      AppLogger.instance.i('SplashViewModel: アプリケーション初期化を開始します');

      // Step 1: Supabaseの初期化確認
      await _checkSupabaseConnection();

      if (!state.isConnectionOk) {
        return; // 接続に失敗した場合は早期リターン
      }

      // Step 2: 認証システムの初期化
      await _initializeAuth();
    } catch (error) {
      AppLogger.instance.e('SplashViewModel初期化エラー', error);
      _safeUpdateState(
        (state) => state.copyWith(
          isLoading: false,
          errorMessage: 'アプリケーション初期化エラー',
          errorDetails: error.toString(),
        ),
      );
    }
  }

  // 認証システムの初期化
  Future<void> _initializeAuth() async {
    try {
      if (_isDisposed) return;

      AppLogger.instance.i('SplashViewModel: 認証システムを初期化します');

      // authInitializationProviderから認証初期化を実行
      AppLogger.instance.i(
        'SplashViewModel: authInitializationProviderを読み込み開始',
      );
      await _ref.read(authInitializationProvider.future);
      AppLogger.instance.i('SplashViewModel: authInitializationProvider完了');

      // アプリ起動時の同期チェックを実行
      if (!_isDisposed) {
        AppLogger.instance.i('SplashViewModel: アプリ起動時の同期チェックを実行します');
        try {
          await _ref.read(startupSyncProvider.future);
          AppLogger.instance.i('SplashViewModel: アプリ起動時の同期チェックが完了しました');
        } catch (syncError) {
          AppLogger.instance.w(
            'SplashViewModel: アプリ起動時の同期チェックでエラーが発生しましたが、処理を続行します',
          );
          AppLogger.instance.e('同期エラー詳細', syncError);
          // 同期エラーでもアプリの初期化は完了させる
        }
      }

      // disposeチェックを追加
      if (!_isDisposed) {
        _safeUpdateState(
          (state) => state.copyWith(isAuthReady: true, isLoading: false),
        );
        AppLogger.instance.i('SplashViewModel: 初期化が完了しました');
      } else {
        AppLogger.instance.w('SplashViewModel: 初期化完了後にdisposeされていました');
      }
    } catch (error) {
      AppLogger.instance.e('認証システムの初期化に失敗しました', error);
      _safeUpdateState(
        (state) => state.copyWith(
          isLoading: false,
          errorMessage: '認証システム初期化エラー',
          errorDetails: error.toString(),
        ),
      );
    }
  }

  // Supabaseの接続状態を確認する
  Future<void> _checkSupabaseConnection() async {
    try {
      // 処理中にdisposeされた場合は早期リターン
      if (_isDisposed) {
        AppLogger.instance.w('SplashViewModel: disposeされた後に接続確認が試みられました');
        return;
      }

      // Supabaseが初期化されているか確認（クライアントの存在確認）
      Supabase.instance.client; // 初期化されていない場合はエラーになる

      // 初期化状態を確認
      if (!EnvConfig.validateSupabaseConfig()) {
        _safeUpdateState(
          (state) => state.copyWith(
            isLoading: false,
            errorMessage: '初期化エラー',
            errorDetails: 'Supabase環境変数が正しく設定されていません。.envファイルを確認してください。',
          ),
        );
        return;
      }

      // Supabaseクライアントが初期化されていれば接続成功とみなす
      // ゲストユーザーの場合、認証が必要なテーブルアクセスは失敗するため
      // 実際のネットワーク接続確認は不要（オフラインファーストアプリとして動作）
      _safeUpdateState((state) => state.copyWith(isConnectionOk: true));

      AppLogger.instance.i('SplashViewModel: Supabase接続確認完了（ゲストユーザー対応）');
    } catch (error) {
      _safeUpdateState(
        (state) => state.copyWith(
          isLoading: false,
          errorMessage: '接続確認エラー',
          errorDetails: error.toString(),
        ),
      );
    }
  }

  // 再接続を試みる
  Future<void> retryConnection() async {
    _safeUpdateState(
      (state) => state.copyWith(
        isLoading: true,
        errorMessage: null,
        errorDetails: null,
        isConnectionOk: false,
        isAuthReady: false,
      ),
    );
    await _initialize();
  }
}
