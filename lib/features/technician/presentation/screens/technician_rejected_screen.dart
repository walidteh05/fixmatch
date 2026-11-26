import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

import 'package:fixmatch/core/widgets/auth_primary_button.dart';

class TechnicianRejectedScreen extends StatelessWidget {
  const TechnicianRejectedScreen({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 72,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ใบสมัครช่างไม่ผ่านการอนุมัติ',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge,
                  ),
                  if (reason.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      reason.trim(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  AuthPrimaryButton(
                    text: 'กลับสู่หน้าเข้าสู่ระบบ',
                    onPressed: () => context.goNamed(AppRoute.welcome),
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
