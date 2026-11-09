class PaginationEntity {
  final int page;
  final int currentPage;
  final int total;
  final int totalPages;

  const PaginationEntity({
    required this.page,
    required this.currentPage,
    required this.total,
    required this.totalPages,
  });
}