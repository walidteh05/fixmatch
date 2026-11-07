import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';

class EmailAvailabilityResult {
  const EmailAvailabilityResult({
    required this.exists,
    this.accountType,
    this.technicianStatus,
  });

  final bool exists;
  final String? accountType;
  final String? technicianStatus;

  factory EmailAvailabilityResult.fromJson(Map<String, dynamic> json) {
    final rawAccountType = (json['account_type'] ?? json['accountType'])
        ?.toString();
    final normalizedAccountType = rawAccountType?.trim();

    final rawTechnicianStatus =
        (json['technician_status'] ?? json['technicianStatus'])?.toString();
    final normalizedTechnicianStatus = rawTechnicianStatus?.trim();

    return EmailAvailabilityResult(
      exists: json['exists'] == true,
      accountType:
          normalizedAccountType != null && normalizedAccountType.isNotEmpty
          ? normalizedAccountType
          : null,
      technicianStatus:
          normalizedTechnicianStatus != null &&
              normalizedTechnicianStatus.isNotEmpty
          ? normalizedTechnicianStatus
          : null,
    );
  }

  bool get isPendingTechnician =>
      exists &&
      accountType?.toLowerCase() == 'technician' &&
      technicianStatus?.toLowerCase() == 'pending';
}

class RegisterEmailScreen extends StatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isCheckingEmail = false;
  String? _emailAvailabilityError;

  static const primaryBlue = Color(0xFF2979FF);
  static const textDark = Color(0xFF1E242B);
  static const textMuted = Color(0xFF6C7A89);
  static const borderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    if (_emailAvailabilityError != null) {
      return _emailAvailabilityError;
    }

    return null;
  }

  Future<void> _onContinue() async {
    if (_isCheckingEmail) return;

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _isCheckingEmail = true;
      _emailAvailabilityError = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'check-email',
        body: {'email': email},
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid response from check-email');
      }

      final result = EmailAvailabilityResult.fromJson(
        Map<String, dynamic>.from(data),
      );

      if (!mounted) return;

      if (!result.exists) {
        context.pushNamed(
          AppRoute.welcomeNewMember,
          queryParameters: {'email': email},
        );
        return;
      }

      if (result.isPendingTechnician) {
        context.goNamed(AppRoute.pendingApproval);
        return;
      }

      setState(() {
        _emailAvailabilityError = 'อีเมลนี้ถูกใช้งานแล้ว';
      });

      _formKey.currentState!.validate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _emailAvailabilityError =
            'ไม่สามารถตรวจสอบอีเมลได้ กรุณาลองใหม่อีกครั้ง';
      });

      _formKey.currentState!.validate();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              context.goNamed(AppRoute.welcome);
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

                        // โลโก้งานซ่อมสไตล์โมเดิร์น
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF82D2FF), Color(0xFF2979FF)],
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

                        // หัวข้อและคำอธิบาย
                        const Text(
                          'สร้างบัญชี FixMatch',
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
                          'กรอกอีเมลของคุณเพื่อเริ่มต้นสมัครสมาชิก',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Label ฟิลด์อีเมล
                        const Text(
                          'กรอกอีเมล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ช่องกรอกอีเมล
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isCheckingEmail,
                          style: const TextStyle(fontSize: 15, color: textDark),
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
                          validator: _emailValidator,
                          onChanged: (value) {
                            if (_emailAvailabilityError != null) {
                              setState(() {
                                _emailAvailabilityError = null;
                              });

                              _formKey.currentState!.validate();
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // ปุ่มดำเนินการต่อ
                        SizedBox(
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF388BFF), Color(0xFF1E67FF)],
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
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isCheckingEmail ? null : _onContinue,
                              child: _isCheckingEmail
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
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

                        const SizedBox(height: 20),

                        // ลิงก์เข้าสู่ระบบ
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'มีบัญชีผู้ใช้อยู่แล้ว? ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: textMuted,
                              ),
                              children: [
                                TextSpan(
                                  text: 'เข้าสู่ระบบ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.goNamed(AppRoute.loginEmail);
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // ส่วนท้าย: ต้องการความช่วยเหลือ
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Center(
                            child: InkWell(
                              onTap: () {},
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
