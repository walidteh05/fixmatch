import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../application/auth_providers.dart';

String? validateLoginPassword(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'กรุณากรอกรหัสผ่าน';
  }
  if (value.trim().length < 8) {
    return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
  }
  return null;
}

class LoginPasswordScreen extends ConsumerStatefulWidget {
  const LoginPasswordScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<LoginPasswordScreen> createState() =>
      _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends ConsumerState<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(Object error) {
    final message = error is AuthException ? error.message : error.toString();
    final lowered = message.toLowerCase();

    if (lowered.contains('invalid login credentials') ||
        lowered.contains('invalid credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }

    if (lowered.contains('email not confirmed') ||
        lowered.contains('not confirmed') ||
        lowered.contains('email is not confirmed')) {
      return 'อีเมลยังไม่ได้ยืนยันตัวตน กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
    }

    if (lowered.contains('too many requests') ||
        lowered.contains('rate limit') ||
        lowered.contains('too many')) {
      return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่อีกครั้งในภายหลัง';
    }

    if (lowered.contains('network')) {
      return 'เกิดปัญหาเครือข่าย กรุณาลองใหม่อีกครั้ง';
    }

    if (lowered.contains('password')) {
      return 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง กรุณาตรวจสอบรหัสผ่านอีกครั้ง';
    }

    return 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่อีกครั้ง';
  }

  Future<void> _resolveAndRouteAfterLogin(User user) async {
    final client = Supabase.instance.client;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.of(context);

    final profileResponse = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) {
      return;
    }

    if (profileResponse == null || profileResponse['role'] == null) {
      await ref.read(authRepositoryProvider).signOut();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลโปรไฟล์ผู้ใช้งาน กรุณาลองใหม่อีกครั้ง'),
        ),
      );
      return;
    }

    final role = profileResponse['role'].toString().toLowerCase();

    if (role == 'customer') {
      if (!mounted) {
        return;
      }
      router.goNamed(AppRoute.customerHome);
      return;
    }

    if (role == 'technician') {
      final technicianResponse = await client
          .from('technician_profiles')
          .select('status')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      final technicianStatus = (technicianResponse?['status'] ?? 'pending')
          .toString()
          .toLowerCase();

      switch (technicianStatus) {
        case 'pending':
          router.goNamed(AppRoute.pendingApproval);
          break;
        case 'approved':
          router.goNamed(AppRoute.technicianHome);
          break;
        case 'rejected':
          await ref.read(authRepositoryProvider).signOut();
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('บัญชีช่างของคุณถูกปฏิเสธการสมัคร กรุณาติดต่อผู้ดูแลระบบ'),
            ),
          );
          break;
        case 'suspended':
          await ref.read(authRepositoryProvider).signOut();
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('บัญชีช่างของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ'),
            ),
          );
          break;
        default:
          await ref.read(authRepositoryProvider).signOut();
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('สถานะบัญชีช่างไม่พร้อมใช้งาน กรุณาติดต่อผู้ดูแลระบบ'),
            ),
          );
      }
      return;
    }

    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) {
      return;
    }

    messenger?.showSnackBar(
      const SnackBar(
        content: Text('บัญชีนี้ไม่สามารถเข้าสู่แอปมือถือได้ กรุณาติดต่อผู้ดูแลระบบ'),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.signInWithPassword(
        email: widget.email.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        throw const AuthException('Login failed. No active session was created.');
      }

      await _resolveAndRouteAfterLogin(user);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(error)),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      debugPrint('Profile lookup failed: ${error.message}');
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถตรวจสอบข้อมูลผู้ใช้งานได้ กรุณาลองใหม่อีกครั้ง'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      debugPrint('Login error: $error');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2979FF);
    const textDark = Color(0xFF1E242B);
    const textMuted = Color(0xFF6C7A89);
    const borderColor = Color(0xFFE2E8F0);
    const cardBgColor = Color(0xFFF4F8FD);

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
              context.goNamed(AppRoute.loginEmail);
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

                        // หัวข้อและคำอธิบายสไตล์ Minimal
                        const Text(
                          'กรอกรหัสผ่าน',
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
                          'เข้าสู่ระบบด้วยบัญชีของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // การ์ดแสดงอีเมลที่เลือก พร้อมปุ่มเปลี่ยน
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryBlue.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'อีเมลเข้าใช้งาน',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.goNamed(AppRoute.loginEmail);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'เปลี่ยน',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Label รหัสผ่าน
                        const Text(
                          'รหัสผ่าน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ช่องกรอกรหัสผ่านแบบ Minimal
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'กรอกรหัสผ่านของคุณ',
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
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ),
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
                          validator: validateLoginPassword,
                        ),
                        const SizedBox(height: 8),

                        // ลิงก์ลืมรหัสผ่าน
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.pushNamed(AppRoute.forgotPassword);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ปุ่ม "เข้าสู่ระบบ" โทนฟ้า Gradient
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
                              onPressed: _isSubmitting ? null : _handleLogin,
                              child: Text(
                                _isSubmitting ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // ส่วนท้าย: "ต้องการความช่วยเหลือ? ติดต่อเรา"
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 16),
                          child: Center(
                            child: InkWell(
                              onTap: () {
                                // Action ซัพพอร์ต
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