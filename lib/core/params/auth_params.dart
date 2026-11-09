import 'dart:io';

import 'package:dio/dio.dart';

/// ----------------------
/// LOGIN PARAMS
/// ----------------------
class SendOtpParams {
  final String countryCode;
  final String phone;

  const SendOtpParams({required this.countryCode, required this.phone});

  Map<String, dynamic> toJson() {
    return {"phone": "$countryCode$phone", "role": 'user'};
  }
}

/// ----------------------
/// Create PARAMS
/// ----------------------

class CreateProfileParams {
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String? city;
  final String? state;
  final String phone;
  final String role;
  final File? file;
  final String countryCode;

  /// Calendar date of birth; converted to UTC epoch ms as `dob` in [toFormData].
  final DateTime dob;

  CreateProfileParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    this.city,
    this.state,
    required this.countryCode,
    required this.role,
    required this.dob,
    this.file,
  });

  FormData toFormData() {
    final dobUtc = DateTime.utc(dob.year, dob.month, dob.day);
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName.trim(),
      'email': email,
      'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      'phone': "$countryCode$phone",
      'role': role,
      'dob': dobUtc.millisecondsSinceEpoch,
    };

    // Agar file hai toh FormData me add karo
    if (file != null) {
      map['file'] = MultipartFile.fromFileSync(
        file!.path,
        filename: file!.path.split('/').last,
      );
    }

    return FormData.fromMap(map);
  }
}

/// ----------------------
/// VERIFY OTP PARAMS
/// ----------------------
class VerifyOtpParams {
  final String phone;
  final String otp;
  final String? fcmToken;
  final String countryCode;

  const VerifyOtpParams({
    required this.countryCode,
    required this.phone,
    this.fcmToken,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      "phone": "$countryCode$phone",
      "otp": otp,
      "role": 'user',
      if (fcmToken != null) "fcmToken": fcmToken,
    };
  }
}

/// ----------------------
/// Update PARAMS
/// ----------------------

class UpdateProfileParams {
  final String firstName;
  final String lastName;
  final String email;
  final String? address;
  final String? city;
  final String? state;
  final File? file;
  final bool removeProfilePicture;

  /// When non-null, sent as UTC epoch ms under `dob` (calendar date).
  final DateTime? dob;

  UpdateProfileParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.address,
    this.city,
    this.state,
    this.file,
    this.removeProfilePicture = false,
    this.dob,
  });

  FormData toFormData() {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName.trim(),
      'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };

    if (dob != null) {
      final dobUtc = DateTime.utc(dob!.year, dob!.month, dob!.day);
      map['dob'] = dobUtc.millisecondsSinceEpoch;
    }

    // Signal backend to remove existing image when explicitly requested.
    if (removeProfilePicture) {
      map['removePFP'] = true;
      map['profilePicture'] = '';
    }

    // Agar file hai toh FormData me add karo
    if (file != null) {
      map['file'] = MultipartFile.fromFileSync(
        file!.path,
        filename: file!.path.split('/').last,
      );
    }

    return FormData.fromMap(map);
  }
}
