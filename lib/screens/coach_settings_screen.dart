import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/top_header.dart';
import '../widgets/yomu_gender_two_choice.dart';

class CoachSettingsScreen extends StatelessWidget {
  const CoachSettingsScreen({
    super.key,
    required this.notificationEnabled,
    required this.onNotificationChanged,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  final bool notificationEnabled;
  final ValueChanged<bool> onNotificationChanged;
  final YomuGender selectedGender;
  final ValueChanged<YomuGender> onGenderChanged;
  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://mercury-ixora-4df.notion.site/30ab9bad745580b89262d3bead931a6b',
  );
  static final Uri _termsUrl = Uri.parse(
    'https://mercury-ixora-4df.notion.site/Facey-30ab9bad745580b78192d675b7fa6b1b',
  );
  static final Uri _contactMailUri = Uri(
    scheme: 'mailto',
    path: 'contactfacey@ymail.ne.jp',
    queryParameters: <String, String>{'subject': 'Facey お問い合わせ'},
  );

  @override
  Widget build(BuildContext context) {
    final Color separatorColor = Colors.white.withValues(alpha: 0.1);
    final Color mutedTextColor = Colors.white.withValues(alpha: 0.92);
    const Color luxuryPurple = Color(0xFF7A4CFF);
    const Color luxuryPurpleDark = Color(0xFF5D33D6);
    final InAppReview inAppReview = InAppReview.instance;

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
                    activeColor: Colors.white,
                    activeTrackColor: luxuryPurple,
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.92),
                    inactiveTrackColor: luxuryPurpleDark.withValues(alpha: 0.32),
                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return luxuryPurple.withValues(alpha: 0.9);
                      }
                      return Colors.white.withValues(alpha: 0.16);
                    }),
                  ),
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'アップグレード',
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.wc_rounded,
                  label: '性別',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GenderScreen(
                          selectedGender: selectedGender,
                          onGenderChanged: onGenderChanged,
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.star_border_rounded,
                  label: 'アプリを評価',
                  onTap: () async {
                    try {
                      await inAppReview.requestReview();
                    } on MissingPluginException {
                      // Unsupported platform or plugin not linked in this runtime.
                    } on PlatformException {
                      // Request review failed on current platform/runtime.
                    }
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.share_outlined,
                  label: 'アプリを共有',
                  onTap: () {
                    Share.share(
                      'Faceyを使ってみてください！\nhttps://mercury-ixora-4df.notion.site/Facey-30ab9bad745580b78192d675b7fa6b1b',
                      subject: 'Faceyを共有',
                    );
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'プライバシーポリシー',
                  onTap: () async {
                    await launchUrl(
                      _privacyPolicyUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.description_outlined,
                  label: '利用規約',
                  onTap: () async {
                    await launchUrl(
                      _termsUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                Divider(height: 1, color: separatorColor),
                settingsRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'お問い合わせ',
                  onTap: () async {
                    await launchUrl(_contactMailUri);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GenderScreen extends StatelessWidget {
  const GenderScreen({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  final YomuGender selectedGender;
  final ValueChanged<YomuGender> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '性別を選択',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0C10), Color(0xFF1A2230), Color(0xFF2E3F5B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: YomuGenderTwoChoice(
            showTitle: true,
            title: 'あなたの性別を\n選択してください',
            wholeOffset: Offset(0, 28),
            titleStyle: TextStyle(
              color: const Color.fromARGB(255, 212, 212, 212),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            initialValue: selectedGender,
            onChanged: onGenderChanged,
          ),
        ),
      ),
    );
  }
}
