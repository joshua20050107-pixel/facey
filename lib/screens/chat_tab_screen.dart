import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'custom_image_picker_screen.dart';
import 'face_analysis_result_screen.dart';

class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  static const String _fixedAssistantReply =
      'いいですね。まずは睡眠・食事・運動の3つを1週間だけ整えて、変化を記録してみましょう。';
  static const int _maxComposerImages = 5;
  static const TextStyle _userBubbleTextStyle = TextStyle(
    color: Color(0xFF0C1220),
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _composerImages = <XFile>[];
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _handleMessageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isSendEnabled =>
      _messageController.text.trim().isNotEmpty || _composerImages.isNotEmpty;
  bool get _canAddMoreImages => _composerImages.length < _maxComposerImages;

  void _refreshChat() {
    setState(() {
      _messages.clear();
      _messageController.clear();
      _composerImages.clear();
    });
    if (_chatScrollController.hasClients) {
      _chatScrollController.jumpTo(0);
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_canAddMoreImages) return;
    if (kIsWeb) {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 90);
      if (!mounted || picked.isEmpty) return;
      _addPickedFiles(picked);
      return;
    }

    final List<String>? selectedPaths =
        await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            final double maxHeight = MediaQuery.sizeOf(context).height * 0.86;
            return SizedBox(
              height: maxHeight,
              child: CustomImagePickerScreen(
                maxSelection: _maxComposerImages - _composerImages.length,
              ),
            );
          },
        );
    if (!mounted || selectedPaths == null || selectedPaths.isEmpty) return;
    _addPickedFiles(selectedPaths.map((String path) => XFile(path)).toList());
  }

  void _addPickedFiles(List<XFile> picked) {
    if (picked.isEmpty) return;
    final int remaining = _maxComposerImages - _composerImages.length;
    if (remaining <= 0) return;

    final List<XFile> filesToAdd = picked.take(remaining).toList();
    setState(() {
      _composerImages.addAll(filesToAdd);
    });
  }

  void _removeComposerImage(int index) {
    if (index < 0 || index >= _composerImages.length) return;
    setState(() {
      _composerImages.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    final String inputText = _messageController.text.trim();
    final List<String> imagePaths = _composerImages
        .map((XFile file) => file.path)
        .toList();
    if (inputText.isEmpty && imagePaths.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          role: _ChatRole.user,
          text: inputText,
          imagePaths: imagePaths,
        ),
      );
      _messageController.clear();
      _composerImages.clear();
    });
    _scrollChatToBottom();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });

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

  String _heroTagForPath(String path) => 'chat_preview_$path';

  Future<void> _openImageReview(
    List<String> imagePaths, {
    int initialIndex = 0,
  }) async {
    if (imagePaths.isEmpty) return;
    final int safeInitialIndex = initialIndex.clamp(0, imagePaths.length - 1);
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => BackImagePreviewScreen(
              previewImagePaths: imagePaths,
              initialIndex: safeInitialIndex,
              heroTagForPath: _heroTagForPath,
              onWillClose: (_) {},
            ),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildUserImageWrap(_ChatMessage message) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: List<Widget>.generate(message.imagePaths.length, (
        int imageIndex,
      ) {
        final String path = message.imagePaths[imageIndex];
        return GestureDetector(
          onTap: () =>
              _openImageReview(message.imagePaths, initialIndex: imageIndex),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _PreviewImage(path: path, width: 110, height: 110),
          ),
        );
      }),
    );
  }

  Widget _buildUserMessage(_ChatMessage message) {
    Widget buildTextBubble() {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(message.text, style: _userBubbleTextStyle),
        ),
      );
    }

    if (message.imagePaths.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildUserImageWrap(message),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            buildTextBubble(),
          ],
        ],
      );
    }

    return buildTextBubble();
  }

  Widget _buildMessages() {
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
                      MediaQuery.sizeOf(context).width *
                      (isUser
                          ? (message.imagePaths.isNotEmpty ? 0.9 : 0.7)
                          : 0.8),
                ),
                child: isUser
                    ? _buildUserMessage(message)
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

  Widget _buildComposer() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_composerImages.isNotEmpty)
              SizedBox(
                height: 104,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: _composerImages.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final XFile file = _composerImages[index];
                    return SizedBox(
                      width: 92,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _PreviewImage(
                              path: file.path,
                              width: 92,
                              height: 92,
                            ),
                          ),
                          Positioned(
                            top: -5,
                            right: -5,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _removeComposerImage(index),
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Color(0xFF111216),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Stack(
              children: [
                TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: Colors.white.withValues(alpha: 0.85),
                  decoration: InputDecoration(
                    hintText: '質問してみましょう',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.only(
                      left: 12,
                      right: 52,
                      top: 14,
                      bottom: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
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
                        color: _isSendEnabled ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSendEnabled ? _sendMessage : null,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Stack(
          children: [
            Column(
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
                  child: Row(
                    crossAxisAlignment: _composerImages.isNotEmpty
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
                    children: [
                      _CircleActionButton(
                        icon: Icons.add_rounded,
                        onPressed: _canAddMoreImages ? _pickFromGallery : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildComposer()),
                    ],
                  ),
                ),
              ],
            ),
            if (_messages.isEmpty)
              const Positioned.fill(
                top: 52,
                bottom: 118,
                child: IgnorePointer(child: _ChatEmptyStateOverlay()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyStateOverlay extends StatelessWidget {
  const _ChatEmptyStateOverlay();

  @override
  Widget build(BuildContext context) {
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
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.imagePaths = const <String>[],
  });

  final _ChatRole role;
  final String text;
  final List<String> imagePaths;
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
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
