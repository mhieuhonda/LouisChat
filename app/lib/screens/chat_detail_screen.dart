import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../services/socket_service.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/loading.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String peerId;
  final String peerName;
  final String? peerAvatar;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    this.peerAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _peerTyping = false;
  bool _peerOnline = false;
  bool _socketConnected = true;
  Timer? _typingDebounce;
  String? _loadError;

  void _onNewMessage(Map<String, dynamic> payload) {
    final msgJson = payload['message'];
    if (msgJson is Map<String, dynamic>) {
      final msg = Message.fromJson(msgJson);
      if (msg.conversationId == widget.conversationId) {
        setState(() {
          _messages.add(msg);
          _peerTyping = false;
        });
        _scrollToBottom();
        if (msg.senderId == widget.peerId) {
          _api.markRead(widget.conversationId);
          _socket.emitRead(widget.conversationId);
        }
      }
    }
  }

  void _onTyping(Map<String, dynamic> payload) {
    if (payload['conversation_id'] != widget.conversationId) return;
    if (payload['user_id'] != widget.peerId) return;
    setState(() => _peerTyping = payload['isTyping'] == true);
  }

  void _onRead(Map<String, dynamic> payload) {
    if (payload['conversation_id'] != widget.conversationId) return;
    if (payload['reader_id'] != widget.peerId) return;
    setState(() {
      for (var i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].status != 'read') {
          _messages[i] = _messages[i].copyWith(status: 'read');
        } else {
          break;
        }
      }
    });
  }

  void _onPresence(Map<String, dynamic> payload) {
    if (payload['userId'] == widget.peerId) {
      setState(() => _peerOnline = payload['online'] == true);
    }
  }

  void _onSocketConnect(Map<String, dynamic> _) {
    setState(() => _socketConnected = true);
    _socket.joinConversation(widget.conversationId);
  }

  void _onSocketDisconnect(Map<String, dynamic> _) {
    setState(() => _socketConnected = false);
  }

  @override
  void initState() {
    super.initState();
    _socket.on('message:new', _onNewMessage);
    _socket.on('typing', _onTyping);
    _socket.on('message:read', _onRead);
    _socket.on('presence', _onPresence);
    _socket.on('connect', _onSocketConnect);
    _socket.on('disconnect', _onSocketDisconnect);
    _socket.joinConversation(widget.conversationId);
    _socketConnected = _socket.isConnected;
    _loadMessages();
  }

  @override
  void dispose() {
    _socket.off('message:new', _onNewMessage);
    _socket.off('typing', _onTyping);
    _socket.off('message:read', _onRead);
    _socket.off('presence', _onPresence);
    _socket.off('connect', _onSocketConnect);
    _socket.off('disconnect', _onSocketDisconnect);
    _socket.leaveConversation(widget.conversationId);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await _api.listMessages(widget.conversationId);
      _messages
        ..clear()
        ..addAll(list.map((e) => Message.fromJson(e as Map<String, dynamic>)));
      await _api.markRead(widget.conversationId);
      _socket.emitRead(widget.conversationId);
      _scrollToBottom();
    } on ApiException catch (e) {
      _loadError = e.viMessage;
    } catch (e) {
      _loadError = 'Lỗi: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    _stopTyping();
    try {
      final msgJson = await _api.sendMessage(widget.conversationId, text);
      final msg = Message.fromJson(msgJson);
      setState(() {
        _messages.add(msg);
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.viMessage),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onInputChanged(String v) {
    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    _socket.emitTyping(widget.conversationId, true);
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      _socket.emitTyping(widget.conversationId, false);
    });
  }

  void _stopTyping() {
    _typingDebounce?.cancel();
    _socket.emitTyping(widget.conversationId, false);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _shouldShowDateSeparator(int i) {
    if (i == 0) return true;
    final prev = _messages[i - 1].createdAt;
    final curr = _messages[i].createdAt;
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MessengerTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              imageUrl: widget.peerAvatar,
              name: widget.peerName,
              radius: 18,
              online: _peerOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MessengerTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      if (!_socketConnected) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Đang kết nối lại...',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ] else if (_peerTyping) ...[
                        const Text(
                          'đang gõ...',
                          style: TextStyle(fontSize: 12, color: MessengerTheme.primary),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _peerOnline ? MessengerTheme.online : MessengerTheme.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _peerOnline ? 'Đang hoạt động' : 'Không hoạt động',
                          style: TextStyle(
                            fontSize: 12,
                            color: _peerOnline
                                ? MessengerTheme.primary
                                : MessengerTheme.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: MessengerTheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gọi điện sẽ có ở phiên bản sau')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: MessengerTheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call sẽ có ở phiên bản sau')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null && _messages.isEmpty
                    ? ErrorView(message: _loadError!, onRetry: _loadMessages)
                    : _messages.isEmpty
                        ? _buildEmptyChat()
                        : GestureDetector(
                            onTap: () => FocusScope.of(context).unfocus(),
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: _messages.length + (_peerTyping ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (_peerTyping && i == _messages.length) {
                                  return _buildTypingBubble();
                                }
                                final m = _messages[i];
                                final showDate = _shouldShowDateSeparator(i);
                                return Column(
                                  children: [
                                    if (showDate) _buildDateSeparator(m.createdAt),
                                    _buildBubble(m, me != null && m.senderId == me.id),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MessengerTheme.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _dateLabel(dt),
        style: const TextStyle(
          color: MessengerTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(imageUrl: widget.peerAvatar, name: widget.peerName, radius: 44),
          const SizedBox(height: 12),
          Text(widget.peerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Hãy gửi lời chào đầu tiên!',
              style: TextStyle(color: MessengerTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBubble(Message m, bool mine) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = mine ? MessengerTheme.bubbleMine : MessengerTheme.bubbleTheirs;
    final fg = mine ? MessengerTheme.bubbleMineText : MessengerTheme.bubbleTheirsText;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: mine ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: mine ? const Radius.circular(4) : const Radius.circular(18),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                Avatar(imageUrl: widget.peerAvatar, name: widget.peerName, radius: 14),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: bg, borderRadius: radius),
                  child: Text(
                    m.content,
                    style: TextStyle(color: fg, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              left: mine ? 0 : 34,
              right: mine ? 4 : 0,
            ),
            child: Row(
              mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(m.createdAt),
                  style: const TextStyle(
                    color: MessengerTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    m.status == 'read' ? Icons.done_all : Icons.done,
                    size: 13,
                    color: m.status == 'read'
                        ? MessengerTheme.primary
                        : MessengerTheme.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Avatar(imageUrl: widget.peerAvatar, name: widget.peerName, radius: 14),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: MessengerTheme.bubbleTheirs,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: _DotAnimation(delay: i * 0.2),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MessengerTheme.divider, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: MessengerTheme.primary, size: 32),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đính kèm ảnh/video sẽ có ở v0.3')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined,
                  color: MessengerTheme.primary, size: 26),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera sẽ có ở v0.3')),
                );
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MessengerTheme.inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        onChanged: _onInputChanged,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Aa',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            _sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _inputCtrl.text.trim().isEmpty ? Icons.mic : Icons.send,
                      color: MessengerTheme.primary,
                      size: 26,
                    ),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final double delay;
  const _DotAnimation({required this.delay});
  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation> with TickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: MessengerTheme.textTertiary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
