import 'package:flutter/material.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.menu_rounded, size: 34),
                color: Colors.white.withValues(alpha: 0.8),
                disabledColor: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Facey Chat',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 46 * 0.58,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 30),
                color: Colors.white.withValues(alpha: 0.8),
                disabledColor: Colors.white.withValues(alpha: 0.5),
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 30),
                color: Colors.white.withValues(alpha: 0.8),
                disabledColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1D2740).withValues(alpha: 0.95),
                            const Color(0xFF2E3F5B).withValues(alpha: 0.92),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'チャットを開始できます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: 41 * 0.58,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '質問・相談・日々の記録をここでまとめて管理できます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _CircleActionButton(icon: Icons.add_rounded, onPressed: null),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'メッセージを入力',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 21 * 0.58,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: null,
                          icon: const Icon(Icons.mic_none_rounded, size: 32),
                          color: Colors.white.withValues(alpha: 0.76),
                          disabledColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _VoiceActionButton(onPressed: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 38),
          color: Colors.white.withValues(alpha: 0.78),
          disabledColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _VoiceActionButton extends StatelessWidget {
  const _VoiceActionButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            Icons.graphic_eq_rounded,
            size: 34,
            color: const Color(0xFF111824).withValues(alpha: 0.92),
          ),
          disabledColor: const Color(0xFF111824).withValues(alpha: 0.66),
        ),
      ),
    );
  }
}
