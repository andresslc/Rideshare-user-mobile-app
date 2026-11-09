class UserEntity {
  final String id;
  final String firstName;
  final String address;
  final String? city;
  final String? state;
  final String lastName;
  final String email;
  final String? profilePicture;
  final String phone;
  final String? stripeCustomerId;
  final num balance;
  final String locale;
  final bool isNotificationEnabled;
  final num rating;
  final int reviewsGiven;
  final int reviewsReceived;
  final int completedRides;
  final int cancelledRides;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final DateTime? dob;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.address,
    this.city,
    this.state,
    required this.email,
    this.profilePicture,
    required this.phone,
    this.stripeCustomerId,
    required this.balance,
    required this.locale,
    required this.isNotificationEnabled,
    required this.rating,
    required this.reviewsGiven,
    required this.reviewsReceived,
    required this.completedRides,
    required this.cancelledRides,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.dob,
  });

  String get fullName {
    final parts = <String>[firstName.trim()];
    final trimmedLastName = lastName.trim();
    if (trimmedLastName.isNotEmpty) {
      parts.add(trimmedLastName);
    }
    return parts.join(' ').trim();
  }

  UserEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? address,
    String? city,
    String? state,
    String? email,
    String? profilePicture,
    String? phone,
    String? stripeCustomerId,
    int? balance,
    String? locale,
    bool? isNotificationEnabled,
    num? rating,
    int? reviewsGiven,
    int? reviewsReceived,
    int? completedRides,
    int? cancelledRides,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
    DateTime? dob,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      profilePicture: profilePicture ?? this.profilePicture,
      phone: phone ?? this.phone,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      balance: balance ?? this.balance,
      locale: locale ?? this.locale,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      rating: rating ?? this.rating,
      reviewsGiven: reviewsGiven ?? this.reviewsGiven,
      reviewsReceived: reviewsReceived ?? this.reviewsReceived,
      completedRides: completedRides ?? this.completedRides,
      cancelledRides: cancelledRides ?? this.cancelledRides,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      dob: dob ?? this.dob,
    );
  }
}
