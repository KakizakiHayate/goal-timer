import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/features/home/presentation/view_models/home_view_model.dart';
import 'package:goal_timer/core/services/study_statistics_service.dart';
import 'package:goal_timer/core/provider/providers.dart';

// StudyStatisticsServiceのプロバイダー
final studyStatisticsServiceProvider = Provider<StudyStatisticsService>((ref) {
  return StudyStatisticsService(
    usersRepository: ref.watch(hybridUsersRepositoryProvider),
    dailyStudyLogsRepository: ref.watch(hybridDailyStudyLogsRepositoryProvider),
    goalsRepository: ref.watch(hybridGoalsRepositoryProvider),
  );
});

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  final statisticsService = ref.watch(studyStatisticsServiceProvider);
  return HomeViewModel(ref, statisticsService);
});
