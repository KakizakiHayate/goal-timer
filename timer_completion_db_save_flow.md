# タイマー学習完了後のDB保存処理フロー

```mermaid
flowchart TD
    A[ユーザーがタイマー開始] --> B{タイマー実行中}
    
    %% 自動完了フロー
    B --> C{カウントダウンが0秒になった?}
    C -->|Yes| D[TimerViewModel.completeTimer実行]
    
    %% 手動完了フロー  
    B --> E[ユーザーが学習完了ボタン(✓)をタップ]
    E --> F[_showCompleteConfirmDialog表示]
    F --> G{ユーザーが完了選択?}
    G -->|Yes| H[確認ダイアログ内で処理開始]
    G -->|No| B
    
    %% 共通フロー：学習時間記録開始
    D --> I[_recordStudyTime実行<br/>チュートリアルモードチェック]
    H --> J[_saveStudyTimeManually実行<br/>手動保存処理]
    
    I --> K{チュートリアルモード?}
    K -->|Yes| L[データ保存をスキップ<br/>ログ出力のみ]
    K -->|No| M[DailyStudyLogModel作成]
    J --> M
    
    %% データモデル作成
    M --> N[データ構造設定<br/>- id: UUID.v4<br/>- goalId: state.goalId<br/>- date: 今日の日付正規化<br/>- totalSeconds: 学習時間秒<br/>- createdAt: 現在時刻<br/>- isSynced: false初期値]
    
    %% Repository層での保存処理
    N --> O[HybridDailyStudyLogsRepository<br/>.upsertDailyLog呼び出し]
    
    %% 1. ローカルDB保存
    O --> P[LocalDailyStudyLogsDatasource<br/>SQLiteローカルDBに保存]
    P --> Q{ローカル保存成功?}
    Q -->|No| R[エラーログ出力<br/>例外をthrow]
    Q -->|Yes| S[ネットワーク接続状態確認<br/>Connectivity.checkConnectivity]
    
    %% 2. ネットワーク状態判定
    S --> T{ネットワーク接続あり?}
    T -->|No| U[SyncStateNotifier.setOffline<br/>オフライン状態設定]
    T -->|Yes| V[Supabaseクラウド同期処理開始]
    
    %% 3. クラウド同期処理
    V --> W[SupabaseDailyStudyLogsDatasource<br/>.upsertDailyLog実行]
    W --> X{Supabase保存成功?}
    X -->|Yes| Y[ローカルDBの同期フラグ更新<br/>isSynced: true<br/>markAsSynced実行]
    X -->|No| Z[同期失敗をログ出力<br/>SyncStateNotifier.setUnsynced<br/>ローカルデータは保持]
    
    %% 4. 目標累計時間更新
    Y --> AA[目標の累計時間更新処理]
    Z --> AA
    U --> AA
    
    AA --> BB[HybridGoalsRepository<br/>.getGoalById実行]
    BB --> CC{目標データ取得成功?}
    CC -->|Yes| DD[現在の目標データから<br/>spentMinutes += 学習分数<br/>copyWith更新]
    CC -->|No| EE[警告ログ出力<br/>累計時間更新スキップ]
    
    DD --> FF[HybridGoalsRepository<br/>.updateGoal実行]
    FF --> GG{目標更新成功?}
    GG -->|Yes| HH[累計時間更新完了]
    GG -->|No| II[警告ログ出力<br/>記録は保存済みのため継続]
    
    %% 5. UI更新処理
    HH --> JJ[ref.invalidate<br/>goalDetailListProvider<br/>キャッシュクリア]
    II --> JJ
    EE --> JJ
    
    %% 6. 完了処理
    JJ --> KK[タイマー状態更新<br/>TimerViewModel.completeTimer<br/>status: completed]
    KK --> LL[成功ログ出力<br/>学習時間記録完了]
    
    %% エラーハンドリング
    R --> MM[エラーフィードバック<br/>SnackBar表示]
    L --> NN[チュートリアル完了<br/>記録スキップ完了]
    
    %% 画面フィードバック（手動完了の場合）
    LL --> OO{手動完了フロー?}
    OO -->|Yes| PP[タイマーリセット実行<br/>Navigator.pop<br/>成功SnackBar表示]
    OO -->|No| QQ[自動完了処理終了]
    
    %% スタイル設定
    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef process fill:#f3e5f5,stroke:#4a148c,stroke-width:2px  
    classDef decision fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef database fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef error fill:#ffebee,stroke:#b71c1c,stroke-width:2px
    classDef success fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    
    class A,B start
    class D,H,I,J,M,N,O,P,V,W,AA,BB,DD,FF,JJ,KK process
    class C,G,K,Q,T,X,CC,GG,OO decision  
    class P,W,BB,FF database
    class R,MM error
    class LL,PP,QQ,NN success
```

## フロー説明

### 1. 学習完了の2つのトリガー
- **自動完了**: カウントダウンタイマーが0秒に到達時に`completeTimer()`自動実行
- **手動完了**: ユーザーが学習完了ボタン(✓)をタップ後、確認ダイアログで完了選択

### 2. データ保存処理の詳細
#### 2.1 学習記録モデル作成
```dart
DailyStudyLogModel(
  id: Uuid().v4(),                    // 自動生成UUID
  goalId: timerState.goalId,          // 現在の目標ID
  date: DateTime(today.year, today.month, today.day), // 日付正規化
  totalSeconds: studyTimeInSeconds,   // 学習時間（秒）
  createdAt: DateTime.now(),          // 作成日時
  isSynced: false,                    // 初期状態は未同期
)
```

#### 2.2 ハイブリッド保存戦略
1. **ローカル優先**: SQLiteローカルDBに確実に保存
2. **クラウド同期**: ネットワークがあればSupabaseにリアルタイム同期
3. **オフライン対応**: ネットワークなしでもローカル保存、後で手動同期

### 3. データフロー詳細
1. `LocalDailyStudyLogsDatasource` → SQLite保存
2. `Connectivity` → ネットワーク状態確認  
3. `SupabaseDailyStudyLogsDatasource` → クラウド同期
4. `HybridGoalsRepository` → 目標の累計時間更新
5. `goalDetailListProvider` → UIキャッシュ更新

### 4. エラーハンドリング
- ローカル保存失敗 → 例外throw、エラーフィードバック
- クラウド同期失敗 → ローカルデータ保持、未同期状態設定
- 目標更新失敗 → 警告ログ、学習記録は保持

### 5. チュートリアル対応
- `isTutorialMode=true`の場合はデータ保存をスキップ
- ログ出力のみ行い、実際のDB操作は実行しない

### 6. UI更新とフィードバック
- 手動完了：タイマーリセット→画面ポップ→成功メッセージ
- 自動完了：バックグラウンド処理のみ
- プロバイダーキャッシュクリアでリアルタイム反映




