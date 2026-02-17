import 'package:flutter/material.dart';

import '../widgets/top_header.dart';

class CoachSettingsScreen extends StatelessWidget {
  const CoachSettingsScreen({
    super.key,
    required this.notificationEnabled,
    required this.onNotificationChanged,
  });

  final bool notificationEnabled;
  final ValueChanged<bool> onNotificationChanged;

  @override
  Widget build(BuildContext context) {
    final Color separatorColor = Colors.white.withValues(alpha: 0.1);
    final Color mutedTextColor = Colors.white.withValues(alpha: 0.92);

    Widget settingsRow({
      required IconData icon,
      required String label,
      Widget? trailing,
      bool highlighted = false,
      Color textColor = Colors.white,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFF2A3358).withValues(alpha: 0.75)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: mutedTextColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          const TopHeader(
            title: '設定',
            titleStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                settingsRow(
                  icon: Icons.notifications_none_rounded,
                  label: '通知',
                  trailing: Switch(
                    value: notificationEnabled,
                    onChanged: onNotificationChanged,
                  ),
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.wc_rounded,
                  label: '性別',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GenderScreen(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.star_border_rounded, label: 'アプリを評価'),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.share_outlined, label: 'アプリを共有'),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'プライバシーポリシー',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.description_outlined, label: '利用規約'),
                Divider(height: 1, color: separatorColor),
                settingsRow(icon: Icons.mail_outline_rounded, label: 'お問い合わせ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '性別を選択',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF060911),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const SizedBox.expand(),
    );
  }
}
