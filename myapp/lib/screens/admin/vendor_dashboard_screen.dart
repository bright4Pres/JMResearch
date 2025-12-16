// ============================================================================
// vendor_dashboard_screen.dart - Vendor Dashboard (REDESIGNED)
// ============================================================================
// Beautiful dashboard for vendors to manage their kitchens
// Features: gradient header, animated cards, statistics summary
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'create_kitchen_screen.dart';
import 'kitchen_detail_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  final VendorKitchenService _vendorService = VendorKitchenService();
  final UserService _userService = UserService();
  String? currentUserId;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getCurrentUser() async {
    final user = await _userService.getCurrentUserData();
    setState(() {
      currentUserId = user?.uid;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: AppLoader()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Kitchen>>(
        stream: _vendorService.getKitchensByOwner(currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoader());
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: '${snapshot.error}',
            );
          }

          final kitchens = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // gradient header
              _buildAppBar(kitchens.length),
              // content
              if (kitchens.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildKitchenCard(kitchens[index], index),
                      childCount: kitchens.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // --------------------------------------------------------------------------
  // App Bar with Gradient
  // --------------------------------------------------------------------------
  Widget _buildAppBar(int kitchenCount) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: AppRadius.smallRadius,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.warmGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.mediumRadius,
                          boxShadow: AppShadows.medium,
                        ),
                        child: const Icon(
                          Icons.store_mall_directory,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vendor Dashboard',
                              style: AppTypography.h2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your food business',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // stats row
                  Row(
                    children: [
                      _buildStatChip(Icons.store, '$kitchenCount', 'Kitchens'),
                      const SizedBox(width: AppSpacing.md),
                      _buildStatChip(Icons.check_circle, 'Active', 'Status'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Empty State
  // --------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 60,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No Kitchens Yet', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start your food business journey by creating your first kitchen.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              style: AppButtons.primary,
              onPressed: _createNewKitchen,
              icon: const Icon(Icons.add_business),
              label: const Text('Create First Kitchen'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Kitchen Card - Animated
  // --------------------------------------------------------------------------
  Widget _buildKitchenCard(Kitchen kitchen, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: AppDecorations.cardElevated,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openKitchenDetail(kitchen),
            borderRadius: AppRadius.largeRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // kitchen image/icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // kitchen details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                kitchen.name,
                                style: AppTypography.h4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(
                              status: kitchen.isActive ? 'Open' : 'Closed',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kitchen.description,
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // quick stats
                        Row(
                          children: [
                            _buildMiniStat(Icons.inventory_2_outlined, 'Items'),
                            const SizedBox(width: AppSpacing.md),
                            _buildMiniStat(
                              Icons.receipt_long_outlined,
                              'Orders',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // FAB
  // --------------------------------------------------------------------------
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _createNewKitchen,
      backgroundColor: AppColors.primary,
      elevation: 4,
      icon: const Icon(Icons.add_business, color: Colors.white),
      label: Text(
        'New Kitchen',
        style: AppTypography.button.copyWith(color: Colors.white),
      ),
    );
  }

  void _createNewKitchen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateKitchenScreen()),
    );
  }

  void _openKitchenDetail(Kitchen kitchen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KitchenDetailScreen(kitchen: kitchen),
      ),
    );
  }
}
