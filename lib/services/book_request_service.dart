import '../models/book_request_model.dart';
import 'db_service.dart';

class BookRequestService {
  final DbService _db = DbService();

  Future<int> createRequest({
    required int userId,
    required String title,
    required String author,
    String? message,
  }) async {
    return await _db.insert('book_requests', {
      'user_id': userId,
      'title': title,
      'author': author,
      'message': message,
      'status': 'pending',
    });
  }

  Future<List<BookRequestModel>> getAllRequests() async {
    final rows = await _db.rawQuery('''
      SELECT br.*, u.name as user_name
      FROM book_requests br
      LEFT JOIN users u ON br.user_id = u.id
      ORDER BY
        CASE br.status WHEN 'pending' THEN 0 ELSE 1 END,
        br.created_at DESC
    ''');
    return rows.map((r) => BookRequestModel.fromMap(r)).toList();
  }

  Future<List<BookRequestModel>> getUserRequests(int userId) async {
    final rows = await _db.rawQuery('''
      SELECT br.*, u.name as user_name
      FROM book_requests br
      LEFT JOIN users u ON br.user_id = u.id
      WHERE br.user_id = ?
      ORDER BY br.created_at DESC
    ''', [userId]);
    return rows.map((r) => BookRequestModel.fromMap(r)).toList();
  }

  Future<int> pendingCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM book_requests WHERE status = 'pending'",
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> updateStatus(int requestId, String status) async {
    await _db.update(
      'book_requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  Future<void> deleteRequest(int requestId) async {
    await _db.delete('book_requests', where: 'id = ?', whereArgs: [requestId]);
  }
}
