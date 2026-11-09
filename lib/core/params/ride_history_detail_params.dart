class RideHistoryDetailParams {
  final String id;

  const RideHistoryDetailParams({required this.id});

  Map<String, dynamic> toJson() {
    return {"id": id};
  }
}
