class NotificationParams {
  final int page;
  final int limit;

  NotificationParams({this.page = 1, this.limit = 10});

  Map<String, dynamic> toJson() {
    return {
      "page": page,
      "limit": limit,
    };
  }
}