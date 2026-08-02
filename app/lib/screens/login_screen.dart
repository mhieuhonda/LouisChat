import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_store.dart';
import '../utils/theme.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'server_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final store = context.read<AppStore>();
    final ok = await store.login(_identifierCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(store.error ?? 'Đăng nhập thất bại'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: (store.error ?? '').contains('máy chủ')
              ? SnackBarAction(
                  label: 'Cài đặt',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                      );
                    },
                    icon: Icon(
                      store.serverReachable ? Icons.cloud_done : Icons.cloud_off,
                      color: store.serverReachable ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      store.serverReachable ? 'Server OK' : 'Server lỗi',
                      style: TextStyle(
                        fontSize: 12,
                        color: store.serverReachable ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: MessengerTheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LouisChat',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng nhập để tiếp tục',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MessengerTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _identifierCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập hoặc Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
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
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Đang đăng nhập...'),
                            ],
                          )
                        : const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? ',
                        style: TextStyle(color: MessengerTheme.textSecondary)),
                    GestureDetector(
                      onTap: _busy
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: MessengerTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
