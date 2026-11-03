import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/account_type.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';

class TechnicianApplicationScreen extends StatefulWidget {
  const TechnicianApplicationScreen({
    super.key,
    required this.email,
    this.accountType = AccountType.technician,
  });

  final String email;
  final AccountType accountType;

  @override
  State<TechnicianApplicationScreen> createState() =>
      _TechnicianApplicationScreenState();
}

class _TechnicianApplicationScreenState
    extends State<TechnicianApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serviceRadiusController = TextEditingController();
  final Set<String> _selectedCategories = {};
  final List<String> _serviceCategories = [
    'Air Conditioning',
    'Electrical',
    'Plumbing',
    'Home Appliance Repair',
    'Carpentry / Furniture',
    'Locksmith',
  ];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สมัครเป็นช่าง FixMatch',
                      style: AppTextStyles.headingLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรอกข้อมูลการสมัครและเอกสารยืนยันความสามารถ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'ข้อมูลส่วนตัว',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 28),
                    Text(
                      'ข้อมูลเชิงอาชีพ',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'หมวดบริการ',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceCategories.map((category) {
                        final selected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: AppColors.primaryLight,
                          checkmarkColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      label: 'ประสบการณ์ทำงาน (ปี)',
                      hintText: 'เช่น 5',
                      controller: _experienceController,
                      prefixIcon: Icons.work_outline,
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'รัศมีให้บริการ (กม.)',
                      hintText: 'เช่น 15',
                      controller: _serviceRadiusController,
                      prefixIcon: Icons.radio_button_checked_outlined,
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'พื้นที่ให้บริการ',
                      hintText: 'กรุงเทพมหานคร, สมุทรปราการ',
                      controller: _locationController,
                      prefixIcon: Icons.location_on_outlined,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'คำอธิบายเกี่ยวกับประสบการณ์',
                      hintText: 'อธิบายความเชี่ยวชาญของคุณ',
                      controller: _descriptionController,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'เอกสารยืนยัน',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _uploadPlaceholder('Identity verification document', Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _uploadPlaceholder('Professional certificate', Icons.school_outlined),
                          const SizedBox(height: 12),
                          _uploadPlaceholder('Portfolio image', Icons.image_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF9A641C),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'บัญชีช่างของคุณจะถูกกำหนดเป็นสถานะ pending จนกว่าผู้ดูแลระบบจะตรวจสอบและอนุมัติ',
                              style: AppTextStyles.bodySmall.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(
                      text: 'ส่งใบสมัคร',
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        if (_selectedCategories.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('กรุณาเลือกอย่างน้อย 1 หมวดบริการ'),
                            ),
                          );
                          return;
                        }
                        context.goNamed(AppRoute.pendingApproval);
                      },
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

  Widget _uploadPlaceholder(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            'Placeholder',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
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
    _experienceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }
}
