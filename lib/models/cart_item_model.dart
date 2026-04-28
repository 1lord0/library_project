class CartItemModel {
  final int? id;
  final int userId;
  final int bookId;
  final int quantity;

  // Join sonucu gelen ekstra alanlar
  final String? bookTitle;
  final String? bookAuthor;
  final double? bookPrice;
  final int? bookStock;
  final String? bookImageUrl;

  const CartItemModel({
    this.id,
    required this.userId,
    required this.bookId,
    this.quantity = 1,
    this.bookTitle,
    this.bookAuthor,
    this.bookPrice,
    this.bookStock,
    this.bookImageUrl,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      bookId: map['book_id'] as int,
      quantity: map['quantity'] as int? ?? 1,
      bookTitle: map['book_title'] as String?,
      bookAuthor: map['book_author'] as String?,
      bookPrice: map['book_price'] != null
          ? (map['book_price'] as num).toDouble()
          : null,
      bookStock: map['book_stock'] as int?,
      bookImageUrl: map['book_image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  CartItemModel copyWith({
    int? id,
    int? userId,
    int? bookId,
    int? quantity,
    String? bookTitle,
    String? bookAuthor,
    double? bookPrice,
    int? bookStock,
    String? bookImageUrl,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      quantity: quantity ?? this.quantity,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      bookPrice: bookPrice ?? this.bookPrice,
      bookStock: bookStock ?? this.bookStock,
      bookImageUrl: bookImageUrl ?? this.bookImageUrl,
    );
  }

  double get lineTotal => (bookPrice ?? 0) * quantity;
}
