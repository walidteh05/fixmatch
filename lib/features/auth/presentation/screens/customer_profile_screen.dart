import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../application/auth_providers.dart';
import '../../domain/account_type.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.email,
    this.accountType = AccountType.customer,
  });

  final String email;
  final AccountType accountType;

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกข้อมูล';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }
    if (!RegExp(r'^\+?[0-9\s-]{9,15}$').hasMatch(trimmed)) {
      return 'กรุณากรอกหมายเลขโทรศัพท์ที่ถูกต้อง';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 8) {
      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    }
    return null;
  }

  String _friendlyAuthMessage(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('user already registered') ||
          message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('email') && message.contains('used')) {
        return 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      }

      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials')) {
        return 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง';
      }

      if (message.contains('network')) {
        return 'เกิดปัญหาเครือข่าย กรุณาลองใหม่อีกครั้ง';
      }

      if (message.contains('password')) {
        return 'รหัสผ่านไม่ผ่านเงื่อนไขความปลอดภัย';
      }

      return error.message;
    }

    return 'เกิดข้อผิดพลาดในการสมัครสมาชิก กรุณาลองใหม่อีกครั้ง';
  }

  Future<void> _submitCustomerRegistration() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับข้อกำหนดและนโยบายความเป็นส่วนตัว'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        metadata: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'customer',
        },
      );

      final hasSession = response.session != null;
      final user = response.user;

      if (!mounted) {
        return;
      }

      if (hasSession && user != null) {
        context.goNamed(AppRoute.customerHome);
        return;
      }

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthMessage(error)),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Customer sign up failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสมัครสมาชิก กรุณาลองใหม่อีกครั้ง'),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลส่วนตัว',
                      style: AppTextStyles.headingLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรอกข้อมูลเพื่อสร้างบัญชีลูกค้า',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      label: 'ชื่อ-นามสกุล',
                      hintText: 'กรอกชื่อของคุณ',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'อีเมล',
                      hintText: 'you@example.com',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      readOnly: true,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'เบอร์โทรศัพท์',
                      hintText: '0812345678',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'รหัสผ่าน',
                      hintText: 'อย่างน้อย 8 ตัวอักษร',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _passwordValidator,
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'ยืนยันรหัสผ่าน',
                      hintText: 'กรอกรหัสผ่านอีกครั้ง',
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณายืนยันรหัสผ่าน';
                        }
                        if (value != _passwordController.text) {
                          return 'รหัสผ่านไม่ตรงกัน';
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      title: Text(
                        'ฉันยอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัว',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthPrimaryButton(
                      text: _isSubmitting ? 'กำลังสมัคร...' : 'สร้างบัญชี',
                      onPressed: _isSubmitting ? null : _submitCustomerRegistration,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
