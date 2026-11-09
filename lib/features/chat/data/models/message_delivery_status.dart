/// Delivery / read receipt for an outbound chat message.
enum MessageDeliveryStatus {
  sent,
  delivered,
  read;

  int get rank => index;

  bool get isRead => this == read;

  /// Single tick for [sent], double for [delivered] / [read].
  bool get isDoubleTick => this == delivered || this == read;

  static MessageDeliveryStatus? tryParse(dynamic raw) {
    if (raw == null) return null;
    switch (raw.toString().trim().toLowerCase()) {
      case 'sent':
        return sent;
      case 'delivered':
        return delivered;
      case 'read':
        return read;
      default:
        return null;
    }
  }

  /// Prefer the higher of [current] and [incoming] (never downgrade).
  static MessageDeliveryStatus upgrade(
    MessageDeliveryStatus current,
    MessageDeliveryStatus incoming,
  ) {
    return incoming.rank >= current.rank ? incoming : current;
  }
}

/// Payload from `chat:status_updated` (sender-side receipt updates).
class ChatStatusUpdate {
  const ChatStatusUpdate({
    required this.conversationId,
    required this.status,
    this.updatedBy,
    this.messageId,
  });

  final String conversationId;
  final MessageDeliveryStatus status;
  final String? updatedBy;
  final String? messageId;

  static ChatStatusUpdate? fromJson(Map<String, dynamic> json) {
    final String conversationId =
        (json['conversationId'] ?? json['conversation_id'] ?? '')
            .toString()
            .trim();
    final MessageDeliveryStatus? status = MessageDeliveryStatus.tryParse(
      json['status'],
    );
    if (conversationId.isEmpty || status == null) return null;

    final String messageId =
        (json['messageId'] ??
                json['message_id'] ??
                json['_id'] ??
                json['id'] ??
                '')
            .toString()
            .trim();
    final String updatedBy =
        (json['updatedBy'] ?? json['updated_by'] ?? '').toString().trim();

    return ChatStatusUpdate(
      conversationId: conversationId,
      status: status,
      updatedBy: updatedBy.isEmpty ? null : updatedBy,
      messageId: messageId.isEmpty ? null : messageId,
    );
  }
}
