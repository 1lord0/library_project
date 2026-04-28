import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../services/seed_service.dart';
import '../widgets/app_state_widgets.dart';

class ResetDemoScreen extends StatefulWidget {
  const ResetDemoScreen({super.key});

  @override
  State<ResetDemoScreen> createState() => _ResetDemoScreenState();
}

class _ResetDemoScreenState extends State<ResetDemoScreen> {
  final SeedService _seedService = SeedService();
  bool _isProcessing = false;
  String? _statusMessage;
  bool? _isSuccess;

  Future<void> _breakSystem() async {
    final confirmed = await _showConfirmDialog(
      title: AppStrings.messUpSystem,
      message:
          'Sisteme sacma veriler eklenecek.\nDashboard ve kitap listesi bozulacak.\n\nDevam etmek istiyor musunuz?',
      confirmText: 'Evet, Boz!',
      confirmColor: Colors.orange,
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    await _seedService.breakSystem();

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage =
          'Sistem bilerek bozuldu. Sacma kitaplar, test kullanicilari ve rastgele satislar dashboard verilerini degistirdi.';
      _isSuccess = true;
    });
  }

  Future<void> _resetToDemo() async {
    final confirmed = await _showConfirmDialog(
      title: AppStrings.resetDemo,
      message:
          'Tum veriler silinecek ve demo verileri tekrar yuklenecek.\n\nBu islem geri alinamaz. Devam etmek istiyor musunuz?',
      confirmText: 'Evet, Sifirla!',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    await _seedService.resetToDemoData();

    if (!mounted) return;

    // Reset sonrasi mevcut admin oturumunu yeniden olustur
    final auth = context.read<AuthService>();
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      await auth.login(currentUser.email, currentUser.password);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage =
          'Temiz demo veri geri yuklendi. Sahte kullanicilar, sacma kitaplar ve bozuk satislar silindi.';
      _isSuccess = true;
    });
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Kontrol Paneli'),
        backgroundColor: AppColors.adminPrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;
            final verticalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;

            return SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeroPanel(
                          primaryColor: AppColors.adminDark,
                          secondaryColor: AppColors.adminPrimary,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sunum Modu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bu ekran hocaya gosterilecek ana senaryoyu tek yerden yonetmek icin tasarlandi.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: AppColors.adminSurface,
                          margin: EdgeInsets.zero,
                          child: const Padding(
                            padding: EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSectionHeader(
                                  title: 'Demo Senaryosu',
                                  subtitle:
                                      'Sunum akisini kaybetmeden adim adim ilerleyin.',
                                  icon: Icons.slideshow_outlined,
                                  color: AppColors.adminPrimary,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  '1. Admin ile giris yapip dashboard ozetini gosterin\n'
                                  '2. Kitap Yonetimi ekraninda bir iki veri degistirin\n'
                                  '3. "Sistemi Boz" ile test verilerini sisteme doldurun\n'
                                  '4. Dashboard ve kitap listesindeki degisimi gosterin\n'
                                  '5. "Demo Verilerine Sifirla" ile her seyi temiz hale getirin',
                                  style: TextStyle(height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ActionCard(
                          icon: Icons.bug_report_outlined,
                          title: AppStrings.messUpSystem,
                          description:
                              '30 sacma kitap, 10 test kullanici ve rastgele satislar ekler. Dashboard ile kitap listesini bilerek bozar.',
                          buttonText: 'Sistemi Boz',
                          buttonColor: Colors.orange,
                          buttonIcon: Icons.warning_amber_rounded,
                          onPressed: _isProcessing ? null : _breakSystem,
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: Icons.restore_rounded,
                          title: AppStrings.resetDemo,
                          description:
                              'Tum tablolari temizler ve seed servisi ile demo verilerini yeniden yukler. Sunum icin temiz hale getirir.',
                          buttonText: 'Demo Verilerine Sifirla',
                          buttonColor: AppColors.error,
                          buttonIcon: Icons.refresh_rounded,
                          onPressed: _isProcessing ? null : _resetToDemo,
                        ),
                        const SizedBox(height: 20),
                        if (_isProcessing)
                          const Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: AppLoadingView(
                                title: 'Islem devam ediyor',
                                subtitle:
                                    'Veritabani uzerinde degisiklikler uygulaniyor.',
                                color: AppColors.adminPrimary,
                              ),
                            ),
                          ),
                        if (_statusMessage != null && !_isProcessing)
                          Card(
                            color: _isSuccess == true
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSuccess == true
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _isSuccess == true
                                        ? Colors.green
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _statusMessage!,
                                      style: TextStyle(
                                        color: _isSuccess == true
                                            ? Colors.green.shade800
                                            : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color buttonColor;
  final IconData buttonIcon;
  final VoidCallback? onPressed;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonColor,
    required this.buttonIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: buttonColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(buttonIcon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
