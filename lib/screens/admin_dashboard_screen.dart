import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../models/sale_model.dart';
import '../services/auth_service.dart';
import '../services/sale_service.dart';
import '../widgets/app_state_widgets.dart';
import 'admin_books_screen.dart';
import 'admin_users_screen.dart';
import 'reset_demo_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SaleService _saleService = SaleService();

  bool _isLoading = true;
  String? _errorMessage;
  int _totalBooks = 0;
  int _totalUsers = 0;
  int _totalSales = 0;
  double _totalRevenue = 0;
  List<SaleModel> _recentSales = [];
  List<Map<String, dynamic>> _topBooks = [];
  List<Map<String, dynamic>> _monthlySummary = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _saleService.totalBooksCount(),
        _saleService.totalUsersCount(),
        _saleService.totalSalesCount(),
        _saleService.totalRevenue(),
        _saleService.recentSales(limit: 10),
        _saleService.topSellingBooks(limit: 5),
        _saleService.monthlySummary(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalBooks = results[0] as int;
        _totalUsers = results[1] as int;
        _totalSales = results[2] as int;
        _totalRevenue = results[3] as double;
        _recentSales = results[4] as List<SaleModel>;
        _topBooks = results[5] as List<Map<String, dynamic>>;
        _monthlySummary = results[6] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Dashboard verileri yuklenemedi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.read<AuthService>().currentUser?.name ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingView(
              title: 'Dashboard yukleniyor',
              subtitle: 'Satislar, kitaplar ve gelir ozeti hazirlaniyor.',
              color: AppColors.adminPrimary,
            )
          : _errorMessage != null
          ? AppErrorState(
              message: _errorMessage!,
              onRetry: _loadData,
              color: AppColors.adminPrimary,
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 380
                      ? 12.0
                      : 16.0;
                  final verticalPadding = constraints.maxWidth < 380
                      ? 12.0
                      : 16.0;
                  final maxContentWidth = constraints.maxWidth < 1120
                      ? constraints.maxWidth
                      : 1120.0;
                  final contentWidth =
                      maxContentWidth - (horizontalPadding * 2);

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 1120,
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppHeroPanel(
                                  primaryColor: AppColors.adminDark,
                                  secondaryColor: AppColors.adminPrimary,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hosgeldiniz, $adminName',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Toplam $_totalSales satis ve ${_totalRevenue.toStringAsFixed(2)} TL gelir ile sistemin son durumunu buradan yonetin.',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildStatGrid(contentWidth),
                                const SizedBox(height: 24),
                                const AppSectionHeader(
                                  title: 'Hizli Islemler',
                                  subtitle:
                                      'Kitaplari ve demo senaryosunu yonetin.',
                                  icon: Icons.flash_on_outlined,
                                  color: AppColors.adminPrimary,
                                ),
                                const SizedBox(height: 10),
                                _buildQuickActions(),
                                const SizedBox(height: 24),
                                const AppSectionHeader(
                                  title: 'En Cok Satan Kitaplar',
                                  subtitle:
                                      'Adet ve gelir bazli ilk bes kitap.',
                                  icon: Icons.emoji_events_outlined,
                                  color: AppColors.adminPrimary,
                                ),
                                const SizedBox(height: 10),
                                _buildTopBooks(),
                                const SizedBox(height: 24),
                                const AppSectionHeader(
                                  title: 'Aylik Ozet',
                                  subtitle:
                                      'Ay bazinda satis adetleri ve gelir dagilimi.',
                                  icon: Icons.bar_chart_outlined,
                                  color: AppColors.adminPrimary,
                                ),
                                const SizedBox(height: 10),
                                _buildMonthlySummary(),
                                const SizedBox(height: 24),
                                const AppSectionHeader(
                                  title: 'Son Satislar',
                                  subtitle:
                                      'En guncel hareketler burada listelenir.',
                                  icon: Icons.receipt_long_outlined,
                                  color: AppColors.adminPrimary,
                                ),
                                const SizedBox(height: 10),
                                _buildRecentSales(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildStatGrid(double availableWidth) {
    final columns = availableWidth >= 1000
        ? 4
        : availableWidth >= 620
        ? 2
        : 1;
    const spacing = 12.0;
    final safeWidth = availableWidth > 0 ? availableWidth : 1.0;
    final itemWidth = columns == 1
        ? safeWidth
        : (safeWidth - ((columns - 1) * spacing)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: itemWidth,
          child: _StatCard(
            title: AppStrings.totalBooks,
            value: '$_totalBooks',
            icon: Icons.book_rounded,
            color: Colors.indigo,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _StatCard(
            title: AppStrings.totalUsers,
            value: '$_totalUsers',
            icon: Icons.people_alt_rounded,
            color: Colors.teal,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _StatCard(
            title: AppStrings.totalSales,
            value: '$_totalSales',
            icon: Icons.receipt_long_rounded,
            color: Colors.orange,
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _StatCard(
            title: AppStrings.totalRevenue,
            value: '${_totalRevenue.toStringAsFixed(2)} TL',
            icon: Icons.payments_rounded,
            color: AppColors.adminPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildMenuCard(
          icon: Icons.book_rounded,
          title: 'Kitap Yonetimi',
          subtitle: 'Kitap ekle, duzenle, sil ve stok degisimlerini takip et.',
          color: AppColors.adminPrimary,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBooksScreen()),
            );
            _loadData();
          },
        ),
        const SizedBox(height: 10),
        _buildMenuCard(
          icon: Icons.restore_rounded,
          title: 'Demo Kontrol Paneli',
          subtitle: 'Sistemi boz, sifirla ve sunum akisini hizla yonet.',
          color: Colors.deepOrange,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResetDemoScreen()),
            );
            _loadData();
          },
        ),
        const SizedBox(height: 10),
        _buildMenuCard(
          icon: Icons.group_outlined,
          title: 'Kullanici Yonetimi',
          subtitle:
              'Yeni kullanici ekle, rolleri gor ve demo hesaplarini yonet.',
          color: Colors.teal,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            );
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBooks() {
    if (_topBooks.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: AppEmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Satis verisi yok',
            message:
                'Ilk satin alma islemi sonrasinda cok satan kitaplar burada gorunecek.',
            color: AppColors.adminPrimary,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _topBooks.asMap().entries.map((entry) {
            final i = entry.key;
            final book = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i == _topBooks.length - 1 ? 0 : 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (i < 3 ? AppColors.adminPrimary : Colors.grey)
                          .withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < 3
                            ? AppColors.adminPrimary
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'] as String? ?? 'Silinmis Kitap',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book['author'] as String? ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(book['total_sold'] as num?)?.toInt() ?? 0} adet',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${((book['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} TL',
                        style: const TextStyle(color: AppColors.adminPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    if (_monthlySummary.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: AppEmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'Aylik rapor hazir degil',
            message:
                'Veri geldikce aylik satis ve gelir ozeti otomatik listelenecek.',
            color: AppColors.adminPrimary,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _monthlySummary.map((row) {
            final month = row['month'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.adminSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatMonth(month),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(row['sale_count'] as num?)?.toInt() ?? 0} satis',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(row['total_quantity'] as num?)?.toInt() ?? 0} adet',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${((row['total_revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} TL',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.adminPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    if (_recentSales.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Satis hareketi yok',
            message:
                'Kullanicilar satin alma yaptikca son satislar burada gorunecek.',
            color: AppColors.adminPrimary,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentSales.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sale = _recentSales[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            minVerticalPadding: 10,
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.adminPrimary.withAlpha(18),
              child: const Icon(Icons.receipt, color: AppColors.adminPrimary),
            ),
            title: Text(
              sale.bookTitle ?? 'Silinmis Kitap',
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${sale.userName ?? "Bilinmeyen"} - ${sale.quantity} adet',
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sale.totalPrice.toStringAsFixed(2)} TL',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.adminPrimary,
                  ),
                ),
                Text(
                  _formatDate(sale.saleDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMonth(String yyyyMm) {
    if (yyyyMm.length < 7) return yyyyMm;
    final months = [
      'Oca',
      'Sub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Agu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final parts = yyyyMm.split('-');
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    return '${months[monthIndex - 1]} ${parts[0]}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 170;
          final padding = compact ? 14.0 : 18.0;
          final iconBox = compact ? 38.0 : 44.0;
          final valueFont = compact ? 18.0 : 22.0;
          final titleFont = compact ? 12.0 : 14.0;
          final gap = compact ? 10.0 : 14.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: compact ? 20 : 24),
                ),
                SizedBox(height: gap),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: valueFont,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: titleFont,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
