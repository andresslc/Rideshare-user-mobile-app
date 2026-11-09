class ReviewsRequestParams {
  final int page;
  final int limit;
  final String id;

  ReviewsRequestParams({this.page = 1, this.limit = 20, required this.id});
}
