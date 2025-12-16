// ============================================================================
// home_screen.dart - Main Home Screen (REDESIGNED)
// ============================================================================
// the main hub of the app - shows kitchens for customers, dashboard for staff
// features: modern card design, smooth animations, gradient accents
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/models/app_user.dart';
import 'package:myapp/theme/app_theme.dart';
import '../../services/vendor_kitchen_service.dart';
import 'kitchen_menu_screen.dart';
import 'orders_screen.dart';
import 'pickup_locations_screen.dart';
import 'edit_profile_screen.dart';
import '../admin/vendor_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // firebase user for display info
  User? currentUser;

  // services
  final AuthService _auth = AuthService();
  final UserService _userService = UserService();
  final VendorKitchenService _vendorService = VendorKitchenService();

  // search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // animation controller for staggered list animation
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userService.currentUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: appUser?.isStaff == true
              ? _buildStaffView()
              : _buildCustomerView(appUser),
          drawer: _buildDrawer(appUser),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Staff View - shows dashboard in a styled container
  // --------------------------------------------------------------------------
  Widget _buildStaffView() {
    return const VendorDashboardScreen();
  }

  // --------------------------------------------------------------------------
  // Customer View - beautiful scrollable home page
  // --------------------------------------------------------------------------
  Widget _buildCustomerView(AppUser? appUser) {
    return CustomScrollView(
      slivers: [
        // modern sliver app bar with gradient
        _buildSliverAppBar(appUser),
        // content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // quick actions row
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.lg),

                // search bar
                _buildSearchBar(),
                const SizedBox(height: AppSpacing.lg),

                // section title
                Text('Available Kitchens', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        // kitchens list
        _buildKitchensList(),
        // bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Modern Sliver App Bar with gradient and profile
  // --------------------------------------------------------------------------
  Widget _buildSliverAppBar(AppUser? appUser) {
    return SliverAppBar(
      expandedHeight: 200,
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
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () {
              // TODO: notifications
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.smallRadius,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
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
                      // greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser?.displayName ?? 'Food Lover',
                              style: AppTypography.h2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'What would you like to eat today?',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // profile avatar
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        child: Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/profile.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // --------------------------------------------------------------------------
  // Quick Action Cards
  // --------------------------------------------------------------------------
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.receipt_long_rounded,
            label: 'My Orders',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.location_on_rounded,
            label: 'Pickup Spots',
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PickupLocationsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.largeRadius,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.smallRadius,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Search Bar
  // --------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search for food or kitchen...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: AppTypography.bodyMedium,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.smallRadius,
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Kitchens List with Stream
  // --------------------------------------------------------------------------
  Widget _buildKitchensList() {
    return StreamBuilder<List<Kitchen>>(
      stream: _vendorService.getAllKitchens(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AppLoader(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Oops! Something went wrong',
              subtitle: 'Error: ${snapshot.error}',
            ),
          );
        }

        final allKitchens = snapshot.data ?? [];

        // Filter kitchens based on search query
        final kitchens = _searchQuery.isEmpty
            ? allKitchens
            : allKitchens.where((kitchen) {
                return kitchen.name.toLowerCase().contains(_searchQuery) ||
                    kitchen.description.toLowerCase().contains(_searchQuery);
              }).toList();

        if (kitchens.isEmpty && _searchQuery.isNotEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No results found',
              subtitle: 'Try searching for something else',
            ),
          );
        }

        if (kitchens.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.store_outlined,
              title: 'No kitchens yet',
              subtitle: 'Check back soon for delicious food options!',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final kitchen = kitchens[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          (index * 0.1).clamp(0.0, 1.0),
                          ((0.6 + index * 0.1)).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      ((0.6 + index * 0.1)).clamp(0.0, 1.0),
                    ),
                  ),
                  child: _buildKitchenCard(kitchen),
                ),
              ),
            );
          }, childCount: kitchens.length),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Kitchen Card - Modern Design
  // --------------------------------------------------------------------------
  Widget _buildKitchenCard(Kitchen kitchen) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => KitchenMenuScreen(kitchen: kitchen)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: AppDecorations.cardElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // kitchen banner with gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.9),
                    AppColors.primaryLight.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Stack(
                children: [
                  // background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // status badge
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: StatusBadge(
                      status: kitchen.isActive ? 'open' : 'closed',
                    ),
                  ),
                  // kitchen icon
                  Positioned(
                    bottom: -20,
                    left: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.mediumRadius,
                        boxShadow: AppShadows.medium,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // kitchen info
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg + 8,
                AppSpacing.md,
                AppSpacing.md,
              ),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kitchen.description,
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // category chips
                  Row(
                    children: [
                      _buildCategoryChip(Icons.restaurant, 'Meals'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildCategoryChip(Icons.fastfood, 'Snacks'),
                      const Spacer(),
                      // pickup locations count
                      if (kitchen.pickupLocations.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${kitchen.pickupLocations.length} pickup spots',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Modern Navigation Drawer
  // --------------------------------------------------------------------------
  Widget _buildDrawer(AppUser? appUser) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // drawer header with gradient
          _buildDrawerHeader(appUser),
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
                  icon: Icons.receipt_long_rounded,
                  title: 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.location_on_outlined,
                  title: 'Pickup Locations',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PickupLocationsScreen(),
                      ),
                    );
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

  Widget _buildDrawerHeader(AppUser? appUser) {
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
            currentUser?.displayName ?? 'User',
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
          // staff badge
          if (appUser?.isStaff == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'STAFF',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
