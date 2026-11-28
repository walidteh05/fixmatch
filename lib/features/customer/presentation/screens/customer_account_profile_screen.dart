import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/customer_account_providers.dart';
import '../../data/customer_account_repository.dart';

class CustomerAccountProfileScreen extends ConsumerStatefulWidget {
  const CustomerAccountProfileScreen({super.key});

  @override
  ConsumerState<CustomerAccountProfileScreen> createState() =>
      _CustomerAccountProfileScreenState();
}

class _CustomerAccountProfileScreenState
    extends ConsumerState<CustomerAccountProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _formInitialized = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSigningOut = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    if (words.isEmpty) return '?';
    return words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
  }

  String? _avatarUrl(Map<String, dynamic>? metadata) {
    final value = metadata?['avatar_url'] ?? metadata?['picture'];
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
        ? value
        : null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '\u{0e01}\u{0e23}\u{0e38}\u{0e13}\u{0e32}\u{0e01}\u{0e23}\u{0e2d}\u{0e01}\u{0e0a}\u{0e37}\u{0e48}\u{0e2d}';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9\s-]{9,15}$').hasMatch(phone)) {
      return '\u{0e01}\u{0e23}\u{0e38}\u{0e13}\u{0e32}\u{0e15}\u{0e23}\u{0e27}\u{0e08}\u{0e2a}\u{0e2d}\u{0e1a}\u{0e40}\u{0e1a}\u{0e2d}\u{0e23}\u{0e4c}\u{0e42}\u{0e17}\u{0e23}\u{0e28}\u{0e31}\u{0e1e}\u{0e17}\u{0e4c}';
    }
    return null;
  }

  void _populateForm(CustomerProfileRecord? profile, User user) {
    if (_formInitialized) return;
    _nameController.text = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : (user.userMetadata?['full_name'] ?? user.userMetadata?['name'])
                  ?.toString() ??
              '';
    _phoneController.text =
        profile?.phone ?? user.userMetadata?['phone']?.toString() ?? '';
    _emailController.text = user.email ?? '';
    _formInitialized = true;
  }

  Future<void> _saveProfile(String profileId) async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final profile = await ref
          .read(customerAccountRepositoryProvider)
          .updateProfile(
            profileId: profileId,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      ref.invalidate(customerProfileRecordProvider(profileId));
      if (!mounted) return;
      _nameController.text = profile.fullName ?? _nameController.text.trim();
      _phoneController.text = profile.phone ?? _phoneController.text.trim();
      setState(() => _isEditing = false);
      _showMessage(
        '\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}\u{0e42}\u{0e1b}\u{0e23}\u{0e44}\u{0e1f}\u{0e25}\u{0e4c}\u{0e41}\u{0e25}\u{0e49}\u{0e27}',
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          '\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}\u{0e44}\u{0e21}\u{0e48}\u{0e2a}\u{0e33}\u{0e40}\u{0e23}\u{0e47}\u{0e08} \u{0e01}\u{0e23}\u{0e38}\u{0e13}\u{0e32}\u{0e25}\u{0e2d}\u{0e07}\u{0e43}\u{0e2b}\u{0e21}\u{0e48}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '\u{0e2d}\u{0e2d}\u{0e01}\u{0e08}\u{0e32}\u{0e01}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}?',
        ),
        content: const Text(
          '\u{0e04}\u{0e38}\u{0e13}\u{0e15}\u{0e49}\u{0e2d}\u{0e07}\u{0e01}\u{0e32}\u{0e23}\u{0e2d}\u{0e2d}\u{0e01}\u{0e08}\u{0e32}\u{0e01}\u{0e1a}\u{0e31}\u{0e0d}\u{0e0a}\u{0e35}\u{0e2b}\u{0e23}\u{0e37}\u{0e2d}\u{0e44}\u{0e21}\u{0e48}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '\u{0e22}\u{0e01}\u{0e40}\u{0e25}\u{0e34}\u{0e01}',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '\u{0e2d}\u{0e2d}\u{0e01}\u{0e08}\u{0e32}\u{0e01}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}',
            ),
          ),
        ],
      ),
    );
    if (shouldSignOut != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(authStateChangesProvider);
      if (mounted) context.goNamed(AppRoute.loginEmail);
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        _showMessage(
          '\u{0e2d}\u{0e2d}\u{0e01}\u{0e08}\u{0e32}\u{0e01}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e44}\u{0e21}\u{0e48}\u{0e2a}\u{0e33}\u{0e40}\u{0e23}\u{0e47}\u{0e08}',
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddressPlaceholder() async {
    final addressController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '\u{0e40}\u{0e1e}\u{0e34}\u{0e48}\u{0e21}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                '\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e08}\u{0e31}\u{0e14}\u{0e40}\u{0e01}\u{0e47}\u{0e1a}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e22}\u{0e31}\u{0e07}\u{0e44}\u{0e21}\u{0e48}\u{0e1e}\u{0e23}\u{0e49}\u{0e2d}\u{0e21} \u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}\u{0e19}\u{0e35}\u{0e49}\u{0e08}\u{0e30}\u{0e44}\u{0e21}\u{0e48}\u{0e16}\u{0e39}\u{0e01}\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e40}\u{0e15}\u{0e47}\u{0e21}',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('\u{0e1b}\u{0e34}\u{0e14}'),
              ),
            ],
          ),
        ),
      ),
    );
    addressController.dispose();
  }

  void _showSettingsPlaceholder(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(message, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
        ?action,
      ],
    );
  }

  Widget _infoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          filled: true,
          fillColor: readOnly ? AppColors.background : AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            '\u{e42}\u{e1b}\u{e23}\u{e44}\u{e1f}\u{e25}\u{e4c}',
          ),
        ),
        body: Center(
          child: FilledButton(
            onPressed: () => context.goNamed(AppRoute.loginEmail),
            child: const Text(
              '\u{0e40}\u{0e02}\u{0e49}\u{0e32}\u{0e2a}\u{0e39}\u{0e48}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e2d}\u{0e35}\u{0e01}\u{0e04}\u{0e23}\u{0e31}\u{0e49}\u{0e07}',
            ),
          ),
        ),
      );
    }

    final profileValue = ref.watch(customerProfileRecordProvider(user.id));
    final metadata = user.userMetadata;
    final metadataName = (metadata?['full_name'] ?? metadata?['name'])
        ?.toString()
        .trim();
    final profile = profileValue.asData?.value;
    final fullName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : metadataName?.isNotEmpty == true
        ? metadataName!
        : '\u{0e25}\u{0e39}\u{0e01}\u{0e04}\u{0e49}\u{0e32}';
    final email = user.email ?? '';
    final avatarUrl = _avatarUrl(metadata);
    if (!profileValue.isLoading) _populateForm(profile, user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '\u{0e42}\u{0e1b}\u{0e23}\u{0e44}\u{0e1f}\u{0e25}\u{0e4c}',
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: '\u{0e41}\u{0e01}\u{0e49}\u{0e44}\u{0e02}\u{0e42}\u{0e1b}\u{0e23}\u{0e44}\u{0e1f}\u{0e25}\u{0e4c}',
              onPressed: profileValue.isLoading
                  ? null
                  : () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _sectionCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl),
                        child: avatarUrl == null
                            ? Text(
                                _initials(fullName),
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (profileValue.isLoading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      if (profileValue.hasError) ...[
                        const SizedBox(height: 10),
                        Text(
                          '\u{0e42}\u{0e2b}\u{0e25}\u{0e14}\u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}\u{0e42}\u{0e1b}\u{0e23}\u{0e44}\u{0e1f}\u{0e25}\u{0e4c}\u{0e44}\u{0e21}\u{0e48}\u{0e2a}\u{0e33}\u{0e40}\u{0e23}\u{0e47}\u{0e08}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  '\u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}\u{0e2a}\u{0e48}\u{0e27}\u{0e19}\u{0e15}\u{0e31}\u{0e27}',
                  action: _isEditing
                      ? TextButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _nameController.text =
                                      profile?.fullName ?? metadataName ?? '';
                                  _phoneController.text =
                                      profile?.phone ??
                                      metadata?['phone']?.toString() ??
                                      '';
                                  setState(() => _isEditing = false);
                                },
                          child: const Text(
                            '\u{0e22}\u{0e01}\u{0e40}\u{0e25}\u{0e34}\u{0e01}',
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                _sectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _infoField(
                          label: '\u{0e0a}\u{0e37}\u{0e48}\u{0e2d}',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          readOnly: !_isEditing,
                          validator: _isEditing ? _validateName : null,
                        ),
                        _infoField(
                          label: '\u{0e40}\u{0e1a}\u{0e2d}\u{0e23}\u{0e4c}\u{0e42}\u{0e17}\u{0e23}\u{0e28}\u{0e31}\u{0e1e}\u{0e17}\u{0e4c}',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          readOnly: !_isEditing,
                          validator: _isEditing ? _validatePhone : null,
                        ),
                        _infoField(
                          label: '\u{0e2d}\u{0e35}\u{0e40}\u{0e21}\u{0e25}',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProfile(user.id),
                              icon: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _isSaving
                                    ? '\u{0e01}\u{0e33}\u{0e25}\u{0e31}\u{0e07}\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}...'
                                    : '\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}\u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  '\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e02}\u{0e2d}\u{0e07}\u{0e09}\u{0e31}\u{0e19}',
                ),
                const SizedBox(height: 8),
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\u{0e22}\u{0e31}\u{0e07}\u{0e44}\u{0e21}\u{0e48}\u{0e21}\u{0e35}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e17}\u{0e35}\u{0e48}\u{0e1a}\u{0e31}\u{0e19}\u{0e17}\u{0e36}\u{0e01}\u{0e44}\u{0e27}\u{0e49}',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u{0e40}\u{0e21}\u{0e37}\u{0e48}\u{0e2d}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e08}\u{0e31}\u{0e14}\u{0e40}\u{0e01}\u{0e47}\u{0e1a}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e1e}\u{0e23}\u{0e49}\u{0e2d}\u{0e21} \u{0e04}\u{0e38}\u{0e13}\u{0e08}\u{0e30}\u{0e40}\u{0e1e}\u{0e34}\u{0e48}\u{0e21} \u{0e41}\u{0e01}\u{0e49}\u{0e44}\u{0e02} \u{0e2b}\u{0e23}\u{0e37}\u{0e2d}\u{0e25}\u{0e1a}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}\u{0e44}\u{0e14}\u{0e49}\u{0e17}\u{0e35}\u{0e48}\u{0e19}\u{0e35}\u{0e48}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _showAddressPlaceholder,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          '\u{0e40}\u{0e15}\u{0e23}\u{0e35}\u{0e22}\u{0e21}\u{0e40}\u{0e1e}\u{0e34}\u{0e48}\u{0e21}\u{0e17}\u{0e35}\u{0e48}\u{0e2d}\u{0e22}\u{0e39}\u{0e48}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  '\u{0e1b}\u{0e23}\u{0e30}\u{0e27}\u{0e31}\u{0e15}\u{0e34}\u{0e01}\u{0e32}\u{0e23}\u{0e08}\u{0e2d}\u{0e07}',
                ),
                const SizedBox(height: 8),
                _sectionCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '\u{0e22}\u{0e31}\u{0e07}\u{0e44}\u{0e21}\u{0e48}\u{0e1e}\u{0e1a}\u{0e02}\u{0e49}\u{0e2d}\u{0e21}\u{0e39}\u{0e25}\u{0e01}\u{0e32}\u{0e23}\u{0e08}\u{0e2d}\u{0e07}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.pushNamed(AppRoute.customerBookings),
                        child: const Text(
                          '\u{0e14}\u{0e39}\u{0e17}\u{0e31}\u{0e49}\u{0e07}\u{0e2b}\u{0e21}\u{0e14}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  '\u{0e01}\u{0e32}\u{0e23}\u{0e15}\u{0e31}\u{0e49}\u{0e07}\u{0e04}\u{0e48}\u{0e32}',
                ),
                const SizedBox(height: 8),
                _sectionCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          '\u{0e01}\u{0e32}\u{0e23}\u{0e41}\u{0e08}\u{0e49}\u{0e07}\u{0e40}\u{0e15}\u{0e37}\u{0e2d}\u{0e19}',
                        ),
                        subtitle: const Text(
                          '\u{0e15}\u{0e31}\u{0e49}\u{0e07}\u{0e04}\u{0e48}\u{0e32}\u{0e01}\u{0e32}\u{0e23}\u{0e41}\u{0e08}\u{0e49}\u{0e07}\u{0e40}\u{0e15}\u{0e37}\u{0e2d}\u{0e19}\u{0e08}\u{0e30}\u{0e1e}\u{0e23}\u{0e49}\u{0e2d}\u{0e21}\u{0e40}\u{0e21}\u{0e37}\u{0e48}\u{0e2d}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e2a}\u{0e48}\u{0e07}\u{0e01}\u{0e32}\u{0e23}\u{0e41}\u{0e08}\u{0e49}\u{0e07}\u{0e40}\u{0e15}\u{0e37}\u{0e2d}\u{0e19}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showSettingsPlaceholder(
                          '\u{0e01}\u{0e32}\u{0e23}\u{0e41}\u{0e08}\u{0e49}\u{0e07}\u{0e40}\u{0e15}\u{0e37}\u{0e2d}\u{0e19}',
                          '\u{0e15}\u{0e31}\u{0e49}\u{0e07}\u{0e04}\u{0e48}\u{0e32}\u{0e44}\u{0e14}\u{0e49}\u{0e40}\u{0e21}\u{0e37}\u{0e48}\u{0e2d}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}\u{0e01}\u{0e32}\u{0e23}\u{0e41}\u{0e08}\u{0e49}\u{0e07}\u{0e40}\u{0e15}\u{0e37}\u{0e2d}\u{0e19}\u{0e1e}\u{0e23}\u{0e49}\u{0e2d}\u{0e21}\u{0e43}\u{0e0a}\u{0e49}\u{0e07}\u{0e32}\u{0e19}',
                        ),
                      ),
                      const Divider(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.manage_accounts_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          '\u{0e1a}\u{0e31}\u{0e0d}\u{0e0a}\u{0e35}\u{0e41}\u{0e25}\u{0e30}\u{0e04}\u{0e27}\u{0e32}\u{0e21}\u{0e1b}\u{0e25}\u{0e2d}\u{0e14}\u{0e20}\u{0e31}\u{0e22}',
                        ),
                        subtitle: const Text(
                          '\u{0e08}\u{0e31}\u{0e14}\u{0e01}\u{0e32}\u{0e23}\u{0e1a}\u{0e31}\u{0e0d}\u{0e0a}\u{0e35}\u{0e41}\u{0e25}\u{0e30}\u{0e01}\u{0e32}\u{0e23}\u{0e40}\u{0e02}\u{0e49}\u{0e32}\u{0e2a}\u{0e39}\u{0e48}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showSettingsPlaceholder(
                          '\u{0e1a}\u{0e31}\u{0e0d}\u{0e0a}\u{0e35}\u{0e41}\u{0e25}\u{0e30}\u{0e04}\u{0e27}\u{0e32}\u{0e21}\u{0e1b}\u{0e25}\u{0e2d}\u{0e14}\u{0e20}\u{0e31}\u{0e22}',
                          '\u{0e2b}\u{0e32}\u{0e01}\u{0e15}\u{0e49}\u{0e2d}\u{0e07}\u{0e01}\u{0e32}\u{0e23}\u{0e40}\u{0e1b}\u{0e25}\u{0e35}\u{0e48}\u{0e22}\u{0e19}\u{0e23}\u{0e2b}\u{0e31}\u{0e2a}\u{0e1c}\u{0e48}\u{0e32}\u{0e19} \u{0e01}\u{0e23}\u{0e38}\u{0e13}\u{0e32}\u{0e43}\u{0e0a}\u{0e49}\u{0e2b}\u{0e19}\u{0e49}\u{0e32}\u{0e08}\u{0e31}\u{0e14}\u{0e01}\u{0e32}\u{0e23}\u{0e1a}\u{0e31}\u{0e0d}\u{0e0a}\u{0e35}\u{0e40}\u{0e21}\u{0e37}\u{0e48}\u{0e2d}\u{0e1f}\u{0e35}\u{0e40}\u{0e08}\u{0e2d}\u{0e23}\u{0e4c}\u{0e1e}\u{0e23}\u{0e49}\u{0e2d}\u{0e21}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSigningOut ? null : _signOut,
                    icon: _isSigningOut
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(
                      _isSigningOut
                          ? '\u{0e01}\u{0e33}\u{0e25}\u{0e31}\u{0e07}\u{0e2d}\u{0e2d}\u{0e01}...'
                          : '\u{0e2d}\u{0e2d}\u{0e01}\u{0e08}\u{0e32}\u{0e01}\u{0e23}\u{0e30}\u{0e1a}\u{0e1a}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
