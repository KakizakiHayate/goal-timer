import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/features/home/presentation/view_models/home_view_model.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(ref);
});