import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/auth_primary_button.dart';

class TechnicianHomeScreen extends StatelessWidget {
  const TechnicianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.handyman_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Technician Dashboard',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'พื้นที่สำหรับช่างที่รอการอนุมัติและจัดการงานภายหลัง',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                AuthPrimaryButton(
                  text: 'กลับสู่หน้าเริ่มต้น',
                  onPressed: () {
                    context.goNamed(AppRoute.welcome);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
