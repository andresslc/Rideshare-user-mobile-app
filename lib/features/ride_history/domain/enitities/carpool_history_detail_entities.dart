// carpool_entity.dart


class CarpoolEntity {
  final CarpoolDriverEntity driver;
  final List<CarpoolStopEntity> stops;
  final int totalSeatsBooked;
  final int requiredSeats;
  final String paymentMethod;
  final String paymentStatus;
  final num distance;
  final num avgTime;
  final double fareCharged;
  final String status;
  final CarpoolReviewEntity? review;
  final TransactionEntity? transaction;

  CarpoolEntity({
    required this.driver,
    this.distance = 0,
    required this.stops,
    this.requiredSeats = 0,
    this.avgTime = 0.0,
    required this.totalSeatsBooked,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.fareCharged,
    required this.status,
    this.review,
    this.transaction,
  });
}

class CarpoolDriverEntity {
  final String id;
  final String firstName;
  final String lastName;
  final double rating;

  CarpoolDriverEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.rating,
  });

  String get fullName {
    final parts = <String>[firstName.trim()];
    final trimmedLastName = lastName.trim();
    if (trimmedLastName.isNotEmpty) {
      parts.add(trimmedLastName);
    }
    return parts.join(' ').trim();
  }
}

class CarpoolStopEntity {
  final String label;
  final String placeName;
  final LocationEntity location;
  final String status;

  CarpoolStopEntity({
    required this.label,
    required this.placeName,
    required this.location,
    required this.status,
  });
}

class LocationEntity {
  final String type;
  final List<double> coordinates;

  LocationEntity({required this.type, required this.coordinates});
}

class CarpoolReviewEntity {
  final String id;
  final double stars;
  final String description;
  final bool isAnonymous;

  CarpoolReviewEntity({
    required this.id,
    required this.stars,
    required this.description,
    required this.isAnonymous,
  });
}

class TransactionEntity {
  final String id;
  final double amount;
  final String type;
  final String user;
  final String userType;
  final String status;
  final CardEntity? card;

  TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.user,
    required this.userType,
    required this.status,
    this.card,
  });
}

class CardEntity {
  final String id;
  final String brand;
  final String last4;

  CardEntity({required this.id, required this.brand, required this.last4});
}
