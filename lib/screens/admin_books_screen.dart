import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/book_cover.dart';
import 'book_form_screen.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final BookService _bookService = BookService();
  final _searchController = TextEditingController();

  List<BookModel> _books = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _bookService.getAllBooks();
      final categories = await _bookService.getCategories();
      if (!mounted) return;
      setState(() {
        _books = books;
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kitaplar yuklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<BookModel> books;
      if (query.isEmpty && _selectedCategory == null) {
        books = await _bookService.getAllBooks();
      } else if (query.isEmpty && _selectedCategory != null) {
        books = await _bookService.getBooksByCategory(_selectedCategory!);
      } else {
        books = await _bookService.searchBooks(query);
        if (_selectedCategory != null) {
          books = books.where((b) => b.category == _selectedCategory).toList();
        }
      }
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Arama sonucu getirilemedi.';
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String? category) {
    _selectedCategory = category;
    _search(_searchController.text);
  }

  void _clearFilters() {
    _searchController.clear();
    _selectedCategory = null;
    _loadBooks();
  }

  Future<void> _addBook() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BookFormScreen()),
    );
    if (result == true) _loadBooks();
  }

  Future<void> _editBook(BookModel book) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookFormScreen(book: book)),
    );
    if (result == true) _loadBooks();
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteBook),
        content: Text(
          '"${book.title}" kitabini silmek istediginize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _bookService.deleteBook(book.id!);
      _loadBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${book.title}" silindi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Yonetimi'),
        backgroundColor: AppColors.adminPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBook,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kitap'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;
            final topPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      AppHeroPanel(
                        primaryColor: AppColors.adminDark,
                        secondaryColor: AppColors.adminPrimary,
                        child: const AppSectionHeader(
                          title: 'Kitap Katalogu',
                          subtitle:
                              'Arama, filtreleme ve CRUD islemlerini bu ekrandan yonet.',
                          icon: Icons.menu_book_rounded,
                          color: Colors.white,
                          titleColor: Colors.white,
                          subtitleColor: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchBooks,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearFilters,
                                )
                              : null,
                        ),
                        onChanged: _search,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: FilterChip(
                                label: const Text('Tumu'),
                                selected: _selectedCategory == null,
                                onSelected: (_) => _filterByCategory(null),
                              ),
                            ),
                            ..._categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: _selectedCategory == cat,
                                  onSelected: (_) => _filterByCategory(
                                    _selectedCategory == cat ? null : cat,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingView(
        title: 'Katalog hazirlaniyor',
        subtitle: 'Kitaplar ve kategoriler yukleniyor.',
        color: AppColors.adminPrimary,
      );
    }

    if (_errorMessage != null) {
      return AppErrorState(
        message: _errorMessage!,
        onRetry: _loadBooks,
        color: AppColors.adminPrimary,
      );
    }

    if (_books.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Kitap bulunamadi',
        message:
            'Filtreleri temizleyip tekrar deneyebilir veya yeni kitap ekleyebilirsiniz.',
        actionLabel: 'Filtreleri Temizle',
        onAction: _clearFilters,
        color: AppColors.adminPrimary,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return _AdminBookCard(
            book: book,
            onEdit: () => _editBook(book),
            onDelete: () => _deleteBook(book),
          );
        },
      ),
    );
  }
}

class _AdminBookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminBookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              title: book.title,
              category: book.category,
              imageUrl: book.imageUrl,
              width: 52,
              height: 72,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        label: '${book.price.toStringAsFixed(2)} TL',
                        color: AppColors.adminPrimary,
                      ),
                      _InfoPill(
                        label: 'Stok: ${book.stock}',
                        color: book.inStock ? Colors.teal : AppColors.error,
                      ),
                      _InfoPill(label: book.category, color: Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.adminPrimary),
                  onPressed: onEdit,
                  tooltip: AppStrings.editBook,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: AppStrings.deleteBook,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
