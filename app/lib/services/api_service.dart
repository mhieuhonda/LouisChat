import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import '../models/user.dart';

/// HTTP timeout for normal requests.
const Duration _kTimeout = Duration(seconds: 12);

/// HTTP timeout for uploads (avatars).
const Duration _kUploadTimeout = Duration(seconds: 30);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  final String _apiUrl = AppConfig.apiUrl;
  final String _socketUrl = AppConfig.socketUrl;

  String get token => _token ?? '';
  String get apiUrl => _apiUrl;
  String get socketUrl => _socketUrl;

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
    return '$_apiUrl$path';
  }

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    h['Accept'] = 'application/json';
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<T> _withTimeout<T>(Future<T> future, {Duration? timeout}) {
    return future.timeout(timeout ?? _kTimeout, onTimeout: () {
      throw ApiException('timeout', 0, {'detail': 'Yêu cầu quá thời gian chờ'});
    });
  }

  // ===== Health check =====
  Future<String> pingServer() async {
    final res = await _withTimeout(
      http.get(Uri.parse('$_apiUrl/api/health'), headers: _headers(json: false)),
    );
    if (res.statusCode == 200) {
      final body = _decode(res);
      return body['version'] as String? ?? 'unknown';
    }
    throw ApiException('server_unreachable', res.statusCode, _decode(res));
  }

  // ===== Auth =====
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _withTimeout(
      http.post(
        Uri.parse('$_apiUrl/api/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      ),
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
    final res = await _withTimeout(
      http.post(
        Uri.parse('$_apiUrl/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'identifier': identifier, 'password': password}),
      ),
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
    final res = await _withTimeout(
      http.get(Uri.parse('$_apiUrl/api/auth/me'), headers: _headers()),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      return AppUser.fromJson(body['user'] as Map<String, dynamic>);
    }
    throw ApiException(body['error'] ?? 'me_failed', res.statusCode, body);
  }

  Future<AppUser> uploadAvatar(String filePath) async {
    final req = http.MultipartRequest('PUT', Uri.parse('$_apiUrl/api/auth/avatar'));
    req.headers['Authorization'] = 'Bearer $_token';
    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    final stream = await _withTimeout(req.send(), timeout: _kUploadTimeout);
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
    final res = await _withTimeout(
      http.put(
        Uri.parse('$_apiUrl/api/auth/profile'),
        headers: _headers(),
        body: jsonEncode({'displayName': displayName, 'bio': bio}),
      ),
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
    final res = await _withTimeout(
      http.get(
        Uri.parse('$_apiUrl/api/users/search?q=${Uri.encodeQueryComponent(q)}'),
        headers: _headers(),
      ),
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
    final res = await _withTimeout(
      http.post(
        Uri.parse('$_apiUrl/api/messages/conversations/direct'),
        headers: _headers(),
        body: jsonEncode({'peerId': peerId}),
      ),
    );
    final body = _decode(res);
    if (res.statusCode == 200) {
      return body['conversationId'] as String;
    }
    throw ApiException(body['error'] ?? 'conv_failed', res.statusCode, body);
  }

  Future<List<dynamic>> listConversations() async {
    final res = await _withTimeout(
      http.get(Uri.parse('$_apiUrl/api/messages/conversations'), headers: _headers()),
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
    final uri = Uri.parse('$_apiUrl/api/messages/$conversationId').replace(queryParameters: params);
    final res = await _withTimeout(http.get(uri, headers: _headers()));
    final body = _decode(res);
    if (res.statusCode == 200) {
      return (body['messages'] as List?) ?? [];
    }
    throw ApiException(body['error'] ?? 'msg_list_failed', res.statusCode, body);
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final res = await _withTimeout(
      http.post(
        Uri.parse('$_apiUrl/api/messages/$conversationId'),
        headers: _headers(),
        body: jsonEncode({'content': content}),
      ),
    );
    final body = _decode(res);
    if (res.statusCode == 201) {
      return body['message'] as Map<String, dynamic>;
    }
    throw ApiException(body['error'] ?? 'msg_send_failed', res.statusCode, body);
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _withTimeout(
        http.post(
          Uri.parse('$_apiUrl/api/messages/$conversationId/read'),
          headers: _headers(),
        ),
      );
    } catch (_) {
      // best-effort
    }
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

  /// Translate error code to Vietnamese user-facing message
  String get viMessage {
    switch (code) {
      case 'timeout':
        return 'Máy chủ không phản hồi. Hãy kiểm tra kết nối mạng.';
      case 'server_unreachable':
        return 'Không kết nối được đến máy chủ. Hãy thử lại sau.';
      case 'user_exists':
        return 'Tên đăng nhập hoặc email đã được sử dụng.';
      case 'user_not_found':
        return 'Không tìm thấy tài khoản. Hãy kiểm tra tên đăng nhập/email.';
      case 'invalid_credentials':
        return 'Mật khẩu không đúng. Vui lòng thử lại.';
      case 'invalid_username':
        return 'Tên đăng nhập chỉ được chứa chữ cái, số, dấu chấm và gạch dưới (3-50 ký tự).';
      case 'invalid_email':
        return 'Email không hợp lệ.';
      case 'password_too_short':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 'missing_fields':
        return 'Vui lòng điền đầy đủ thông tin.';
      case 'rate_limited':
        return 'Bạn đã thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
      case 'too_many_auth_attempts':
        return 'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau 15 phút.';
      case 'only_image_allowed':
        return 'Chỉ được tải lên file ảnh (PNG, JPG, WEBP, GIF).';
      case 'file_too_large':
        return 'File quá lớn. Tối đa 10MB.';
      case 'invalid_token':
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case 'not_a_member':
        return 'Bạn không có quyền truy cập cuộc trò chuyện này.';
      default:
        return 'Đã có lỗi xảy ra ($code). Vui lòng thử lại.';
    }
  }

  @override
  String toString() => 'ApiException($status): $code';
}
