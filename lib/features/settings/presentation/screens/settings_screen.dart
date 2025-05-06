import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import '../viewmodels/settings_view_model.dart';
import '../../domain/entities/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsContent(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // アプリ設定セクション
        _buildSectionCard(
          context,
          title: 'アプリ設定',
          icon: Icons.settings_outlined,
          children: [_buildThemeSelector(context, ref, settings)],
        ),

        const SizedBox(height: 16),

        // 通知設定セクション
        _buildSectionCard(
          context,
          title: '通知設定',
          icon: Icons.notifications_outlined,
          children: [
            _buildNotificationToggle(context, ref, settings),
            if (settings.notificationsEnabled)
              _buildReminderIntervalSelector(context, ref, settings),
          ],
        ),

        const SizedBox(height: 16),

        // サウンド設定セクション
        _buildSectionCard(
          context,
          title: 'サウンド設定',
          icon: Icons.volume_up_outlined,
          children: [_buildSoundToggle(context, ref, settings)],
        ),

        const SizedBox(height: 16),

        // タイマー設定セクション
        _buildSectionCard(
          context,
          title: 'タイマー設定',
          icon: Icons.timer_outlined,
          children: [
            _buildDefaultTimerDurationSelector(context, ref, settings),
          ],
        ),

        const SizedBox(height: 16),

        // データ管理セクション
        _buildSectionCard(
          context,
          title: 'データ管理',
          icon: Icons.storage_outlined,
          children: [
            ListTile(
              leading: const Icon(
                Icons.backup_outlined,
                color: ColorConsts.primary,
              ),
              title: const Text('データのバックアップ'),
              subtitle: const Text('目標データをエクスポートする'),
              onTap: () {
                // バックアップ機能の実装
                _showFeatureNotAvailableDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.restore_outlined,
                color: ColorConsts.primary,
              ),
              title: const Text('データの復元'),
              subtitle: const Text('バックアップからデータを復元する'),
              onTap: () {
                // 復元機能の実装
                _showFeatureNotAvailableDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('すべてのデータを削除'),
              subtitle: const Text('アプリのすべてのデータを消去する（この操作は元に戻せません）'),
              onTap: () {
                // データ削除確認ダイアログ
                _showDeleteConfirmationDialog(context);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // アプリ情報セクション
        _buildSectionCard(
          context,
          title: 'アプリ情報',
          icon: Icons.info_outline,
          children: [
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: ColorConsts.primary,
              ),
              title: const Text('バージョン情報'),
              subtitle: const Text('v1.0.0'),
              onTap: () {
                // バージョン情報の詳細表示
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.policy_outlined,
                color: ColorConsts.primary,
              ),
              title: const Text('プライバシーポリシー'),
              onTap: () {
                // プライバシーポリシーを表示
                _showFeatureNotAvailableDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: ColorConsts.primary,
              ),
              title: const Text('ヘルプ・サポート'),
              onTap: () {
                // ヘルプ・サポート情報を表示
                _showFeatureNotAvailableDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  // セクションカードを構築
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Row(
              children: [
                Icon(icon, color: ColorConsts.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorConsts.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 子ウィジェット
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.palette_outlined, color: ColorConsts.primary),
      title: const Text('テーマ'),
      subtitle: Text(_getThemeText(settings.theme)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('テーマ選択'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: const Text('システム設定に合わせる'),
                      value: 'system',
                      groupValue: settings.theme,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateTheme(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('ライトモード'),
                      value: 'light',
                      groupValue: settings.theme,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateTheme(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('ダークモード'),
                      value: 'dark',
                      groupValue: settings.theme,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateTheme(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
        );
      },
    );
  }

  String _getThemeText(String theme) {
    switch (theme) {
      case 'system':
        return 'システム設定に合わせる';
      case 'light':
        return 'ライトモード';
      case 'dark':
        return 'ダークモード';
      default:
        return 'システム設定に合わせる';
    }
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('通知'),
      subtitle: const Text('目標達成のリマインダーを通知する'),
      value: settings.notificationsEnabled,
      activeColor: ColorConsts.primary,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateNotificationsEnabled(value);
      },
    );
  }

  Widget _buildReminderIntervalSelector(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timer_outlined, color: ColorConsts.primary),
      title: const Text('リマインダー間隔'),
      subtitle: Text('${settings.reminderInterval}分ごと'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('リマインダー間隔'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      [15, 30, 60, 120].map((interval) {
                        return RadioListTile<int>(
                          title: Text('$interval分ごと'),
                          value: interval,
                          groupValue: settings.reminderInterval,
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateReminderInterval(value);
                              Navigator.of(context).pop();
                            }
                          },
                        );
                      }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildSoundToggle(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('効果音'),
      subtitle: const Text('操作時に効果音を再生する'),
      value: settings.soundEnabled,
      activeColor: ColorConsts.primary,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateSoundEnabled(value);
      },
    );
  }

  Widget _buildDefaultTimerDurationSelector(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.av_timer, color: ColorConsts.primary),
      title: const Text('デフォルトタイマー時間'),
      subtitle: Text('${settings.defaultTimerDuration}分'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // タイマー時間設定ダイアログ
        _showTimePickerDialog(context, ref, settings);
      },
    );
  }

  // タイマー時間設定ダイアログ
  void _showTimePickerDialog(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('デフォルトタイマー時間'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [15, 25, 30, 45, 60].map((minutes) {
                    return RadioListTile<int>(
                      title: Text('$minutes分'),
                      value: minutes,
                      groupValue: settings.defaultTimerDuration,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateDefaultTimerDuration(value);
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
    );
  }

  // 機能未実装ダイアログ
  void _showFeatureNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('お知らせ'),
            content: const Text('この機能は現在開発中です。今後のアップデートをお待ちください。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  // データ削除確認ダイアログ
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('すべてのデータを削除'),
            content: const Text(
              'この操作を実行すると、アプリ内のすべてのデータが削除されます。この操作は元に戻せません。\n\n本当に削除しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  // データ削除機能（実装予定）
                  _showFeatureNotAvailableDialog(context);
                },
                child: const Text('削除する'),
              ),
            ],
          ),
    );
  }
}
