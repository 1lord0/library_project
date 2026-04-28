import 'db_service.dart';
import '../models/book_model.dart';

class BookService {
  final DbService _db = DbService();

  Future<List<BookModel>> getAllBooks() async {
    final results = await _db.query('books', orderBy: 'title ASC');
    return results.map((m) => BookModel.fromMap(m)).toList();
  }

  Future<List<BookModel>> searchBooks(String query) async {
    final results = await _db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return results.map((m) => BookModel.fromMap(m)).toList();
  }

  Future<List<BookModel>> getBooksByCategory(String category) async {
    final results = await _db.query(
      'books',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title ASC',
    );
    return results.map((m) => BookModel.fromMap(m)).toList();
  }

  Future<List<String>> getCategories() async {
    final results = await _db.rawQuery(
      'SELECT DISTINCT category FROM books ORDER BY category ASC',
    );
    return results.map((m) => m['category'] as String).toList();
  }

  Future<BookModel?> getBookById(int id) async {
    final results = await _db.query('books', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return BookModel.fromMap(results.first);
  }

  Future<int> insertBook(BookModel book) async {
    return await _db.insert('books', book.toMap());
  }

  Future<int> updateBook(BookModel book) async {
    return await _db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    return await _db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> decreaseStock(int bookId, int quantity) async {
    final book = await getBookById(bookId);
    if (book == null) return;
    final newStock = book.stock - quantity;
    await _db.update(
      'books',
      {'stock': newStock < 0 ? 0 : newStock},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }
}
