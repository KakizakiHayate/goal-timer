# チュートリアル管理移行実装プラン

## 概要

現在のSharedPreferencesベースのチュートリアル管理を、usersテーブルのローカル専用カラムで管理する実装プラン。

## 目的

- チュートリアル状態の一元管理
- データベースベースでの堅牢な状態管理
- SharedPreferencesとの重複管理解消
- ユーザー単位でのチュートリアル状態追跡

## 現状分析

### 現在の実装
```dart
// SharedPreferencesでの管理
final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
final currentStepId = prefs.getString('tutorial_current_step') ?? '';
final currentStepIndex = prefs.getInt('tutorial_current_step_index') ?? 0;
final totalSteps = prefs.getInt('tutorial_total_steps') ?? 3;
```

### 問題点
- SharedPreferencesでの散在した状態管理
- 複数のキーでの管理による複雑性
- ユーザー単位での管理ができていない
- アプリアンインストール時にデータが失われる

## 実装方針

### 設計原則
- **ローカル専用**: Supabaseには同期しない
- **シンプル**: 完了/未完了の判定のみ
- **ユーザー単位**: usersテーブルで管理
- **後方互換性**: 既存のSharedPreferences管理と併存

### データ構造

#### ローカルDB（SQLite）
```sql
-- 既存のusersテーブルに追加
ALTER TABLE users ADD COLUMN is_tutorial_completed INTEGER DEFAULT 0;
```

#### Supabaseスキーマ
```sql
-- 変更なし（チュートリアル関連カラムは追加しない）
```

## 実装手順

### Phase 1: データベースマイグレーション

#### 1.1 app_database.dart の更新
```dart
// バージョンを6から7に更新
return await openDatabase(
  path,
  version: 7,  // ← 更新
  onCreate: _createDB,
  onUpgrade: _upgradeDB,
);
```

#### 1.2 マイグレーション処理追加
```dart
if (oldVersion < 7) {
  // チュートリアル管理カラムを追加
  AppLogger.instance.i('チュートリアル完了フラグを追加します...');
  
  await db.execute(
    'ALTER TABLE users ADD COLUMN is_tutorial_completed INTEGER DEFAULT 0'
  );
  
  AppLogger.instance.i('バージョン7へのマイグレーションが完了しました');
}
```

#### 1.3 CREATE TABLE文の更新
```dart
// _createDB メソッドで新規作成時のスキーマ更新
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT,
  display_name TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login TEXT,
  is_synced INTEGER DEFAULT 0,
  is_tutorial_completed INTEGER DEFAULT 0  -- 新規追加
)
```

### Phase 2: UserModel の更新

#### 2.1 モデル定義更新
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    String? email,
    String? displayName,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? syncUpdatedAt,
    DateTime? lastLogin,
    @Default(false) bool isSynced,
    
    // 新規追加: ローカル専用フィールド
    @Default(false) bool isTutorialCompleted,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

#### 2.2 Extension メソッド追加
```dart
extension UserModelExtension on UserModel {
  // ローカルDB用（全フィールド含む）
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_updated_at': syncUpdatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_tutorial_completed': isTutorialCompleted ? 1 : 0,  // 新規
    };
  }

  // Supabase用（ローカル専用フィールドを除外）
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_updated_at': syncUpdatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      // is_tutorial_completed は除外
    };
  }

  // ローカルDBからの読み込み
  factory UserModel.fromLocalMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      displayName: map['display_name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncUpdatedAt: map['sync_updated_at'] != null 
          ? DateTime.parse(map['sync_updated_at']) 
          : null,
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login']) 
          : null,
      isSynced: map['is_synced'] == 1,
      isTutorialCompleted: map['is_tutorial_completed'] == 1,  // 新規
    );
  }
}
```

### Phase 3: Repository層の更新

#### 3.1 LocalUserDatasource の更新
```dart
class LocalUserDatasource {
  
  /// チュートリアル完了状態を更新
  Future<void> updateTutorialStatus(String userId, bool isCompleted) async {
    try {
      final db = await _database.database;
      await db.update(
        'users',
        {
          'is_tutorial_completed': isCompleted ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      AppLogger.instance.e('チュートリアル状態更新エラー: $e');
      rethrow;
    }
  }

  /// ユーザーのチュートリアル完了状態を取得
  Future<bool> getTutorialStatus(String userId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'users',
        columns: ['is_tutorial_completed'],
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (result.isEmpty) return false;
      return result.first['is_tutorial_completed'] == 1;
    } catch (e) {
      AppLogger.instance.e('チュートリアル状態取得エラー: $e');
      return false;
    }
  }
}
```

#### 3.2 SupabaseUserDatasource の更新
```dart
class SupabaseUserDatasource {
  
  Future<UserModel> updateUser(UserModel user) async {
    try {
      // Supabase用マップ（is_tutorial_completed除外）
      final supabaseData = user.toSupabaseMap();
      
      await _client.from('users').update(supabaseData).eq('id', user.id);
      return user;
    } catch (e) {
      AppLogger.instance.e('Supabaseユーザー更新エラー: $e');
      rethrow;
    }
  }
}
```

### Phase 4: TutorialViewModel の更新

#### 4.1 依存関係追加
```dart
class TutorialViewModel extends StateNotifier<TutorialState> {
  final TempUserService _tempUserService;
  final UserRepository _userRepository;  // 新規追加

  TutorialViewModel(
    this._tempUserService,
    this._userRepository,  // 新規追加
  ) : super(const TutorialState()) {
    _loadTutorialState();
  }
}
```

#### 4.2 チュートリアル状態管理更新
```dart
/// チュートリアル完了状態をチェック
Future<bool> hasCompletedTutorial() async {
  final currentUserId = await _getCurrentUserId();
  if (currentUserId == null) return false;
  
  try {
    return await _userRepository.getTutorialStatus(currentUserId);
  } catch (e) {
    AppLogger.instance.e('チュートリアル状態取得エラー: $e');
    // フォールバック: SharedPreferencesをチェック
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_active') ?? false);
  }
}

/// チュートリアルを完了
Future<void> completeTutorial() async {
  print('🏆 completeTutorial called');

  // 1. データベースでのチュートリアル完了状態更新
  final currentUserId = await _getCurrentUserId();
  if (currentUserId != null) {
    try {
      await _userRepository.updateTutorialStatus(currentUserId, true);
      print('✅ データベースでチュートリアル完了状態を更新しました');
    } catch (e) {
      print('❌ データベース更新に失敗: $e');
    }
  }

  // 2. SharedPreferencesのクリア（後方互換性のため）
  await _clearTutorialFlag();
  
  // 3. 状態更新
  state = state.copyWith(
    isTutorialActive: false,
    isCompleted: true,
  );
  print('✅ チュートリアル完了処理が完了しました');
}

/// 現在のユーザーIDを取得
Future<String?> _getCurrentUserId() async {
  // 認証済みユーザーの場合
  final authUser = await _authService.getCurrentUser();
  if (authUser != null) {
    return authUser.id;
  }
  
  // ゲストユーザーの場合
  final tempUserId = await _tempUserService.getTempUserId();
  return tempUserId;
}
```

#### 4.3 初期化処理の更新
```dart
/// SharedPreferencesとデータベースから状態を復元
Future<void> _loadTutorialState() async {
  try {
    // 1. データベースからチュートリアル完了状態をチェック
    final isCompletedInDB = await hasCompletedTutorial();
    if (isCompletedInDB) {
      print('📋 データベース: チュートリアル完了済み');
      state = state.copyWith(
        isTutorialActive: false,
        isCompleted: true,
      );
      return;
    }

    // 2. フォールバック: SharedPreferencesをチェック
    final prefs = await SharedPreferences.getInstance();
    final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
    
    if (isTutorialActive) {
      // 進行中のチュートリアル状態を復元
      final tempUserId = await _tempUserService.getTempUserId();
      final currentStepId = prefs.getString('tutorial_current_step') ?? 'home_goal_selection';
      final currentStepIndex = prefs.getInt('tutorial_current_step_index') ?? 0;
      final totalSteps = prefs.getInt('tutorial_total_steps') ?? 3;
      
      state = state.copyWith(
        isTutorialActive: true,
        tempUserId: tempUserId,
        currentStepId: currentStepId,
        currentStepIndex: currentStepIndex,
        totalSteps: totalSteps,
        isCompleted: false,
      );
    }
  } catch (e) {
    print('❌ チュートリアル状態の復元に失敗: $e');
  }
}
```

### Phase 5: Provider の更新

#### 5.1 TutorialViewModel Provider更新
```dart
final tutorialViewModelProvider =
    StateNotifierProvider<TutorialViewModel, TutorialState>((ref) {
  final tempUserService = ref.watch(tempUserServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);  // 新規追加
  return TutorialViewModel(tempUserService, userRepository);
});
```

## 後方互換性

### 移行期間中の対応
```dart
/// チュートリアル状態のダブルチェック
Future<bool> hasCompletedTutorial() async {
  // 1. データベースをチェック
  final dbResult = await _checkDatabaseTutorialStatus();
  if (dbResult != null) return dbResult;
  
  // 2. フォールバック: SharedPreferencesをチェック
  final prefs = await SharedPreferences.getInstance();
  final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
  return !isTutorialActive; // activeでない = 完了済み
}
```

### データマイグレーション
```dart
/// 既存のSharedPreferencesデータをデータベースに移行
Future<void> _migrateExistingTutorialData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasLegacyData = prefs.containsKey('tutorial_active');
    
    if (hasLegacyData) {
      final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
      final isCompleted = !isTutorialActive;
      
      final currentUserId = await _getCurrentUserId();
      if (currentUserId != null && isCompleted) {
        await _userRepository.updateTutorialStatus(currentUserId, true);
        print('✅ 既存データをデータベースに移行しました');
      }
    }
  } catch (e) {
    print('❌ データ移行に失敗: $e');
  }
}
```

## テスト計画

### Unit Tests
- [ ] UserModel のシリアライゼーション/デシリアライゼーション
- [ ] LocalUserDatasource のチュートリアル状態管理
- [ ] TutorialViewModel の新しいロジック
- [ ] データベースマイグレーション

### Integration Tests
- [ ] チュートリアル完了フローの統合テスト
- [ ] ゲストユーザーでのチュートリアル管理
- [ ] 認証済みユーザーでのチュートリアル管理
- [ ] データ移行プロセスのテスト

### E2E Tests
- [ ] 新規ユーザーのチュートリアルフロー
- [ ] 既存ユーザーのアップグレード体験
- [ ] アプリ再起動後の状態復元

## リスク管理

### 想定されるリスク
1. **データベースマイグレーション失敗**
   - 対策: try-catchでの例外処理とフォールバック
2. **既存ユーザーのデータ損失**
   - 対策: SharedPreferences併用での後方互換性
3. **パフォーマンス劣化**
   - 対策: インデックス追加とクエリ最適化

### 緊急時対応
```dart
// フォールバック機能
Future<bool> _emergencyTutorialCheck() async {
  try {
    return await _checkDatabaseTutorialStatus();
  } catch (e) {
    // データベースアクセス失敗時はSharedPreferencesを使用
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_active') ?? false);
  }
}
```

## 実装スケジュール

### Week 1: データベース層
- [ ] app_database.dart マイグレーション実装
- [ ] UserModel 更新
- [ ] Unit Tests

### Week 2: Repository/Datasource層
- [ ] LocalUserDatasource 更新
- [ ] SupabaseUserDatasource 更新
- [ ] Integration Tests

### Week 3: ViewModel層
- [ ] TutorialViewModel 更新
- [ ] Provider 更新
- [ ] E2E Tests

### Week 4: テスト・デバッグ
- [ ] 総合テスト
- [ ] パフォーマンステスト
- [ ] バグ修正

## 完了基準

- [ ] すべてのユニットテストが通過
- [ ] 統合テストが通過
- [ ] E2Eテストが通過
- [ ] 既存機能に影響がない
- [ ] パフォーマンス劣化がない
- [ ] コードレビューが完了

## 参考資料

- [SQLite ALTER TABLE Documentation](https://www.sqlite.org/lang_altertable.html)
- [Freezed Documentation](https://pub.dev/packages/freezed)
- [Riverpod State Management](https://riverpod.dev/)






