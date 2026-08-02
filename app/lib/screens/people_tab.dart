import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/loading.dart';
import 'chat_detail_screen.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final ApiService _api = ApiService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<AppUser> _results = [];
  bool _searching = false;
  bool _loaded = false;
  String? _error;

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loaded = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      _results = await _api.searchUsers(query);
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.viMessage;
    } catch (e) {
      _error = 'Lỗi: $e';
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onChanged(String v) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _doSearch(v));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
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
        title: const Text('Mọi người',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: MessengerTheme.inputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: 'Tìm bạn bè theo tên đăng nhập...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(store)),
        ],
      ),
    );
  }

  Widget _buildBody(AppStore store) {
    if (!_loaded && !_searching) {
      return const EmptyView(
        icon: Icons.person_search,
        title: 'Tìm bạn bè để bắt đầu chat',
        subtitle: 'Nhập tên đăng nhập ở ô tìm kiếm phía trên.',
      );
    }
    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _results.isEmpty) {
      return ErrorView(message: _error!, onRetry: () => _doSearch(_controller.text));
    }
    if (_results.isEmpty) {
      return const EmptyView(
        icon: Icons.sentiment_dissatisfied,
        title: 'Không tìm thấy người dùng',
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
      itemBuilder: (context, i) {
        final u = _results[i];
        final online = store.isOnline(u.id) || u.online;
        final avatar = _api.resolveAsset(u.avatarUrl);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Avatar(
            imageUrl: avatar,
            name: u.displayName,
            radius: 26,
            online: online,
          ),
          title: Text(u.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('@${u.username}',
              style: const TextStyle(
                  color: MessengerTheme.textSecondary, fontSize: 13)),
          onTap: () async {
            try {
              final convId = await _api.getOrCreateDirectConversation(u.id);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: convId,
                    peerId: u.id,
                    peerName: u.displayName,
                    peerAvatar: avatar,
                  ),
                ),
              );
            } on ApiException catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.viMessage),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
        );
      },
    );
  }
}
