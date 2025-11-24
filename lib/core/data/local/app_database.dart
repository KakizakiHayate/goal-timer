import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_consts.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConsts.databaseName);

    return openDatabase(
      path,
      version: DatabaseConsts.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // バージョンごとのマイグレーションロジック
    if (oldVersion < 2) {
      // バージョン2へのマイグレーション: goalsテーブルにcompleted_atカラムを追加
      await db.execute('''
        ALTER TABLE ${DatabaseConsts.tableGoals}
        ADD COLUMN ${DatabaseConsts.columnCompletedAt} TEXT
      ''');
    }
    // 今後のバージョンアップ時は、ここに追加のマイグレーションロジックを記述
    // if (oldVersion < 3) { ... }
  }

  /// テーブルを作成
  Future<void> _createTables(Database db) async {
    // study_daily_logsテーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConsts.tableStudyDailyLogs} (
        ${DatabaseConsts.columnId} TEXT PRIMARY KEY,
        ${DatabaseConsts.columnGoalId} TEXT NOT NULL,
        ${DatabaseConsts.columnStudyDate} TEXT NOT NULL,
        ${DatabaseConsts.columnTotalSeconds} INTEGER NOT NULL,
        ${DatabaseConsts.columnUserId} TEXT,
        ${DatabaseConsts.columnCreatedAt} TEXT,
        ${DatabaseConsts.columnUpdatedAt} TEXT,
        ${DatabaseConsts.columnSyncUpdatedAt} TEXT
      )
    ''');

    // goalsテーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConsts.tableGoals} (
        ${DatabaseConsts.columnId} TEXT PRIMARY KEY,
        ${DatabaseConsts.columnUserId} TEXT,
        ${DatabaseConsts.columnTitle} TEXT NOT NULL,
        ${DatabaseConsts.columnDescription} TEXT,
        ${DatabaseConsts.columnTargetMinutes} INTEGER NOT NULL,
        ${DatabaseConsts.columnAvoidMessage} TEXT NOT NULL,
        ${DatabaseConsts.columnDeadline} TEXT NOT NULL,
        ${DatabaseConsts.columnCompletedAt} TEXT,
        ${DatabaseConsts.columnCreatedAt} TEXT,
        ${DatabaseConsts.columnUpdatedAt} TEXT,
        ${DatabaseConsts.columnSyncUpdatedAt} TEXT
      )
    ''');

    // usersテーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConsts.tableUsers} (
        ${DatabaseConsts.columnId} TEXT PRIMARY KEY,
        ${DatabaseConsts.columnEmail} TEXT,
        ${DatabaseConsts.columnDisplayName} TEXT,
        ${DatabaseConsts.columnCreatedAt} TEXT,
        ${DatabaseConsts.columnUpdatedAt} TEXT,
        ${DatabaseConsts.columnLastLogin} TEXT,
        ${DatabaseConsts.columnSyncUpdatedAt} TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
