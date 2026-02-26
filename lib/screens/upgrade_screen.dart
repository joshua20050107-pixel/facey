import 'package:flutter/material.dart';

import 'payment_page_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaymentPageScaffold(
      onClose: () => Navigator.of(context).pop(),
      closeAlignment: Alignment.topLeft,
      closePadding: const EdgeInsets.only(left: 8, top: 4),
      closeIcon: const Icon(Icons.close_rounded, size: 34, color: Colors.white),
    );
  }
}
