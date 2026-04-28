class SaleModel {
  final int? id;
  final int userId;
  final int bookId;
  final int quantity;
  final double totalPrice;
  final String? saleDate;

  // Join sonucu gelen ekstra alanlar
  final String? bookTitle;
  final String? userName;

  const SaleModel({
    this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    required this.totalPrice,
    this.saleDate,
    this.bookTitle,
    this.userName,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      bookId: map['book_id'] as int,
      quantity: map['quantity'] as int,
      totalPrice: (map['total_price'] as num).toDouble(),
      saleDate: map['sale_date'] as String?,
      bookTitle: map['book_title'] as String?,
      userName: map['user_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
      'total_price': totalPrice,
    };
    if (id != null) map['id'] = id;
    if (saleDate != null) map['sale_date'] = saleDate;
    return map;
  }

  SaleModel copyWith({
    int? id,
    int? userId,
    int? bookId,
    int? quantity,
    double? totalPrice,
    String? saleDate,
    String? bookTitle,
    String? userName,
  }) {
    return SaleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      saleDate: saleDate ?? this.saleDate,
      bookTitle: bookTitle ?? this.bookTitle,
      userName: userName ?? this.userName,
    );
  }
}
