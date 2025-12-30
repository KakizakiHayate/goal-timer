import 'package:flutter/material.dart';
import 'color_consts.dart';

final class ShadowConsts {
  // === カードシャドウ ===
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: ColorConsts.shadowLight,
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: ColorConsts.shadowLight,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // === エレベーション別シャドウ ===
  static const List<BoxShadow> elevationSmall = [
    BoxShadow(
      color: ColorConsts.shadowLight,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevationMedium = [
    BoxShadow(
      color: ColorConsts.shadowMedium,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevationLarge = [
    BoxShadow(
      color: ColorConsts.shadowMedium,
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // === 特殊シャドウ ===
  // ボタンプレス時
  static const List<BoxShadow> buttonPressed = [
    BoxShadow(
      color: ColorConsts.shadowLight,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // フォーカス時のアウトライン
  static const List<BoxShadow> focusOutline = [
    BoxShadow(
      color: ColorConsts.focusOverlay,
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 2,
    ),
  ];
}
