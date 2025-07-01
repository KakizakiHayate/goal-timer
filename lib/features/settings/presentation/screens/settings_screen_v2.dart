import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/setting_item_v2.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../auth/provider/auth_provider.dart';

/// 改善された設定画面
class SettingsScreenV2 extends ConsumerStatefulWidget {
  const SettingsScreenV2({super.key});

  @override
  ConsumerState<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends ConsumerState<SettingsScreenV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedTheme = 'system'; // system, light, dark

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              
              const SizedBox(height: SpacingConsts.xl),
              
              // 通知設定
              _buildNotificationSection(),
              
              const SizedBox(height: SpacingConsts.xl),
              
              // アプリ設定
              _buildAppSection(),
              
              const SizedBox(height: SpacingConsts.xl),
              
              // データとプライバシー
              _buildDataSection(),
              
              const SizedBox(height: SpacingConsts.xl),
              
              // サポート
              _buildSupportSection(),
              
              const SizedBox(height: SpacingConsts.xl),
              
              // アカウント
              _buildAccountSection(),
              
              const SizedBox(height: SpacingConsts.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      onTap: _showProfileModal,
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
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(width: SpacingConsts.l),
          
          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ユーザー名',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  'user@example.com',
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
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

  Widget _buildNotificationSection() {
    return _buildSection(
      title: '通知設定',
      children: [
        SettingItemV2(
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
        SettingItemV2(
          title: 'サウンド',
          subtitle: '通知音を再生する',
          icon: Icons.volume_up_outlined,
          iconColor: ColorConsts.warning,
          enabled: _notificationsEnabled,
          trailing: Switch(
            value: _soundEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  }
                : null,
            activeColor: ColorConsts.primary,
          ),
        ),
        SettingItemV2(
          title: 'バイブレーション',
          subtitle: '通知時に振動する',
          icon: Icons.vibration_outlined,
          iconColor: ColorConsts.success,
          enabled: _notificationsEnabled,
          trailing: Switch(
            value: _vibrationEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
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
        SettingItemV2(
          title: 'テーマ',
          subtitle: _getThemeSubtitle(),
          icon: Icons.palette_outlined,
          iconColor: ColorConsts.primary,
          onTap: _showThemeSelector,
        ),
        SettingItemV2(
          title: 'デフォルトタイマー時間',
          subtitle: '新しい目標のデフォルト時間：25分',
          icon: Icons.timer_outlined,
          iconColor: ColorConsts.warning,
          onTap: _showTimerSettings,
        ),
        SettingItemV2(
          title: '週の開始日',
          subtitle: '統計の週の開始日：月曜日',
          icon: Icons.calendar_today_outlined,
          iconColor: ColorConsts.success,
          onTap: _showWeekStartSettings,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'データとプライバシー',
      children: [
        SettingItemV2(
          title: 'データのエクスポート',
          subtitle: '学習データをエクスポート',
          icon: Icons.download_outlined,
          iconColor: ColorConsts.primary,
          onTap: _exportData,
        ),
        SettingItemV2(
          title: 'データのバックアップ',
          subtitle: 'クラウドにデータを同期',
          icon: Icons.cloud_upload_outlined,
          iconColor: ColorConsts.success,
          onTap: _showBackupSettings,
        ),
        SettingItemV2(
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
        SettingItemV2(
          title: 'ヘルプ・FAQ',
          subtitle: 'よくある質問と使い方',
          icon: Icons.help_outline,
          iconColor: ColorConsts.primary,
          onTap: _showHelp,
        ),
        SettingItemV2(
          title: 'お問い合わせ',
          subtitle: 'ご意見・ご要望をお聞かせください',
          icon: Icons.email_outlined,
          iconColor: ColorConsts.success,
          onTap: _showContact,
        ),
        SettingItemV2(
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
    return _buildSection(
      title: 'アカウント',
      children: [
        SettingItemV2(
          title: 'サインアウト',
          subtitle: 'アカウントからサインアウト',
          icon: Icons.logout,
          iconColor: ColorConsts.error,
          onTap: _showSignOutDialog,
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

  String _getThemeSubtitle() {
    switch (_selectedTheme) {
      case 'light':
        return 'ライトテーマ';
      case 'dark':
        return 'ダークテーマ';
      case 'system':
      default:
        return 'システム設定に従う';
    }
  }

  // モーダル・ダイアログ表示メソッド
  void _showProfileModal() {
    // TODO: プロフィール編集モーダルの実装
    _showComingSoonDialog('プロフィール編集');
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('システム設定に従う'),
              value: 'system',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('ライトテーマ'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('ダークテーマ'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimerSettings() {
    _showComingSoonDialog('タイマー設定');
  }

  void _showWeekStartSettings() {
    _showComingSoonDialog('週開始日設定');
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

  void _showHelp() {
    _showComingSoonDialog('ヘルプ');
  }

  void _showContact() {
    _showComingSoonDialog('お問い合わせ');
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Goal Timer について'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Timer',
              style: TextConsts.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: SpacingConsts.s),
            const Text('バージョン: 1.0.0'),
            const SizedBox(height: SpacingConsts.m),
            const Text(
              '目標達成をサポートするタイマーアプリです。毎日の小さな積み重ねが、大きな成果につながります。',
            ),
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
      builder: (context) => AlertDialog(
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
                final authNotifier = ref.read(authViewModelProvider.notifier);
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
            style: TextButton.styleFrom(
              foregroundColor: ColorConsts.error,
            ),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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