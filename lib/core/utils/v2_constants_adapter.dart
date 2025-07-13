import 'spacing_consts.dart';
import 'text_consts.dart';

/// V2画面で使用されている定数へのアダプター
/// V2画面で使われている短縮名を既存の定数にマッピング
extension SpacingConstsV2 on SpacingConsts {
  static const double xs = SpacingConsts.xs;  // extra small
  static const double s = SpacingConsts.sm;   // small
  static const double m = SpacingConsts.md;   // medium  
  static const double l = SpacingConsts.lg;   // large
}

extension TextConstsV2 on TextConsts {
  static const body = TextConsts.bodyMedium;
  static const caption = TextConsts.caption;
}