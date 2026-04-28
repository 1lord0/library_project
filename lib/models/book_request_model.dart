class BookRequestModel {
  final int? id;
  final int userId;
  final String title;
  final String author;
  final String? message;
  final String status; // pending, approved, rejected
  final String? createdAt;

  // Join sonucu gelen ekstra alan
  final String? userName;

  const BookRequestModel({
    this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.userName,
  });

  factory BookRequestModel.fromMap(Map<String, dynamic> map) {
    return BookRequestModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      message: map['message'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String?,
      userName: map['user_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'author': author,
      'status': status,
    };
    if (id != null) map['id'] = id;
    if (message != null) map['message'] = message;
    if (createdAt != null) map['created_at'] = createdAt;
    return map;
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Onaylandi';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  bool get isPending => status == 'pending';
}
