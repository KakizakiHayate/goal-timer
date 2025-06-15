import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/data/local/database/app_database.dart';
import 'package:flutter/services.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class SQLiteViewerScreen extends ConsumerStatefulWidget {
  const SQLiteViewerScreen({super.key});

  @override
  ConsumerState<SQLiteViewerScreen> createState() => _SQLiteViewerScreenState();
}

class _SQLiteViewerScreenState extends ConsumerState<SQLiteViewerScreen> {
  bool _isLoading = true;
  List<String> _tableNames = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _columnNames = [];
  String _dbPath = '';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // データベースのパスを取得
      final dbPath = await getDatabasesPath();
      final path = path_lib.join(dbPath, 'goal_timer.db');
      _dbPath = path;

      // データベース接続
      final db = await AppDatabase.instance.database;

      // テーブル一覧を取得
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );
      _tableNames = tables.map((table) => table['name'] as String).toList();

      if (_tableNames.isNotEmpty) {
        _selectedTable = _tableNames.first;
        await _loadTableData(_selectedTable!);
      }
    } catch (e) {
      AppLogger.instance.e('データベース初期化エラー', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データベースエラー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await AppDatabase.instance.database;

      // テーブルのカラム情報を取得
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      _columnNames = tableInfo.map((col) => col['name'] as String).toList();

      // テーブルのデータを取得
      _tableData = await db.query(tableName);
    } catch (e) {
      AppLogger.instance.e('テーブルデータ取得エラー', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('テーブルデータ取得エラー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQLiteデータビューア')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'データベースパス: $_dbPath',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedTable,
                      hint: const Text('テーブルを選択'),
                      onChanged: (newValue) {
                        if (newValue != null && newValue != _selectedTable) {
                          setState(() {
                            _selectedTable = newValue;
                          });
                          _loadTableData(newValue);
                        }
                      },
                      items:
                          _tableNames.map<DropdownMenuItem<String>>((
                            tableName,
                          ) {
                            return DropdownMenuItem<String>(
                              value: tableName,
                              child: Text(tableName),
                            );
                          }).toList(),
                    ),
                  ),
                  Expanded(
                    child:
                        _tableData.isEmpty
                            ? const Center(child: Text('データがありません'))
                            : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns:
                                      _columnNames
                                          .map(
                                            (name) =>
                                                DataColumn(label: Text(name)),
                                          )
                                          .toList(),
                                  rows:
                                      _tableData.map((row) {
                                        return DataRow(
                                          cells:
                                              _columnNames.map((colName) {
                                                var value = row[colName];
                                                return DataCell(
                                                  Text(
                                                    value?.toString() ?? 'null',
                                                  ),
                                                );
                                              }).toList(),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _loadTableData(_selectedTable!),
                          child: const Text('リロード'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _dbPath));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'データベースパスをクリップボードにコピーしました: $_dbPath',
                                ),
                              ),
                            );
                          },
                          child: const Text('DBパスをコピー'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
