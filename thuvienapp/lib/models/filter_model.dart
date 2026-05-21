class BookFilterModel {
  String? author;
  String? publisher;
  double? minPrice;
  double? maxPrice;

  BookFilterModel({
    this.author,
    this.publisher,
    this.minPrice,
    this.maxPrice,
  });

  bool get hasFilter =>
      author != null ||
      publisher != null ||
      minPrice != null ||
      maxPrice != null;

  void clear() {
    author = null;
    publisher = null;
    minPrice = null;
    maxPrice = null;
  }
}
