import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsContent(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
      BuildContext context, WidgetRef ref, Settings settings) {
    return ListView(
      children: [
        _buildSectionHeader(context, 'アプリ設定'),
        _buildThemeSelector(context, ref, settings),
        const Divider(),
        _buildSectionHeader(context, '通知設定'),
        _buildNotificationToggle(context, ref, settings),
        _buildReminderIntervalSelector(context, ref, settings),
        const Divider(),
        _buildSectionHeader(context, 'サウンド設定'),
        _buildSoundToggle(context, ref, settings),
        const Divider(),
        _buildSectionHeader(context, 'アプリ情報'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('バージョン情報'),
          subtitle: const Text('v1.0.0'), // アプリのバージョン情報
          onTap: () {
            // バージョン情報の詳細表示など
          },
        ),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('プライバシーポリシー'),
          onTap: () {
            // プライバシーポリシーを表示
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('ヘルプ・サポート'),
          onTap: () {
            // ヘルプ・サポート情報を表示
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, Settings settings) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('テーマ'),
      subtitle: Text(_getThemeText(settings.theme)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
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
                      ref.read(settingsProvider.notifier).updateTheme(value);
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
                      ref.read(settingsProvider.notifier).updateTheme(value);
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
                      ref.read(settingsProvider.notifier).updateTheme(value);
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
      BuildContext context, WidgetRef ref, Settings settings) {
    return SwitchListTile(
      title: const Text('通知'),
      subtitle: const Text('目標達成のリマインダーを通知する'),
      value: settings.notificationsEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateNotificationsEnabled(value);
      },
    );
  }

  Widget _buildReminderIntervalSelector(
      BuildContext context, WidgetRef ref, Settings settings) {
    return ListTile(
      enabled: settings.notificationsEnabled,
      leading: const Icon(Icons.timer_outlined),
      title: const Text('リマインダー間隔'),
      subtitle: Text('${settings.reminderInterval}分ごと'),
      onTap: settings.notificationsEnabled
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('リマインダー間隔'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [15, 30, 60, 120].map((interval) {
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
            }
          : null,
    );
  }

  Widget _buildSoundToggle(
      BuildContext context, WidgetRef ref, Settings settings) {
    return SwitchListTile(
      title: const Text('効果音'),
      subtitle: const Text('操作時に効果音を再生する'),
      value: settings.soundEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateSoundEnabled(value);
      },
    );
  }
}
