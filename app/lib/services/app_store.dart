import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'socket_service.dart';

/// Global app state: current user, auth state, online user map, server config.
class AppStore extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _bootstrapped = false;
  bool get bootstrapped => _bootstrapped;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String _serverVersion = '';
  String get serverVersion => _serverVersion;

  bool _serverReachable = true;
  bool get serverReachable => _serverReachable;

  final Map<String, bool> _online = {};
  bool isOnline(String userId) => _online[userId] ?? false;

  final ApiService _api = ApiService();

  Future<void> bootstrap() async {
    await _api.init();
    // Test server reachability first
    await checkServer();
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('user');
      if (_api.token.isNotEmpty && raw != null) {
        try {
          _currentUser = await _api.me();
        } catch (_) {
          _currentUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<void> checkServer() async {
    try {
      _serverVersion = await _api.pingServer();
      _serverReachable = true;
    } catch (_) {
      _serverReachable = false;
      _serverVersion = '';
    }
    notifyListeners();
  }

  Future<bool> setServerUrls({required String api, required String socket}) async {
    await _api.setServerUrls(api: api, socket: socket);
    await checkServer();
    return _serverReachable;
  }

  Future<void> resetServerUrls() async {
    await _api.resetServerUrls();
    await checkServer();
  }

  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.login(identifier: identifier, password: password);
      _currentUser = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      SocketService().connect(_api.token, _api.socketUrl);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _loading = false;
      _error = e.viMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Lỗi không xác định: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      SocketService().connect(_api.token, _api.socketUrl);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _loading = false;
      _error = e.viMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = 'Lỗi không xác định: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    SocketService().disconnect();
    await _api.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshMe() async {
    try {
      _currentUser = await _api.me();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateAvatar(String filePath) async {
    try {
      _currentUser = await _api.uploadAvatar(filePath);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? displayName, String? bio}) async {
    try {
      _currentUser = await _api.updateProfile(displayName: displayName, bio: bio);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setPresence(String userId, bool online) {
    if (_online[userId] != online) {
      _online[userId] = online;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
