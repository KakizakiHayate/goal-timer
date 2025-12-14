/// 文字列定数（将来的なi18n対応の基盤）
class StringConsts {
  StringConsts._();

  // 目標モーダル関連
  static const String addGoalTitle = '目標を追加';
  static const String editGoalTitle = '目標を編集';
  static const String goalAddedMessage = '目標を追加しました';
  static const String goalUpdatedMessage = '目標を更新しました';
  static const String goalAddFailedMessage = '目標の追加に失敗しました';
  static const String goalUpdateFailedMessage = '目標の更新に失敗しました';
  static const String selectDeadlineMessage = '期限を選択してください';

  // フォームラベル
  static const String goalNameLabel = '目標名 *';
  static const String descriptionLabel = '説明';
  static const String targetMinutesLabel = '一日の目標時間 *';
  static const String deadlineLabel = '期限 *';
  static const String avoidMessageLabel = '達成しないとどうなりますか？ *';
  static const String avoidMessageHint = 'ネガティブな結果を明確にすることで、モチベーションを維持しやすくなります';

  // バリデーションメッセージ
  static const String goalNameRequired = '目標名を入力してください';
  static const String targetMinutesRequired = '目標時間を入力してください';
  static const String invalidNumber = '正しい数値を入力してください';
  static const String avoidMessageRequired = '達成しない場合の結果を入力してください';

  // プレースホルダー
  static const String goalNamePlaceholder = '例: TOEIC 800点取得';
  static const String descriptionPlaceholder = '例: 海外転職のために英語力を向上させたい';
  static const String targetMinutesPlaceholder = '例: 1500';
  static const String avoidMessagePlaceholder = '例: キャリアアップの機会を逃してしまう';
  static const String selectDeadlinePlaceholder = '期限を選択してください';

  // ボタン
  static const String saveButton = '保存';
  static const String updateButton = '更新';
  static const String deleteButton = '削除';
  static const String cancelButton = 'キャンセル';

  // 削除確認ダイアログ
  static const String deleteGoalTitle = '目標を削除しますか？';
  static const String deleteGoalMessage =
      'この目標と、紐づいた学習ログがすべて削除されます。この操作は元に戻せません。';
  static const String goalDeletedMessage = '目標を削除しました';
  static const String goalDeleteFailedMessage = '目標の削除に失敗しました';
}
