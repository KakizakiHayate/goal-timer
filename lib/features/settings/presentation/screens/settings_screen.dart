import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/setting_item.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../../core/services/timer_restriction_service.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../shared/widgets/sync_status_indicator.dart';
import '../../../billing/presentation/screens/upgrade_screen.dart';

// タイマー制限サービスのプロバイダー
final timerRestrictionServiceProvider = Provider<TimerRestrictionService>((
  ref,
) {
  return TimerRestrictionService();
});

/// 改善された設定画面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 通知設定の状態変数
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

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

              // プレミアムプラン
              _buildPremiumSection(),

              const SizedBox(height: SpacingConsts.l),

              // 通知設定
              _buildNotificationSection(),

              const SizedBox(height: SpacingConsts.l),

              // アプリ設定
              _buildAppSection(),

              const SizedBox(height: SpacingConsts.l),

              // データとプライバシー
              _buildDataSection(),

              const SizedBox(height: SpacingConsts.l),

              // サポート
              _buildSupportSection(),

              const SizedBox(height: SpacingConsts.l),

              // アカウント
              _buildAccountSection(),

              const SizedBox(height: SpacingConsts.l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Consumer(
      builder: (context, ref, _) {
        final currentUser = ref.watch(currentUserProvider);
        final authState = ref.watch(authViewModelProvider);

        return currentUser.when(
          data: (user) => _buildProfileCard(user, authState),
          loading: () => _buildProfileLoadingCard(),
          error: (_, __) => _buildProfileErrorCard(),
        );
      },
    );
  }

  Widget _buildProfileCard(AppUser? user, AuthState authState) {
    // デフォルト値の設定
    final displayName = user?.displayName ?? 'ゲストユーザー';
    final email = user?.email ?? '';
    final showEmail = email.isNotEmpty && authState != AuthState.guest;

    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      onTap: () => _showUsernameEditDialog(displayName),
      child: Row(
        children: [
          // アバター
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
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
                  displayName,
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showEmail) ...[
                  const SizedBox(height: SpacingConsts.xs),
                  Text(
                    email,
                    style: TextConsts.body.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: SpacingConsts.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConsts.s,
                    vertical: SpacingConsts.xs,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConsts.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'プレミアム会員',
                    style: TextConsts.caption.copyWith(
                      color: ColorConsts.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: ColorConsts.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileLoadingCard() {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      onTap: null,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ColorConsts.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(width: SpacingConsts.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: ColorConsts.backgroundSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: SpacingConsts.xs),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: ColorConsts.backgroundSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileErrorCard() {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      onTap: null,
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: ColorConsts.error),
          SizedBox(width: SpacingConsts.l),
          Text('プロフィール情報の読み込みに失敗しました'),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: '通知設定',
      children: [
        SettingItem(
          title: '通知を有効にする',
          subtitle: '目標のリマインダーやお知らせを受け取る',
          icon: Icons.notifications_outlined,
          iconColor: ColorConsts.primary,
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: ColorConsts.primary,
          ),
        ),
        SettingItem(
          title: 'サウンド',
          subtitle: '通知音を再生する',
          icon: Icons.volume_up_outlined,
          iconColor: ColorConsts.warning,
          enabled: _notificationsEnabled,
          trailing: Switch(
            value: _soundEnabled && _notificationsEnabled,
            onChanged:
                _notificationsEnabled
                    ? (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    }
                    : null,
            activeColor: ColorConsts.primary,
          ),
        ),
        SettingItem(
          title: 'バイブレーション',
          subtitle: '通知時に振動する',
          icon: Icons.vibration_outlined,
          iconColor: ColorConsts.success,
          enabled: _notificationsEnabled,
          trailing: Switch(
            value: _vibrationEnabled && _notificationsEnabled,
            onChanged:
                _notificationsEnabled
                    ? (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                    }
                    : null,
            activeColor: ColorConsts.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    return _buildSection(
      title: 'アプリ設定',
      children: [
        SettingItem(
          title: 'デフォルトタイマー時間',
          subtitle: '新しい目標のデフォルト時間：25分',
          icon: Icons.timer_outlined,
          iconColor: ColorConsts.warning,
          onTap: _showTimerSettings,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'データとプライバシー',
      children: [
        // 手動同期ボタン
        Container(
          margin: const EdgeInsets.only(bottom: SpacingConsts.s),
          child: PressableCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(SpacingConsts.l),
            backgroundColor: ColorConsts.cardBackground,
            borderRadius: 20.0,
            elevation: 2.0,
            onTap: null, // SyncStatusIndicatorが独自のタップ処理を持つ
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ColorConsts.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sync, color: ColorConsts.primary, size: 24),
                ),
                const SizedBox(width: SpacingConsts.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '手動同期',
                        style: TextConsts.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConsts.textPrimary,
                        ),
                      ),
                      const SizedBox(height: SpacingConsts.xs),
                      Text(
                        'データをクラウドと同期する',
                        style: TextConsts.caption.copyWith(
                          color: ColorConsts.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SyncStatusIndicator(),
              ],
            ),
          ),
        ),

        SettingItem(
          title: 'データのエクスポート',
          subtitle: '学習データをエクスポート',
          icon: Icons.download_outlined,
          iconColor: ColorConsts.primary,
          onTap: _exportData,
        ),
        SettingItem(
          title: 'データのバックアップ',
          subtitle: 'クラウドにデータを同期',
          icon: Icons.cloud_upload_outlined,
          iconColor: ColorConsts.success,
          onTap: _showBackupSettings,
        ),
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
          subtitle: 'バージョン 1.0.0',
          icon: Icons.info_outline,
          iconColor: ColorConsts.textSecondary,
          onTap: _showAbout,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authViewModelProvider);
        final isGuest = authState.isGuest;

        return _buildSection(
          title: 'アカウント',
          children: [
            // ゲストユーザーの場合のみアカウント連携項目を表示
            if (isGuest)
              SettingItem(
                title: 'アカウント連携',
                subtitle: 'Google・Appleアカウントと連携する',
                icon: Icons.link,
                iconColor: ColorConsts.primary,
                onTap: _navigateToAccountLinking,
              ),

            // アカウント終了項目（ゲストの場合は「リセット」、認証済みの場合は「サインアウト」）
            SettingItem(
              title: isGuest ? 'リセット' : 'サインアウト',
              subtitle: isGuest ? 'すべてのデータを削除してリセット' : 'アカウントからサインアウト',
              icon: isGuest ? Icons.refresh : Icons.logout,
              iconColor: ColorConsts.error,
              onTap: isGuest ? _showResetDialog : _showSignOutDialog,
            ),
          ],
        );
      },
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

  // モーダル・ダイアログ表示メソッド
  void _showUsernameEditDialog(String currentUsername) {
    final textController = TextEditingController(text: currentUsername);
    String? errorText;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('ユーザー名編集'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('新しいユーザー名を入力してください'),
                      const SizedBox(height: SpacingConsts.md),
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'ユーザー名',
                          errorText: errorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: ColorConsts.primary),
                          ),
                        ),
                        maxLength: 50,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        final newUsername = textController.text.trim();
                        final validation = _validateUsername(newUsername);

                        if (validation != null) {
                          setState(() {
                            errorText = validation;
                          });
                          return;
                        }

                        // ユーザー名更新処理
                        _updateUsername(newUsername);
                        Navigator.pop(context);
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );
  }

  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return 'ユーザー名を入力してください';
    }

    if (username.length > 50) {
      return 'ユーザー名は50文字以内で入力してください';
    }

    // 無効な文字のチェック（英数字、ひらがな、カタカナ、漢字、スペース、一部記号のみ許可）
    final validPattern = RegExp(r'^[a-zA-Z0-9ぁ-んァ-ンー一-龯\s\-_\.]+$');
    if (!validPattern.hasMatch(username)) {
      return '使用できない文字が含まれています';
    }

    return null;
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      // 現在のユーザー情報を取得
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('ユーザーが見つかりません');
      }

      // ユーザー名更新ユースケースを実行
      final updateUsernameUseCase = ref.read(updateUsernameUseCaseProvider);
      await updateUsernameUseCase.execute(currentUser.id, newUsername);

      // プロバイダーを更新してUIに反映
      ref.invalidate(currentUserProvider);

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ユーザー名を更新しました'),
            backgroundColor: ColorConsts.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ユーザー名の更新に失敗しました: $e'),
            backgroundColor: ColorConsts.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showTimerSettings() {
    _showComingSoonDialog('タイマー設定');
  }

  void _exportData() {
    _showComingSoonDialog('データエクスポート');
  }

  void _showBackupSettings() {
    _showComingSoonDialog('バックアップ設定');
  }

  void _showPrivacyPolicy() {
    _showComingSoonDialog('プライバシーポリシー');
  }

  void _showContact() {
    _showComingSoonDialog('お問い合わせ');
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Goal Timer について'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal Timer',
                  style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: SpacingConsts.s),
                const Text('バージョン: 1.0.0'),
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

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('サインアウト'),
            content: const Text('サインアウトしますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final authNotifier = ref.read(
                      authViewModelProvider.notifier,
                    );
                    await authNotifier.signOut();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('サインアウトに失敗しました: $e'),
                          backgroundColor: ColorConsts.error,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: ColorConsts.error),
                child: const Text('サインアウト'),
              ),
            ],
          ),
    );
  }

  Widget _buildPremiumSection() {
    final restrictionService = ref.read(timerRestrictionServiceProvider);
    final currentPlan = restrictionService.getCurrentPlan();
    final limitations = restrictionService.getPlanLimitations();
    final isPremium = currentPlan == 'Premium';

    return _buildSection(
      title: 'プラン情報',
      children: [
        // 現在のプラン表示
        PressableCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(SpacingConsts.lg),
          backgroundColor:
              isPremium
                  ? ColorConsts.primary.withValues(alpha: 0.1)
                  : ColorConsts.cardBackground,
          borderRadius: 20.0,
          elevation: 2.0,
          onTap: isPremium ? null : _showUpgradeScreen,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient:
                          isPremium
                              ? const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : const LinearGradient(
                                colors: [
                                  ColorConsts.primary,
                                  ColorConsts.primaryLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPremium ? Icons.diamond : Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: SpacingConsts.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '現在のプラン: ',
                              style: TextConsts.bodySmall.copyWith(
                                color: ColorConsts.textSecondary,
                              ),
                            ),
                            Text(
                              currentPlan,
                              style: TextConsts.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    isPremium
                                        ? ColorConsts.primary
                                        : ColorConsts.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacingConsts.xs),
                        if (isPremium)
                          Text(
                            'すべての機能をご利用いただけます',
                            style: TextConsts.caption.copyWith(
                              color: ColorConsts.success,
                            ),
                          )
                        else
                          Text(
                            'プレミアムで更多機能を解除',
                            style: TextConsts.caption.copyWith(
                              color: ColorConsts.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isPremium)
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: ColorConsts.textSecondary,
                      size: 16,
                    ),
                ],
              ),

              const SizedBox(height: SpacingConsts.md),

              // プラン制限表示
              Container(
                padding: const EdgeInsets.all(SpacingConsts.md),
                decoration: BoxDecoration(
                  color: ColorConsts.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildPlanLimitationItem(
                      icon: Icons.flag,
                      title: '目標数',
                      value:
                          limitations['max_goals'] == -1
                              ? '無制限'
                              : '${limitations['max_goals']}個まで',
                      isUnlimited: limitations['max_goals'] == -1,
                    ),
                    _buildPlanLimitationItem(
                      icon: Icons.timer,
                      title: 'タイマーモード',
                      value:
                          '${(limitations['available_timers'] as List).length}種類',
                      isUnlimited:
                          (limitations['available_timers'] as List).length >= 4,
                    ),
                    _buildPlanLimitationItem(
                      icon: Icons.storage,
                      title: 'データ保存期間',
                      value:
                          limitations['log_retention_days'] == -1
                              ? '無制限'
                              : '${limitations['log_retention_days']}日間',
                      isUnlimited: limitations['log_retention_days'] == -1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // アップグレードボタン（非プレミアムユーザーのみ）
        if (!isPremium) ...[
          const SizedBox(height: SpacingConsts.md),
          PressableCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(SpacingConsts.lg),
            backgroundColor: ColorConsts.cardBackground,
            borderRadius: 20.0,
            elevation: 2.0,
            onTap: _showUpgradeScreen,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upgrade,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: SpacingConsts.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'プレミアムにアップグレード',
                        style: TextConsts.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConsts.textPrimary,
                        ),
                      ),
                      const SizedBox(height: SpacingConsts.xs),
                      Text(
                        '無制限の目標・ポモドーロタイマー・データ永続保存',
                        style: TextConsts.caption.copyWith(
                          color: ColorConsts.textSecondary,
                        ),
                      ),
                      const SizedBox(height: SpacingConsts.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingConsts.sm,
                          vertical: SpacingConsts.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '7日間無料トライアル',
                          style: TextConsts.caption.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ColorConsts.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanLimitationItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isUnlimited,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConsts.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isUnlimited ? ColorConsts.success : ColorConsts.textSecondary,
          ),
          const SizedBox(width: SpacingConsts.sm),
          Expanded(
            child: Text(
              title,
              style: TextConsts.bodySmall.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextConsts.bodySmall.copyWith(
              color:
                  isUnlimited ? ColorConsts.success : ColorConsts.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UpgradeScreen()));
  }

  // アカウント連携画面への遷移
  void _navigateToAccountLinking() {
    // TODO: AccountPromotionScreenへのナビゲーション実装
    // 現在は開発中のため、開発中ダイアログを表示
    _showComingSoonDialog('アカウント連携');

    // 実装予定のコード:
    // Navigator.of(context).pushNamed(
    //   '/onboarding/account-promotion',
    //   arguments: {
    //     'fromSettings': true,
    //     'skipOnboardingFlow': true,
    //   },
    // );
  }

  // ゲストユーザー向けリセット処理
  void _showResetDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('データをリセット'),
            content: const Text(
              'すべての目標と学習記録が削除されます。\n'
              'この操作は元に戻せません。\n'
              '本当にリセットしますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performReset();
                },
                style: TextButton.styleFrom(foregroundColor: ColorConsts.error),
                child: const Text('リセット'),
              ),
            ],
          ),
    );
  }

  // リセット処理の実行
  Future<void> _performReset() async {
    try {
      // TODO: ゲストデータの削除処理
      // final tempUserService = ref.read(tempUserServiceProvider);
      // await tempUserService.clearAllData();

      // 現在は開発中のため、成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リセットが完了しました（開発中）'),
            backgroundColor: ColorConsts.success,
          ),
        );
      }

      // TODO: 初期画面に戻る処理
      // if (mounted) {
      //   Navigator.of(context).pushNamedAndRemoveUntil(
      //     '/onboarding/goal-creation',
      //     (route) => false,
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('リセットに失敗しました: $e'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(feature),
            content: const Text('この機能は開発中です。\n今後のアップデートをお待ちください。'),
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
