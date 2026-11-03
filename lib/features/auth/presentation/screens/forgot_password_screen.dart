import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/auth_primary_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'ตั้งรหัสผ่านใหม่',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'ระบบรีเซ็ตรหัสผ่านจะพร้อมใช้งานเมื่อ Supabase Auth ถูกผนวกเข้ามาในภายหลัง',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                text: 'กลับสู่หน้าเข้าสู่ระบบ',
                onPressed: () {
                  context.goNamed(AppRoute.loginEmail);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
