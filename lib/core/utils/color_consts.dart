import 'package:flutter/material.dart';

final class ColorConsts {
  // === メインカラーパレット ===
  // プライマリーカラー（少し柔らかい青）
  static const primary = Color(0xFF4F91FF);
  static const primaryDark = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFF93C5FD);
  
  // === ニュートラルカラー（グレー系） ===
  // 背景色
  static const backgroundPrimary = Color(0xFFF8F9FA);
  static const backgroundSecondary = Color(0xFFE9ECEF);
  static const cardBackground = Color(0xFFFFFFFF);
  
  // テキストカラー
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF6C757D);
  static const textTertiary = Color(0xFFADB5BD);
  
  // 境界線・区切り線
  static const border = Color(0xFFDEE2E6);
  static const borderLight = Color(0xFFF8F9FA);
  
  // === アクセントカラー ===
  // 成功・ポジティブ
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF6EE7B7);
  
  // 警告・注意
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFCD34D);
  
  // エラー・危険
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFCA5A5);
  
  // === シャドウ・エレベーション ===
  // カードシャドウ用
  static const shadowLight = Color(0x0F000000);
  static const shadowMedium = Color(0x1A000000);
  
  // === インタラクション状態 ===
  // ホバー・フォーカス状態
  static const hoverOverlay = Color(0x0A000000);
  static const pressedOverlay = Color(0x14000000);
  static const focusOverlay = Color(0x1F4F91FF);
  
  // === ダークモード対応（将来用） ===
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB3B3B3);
}
