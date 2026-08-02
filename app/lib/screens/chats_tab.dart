import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import 'chat_detail_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final ApiService _api = ApiService();
  List<Conversation> _convs = [];
  bool _loading = true;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    // Lightweight polling as a safety net alongside socket realtime.
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final list = await _api.listConversations();
      _convs = list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Text(
              'Chats',
              style: TextStyle(
                color: MessengerTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _load(),
              child: CircleAvatar(
                backgroundColor: MessengerTheme.inputBg,
                child: Icon(Icons.edit, color: MessengerTheme.primary, size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: MessengerTheme.primary,
        onRefresh: _load,
        child: _loading && _convs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _convs.isEmpty
                ? _buildError()
                : _convs.isEmpty
                    ? _buildEmpty()
                    : _buildList(store),
      ),
    );
  }

  Widget _buildList(AppStore store) {
    return ListView.separated(
      itemCount: _convs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 86),
      itemBuilder: (context, i) {
        final c = _convs[i];
        final peer = c.peers.isNotEmpty ? c.peers.first : null;
        final name = peer?.displayName ?? peer?.username ?? c.title ?? 'Conversation';
        final avatarUrl = _api.resolveAsset(peer?.avatarUrl);
        final online = store.isOnline(peer?.id ?? '');
        final last = c.lastMessage ?? 'Hãy bắt đầu trò chuyện!';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Avatar(imageUrl: avatarUrl, name: name, radius: 28, online: online),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: MessengerTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Text(
            _formatTime(c.lastMessageAt ?? c.updatedAt),
            style: TextStyle(color: MessengerTheme.textTertiary, fontSize: 11),
          ),
          onTap: () async {
            if (peer == null) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  conversationId: c.id,
                  peerId: peer.id,
                  peerName: name,
                  peerAvatar: avatarUrl,
                ),
              ),
            );
            _load(silent: true);
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.forum_outlined, size: 64, color: MessengerTheme.textTertiary),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(color: MessengerTheme.textSecondary, fontSize: 15),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Mở tab "Mọi người" để tìm bạn bè.',
            style: TextStyle(color: MessengerTheme.textTertiary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Không tải được danh sách chat',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton(
            onPressed: _load,
            child: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }
}
