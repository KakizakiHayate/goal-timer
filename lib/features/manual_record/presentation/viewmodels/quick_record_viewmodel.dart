import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/provider/providers.dart';
import '../../domain/entities/quick_record.dart';
import '../../domain/usecases/save_quick_record_usecase.dart';

/// Issue #44: 手動学習記録の状態
class QuickRecordState {
  final String goalId;
  final String goalTitle;
  final DateTime selectedDate;
  final int hours;
  final int minutes;
  final String? errorMessage;
  final bool isLoading;

  const QuickRecordState({
    required this.goalId,
    required this.goalTitle,
    required this.selectedDate,
    this.hours = 0,
    this.minutes = 0,
    this.errorMessage,
    this.isLoading = false,
  });

  QuickRecord get quickRecord => QuickRecord(
        goalId: goalId,
        date: selectedDate,
        hours: hours,
        minutes: minutes,
      );

  QuickRecordState copyWith({
    String? goalId,
    String? goalTitle,
    DateTime? selectedDate,
    int? hours,
    int? minutes,
    String? errorMessage,
    bool? isLoading,
  }) {
    return QuickRecordState(
      goalId: goalId ?? this.goalId,
      goalTitle: goalTitle ?? this.goalTitle,
      selectedDate: selectedDate ?? this.selectedDate,
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickRecordState &&
        other.goalId == goalId &&
        other.goalTitle == goalTitle &&
        other.selectedDate == selectedDate &&
        other.hours == hours &&
        other.minutes == minutes &&
        other.errorMessage == errorMessage &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return goalId.hashCode ^
        goalTitle.hashCode ^
        selectedDate.hashCode ^
        hours.hashCode ^
        minutes.hashCode ^
        errorMessage.hashCode ^
        isLoading.hashCode;
  }
}

/// Issue #44: 手動学習記録ViewModel
class QuickRecordViewModel extends StateNotifier<QuickRecordState> {
  final SaveQuickRecordUseCase _saveQuickRecordUseCase;

  QuickRecordViewModel(
    this._saveQuickRecordUseCase,
    String goalId,
    String goalTitle,
  ) : super(QuickRecordState(
          goalId: goalId,
          goalTitle: goalTitle,
          selectedDate: DateTime.now(),
        ));

  /// 時間を更新
  void updateHours(int hours) {
    state = state.copyWith(
      hours: hours.clamp(0, 23),
      errorMessage: null,
    );
  }

  /// 分を更新
  void updateMinutes(int minutes) {
    state = state.copyWith(
      minutes: minutes.clamp(0, 59),
      errorMessage: null,
    );
  }

  /// 日付を更新
  void updateDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      errorMessage: null,
    );
  }

  /// 文字列入力から時間を更新（空文字は0として扱う）
  void updateHoursFromString(String value) {
    final hours = int.tryParse(value.trim()) ?? 0;
    updateHours(hours);
  }

  /// 文字列入力から分を更新（空文字は0として扱う）
  void updateMinutesFromString(String value) {
    final minutes = int.tryParse(value.trim()) ?? 0;
    updateMinutes(minutes);
  }

  /// 学習記録を保存
  Future<bool> saveRecord() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final record = state.quickRecord;

      // バリデーションチェック
      if (!record.isValid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: record.validationError,
        );
        return false;
      }

      // 保存実行
      await _saveQuickRecordUseCase(record);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Issue #44: QuickRecordViewModelのプロバイダー
final quickRecordViewModelProvider = StateNotifierProvider.family<
    QuickRecordViewModel, QuickRecordState, Map<String, String>>(
  (ref, params) {
    final dailyStudyLogsRepository = ref.watch(hybridDailyStudyLogsRepositoryProvider);
    final goalsRepository = ref.watch(hybridGoalsRepositoryProvider);
    
    final saveUseCase = SaveQuickRecordUseCase(
      dailyStudyLogsRepository: dailyStudyLogsRepository,
      goalsRepository: goalsRepository,
    );

    return QuickRecordViewModel(
      saveUseCase,
      params['goalId']!,
      params['goalTitle']!,
    );
  },
);