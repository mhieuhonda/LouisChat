import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as sio;

typedef JsonHandler = void Function(Map<String, dynamic>);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  sio.Socket? _socket;
  bool _connected = false;
  bool get isConnected => _connected;

  final Map<String, List<JsonHandler>> _handlers = {
    'message:new': [],
    'typing': [],
    'message:read': [],
    'presence': [],
    'connect': [],
    'disconnect': [],
  };

  void connect(String token, String socketUrl) {
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    _connected = false;

    _socket = sio.io(
      socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      print('[socket] connected');
      _dispatch('connect', {'ok': true});
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      print('[socket] disconnected');
      _dispatch('disconnect', {'ok': false});
    });

    _socket!.onConnectError((err) {
      print('[socket] connect error: $err');
    });

    _socket!.onReconnectAttempt((n) {
      print('[socket] reconnect attempt #$n');
    });

    _socket!.on('message:new', (data) => _dispatch('message:new', data));
    _socket!.on('typing', (data) => _dispatch('typing', data));
    _socket!.on('message:read', (data) => _dispatch('message:read', data));
    _socket!.on('presence', (data) => _dispatch('presence', data));

    _socket!.connect();
  }

  void _dispatch(String event, dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final h in List<JsonHandler>.from(_handlers[event] ?? [])) {
        h(data);
      }
    } else if (data == null) {
      for (final h in List<JsonHandler>.from(_handlers[event] ?? [])) {
        h({'ok': true});
      }
    }
  }

  void on(String event, JsonHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event, JsonHandler handler) {
    _handlers[event]?.remove(handler);
  }

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', conversationId);
  }

  void emitTyping(String conversationId, bool isTyping) {
    _socket?.emit('typing', {'conversationId': conversationId, 'isTyping': isTyping});
  }

  void emitRead(String conversationId) {
    _socket?.emit('message:read', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _handlers.forEach((_, list) => list.clear());
  }
}
