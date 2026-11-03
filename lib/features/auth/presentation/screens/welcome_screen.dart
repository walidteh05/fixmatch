import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/auth_primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'บริการซ่อมบ้าน เริ่มต้นได้ที่ FixMatch',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ค้นหาช่างมืออาชีพและบริการซ่อมบ้านที่ไว้ใจได้',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  AuthPrimaryButton(
                    text: 'เข้าสู่ระบบ',
                    onPressed: () {
                      context.pushNamed(AppRoute.loginEmail);
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    text: 'สมัครสมาชิก',
                    isSecondary: true,
                    onPressed: () {
                      context.pushNamed(AppRoute.registerEmail);
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
