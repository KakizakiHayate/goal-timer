/// ユーザー機能に関連する定数
class UserConsts {
  // ビジネスロジック定数

  /// ユーザー名の最大文字数
  static const int maxDisplayNameLength = 20;

  /// ゲストユーザーのデフォルト名
  static const String defaultGuestName = 'ゲスト';

  // バリデーションメッセージ

  /// 空文字エラーメッセージ
  static const String emptyNameError = '名前を入力してください';

  /// 文字数超過エラーメッセージ
  static String maxLengthError(int max) => '名前は$max文字以内で入力してください';

  // ダイアログ関連

  /// 名前変更ダイアログのタイトル
  static const String changeNameDialogTitle = '名前を変更';

  /// 名前変更ダイアログのヒント
  static const String changeNameDialogHint = '名前を入力';

  /// オフラインエラーメッセージ
  static const String offlineError = 'オフラインのため変更できません';

  /// 保存ボタンのラベル
  static const String saveButtonLabel = '保存';

  /// キャンセルボタンのラベル
  static const String cancelButtonLabel = 'キャンセル';
}
