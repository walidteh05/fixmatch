import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/technician_status.dart';
import '../widgets/auth_primary_button.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const status = TechnicianStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ส่งใบสมัครเรียบร้อยแล้ว',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'บัญชีของคุณกำลังรอการตรวจสอบจากทีมงาน FixMatch',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.label,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ช่างจะไม่สามารถรับงานหรือจองคิวได้จนกว่าจะได้รับการอนุมัติจากแอดมิน',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AuthPrimaryButton(
                    text: 'กลับสู่หน้าเข้าสู่ระบบ',
                    onPressed: () {
                      context.goNamed(AppRoute.welcome);
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    text: 'ตรวจสอบสถานะคำขอ',
                    isSecondary: true,
                    onPressed: () {
                      context.goNamed(AppRoute.technicianHome);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
