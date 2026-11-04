import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/account_type.dart';

class ChooseAccountTypeScreen extends StatefulWidget {
  const ChooseAccountTypeScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<ChooseAccountTypeScreen> createState() =>
      _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState extends State<ChooseAccountTypeScreen> {
  AccountType _selectedType = AccountType.customer;

  static const primaryBlue = Color(0xFF2979FF);
  static const softBlue = Color(0xFFF4F8FD);
  static const textDark = Color(0xFF1E242B);
  static const textMuted = Color(0xFF6C7A89);
  static const borderColor = Color(0xFFE2E8F0);

  void _onContinue() {
    if (_selectedType == AccountType.customer) {
      context.pushNamed(
        AppRoute.customerProfile,
        queryParameters: {
          'email': widget.email,
          'accountType': _selectedType.name,
        },
      );
      return;
    }

    context.pushNamed(
      AppRoute.technicianApplication,
      queryParameters: {
        'email': widget.email,
        'accountType': _selectedType.name,
      },
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required AccountType type,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? softBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : borderColor,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : softBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryBlue.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? primaryBlue : textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 13,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryBlue : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? primaryBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
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
              fontFamily: 'Prompt',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // หัวข้อหลักและคำอธิบาย
                      const Text(
                        'เลือกประเภทบัญชี',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'เลือกรูปแบบบัญชีที่ตรงกับความต้องการของคุณ',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // การ์ดผู้ใช้งานทั่วไป (Customer)
                      _buildTypeCard(
                        title: 'ลูกค้าทั่วไป (Customer)',
                        description: 'ค้นหาและจองบริการช่างซ่อมบ้านมืออาชีพ',
                        icon: Icons.person_rounded,
                        type: AccountType.customer,
                      ),
                      const SizedBox(height: 16),

                      // การ์ดช่างมืออาชีพ (Technician)
                      _buildTypeCard(
                        title: 'ช่างมืออาชีพ (Technician)',
                        description: 'รับงานซ่อมและสร้างรายได้ผ่านแพลตฟอร์ม',
                        icon: Icons.handyman_rounded,
                        type: AccountType.technician,
                      ),
                      const SizedBox(height: 20),

                      // กล่องข้อความแจ้งสิทธิ์ Admin
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: primaryBlue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'บัญชีผู้ดูแลระบบ (Admin) ไม่สามารถลงทะเบียนผ่านแอปได้ สิทธิ์จะถูกจัดสรรโดยส่วนกลางเพื่อความปลอดภัย',
                                style: TextStyle(
                                  fontFamily: 'Prompt',
                                  fontSize: 12,
                                  color: textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ปุ่มดำเนินการต่อ
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
                                fontFamily: 'Prompt',
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
                                      fontFamily: 'Prompt',
                                      fontSize: 13,
                                      color: textDark,
                                    ),
                                  ),
                                  Text(
                                    'ติดต่อเรา',
                                    style: TextStyle(
                                      fontFamily: 'Prompt',
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
            );
          },
        ),
      ),
    );
  }
}