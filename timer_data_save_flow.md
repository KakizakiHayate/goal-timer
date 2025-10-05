# タイマー終了からデータベース保存までのフロー

```mermaid
flowchart TD
    A[タイマー開始] --> B{タイマー実行中}
    
    %% 自動完了フロー
    B --> C{カウントダウンが0秒?}
    C -->|Yes| D[completeTimer呼び出し]
    
    %% 手動完了フロー
    B --> E[ユーザーが学習完了ボタンをタップ]
    E --> F[_showCompleteConfirmDialog表示]
    F --> G{ユーザーが完了選択?}
    G -->|Yes| H[_saveStudyTimeManually呼び出し]
    G -->|No| B
    
    %% 共通のデータ保存処理
    D --> I[_recordStudyTime呼び出し]
    H --> J[DailyStudyLogModel作成]
    I --> J
    
    J --> K[HybridDailyStudyLogsRepository.upsertDailyLog呼び出し]
    
    %% Repository層での処理
    K --> L[1. ローカルDB(SQLite)に保存]
    L --> M{ネットワーク接続あり?}
    
    M -->|Yes| N[2. Supabase(クラウド)に同期保存]
    M -->|No| O[オフライン状態で記録]
    
    N --> P[同期成功?]
    P -->|Yes| Q[isSyncedフラグをtrueに更新]
    P -->|No| R[未同期状態で記録]
    
    O --> S[後で同期するため未同期状態で記録]
    Q --> T[目標の累計時間を更新]
    R --> T
    S --> T
    
    T --> U[goalDetailListProviderを無効化]
    U --> V[保存完了]
    
    %% データベース構造
    V --> W[保存されるデータ]
    W --> X[id: UUID]
    W --> Y[goalId: 目標ID]
    W --> Z[date: 学習日付]
    W --> AA[totalSeconds: 学習時間秒]
    W --> BB[isSynced: 同期状態]
    W --> CC[isTemp/tempUserId: 仮ユーザー情報]
    
    %% スタイル設定
    classDef startEnd fill:#e1f5fe
    classDef process fill:#f3e5f5
    classDef decision fill:#fff3e0
    classDef database fill:#e8f5e8
    classDef error fill:#ffebee
    
    class A,V startEnd
    class D,H,I,J,K,L,N,T,U process
    class C,G,M,P decision
    class W,X,Y,Z,AA,BB,CC database
    class O,R,S error
```

## フロー説明

### 1. タイマー終了の2つのパターン
- **自動完了**: カウントダウンタイマーが0秒になった時に`completeTimer()`が自動実行
- **手動完了**: ユーザーが学習完了ボタン(チェックマーク)をタップして確認ダイアログから完了選択

### 2. データ保存処理
- `_recordStudyTime()` または `_saveStudyTimeManually()`でDailyStudyLogModelを作成
- HybridDailyStudyLogsRepositoryの`upsertDailyLog()`でデータベースに保存

### 3. ハイブリッド保存戦略
1. **ローカル優先**: まずSQLiteローカルDBに確実に保存
2. **クラウド同期**: ネットワークがあればSupabaseにも同期保存
3. **オフライン対応**: ネットワークなしでもローカルに保存し、後で同期

### 4. 保存されるデータ構造
```dart
DailyStudyLogModel(
  id: UUID,                    // 一意ID
  goalId: String,              // 目標ID
  date: DateTime,              // 学習日付
  totalSeconds: int,           // 学習時間(秒)
  isSynced: bool,              // 同期状態
  isTemp: bool,                // 仮ユーザーフラグ
  tempUserId: String?,         // 仮ユーザーID
)
```

### 5. 後処理
- 目標の累計時間(`spentMinutes`)を更新
- `goalDetailListProvider`を無効化してUI更新
- 保存完了



