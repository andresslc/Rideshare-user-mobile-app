import '../../domain/entities/pagination_entity.dart';

class PaginationModel extends PaginationEntity {
  const PaginationModel({
    required super.page,
    required super.currentPage,
    required super.total,
    required super.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
