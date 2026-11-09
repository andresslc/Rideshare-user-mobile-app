class CarpoolParam {
  final int page;
  final int limit;
  final String? status;

  CarpoolParam({this.page = 1, this.limit = 10, this.status});

  // toJsone
  Map<String, dynamic> toJson() {
    return {"page": page, "limit": limit};
  }
}
