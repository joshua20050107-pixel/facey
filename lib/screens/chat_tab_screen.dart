import 'dart:async';

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
  static const String _fixedAssistantReply =
      'いいですね。まずは睡眠・食事・運動の3つを1週間だけ整えて、変化を記録してみましょう。';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _inputScrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
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
    _chatScrollController.dispose();
    super.dispose();
  }

  void _handleMessageChanged() {
    if (mounted) {
      setState(() {});
    }
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

  bool get _isSendEnabled => _messageController.text.trim().isNotEmpty;

  void _refreshChat() {
    setState(() {
      _messages.clear();
      _messageController.clear();
    });
    if (_chatScrollController.hasClients) {
      _chatScrollController.jumpTo(0);
    }
  }

  Future<void> _sendMessage() async {
    final String inputText = _messageController.text.trim();
    if (inputText.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: inputText));
      _messageController.clear();
    });
    _scrollChatToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() {
      _messages.add(
        const _ChatMessage(
          role: _ChatRole.assistant,
          text: _fixedAssistantReply,
        ),
      );
    });
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _chatScrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        final _ChatMessage message = _messages[index];
        final bool isUser = message.role == _ChatRole.user;
        final bool hasPrevious = index > 0;
        final bool roleChanged =
            hasPrevious && _messages[index - 1].role != message.role;
        final double topSpacing = index == 0
            ? 6
            : roleChanged
            ? 18
            : 8;
        return Padding(
          padding: EdgeInsets.only(top: topSpacing),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.sizeOf(context).width * (isUser ? 0.7 : 0.8),
                ),
                child: isUser
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: Color(0xFF0C1220),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
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
                      onPressed: _refreshChat,
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
            Expanded(child: _buildMessages()),
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
                                    decoration: BoxDecoration(
                                      color: _isSendEnabled
                                          ? Colors.white
                                          : Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: _isSendEnabled
                                          ? _sendMessage
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 23,
                                        color: _isSendEnabled
                                            ? const Color(0xFF0D1524)
                                            : Colors.white,
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

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _ChatRole role;
  final String text;
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
