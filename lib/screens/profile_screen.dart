import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/book_cover.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DbService _db = DbService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
  double _totalSpent = 0;
  int _totalBooks = 0;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);

    final userId = context.read<AuthService>().currentUser!.id!;
    final results = await _db.rawQuery(
      '''
      SELECT s.quantity, s.total_price, s.sale_date,
             b.title, b.author, b.category, b.image_url
      FROM sales s
      LEFT JOIN books b ON s.book_id = b.id
      WHERE s.user_id = ?
      ORDER BY s.sale_date DESC
    ''',
      [userId],
    );

    double spent = 0;
    int books = 0;
    for (final r in results) {
      spent += (r['total_price'] as num?)?.toDouble() ?? 0;
      books += (r['quantity'] as int?) ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _purchases = results;
      _totalSpent = spent;
      _totalBooks = books;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: _isLoading
          ? const AppLoadingView(
              title: 'Profil hazirlaniyor',
              subtitle: 'Satin alma gecmisiniz yukleniyor.',
            )
          : SingleChildScrollView(
              child: AppResponsiveBody(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // --- Profile Card ---
                    AppHeroPanel(
                      primaryColor: AppColors.primaryDark,
                      secondaryColor: AppColors.primaryLight,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                _initials(user.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                if (user.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Uyelik: ${_formatDate(user.createdAt!)}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Stats Row ---
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Satin Alinan',
                            value: '$_totalBooks kitap',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.payments_outlined,
                            label: 'Toplam Harcama',
                            value: '${_totalSpent.toStringAsFixed(2)} TL',
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long_outlined,
                            label: 'Siparis',
                            value: '${_purchases.length} adet',
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Purchase History ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Satin Alma Gecmisim',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_purchases.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(30),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Henuz bir kitap satin almadiniz.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_purchases.length, (index) {
                        final p = _purchases[index];
                        return _PurchaseCard(
                          title: p['title'] as String? ?? 'Silinmis Kitap',
                          author: p['author'] as String? ?? '',
                          category: p['category'] as String?,
                          imageUrl: p['image_url'] as String?,
                          quantity: p['quantity'] as int? ?? 0,
                          totalPrice:
                              (p['total_price'] as num?)?.toDouble() ?? 0,
                          date: p['sale_date'] as String?,
                        );
                      }),
                    const SizedBox(height: 24),

                    // --- Logout Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthService>().logout();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Cikis Yap'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final String title;
  final String author;
  final String? category;
  final String? imageUrl;
  final int quantity;
  final double totalPrice;
  final String? date;

  const _PurchaseCard({
    required this.title,
    required this.author,
    this.category,
    this.imageUrl,
    required this.quantity,
    required this.totalPrice,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            BookCover(
              title: title,
              category: category,
              imageUrl: imageUrl,
              width: 48,
              height: 68,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _pill('$quantity adet', AppColors.primary),
                      _pill(
                        '${totalPrice.toStringAsFixed(2)} TL',
                        AppColors.secondary,
                      ),
                      if (date != null) _pill(_shortDate(date!), Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
