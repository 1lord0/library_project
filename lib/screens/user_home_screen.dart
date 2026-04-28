import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../services/book_request_service.dart';
import '../services/book_service.dart';
import '../services/cart_service.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final BookService _bookService = BookService();
  final CartService _cartService = CartService();
  final BookRequestService _requestService = BookRequestService();
  final _searchController = TextEditingController();

  List<BookModel> _books = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
        _errorMessage = 'Kitap listesi yuklenemedi.';
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
        _errorMessage = 'Arama sirasinda bir sorun olustu.';
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String? category) {
    _selectedCategory = category;
    _search(_searchController.text);
  }

  Future<void> _addToCart(BookModel book) async {
    if (!book.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.outOfStock),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = context.read<AuthService>().currentUser!.id!;
    try {
      await _cartService.addToCart(userId, book.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${book.title} sepete eklendi')));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: AppColors.error,
        ),
      );
      await _loadData();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    _selectedCategory = null;
    _loadData();
  }

  Future<void> _showRequestDialog() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitap Istegi'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Katalogda bulamadiginiz bir kitabi admin ekibinden talep edin.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Kitap Adi',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Kitap adi gerekli' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Yazar',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Yazar gerekli' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Not (istege bagli)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Gonder'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    final userId = context.read<AuthService>().currentUser!.id!;
    await _requestService.createRequest(
      userId: userId,
      title: titleController.text.trim(),
      author: authorController.text.trim(),
      message: messageController.text.trim().isEmpty
          ? null
          : messageController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kitap isteginiz admin ekibine iletildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthService>().currentUser?.name ?? 'Okur';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.books),
        leading: IconButton(
          icon: const Icon(Icons.person),
          tooltip: 'Profilim',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            _loadData();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Kitap Iste',
            onPressed: _showRequestDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: AppResponsiveBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AppHeroPanel(
                primaryColor: AppColors.primaryDark,
                secondaryColor: AppColors.primaryLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, $userName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kategoriye gore filtrele, kitap detayini incele ve stok varsa hizlica sepete ekle.',
                      style: TextStyle(color: Colors.white, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
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
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Tumu'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => _filterByCategory(null),
                    ),
                  ),
                  ..._categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingView(
        title: 'Kitaplar hazirlaniyor',
        subtitle: 'Veritabani ve filtreler yukleniyor.',
      );
    }

    if (_errorMessage != null) {
      return AppErrorState(message: _errorMessage!, onRetry: _loadData);
    }

    if (_books.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Kitap bulunamadi',
        message:
            'Arama veya kategori filtresini degistirerek baska kitaplara goz atabilirsiniz.',
        actionLabel: 'Filtreleri Temizle',
        onAction: _clearFilters,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return BookCard(
            book: book,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(
                    book: book,
                    onAddToCart: () {
                      _addToCart(book);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
            onAddToCart: () => _addToCart(book),
          );
        },
      ),
    );
  }
}
