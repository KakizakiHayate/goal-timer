import 'package:flutter/material.dart';
import 'color_consts.dart';

final class TextConsts {
  // === ヘッダー系 ===
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.25,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: ColorConsts.textPrimary,
  );
  
  // === 本文系 ===
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ColorConsts.textSecondary,
  );
  
  // === ラベル・キャプション系 ===
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.25,
    color: ColorConsts.textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.29,
    color: ColorConsts.textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: ColorConsts.textTertiary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: ColorConsts.textTertiary,
  );
  
  // === ボタン系 ===
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Colors.white,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: Colors.white,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.29,
    color: Colors.white,
  );
  
  // === 特殊・強調系 ===
  static const TextStyle emphasis = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ColorConsts.primary,
  );
  
  static const TextStyle timer = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300, // Light
    height: 1.1,
    color: ColorConsts.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()], // 等幅数字
  );
  
  static const TextStyle number = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: ColorConsts.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  // === エイリアス（旧V2定数） ===
  // これらは旧v2_constants_adapterで定義されていたもの
  static const TextStyle body = bodyMedium;
}
