# FutureProviderキャッシュ無効化による画面間データ不一致修正プラン

## 📋 問題の整理

### 現象
- **ホーム画面**: 4件の目標を表示（同期後の最新データ）
- **タイマータブ**: 5件の目標を表示（同期前の古いキャッシュ）

### 発生条件
1. アプリ起動時、タイマータブを先に表示
2. ホーム画面に遷移すると自動同期が実行される
3. ローカルDBが更新される（5件→4件）
4. タイマータブに戻ると、古いキャッシュ（5件）が表示される

---

## 🔍 根本原因

### 原因1: FutureProviderのキャッシュが無効化されていない

**該当コード**: `lib/features/home/presentation/view_models/home_view_model.dart:138-154`

```dart
void _reloadGoalsAfterSync() async {
  try {
    // 同期後の再読み込みでは同期を避けるため、直接ローカルから取得
    final repository = _ref.read(goalsRepositoryProvider);
    final goals = await repository.getLocalGoalsOnly();

    state = state.copyWith(goals: goals);  // ← HomeViewModelの状態のみ更新
    // ❌ 問題: goalDetailListProviderが無効化されていない

    AppLogger.instance.i('同期後のデータ再読み込みが完了しました: ${goals.length}件');
    _loadGoalStreaks();
  } catch (e) {
    AppLogger.instance.e('同期後のデータ再読み込みに失敗しました', e);
  }
}
```

**問題点**:
- `goalDetailListProvider`（タイマータブで使用）を無効化していない
- ホーム画面は`HomeViewModel`の内部状態（`state.goals`）を使うため正常に更新される
- タイマータブは`FutureProvider`のキャッシュを参照するため古いデータが表示される

### 原因2: 同期処理とFutureProviderのライフサイクルが分離している

```
同期処理（SyncChecker）
  ↓
ローカルDBを更新
  ↓
HomeViewModelに通知（_listenToSyncState）
  ↓
HomeViewModel内部の状態のみ更新
  ↓
❌ FutureProviderには通知されない
```

---

## 🎯 修正方針

### アプローチ: 同期完了時にFutureProviderを無効化する

**基本方針**:
1. 同期完了時に`goalDetailListProvider`を無効化
2. タイマータブが次回表示されたときに、FutureProviderが再実行される
3. 最新のローカルDBデータ（4件）が取得される

### 修正箇所
- `lib/features/home/presentation/view_models/home_view_model.dart`
  - `_reloadGoalsAfterSync()` メソッドに`ref.invalidate()`を追加

---

## 🛠️ 具体的な修正内容

### 修正ファイル: `home_view_model.dart`

**修正前**:
```dart
void _reloadGoalsAfterSync() async {
  try {
    final repository = _ref.read(goalsRepositoryProvider);
    final goals = await repository.getLocalGoalsOnly();

    state = state.copyWith(goals: goals);
    AppLogger.instance.i('同期後のデータ再読み込みが完了しました: ${goals.length}件');

    _loadGoalStreaks();
  } catch (e) {
    AppLogger.instance.e('同期後のデータ再読み込みに失敗しました', e);
  }
}
```

**修正後**:
```dart
void _reloadGoalsAfterSync() async {
  try {
    final repository = _ref.read(goalsRepositoryProvider);
    final goals = await repository.getLocalGoalsOnly();

    state = state.copyWith(goals: goals);
    AppLogger.instance.i('同期後のデータ再読み込みが完了しました: ${goals.length}件');

    // ✅ 追加: タイマータブで使用されるFutureProviderを無効化
    _ref.invalidate(goalDetailListProvider);
    AppLogger.instance.i('goalDetailListProviderを無効化しました（タイマータブのキャッシュをクリア）');

    _loadGoalStreaks();
  } catch (e) {
    AppLogger.instance.e('同期後のデータ再読み込みに失敗しました', e);
  }
}
```

### 必要なimport追加

```dart
import '../../../goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
```

**既存のimportを確認**: `home_view_model.dart:1-10`
- すでに存在する場合は追加不要

---

## 📊 修正後のデータフロー

### 修正前（現状）

```
ホーム画面で同期完了
  ↓
ローカルDB: 5件 → 4件に更新
  ↓
HomeViewModel.state.goals: 4件に更新 ✅
  ↓
❌ goalDetailListProviderはキャッシュ（5件）を保持したまま
  ↓
タイマータブに戻る
  ↓
❌ 古いキャッシュ（5件）を表示
```

### 修正後（期待される動作）

```
ホーム画面で同期完了
  ↓
ローカルDB: 5件 → 4件に更新
  ↓
HomeViewModel.state.goals: 4件に更新 ✅
  ↓
✅ ref.invalidate(goalDetailListProvider) 実行
  ↓
FutureProviderのキャッシュがクリアされる
  ↓
タイマータブに戻る
  ↓
FutureProviderが再実行される
  ↓
ローカルDBから最新データ（4件）を取得
  ↓
✅ 正しく4件を表示
```

---

## ⚠️ 影響範囲

### 影響を受けるファイル
1. **修正**: `lib/features/home/presentation/view_models/home_view_model.dart`
   - `_reloadGoalsAfterSync()` メソッド

### 影響を受ける画面
1. **タイマータブ** (`home_screen.dart` の `_TimerPage`)
   - 同期後に最新データが表示されるようになる（改善）

2. **ホーム画面**
   - 変更なし（既に正常動作）

### 影響を受けるProvider
1. **goalDetailListProvider**
   - 同期完了時に無効化される
   - 次回参照時に再実行される

---

## ✅ テスト項目

### 必須テスト

#### テスト1: 基本的な同期動作
1. アプリを起動
2. タイマータブを開く → 件数を確認（例: 5件）
3. ホーム画面に遷移 → 同期が実行される
4. ホーム画面の表示件数を確認（例: 4件）
5. タイマータブに戻る
6. **期待結果**: タイマータブも4件を表示

#### テスト2: 複数回の画面遷移
1. ホーム画面 → タイマータブ → ホーム画面 → タイマータブ
2. 各画面で表示件数が一致していることを確認
3. **期待結果**: すべての画面で同じ件数を表示

#### テスト3: 目標の追加・削除
1. ホーム画面で目標を追加
2. タイマータブに遷移
3. **期待結果**: 追加した目標がタイマータブにも表示される
4. ホーム画面で目標を削除
5. タイマータブに遷移
6. **期待結果**: 削除した目標がタイマータブからも消える

#### テスト4: オフライン→オンライン
1. 機内モードON（オフライン）
2. ホーム画面でローカルデータを確認
3. タイマータブでローカルデータを確認
4. 機内モードOFF（オンライン）
5. ホーム画面に戻る → 同期が実行される
6. タイマータブに遷移
7. **期待結果**: 同期後のデータが正しく表示される

### 任意テスト（可能であれば実施）

#### テスト5: アプリ再起動
1. アプリを再起動
2. タイマータブを開く
3. **期待結果**: 最新のローカルDBデータが表示される

#### テスト6: 統計画面・設定画面からの遷移
1. 統計画面 → タイマータブ
2. 設定画面 → タイマータブ
3. **期待結果**: どの画面から遷移しても正しいデータが表示される

---

## 📝 実装時の注意点

### 1. importの確認
- `goalDetailListProvider`をimportする必要がある
- 循環参照に注意（現状問題なし）

### 2. ログ出力
- 無効化処理の前後でログを出力し、動作を確認できるようにする

```dart
AppLogger.instance.i('goalDetailListProviderを無効化しました（タイマータブのキャッシュをクリア）');
```

### 3. 他の画面での影響
- `goalDetailListProvider`を使用している他の画面がないか確認
- 現状は以下の2箇所のみ：
  - ホーム画面の`_TimerPage`
  - （他に使用箇所があれば追加確認）

### 4. パフォーマンスへの影響
- `ref.invalidate()`は軽量な操作
- 次回参照時にのみ再実行されるため、無駄な処理は発生しない

---

## 🔄 代替案（検討したが不採用）

### 代替案1: StateNotifierProviderを使う
- **メリット**: 状態管理が一元化される
- **デメリット**: 大規模なリファクタリングが必要
- **判断**: 現状の修正で十分に対応可能

### 代替案2: ProviderObserverで監視
- **メリット**: 自動的に無効化できる
- **デメリット**: 複雑性が増す、過剰な設計
- **判断**: シンプルな修正で十分

### 代替案3: StreamProviderを使う
- **メリット**: リアルタイム更新が可能
- **デメリット**: オーバーエンジニアリング
- **判断**: FutureProviderで十分

---

## 📅 実装スケジュール

1. **修正**: 5分
   - `home_view_model.dart`に1行追加

2. **動作確認**: 10分
   - 上記のテスト項目を実施

3. **コミット・PR**: 5分
   - 修正をコミットしてPR作成

**合計所要時間**: 約20分

---

## ✅ 完了条件

- [ ] `home_view_model.dart`の修正完了
- [ ] 必須テスト4項目をすべてパス
- [ ] ログ出力で無効化が確認できる
- [ ] ホーム画面とタイマータブで同じ件数が表示される
- [ ] コミット・PR作成完了

---

## 📚 参考情報

### Riverpod公式ドキュメント
- [Invalidating a provider](https://riverpod.dev/docs/concepts/reading#invalidating-a-provider)
- [FutureProvider](https://riverpod.dev/docs/providers/future_provider)

### 関連ファイル
- `lib/features/home/presentation/view_models/home_view_model.dart`
- `lib/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/core/services/sync_checker.dart`
