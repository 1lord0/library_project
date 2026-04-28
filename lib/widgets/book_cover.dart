import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

class BookCover extends StatelessWidget {
  final String title;
  final String? category;
  final String? imageUrl;
  final double width;
  final double height;
  final Color? accentColor;

  const BookCover({
    super.key,
    required this.title,
    this.category,
    this.imageUrl,
    required this.width,
    required this.height,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final compact = height < 100;
    final borderRadius = BorderRadius.circular(compact ? 16 : 20);

    // If we have a network image URL, show it with a fallback
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: (_resolveColors().first).withAlpha(45),
              blurRadius: compact ? 12 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildGradientFallback(compact, borderRadius);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildGradientFallback(compact, borderRadius);
            },
          ),
        ),
      );
    }

    return _buildGradientFallback(compact, borderRadius);
  }

  Widget _buildGradientFallback(bool compact, BorderRadius borderRadius) {
    final colors = _resolveColors();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: colors.first.withAlpha(45),
            blurRadius: compact ? 12 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned(
              top: compact ? 6 : 10,
              left: compact ? 8 : 10,
              right: compact ? 8 : 10,
              child: Text(
                category ?? 'Kitap',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: compact ? 8.5 : 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Align(
              alignment: compact
                  ? const Alignment(0, -0.1)
                  : const Alignment(0, -0.05),
              child: Text(
                _initials(title),
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: compact ? 22 : 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Positioned(
              left: compact ? 8 : 10,
              right: compact ? 8 : 10,
              bottom: compact ? 8 : 12,
              child: Text(
                title,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 9.5 : 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _resolveColors() {
    if (accentColor != null) {
      return [
        accentColor!,
        Color.lerp(accentColor, Colors.black, 0.22) ?? accentColor!,
      ];
    }

    switch (category) {
      case 'Roman':
        return const [Color(0xFF7A3E2B), Color(0xFFB76D4C)];
      case 'Bilim Kurgu':
        return const [Color(0xFF19376D), Color(0xFF3D7BFF)];
      case 'Tarih':
        return const [Color(0xFF5E3A1F), Color(0xFF9D7240)];
      case 'Kisisel Gelisim':
        return const [Color(0xFF12664F), Color(0xFF2E9B78)];
      case 'Felsefe':
        return const [Color(0xFF4A377A), Color(0xFF7B63B8)];
      case 'Siir':
        return const [Color(0xFF8C2F39), Color(0xFFD96C7A)];
      case 'Bilim':
        return const [Color(0xFF17594A), Color(0xFF2CB89A)];
      default:
        return [AppColors.primaryDark, AppColors.primaryLight];
    }
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();

    if (words.isEmpty) return 'BK';
    if (words.length == 1) {
      final word = words.first;
      return word.length >= 2 ? word.substring(0, 2).toUpperCase() : word.toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
