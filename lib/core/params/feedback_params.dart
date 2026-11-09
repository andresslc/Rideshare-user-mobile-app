// class FeedbackParam {
//   final String receiverId;
//   final String receiverType;
//   final num stars;
//   final String description;
//   final String rideId;

//   const FeedbackParam({
//     required this.receiverId,
//     required this.receiverType,
//     required this.stars,
//     required this.description,
//     required this.rideId,
//   });
//   Map<String, dynamic> toJson() {
//     return {
//       "receiverId": receiverId,
//       "receiverType": receiverType,
//       "stars": stars,
//       "description": description,
//       "rideId": rideId,
//     };
//   }
// }

class FeedbackParam {
  final String receiverId;
  final String receiverType;
  final num stars;
  final String description;
  final String? rideId;
  final String? carpoolId;

  const FeedbackParam({
    required this.receiverId,
    required this.receiverType,
    required this.stars,
    required this.description,
    this.rideId,
    this.carpoolId,
  });

  Map<String, dynamic> toJson() {
    return {
      "receiverId": receiverId,
      "receiverType": receiverType,
      "stars": stars,
      "description": description,
      if (rideId != null) "rideId": rideId,
      if (carpoolId != null) "carpoolId": carpoolId,
    };
  }
}
