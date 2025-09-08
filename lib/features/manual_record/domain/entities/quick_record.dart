/// Issue #44: 手動学習記録エンティティ
class QuickRecord {
  final String goalId;
  final DateTime date;
  final int hours;    // 0-23時間
  final int minutes;  // 0-59分

  const QuickRecord({
    required this.goalId,
    required this.date,
    required this.hours,
    required this.minutes,
  });

  /// 合計分数を計算
  int get totalMinutes => (hours * 60) + minutes;

  /// 表示用文字列
  String get displayText {
    if (hours == 0) {
      return '${minutes}分';
    } else if (minutes == 0) {
      return '${hours}時間';
    } else {
      return '${hours}時間${minutes}分';
    }
  }

  /// バリデーション
  bool get isValid {
    // 最小値チェック: 1分以上
    if (totalMinutes < 1) return false;
    
    // 最大値チェック: 23時間59分以下
    if (hours > 23) return false;
    if (minutes > 59) return false;
    
    // 最大合計分数チェック: 1439分（23時間59分）以下
    if (totalMinutes > 1439) return false;
    
    return true;
  }

  /// バリデーションエラーメッセージ
  String? get validationError {
    if (totalMinutes < 1) {
      return '1分以上入力してください';
    }
    if (hours > 23) {
      return '23時間以下で入力してください';
    }
    if (minutes > 59) {
      return '59分以下で入力してください';
    }
    if (totalMinutes > 1439) {
      return '23時間59分以下で入力してください';
    }
    return null;
  }

  QuickRecord copyWith({
    String? goalId,
    DateTime? date,
    int? hours,
    int? minutes,
  }) {
    return QuickRecord(
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
    );
  }

  @override
  String toString() {
    return 'QuickRecord(goalId: $goalId, date: $date, hours: $hours, minutes: $minutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickRecord &&
        other.goalId == goalId &&
        other.date == date &&
        other.hours == hours &&
        other.minutes == minutes;
  }

  @override
  int get hashCode {
    return goalId.hashCode ^
        date.hashCode ^
        hours.hashCode ^
        minutes.hashCode;
  }
}