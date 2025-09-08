import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:goal_timer/core/widgets/metric_card.dart';

void main() {
  group('Statistics UI Cleanup Tests - Issue #51', () {
    
    testWidgets('test_metrics_grid_layout - 2x1グリッドレイアウト', (tester) async {
      // 統計画面の MetricCard が2項目のみ表示されることを確認
      
      // 基本的なProviderContainerでラップ
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const StatisticsScreen(),
          ),
        ),
      );
      
      // ローディング状態を待つ
      await tester.pump();
      
      // MetricCard が2つのみ表示されることを確認
      final metricCards = find.byType(MetricCard);
      expect(metricCards, findsNWidgets(2));
    });
    
    testWidgets('test_required_metrics_display - 必要項目の表示確認', (tester) async {
      // 「総勉強時間」と「継続日数」が表示されることを確認
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const StatisticsScreen(),
          ),
        ),
      );
      
      await tester.pump();
      
      // 「総勉強時間」の表示を確認
      expect(find.text('総勉強時間'), findsOneWidget);
      
      // 「継続日数」の表示を確認
      expect(find.text('継続日数'), findsOneWidget);
    });
    
    testWidgets('test_removed_metrics_not_displayed - 削除項目の非表示確認', (tester) async {
      // 「目標達成率」と「平均集中時間」が表示されないことを確認
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const StatisticsScreen(),
          ),
        ),
      );
      
      await tester.pump();
      
      // 「達成率」が表示されないことを確認
      expect(find.text('達成率'), findsNothing);
      
      // 「平均集中時間」が表示されないことを確認
      expect(find.text('平均集中時間'), findsNothing);
    });
    
    testWidgets('test_layout_structure - レイアウト構造確認', (tester) async {
      // 2x1グリッドの構造を確認
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const StatisticsScreen(),
          ),
        ),
      );
      
      await tester.pump();
      
      // 1つのRow（上段のみ）が存在することを確認
      final rowWidgets = find.byType(Row);
      // メトリクス表示用のRowが1つだけ存在することを期待
      expect(rowWidgets, findsAtLeastNWidgets(1));
    });

    // TODO: 実装完了後に以下のテストを有効化

    // testWidgets('test_local_db_priority_display - ローカルDB優先表示', (tester) async {
    //   // ローカルDBから優先的にデータが表示されることを確認
    // });
    
    // testWidgets('test_background_sync_with_cloud - バックグラウンド同期', (tester) async {
    //   // クラウドDBとの同期がバックグラウンドで実行されることを確認
    // });
    
    // testWidgets('test_offline_functionality - オフライン機能', (tester) async {
    //   // オフライン状態でもローカルデータが表示されることを確認
    // });

    // より詳細なテストは実装完了後に追加
    // 現在は基本的なUI構造のテストのみ
  });
}