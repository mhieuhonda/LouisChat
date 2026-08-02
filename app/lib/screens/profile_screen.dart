import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/avatar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _uploading = true);
    final store = context.read<AppStore>();
    await store.updateAvatar(x.path);
    if (mounted) {
      setState(() => _uploading = false);
      if (store.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(store.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    await store.updateProfile(
      displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
      if (store.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(store.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để sử dụng LouisChat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final store = context.read<AppStore>();
    await store.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final user = store.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_editing) {
      _nameCtrl.text = user.displayName;
      _bioCtrl.text = user.bio ?? '';
    }

    final avatarUrl = _api.resolveAsset(user.avatarUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Hồ sơ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: MessengerTheme.primary),
            onPressed: () => setState(() => _editing = true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploading ? null : _pickAvatar,
              child: Stack(
                children: [
                  Avatar(imageUrl: avatarUrl, name: user.displayName, radius: 56),
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  if (!_uploading)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: MessengerTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text('@${user.username}',
                style: const TextStyle(color: MessengerTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            if (_editing) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tiểu sử',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                                _editing = false;
                                _nameCtrl.text = user.displayName;
                                _bioCtrl.text = user.bio ?? '';
                              }),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MessengerTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MessengerTheme.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(user.bio!,
                      style: const TextStyle(fontSize: 14, color: MessengerTheme.textPrimary)),
                ),
                const SizedBox(height: 16),
              ],
              _buildInfoTile(Icons.alternate_email, '@${user.username}', 'Tên đăng nhập'),
              _buildInfoTile(Icons.email_outlined, user.email, 'Email'),
              if (user.createdAt != null)
                _buildInfoTile(
                  Icons.calendar_today_outlined,
                  '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                  'Ngày tham gia',
                ),
              const Divider(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: _confirmLogout,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'LouisChat v0.3.0',
              style: TextStyle(color: MessengerTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: MessengerTheme.primary),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(label, style: const TextStyle(color: MessengerTheme.textTertiary, fontSize: 12)),
    );
  }
}
