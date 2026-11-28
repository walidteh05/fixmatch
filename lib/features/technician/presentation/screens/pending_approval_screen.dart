import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

import 'package:fixmatch/core/widgets/auth_primary_button.dart';
import 'package:fixmatch/features/auth/application/auth_providers.dart';
import 'package:fixmatch/features/auth/data/auth_repository.dart';
import 'package:fixmatch/features/technician/domain/technician_status.dart';
import 'package:fixmatch/features/technician/technician_providers.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isAuthorized = false;
  bool _isLoggingOut = false;
  String? _guardError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_guardPendingApproval());
    });
  }

  Future<void> _guardPendingApproval() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      if (mounted) context.goNamed(AppRoute.loginEmail);
      return;
    }

    final email = session.user.email ?? '';
    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      final roleValue = profile?['role'];
      if (profile == null || roleValue is! String || roleValue.trim().isEmpty) {
        setState(() {
          _guardError = 'ไม่พบข้อมูลโปรไฟล์ จึงไม่สามารถยืนยันสถานะใบสมัครได้';
        });
        return;
      }

      final role = roleValue.trim().toLowerCase();
      if (role == 'customer') {
        context.goNamed(AppRoute.customerHome);
        return;
      }
      if (role != 'technician') {
        setState(() {
          _guardError = 'บัญชีนี้ไม่มีสิทธิ์เข้าถึงสถานะใบสมัครช่าง';
        });
        return;
      }

      final application = await ref
          .read(technicianRegistrationRepositoryProvider)
          .loadApplicationSnapshot(profileId: session.user.id);
      if (!mounted) return;

      if (!application.profileExists ||
          application.role?.toLowerCase() != 'technician') {
        setState(() {
          _guardError = 'ไม่พบข้อมูลบัญชีช่าง จึงไม่สามารถยืนยันสถานะได้';
        });
        return;
      }

      switch (application.status?.trim().toLowerCase()) {
        case 'pending':
          if (!application.isComplete) {
            context.goNamed(
              AppRoute.technicianApplication,
              queryParameters: {'email': email, 'resume': 'true'},
            );
            return;
          }
          setState(() => _isAuthorized = true);
          return;
        case 'approved':
          context.goNamed(AppRoute.technicianHome);
          return;
        case 'rejected':
          context.goNamed(
            AppRoute.technicianRejected,
            queryParameters: {
              'reason': application.rejectedReason?.trim() ?? '',
            },
          );
          return;
        default:
          setState(() {
            _guardError = 'สถานะบัญชีช่างไม่พร้อมแสดง Pending Approval';
          });
      }
    } catch (error, stackTrace) {
      debugPrint('Pending approval route guard failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      if (isAuthSessionFailure(error)) {
        context.goNamed(
          AppRoute.loginPassword,
          queryParameters: {'email': email, 'sessionExpired': 'true'},
        );
        return;
      }

      setState(() {
        _guardError =
            'ไม่สามารถตรวจสอบใบสมัครได้ กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _logoutAndReturnToLogin() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    final client = Supabase.instance.client;
    try {
      await client.auth.signOut();

      if (client.auth.currentSession != null ||
          client.auth.currentUser != null) {
        throw StateError('Supabase Auth ยังมี Session หลังออกจากระบบ');
      }

      ref.invalidate(authStateChangesProvider);
      if (!mounted) return;
      context.goNamed(AppRoute.loginEmail);
    } catch (error, stackTrace) {
      debugPrint('Pending approval sign out failed: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      final detail = error is AuthException ? error.message : error.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $detail')));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _guardError == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _guardError!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthPrimaryButton(
                          text: 'กลับสู่หน้าเข้าสู่ระบบ',
                          onPressed: () => context.goNamed(AppRoute.loginEmail),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    const status = TechnicianStatus.pending;

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
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ส่งใบสมัครเรียบร้อยแล้ว',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'บัญชีของคุณกำลังรอการตรวจสอบจากทีมงาน FixMatch',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.label,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ช่างจะไม่สามารถรับงานหรือจองคิวได้จนกว่าจะได้รับการอนุมัติจากแอดมิน',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AuthPrimaryButton(
                    text: _isLoggingOut
                        ? 'กำลังออกจากระบบ...'
                        : 'กลับสู่หน้าเข้าสู่ระบบ',
                    onPressed: _isLoggingOut ? null : _logoutAndReturnToLogin,
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    text: 'ตรวจสอบสถานะคำขอ',
                    isSecondary: true,
                    onPressed: () {
                      context.goNamed(AppRoute.technicianHome);
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
