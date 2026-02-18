import 'package:flutter/material.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/メス.png', fit: BoxFit.cover),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 34),
                  color: Colors.white,
                  tooltip: '閉じる',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
