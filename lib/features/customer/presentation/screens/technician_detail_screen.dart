import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/customer_marketplace_repository.dart';

class TechnicianDetailScreen extends StatelessWidget {
  const TechnicianDetailScreen({super.key, this.technician});

  final RecommendedTechnician? technician;

  @override
  Widget build(BuildContext context) {
    final current = technician;
    if (current == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('\u{3f}\u{3f}\u{3f}\u{3f}')),
        body: const Center(
          child: Text(
            '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
          ),
        ),
      );
    }

    final categories = current.serviceCategories.toList()..sort();
    final initial = current.fullName.trim().isEmpty
        ? '?'
        : current.fullName.trim().characters.first.toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      initial,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(current.fullName, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 6),
                  Text(
                    categories.isEmpty
                        ? '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}'
                        : categories.join(' · '),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (current.serviceArea?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _DetailCard(
              icon: Icons.location_on_outlined,
              title: '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
              value: current.serviceArea!,
            ),
          ],
          if (current.bio?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _DetailCard(
              icon: Icons.info_outline_rounded,
              title: '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
              value: current.bio!,
            ),
          ],
          const SizedBox(height: 12),
          const _DetailCard(
            icon: Icons.star_border_rounded,
            title: '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
            value: '\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}\u{3f}',
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label),
                  const SizedBox(height: 5),
                  Text(value, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
