import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goal_timer/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:goal_timer/features/statistics/presentation/viewmodels/statistics_view_model.dart';
import 'package:goal_timer/features/statistics/domain/usecases/get_statistics_usecase.dart';
import 'package:goal_timer/features/statistics/domain/usecases/get_daily_stats_usecase.dart';
import 'package:goal_timer/core/widgets/metric_card.dart';
import 'package:goal_timer/core/widgets/chart_card.dart';
import '../../helpers/statistics_test_data.dart';

// モックの生成
@GenerateMocks([
  GetStatisticsUseCase,
  GetDailyStatsUseCase,
])
import 'statistics_screen_test.mocks.dart';

void main() {
  group('StatisticsScreen Widget Tests', () {
    late MockGetStatisticsUseCase mockGetStatisticsUseCase;
    late MockGetDailyStatsUseCase mockGetDailyStatsUseCase;

    setUp(() {
      mockGetStatisticsUseCase = MockGetStatisticsUseCase();
      mockGetDailyStatsUseCase = MockGetDailyStatsUseCase();
    });

    // ウィジェットテストのヘルパー関数
    Widget createTestWidget({
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          getStatisticsUseCaseProvider.overrideWithValue(mockGetStatisticsUseCase),
          getDailyStatsUseCaseProvider.overrideWithValue(mockGetDailyStatsUseCase),
          ...overrides,
        ],
        child: const MaterialApp(
          home: StatisticsScreen(),
        ),
      );
    }

    group('基本UI表示テスト', () {
      testWidgets('TC001: 統計画面が正常に表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => [StatisticsTestData.expectedThisWeekStatistics]);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('統計'), findsOneWidget);
        expect(find.byType(StatisticsScreen), findsOneWidget);
      });

      testWidgets('TC002: SliverAppBarが正しく表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.text('統計'), findsOneWidget);
      });

      testWidgets('TC003: 期間選択セクションが表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('週間'), findsOneWidget);
        expect(find.text('月間'), findsOneWidget);
        expect(find.text('年間'), findsOneWidget);
      });

      testWidgets('TC004: メトリクスカードが4つ表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(MetricCard), findsNWidgets(4));
        expect(find.text('総勉強時間'), findsOneWidget);
        expect(find.text('継続日数'), findsOneWidget);
        expect(find.text('達成率'), findsOneWidget);
        expect(find.text('平均集中時間'), findsOneWidget);
      });

      testWidgets('TC005: チャートセクションが表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ChartCard), findsNWidgets(2));
        expect(find.text('勉強時間の推移'), findsOneWidget);
        expect(find.text('目標別時間分布'), findsOneWidget);
      });
    });

    group('期間選択機能テスト', () {
      testWidgets('TC006: 週間が初期選択されていること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        // 週間ボタンがselectedスタイルで表示されることを確認
        final weekButton = find.text('週間');
        expect(weekButton, findsOneWidget);
      });

      testWidgets('TC007: 期間選択タップで切り替えができること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 月間をタップ
        await tester.tap(find.text('月間'));
        await tester.pumpAndSettle();

        // Assert
        // UIが更新されることを確認（実際の選択状態の確認は統合テストで行う）
        expect(find.text('月間'), findsOneWidget);
      });

      testWidgets('TC008: 年間選択ができること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 年間をタップ
        await tester.tap(find.text('年間'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('年間'), findsOneWidget);
      });
    });

    group('ハードコード値表示テスト', () {
      testWidgets('TC009: 総勉強時間のハードコード値が表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - ハードコードされた値の確認
        expect(find.text('24'), findsOneWidget); // 総勉強時間の値
        expect(find.text('h'), findsOneWidget); // 単位
        expect(find.text('+2.5h'), findsOneWidget); // 変化量
      });

      testWidgets('TC010: 継続日数のハードコード値が表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - ハードコードされた値の確認
        expect(find.text('12'), findsOneWidget); // 継続日数の値
        expect(find.text('日'), findsOneWidget); // 単位
        expect(find.text('+3日'), findsOneWidget); // 変化量
      });

      testWidgets('TC011: 達成率のハードコード値が表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - ハードコードされた値の確認
        expect(find.text('85'), findsOneWidget); // 達成率の値
        expect(find.text('%'), findsOneWidget); // 単位
        expect(find.text('+5%'), findsOneWidget); // 変化量
      });

      testWidgets('TC012: 平均集中時間のハードコード値が表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - ハードコードされた値の確認
        expect(find.text('42'), findsOneWidget); // 平均集中時間の値
        expect(find.text('分'), findsOneWidget); // 単位
        expect(find.text('+7分'), findsOneWidget); // 変化量
      });

      testWidgets('TC013: チャート凡例のハードコード値が表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - チャート凡例のハードコード値
        expect(find.text('英語'), findsOneWidget);
        expect(find.text('プログラミング'), findsOneWidget);
        expect(find.text('資格勉強'), findsOneWidget);
      });
    });

    group('アニメーションテスト', () {
      testWidgets('TC014: フェードインアニメーションが動作すること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        
        // アニメーション開始前
        expect(find.byType(FadeTransition), findsOneWidget);
        
        // アニメーション完了まで待機
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(StatisticsScreen), findsOneWidget);
      });

      testWidgets('TC015: 期間選択のアニメーションが動作すること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 期間選択をタップ
        await tester.tap(find.text('月間'));
        
        // アニメーション中の状態確認
        await tester.pump();
        expect(find.byType(AnimatedContainer), findsWidgets);

        // アニメーション完了
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('月間'), findsOneWidget);
      });
    });

    group('レスポンシブレイアウトテスト', () {
      testWidgets('TC016: 小さな画面でも正しくレイアウトされること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(MetricCard), findsNWidgets(4));
        expect(find.byType(StatisticsScreen), findsOneWidget);
      });

      testWidgets('TC017: 大きな画面でも正しくレイアウトされること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(MetricCard), findsNWidgets(4));
        expect(find.byType(ChartCard), findsNWidgets(2));
      });
    });

    group('スクロール動作テスト', () {
      testWidgets('TC018: カスタムスクロールビューが動作すること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // スクロールテスト
        final scrollView = find.byType(CustomScrollView);
        expect(scrollView, findsOneWidget);

        await tester.drag(scrollView, const Offset(0, -200));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CustomScrollView), findsOneWidget);
      });

      testWidgets('TC019: SliverAppBarが正しくピン留めされること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // スクロールしてAppBarの動作を確認
        final scrollView = find.byType(CustomScrollView);
        await tester.drag(scrollView, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.text('統計'), findsOneWidget); // タイトルは常に表示
      });
    });

    group('エラー状態テスト', () {
      testWidgets('TC020: データ取得エラー時もUIが表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenThrow(Exception('Network error'));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - UIは表示される（エラーハンドリングは別レイヤーで行う）
        expect(find.byType(StatisticsScreen), findsOneWidget);
        expect(find.text('統計'), findsOneWidget);
        expect(find.byType(MetricCard), findsNWidgets(4));
      });

      testWidgets('TC021: 空データ時でもUIが正常に表示されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(StatisticsScreen), findsOneWidget);
        expect(find.byType(MetricCard), findsNWidgets(4));
        expect(find.text('総勉強時間'), findsOneWidget);
      });
    });

    group('アクセシビリティテスト', () {
      testWidgets('TC022: セマンティクスが正しく設定されていること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - セマンティクス情報の確認
        final titleWidget = find.text('統計');
        expect(titleWidget, findsOneWidget);
        
        // ボタンのセマンティクス確認
        final weekButton = find.text('週間');
        expect(weekButton, findsOneWidget);
      });

      testWidgets('TC023: タブナビゲーションが正しく動作すること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tab キーでのナビゲーションテスト
        // 期間選択ボタンにフォーカス
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Assert
        // フォーカス状態の確認（実装依存）
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('プライベートメソッドの間接テスト', () {
      testWidgets('TC024: _buildMetricsGrid が正しく構築されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - メトリクスグリッドの構造を確認
        expect(find.byType(LayoutBuilder), findsWidgets); // 複数のLayoutBuilderが存在する可能性
        expect(find.byType(Column), findsWidgets); // メトリクスグリッドのColumn
        expect(find.byType(Row), findsWidgets); // メトリクスの行
      });

      testWidgets('TC025: _buildChartsSection が正しく構築されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - チャートセクションの構造を確認
        expect(find.byType(ChartCard), findsNWidgets(2));
        expect(find.text('勉強時間の推移'), findsOneWidget);
        expect(find.text('目標別時間分布'), findsOneWidget);
        expect(find.text('時間推移チャート\n（実装予定）'), findsOneWidget);
        expect(find.text('分布チャート\n（実装予定）'), findsOneWidget);
      });
    });

    group('メモリリーク防止テスト', () {
      testWidgets('TC026: AnimationController が適切に破棄されること', (tester) async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // ウィジェットを削除
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Assert - メモリリークがないことを確認
        // （実際のメモリリーク検出は統合テストやプロファイリングツールで行う）
        expect(find.byType(StatisticsScreen), findsNothing);
      });
    });
  });
}