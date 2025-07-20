final class SpacingConsts {
  // === 基本スペーシング ===
  static const double xxs = 2.0;  // 極極小
  static const double xs = 4.0;   // 極小
  static const double sm = 8.0;   // 小
  static const double md = 16.0;  // 中（基準）
  static const double lg = 24.0;  // 大
  static const double xl = 32.0;  // 特大
  static const double xxl = 48.0; // 超特大
  
  // === 短縮エイリアス（旧V2定数） ===
  // これらは旧v2_constants_adapterで定義されていたもの
  static const double s = sm;    // small
  static const double m = md;    // medium  
  static const double l = lg;    // large
  
  // === レイアウト専用 ===
  static const double sectionSpacing = 32.0;  // セクション間
  static const double cardPadding = 16.0;     // カード内パディング
  static const double screenPadding = 20.0;   // 画面端からの余白
  
  // === ボーダーラディウス ===
  static const double radiusXs = 4.0;   // 小さな角丸
  static const double radiusSm = 8.0;   // 小角丸
  static const double radiusMd = 12.0;  // 標準角丸
  static const double radiusLg = 16.0;  // 大角丸
  static const double radiusXl = 24.0;  // 特大角丸
  static const double radiusRound = 50.0; // 完全な円形
  
  // === エレベーション ===
  static const double elevationNone = 0.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;
  
  // === ボタン・タッチターゲット ===
  static const double minTouchTarget = 44.0;  // 最小タッチエリア
  static const double buttonHeight = 48.0;    // 標準ボタン高さ
  static const double buttonHeightSm = 36.0;  // 小ボタン高さ
  static const double buttonHeightLg = 56.0;  // 大ボタン高さ
}