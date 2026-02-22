# エラーハンドリング統一ガイドライン

このドキュメントは、Goal Timerプロジェクトでのエラーハンドリングの統一基準を定めます。

---

## 1️⃣ AppLogger の使い方

### 基本原則

このプロジェクトでは`AppLogger`を使用してログ出力を行います。

```dart
import 'package:goal_timer/core/utils/app_logger.dart';

// シングルトンインスタンス
AppLogger.instance.d('デバッグメッセージ');
AppLogger.instance.i('情報メッセージ');
AppLogger.instance.w('警告メッセージ');
AppLogger.instance.e('エラーメッセージ', error, stackTrace);
```

### ログレベルと使い分け

| レベル | メソッド | 用途 | 例 |
|--------|---------|------|-----|
| **Debug** | `d()` | 開発時のデバッグ情報 | 変数の値、処理の開始/終了 |
| **Info** | `i()` | 通常の情報ログ | データ取得成功、処理完了 |
| **Warning** | `w()` | 警告（処理は継続） | データが空、デフォルト値使用 |
| **Error** | `e()` | エラー（例外発生） | 必ずstackTraceを含める |

### ✅ DO: エラーログには必ずstackTraceを含める

```dart
// ✅ GOOD: error と stackTrace を両方渡す
try {
  await _saveStudyLogUseCase.execute(...);
} catch (error, stackTrace) {
  AppLogger.instance.e(
    '学習時間の記録に失敗しました',
    error,
    stackTrace,  // ✅ 必須
  );
  rethrow;
}
```

### ❌ DON'T: stackTraceなしのエラーログ

```dart
// ❌ BAD: stackTraceがない
try {
  await _saveStudyLogUseCase.execute(...);
} catch (e) {
  AppLogger.instance.e('保存失敗: $e');  // ❌ デバッグが困難
}
```

### AppLogger のシグネチャ

```dart
class AppLogger {
  void d(dynamic message);
  void i(dynamic message);
  void w(dynamic message);
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]);
  //                      ↑ 位置引数（名前付きではない）
}
```

**注意**: `e()`メソッドは**位置引数**なので、名前付きパラメータは使えません。

```dart
// ❌ BAD: 名前付きパラメータ
AppLogger.instance.e('エラー', error: error, stackTrace: stackTrace);

// ✅ GOOD: 位置引数
AppLogger.instance.e('エラー', error, stackTrace);
```

---

## 2️⃣ 例外の種類と使い分け

### 標準例外

| 例外クラス | 用途 | 例 |
|-----------|------|-----|
| `ArgumentError` | **引数のバリデーションエラー** | 学習時間が0以下 |
| `StateError` | **不正な状態での操作** | 初期化前の使用 |
| `FormatException` | **データフォーマットエラー** | 日付パースエラー |
| `Exception` | **一般的なエラー** | カスタム例外の基底 |

### ✅ DO: UseCaseでArgumentErrorをスロー

```dart
class SaveStudyLogUseCase {
  Future<DailyStudyLogModel> execute({
    required String goalId,
    required int studyDurationInSeconds,
  }) async {
    // ✅ ビジネスルールのバリデーション
    if (studyDurationInSeconds <= 0) {
      throw ArgumentError('学習時間は0より大きい必要があります');
    }

    // ...
  }
}
```

### ❌ DON'T: nullを返してエラーを隠す

```dart
// ❌ BAD: エラーを隠す
Future<DailyStudyLogModel?> execute({
  required String goalId,
  required int studyDurationInSeconds,
}) async {
  if (studyDurationInSeconds <= 0) {
    return null;  // ❌ エラー理由が不明
  }
  // ...
}
```

### カスタム例外の作成（必要な場合）

```dart
// カスタム例外クラス
class SyncException implements Exception {
  final String message;
  final dynamic originalError;

  SyncException(this.message, [this.originalError]);

  @override
  String toString() => 'SyncException: $message';
}

// 使用例
throw SyncException('同期に失敗しました', error);
```

---

## 3️⃣ エラーハンドリングパターン

### パターン1: ViewModel層でのエラーハンドリング

ViewModelでは、UseCaseの例外をキャッチしてログ出力とUI状態更新を行います。

```dart
class TimerViewModel extends StateNotifier<TimerState> {
  final SaveStudyLogUseCase _saveStudyLogUseCase;

  Future<void> completeStudySession({
    required int studyTimeInSeconds,
  }) async {
    // ✅ 早期チェック（UI層のバリデーション）
    if (studyTimeInSeconds <= 0) {
      AppLogger.instance.w('学習時間が0秒のため記録しません');
      return;
    }

    try {
      AppLogger.instance.i('学習時間を記録します: $studyTimeInSeconds秒');

      // ✅ UseCaseを呼び出し
      await _saveStudyLogUseCase.execute(
        goalId: state.goalId!,
        studyDurationInSeconds: studyTimeInSeconds,
      );

      AppLogger.instance.i('学習時間の記録が完了しました');

      // ✅ 成功時のみ実行
      state = state.copyWith(status: TimerStatus.completed);

    } catch (error, stackTrace) {
      // ✅ エラーログ（stackTrace必須）
      AppLogger.instance.e(
        '学習時間の記録に失敗しました: $error',
        error,
        stackTrace,
      );

      // ✅ 必要に応じて再スロー
      rethrow;
    }
  }
}
```

### パターン2: Repository層でのエラーハンドリング

Repositoryでは、リモート保存失敗時もローカルは保存済みとします。

```dart
class HybridDailyStudyLogsRepository {
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log) async {
    // ✅ 1. まずローカルに保存（オフライン対応）
    final savedLog = await _localDatasource.upsertDailyLog(log);

    // ✅ 2. ネットワーク接続確認
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        // ✅ 3. リモートにも保存
        await _remoteDatasource.upsertDailyLog(savedLog);

        // ✅ 同期成功
        final syncedLog = savedLog.copyWith(isSynced: true);
        await _localDatasource.upsertDailyLog(syncedLog);

        return syncedLog;
      } catch (e) {
        // ✅ リモート保存失敗でもローカルは保存済み
        AppLogger.instance.e('リモート保存失敗（ローカルは保存済み）', e);
        _syncNotifier.setError(e.toString());
        // ❌ rethrowしない（ローカル保存は成功しているため）
      }
    } else {
      _syncNotifier.setOffline();
    }

    return savedLog;
  }
}
```

### パターン3: DataSource層でのエラーハンドリング

DataSourceでは、DBエラーをそのままスローします。

```dart
class LocalDailyStudyLogsDatasource {
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log) async {
    try {
      final db = await _database.database;
      await db.insert(
        'daily_study_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return log;
    } catch (e) {
      // ✅ エラーログ後、再スロー
      AppLogger.instance.e('ローカルDB保存エラー', e);
      rethrow;
    }
  }
}
```

---

## 4️⃣ rethrow の使い分け

### ✅ DO: rethrowすべきケース

```dart
// ✅ GOOD: ViewModelでエラーをキャッチしてログ出力後、再スロー
try {
  await _saveStudyLogUseCase.execute(...);
} catch (error, stackTrace) {
  AppLogger.instance.e('保存失敗', error, stackTrace);
  rethrow;  // ✅ 上位でハンドリングさせる
}
```

### ❌ DON'T: rethrowしないケース

```dart
// ✅ GOOD: リモート保存失敗でもローカルは成功
try {
  await _remoteDatasource.save(data);
} catch (e) {
  AppLogger.instance.e('リモート保存失敗', e);
  // ❌ rethrowしない（ローカル保存は成功しているため）
}
```

### rethrow vs throw の違い

```dart
try {
  await someOperation();
} catch (e) {
  // ❌ throw e: スタックトレースが失われる
  throw e;

  // ✅ rethrow: スタックトレースが保持される
  rethrow;
}
```

---

## 5️⃣ ユーザー向けエラーメッセージ設計

### 原則

1. **技術的詳細は表示しない**（ログには出力）
2. **ユーザーが取るべきアクションを示す**
3. **簡潔で分かりやすい日本語**

### 実装例

```dart
class TimerViewModel extends StateNotifier<TimerState> {
  Future<void> completeStudySession() async {
    try {
      await _saveStudyLogUseCase.execute(...);
    } catch (error, stackTrace) {
      // ✅ 開発者向けログ（詳細）
      AppLogger.instance.e('学習時間の記録に失敗しました', error, stackTrace);

      // ✅ ユーザー向けメッセージ（簡潔）
      state = state.copyWith(
        errorMessage: 'データの保存に失敗しました。ネットワーク接続を確認してください。',
      );
    }
  }
}
```

### エラーメッセージ例

| 状況 | ❌ BAD | ✅ GOOD |
|------|--------|---------|
| ネットワークエラー | `SocketException: Failed host lookup` | `ネットワーク接続を確認してください` |
| バリデーションエラー | `ArgumentError: studyDurationInSeconds <= 0` | `学習時間を入力してください` |
| 認証エラー | `401 Unauthorized` | `ログインが必要です` |

---

## 6️⃣ エラーハンドリングチェックリスト

新規実装時に以下を確認してください：

### ViewModel層
- [ ] try-catchブロックを使用している
- [ ] catch節で`error`と`stackTrace`を両方キャプチャしている
- [ ] `AppLogger.instance.e()`で**stackTraceを含めて**ログ出力している
- [ ] ユーザー向けエラーメッセージを設定している
- [ ] 必要に応じてrethrowしている

### UseCase層
- [ ] バリデーションエラーは`ArgumentError`をスローしている
- [ ] nullを返すのではなく例外をスローしている
- [ ] エラーメッセージが明確で分かりやすい

### Repository層
- [ ] ローカル保存失敗時は例外をスローしている
- [ ] リモート保存失敗時はログ出力のみ（ローカルは成功）
- [ ] 同期状態を適切に更新している

### DataSource層
- [ ] DB操作エラーをキャッチしてログ出力している
- [ ] rethrowして上位に伝播させている

---

## 7️⃣ 実装例とアンチパターン

### 例1: 完全なエラーハンドリング実装

```dart
// ✅ GOOD: 完全な実装
class TimerViewModel extends StateNotifier<TimerState> {
  final SaveStudyLogUseCase _saveStudyLogUseCase;

  Future<void> completeStudySession({
    required TimerState timerState,
    required int studyTimeInSeconds,
    required VoidCallback onGoalDataRefreshNeeded,
  }) async {
    // ✅ 1. 早期チェック
    if (!timerState.hasGoal) {
      AppLogger.instance.e('目標IDが設定されていないため、学習時間を記録できません');
      return;
    }

    if (studyTimeInSeconds <= 0) {
      AppLogger.instance.w('学習時間が0秒のため記録しません');
      return;
    }

    try {
      // ✅ 2. 処理開始ログ
      AppLogger.instance.i(
        '手動保存: 目標ID ${timerState.goalId} に $studyTimeInSeconds 秒を記録します',
      );

      // ✅ 3. UseCaseを呼び出し
      await _saveStudyLogUseCase.execute(
        goalId: timerState.goalId!,
        studyDurationInSeconds: studyTimeInSeconds,
      );

      // ✅ 4. 成功ログ
      AppLogger.instance.i('学習時間の手動記録が完了しました: $studyTimeInSeconds秒');

      // ✅ 5. 成功時のみ実行
      onGoalDataRefreshNeeded();
      state = state.copyWith(status: TimerStatus.completed);

    } catch (error, stackTrace) {
      // ✅ 6. エラーログ（stackTrace必須）
      AppLogger.instance.e(
        '学習時間の手動記録に失敗しました: $error',
        error,
        stackTrace,
      );

      // ✅ 7. ユーザー向けエラーメッセージ
      state = state.copyWith(
        errorMessage: 'データの保存に失敗しました',
      );

      // ✅ 8. 再スロー
      rethrow;
    }
  }
}
```

### 例2: アンチパターン集

```dart
// ❌ BAD: stackTraceなし
try {
  await operation();
} catch (e) {
  AppLogger.instance.e('エラー: $e');  // ❌
}

// ❌ BAD: エラーを無視
try {
  await operation();
} catch (e) {
  // ❌ 何もしない
}

// ❌ BAD: nullを返す
Future<Data?> getData() async {
  try {
    return await _repository.fetch();
  } catch (e) {
    return null;  // ❌ エラー理由が不明
  }
}

// ❌ BAD: 名前付きパラメータ
AppLogger.instance.e('エラー', error: e, stackTrace: st);  // ❌

// ❌ BAD: throw e でスタックトレース失う
try {
  await operation();
} catch (e) {
  throw e;  // ❌ rethrowを使うべき
}
```

---

## まとめ

### 必須ルール

1. **エラーログには必ずstackTraceを含める**
2. **例外は`AppLogger.instance.e(message, error, stackTrace)`で出力**
3. **UseCaseではArgumentErrorをスロー（nullを返さない）**
4. **ViewModel層でtry-catchしてユーザー向けメッセージを設定**
5. **rethrowでスタックトレースを保持**

### 推奨事項

- バリデーションエラーは早期チェックで検出
- ローカル保存優先（オフライン対応）
- リモート保存失敗時もローカルは保存済みとする
- エラーメッセージは簡潔で分かりやすく

**このガイドラインに従うことで、デバッグ効率が向上し、ユーザー体験も改善されます。**
