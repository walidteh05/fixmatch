import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

String? validateLoginEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'กรุณากรอกอีเมล';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'รูปแบบอีเมลไม่ถูกต้อง';
  }
  return null;
}

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      context.pushNamed(
        AppRoute.loginPassword,
        queryParameters: {'email': email},
      );
    }
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed(AppRoute.welcome);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2979FF);
    const textDark = Color(0xFF1E242B);
    const textMuted = Color(0xFF6C7A89);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: _onBack,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 440,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        // โลโก้งานซ่อมสไตล์โมเดิร์น โทนสีฟ้าไล่เฉดตามแบบภาพ
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
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
                              Icons.home_repair_service_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // หัวข้อและคำอธิบายสไตล์ Minimal
                        const Text(
                          'ยินดีต้อนรับสู่ FixMatch',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'เข้าสู่ระบบหรือสร้างบัญชีฟรี',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Label กรอกอีเมล
                        const Text(
                          'กรอกอีเมล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ช่องกรอกอีเมลแบบเรียบมน Minimal
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: borderColor,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: validateLoginEmail,
                        ),
                        const SizedBox(height: 20),

                        // ปุ่ม "ดำเนินการต่อ" โทนฟ้า Gradient มี Drop Shadow
                        SizedBox(
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF388BFF),
                                  Color(0xFF1E67FF),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _onContinue,
                              child: const Text(
                                'ดำเนินการต่อ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ดันเนื้อหาข้อความส่วนท้ายไปติดขอบล่างหน้าจอ
                        const Spacer(),

                        // ส่วนท้าย: "ต้องการความช่วยเหลือ? ติดต่อเรา" ตามแบบรูป
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Center(
                            child: InkWell(
                              onTap: () {
                                // Action สำหรับติดต่อซัพพอร์ต
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.help_outline_rounded,
                                      size: 16,
                                      color: textDark,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'ต้องการความช่วยเหลือ? ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textDark,
                                      ),
                                    ),
                                    Text(
                                      'ติดต่อเรา',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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