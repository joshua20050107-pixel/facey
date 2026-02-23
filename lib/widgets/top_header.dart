import 'package:flutter/material.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({
    super.key,
    required this.title,
    required this.titleStyle,
    this.iconSize = 39,
    this.headerHeight = 52,
    this.showKeke = true,
  });

  final String title;
  final TextStyle titleStyle;
  final double iconSize;
  final double headerHeight;
  final bool showKeke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(right: iconSize + 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
          ),
          if (showKeke)
            Positioned(
              right: 0,
              top: (headerHeight - iconSize) / 2,
              child: GestureDetector(
                onTap: () {},
                child: Image.asset(
                  'assets/images/keke.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
