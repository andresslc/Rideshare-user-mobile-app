class CarpoolDetailParams {
  final String id;

  const CarpoolDetailParams({required this.id});

  Map<String, dynamic> toJson() {
    return {"id": id};
  }
}
