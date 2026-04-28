import 'db_service.dart';
import '../models/sale_model.dart';

class SaleService {
  final DbService _db = DbService();

  Future<int> totalSalesCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
    return result.first['count'] as int? ?? 0;
  }

  Future<double> totalRevenue() async {
    final result = await _db.rawQuery(
      'SELECT SUM(total_price) as total FROM sales',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> totalBooksCount() async {
    return await _db.count('books');
  }

  Future<int> totalUsersCount() async {
    return await _db.count('users');
  }

  Future<List<SaleModel>> recentSales({int limit = 10}) async {
    final results = await _db.rawQuery(
      '''
      SELECT s.*, b.title as book_title, u.name as user_name
      FROM sales s
      LEFT JOIN books b ON s.book_id = b.id
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.sale_date DESC
      LIMIT ?
    ''',
      [limit],
    );
    return results.map((m) => SaleModel.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> topSellingBooks({int limit = 5}) async {
    return await _db.rawQuery(
      '''
      SELECT b.title, b.author, SUM(s.quantity) as total_sold, SUM(s.total_price) as total_revenue
      FROM sales s
      LEFT JOIN books b ON s.book_id = b.id
      GROUP BY s.book_id
      ORDER BY total_sold DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> monthlySummary() async {
    return await _db.rawQuery('''
      SELECT
        strftime('%Y-%m', sale_date) as month,
        COUNT(*) as sale_count,
        SUM(quantity) as total_quantity,
        SUM(total_price) as total_revenue
      FROM sales
      GROUP BY strftime('%Y-%m', sale_date)
      ORDER BY month DESC
      LIMIT 6
    ''');
  }
}
