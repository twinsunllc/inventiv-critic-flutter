class PaginatedResponse<T> {
  final int count;
  final int currentPage;
  final int totalPages;
  final List<T> items;

  PaginatedResponse({
    required this.count,
    required this.currentPage,
    required this.totalPages,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    String itemsKey,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      count: json['count'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      items:
          (json[itemsKey] as List<dynamic>)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList(),
    );
  }
}
