import 'package:flutter/material.dart';

/// Mixin that adds offset-based pagination logic to any [State].
///
/// Override [loadPage] to fetch data. The mixin handles the scroll
/// listener, loading state, and "has more" tracking.
///
/// Usage:
/// ```dart
/// class _MyListScreenState extends State<MyListScreen>
///     with PaginationMixin<MyListScreen> {
///
///   final items = <ItemEntity>[];
///
///   @override
///   Future<List<dynamic>> loadPage(int offset, int limit) async {
///     return await repository.getItems(offset: offset, limit: limit);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       controller: scrollController,
///       itemCount: items.length + (hasMore ? 1 : 0),
///       itemBuilder: (ctx, i) {
///         if (i == items.length) return const CircularProgressIndicator();
///         return ItemTile(items[i]);
///       },
///     );
///   }
/// }
/// ```
mixin PaginationMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();

  int _offset = 0;
  int pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    fetchNextPage();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200 && !_isLoading && _hasMore) {
      fetchNextPage();
    }
  }

  /// Override to fetch data for the given [offset] and [limit].
  /// Return the list of items fetched.
  Future<List<dynamic>> loadPage(int offset, int limit);

  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final results = await loadPage(_offset, pageSize);
      setState(() {
        _offset += results.length;
        _hasMore = results.length >= pageSize;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  /// Reset and reload from the beginning.
  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    return fetchNextPage();
  }
}
