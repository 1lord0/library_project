import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_project/models/book_model.dart';
import 'package:library_project/models/cart_item_model.dart';
import 'package:library_project/models/user_model.dart';
import 'package:library_project/widgets/book_cover.dart';
import 'package:library_project/widgets/book_card.dart';

void main() {
  testWidgets('BookCover shows title initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BookCover(
              title: 'Atomik Aliskanliklar',
              category: 'Roman',
              width: 96,
              height: 132,
            ),
          ),
        ),
      ),
    );

    expect(find.text('AA'), findsOneWidget);
    expect(find.text('Roman'), findsOneWidget);
  });

  testWidgets('BookCard disables add button when stock is empty', (
    tester,
  ) async {
    const book = BookModel(
      title: 'Tukenmis Kitap',
      author: 'Yazar',
      category: 'Roman',
      price: 20,
      stock: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(
            book: book,
            onTap: () {},
            onAddToCart: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.text('Tukendi'), findsOneWidget);
  });

  test('BookModel inStock reflects stock amount', () {
    const inStockBook = BookModel(
      title: 'Deneme',
      author: 'Yazar',
      category: 'Roman',
      price: 10,
      stock: 3,
    );
    const outOfStockBook = BookModel(
      title: 'Bos',
      author: 'Yazar',
      category: 'Roman',
      price: 10,
      stock: 0,
    );

    expect(inStockBook.inStock, isTrue);
    expect(outOfStockBook.inStock, isFalse);
  });

  test('UserModel isAdmin reflects role', () {
    const admin = UserModel(
      name: 'Admin',
      email: 'admin@test.com',
      password: '123',
      role: 'admin',
    );
    const user = UserModel(
      name: 'User',
      email: 'user@test.com',
      password: '123',
      role: 'user',
    );

    expect(admin.isAdmin, isTrue);
    expect(user.isAdmin, isFalse);
  });

  test('CartItemModel lineTotal multiplies price and quantity', () {
    const item = CartItemModel(
      userId: 1,
      bookId: 1,
      quantity: 3,
      bookPrice: 42.5,
    );

    expect(item.lineTotal, 127.5);
  });
}
