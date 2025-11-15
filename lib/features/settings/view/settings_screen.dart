import 'package:flutter/material.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/animation_consts.dart';
import '../../../core/widgets/setting_item.dart';
import '../../../core/widgets/pressable_card.dart';

/// 設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

              // アプリ設定
              _buildAppSection(),

              const SizedBox(height: SpacingConsts.l),

              // データとプライバシー
              _buildDataSection(),

              const SizedBox(height: SpacingConsts.l),

              // サポート
              _buildSupportSection(),

              const SizedBox(height: SpacingConsts.l),
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
      onTap: null,
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
                  'ゲストユーザー',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showTimerSettings() {
    _showComingSoonDialog('タイマー設定');
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
      builder: (context) => AlertDialog(
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
