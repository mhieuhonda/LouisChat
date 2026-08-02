class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final String status; // sent | delivered | read
  final DateTime createdAt;
  final DateTime? readAt;
  final String? senderUsername;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.senderUsername,
  });

  factory Message.fromJson(Map<String, dynamic> j) {
    return Message(
      id: j['id'] as String,
      conversationId: j['conversation_id'] as String? ?? '',
      senderId: j['sender_id'] as String? ?? '',
      content: j['content'] as String? ?? '',
      attachmentUrl: j['attachment_url'] as String?,
      status: j['status'] as String? ?? 'sent',
      createdAt: j['created_at'] != null
          ? (DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      readAt: j['read_at'] != null ? DateTime.tryParse(j['read_at'].toString()) : null,
      senderUsername: j['sender_username'] as String?,
    );
  }

  Message copyWith({String? status, DateTime? readAt}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      attachmentUrl: attachmentUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      senderUsername: senderUsername,
    );
  }
}

class Conversation {
  final String id;
  final String type;
  final String? title;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final List<Peer> peers;

  Conversation({
    required this.id,
    required this.type,
    this.title,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.peers = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final peersRaw = (j['peers'] as List?) ?? [];
    return Conversation(
      id: j['id'] as String,
      type: j['type'] as String? ?? 'direct',
      title: j['title'] as String?,
      updatedAt: j['updated_at'] != null
          ? (DateTime.tryParse(j['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      lastMessage: j['last_message'] as String?,
      lastMessageAt: j['last_message_at'] != null
          ? DateTime.tryParse(j['last_message_at'].toString())
          : null,
      peers: peersRaw.map((p) => Peer.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class Peer {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  Peer({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory Peer.fromJson(Map<String, dynamic> j) {
    return Peer(
      id: j['id'] as String,
      username: j['username'] as String? ?? '',
      displayName: j['display_name'] as String? ?? j['username'] as String? ?? '',
      avatarUrl: j['avatar_url'] as String?,
    );
  }
}
