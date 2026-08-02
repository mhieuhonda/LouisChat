import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/loading.dart';
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
  bool _refreshing = false;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    // Lightweight polling as a safety net alongside socket realtime.
    _poller = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        if (_convs.isEmpty) {
          _loading = true;
        } else {
          _refreshing = true;
        }
        _error = null;
      });
    }
    try {
      final list = await _api.listConversations();
      _convs = list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.viMessage;
    } catch (e) {
      _error = 'Lỗi: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
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
            if (_refreshing)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.search, color: MessengerTheme.primary),
              onPressed: () {
                // Switch to People tab — handled via IndexStack
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mở tab "Mọi người" để tìm bạn bè'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: MessengerTheme.primary,
        onRefresh: _load,
        child: _buildBody(store),
      ),
    );
  }

  Widget _buildBody(AppStore store) {
    if (_loading && _convs.isEmpty) {
      return const ChatListSkeleton();
    }
    if (_error != null && _convs.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          ErrorView(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_convs.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          EmptyView(
            icon: Icons.forum_outlined,
            title: 'Chưa có cuộc trò chuyện nào',
            subtitle: 'Mở tab "Mọi người" để tìm bạn bè và bắt đầu chat.',
          ),
        ],
      );
    }
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
}
