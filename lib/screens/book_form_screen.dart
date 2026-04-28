import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/app_strings.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../widgets/app_state_widgets.dart';

class BookFormScreen extends StatefulWidget {
  final BookModel? book;

  const BookFormScreen({super.key, this.book});

  bool get isEditing => book != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BookService _bookService = BookService();

  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  final _defaultCategories = [
    'Roman',
    'Bilim Kurgu',
    'Tarih',
    'Kisisel Gelisim',
    'Felsefe',
    'Siir',
    'Bilim',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _categoryController = TextEditingController(
      text: widget.book?.category ?? '',
    );
    _priceController = TextEditingController(
      text: widget.book?.price.toStringAsFixed(2) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.book?.stock.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final book = BookModel(
      id: widget.book?.id,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      category: _categoryController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdAt: widget.book?.createdAt,
    );

    if (widget.isEditing) {
      await _bookService.updateBook(book);
    } else {
      await _bookService.insertBook(book);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? AppStrings.editBook : AppStrings.addBook;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;
            final verticalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            return SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            margin: EdgeInsets.zero,
                            color: AppColors.adminSurface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: AppSectionHeader(
                                title: title,
                                subtitle: widget.isEditing
                                    ? 'Kitabin bilgilerini guncelleyip kaydedin.'
                                    : 'Yeni kitap bilgisini hizlica veritabanina ekleyin.',
                                icon: widget.isEditing
                                    ? Icons.edit_note
                                    : Icons.library_add,
                                color: AppColors.adminPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Kitap Adi',
                              prefixIcon: Icon(Icons.book),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Kitap adi gerekli'
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _authorController,
                            decoration: const InputDecoration(
                              labelText: 'Yazar',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Yazar gerekli'
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          Autocomplete<String>(
                            initialValue: _categoryController.value,
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _defaultCategories;
                              }
                              return _defaultCategories.where(
                                (c) => c.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ),
                              );
                            },
                            onSelected: (selection) {
                              _categoryController.text = selection;
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                                  controller.text = _categoryController.text;
                                  controller.addListener(() {
                                    _categoryController.text = controller.text;
                                  });
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori',
                                      prefixIcon: Icon(Icons.category),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Kategori gerekli'
                                        : null,
                                    textInputAction: TextInputAction.next,
                                  );
                                },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Fiyat (TL)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Fiyat gerekli';
                              }
                              final price = double.tryParse(v.trim());
                              if (price == null) {
                                return 'Gecerli bir sayi girin';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stok',
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Stok gerekli';
                              }
                              final stock = int.tryParse(v.trim());
                              if (stock == null) {
                                return 'Gecerli bir tam sayi girin';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Aciklama (opsiyonel)',
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      widget.isEditing ? Icons.save : Icons.add,
                                    ),
                              label: Text(
                                widget.isEditing
                                    ? 'Kaydet'
                                    : AppStrings.addBook,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminPrimary,
                              ),
                            ),
                          ),
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
}
