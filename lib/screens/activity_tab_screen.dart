import 'package:flutter/material.dart';

import '../widgets/top_header.dart';

class ActivityTabScreen extends StatelessWidget {
  const ActivityTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          const TopHeader(
            title: '今日のコンディション',
            titleStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          Transform.translate(
            offset: const Offset(3, -4),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '今日のあなたの状態を観測します',
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
