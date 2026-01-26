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
import '../../../core/utils/user_consts.dart';
import '../../../core/widgets/pressable_card.dart';
import '../../../core/widgets/setting_item.dart';
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
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          '設定',
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
              _buildProfileSection(),

              const SizedBox(height: SpacingConsts.l),

              // アカウント連携セクション
              _buildAccountSection(),

              const SizedBox(height: SpacingConsts.l),

              // アプリ設定
              _buildAppSection(),

              const SizedBox(height: SpacingConsts.l),

              // 通知設定
              _buildNotificationSection(),

              const SizedBox(height: SpacingConsts.l),

              // データとプライバシー
              _buildDataSection(),

              const SizedBox(height: SpacingConsts.l),

              // サポート
              _buildSupportSection(),

              const SizedBox(height: SpacingConsts.l),

              // アカウント管理（ログアウト・削除）
              _buildAccountManagementSection(),

              const SizedBox(height: SpacingConsts.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
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
                    'タップして名前を変更',
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
    // オンラインチェック
    final hasNetwork = await _settingsViewModel.checkNetworkConnection();
    if (!hasNetwork) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(UserConsts.offlineError),
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
      builder: (context) => AlertDialog(
        title: const Text(UserConsts.changeNameDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLength: UserConsts.maxDisplayNameLength,
              autofocus: true,
              decoration: InputDecoration(
                hintText: UserConsts.changeNameDialogHint,
                counterText:
                    '${controller.text.length}/${UserConsts.maxDisplayNameLength}',
              ),
              onChanged: (value) {
                // counterTextを更新するため、setStateを使用
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(UserConsts.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(UserConsts.emptyNameError),
                    backgroundColor: ColorConsts.error,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(newName);
            },
            child: const Text(UserConsts.saveButtonLabel),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final success = await _settingsViewModel.updateDisplayName(result);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('名前を変更しました'),
          backgroundColor: ColorConsts.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('名前の変更に失敗しました'),
          backgroundColor: ColorConsts.error,
        ),
      );
    }
  }

  Widget _buildAccountSection() {
    // Supabaseの現在のユーザーを取得
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;

    return _buildSection(
      title: 'アカウント連携',
      children: [
        if (isAnonymous)
          SettingItem(
            title: 'アカウントを連携する',
            subtitle: 'Google / Apple でデータをバックアップ',
            icon: Icons.link,
            iconColor: ColorConsts.primary,
            onTap: _showLoginScreen,
          )
        else
          SettingItem(
            title: '連携済み',
            subtitle: currentUser?.email ?? 'アカウント連携済み',
            icon: Icons.check_circle,
            iconColor: ColorConsts.success,
            onTap: null,
          ),
      ],
    );
  }

  Widget _buildAppSection() {
    return _buildSection(
      title: 'アプリ設定',
      children: [
        Obx(() {
          return SettingItem(
            title: 'デフォルトタイマー時間',
            subtitle:
                '新しい目標のデフォルト時間：${_settingsViewModel.formattedDefaultTime}',
            icon: Icons.timer_outlined,
            iconColor: ColorConsts.warning,
            onTap: _showTimerSettings,
          );
        }),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: '通知設定',
      children: [
        Obx(() {
          return _buildSwitchSettingItem(
            title: 'ストリークリマインダー',
            subtitle:
                _settingsViewModel.streakReminderEnabled.value
                    ? '連続学習を維持するためのリマインダーを受け取ります'
                    : 'リマインダー通知はOFFです',
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

  Widget _buildDataSection() {
    return _buildSection(
      title: 'データとプライバシー',
      children: [
        SettingItem(
          title: 'プライバシーポリシー',
          subtitle: 'データの取り扱いについて',
          icon: Icons.privacy_tip_outlined,
          iconColor: ColorConsts.textSecondary,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'サポート',
      children: [
        SettingItem(
          title: 'お問い合わせ',
          subtitle: 'ご意見・ご要望をお聞かせください',
          icon: Icons.email_outlined,
          iconColor: ColorConsts.success,
          onTap: _showContact,
        ),
        SettingItem(
          title: 'アプリについて',
          subtitle: 'バージョン ${AppConsts.appVersion}',
          icon: Icons.info_outline,
          iconColor: ColorConsts.textSecondary,
          onTap: _showAbout,
        ),
      ],
    );
  }

  Widget _buildAccountManagementSection() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;

    return _buildSection(
      title: 'アカウント管理',
      children: [
        // ログアウトボタン（連携済みユーザーのみ表示）
        if (!isAnonymous)
          SettingItem(
            title: 'ログアウト',
            subtitle: 'アカウントからログアウトします',
            icon: Icons.logout,
            iconColor: ColorConsts.warning,
            onTap: _showLogoutConfirmDialog,
          ),

        // アカウント削除ボタン（全ユーザーに表示）
        SettingItem(
          title: 'アカウントを削除',
          subtitle: 'すべてのデータが削除されます',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: ColorConsts.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.warning,
            ),
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  /// ログアウトを実行
  Future<void> _performLogout() async {
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

      AppLogger.instance.i('ログアウト完了');

      // ウェルカム画面へ遷移
      if (mounted) {
        Get.offAll(() => const WelcomeScreen());
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('ログアウトに失敗しました', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログアウトに失敗しました'),
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
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除'),
        content: const Text(
          'この操作は取り消せません。\n\n'
          'すべてのデータ（目標、学習記録など）が\n完全に削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: ColorConsts.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.error,
            ),
            child: const Text(
              '削除する',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _showFinalDeleteConfirmDialog();
    }
  }

  /// アカウント削除確認ダイアログ（2段目・最終確認）
  Future<void> _showFinalDeleteConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '本当に削除しますか？',
          style: TextStyle(color: ColorConsts.error),
        ),
        content: const Text(
          'この操作を実行すると、あなたのアカウントと\n'
          'すべてのデータが完全に削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'やめる',
              style: TextStyle(color: ColorConsts.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.error,
            ),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performDeleteAccount();
    }
  }

  /// アカウント削除を実行
  Future<void> _performDeleteAccount() async {
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
          const SnackBar(
            content: Text('アカウント削除に失敗しました'),
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
      builder: (context) {
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'キャンセル',
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
                              'デフォルトタイマー時間',
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
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          '保存',
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URLを開けませんでした'),
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

  void _showContact() {
    // PRコメント対応: URLを定数化
    _openUrl(AppConsts.contactFormUrl);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('${AppConsts.appName} について'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConsts.appName,
                  style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: SpacingConsts.s),
                const Text('バージョン: ${AppConsts.appVersion}'),
                const SizedBox(height: SpacingConsts.m),
                const Text('目標達成をサポートするタイマーアプリです。毎日の小さな積み重ねが、大きな成果につながります。'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
