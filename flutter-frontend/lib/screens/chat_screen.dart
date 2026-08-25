import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();
  bool _atBottom    = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final max = _scrollCtrl.position.maxScrollExtent;
    _atBottom = _scrollCtrl.offset >= max - 80;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (animated) {
      _scrollCtrl.animateTo(max,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollCtrl.jumpTo(max);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AppProvider>().sendUserMessage(text);
    Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
  }

  void _reset() {
    context.read<AppProvider>()
      ..clearMessages()
      ..setStep(AppStep.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SikanuaTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: SikanuaLogo(size: 36),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SIKANUA',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 14)),
              Text('Nutrition & Fitness AI',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: SikanuaTheme.ink.withOpacity(0.45))),
            ],
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: SikanuaTheme.border),
        ),
        actions: [
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: SikanuaTheme.forest),
            label: const Text('New Plan',
                style: TextStyle(
                    color: SikanuaTheme.forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // Auto-scroll when streaming
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.streaming && _atBottom) {
              _scrollToBottom(animated: false);
            }
          });

          return Column(
            children: [
              // Messages list
              Expanded(
                child: provider.messages.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: provider.messages.length +
                            (provider.streaming &&
                                    provider.messages.isNotEmpty &&
                                    provider.messages.last.role ==
                                        MessageRole.assistant &&
                                    provider.messages.last.content.isEmpty
                                ? 1
                                : 0),
                        itemBuilder: (ctx, i) {
                          if (i == provider.messages.length) {
                            return _typingBubble();
                          }
                          return _MessageTile(msg: provider.messages[i]);
                        },
                      ),
              ),

              // Error banner
              if (provider.error != null)
                _ErrorBanner(
                  message: provider.error!,
                  onDismiss: () =>
                      context.read<AppProvider>().clearMessages(),
                ),

              // Input bar
              _InputBar(
                controller: _controller,
                focusNode: _focusNode,
                streaming: provider.streaming,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SikanuaLogo(size: 56),
              const SizedBox(height: 16),
              Text('Generating your plan…',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const TypingDots(),
            ],
          ),
        ),
      );

  Widget _typingBubble() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Avatar(role: MessageRole.assistant),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: SikanuaTheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: SikanuaTheme.border),
              ),
              child: const TypingDots(),
            ),
          ],
        ),
      );
}

// ── Message tile ──────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final ChatMessage msg;
  const _MessageTile({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _Avatar(role: msg.role),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? SikanuaTheme.forest : SikanuaTheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: SikanuaTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        msg.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      )
                    : _MarkdownBody(content: msg.content),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _Avatar(role: msg.role),
          ],
        ],
      ),
    );
  }
}

// ── Markdown renderer ─────────────────────────────────────────────────────────

class _MarkdownBody extends StatelessWidget {
  final String content;
  const _MarkdownBody({required this.content});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SikanuaTheme.forest,
          height: 1.4,
        ),
        h2: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: SikanuaTheme.forest,
          height: 1.4,
        ),
        h3: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SikanuaTheme.ink,
          height: 1.4,
        ),
        p: const TextStyle(
          fontSize: 13,
          color: SikanuaTheme.ink,
          height: 1.6,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: SikanuaTheme.ink),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: const TextStyle(fontSize: 13, color: SikanuaTheme.forest),
        tableHead: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        tableBody: const TextStyle(fontSize: 12, color: SikanuaTheme.ink),
        tableHeadAlign: TextAlign.left,
        tableBorder: TableBorder.all(
          color: SikanuaTheme.border,
          width: 1,
        ),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tableHeadDecoration:
            const BoxDecoration(color: SikanuaTheme.forest),
        code: TextStyle(
          fontSize: 11,
          backgroundColor: SikanuaTheme.forestLight,
          color: SikanuaTheme.forestDark,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: SikanuaTheme.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: SikanuaTheme.border, width: 1),
          ),
        ),
        blockquoteDecoration: BoxDecoration(
          color: SikanuaTheme.forestLight,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: SikanuaTheme.forest, width: 3),
          ),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final MessageRole role;
  const _Avatar({required this.role});

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? SikanuaTheme.forestLight : SikanuaTheme.forest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.spa_rounded,
        size: 16,
        color: isUser ? SikanuaTheme.forest : Colors.white,
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connection error',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        fontSize: 12)),
                Text(message,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: Colors.red,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool streaming;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.streaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SikanuaTheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: SikanuaTheme.border),
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !streaming,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                        fontSize: 14, color: SikanuaTheme.ink),
                    decoration: InputDecoration(
                      hintText: 'Ask about your plan…',
                      hintStyle: TextStyle(
                          color: SikanuaTheme.ink.withOpacity(0.35),
                          fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: SikanuaTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: SikanuaTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: SikanuaTheme.forest, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: SikanuaTheme.background,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: streaming
                        ? SikanuaTheme.border
                        : SikanuaTheme.forest,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: streaming ? null : onSend,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: streaming
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      SikanuaTheme.forest),
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Powered by PyTorch · Not a substitute for medical advice',
              style: TextStyle(
                  fontSize: 10,
                  color: SikanuaTheme.ink.withOpacity(0.3)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
