import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class ServerSettingsScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ServerSettingsScreen({super.key, this.isInitialSetup = false});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _apiCtrl;
  late final TextEditingController _socketCtrl;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final api = ApiService();
    _apiCtrl = TextEditingController(text: api.apiUrl);
    _socketCtrl = TextEditingController(text: api.socketUrl);
  }

  @override
  void dispose() {
    _apiCtrl.dispose();
    _socketCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final store = context.read<AppStore>();
    final ok = await store.setServerUrls(
      api: _apiCtrl.text.trim(),
      socket: _socketCtrl.text.trim().isEmpty ? _apiCtrl.text.trim() : _socketCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = ok
          ? 'Đã kết nối thành công! (server v${store.serverVersion})'
          : 'Không kết nối được. Hãy kiểm tra địa chỉ và đảm bảo server đang chạy.';
    });
  }

  Future<void> _save() async {
    final store = context.read<AppStore>();
    await store.setServerUrls(
      api: _apiCtrl.text.trim(),
      socket: _socketCtrl.text.trim().isEmpty ? _apiCtrl.text.trim() : _socketCtrl.text.trim(),
    );
    if (!mounted) return;

    if (widget.isInitialSetup) {
      if (store.currentUser != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reset() async {
    final store = context.read<AppStore>();
    await store.resetServerUrls();
    _apiCtrl.text = ApiService().apiUrl;
    _socketCtrl.text = ApiService().socketUrl;
    setState(() => _testResult = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: MessengerTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text('Cài đặt máy chủ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nhập địa chỉ máy chủ LouisChat mà app sẽ kết nối. '
                        'Ví dụ: http://192.168.1.10:3000 hoặc http://10.0.2.2:3000 (emulator).',
                        style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _apiCtrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ API (HTTP)',
                  hintText: 'http://192.168.1.10:3000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _socketCtrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ WebSocket (để trống = dùng API)',
                  hintText: 'http://192.168.1.10:3000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flash_on),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Kiểm tra kết nối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Mặc định'),
                    ),
                  ),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testOk ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testOk ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testOk ? Icons.check_circle : Icons.error,
                        color: _testOk ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testOk ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MessengerTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text('LƯU & TIẾP TỤC',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'LouisChat v0.2.0',
                  style: TextStyle(color: MessengerTheme.textTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
