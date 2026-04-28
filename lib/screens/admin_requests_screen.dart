import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/book_request_model.dart';
import '../services/book_request_service.dart';
import '../widgets/app_state_widgets.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final BookRequestService _requestService = BookRequestService();

  List<BookRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _requestService.getAllRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Istekler yuklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(BookRequestModel request, String status) async {
    await _requestService.updateStatus(request.id!, status);
    _loadRequests();
    if (!mounted) return;
    final label = status == 'approved' ? 'onaylandi' : 'reddedildi';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${request.title}" $label')),
    );
  }

  Future<void> _deleteRequest(BookRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Istegi Sil'),
        content: Text('"${request.title}" istegini silmek istiyor musunuz?'),
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
      await _requestService.deleteRequest(request.id!);
      _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Istekleri'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: _isLoading
          ? const AppLoadingView(
              title: 'Istekler yukleniyor',
              subtitle: 'Kullanici talepleri getiriliyor.',
              color: AppColors.adminPrimary,
            )
          : _errorMessage != null
              ? AppErrorState(
                  message: _errorMessage!,
                  onRetry: _loadRequests,
                  color: AppColors.adminPrimary,
                )
              : _requests.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Henuz istek yok',
                      message:
                          'Kullanicilar kitap istegi gonderdiginde burada gorunecek.',
                      color: AppColors.adminPrimary,
                    )
                  : SafeArea(
                      child: RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                return _RequestCard(
                                  request: _requests[index],
                                  onApprove: () => _updateStatus(
                                    _requests[index],
                                    'approved',
                                  ),
                                  onReject: () => _updateStatus(
                                    _requests[index],
                                    'rejected',
                                  ),
                                  onDelete: () =>
                                      _deleteRequest(_requests[index]),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BookRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    request.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (_formatDate(request.createdAt) != null)
                  Text(
                    _formatDate(request.createdAt)!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.author,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (request.userName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Talep eden: ${request.userName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.adminSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.isPending) ...[
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reddet'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Onayla'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ] else
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Sil'),
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
  }

  String? _formatDate(String? dateStr) {
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
