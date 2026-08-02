import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String get token => _token ?? '';

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('jwt');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('jwt', token);
  }

  Future<void> logout() async {
    _token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('jwt');
    await sp.remove('user');
  }

  String _abs(String path) {
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiUrl}$path';
  }

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ===== Auth =====
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _saveToken(body['token'] as String);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user', jsonEncode(body['user']));
      return body;
    }
    throw ApiException(body['error'] ?? 'register_failed', res.statusCode, body);
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _saveToken(body['token'] as String);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user', jsonEncode(body['user']));
      return body;
    }
    throw ApiException(body['error'] ?? 'login_failed', res.statusCode, body);
  }

  Future<AppUser> me() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiUrl}/api/auth/me'),
      headers: _headers(),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      return AppUser.fromJson(body['user'] as Map<String, dynamic>);
    }
    throw ApiException(body['error'] ?? 'me_failed', res.statusCode, body);
  }

  Future<AppUser> uploadAvatar(String filePath) async {
    final req = http.MultipartRequest(
      'PUT',
      Uri.parse('${AppConfig.apiUrl}/api/auth/avatar'),
    );
    req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    final stream = await req.send();
    final res = await http.Response.fromStream(stream);
    final body = _decode(res);
    if (res.statusCode == 200) {
      final u = AppUser.fromJson(body['user'] as Map<String, dynamic>);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user', jsonEncode(u.toJson()));
      return u;
    }
    throw ApiException(body['error'] ?? 'avatar_failed', res.statusCode, body);
  }

  Future<AppUser> updateProfile({String? displayName, String? bio}) async {
    final res = await http.put(
      Uri.parse('${AppConfig.apiUrl}/api/auth/profile'),
      headers: _headers(),
      body: jsonEncode({'displayName': displayName, 'bio': bio}),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      final u = AppUser.fromJson(body['user'] as Map<String, dynamic>);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user', jsonEncode(u.toJson()));
      return u;
    }
    throw ApiException(body['error'] ?? 'profile_failed', res.statusCode, body);
  }

  // ===== Users =====
  Future<List<AppUser>> searchUsers(String q) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiUrl}/api/users/search?q=${Uri.encodeQueryComponent(q)}'),
      headers: _headers(),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      final list = (body['users'] as List?) ?? [];
      return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException(body['error'] ?? 'search_failed', res.statusCode, body);
  }

  // ===== Conversations / Messages =====
  Future<String> getOrCreateDirectConversation(String peerId) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/messages/conversations/direct'),
      headers: _headers(),
      body: jsonEncode({'peerId': peerId}),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      return body['conversationId'] as String;
    }
    throw ApiException(body['error'] ?? 'conv_failed', res.statusCode, body);
  }

  Future<List<dynamic>> listConversations() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiUrl}/api/messages/conversations'),
      headers: _headers(),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      return (body['conversations'] as List?) ?? [];
    }
    throw ApiException(body['error'] ?? 'conv_list_failed', res.statusCode, body);
  }

  Future<List<dynamic>> listMessages(String conversationId, {String? before, int limit = 50}) async {
    final params = <String, String>{'limit': '$limit'};
    if (before != null) params['before'] = before;
    final uri = Uri.parse(
      '${AppConfig.apiUrl}/api/messages/$conversationId',
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers());
    final body = _decode(res);
    if (res.statusCode == 200) {
      return (body['messages'] as List?) ?? [];
    }
    throw ApiException(body['error'] ?? 'msg_list_failed', res.statusCode, body);
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/messages/$conversationId'),
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );
    final body = _decode(res);
    if (res.statusCode == 201) {
      return body['message'] as Map<String, dynamic>;
    }
    throw ApiException(body['error'] ?? 'msg_send_failed', res.statusCode, body);
  }

  Future<void> markRead(String conversationId) async {
    await http.post(
      Uri.parse('${AppConfig.apiUrl}/api/messages/$conversationId/read'),
      headers: _headers(),
    );
  }

  String resolveAsset(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return _abs(path);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'invalid_response', 'body': res.body};
    }
  }
}

class ApiException implements Exception {
  final String code;
  final int status;
  final Map<String, dynamic> body;
  ApiException(this.code, this.status, this.body);

  @override
  String toString() => 'ApiException($status): $code';
}
