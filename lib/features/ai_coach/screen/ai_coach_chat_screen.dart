import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/agents/coach_agent.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AICoachChatScreen extends ConsumerStatefulWidget {
  const AICoachChatScreen({super.key});

  @override
  ConsumerState<AICoachChatScreen> createState() => _AICoachChatScreenState();
}

class _AICoachChatScreenState extends ConsumerState<AICoachChatScreen> {
  final _messages = <_ChatMessage>[];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final CoachAgent _agent;
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _agent = CoachAgent(aiServiceInstance);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final profile = ref.read(profileNotifierProvider).value;
    if (profile != null) _agent.startSession(profile);

    final greeting = 'Hi! I\'m Aria, your AI morning coach. I\'m here to help with sleep tips, productivity, and building better morning habits. How can I help you today?';
    setState(() {
      _messages.add(_ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()));
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _typing) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _typing = true;
    });
    _scrollToBottom();

    final response = await _agent.sendMessage(text);
    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        _typing = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
            Text('Aria — AI Coach'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const _TypingIndicator();
                return _MessageBubble(msg: _messages[i])
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          _QuickPrompts(onTap: _send),
          _InputBar(ctrl: _ctrl, typing: _typing, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: msg.isUser ? AppColors.primaryGradient : null,
          color: msg.isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aria is thinking', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'Sleep tip for tonight',
      'Plan my morning',
      'I\'m feeling tired',
      'Wake up tips',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(prompts[i], style: const TextStyle(fontSize: 12)),
          onPressed: () => onTap(prompts[i]),
          backgroundColor: AppColors.surfaceVariant,
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.ctrl, required this.typing, required this.onSend});
  final TextEditingController ctrl;
  final bool typing;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              enabled: !typing,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask Aria anything...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onSend(ctrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
