import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../models/cart_item_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/book_cover.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  int get _userId => context.read<AuthService>().currentUser!.id!;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _cartService.getCartItems(_userId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Sepet verisi yuklenemedi.';
        _isLoading = false;
      });
    }
  }

  double get _totalPrice => _items.fold(0, (sum, item) => sum + item.lineTotal);

  bool get _hasStockIssue => _items.any((item) {
    final stock = item.bookStock ?? 0;
    return stock <= 0 || item.quantity > stock;
  });

  Future<void> _checkout() async {
    if (_items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Satin Alma Onayi'),
        content: Text(
          'Toplam ${_totalPrice.toStringAsFixed(2)} TL odeyeceksiniz. Onayliyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _cartService.checkout(_userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satin alma basarili!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: AppColors.error,
        ),
      );
      await _loadCart();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satin alma sirasinda bir sorun olustu.'),
          backgroundColor: AppColors.error,
        ),
      );
      await _loadCart();
    }
  }

  Future<void> _changeQuantity(CartItemModel item, int nextQuantity) async {
    try {
      await _cartService.updateQuantity(item.id!, nextQuantity);
      await _loadCart();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: AppColors.error,
        ),
      );
      await _loadCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.cart)),
      body: _isLoading
          ? const AppLoadingView(
              title: 'Sepet hazirlaniyor',
              subtitle: 'Eklenen urunler listeleniyor.',
            )
          : _errorMessage != null
          ? AppErrorState(message: _errorMessage!, onRetry: _loadCart)
          : _items.isEmpty
          ? const AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Sepetiniz bos',
              message:
                  'Kitap listesinden urun eklediginizde sepetiniz burada gorunecek.',
            )
          : AppResponsiveBody(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: AppHeroPanel(
                      primaryColor: AppColors.primaryDark,
                      secondaryColor: AppColors.primaryLight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alisveris Ozeti',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_items.length} urun, toplam ${_totalPrice.toStringAsFixed(2)} TL',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final stock = item.bookStock ?? 0;
                        final canIncrease = stock > item.quantity;
                        final stockLabel = stock > 0
                            ? 'Stok: $stock'
                            : 'Stokta yok';
                        final stockColor = stock > 0
                            ? AppColors.textSecondary
                            : AppColors.error;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BookCover(
                                  title: item.bookTitle ?? 'Kitap',
                                  imageUrl: item.bookImageUrl,
                                  width: 48,
                                  height: 68,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.bookTitle ?? 'Kitap',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.bookAuthor ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stockLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: stockColor,
                                          fontWeight: stock > 0
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${item.lineTotal.toStringAsFixed(2)} TL',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () => _changeQuantity(
                                            item,
                                            item.quantity - 1,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: canIncrease
                                              ? () => _changeQuantity(
                                                  item,
                                                  item.quantity + 1,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await _cartService.removeFromCart(
                                          item.id!,
                                        );
                                        _loadCart();
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      label: const Text('Kaldir'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_hasStockIssue)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Sepette stok problemi olan urunler var. Satin alma oncesi adetleri duzeltin.',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Toplam',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_totalPrice.toStringAsFixed(2)} TL',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _items.isNotEmpty && !_hasStockIssue
                                      ? _checkout
                                      : null,
                                  icon: const Icon(Icons.payment),
                                  label: const Text(AppStrings.buyNow),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
