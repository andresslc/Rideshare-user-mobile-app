import 'message_delivery_status.dart';

/// Single chat message from history or send response / socket.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.contextId,
    this.conversationId,
    this.status = MessageDeliveryStatus.sent,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  /// Ride / booking id when message came from socket (`chat:receive`).
  final String? contextId;

  /// Thread id used by `chat:status_updated`.
  final String? conversationId;

  /// Delivery / read receipt (`sent` | `delivered` | `read`).
  final MessageDeliveryStatus status;

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? createdAt,
    String? contextId,
    String? conversationId,
    MessageDeliveryStatus? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      contextId: contextId ?? this.contextId,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
    );
  }

  /// True if this message should show as "mine" (right side) on the user/passenger app.
  ///
  /// Driver-centric: "to driver" = outgoing, "from driver" = incoming. Does not depend
  /// on [myUserId] so it works even when profile is not loaded.
  bool isOutgoingFromUser(String myUserId, String driverId) {
    final String driver = _norm(driverId);
    final String s = _norm(senderId);
    final String r = _norm(receiverId);

    if (driver.isEmpty) {
      final String me = _norm(myUserId);
      return me.isNotEmpty && s == me;
    }

    if (s == driver) return false;
    if (r == driver) return true;
    if (s.isEmpty && r == driver) return true;
    if (s.isEmpty && r.isNotEmpty) return false;

    final String me = _norm(myUserId);
    if (me.isNotEmpty && s == me) return true;
    if (me.isNotEmpty && s == driver) return false;
    return false;
  }

  static String _norm(String id) => id.trim().toLowerCase();

  static String _extractId(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      return (m['_id'] ?? m['id'] ?? '').toString();
    }
    final s = value.toString().trim();
    return s.isEmpty ? '' : s;
  }

  static ChatMessageModel fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] ?? json['from'];
    final receiver = json['receiver'] ?? json['to'];
    String senderId = _extractId(sender);
    String receiverId = _extractId(receiver);
    final createdAtStr = (json['createdAt'] ?? '').toString();
    final String id = (json['_id'] ?? json['id'] ?? '').toString();
    final String conversationId =
        (json['conversationId'] ?? json['conversation_id'] ?? '')
            .toString()
            .trim();
    final String contextId =
        (json['contextId'] ?? json['context_id'] ?? '').toString().trim();
    return ChatMessageModel(
      id: id.isNotEmpty
          ? id
          : 'tmp-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
      contextId: contextId.isNotEmpty
          ? contextId
          : (conversationId.isNotEmpty ? conversationId : null),
      conversationId: conversationId.isNotEmpty ? conversationId : null,
      status:
          MessageDeliveryStatus.tryParse(json['status']) ??
          MessageDeliveryStatus.sent,
    );
  }
}
