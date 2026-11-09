/// Arguments passed when navigating to the chat screen (e.g. from Contact Driver).
class ChatScreenArgs {
  const ChatScreenArgs({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    this.driverProfileImage,
    this.isCarpool = 'false',
  });

  final String rideId;
  final String driverId;
  final String driverName;
  final String? driverProfileImage;
  final String isCarpool;
}
