class BookModel {
  final int? id;
  final String title;
  final String author;
  final String category;
  final double price;
  final int stock;
  final String? description;
  final String? imageUrl;
  final String? createdAt;

  const BookModel({
    this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.price,
    this.stock = 0,
    this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'author': author,
      'category': category,
      'price': price,
      'stock': stock,
    };
    if (id != null) map['id'] = id;
    if (description != null) map['description'] = description;
    if (imageUrl != null) map['image_url'] = imageUrl;
    if (createdAt != null) map['created_at'] = createdAt;
    return map;
  }

  BookModel copyWith({
    int? id,
    String? title,
    String? author,
    String? category,
    double? price,
    int? stock,
    String? description,
    String? imageUrl,
    String? createdAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get inStock => stock > 0;
}
