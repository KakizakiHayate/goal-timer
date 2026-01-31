import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/utils/animation_consts.dart';
import '../../../core/utils/app_consts.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/url_launcher_utils.dart';
import '../../../core/utils/user_consts.dart';
import '../../../core/widgets/pressable_card.dart';
import '../../../core/widgets/setting_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/view/login_screen.dart';
import '../../welcome/view/welcome_screen.dart';
import '../view_model/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // PRコメント対応: インスタンス変数として一度だけ取得
  final _settingsViewModel = Get.find<SettingsViewModel>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Obx(() {
      // 監視対象のobservable変数にアクセス（子メソッド内の変数も追跡される）
      _settingsViewModel.displayName.value;

      return Scaffold(
        backgroundColor: ColorConsts.backgroundPrimary,
        appBar: AppBar(
          title: Text(
            l10n?.settingsTitle ?? 'Settings',
            style: TextConsts.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: ColorConsts.primary,
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(SpacingConsts.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プロフィールセクション
              _buildProfileSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // アカウント連携セクション
              _buildAccountSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // アプリ設定
              _buildAppSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // 通知設定
              _buildNotificationSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // データとプライバシー
              _buildDataSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // サポート
              _buildSupportSection(l10n),

              const SizedBox(height: SpacingConsts.l),

              // アカウント管理（ログアウト・削除）
              _buildAccountManagementSection(l10n),

              const SizedBox(height: SpacingConsts.xxl),
            ],
          ),
        ),
      ),
    );
    });
  }

  Widget _buildProfileSection(AppLocalizations? l10n) {
    return Obx(
      () => PressableCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(SpacingConsts.l),
        backgroundColor: ColorConsts.cardBackground,
        borderRadius: 20.0,
        elevation: 2.0,
        onTap: _showChangeNameDialog,
        child: Row(
          children: [
            // アバター
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorConsts.primary, ColorConsts.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),

            const SizedBox(width: SpacingConsts.l),

            // ユーザー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settingsViewModel.displayName.value,
                    style: TextConsts.h4.copyWith(
                      color: ColorConsts.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SpacingConsts.xs),
                  Text(
                    l10n?.tapToChangeName ?? 'Tap to change name',
                    style: TextConsts.caption.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 編集アイコン
            const Icon(
              Icons.edit_outlined,
              color: ColorConsts.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 名前変更ダイアログを表示
  Future<void> _showChangeNameDialog() async {
    final l10n = AppLocalizations.of(context);

    // オンラインチェック
    final hasNetwork = await _settingsViewModel.checkNetworkConnection();
    if (!hasNetwork) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.offlineError ?? 'Cannot change while offline'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
      return;
    }

    final controller = TextEditingController(
      text: _settingsViewModel.displayName.value,
    );

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(dialogL10n?.changeNameDialogTitle ?? 'Change Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLength: UserConsts.maxDisplayNameLength,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: dialogL10n?.changeNameDialogHint ?? 'Enter name',
                    counterText:
                        '${controller.text.length}/${UserConsts.maxDisplayNameLength}',
                  ),
                  onChanged: (value) {
                    // counterTextを更新するため、StatefulBuilderのsetStateを使用
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogL10n?.commonBtnCancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(dialogL10n?.emptyNameError ?? 'Please enter a name'),
                        backgroundColor: ColorConsts.error,
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(newName);
                },
                child: Text(dialogL10n?.commonBtnSave ?? 'Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;

    final success = await _settingsViewModel.updateDisplayName(result);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.nameChangedSuccess ?? 'Name changed successfully'),
          backgroundColor: ColorConsts.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.nameChangeFailed ?? 'Failed to change name'),
          backgroundColor: ColorConsts.error,
        ),
      );
    }
  }

  Widget _buildAccountSection(AppLocalizations? l10n) {
    // Supabaseの現在のユーザーを取得
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;

    return _buildSection(
      title: l10n?.sectionAccountLink ?? 'Account Link',
      children: [
        if (isAnonymous)
          SettingItem(
            title: l10n?.linkAccount ?? 'Link Account',
            subtitle: l10n?.linkAccountSubtitle ?? 'Backup data with Google / Apple',
            icon: Icons.link,
            iconColor: ColorConsts.primary,
            onTap: _showLoginScreen,
          )
        else
          SettingItem(
            title: l10n?.accountLinked ?? 'Linked',
            subtitle: currentUser?.email ?? (l10n?.accountLinkedDefault ?? 'Account linked'),
            icon: Icons.check_circle,
            iconColor: ColorConsts.success,
            onTap: null,
          ),
      ],
    );
  }

  Widget _buildAppSection(AppLocalizations? l10n) {
    return _buildSection(
      title: l10n?.sectionAppSettings ?? 'App Settings',
      children: [
        Obx(() {
          final subtitle = l10n?.defaultTimerDurationSubtitle(
                _settingsViewModel.formattedDefaultTime,
              ) ??
              'Default time for new goals: ${_settingsViewModel.formattedDefaultTime}';
          return SettingItem(
            title: l10n?.defaultTimerDuration ?? 'Default Timer Duration',
            subtitle: subtitle,
            icon: Icons.timer_outlined,
            iconColor: ColorConsts.warning,
            onTap: _showTimerSettings,
          );
        }),
      ],
    );
  }

  Widget _buildNotificationSection(AppLocalizations? l10n) {
    return _buildSection(
      title: l10n?.sectionNotifications ?? 'Notifications',
      children: [
        Obx(() {
          final subtitle = _settingsViewModel.streakReminderEnabled.value
              ? (l10n?.streakReminderOnSubtitle ?? 'Receive reminders to maintain your study streak')
              : (l10n?.streakReminderOffSubtitle ?? 'Reminder notifications are OFF');
          return _buildSwitchSettingItem(
            title: l10n?.streakReminder ?? 'Streak Reminder',
            subtitle: subtitle,
            icon: Icons.notifications_active_outlined,
            iconColor: ColorConsts.primary,
            value: _settingsViewModel.streakReminderEnabled.value,
            onChanged: (value) {
              _settingsViewModel.updateStreakReminderEnabled(value);
            },
          );
        }),
      ],
    );
  }

  Widget _buildSwitchSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingConsts.s),
      decoration: BoxDecoration(
        color: ColorConsts.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.m,
          vertical: SpacingConsts.s,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextConsts.body.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorConsts.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextConsts.bodySmall.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: ColorConsts.primary,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ColorConsts.primary;
            }
            return null;
          }),
        ),
      ),
    );
  }

  Widget _buildDataSection(AppLocalizations? l10n) {
    return _buildSection(
      title: l10n?.sectionDataPrivacy ?? 'Data & Privacy',
      children: [
        SettingItem(
          title: l10n?.privacyPolicy ?? 'Privacy Policy',
          subtitle: l10n?.privacyPolicySubtitle ?? 'About data handling',
          icon: Icons.privacy_tip_outlined,
          iconColor: ColorConsts.textSecondary,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildSupportSection(AppLocalizations? l10n) {
    return _buildSection(
      title: l10n?.sectionSupport ?? 'Support',
      children: [
        SettingItem(
          title: l10n?.bugReport ?? 'Bug Report',
          subtitle: l10n?.bugReportSubtitle ?? 'Report bugs and issues',
          icon: Icons.bug_report_outlined,
          iconColor: ColorConsts.error,
          onTap: _showBugReportForm,
        ),
        SettingItem(
          title: l10n?.featureRequest ?? 'Feature Request',
          subtitle: l10n?.featureRequestSubtitle ?? 'Share your ideas for new features',
          icon: Icons.lightbulb_outline,
          iconColor: ColorConsts.warning,
          onTap: _showFeatureRequestForm,
        ),
        SettingItem(
          title: l10n?.aboutApp ?? 'About',
          subtitle: l10n?.versionLabel(AppConsts.appVersion) ?? 'Version ${AppConsts.appVersion}',
          icon: Icons.info_outline,
          iconColor: ColorConsts.textSecondary,
          onTap: _showAbout,
        ),
      ],
    );
  }


  Widget _buildAccountManagementSection(AppLocalizations? l10n) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;

    return _buildSection(
      title: l10n?.sectionAccountManagement ?? 'Account Management',
      children: [
        // ログアウトボタン（連携済みユーザーのみ表示）
        if (!isAnonymous)
          SettingItem(
            title: l10n?.logout ?? 'Logout',
            subtitle: l10n?.logoutSubtitle ?? 'Sign out from your account',
            icon: Icons.logout,
            iconColor: ColorConsts.warning,
            onTap: _showLogoutConfirmDialog,
          ),

        // アカウント削除ボタン（全ユーザーに表示）
        SettingItem(
          title: l10n?.deleteAccount ?? 'Delete Account',
          subtitle: l10n?.deleteAccountSubtitle ?? 'All data will be deleted',
          icon: Icons.delete_forever,
          iconColor: ColorConsts.error,
          onTap: _showDeleteAccountConfirmDialog,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: SpacingConsts.s,
            bottom: SpacingConsts.m,
          ),
          child: Text(
            title,
            style: TextConsts.h4.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _showLoginScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen(mode: LoginMode.link)),
    );

    // ログイン画面から戻ったときにdisplayNameを再読み込み
    await _settingsViewModel.refreshDisplayName();
  }

  /// ログアウト確認ダイアログを表示
  Future<void> _showLogoutConfirmDialog() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n?.logout ?? 'Logout'),
          content: Text(dialogL10n?.logoutConfirmMessage ?? 'Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                dialogL10n?.commonBtnCancel ?? 'Cancel',
                style: const TextStyle(color: ColorConsts.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.warning,
              ),
              child: Text(
                dialogL10n?.logout ?? 'Logout',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _performLogout(l10n);
    }
  }

  /// ログアウトを実行
  Future<void> _performLogout(AppLocalizations? l10n) async {
    try {
      final authDatasource = SupabaseAuthDatasource(
        supabase: Supabase.instance.client,
      );
      await authDatasource.signOut();

      // ローカルDBのdisplayNameをリセット
      final usersDatasource = LocalUsersDatasource(
        database: Get.find<AppDatabase>(),
      );
      await usersDatasource.resetDisplayName();

      // SettingsViewModelのdisplayNameをリセット（permanentなのでメモリ上の値も更新）
      _settingsViewModel.displayName.value = UserConsts.defaultGuestName;

      AppLogger.instance.i('ログアウト完了');

      // ウェルカム画面へ遷移
      if (mounted) {
        Get.offAll(() => const WelcomeScreen());
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('ログアウトに失敗しました', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.logoutFailed ?? 'Failed to logout'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  /// アカウント削除確認ダイアログ（1段目）
  Future<void> _showDeleteAccountConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n?.deleteAccountConfirmTitle ?? 'Delete Account'),
          content: Text(
            dialogL10n?.deleteAccountConfirmMessage ??
                'This action cannot be undone.\n\nAll your data (goals, study records, etc.) will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                dialogL10n?.commonBtnCancel ?? 'Cancel',
                style: const TextStyle(color: ColorConsts.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.error,
              ),
              child: Text(
                dialogL10n?.btnDelete ?? 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _showFinalDeleteConfirmDialog();
    }
  }

  /// アカウント削除確認ダイアログ（2段目・最終確認）
  Future<void> _showFinalDeleteConfirmDialog() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(
            dialogL10n?.deleteAccountFinalTitle ?? 'Are you sure?',
            style: const TextStyle(color: ColorConsts.error),
          ),
          content: Text(
            dialogL10n?.deleteAccountFinalMessage ??
                'This action will permanently delete your account and all your data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                dialogL10n?.btnStop ?? 'Stop',
                style: const TextStyle(color: ColorConsts.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConsts.error,
              ),
              child: Text(
                dialogL10n?.commonBtnDelete ?? 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _performDeleteAccount(l10n);
    }
  }

  /// アカウント削除を実行
  Future<void> _performDeleteAccount(AppLocalizations? l10n) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authDatasource = SupabaseAuthDatasource(
        supabase: Supabase.instance.client,
      );

      // Edge Function経由でアカウント削除
      await authDatasource.deleteAccount();

      // ローカルデータを削除
      final appDatabase = Get.find<AppDatabase>();
      await appDatabase.clearAllData();

      // SettingsViewModelのdisplayNameをリセット（permanentなのでメモリ上の値も更新）
      _settingsViewModel.displayName.value = UserConsts.defaultGuestName;

      AppLogger.instance.i('アカウント削除完了');

      // ダイアログを閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }

      // ウェルカム画面へ遷移
      if (mounted) {
        Get.offAll(() => const WelcomeScreen());
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('アカウント削除に失敗しました', error, stackTrace);

      // ダイアログを閉じる
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.deleteAccountFailed ?? 'Failed to delete account'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  void _showTimerSettings() {
    Duration tempDuration = Duration(
      seconds: _settingsViewModel.defaultTimerSeconds.value,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetL10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(SpacingConsts.m),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          sheetL10n?.commonBtnCancel ?? 'Cancel',
                          style: TextConsts.body.copyWith(
                            color: ColorConsts.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              sheetL10n?.defaultTimerDuration ?? 'Default Timer Duration',
                              style: TextConsts.h4.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // PRコメント対応: ViewModelでバリデーションするのでUI側のclampは不要
                          await _settingsViewModel.updateDefaultTimerDuration(
                            tempDuration,
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: Text(
                          sheetL10n?.commonBtnSave ?? 'Save',
                          style: TextConsts.body.copyWith(
                            color: ColorConsts.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: tempDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      tempDuration = newDuration;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.urlOpenFailed ?? 'Could not open URL'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    // PRコメント対応: URLを定数化
    _openUrl(AppConsts.privacyPolicyUrl);
  }

  /// 不具合報告フォームを内部ブラウザで開く
  Future<void> _showBugReportForm() async {
    await UrlLauncherUtils.openInAppWebView(
      context,
      AppConsts.bugReportFormUrl,
    );
  }

  /// 機能追加要望フォームを内部ブラウザで開く
  Future<void> _showFeatureRequestForm() async {
    await UrlLauncherUtils.openInAppWebView(
      context,
      AppConsts.featureRequestFormUrl,
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n?.aboutDialogTitle(AppConsts.appName) ?? 'About ${AppConsts.appName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConsts.appName,
                style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: SpacingConsts.s),
              Text(dialogL10n?.versionLabel(AppConsts.appVersion) ?? 'Version: ${AppConsts.appVersion}'),
              const SizedBox(height: SpacingConsts.m),
              Text(dialogL10n?.aboutDialogDescription ?? 'A timer app to help you achieve your goals. Small daily efforts lead to great results.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogL10n?.commonBtnOk ?? 'OK'),
            ),
          ],
        );
      },
    );
  }
}
