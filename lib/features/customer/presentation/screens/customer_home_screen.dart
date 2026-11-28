import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/customer_marketplace_providers.dart';
import '../../data/customer_marketplace_repository.dart';

import 'package:fixmatch/core/widgets/auth_primary_button.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showAllCategories = false;
  late int _selectedTab;
  String? _serviceAreaFilter;

  static const List<_ServiceCategory> _categories = [
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e41}\u{0e2d}\u{0e23}\u{0e4c}',
      icon: Icons.ac_unit_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e44}\u{0e1f}\u{0e1f}\u{0e49}\u{0e32}',
      icon: Icons.bolt_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e1b}\u{0e23}\u{0e30}\u{0e1b}\u{0e32}',
      icon: Icons.water_drop_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e0b}\u{0e48}\u{0e2d}\u{0e21}\u{0e40}\u{0e04}\u{0e23}\u{0e37}\u{0e48}\u{0e2d}\u{0e07}\u{0e43}\u{0e0a}\u{0e49}\u{0e44}\u{0e1f}\u{0e1f}\u{0e49}\u{0e32}',
      icon: Icons.kitchen_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e40}\u{0e1f}\u{0e2d}\u{0e23}\u{0e4c}\u{0e19}\u{0e34}\u{0e40}\u{0e08}\u{0e2d}\u{0e23}\u{0e4c}',
      icon: Icons.chair_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e0a}\u{0e48}\u{0e32}\u{0e07}\u{0e01}\u{0e38}\u{0e0d}\u{0e41}\u{0e08}',
      icon: Icons.key_rounded,
    ),
    _ServiceCategory(
      name: '\u{0e1a}\u{0e23}\u{0e34}\u{0e01}\u{0e32}\u{0e23}\u{0e2d}\u{0e37}\u{0e48}\u{0e19} \u{0e46}',
      icon: Icons.handyman_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<_ServiceCategory> get _filteredCategories {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _categories;

    return _categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
  }

  void _showPreviewMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final userMetadata = ref.watch(currentUserProvider)?.userMetadata;
    final technicians = ref.watch(recommendedTechniciansProvider);
    final rawName = (userMetadata?['full_name'] ?? userMetadata?['name'])
        ?.toString()
        .trim();
    final displayName = rawName == null || rawName.isEmpty
        ? 'คุณลูกค้า'
        : rawName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 900
                ? 860.0
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: _selectedTab == 0
                    ? _buildHomePage(displayName, contentWidth, technicians)
                    : _buildDestinationPage(
                        displayName,
                        contentWidth,
                        technicians,
                      ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == 3 && GoRouter.maybeOf(context) != null) {
            context.pushNamed<void>(AppRoute.customerAccountProfile);
            return;
          }
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(
    String displayName,
    double contentWidth,
    AsyncValue<List<RecommendedTechnician>> technicians,
  ) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        _buildGreetingHeader(displayName),
        const SizedBox(height: 20),
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildPromotionalBanner(),
        const SizedBox(height: 28),
        _buildSectionHeading('หมวดหมู่บริการ'),
        const SizedBox(height: 14),
        _buildCategoryGrid(contentWidth - 40),
        const SizedBox(height: 28),
        _buildSectionHeading('ช่างแนะนำ'),
        const SizedBox(height: 14),
        _buildTechnicianResults(technicians),
        const SizedBox(height: 28),
        _buildReportProblemCard(),
      ],
    );
  }

  Widget _buildDestinationPage(
    String displayName,
    double contentWidth,
    AsyncValue<List<RecommendedTechnician>> technicians,
  ) {
    if (_selectedTab == 1) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Text('ค้นหาช่าง', style: AppTextStyles.headingLarge),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 20),
          _buildTechnicianResults(technicians),
        ],
      );
    }
    if (_selectedTab == 2) {
      return _buildPlaceholderPage(
        icon: Icons.calendar_month_outlined,
        title: 'การจอง',
        message: 'เมื่อเริ่มจองบริการ รายการจองของคุณจะแสดงที่นี่',
      );
    }
    return _buildPlaceholderPage(
      icon: Icons.person_outline_rounded,
      title: 'โปรไฟล์',
      message: 'สวัสดี, $displayName',
    );
  }

  Widget _buildPlaceholderPage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(String displayName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สวัสดี, $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'วันนี้มีอะไรให้ FixMatch ช่วยไหม?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            tooltip: 'การแจ้งเตือน',
            onPressed: () => _showPreviewMessage('การแจ้งเตือนกำลังพัฒนา'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('customerHomeSearchField'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'ค้นหาช่างหรือบริการ',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ล้างคำค้นหา',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            tooltip: 'ตัวกรอง',
            onPressed: _showFilters,
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionalBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showIllustration = constraints.maxWidth >= 360;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'มีปัญหาเรื่องบ้านใช่ไหม?',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ค้นหาช่างที่เหมาะกับงานของคุณได้ที่ FixMatch',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedTab = 1);
                        FocusScope.of(context).requestFocus(_searchFocusNode);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ค้นหาช่างเลย',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              if (showIllustration) ...[
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    color: AppColors.surface,
                    size: 34,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeading(String title) {
    final hasMoreCategories =
        title ==
            '\u0e2b\u0e21\u0e27\u0e14\u0e2b\u0e21\u0e39\u0e48\u0e1a\u0e23\u0e34\u0e01\u0e32\u0e23' &&
        _filteredCategories.length > 4 &&
        _searchQuery.trim().isEmpty;
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
        if (hasMoreCategories)
          TextButton(
            onPressed: () =>
                setState(() => _showAllCategories = !_showAllCategories),
            child: Text(
              _showAllCategories
                  ? '\u0e22\u0e48\u0e2d\u0e2b\u0e21\u0e27\u0e14\u0e2b\u0e21\u0e39\u0e48'
                  : '\u0e14\u0e39\u0e17\u0e31\u0e49\u0e07\u0e2b\u0e21\u0e14',
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid(double availableWidth) {
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return _buildEmptySearchState();
    }

    final columns = availableWidth >= 320
        ? 4
        : availableWidth >= 240
        ? 3
        : 2;
    final showAll = _showAllCategories || _searchQuery.trim().isNotEmpty;
    final visibleCategories = showAll
        ? categories
        : categories.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCategories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            final isSelected = _selectedCategory == category.name;

            return Card(
              margin: EdgeInsets.zero,
              color: isSelected ? AppColors.primarySurface : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _selectedCategory = category.name);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              category.icon,
                              color: AppColors.primary,
                              size: 23,
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              right: -7,
                              top: -7,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        category.name,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text('ไม่พบหมวดหมู่ที่ค้นหา', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(
              'ลองค้นหาด้วยคำอื่น หรือ ล้างคำค้นหา',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianResults(
    AsyncValue<List<RecommendedTechnician>> technicianValue,
  ) {
    return technicianValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              const Text('ยังโหลดรายชื่อช่างไม่ได้'),
              TextButton(
                onPressed: () => ref.invalidate(recommendedTechniciansProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (technicians) {
        final query = _searchQuery.trim().toLowerCase();
        final areaQuery = (_serviceAreaFilter ?? '').trim().toLowerCase();
        final filtered = technicians.where((technician) {
          final matchesQuery =
              query.isEmpty ||
              technician.fullName.toLowerCase().contains(query) ||
              technician.serviceCategories.any(
                (category) => category.toLowerCase().contains(query),
              ) ||
              (technician.bio?.toLowerCase().contains(query) ?? false);
          final matchesCategory =
              _selectedCategory == null ||
              technician.serviceCategories.any(
                (category) =>
                    category.toLowerCase() == _selectedCategory!.toLowerCase(),
              );
          final matchesArea =
              areaQuery.isEmpty ||
              (technician.serviceArea?.toLowerCase().contains(areaQuery) ??
                  false);
          return matchesQuery && matchesCategory && matchesArea;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyTechniciansState(
            technicians.isEmpty
                ? 'ยังไม่มีช่างที่ได้รับอนุมัติ'
                : 'ไม่พบช่างที่ตรงกับเงื่อนไข',
          );
        }
        return Column(
          children: filtered
              .map(
                (technician) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTechnicianCard(technician),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyTechniciansState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.handyman_outlined,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(message, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(
              'ลองเปลี่ยนคำค้นหาหรือตัวกรองภายหลัง',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(RecommendedTechnician technician) {
    final categories = technician.serviceCategories.toList()..sort();
    final initials = technician.fullName.trim().isEmpty
        ? '?'
        : technician.fullName.trim().characters.first.toUpperCase();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTechnicianDetails(technician),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  initials,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      categories.isEmpty
                          ? 'ยังไม่ระบุประเภทงาน'
                          : categories.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (technician.serviceArea?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              technician.serviceArea!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (technician.bio?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 7),
                      Text(
                        technician.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTechnicianDetails(RecommendedTechnician technician) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final categories = technician.serviceCategories.toList()..sort();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        technician.fullName.characters.first.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        technician.fullName,
                        style: AppTextStyles.headingSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  categories.isEmpty
                      ? 'ยังไม่ระบุประเภทงาน'
                      : categories.join(' · '),
                ),
                if (technician.serviceArea?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text('พื้นที่ให้บริการ: ${technician.serviceArea}'),
                ],
                if (technician.bio?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text(technician.bio!),
                ],
                const SizedBox(height: 12),
                Text(
                  'ยังไม่มีข้อมูลคะแนนและรีวิว',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTechnicianDetails(RecommendedTechnician technician) {
    if (GoRouter.maybeOf(context) == null) {
      _showTechnicianDetails(technician);
      return;
    }
    context.pushNamed<void>(
      AppRoute.technicianDetail,
      pathParameters: {'technicianId': technician.profileId},
      extra: technician,
    );
  }

  Future<void> _showFilters() async {
    final technicians =
        ref.read(recommendedTechniciansProvider).asData?.value ??
        const <RecommendedTechnician>[];
    final availableCategories =
        technicians
            .expand((technician) => technician.serviceCategories)
            .toSet()
            .toList()
          ..sort();
    final areaController = TextEditingController(text: _serviceAreaFilter);
    var category = _selectedCategory;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
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
                Text('ตัวกรองช่าง', style: AppTextStyles.headingSmall),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      category != null && availableCategories.contains(category)
                      ? category
                      : null,
                  decoration: const InputDecoration(labelText: 'ประเภทบริการ'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('ทุกประเภท'),
                    ),
                    ...availableCategories.map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(
                    () => category = value == null || value.isEmpty
                        ? null
                        : value,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(
                    labelText: 'พื้นที่ให้บริการ',
                    hintText: 'พิมพ์จังหวัดหรือเขต',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _serviceAreaFilter = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('ล้างตัวกรอง'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = category;
                          _serviceAreaFilter =
                              areaController.text.trim().isEmpty
                              ? null
                              : areaController.text.trim();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('นำไปใช้'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    areaController.dispose();
  }

  Widget _buildReportProblemCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'มีปัญหาเรื่องงานซ่อม?',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'บอกเราได้ว่าต้องการความช่วยเหลือเรื่องอะไร',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              text: 'เริ่มต้นแจ้งปัญหา',
              onPressed: _showReportProblemForm,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportProblemForm() async {
    final descriptionController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('แจ้งปัญหางานซ่อม', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(
                'อธิบายสิ่งที่ต้องการให้ช่างช่วย ระบบยังไม่ส่งข้อมูลจนกว่าบริการแจ้งงานจะพร้อม',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'รายละเอียดปัญหา',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      ),
    );
    descriptionController.dispose();
  }
}

class _ServiceCategory {
  const _ServiceCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
