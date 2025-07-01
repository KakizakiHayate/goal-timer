import 'package:flutter/material.dart';

/// アニメーション関連の定数定義
final class AnimationConsts {
  // === 基本的なDuration ===
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
  
  // === 具体的な用途別Duration ===
  static const Duration buttonTap = Duration(milliseconds: 150);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration modalTransition = Duration(milliseconds: 250);
  static const Duration fadeTransition = Duration(milliseconds: 200);
  static const Duration scaleTransition = Duration(milliseconds: 300);
  
  // === カーブ ===
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve sharpCurve = Curves.easeOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  
  // === マイクロインタラクション用の値 ===
  static const double scalePressed = 0.95;
  static const double scaleHover = 1.02;
  static const double opacityDisabled = 0.5;
  static const double opacityPressed = 0.8;
}