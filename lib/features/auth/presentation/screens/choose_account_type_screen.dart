import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/account_type.dart';
import '../widgets/account_type_card.dart';
import '../widgets/auth_primary_button.dart';

class ChooseAccountTypeScreen extends StatefulWidget {
  const ChooseAccountTypeScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<ChooseAccountTypeScreen> createState() => _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState extends State<ChooseAccountTypeScreen> {
  AccountType _selectedType = AccountType.customer;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เลือกประเภทบัญชี',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เลือกบัญชีที่เหมาะสมกับความต้องการของคุณ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AccountTypeCard(
                    title: 'Customer',
                    description: 'ค้นหาและจองช่างสำหรับบริการภายในบ้าน',
                    icon: Icons.person_outline_rounded,
                    isSelected: _selectedType == AccountType.customer,
                    onTap: () {
                      setState(() {
                        _selectedType = AccountType.customer;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AccountTypeCard(
                    title: 'Technician',
                    description: 'สมัครเป็นช่างและรับงานจากลูกค้า',
                    icon: Icons.handyman_outlined,
                    isSelected: _selectedType == AccountType.technician,
                    onTap: () {
                      setState(() {
                        _selectedType = AccountType.technician;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Admin tidakสามารถลงทะเบียนผ่านแอปส่วนบุคคลได้ ระบบจะจัดสรรสิทธิ์โดยผู้ดูแลระบบอย่างปลอดภัย',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthPrimaryButton(
                    text: 'ดำเนินการต่อ',
                    onPressed: () {
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
