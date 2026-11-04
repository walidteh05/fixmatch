import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

enum AccountType { customer, technician }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serviceAreaController = TextEditingController();

  AccountType _accountType = AccountType.customer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  final List<String> _categories = [
    'แอร์และเครื่องทำความเย็น',
    'ระบบไฟฟ้า',
    'ระบบประปา',
    'เครื่องใช้ไฟฟ้า',
    'งานไม้และเฟอร์นิเจอร์',
    'งานกุญแจและประตู',
  ];

  final Set<String> _selectedCategories = {};

  static const primaryBlue = Color(0xFF2979FF);
  static const softBlue = Color(0xFFF4F8FD);
  static const textDark = Color(0xFF1E242B);
  static const textMuted = Color(0xFF6C7A89);
  static const borderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกข้อมูลในช่องนี้';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
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

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    if (_accountType == AccountType.technician && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกความถนัดอย่างน้อย 1 รายการ')),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณายอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _accountType == AccountType.customer
              ? 'ลงทะเบียนลูกค้าสำเร็จ'
              : 'ส่งใบสมัครช่างเรียบร้อยแล้ว',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('เลือกประเภทบัญชี'),
        Row(
          children: [
            Expanded(
              child: _roleCard(
                title: 'ลูกค้าทั่วไป',
                subtitle: 'หาบริการและช่างซ่อมบ้าน',
                icon: Icons.person_rounded,
                type: AccountType.customer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _roleCard(
                title: 'ช่างมืออาชีพ',
                subtitle: 'ลงทะเบียนรับงานซ่อม',
                icon: Icons.handyman_rounded,
                type: AccountType.technician,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required AccountType type,
  }) {
    final selected = _accountType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _accountType = type;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? softBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryBlue : borderColor,
            width: selected ? 1.8 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? primaryBlue : textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? primaryBlue : textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ข้อมูลความเชี่ยวชาญ'),
        const Text(
          'ประเภทงานที่เชี่ยวชาญ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final selected = _selectedCategories.contains(category);

            return FilterChip(
              label: Text(category),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? primaryBlue : textDark,
              ),
              selected: selected,
              backgroundColor: Colors.white,
              selectedColor: softBlue,
              side: BorderSide(
                color: selected ? primaryBlue : borderColor,
                width: selected ? 1.4 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'ประสบการณ์การทำงาน (ปี)',
          hint: 'เช่น 5',
          controller: _experienceController,
          keyboardType: TextInputType.number,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'พื้นที่ให้บริการ',
          hint: 'เช่น กรุงเทพฯ, นนทบุรี',
          controller: _serviceAreaController,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'แนะนำประวัติและผลงานเบื้องต้น',
          hint: 'อธิบายทักษะ ประสบการณ์ หรือความชำนาญของคุณ',
          controller: _descriptionController,
          maxLines: 3,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('เอกสารยืนยันตัวตน'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 28,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'อัปโหลดเอกสารยืนยันตัวตนและใบรับรอง',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'บัตรประชาชน / ใบประกอบวิชาชีพ (ถ้ามี)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_rounded,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'บัญชีช่างของคุณจะอยู่ในสถานะ "รอการตรวจสอบ" เพื่อความปลอดภัยของผู้ใช้งานทุกท่าน',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D4037), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'สร้างบัญชีผู้ใช้ใหม่',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'เริ่มต้นใช้งาน FixMatch เพื่อบริการที่ตรงใจคุณ',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildRoleSelector(),
                    const SizedBox(height: 28),

                    _buildSectionTitle('ข้อมูลส่วนตัว'),
                    _buildTextField(
                      label: 'ชื่อ - นามสกุล',
                      hint: 'กรอกชื่อและนามสกุลของคุณ',
                      controller: _nameController,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'อีเมล',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'เบอร์โทรศัพท์',
                      hint: 'เช่น 0812345678',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'รหัสผ่าน',
                      hint: 'อย่างน้อย 8 ตัวอักษร',
                      controller: _passwordController,
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
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'ยืนยันรหัสผ่าน',
                      hint: 'กรอกรหัสผ่านอีกครั้ง',
                      controller: _confirmPasswordController,
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
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    ),

                    if (_accountType == AccountType.technician) ...[
                      const SizedBox(height: 28),
                      _buildTechnicianFields(),
                    ],

                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                      activeColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'ฉันยอมรับเงื่อนไขการใช้งานและนโยบายความเป็นส่วนตัว',
                        style: TextStyle(
                          fontSize: 13,
                          color: textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มกดสร้างบัญชีโทนฟ้า Gradient
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
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleRegister,
                          child: Text(
                            _accountType == AccountType.customer
                                ? 'สร้างบัญชีผู้ใช้'
                                : 'ส่งใบสมัครช่าง',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
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
                    const SizedBox(height: 28),

                    // ลิงก์ติดต่อความช่วยเหลือด้านล่าง
                    Center(
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}