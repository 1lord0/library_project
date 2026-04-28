import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../constants/app_strings.dart';
import '../models/book_model.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/book_cover.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;
  final bool showAddToCart;
  final VoidCallback? onAddToCart;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.showAddToCart = true,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Detayi')),
      body: SingleChildScrollView(
        child: AppResponsiveBody(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeroPanel(
                primaryColor: AppColors.primaryDark,
                secondaryColor: AppColors.primaryLight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 520;
                    return stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BookCover(
                                title: book.title,
                                category: book.category,
                                imageUrl: book.imageUrl,
                                width: 110,
                                height: 150,
                              ),
                              const SizedBox(height: 18),
                              _BookDetailHeroText(book: book),
                            ],
                          )
                        : Row(
                            children: [
                              BookCover(
                                title: book.title,
                                category: book.category,
                                imageUrl: book.imageUrl,
                                width: 110,
                                height: 150,
                              ),
                              const SizedBox(width: 18),
                              Expanded(child: _BookDetailHeroText(book: book)),
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _infoChip(Icons.category, book.category),
                  _infoChip(
                    Icons.inventory,
                    book.inStock
                        ? 'Stok: ${book.stock}'
                        : AppStrings.outOfStock,
                    color: book.inStock ? null : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${book.price.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (book.description != null && book.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Aciklama',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withAlpha(30)),
                  ),
                  child: Text(
                    book.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (showAddToCart)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: book.inStock ? onAddToCart : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      book.inStock
                          ? AppStrings.addToCart
                          : AppStrings.outOfStock,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BookDetailHeroText extends StatelessWidget {
  final BookModel book;

  const _BookDetailHeroText({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.author,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          '${book.price.toStringAsFixed(2)} TL',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
