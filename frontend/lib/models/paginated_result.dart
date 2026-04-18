class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;

  PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });
}
