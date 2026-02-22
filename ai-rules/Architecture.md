# MVVM Architecture - Goal Timer

Goal TimerプロジェクトのMVVMアーキテクチャ定義（MVP版: シンプル構造）

---

## 📐 MVVMとは

**MVVM (Model-View-ViewModel)** は、UIとビジネスロジックを分離するアーキテクチャパターンです。

```
┌─────────────┐
│    View     │  UI表示、ユーザー入力
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  ViewModel  │  状態管理、ビジネスロジック
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ DataSource  │  実際のDB操作（SQLite）
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   SQLite    │  ローカルDB
└─────────────┘
```

**MVP開発のため、Repository層は省略しています。**
将来Supabase同期が必要になったら追加します。

---

## 1️⃣ 各層の役割

### View（ビュー）

**役割:**
- UI表示
- ユーザー入力の受け取り
- ViewModelの呼び出し

**実装:**
```dart
class TimerScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerViewModel>(
      builder: (viewModel) {
        return ElevatedButton(
          onPressed: () => viewModel.saveLog(),
          child: Text('完了'),
        );
      },
    );
  }
}
```

---

### ViewModel（ビューモデル）

**役割:**
- UI状態の管理
- ビジネスロジック
- DataSourceのメソッド呼び出し
- エラーハンドリング

**実装:**
```dart
class TimerViewModel extends GetxController {
  late final LocalStudyDailyLogsDatasource _datasource;

  TimerState _state = TimerState();
  TimerState get state => _state;

  int _elapsedSeconds = 0;

  TimerViewModel() {
    // DataSource のインスタンス化
    _datasource = LocalStudyDailyLogsDatasource(database: AppDatabase());
  }

  Future<void> saveLog() async {
    try {
      // バリデーション
      if (_elapsedSeconds <= 0 || state.goalId == null) return;

      // Modelを生成
      final today = DateTime.now();
      final log = StudyDailyLogsModel(
        id: const Uuid().v4(),
        goalId: state.goalId!,
        studyDate: DateTime(today.year, today.month, today.day),
        totalSeconds: _elapsedSeconds,
        createdAt: today,
      );

      // DataSource経由でデータ保存
      await _datasource.saveLog(log, isSynced: false);

      // UI状態を更新
      resetTimer();
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('保存失敗', error, stackTrace);
    }
  }

  void resetTimer() {
    _elapsedSeconds = 0;
    _state = state.copyWith(seconds: 0);
    update();
  }
}
```

---

### DataSource（データソース）

**役割:**
- 実際のDB操作（SQLite）
- CRUD操作の実装

**実装:**
```dart
class LocalStudyDailyLogsDatasource {
  final AppDatabase _database;

  LocalStudyDailyLogsDatasource({required AppDatabase database})
      : _database = database;

  Future<void> saveLog(StudyDailyLogsModel log, {bool isSynced = false}) async {
    final db = await _database.database;
    await db.insert(
      DatabaseConsts.tableStudyDailyLogs,
      _modelToMap(log, isSynced: isSynced),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudyDailyLogsModel>> fetchAllLogs() async {
    final db = await _database.database;
    final maps = await db.query(DatabaseConsts.tableStudyDailyLogs);
    return maps.map((map) => _mapToModel(map)).toList();
  }

  Map<String, dynamic> _modelToMap(StudyDailyLogsModel model, {required bool isSynced}) {
    return {
      DatabaseConsts.columnId: model.id,
      DatabaseConsts.columnGoalId: model.goalId,
      DatabaseConsts.columnStudyDate: model.studyDate.toIso8601String(),
      DatabaseConsts.columnTotalSeconds: model.totalSeconds,
      DatabaseConsts.columnSyncUpdatedAt: isSynced ? DateTime.now().toIso8601String() : null,
    };
  }

  StudyDailyLogsModel _mapToModel(Map<String, dynamic> map) {
    return StudyDailyLogsModel(
      id: map[DatabaseConsts.columnId] as String,
      goalId: map[DatabaseConsts.columnGoalId] as String,
      studyDate: DateTime.parse(map[DatabaseConsts.columnStudyDate] as String),
      totalSeconds: map[DatabaseConsts.columnTotalSeconds] as int,
    );
  }
}
```

---

### Model（モデル）

**役割:**
- データモデルの定義のみ（freezed）
- データアクセスメソッドは持たない

**実装:**
```dart
@freezed
class StudyDailyLogsModel with _$StudyDailyLogsModel {
  const factory StudyDailyLogsModel({
    required String id,
    required String goalId,
    required DateTime studyDate,
    required int totalSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncUpdatedAt,
  }) = _StudyDailyLogsModel;

  factory StudyDailyLogsModel.fromJson(Map<String, dynamic> json) =>
      _$StudyDailyLogsModelFromJson(json);
}
```

---

## 2️⃣ ディレクトリ構造

```
lib/
├── core/
│   ├── data/                      # データ層
│   │   └── local/                 # ローカルデータ関連（統合）
│   │       ├── datasources/       # DataSource実装
│   │       │   └── local_study_daily_logs_datasource.dart
│   │       ├── app_database.dart  # SQLite DB管理（シングルトン）
│   │       └── database_consts.dart  # DB定数（テーブル名・カラム名）
│   │
│   ├── models/                    # Model（データモデル定義のみ、freezed）
│   │   ├── study_daily_logs/
│   │   │   └── study_daily_logs_model.dart
│   │   ├── goals/
│   │   │   └── goals_model.dart
│   │   └── users/
│   │       └── users_model.dart
│   │
│   ├── utils/                     # ユーティリティ
│   │   ├── app_logger.dart
│   │   ├── color_consts.dart
│   │   ├── text_consts.dart
│   │   └── ...
│   │
│   └── widgets/                   # 共通ウィジェット
│       ├── common_button.dart
│       ├── goal_card.dart
│       └── ...
│
├── features/                      # 機能別モジュール（Feature-First）
│   ├── timer/
│   │   ├── view/                 # View層
│   │   │   └── timer_screen.dart
│   │   └── view_model/           # ViewModel層
│   │       └── timer_view_model.dart
│   │
│   ├── home/
│   │   ├── view/
│   │   │   └── home_screen.dart
│   │   └── view_model/
│   │       └── home_view_model.dart
│   │
│   └── settings/
│       └── view/
│           └── settings_screen.dart
│
└── main.dart
```

---

## 3️⃣ データフロー

```
┌───────────────┐
│  ユーザー操作  │
│ (ボタンタップ) │
└───────┬───────┘
        │
        ▼
┌────────────────────────┐
│  View (timer_screen)   │
│  viewModel.saveLog()   │
└───────┬────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  ViewModel                   │
│  - バリデーション             │
│  - Modelインスタンス生成      │
│  - DataSource.saveLog()呼び出し│
│  - update() でUI更新          │
└───────┬──────────────────────┘
        │
        ▼
┌──────────────────────────────┐
│  DataSource                  │
│  - SQLiteにデータ保存         │
│  - Map⇄Model変換             │
└──────────────────────────────┘
```

---

## 4️⃣ GetXでの実装

### ViewModelの生成

**View層でViewModelを生成:**

```dart
class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();

    // ViewModel の生成（DataSourceは内部でインスタンス化）
    Get.put(TimerViewModel());
  }

  @override
  void dispose() {
    Get.delete<TimerViewModel>();
    super.dispose();
  }
}
```

---


---

### 状態管理

**ViewModel:**
```dart
class TimerViewModel extends GetxController {
  TimerState _state = TimerState();
  TimerState get state => _state;

  void startTimer() {
    _state = state.copyWith(isRunning: true);
    update(); // ← GetBuilderに通知
  }
}
```

**View:**
```dart
GetBuilder<TimerViewModel>(
  builder: (viewModel) {
    final state = viewModel.state;
    return Text('${state.seconds}秒');
  },
)
```

---

## 5️⃣ 完全な実装例

### 1. Model

`lib/core/models/daily_study_logs/daily_study_log_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';

part 'daily_study_log_model.freezed.dart';
part 'daily_study_log_model.g.dart';

@freezed
class DailyStudyLogModel with _$DailyStudyLogModel {
  const factory DailyStudyLogModel({
    required String id,
    required String goalId,
    required DateTime date,
    required int totalSeconds,
    DateTime? createdAt,
  }) = _DailyStudyLogModel;

  /// ファクトリーメソッド: 新規作成
  factory DailyStudyLogModel.create({
    required String goalId,
    required int totalSeconds,
  }) {
    final today = DateTime.now();
    return DailyStudyLogModel(
      id: const Uuid().v4(),
      goalId: goalId,
      date: DateTime(today.year, today.month, today.day),
      totalSeconds: totalSeconds,
      createdAt: today,
    );
  }

  /// データアクセス: 保存
  static Future<void> save(DailyStudyLogModel log) async {
    final db = await AppDatabase().database;
    await db.insert(
      'daily_study_logs',
      log.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// データアクセス: 全件取得
  static Future<List<DailyStudyLogModel>> getAll() async {
    final db = await AppDatabase().database;
    final maps = await db.query('daily_study_logs');
    return maps.map((m) => DailyStudyLogModel.fromJson(m)).toList();
  }

  /// データアクセス: 目標IDで取得
  static Future<List<DailyStudyLogModel>> getByGoalId(String goalId) async {
    final db = await AppDatabase().database;
    final maps = await db.query(
      'daily_study_logs',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    return maps.map((m) => DailyStudyLogModel.fromJson(m)).toList();
  }

  /// データアクセス: 削除
  static Future<void> delete(String id) async {
    final db = await AppDatabase().database;
    await db.delete(
      'daily_study_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  factory DailyStudyLogModel.fromJson(Map<String, dynamic> json) =>
      _$DailyStudyLogModelFromJson(json);
}
```

---

### 2. ViewModel

`lib/features/timer/view_model/timer_view_model.dart`

```dart
import 'dart:async';
import 'package:get/get.dart';
import '../../../core/models/daily_study_logs/daily_study_log_model.dart';
import '../../../core/utils/app_logger.dart';

class TimerViewModel extends GetxController {
  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _goalId;

  TimerState _state = TimerState();
  TimerState get state => _state;

  void setGoalId(String goalId) => _goalId = goalId;

  Future<void> onTappedTimerFinishButton() async {
    try {
      // バリデーション
      if (_elapsedSeconds <= 0) {
        AppLogger.instance.w('学習時間が0秒のため記録しません');
        return;
      }

      if (_goalId == null) {
        AppLogger.instance.e('目標IDが設定されていません');
        return;
      }

      AppLogger.instance.i('学習記録を保存します: $_elapsedSeconds秒');

      // Modelを生成
      final log = DailyStudyLogModel.create(
        goalId: _goalId!,
        totalSeconds: _elapsedSeconds,
      );

      // Modelのメソッドで保存
      await DailyStudyLogModel.save(log);

      AppLogger.instance.i('学習記録を保存しました');

      // タイマーをリセット
      resetTimer();
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習記録の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    _state = state.copyWith(status: TimerStatus.running);
    update();
    _elapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      _state = state.copyWith(currentSeconds: _elapsedSeconds);
      update();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = state.copyWith(status: TimerStatus.paused);
    update();
  }

  void resetTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _state = state.copyWith(
      currentSeconds: 0,
      status: TimerStatus.initial,
    );
    update();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

// TimerState定義
enum TimerStatus { initial, running, paused, completed }

class TimerState {
  final int currentSeconds;
  final TimerStatus status;

  TimerState({
    this.currentSeconds = 0,
    this.status = TimerStatus.initial,
  });

  TimerState copyWith({
    int? currentSeconds,
    TimerStatus? status,
  }) {
    return TimerState(
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
    );
  }

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
}
```

---

### 3. View

`lib/features/timer/view/timer_screen.dart`

```dart
class TimerScreen extends StatefulWidget {
  final String goalId;

  const TimerScreen({required this.goalId, super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();

    // ViewModelを生成
    Get.put(TimerViewModel());

    // 目標IDを設定
    Get.find<TimerViewModel>().setGoalId(widget.goalId);
  }

  @override
  void dispose() {
    // ViewModelを削除
    Get.delete<TimerViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TimerViewModel>(
      builder: (viewModel) {
        final state = viewModel.state;

        return Scaffold(
          appBar: AppBar(title: Text('タイマー')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // タイマー表示
                Text(
                  '${state.currentSeconds}秒',
                  style: TextStyle(fontSize: 48),
                ),

                SizedBox(height: 32),

                // スタート/一時停止ボタン
                ElevatedButton(
                  onPressed: state.isRunning
                      ? () => viewModel.pauseTimer()
                      : () => viewModel.startTimer(),
                  child: Text(state.isRunning ? '一時停止' : 'スタート'),
                ),

                SizedBox(height: 16),

                // 完了ボタン
                ElevatedButton(
                  onPressed: () async {
                    await viewModel.onTappedTimerFinishButton();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('完了'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 6️⃣ ルール

### ✅ DO（推奨）

```dart
// ViewModelでDataSource経由でデータ操作
await _datasource.saveLog(log, isSynced: false);

// ViewModelでDataSourceをインスタンス化
TimerViewModel() {
  _datasource = LocalStudyDailyLogsDatasource(database: AppDatabase());
}

// 状態変更後はupdate()を呼ぶ
_state = state.copyWith(isRunning: true);
update();

// ViewModelは画面ごとに生成・削除
Get.put(TimerViewModel());  // initState
Get.delete<TimerViewModel>();  // dispose
```

### ❌ DON'T（非推奨）

```dart
// ViewModelで直接DB操作しない
final db = await AppDatabase().database;
await db.insert(...);  // ❌ DataSource経由で

// Modelに静的メソッドを定義しない
static Future<void> save(Model model) { ... }  // ❌ DataSourceに実装

// ViewでDataSourceを直接呼ばない
await datasource.saveLog(...);  // ❌ ViewModel経由で
```

---

## まとめ

**MVVMの3層（MVP版）:**

1. **View** → UI表示、GetBuilderで状態購読
2. **ViewModel** → 状態管理 + ビジネスロジック + DataSource呼び出し
3. **DataSource** → 実際のDB操作（SQLite）、Map⇄Model変換

**GetXの役割:**
- 状態管理: `GetxController` + `update()`
- ライフサイクル管理: `initState` で `Get.put()`, `dispose` で `Get.delete()`

**データアクセス:**
- ViewModel → DataSource → SQLite
- Modelはデータ定義のみ（freezed）、データアクセスメソッドは持たない
- DataSourceがMap⇄Model変換を担当

**メリット:**
- ✅ シンプルで理解しやすい
- ✅ コード量が少ない
- ✅ MVP開発に最適

**将来の拡張:**
アプリが人気になったら、Repository層を追加してSupabase同期を実装できます。

```dart
// 将来的にはこうなる
ViewModel → Repository → LocalDataSource + SupabaseDataSource
```

MVP開発に適した、シンプルで拡張性のあるMVVMアーキテクチャです。
