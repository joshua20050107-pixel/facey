import 'package:flutter/material.dart';

import '../widgets/top_header.dart';

class ActivityTabScreen extends StatelessWidget {
  const ActivityTabScreen({
    super.key,
    this.title = '今日のコンディション',
    this.subtitle = '今日のあなたの状態を観測します',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          TopHeader(
            title: title,
            titleStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          Transform.translate(
            offset: const Offset(3, -4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB9C0CF),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
