import 'db_service.dart';
import '../models/cart_item_model.dart';

class CartService {
  final DbService _db = DbService();

  Future<void> addToCart(int userId, int bookId) async {
    final books = await _db.query(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
    if (books.isEmpty) {
      throw StateError('Kitap bulunamadi.');
    }

    final stock = (books.first['stock'] as num?)?.toInt() ?? 0;
    if (stock <= 0) {
      throw StateError('Bu kitap stokta kalmadi.');
    }

    final existing = await _db.query(
      'cart_items',
      where: 'user_id = ? AND book_id = ?',
      whereArgs: [userId, bookId],
    );

    final currentQuantity = existing.isNotEmpty
        ? (existing.first['quantity'] as num?)?.toInt() ?? 0
        : 0;
    final nextQuantity = currentQuantity + 1;

    if (nextQuantity > stock) {
      throw StateError('Sepette en fazla $stock adet olabilir.');
    }

    if (existing.isNotEmpty) {
      final current = existing.first;
      await _db.update(
        'cart_items',
        {'quantity': nextQuantity},
        where: 'id = ?',
        whereArgs: [current['id']],
      );
    } else {
      await _db.insert('cart_items', {
        'user_id': userId,
        'book_id': bookId,
        'quantity': 1,
      });
    }
  }

  Future<List<CartItemModel>> getCartItems(int userId) async {
    final results = await _db.rawQuery(
      '''
      SELECT ci.*, b.title as book_title, b.author as book_author,
             b.price as book_price, b.stock as book_stock,
             b.image_url as book_image_url
      FROM cart_items ci
      JOIN books b ON ci.book_id = b.id
      WHERE ci.user_id = ?
    ''',
      [userId],
    );
    return results.map((m) => CartItemModel.fromMap(m)).toList();
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity <= 0) {
      await _db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
      return;
    }

    final results = await _db.rawQuery(
      '''
      SELECT ci.id, b.title as book_title, b.stock as book_stock
      FROM cart_items ci
      JOIN books b ON ci.book_id = b.id
      WHERE ci.id = ?
    ''',
      [cartItemId],
    );

    if (results.isEmpty) {
      throw StateError('Sepet urunu bulunamadi.');
    }

    final stock = (results.first['book_stock'] as num?)?.toInt() ?? 0;
    final title = results.first['book_title'] as String? ?? 'Bu kitap';

    if (stock <= 0) {
      throw StateError('$title artik stokta yok.');
    }

    if (quantity > stock) {
      throw StateError('$title icin en fazla $stock adet secilebilir.');
    }

    await _db.update(
      'cart_items',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> removeFromCart(int cartItemId) async {
    await _db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  Future<void> clearCart(int userId) async {
    await _db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> getCartCount(int userId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(quantity) as total FROM cart_items WHERE user_id = ?',
      [userId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> checkout(int userId) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      final items = await txn.rawQuery(
        '''
        SELECT
          ci.id,
          ci.book_id,
          ci.quantity,
          b.id as existing_book_id,
          b.title as book_title,
          b.price as book_price,
          b.stock as book_stock
        FROM cart_items ci
        LEFT JOIN books b ON ci.book_id = b.id
        WHERE ci.user_id = ?
      ''',
        [userId],
      );

      if (items.isEmpty) {
        throw StateError('Sepetiniz bos.');
      }

      for (final item in items) {
        if (item['existing_book_id'] == null) {
          throw StateError(
            'Sepette silinmis bir kitap var. Urunu kaldirip tekrar deneyin.',
          );
        }

        final title = item['book_title'] as String? ?? 'Bu kitap';
        final stock = (item['book_stock'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

        if (stock <= 0) {
          throw StateError('$title artik stokta yok.');
        }

        if (quantity > stock) {
          throw StateError('$title icin yalnizca $stock adet stok kaldi.');
        }
      }

      final saleDate = DateTime.now().toIso8601String();

      for (final item in items) {
        final bookId = (item['book_id'] as num).toInt();
        final quantity = (item['quantity'] as num).toInt();
        final stock = (item['book_stock'] as num).toInt();
        final price = (item['book_price'] as num).toDouble();

        await txn.insert('sales', {
          'user_id': userId,
          'book_id': bookId,
          'quantity': quantity,
          'total_price': price * quantity,
          'sale_date': saleDate,
        });

        await txn.update(
          'books',
          {'stock': stock - quantity},
          where: 'id = ?',
          whereArgs: [bookId],
        );
      }

      await txn.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
    });
  }
}
