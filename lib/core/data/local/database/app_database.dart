import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static String? _databasePath;

  AppDatabase._init();

  // データベースのパスを取得
  static String? get databasePath => _databasePath;

  // データベースを初期化するメソッド
  Future<void> initialize() async {
    AppLogger.instance.i('SQLiteデータベースを初期化しています...');
    await database; // データベースを取得（必要に応じて作成）
    await _logDatabasePath(); // データベースパスをログに出力
    AppLogger.instance.i('SQLiteデータベースの初期化が完了しました');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goal_timer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      _databasePath = path; // パスを保存

      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e) {
      AppLogger.instance.e('データベース初期化エラー: $e');
      rethrow;
    }
  }

  // データベースパスの詳細をログに出力
  Future<void> _logDatabasePath() async {
    try {
      if (_databasePath == null) {
        AppLogger.instance.e('データベースパスが取得できませんでした');
        return;
      }

      final dbFile = File(_databasePath!);
      final exists = await dbFile.exists();
      final fileSize = exists ? await dbFile.length() : 0;

      // アプリのドキュメントディレクトリ
      final appDocDir = await getApplicationDocumentsDirectory();

      // デバイス情報
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;

      AppLogger.instance.i('====================================');
      AppLogger.instance.i('🔍 SQLiteデータベース情報');
      AppLogger.instance.i('====================================');
      AppLogger.instance.i('📱 デバイス: $platform $version');
      AppLogger.instance.i('📁 データベースパス: $_databasePath');
      AppLogger.instance.i('📁 ドキュメントディレクトリ: ${appDocDir.path}');
      AppLogger.instance.i('💾 ファイル存在: $exists');
      if (exists) {
        AppLogger.instance.i(
          '💾 ファイルサイズ: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        );
      }
      AppLogger.instance.i('');
      AppLogger.instance.i('📌 DB Browserでの開き方:');
      AppLogger.instance.i('1. DB Browser for SQLiteを起動');
      AppLogger.instance.i('2. 「データベースを開く」をクリック');
      AppLogger.instance.i('3. 上記のパスを指定');
      AppLogger.instance.i('====================================');

      // 標準出力にも表示（ログが見つけにくい場合用）
      AppLogger.instance.i('SQLiteデータベースのパス: $_databasePath');
      AppLogger.instance.i('ドキュメントディレクトリ: ${appDocDir.path}');
    } catch (e) {
      AppLogger.instance.e('データベースパス情報のログ出力に失敗', e);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // usersテーブル
      await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        display_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_login TEXT,
        is_synced INTEGER DEFAULT 0
      )
      ''');

      // goalsテーブル
      await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        is_completed INTEGER NOT NULL,
        avoid_message TEXT NOT NULL,
        total_target_hours INTEGER NOT NULL,
        spent_minutes INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
      ''');

      // daily_study_logsテーブル
      await db.execute('''
      CREATE TABLE daily_study_logs (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        date TEXT NOT NULL,
        minutes INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (goal_id) REFERENCES goals (id)
      )
      ''');

      // 同期メタデータテーブル
      await db.execute('''
      CREATE TABLE sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_sync_time TEXT NOT NULL
      )
      ''');

      // リモート最終更新時刻テーブル
      await db.execute('''
      CREATE TABLE remote_last_modified (
        table_name TEXT PRIMARY KEY,
        last_modified TEXT NOT NULL
      )
      ''');

      // オフライン操作追跡テーブル
      await db.execute('''
      CREATE TABLE offline_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        record_id TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
      ''');
    } catch (e) {
      AppLogger.instance.e('テーブル作成エラー: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      AppLogger.instance.i('データベースをバージョン$oldVersionから$newVersionにアップグレードします');

      if (oldVersion < 2) {
        // バージョン2へのマイグレーション: sync_updated_atカラムを追加
        AppLogger.instance.i('sync_updated_atカラムを追加しています...');

        // usersテーブルにsync_updated_atカラムを追加
        await db.execute('''
          ALTER TABLE users ADD COLUMN sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        ''');

        // goalsテーブルにsync_updated_atカラムを追加
        await db.execute('''
          ALTER TABLE goals ADD COLUMN sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        ''');

        // daily_study_logsテーブルにsync_updated_atカラムを追加
        await db.execute('''
          ALTER TABLE daily_study_logs ADD COLUMN sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        ''');

        // リモート最終更新時刻テーブルを作成
        await db.execute('''
          CREATE TABLE remote_last_modified (
            table_name TEXT PRIMARY KEY,
            last_modified TEXT NOT NULL
          )
        ''');

        AppLogger.instance.i('バージョン2へのマイグレーションが完了しました');
      }

      if (oldVersion < 3) {
        // バージョン3へのマイグレーション: 新機能の追加
        AppLogger.instance.i('バージョン3へのマイグレーションを実行中...');

        // 必要な新しいテーブルや設定の追加など
        AppLogger.instance.i('バージョン3へのマイグレーションが完了しました');
      }
    } catch (e) {
      AppLogger.instance.e('データベースアップグレードエラー: $e');
      rethrow;
    }
  }

  // データベースファイルパスを取得
  Future<String> getPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'goal_timer.db');
  }

  // データベースインスタンスを明示的に閉じる
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
