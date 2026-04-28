import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_state_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  int get _currentUserId => context.read<AuthService>().currentUser!.id!;
  int get _adminCount => _users.where((user) => user.isAdmin).length;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _userService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kullanici listesi yuklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddUserSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddUserSheet(onSubmit: _createUser),
    );

    if (created == true) {
      await _loadUsers();
    }
  }

  Future<void> _createUser(UserModel user) async {
    if (await _userService.emailExists(user.email.trim())) {
      throw StateError('Bu e-posta zaten kullaniliyor.');
    }

    await _userService.createUser(
      user.copyWith(
        name: user.name.trim(),
        email: user.email.trim(),
        password: user.password.trim(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name} kullanicisi eklendi.')),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (user.id == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktif oturumdaki admin hesabi silinemez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (user.isAdmin && _adminCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistemde en az bir admin kalmalidir.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullaniciyi Sil'),
        content: Text(
          '"${user.name}" kullanicisini silmek istediginize emin misiniz?',
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

    if (confirmed != true) return;

    await _userService.deleteUser(user.id!);
    await _loadUsers();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${user.name} silindi.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanici Yonetimi'),
        backgroundColor: AppColors.adminPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddUserSheet,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Yeni Kullanici'),
      ),
      body: _isLoading
          ? const AppLoadingView(
              title: 'Kullanicilar hazirlaniyor',
              subtitle: 'Admin ve normal hesaplar listeleniyor.',
              color: AppColors.adminPrimary,
            )
          : _errorMessage != null
          ? AppErrorState(
              message: _errorMessage!,
              onRetry: _loadUsers,
              color: AppColors.adminPrimary,
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 380
                      ? 12.0
                      : 16.0;
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kullanici Kontrolu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_users.length} toplam hesap, $_adminCount admin ve ${_users.length - _adminCount} normal kullanici aktif durumda.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadUsers,
                                child: _users.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 48),
                                          AppEmptyState(
                                            icon: Icons.group_off_outlined,
                                            title: 'Kullanici yok',
                                            message:
                                                'Yeni kullanici ekleyerek listeyi doldurabilirsiniz.',
                                            color: AppColors.adminPrimary,
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(
                                          bottom: 90,
                                        ),
                                        itemCount: _users.length,
                                        itemBuilder: (context, index) {
                                          final user = _users[index];
                                          return _UserCard(
                                            user: user,
                                            isCurrentUser:
                                                user.id == _currentUserId,
                                            onDelete: () => _deleteUser(user),
                                          );
                                        },
                                      ),
                              ),
                            ),
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
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin ? AppColors.adminPrimary : Colors.teal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: roleColor.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.isAdmin ? 'Admin' : 'Kullanici',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sifre: ${user.password}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isCurrentUser ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: isCurrentUser ? 'Aktif hesap' : 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}

class _AddUserSheet extends StatefulWidget {
  final Future<void> Function(UserModel user) onSubmit;

  const _AddUserSheet({required this.onSubmit});

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'user';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        UserModel(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message.toString();
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kullanici eklenemedi.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yeni Kullanici Ekle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin veya normal kullanici hesabini hizlica olusturun.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Gecerli bir e-posta girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Sifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sifre gerekli';
                  }
                  if (value.trim().length < 3) {
                    return 'En az 3 karakter girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Kullanici')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _role = value);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
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
                      : const Icon(Icons.person_add_alt_1),
                  label: const Text('Kullaniciyi Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
