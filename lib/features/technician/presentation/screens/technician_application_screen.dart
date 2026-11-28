import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
import 'package:fixmatch/features/auth/domain/account_type.dart';
import 'package:fixmatch/features/technician/data/technician_registration_repository.dart';
import 'package:fixmatch/features/technician/technician_providers.dart';

import '../widgets/auth_text_field.dart';
import '../widgets/document_upload_field.dart';

enum _SessionConflictChoice { useExistingAccount, signOutAndRegister }

class TechnicianApplicationScreen extends ConsumerStatefulWidget {
  const TechnicianApplicationScreen({
    super.key,
    required this.email,
    this.accountType = AccountType.technician,
    this.resume = false,
  });

  final String email;
  final AccountType accountType;
  final bool resume;

  @override
  ConsumerState<TechnicianApplicationScreen> createState() =>
      _TechnicianApplicationScreenState();
}

class _TechnicianApplicationScreenState
    extends ConsumerState<TechnicianApplicationScreen> {
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
  final _otherCategoryController = TextEditingController();

  final Set<Object> _selectedCategories = {};
  List<ServiceCategory> _serviceCategories = [];
  bool _isLoadingCategories = true;
  String? _categoryLoadError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _createdAuthUserId;
  bool _isLoadingResume = false;
  bool _resumeDataLoaded = false;
  String? _resumeLoadError;
  bool _hasExistingIdentityDocument = false;
  List<TechnicianDocument> _storedDocuments = [];

  List<PlatformFile> _identityDocuments = [];
  List<PlatformFile> _certificateDocuments = [];
  List<PlatformFile> _portfolioImages = [];

  bool _isPickingIdentity = false;
  bool _isPickingCertificate = false;
  bool _isPickingPortfolio = false;

  static const primaryBlue = Color(0xFF2979FF);
  static const softBlue = Color(0xFFF4F8FD);
  static const textDark = Color(0xFF1E242B);
  static const textMuted = Color(0xFF6C7A89);
  static const borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadServiceCategories());
      }
    });
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
    _otherCategoryController.dispose();
    super.dispose();
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

  int? _parseServiceRadiusKm(String? value) {
    final parsed = num.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || parsed <= 0 || parsed % 1 != 0) {
      return null;
    }
    return parsed.toInt();
  }

  String? _serviceRadiusValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'กรุณากรอกรัศมีให้บริการ';
    }

    final parsed = num.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) {
      return 'รัศมีให้บริการต้องเป็นตัวเลข';
    }
    if (parsed < 0) {
      return 'รัศมีให้บริการต้องไม่ติดลบ';
    }
    if (parsed == 0) {
      return 'รัศมีให้บริการต้องมากกว่า 0';
    }
    if (parsed % 1 != 0) {
      return 'รัศมีให้บริการต้องเป็นจำนวนเต็ม เช่น 20';
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

  bool get _isOtherCategorySelected => _serviceCategories.any(
    (category) => category.isOther && _selectedCategories.contains(category.id),
  );

  bool get _hasMatchingResumeSession {
    final session = ref.read(authRepositoryProvider).currentSession;
    return widget.resume &&
        session != null &&
        (session.user.email ?? '').trim().toLowerCase() ==
            widget.email.trim().toLowerCase();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
      return 'ไม่สามารถระบุอีเมลได้';
    }

    final localPart = parts.first;
    final maskedLocalPart = localPart.length <= 2
        ? '${localPart[0]}***'
        : '${localPart[0]}***${localPart[localPart.length - 1]}';
    return '$maskedLocalPart@${parts.last}';
  }

  Future<bool> _prepareRegistrationSession(
    AuthRepository authRepository, {
    required bool isResume,
  }) async {
    final initialSession = authRepository.currentSession;
    final initialUser = authRepository.currentUser;

    if (initialSession == null && initialUser == null) {
      if (isResume) {
        context.goNamed(
          AppRoute.loginPassword,
          queryParameters: {'email': _emailController.text.trim()},
        );
        return false;
      }
      return true;
    }

    if (initialSession == null ||
        initialUser == null ||
        initialSession.user.id != initialUser.id) {
      _routeToLoginAfterSessionFailure();
      return false;
    }

    try {
      await Supabase.instance.client.auth.getSession();
    } catch (error, stackTrace) {
      debugPrint('Validating Technician registration session failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _routeToLoginAfterSessionFailure();
      return false;
    }

    if (!mounted) return false;

    final session = authRepository.currentSession;
    final user = authRepository.currentUser;
    if (session == null || user == null || session.user.id != user.id) {
      _routeToLoginAfterSessionFailure();
      return false;
    }

    final existingEmail = (user.email ?? session.user.email ?? '').trim();
    if (existingEmail.toLowerCase() ==
        _emailController.text.trim().toLowerCase()) {
      return true;
    }

    final choice = await showDialog<_SessionConflictChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('พบ Session ของบัญชีเดิม'),
        content: Text(
          'ขณะนี้มีบัญชี ${_maskEmail(existingEmail)} อยู่ในแอป '
          'แต่ไม่ตรงกับอีเมลที่กรอกสมัครช่าง '
          'คุณต้องการกลับไปใช้บัญชีเดิม หรือออกจากระบบเพื่อสมัครบัญชีใหม่?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_SessionConflictChoice.useExistingAccount),
            child: const Text('กลับไปใช้บัญชีเดิม'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_SessionConflictChoice.signOutAndRegister),
            child: Text(
              isResume
                  ? 'ออกจากระบบและเข้าสู่บัญชีใบสมัคร'
                  : 'ออกจากระบบและสมัครบัญชีใหม่',
            ),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return false;

    if (choice == _SessionConflictChoice.useExistingAccount) {
      context.goNamed(
        AppRoute.loginPassword,
        queryParameters: {'email': existingEmail},
      );
      return false;
    }

    try {
      await authRepository.signOut();
      if (!mounted) return false;

      if (authRepository.currentSession != null ||
          authRepository.currentUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ออกจากระบบบัญชีเดิมไม่สำเร็จ กรุณาลองอีกครั้งก่อนสมัครบัญชีใหม่',
            ),
          ),
        );
        return false;
      }

      ref.invalidate(authStateChangesProvider);

      if (isResume) {
        context.goNamed(
          AppRoute.loginPassword,
          queryParameters: {'email': _emailController.text.trim()},
        );
        return false;
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Explicit sign out before Technician registration failed: '
        '${error.runtimeType}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        final detail = error is AuthException
            ? error.message
            : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ออกจากระบบบัญชีเดิมไม่สำเร็จ: $detail')),
        );
      }
      return false;
    }
  }

  void _routeToLoginAfterSessionFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Session หมดอายุหรือยืนยันไม่ได้ กรุณาเข้าสู่ระบบใหม่ก่อนสมัครช่าง',
        ),
      ),
    );
    context.goNamed(
      AppRoute.loginPassword,
      queryParameters: {
        'email': _emailController.text.trim(),
        'sessionExpired': 'true',
      },
    );
  }

  Future<T> _runRegistrationStep<T>(
    String step,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on TechnicianRegistrationStepException {
      rethrow;
    } catch (error) {
      throw TechnicianRegistrationStepException(step: step, cause: error);
    }
  }

  Future<void> _loadServiceCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final session = await Supabase.instance.client.auth.getSession();
      debugPrint(
        'Loading technician service categories: '
        'authSessionAvailable=${session != null}',
      );

      final categories = await ref
          .read(technicianRegistrationRepositoryProvider)
          .loadActiveServiceCategories();

      if (categories.isEmpty && !widget.resume) {
        if (!mounted) return;
        setState(() {
          _serviceCategories = categories;
          _categoryLoadError = 'ไม่พบหมวดบริการที่เปิดใช้งานในขณะนี้';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _serviceCategories = categories;
      });
      if (widget.resume) {
        await _loadResumeData();
      }
    } catch (error, stackTrace) {
      if (error is PostgrestException) {
        debugPrint(
          'Loading service categories failed: '
          'message=${error.message}, code=${error.code}, '
          'details=${error.details}, hint=${error.hint}',
        );
      } else {
        debugPrint(
          'Loading service categories failed: '
          '${error.runtimeType}: $error',
        );
      }
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        _categoryLoadError = 'ไม่สามารถโหลดหมวดบริการได้ กรุณาลองใหม่อีกครั้ง';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadResumeData() async {
    if (_isLoadingResume || _resumeDataLoaded || !mounted) return;

    final authRepository = ref.read(authRepositoryProvider);
    final session = authRepository.currentSession;
    if (session == null) {
      setState(() {
        _resumeLoadError = 'กรุณาเข้าสู่ระบบบัญชีช่างเพื่อทำใบสมัครต่อ';
      });
      return;
    }

    if ((session.user.email ?? '').trim().toLowerCase() !=
        widget.email.trim().toLowerCase()) {
      setState(() {
        _resumeLoadError = 'บัญชีที่เข้าสู่ระบบไม่ตรงกับอีเมลใบสมัคร กรุณาเข้าสู่ระบบบัญชีที่ถูกต้อง';
      });
      return;
    }

    setState(() {
      _isLoadingResume = true;
      _resumeLoadError = null;
    });

    try {
      final snapshot = await ref
          .read(technicianRegistrationRepositoryProvider)
          .loadApplicationSnapshot(profileId: session.user.id);

      if (!snapshot.profileExists ||
          snapshot.role?.toLowerCase() != 'technician') {
        throw StateError('ไม่พบข้อมูลบัญชีช่างสำหรับทำใบสมัครต่อ');
      }

      if (!mounted) return;
      setState(() {
        final categoriesById = {
          for (final category in _serviceCategories) category.id: category,
          for (final category in snapshot.categories) category.id: category,
        };
        _serviceCategories = categoriesById.values.toList()
          ..sort((left, right) => left.name.compareTo(right.name));
        _nameController.text = snapshot.fullName ?? '';
        _phoneController.text = snapshot.phone ?? '';
        _experienceController.text = snapshot.yearsExperience?.toString() ?? '';
        _serviceRadiusController.text =
            snapshot.serviceRadiusKm?.toString() ?? '';
        _locationController.text = snapshot.serviceArea ?? '';
        _descriptionController.text = snapshot.bio ?? '';
        _otherCategoryController.text = snapshot.otherServiceDescription ?? '';
        _hasExistingIdentityDocument = snapshot.hasIdentityDocument;
        _storedDocuments = snapshot.documents;
        _selectedCategories
          ..clear()
          ..addAll(snapshot.categoryIds);
        _resumeDataLoaded = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Loading technician application for resume failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      if (isAuthSessionFailure(error)) {
        _routeToLoginAfterSessionFailure();
        return;
      }

      setState(() {
        _resumeLoadError =
            'ไม่สามารถโหลดข้อมูลใบสมัครเดิมได้ กรุณาลองใหม่อีกครั้ง';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingResume = false);
      }
    }
  }

  Future<void> _submitTechnicianRegistration() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim().toLowerCase();
    final authRepository = ref.read(authRepositoryProvider);
    var sessionPrepared = false;

    void resetResumeSubmission() {
      if (widget.resume && mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (widget.resume) {
      setState(() => _isSubmitting = true);
      final canContinue = await _prepareRegistrationSession(
        authRepository,
        isResume: true,
      );
      if (!canContinue || !mounted) {
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }
      sessionPrepared = true;
    }

    if (!_formKey.currentState!.validate()) {
      resetResumeSubmission();
      return;
    }

    if (_categoryLoadError != null ||
        (_serviceCategories.isEmpty && _selectedCategories.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาโหลดหมวดบริการก่อนส่งใบสมัคร')),
      );
      resetResumeSubmission();
      return;
    }

    if (widget.resume && !_resumeDataLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _resumeLoadError ?? 'กรุณาโหลดข้อมูลใบสมัครเดิมก่อนดำเนินการต่อ',
          ),
        ),
      );
      resetResumeSubmission();
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 หมวดบริการ')),
      );
      resetResumeSubmission();
      return;
    }

    if (_identityDocuments.isEmpty && !_hasExistingIdentityDocument) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกเอกสารยืนยันตัวตนอย่างน้อย 1 ไฟล์'),
        ),
      );
      resetResumeSubmission();
      return;
    }

    final yearsExperience = int.tryParse(_experienceController.text.trim());
    final serviceRadiusKm = _parseServiceRadiusKm(
      _serviceRadiusController.text,
    );
    if (yearsExperience == null || serviceRadiusKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            yearsExperience == null
                ? 'กรุณากรอกประสบการณ์เป็นตัวเลข'
                : 'รัศมีให้บริการต้องเป็นจำนวนเต็มมากกว่า 0',
          ),
        ),
      );
      resetResumeSubmission();
      return;
    }

    if (!sessionPrepared) {
      setState(() => _isSubmitting = true);
      final canContinue = await _prepareRegistrationSession(
        authRepository,
        isResume: false,
      );
      if (!canContinue || !mounted) {
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }
    }

    try {
      final registrationRepository = ref.read(
        technicianRegistrationRepositoryProvider,
      );
      var currentSession = authRepository.currentSession;
      var currentUser = authRepository.currentUser;
      User user;

      if (widget.resume) {
        if (currentSession == null ||
            currentUser == null ||
            currentSession.user.id != currentUser.id) {
          _routeToLoginAfterSessionFailure();
          return;
        }
        if ((currentSession.user.email ?? '').trim().toLowerCase() != email) {
          context.goNamed(
            AppRoute.loginPassword,
            queryParameters: {'email': email},
          );
          return;
        }
        user = currentSession.user;
      } else {
        if (currentSession != null) {
          user = currentSession.user;
          if ((user.email ?? '').trim().toLowerCase() != email) {
            throw StateError(
              'Session เปลี่ยนระหว่างเริ่มสมัคร กรุณากดส่งใบสมัครอีกครั้งเพื่อยืนยันบัญชี',
            );
          }
          if (_createdAuthUserId != null && user.id != _createdAuthUserId) {
            throw StateError(
              'เซสชันปัจจุบันไม่ตรงกับบัญชีที่เริ่มสมัคร กรุณาเข้าสู่ระบบบัญชีเดิม',
            );
          }
        } else {
          if (_createdAuthUserId != null || currentUser != null) {
            throw StateError(
              'บัญชีถูกสร้างแล้วแต่ไม่มี Auth Session กรุณาเข้าสู่ระบบบัญชีนี้ก่อนลองบันทึกอีกครั้ง',
            );
          }

          if (await authRepository.emailExists(email)) {
            throw StateError(
              'อีเมลนี้มีบัญชีอยู่แล้ว กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ',
            );
          }

          if (authRepository.currentSession != null ||
              authRepository.currentUser != null) {
            throw StateError(
              'มี Session เปลี่ยนแปลงก่อนเริ่มสมัคร กรุณาตรวจสอบบัญชีแล้วลองใหม่',
            );
          }

          final response = await authRepository.signUp(
            email: email,
            password: _passwordController.text,
            metadata: {
              'full_name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'role': 'technician',
            },
          );

          user =
              response.user ??
              (throw StateError('Supabase did not return a user.'));
          _createdAuthUserId = user.id;

          final session = response.session ?? authRepository.currentSession;
          if (session == null || session.user.id != user.id) {
            throw StateError(
              'สร้างบัญชีแล้วแต่ยังไม่มี Auth Session จึงยังบันทึกใบสมัครไม่ได้ กรุณาเข้าสู่ระบบก่อนลองอีกครั้ง',
            );
          }
        }
      }

      if (_createdAuthUserId != null && user.id != _createdAuthUserId) {
        throw StateError(
          'เซสชันปัจจุบันไม่ตรงกับบัญชีที่เริ่มสมัคร กรุณาเข้าสู่ระบบบัญชีเดิม',
        );
      }

      final application = await _runRegistrationStep(
        'ตรวจสอบข้อมูลใบสมัครช่าง',
        () =>
            registrationRepository.loadApplicationSnapshot(profileId: user.id),
      );
      if (!application.profileExists ||
          application.role?.toLowerCase() != 'technician') {
        throw StateError(
          'บัญชีนี้ยังไม่มี Technician profile ที่สร้างโดย Trigger',
        );
      }
      if (application.status != null &&
          application.status!.toLowerCase() != 'pending') {
        throw StateError(
          'สถานะบัญชีเปลี่ยนแปลงแล้ว กรุณาเข้าสู่ระบบใหม่เพื่อตรวจสอบสถานะ',
        );
      }

      await registrationRepository.updateProfileBasics(
        profileId: user.id,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await registrationRepository.updateTechnicianProfile(
        profileId: user.id,
        bio: _descriptionController.text.trim(),
        serviceArea: _locationController.text.trim(),
        serviceRadiusKm: serviceRadiusKm,
        yearsExperience: yearsExperience,
        otherServiceDescription: _isOtherCategorySelected
            ? _otherCategoryController.text.trim()
            : null,
      );

      await registrationRepository.syncServiceCategories(
        technicianProfileId: user.id,
        categoryIds: _selectedCategories,
      );

      await _uploadPendingDocuments(profileId: user.id);

      final savedApplication = await _runRegistrationStep(
        'ตรวจสอบข้อมูลใบสมัครที่บันทึกแล้ว',
        () =>
            registrationRepository.loadApplicationSnapshot(profileId: user.id),
      );
      if (!savedApplication.profileExists ||
          savedApplication.role?.trim().toLowerCase() != 'technician' ||
          savedApplication.status?.trim().toLowerCase() != 'pending' ||
          !savedApplication.isComplete) {
        throw StateError(
          'บันทึกข้อมูลแล้วแต่ใบสมัครยังไม่ครบหรือสถานะไม่ใช่ pending',
        );
      }

      if (!mounted) return;
      context.goNamed(AppRoute.pendingApproval);
    } on TechnicianRegistrationStepException catch (error, stackTrace) {
      debugPrint(
        'Technician registration step failed: '
        '${error.step} (${error.cause.runtimeType})',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));

      if (isAuthSessionFailure(error.cause)) {
        context.goNamed(
          AppRoute.loginPassword,
          queryParameters: {'email': email, 'sessionExpired': 'true'},
        );
      }
    } on AuthException catch (error, stackTrace) {
      debugPrint('Technician sign up failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      if (isAuthSessionFailure(error) &&
          (widget.resume ||
              _createdAuthUserId != null ||
              ref.read(authRepositoryProvider).currentUser != null)) {
        _routeToLoginAfterSessionFailure();
        return;
      }

      final message = error.message.toLowerCase().contains('already')
          ? 'อีเมลนี้มีบัญชีอยู่แล้ว กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ'
          : 'ไม่สามารถสร้างบัญชีช่างได้ กรุณาตรวจสอบข้อมูลและลองอีกครั้ง';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error, stackTrace) {
      debugPrint('Technician registration save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      if (isAuthSessionFailure(error) &&
          (widget.resume ||
              _createdAuthUserId != null ||
              ref.read(authRepositoryProvider).currentUser != null)) {
        _routeToLoginAfterSessionFailure();
        return;
      }

      final message = error is StateError ? error.message : error.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goToLoginForResume(String email) {
    context.goNamed(AppRoute.loginPassword, queryParameters: {'email': email});
  }

  Future<void> _pickFiles({
    required List<PlatformFile> currentFiles,
    required ValueChanged<List<PlatformFile>> onUpdate,
    required bool allowMultiple,
    required List<String> allowedExtensions,
    required bool isLoading,
    required String errorMessage,
    required void Function(bool) setLoading,
  }) async {
    if (isLoading) return;

    setLoading(true);

    try {
      final List<PlatformFile> pickedFiles;

      if (allowMultiple) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        pickedFiles = result;
      } else {
        final result = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        pickedFiles = result == null ? const [] : [result];
      }

      if (!mounted) return;

      if (pickedFiles.isEmpty) {
        return;
      }

      final validFiles = <PlatformFile>[];
      final invalidFiles = <String>[];

      for (final file in pickedFiles) {
        final extension = (file.extension ?? '').toLowerCase();
        final fileSizeBytes = file.lengthSync() ?? 0;
        final isAllowed = allowedExtensions.contains(extension);
        final isWithinLimit = fileSizeBytes <= 10 * 1024 * 1024;

        if (!isAllowed) {
          invalidFiles.add('${file.name} ไม่ใช่ไฟล์ที่รองรับ');
          continue;
        }

        if (!isWithinLimit) {
          invalidFiles.add('${file.name} ขนาดเกิน 10 MB');
          continue;
        }

        validFiles.add(file);
      }

      if (invalidFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invalidFiles.join('\n')),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (validFiles.isEmpty) {
        return;
      }

      final nextFiles = allowMultiple
          ? [...currentFiles, ...validFiles]
          : validFiles.take(1).toList();

      onUpdate(nextFiles);
    } catch (e, st) {
      debugPrint('FilePicker error: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }

  Future<Uint8List> _readDocumentBytes(PlatformFile file) async {
    return file.readAsBytes();
  }

  Future<void> _uploadPendingDocuments({required String profileId}) async {
    await _uploadFilesForType(
      profileId: profileId,
      documentType: 'identity',
      files: List<PlatformFile>.of(_identityDocuments),
      replaceExisting: true,
    );
    await _uploadFilesForType(
      profileId: profileId,
      documentType: 'certificate',
      files: List<PlatformFile>.of(_certificateDocuments),
      replaceExisting: true,
    );
    await _uploadFilesForType(
      profileId: profileId,
      documentType: 'portfolio',
      files: List<PlatformFile>.of(_portfolioImages),
      replaceExisting: false,
    );
  }

  Future<void> _uploadFilesForType({
    required String profileId,
    required String documentType,
    required List<PlatformFile> files,
    required bool replaceExisting,
  }) async {
    final repository = ref.read(technicianRegistrationRepositoryProvider);
    for (final file in files) {
      final previousDocuments = replaceExisting
          ? _storedDocuments
                .where((document) => document.documentType == documentType)
                .toList()
          : <TechnicianDocument>[];
      final bytes = await _runRegistrationStep(
        'อ่านไฟล์ $documentType',
        () => _readDocumentBytes(file),
      );
      final uploadedDocument = await repository.uploadDocument(
        profileId: profileId,
        documentType: documentType,
        fileName: file.name,
        bytes: bytes,
      );

      if (!mounted) return;
      setState(() {
        _storedDocuments = [..._storedDocuments, uploadedDocument];
        switch (documentType) {
          case 'identity':
            _identityDocuments.remove(file);
            _hasExistingIdentityDocument = true;
          case 'certificate':
            _certificateDocuments.remove(file);
          case 'portfolio':
            _portfolioImages.remove(file);
        }
      });

      for (final previousDocument in previousDocuments) {
        await repository.deleteDocument(
          profileId: profileId,
          document: previousDocument,
        );
        if (!mounted) return;
        setState(() {
          _storedDocuments.removeWhere(
            (document) => document.filePath == previousDocument.filePath,
          );
          _hasExistingIdentityDocument = _storedDocuments.any(
            (document) =>
                document.documentType == 'identity' && document.fileExists,
          );
        });
      }
    }
  }

  Future<void> _removeStoredDocument(TechnicianDocument document) async {
    if (_isSubmitting) return;
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      _routeToLoginAfterSessionFailure();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(technicianRegistrationRepositoryProvider)
          .deleteDocument(profileId: userId, document: document);
      if (!mounted) return;
      setState(() {
        _storedDocuments.removeWhere(
          (stored) => stored.filePath == document.filePath,
        );
        _hasExistingIdentityDocument = _storedDocuments.any(
          (stored) => stored.documentType == 'identity' && stored.fileExists,
        );
      });
    } on TechnicianRegistrationStepException catch (error, stackTrace) {
      debugPrint(
        'Technician document removal failed: ${error.cause.runtimeType}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
      if (isAuthSessionFailure(error.cause)) {
        context.goNamed(
          AppRoute.loginPassword,
          queryParameters: {
            'email': _emailController.text.trim(),
            'sessionExpired': 'true',
          },
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Technician document removal failed: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบเอกสารไม่สำเร็จ: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStoredDocumentSection(String documentType) {
    final documents = _storedDocuments
        .where((document) => document.documentType == documentType)
        .toList();
    if (documents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เอกสารที่บันทึกไว้'),
          const SizedBox(height: 8),
          for (final document in documents)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (document.fileExists &&
                      document.isImage &&
                      document.signedUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        document.signedUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    )
                  else
                    Icon(
                      document.fileExists
                          ? document.isImage
                                ? Icons.image_outlined
                                : Icons.picture_as_pdf_outlined
                          : Icons.warning_amber_rounded,
                      size: 40,
                      color: document.fileExists
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          document.fileExists
                              ? 'ไฟล์อยู่ใน Storage'
                              : 'ไม่พบไฟล์ใน Storage',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: document.fileExists
                                ? AppColors.textSecondary
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'ลบเอกสาร',
                    onPressed: _isSubmitting
                        ? null
                        : () => unawaited(_removeStoredDocument(document)),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// ส่วนเลือกหมวดหมู่บริการแบบตาราง 2 คอลัมน์ + ช่องกรอกเพิ่มเติมเมื่อเลือก "อื่น ๆ"
  Widget _buildServiceCategorySelector() {
    final isOtherSelected = _isOtherCategorySelected;

    // แบ่งรายการเป็นคู่สำหรับแสดงผล 2 คอลัมน์ต่อแถว
    final List<List<ServiceCategory>> rows = [];
    for (int i = 0; i < _serviceCategories.length; i += 2) {
      rows.add(
        _serviceCategories.sublist(
          i,
          i + 2 > _serviceCategories.length ? _serviceCategories.length : i + 2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หมวดหมู่บริการ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'เลือกได้มากกว่า 1 หมวดหมู่',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
        const SizedBox(height: 12),

        if (_isLoadingCategories)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_categoryLoadError != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  _categoryLoadError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => unawaited(_loadServiceCategories()),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          )
        else
          // รายการการ์ดหมวดหมู่แบบ 2 คอลัมน์
          Column(
            children: rows.map((rowCategories) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: _buildCategoryCard(rowCategories[0])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: rowCategories.length > 1
                          ? _buildCategoryCard(rowCategories[1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        // แสดงช่องกรอกบริการเพิ่มเติมแบบ Smooth Animation เมื่อกดเลือก "อื่น ๆ"
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: isOtherSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ระบุประเภทงานที่ต้องการให้บริการ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _otherCategoryController,
                        style: const TextStyle(fontSize: 14, color: textDark),
                        decoration: InputDecoration(
                          hintText: 'เช่น ช่างปูน, ช่างสี, ช่างกระจก',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
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
                        validator: (value) {
                          if (_isOtherCategorySelected &&
                              (value == null || value.trim().isEmpty)) {
                            return 'กรุณาระบุประเภทงานที่ต้องการให้บริการ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Admin จะตรวจสอบหมวดหมู่ก่อนอนุมัติ',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final isSelected = _selectedCategories.contains(category.id);

    return InkWell(
      onTap: category.isActive
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedCategories.remove(category.id);
                  if (category.isOther) {
                    _otherCategoryController.clear();
                  }
                } else {
                  _selectedCategories.add(category.id);
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? softBlue : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryBlue : borderColor,
            width: isSelected ? 1.6 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryBlue : textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveResumeSession = _hasMatchingResumeSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(
                AppRoute.chooseAccountType,
                queryParameters: {'email': widget.email},
              );
            }
          },
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
                    if (widget.resume) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ดำเนินการสมัครช่างต่อจากใบสมัครเดิม',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (widget.resume && _resumeLoadError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _resumeLoadError!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoadingResume
                            ? null
                            : () {
                                if (!_hasMatchingResumeSession) {
                                  _goToLoginForResume(widget.email);
                                } else {
                                  unawaited(_loadResumeData());
                                }
                              },
                        child: Text(
                          !_hasMatchingResumeSession
                              ? 'เข้าสู่ระบบเพื่อทำต่อ'
                              : 'ลองโหลดข้อมูลอีกครั้ง',
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('ข้อมูลส่วนตัว', style: AppTextStyles.headingSmall),
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
                    if (!widget.resume) ...[
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'รหัสผ่าน',
                        hintText: 'อย่างน้อย 8 ตัวอักษร',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: hasActiveResumeSession
                            ? null
                            : _passwordValidator,
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
                        validator: hasActiveResumeSession
                            ? null
                            : (value) {
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
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('ข้อมูลเชิงอาชีพ', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),

                    // เรียกใช้ Widget หมวดหมู่บริการที่ปรับแต่งใหม่
                    _buildServiceCategorySelector(),

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
                      validator: _serviceRadiusValidator,
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
                    Text('เอกสารยืนยัน', style: AppTextStyles.headingSmall),
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
                          DocumentUploadField(
                            label: 'Identity Verification Document',
                            required: true,
                            allowMultiple: false,
                            files: _identityDocuments,
                            isLoading: _isPickingIdentity,
                            helperText: 'รองรับ PDF, JPG, PNG เท่านั้น',
                            onPickFiles: () async {
                              await _pickFiles(
                                currentFiles: _identityDocuments,
                                onUpdate: (files) {
                                  setState(() => _identityDocuments = files);
                                },
                                allowMultiple: false,
                                allowedExtensions: const [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png',
                                ],
                                isLoading: _isPickingIdentity,
                                errorMessage:
                                    'ไม่สามารถเลือกไฟล์เอกสารยืนยันตัวตนได้',
                                setLoading: (loading) {
                                  setState(() => _isPickingIdentity = loading);
                                },
                              );
                            },
                            onReplaceFile: () async {
                              await _pickFiles(
                                currentFiles: _identityDocuments,
                                onUpdate: (files) {
                                  setState(() => _identityDocuments = files);
                                },
                                allowMultiple: false,
                                allowedExtensions: const [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png',
                                ],
                                isLoading: _isPickingIdentity,
                                errorMessage:
                                    'ไม่สามารถเลือกไฟล์เอกสารยืนยันตัวตนได้',
                                setLoading: (loading) {
                                  setState(() => _isPickingIdentity = loading);
                                },
                              );
                            },
                            onRemoveFile: (index) {
                              setState(() {
                                _identityDocuments.removeAt(index);
                              });
                            },
                          ),
                          _buildStoredDocumentSection('identity'),
                          const SizedBox(height: 18),
                          DocumentUploadField(
                            label: 'Professional Certificate',
                            required: false,
                            allowMultiple: false,
                            files: _certificateDocuments,
                            isLoading: _isPickingCertificate,
                            helperText: 'รองรับ PDF, JPG, PNG ไม่บังคับกรอก',
                            onPickFiles: () async {
                              await _pickFiles(
                                currentFiles: _certificateDocuments,
                                onUpdate: (files) {
                                  setState(() => _certificateDocuments = files);
                                },
                                allowMultiple: false,
                                allowedExtensions: const [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png',
                                ],
                                isLoading: _isPickingCertificate,
                                errorMessage:
                                    'ไม่สามารถเลือกไฟล์ใบประกอบวิชาชีพได้',
                                setLoading: (loading) {
                                  setState(
                                    () => _isPickingCertificate = loading,
                                  );
                                },
                              );
                            },
                            onReplaceFile: () async {
                              await _pickFiles(
                                currentFiles: _certificateDocuments,
                                onUpdate: (files) {
                                  setState(() => _certificateDocuments = files);
                                },
                                allowMultiple: false,
                                allowedExtensions: const [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png',
                                ],
                                isLoading: _isPickingCertificate,
                                errorMessage:
                                    'ไม่สามารถเลือกไฟล์ใบประกอบวิชาชีพได้',
                                setLoading: (loading) {
                                  setState(
                                    () => _isPickingCertificate = loading,
                                  );
                                },
                              );
                            },
                            onRemoveFile: (index) {
                              setState(() {
                                _certificateDocuments.removeAt(index);
                              });
                            },
                          ),
                          _buildStoredDocumentSection('certificate'),
                          const SizedBox(height: 18),
                          DocumentUploadField(
                            label: 'Portfolio / Work Samples',
                            required: false,
                            allowMultiple: true,
                            files: _portfolioImages,
                            isLoading: _isPickingPortfolio,
                            helperText: 'เลือกรูปภาพ JPG, PNG ได้หลายภาพ',
                            onPickFiles: () async {
                              await _pickFiles(
                                currentFiles: _portfolioImages,
                                onUpdate: (files) {
                                  setState(() => _portfolioImages = files);
                                },
                                allowMultiple: true,
                                allowedExtensions: const ['jpg', 'jpeg', 'png'],
                                isLoading: _isPickingPortfolio,
                                errorMessage: 'ไม่สามารถเลือกรูปภาพผลงานได้',
                                setLoading: (loading) {
                                  setState(() => _isPickingPortfolio = loading);
                                },
                              );
                            },
                            onReplaceFile: () async {
                              await _pickFiles(
                                currentFiles: _portfolioImages,
                                onUpdate: (files) {
                                  setState(() => _portfolioImages = files);
                                },
                                allowMultiple: true,
                                allowedExtensions: const ['jpg', 'jpeg', 'png'],
                                isLoading: _isPickingPortfolio,
                                errorMessage: 'ไม่สามารถเลือกรูปภาพผลงานได้',
                                setLoading: (loading) {
                                  setState(() => _isPickingPortfolio = loading);
                                },
                              );
                            },
                            onRemoveFile: (index) {
                              setState(() {
                                _portfolioImages.removeAt(index);
                              });
                            },
                          ),
                          _buildStoredDocumentSection('portfolio'),
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
                      text: _isSubmitting
                          ? 'กำลังบันทึกข้อมูล...'
                          : 'ส่งใบสมัคร',
                      onPressed: _isSubmitting
                          ? null
                          : _submitTechnicianRegistration,
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
