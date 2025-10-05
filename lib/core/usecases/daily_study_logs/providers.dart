import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'save_study_log_usecase.dart';

/// SaveStudyLogUseCaseのProvider
final saveStudyLogUseCaseProvider = Provider<SaveStudyLogUseCase>((ref) {
  final repository = ref.watch(hybridDailyStudyLogsRepositoryProvider);
  return SaveStudyLogUseCase(repository: repository);
});
