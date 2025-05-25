import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/splash/presentation/viewmodels/splash_view_model.dart';

final splashViewModelProvider =
    StateNotifierProvider<SplashViewModel, SplashState>((ref) {
      return SplashViewModel();
    });