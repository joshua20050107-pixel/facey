import 'package:flutter/material.dart';

import '../main.dart';
import 'payment_page_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  Widget build(BuildContext context) {
    return PaymentPageScaffold(
      onClose: () {
        if (fromSettings) {
          Navigator.of(context).pop();
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (BuildContext context, _, __) => const HomeScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      },
      closeAlignment: Alignment.topLeft,
      closePadding: const EdgeInsets.only(left: 8, top: 4),
      closeIcon: const Icon(Icons.close_rounded, size: 34, color: Colors.white),
    );
  }
}
