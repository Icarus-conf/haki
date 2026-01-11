import 'dart:io';

import 'package:chat_mobile/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/typing_indicator_bubble.dart';
import '../widgets/loading_indicator.dart';

class ChatView extends StatefulWidget {
  final bool isEmbedded;
  const ChatView({super.key, this.isEmbedded = false});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  String? _pendingAttachmentPath;
  MessageModel? _replyToMessage;

  @override
  void initState() {
    super.initState();

    // Listen to focus changes for typing indicator
    _focusNode.addListener(() {
      final chat = context.read<ChatProvider>();
      if (_focusNode.hasFocus) {
        // Keyboard opened - user is typing
        chat.sendTypingNotification(true);
      } else {
        // Keyboard closed - stopped typing
        chat.sendTypingNotification(false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _pendingAttachmentPath != null) {
      context.read<ChatProvider>().sendMessage(
        text,
        attachmentPath: _pendingAttachmentPath,
        replyToMessageId: _replyToMessage?.id,
        replyToSender: _replyToMessage?.sender,
        replyToMessage: _replyToMessage?.message,
      );
      _controller.clear();
      setState(() {
        _pendingAttachmentPath = null;
        _replyToMessage = null;
      });
      // Unfocus to close keyboard and stop typing indicator
      _focusNode.unfocus();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pendingAttachmentPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final recipient = chat.activeRecipient;
    final messages = chat.messages;
    final reversedMsgs = messages.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFf3f4f6),
      appBar: ChatAppBar(
        recipient: recipient,
        isRecipientTyping: chat.isRecipientTyping,
        onlineUserIds: chat.onlineUserIds,
        isEmbedded: widget.isEmbedded,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          image: chat.chatWallpaper != null
              ? DecorationImage(
                  image: FileImage(File(chat.chatWallpaper!)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: chat.isDarkMode ? 0.6 : 0.2),
                    BlendMode.darken,
                  ),
                )
              : null,
          gradient: chat.chatWallpaper == null && chat.isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF0F172A), // Deep Midnight
                  ],
                )
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: chat.isHistoryLoading
                  ? const LoadingIndicator()
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: reversedMsgs.length,
                      itemBuilder: (context, index) {
                        final m = reversedMsgs[index];
                        final isMe = m.senderId == chat.me?.id;
                        // In reverse, index + 1 is the message ABOVE (older)
                        final isFollowing =
                            index < reversedMsgs.length - 1 &&
                            reversedMsgs[index + 1].senderId == m.senderId;

                        return Dismissible(
                          key: Key('msg_${m.id ?? m.tempId ?? index}'),
                          direction: isMe
                              ? DismissDirection.endToStart
                              : DismissDirection.startToEnd,
                          confirmDismiss: (direction) async {
                            setState(() {
                              _replyToMessage = m;
                            });
                            _focusNode.requestFocus();
                            return false; // Don't actually dismiss
                          },
                          background: Container(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            padding: EdgeInsets.only(left: isMe ? 0 : 20, right: isMe ? 20 : 0),
                            child: Icon(
                              Icons.reply,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                          ),
                          child: MessageBubble(message: m, isMe: isMe, isFollowing: isFollowing),
                        );
                      },
                    ),
            ),
            // Typing Indicator
            if (chat.isRecipientTyping) TypingIndicatorBubble(recipient: recipient),
            ChatInput(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _send,
              onAttachment: _pickImage,
              onVoiceStop: (path) {
                context.read<ChatProvider>().sendMessage('', attachmentPath: path);
                _focusNode.unfocus(); // Close keyboard after voice message
              },
              onVoiceCancel: () {},
              pendingAttachmentUrl: _pendingAttachmentPath,
              onCancelAttachment: () {
                setState(() {
                  _pendingAttachmentPath = null;
                });
              },
              replyToMessage: _replyToMessage,
              onCancelReply: () {
                setState(() {
                  _replyToMessage = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
