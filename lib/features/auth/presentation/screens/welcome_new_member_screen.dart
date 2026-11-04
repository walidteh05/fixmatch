import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class WelcomeNewMemberScreen extends StatelessWidget {
  const WelcomeNewMemberScreen({
    super.key,
    required this.email,
  });

  final String email;

  static const primaryBlue = Color(0xFF2979FF);
  static const darkBlue = Color(0xFF1565C0);
  static const softBlue = Color(0xFFF4F8FD);
  static const textDark = Color(0xFF1E242B);
  static const textMuted = Color(0xFF6C7A89);
  static const borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final displayEmail = email.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.registerEmail);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: textDark,
          ),
          label: const Text(
            'กลับ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF82D2FF),
                            Color(0xFF2979FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'ยินดีต้อนรับสู่ FixMatch',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ดูเหมือนคุณเป็นสมาชิกใหม่ของ FixMatch',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'อีเมลของคุณ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayEmail.isNotEmpty ? displayEmail : 'อีเมลของคุณ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.pushNamed(
                          AppRoute.chooseAccountType,
                          queryParameters: {'email': displayEmail},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ดำเนินการสร้างบัญชี',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
