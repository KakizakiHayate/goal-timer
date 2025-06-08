import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/splash/presentation/view_models/splash_view_model.dart';
import 'package:goal_timer/core/provider/providers.dart';

final splashViewModelProvider =
    StateNotifierProvider<SplashViewModel, SplashState>((ref) {
      // supabaseInitProviderに依存させることで、Supabaseの初期化を待つ
      ref.watch(supabaseInitProvider);
      return SplashViewModel();
    });
