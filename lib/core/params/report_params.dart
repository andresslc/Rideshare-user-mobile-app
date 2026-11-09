class ReportParam {
  final String entityId;
  final String entityType;
  final String reason;
  // final String description;
  final String supportingEntityId;
  final String supportingEntityType;

  const ReportParam({
    required this.entityId,
    required this.entityType,
    required this.reason,
    // required this.description,
    required this.supportingEntityId,
    required this.supportingEntityType,
  });
  Map<String, dynamic> toJson() {
    return {
      "entityId": entityId,
      "entityType": entityType,
      "reason": reason,
      "description": '',
      "supportingEntityId": supportingEntityId,
      "supportingEntityType": supportingEntityType,
    };
  }
}
