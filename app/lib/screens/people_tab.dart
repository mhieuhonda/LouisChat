import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import 'chat_detail_screen.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final ApiService _api = ApiService();
  final _controller = TextEditingController();
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
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
                onChanged: (v) {
                  // debounce
                  _doSearch(v);
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm bạn bè theo tên đăng nhập...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: !_loaded && !_searching
                ? _buildHint()
                : _searching && _results.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? _buildNoResults()
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
                            itemBuilder: (context, i) {
                              final u = _results[i];
                              final online = store.isOnline(u.id) || u.online;
                              final avatar = _api.resolveAsset(u.avatarUrl);
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 64, color: MessengerTheme.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Tìm bạn bè để bắt đầu chat',
            style: TextStyle(color: MessengerTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_dissatisfied, size: 48, color: MessengerTheme.textTertiary),
          const SizedBox(height: 8),
          const Text('Không tìm thấy người dùng',
              style: TextStyle(color: MessengerTheme.textSecondary)),
        ],
      ),
    );
  }
}
