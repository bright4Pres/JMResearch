// ============================================================================
// vendor_dashboard_screen.dart - Vendor Dashboard (REDESIGNED)
// ============================================================================
// Beautiful dashboard for vendors to manage their kitchens
// Features: gradient header, animated cards, statistics summary
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/vendor_kitchen_service.dart';
import '../../services/user_service.dart';
import '../../services/auth.dart';
import '../../theme/app_theme.dart';
import '../home/edit_profile_screen.dart';
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
  final AuthService _auth = AuthService();
  String? currentUserId;
  User? currentUser;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    currentUser = FirebaseAuth.instance.currentUser;
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
      drawer: _buildDrawer(),
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
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.smallRadius,
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
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
    return FloatingActionButton(
      onPressed: _createNewKitchen,
      backgroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.add_business, color: Colors.white),
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

  // --------------------------------------------------------------------------
  // Drawer - Vendor Menu
  // --------------------------------------------------------------------------
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // drawer header with gradient
          _buildDrawerHeader(),
          // menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'My Kitchens',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.add_business_outlined,
                  title: 'Create Kitchen',
                  onTap: () {
                    Navigator.pop(context);
                    _createNewKitchen();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => Navigator.pop(context),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _showSignOutDialog();
                  },
                ),
              ],
            ),
          ),
          // app version footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text('Iskaon v1.0.0', style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: AppColors.warmGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // profile pic
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/profile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // name
          Text(
            currentUser?.displayName ?? 'Vendor',
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          // email
          Text(
            currentUser?.email ?? 'No email',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // vendor badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'VENDOR',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: AppRadius.smallRadius,
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Sign Out Dialog
  // --------------------------------------------------------------------------
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Sign Out'),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await _auth.signOut();
              navigator.pop();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
