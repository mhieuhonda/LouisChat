import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'socket_service.dart';

/// Global app state: current user, auth state, online user map.
class AppStore extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _bootstrapped = false;
  bool get bootstrapped => _bootstrapped;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  final Map<String, bool> _online = {};
  bool isOnline(String userId) => _online[userId] ?? false;

  final ApiService _api = ApiService();

  Future<void> bootstrap() async {
    await _api.init();
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('user');
      if (_api.token.isNotEmpty && raw != null) {
        // Try /me to ensure token still valid
        try {
          _currentUser = await _api.me();
        } catch (_) {
          // fall back to cached user
          _currentUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.login(identifier: identifier, password: password);
      _currentUser = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      SocketService().connect(_api.token);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
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
      SocketService().connect(_api.token);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
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
}
