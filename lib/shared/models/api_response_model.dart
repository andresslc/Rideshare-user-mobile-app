// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// To parse this JSON data, do

class ApiResponse {
  final String? status;
  final bool success;
  final String? message;
  final dynamic data;
  final String? resetToken;
  final num? unreadCount;
  final Pagination? pagination;
  Error? error;

  ApiResponse({
    this.status,
    this.success = false,
    this.message,
    this.data,
    this.error,
    this.pagination,
    this.resetToken,
    this.unreadCount,
  });

  ApiResponse copyWith({
    String? status,
    bool? success,
    String? message,
    dynamic data,
    Error? error,
    Pagination? pagination,
    String? resetToken,
    num? unreadCount,
  }) {
    return ApiResponse(
      status: status ?? this.status,
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      error: error ?? this.error,
      pagination: pagination ?? this.pagination,
      resetToken: resetToken ?? this.resetToken,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
      'success': success,
      'message': message,
      'data': data,
      'error': error?.toMap(),
    };
  }

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      status: map['status'] != null ? map['status'] as String : null,
      success: map['success'] != null ? map['success'] as bool : false,
      message: map['message'] != null ? map['message'] as String : null,
      data: map['data'] as dynamic,
      error: map['error'] != null
          ? Error.fromMap(map['error'] as Map<String, dynamic>)
          : null,
      pagination: map["pagination"] == null
          ? null
          : Pagination.fromMap(map["pagination"]),
      resetToken: map['resetToken'] != null
          ? map['resetToken'] as String
          : null,
      unreadCount: map['unreadCount'] != null
          ? map['unreadCount'] as num
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'ApiResponse(status: $status, success: $success, message: $message, data: $data, error: $error)';
  }

  @override
  bool operator ==(covariant ApiResponse other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.success == success &&
        other.message == message &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        success.hashCode ^
        message.hashCode ^
        data.hashCode ^
        error.hashCode;
  }
}

class Error {
  int? statusCode;
  bool? success;
  bool? isOperational;

  Error({this.statusCode, this.success, this.isOperational});

  Error copyWith({int? statusCode, bool? success, bool? isOperational}) {
    return Error(
      statusCode: statusCode ?? this.statusCode,
      success: success ?? this.success,
      isOperational: isOperational ?? this.isOperational,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusCode': statusCode,
      'success': success,
      'isOperational': isOperational,
    };
  }

  factory Error.fromMap(Map<String, dynamic> map) {
    return Error(
      statusCode: map['statusCode'] != null ? map['statusCode'] as int : null,
      success: map['success'] != null ? map['success'] as bool : null,
      isOperational: map['isOperational'] != null
          ? map['isOperational'] as bool
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Error.fromJson(String source) =>
      Error.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Error(statusCode: $statusCode, success: $success, isOperational: $isOperational)';

  @override
  bool operator ==(covariant Error other) {
    if (identical(this, other)) return true;

    return other.statusCode == statusCode &&
        other.success == success &&
        other.isOperational == isOperational;
  }

  @override
  int get hashCode =>
      statusCode.hashCode ^ success.hashCode ^ isOperational.hashCode;
}

class Pagination {
  final num? itemsPerPage;
  final num? currentPage;
  final num? totalItems;
  final num? totalPages;

  Pagination({
    this.itemsPerPage,
    this.currentPage,
    this.totalItems,
    this.totalPages,
  });

  Pagination copyWith({
    num? itemsPerPage,
    num? currentPage,
    num? totalItems,
    num? totalPages,
  }) => Pagination(
    itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    currentPage: currentPage ?? this.currentPage,
    totalItems: totalItems ?? this.totalItems,
    totalPages: totalPages ?? this.totalPages,
  );

  factory Pagination.fromMap(Map<String, dynamic> json) => Pagination(
    itemsPerPage: json["limit"], // was "itemsPerPage"
    currentPage: json["page"], // was "currentPage"
    totalItems: json["total"], // was "totalItems"
    totalPages: json["totalPages"], // this one is correct
  );

  Map<String, dynamic> toMap() => {
    "limit": itemsPerPage,
    "page": currentPage,
    "total": totalItems,
    "totalPages": totalPages,
  };
}
