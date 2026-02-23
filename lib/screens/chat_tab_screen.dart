import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  static const MethodChannel _hapticChannel = MethodChannel('facey/haptics');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _inputScrollController = ScrollController();
  bool _showOverflowScrollbar = false;
  bool _didTriggerScrollbarGrabHaptic = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
    _inputScrollController.addListener(_handleInputScrolled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollbarVisibility();
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _inputScrollController.removeListener(_handleInputScrolled);
    _messageController.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  void _handleMessageChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollbarVisibility();
    });
  }

  void _handleInputScrolled() {
    _updateScrollbarVisibility();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateScrollbarVisibility() {
    if (!mounted || !_inputScrollController.hasClients) return;
    final bool shouldShow = _inputScrollController.position.maxScrollExtent > 0;
    if (shouldShow != _showOverflowScrollbar) {
      setState(() {
        _showOverflowScrollbar = shouldShow;
      });
    }
  }

  void _triggerScrollbarGrabHaptic() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _hapticChannel.invokeMethod<void>('softImpact').catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Facey Chat',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 24,
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(5, 4),
                    child: IconButton(
                      onPressed: null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 58,
                        minHeight: 58,
                      ),
                      icon: Image.asset(
                        'assets/images/manto.png',
                        width: 37,
                        height: 37,
                        color: const Color.fromARGB(255, 215, 214, 214),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      color: Colors.white.withValues(alpha: 0.8),
                      disabledColor: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
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
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '外見の改善や戦略を相談',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.94),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '改善点やこれからの行動・気になることを\n相談してみてください',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.56),
                          fontSize: 13,
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
              padding: const EdgeInsets.only(bottom: 2),
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: Row(
                  children: [
                    _CircleActionButton(
                      icon: Icons.add_rounded,
                      onPressed: null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 168,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Builder(
                                builder: (BuildContext scrollbarContext) =>
                                    Listener(
                                      behavior: HitTestBehavior.translucent,
                                      onPointerDown: (PointerDownEvent event) {
                                        if (_didTriggerScrollbarGrabHaptic ||
                                            !_showOverflowScrollbar ||
                                            !_inputScrollController
                                                .hasClients) {
                                          return;
                                        }
                                        final double maxExtent =
                                            _inputScrollController
                                                .position
                                                .maxScrollExtent;
                                        if (maxExtent <= 0) return;
                                        final RenderBox? box =
                                            scrollbarContext.findRenderObject()
                                                as RenderBox?;
                                        final double fieldWidth =
                                            box?.size.width ?? 0;
                                        if (fieldWidth <= 0) return;
                                        if (event.localPosition.dx >=
                                            fieldWidth - 24) {
                                          _didTriggerScrollbarGrabHaptic = true;
                                          _triggerScrollbarGrabHaptic();
                                        }
                                      },
                                      onPointerUp: (_) {
                                        _didTriggerScrollbarGrabHaptic = false;
                                      },
                                      onPointerCancel: (_) {
                                        _didTriggerScrollbarGrabHaptic = false;
                                      },
                                      child: RawScrollbar(
                                        controller: _inputScrollController,
                                        thumbVisibility: _showOverflowScrollbar,
                                        interactive: true,
                                        thickness: 4,
                                        radius: const Radius.circular(999),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 6,
                                        minThumbLength: 12,
                                        thumbColor: Colors.white.withValues(
                                          alpha: 0.68,
                                        ),
                                        child: TextField(
                                          controller: _messageController,
                                          scrollController:
                                              _inputScrollController,
                                          minLines: 1,
                                          maxLines: 5,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          cursorColor: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'メッセージを入力',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.45,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  left: 12,
                                                  right: 52,
                                                  top: 14,
                                                  bottom: 14,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                              Positioned(
                                right: 12,
                                bottom: 8,
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 23,
                                        color: Colors.white,
                                      ),
                                      disabledColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          color: Colors.white.withValues(alpha: 0.78),
          disabledColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
