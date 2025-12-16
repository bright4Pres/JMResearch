// ============================================================================
// kitchen_detail_screen.dart - Staff/Owner Kitchen Management (REDESIGNED)
// ============================================================================
// Beautiful kitchen management screen with modern tabs, cards, and animations
// Features: gradient header, animated lists, status badges, order management
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';
import '../../theme/app_theme.dart';
import 'add_item_screen.dart';
import 'analytics_screen.dart';

class KitchenDetailScreen extends StatefulWidget {
  final Kitchen kitchen;

  const KitchenDetailScreen({super.key, required this.kitchen});

  @override
  State<KitchenDetailScreen> createState() => _KitchenDetailScreenState();
}

class _KitchenDetailScreenState extends State<KitchenDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VendorKitchenService _vendorService = VendorKitchenService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [_buildAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildItemsList('fullmeals'),
            _buildItemsList('snacks'),
            _buildOrdersList(statusFilter: 'pending'),
            _buildOrdersList(statusFilter: 'ready for pick up'),
            _buildOrdersList(statusFilter: 'finished'),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // --------------------------------------------------------------------------
  // App Bar with Gradient and Tabs
  // --------------------------------------------------------------------------
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
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
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.smallRadius,
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          tooltip: 'Pickup Locations',
          onPressed: _showPickupLocationsDialog,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.smallRadius,
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 20),
          ),
          tooltip: 'Analytics',
          onPressed: _navigateToAnalytics,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.warmGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 80),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // kitchen icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.mediumRadius,
                      boxShadow: AppShadows.medium,
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // kitchen info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.kitchen.name,
                          style: AppTypography.h2.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.kitchen.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        StatusBadge(
                          status: widget.kitchen.isActive ? 'Open' : 'Closed',
                          isLarge: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: AppRadius.largeRadius,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: AppRadius.mediumRadius,
            ),
            isScrollable: true,
            labelStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.restaurant, size: 18), text: 'Meals'),
              Tab(icon: Icon(Icons.fastfood, size: 18), text: 'Snacks'),
              Tab(icon: Icon(Icons.schedule, size: 18), text: 'Pending'),
              Tab(icon: Icon(Icons.delivery_dining, size: 18), text: 'Ready'),
              Tab(icon: Icon(Icons.check_circle, size: 18), text: 'Done'),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Menu Items List
  // --------------------------------------------------------------------------
  Widget _buildItemsList(String category) {
    return StreamBuilder<List<KitchenItem>>(
      stream: _vendorService.getItemsByKitchenAndCategory(
        widget.kitchen.id,
        category,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoader());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Error loading items',
            subtitle: '${snapshot.error}',
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return EmptyState(
            icon: category == 'fullmeals' ? Icons.restaurant : Icons.fastfood,
            title: 'No ${category == 'fullmeals' ? 'meals' : 'snacks'} yet',
            subtitle: 'Tap + to add your first item',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItemCard(items[index], index),
        );
      },
    );
  }

  Widget _buildItemCard(KitchenItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: AppDecorations.cardElevated,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // category icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: Icon(
                  item.category == 'fullmeals'
                      ? Icons.restaurant
                      : Icons.fastfood,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTypography.h4),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: AppTypography.price,
                    ),
                  ],
                ),
              ),
              // actions
              Column(
                children: [
                  _buildActionButton(
                    Icons.edit_outlined,
                    AppColors.primary,
                    () => _editItem(item),
                  ),
                  const SizedBox(height: 4),
                  _buildActionButton(
                    Icons.delete_outline,
                    AppColors.error,
                    () => _deleteItem(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.smallRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smallRadius,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Orders List
  // --------------------------------------------------------------------------
  Widget _buildOrdersList({required String statusFilter}) {
    return StreamBuilder<List<KitchenOrder>>(
      stream: _vendorService.getOrdersByKitchen(widget.kitchen.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoader());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Error loading orders',
            subtitle: '${snapshot.error}',
          );
        }

        final allOrders = snapshot.data ?? [];
        final orders = _filterOrdersByStatus(allOrders, statusFilter);

        if (orders.isEmpty) {
          return _buildEmptyOrdersState(statusFilter);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: orders.length,
          itemBuilder: (context, index) =>
              _buildOrderCard(orders[index], index),
        );
      },
    );
  }

  List<KitchenOrder> _filterOrdersByStatus(
    List<KitchenOrder> orders,
    String statusFilter,
  ) {
    return orders.where((order) {
      final status = order.status.toLowerCase();
      if (statusFilter == 'pending') {
        return status == 'pending' || status.isEmpty;
      }
      return status == statusFilter;
    }).toList();
  }

  Widget _buildEmptyOrdersState(String statusFilter) {
    final (icon, title, subtitle) = switch (statusFilter) {
      'pending' => (
        Icons.schedule,
        'No pending orders',
        'New orders will appear here',
      ),
      'ready for pick up' => (
        Icons.delivery_dining,
        'Nothing ready',
        'Orders ready for pickup appear here',
      ),
      _ => (
        Icons.check_circle,
        'No completed orders',
        'Finished orders will be shown here',
      ),
    };

    return EmptyState(icon: icon, title: title, subtitle: subtitle);
  }

  Widget _buildOrderCard(KitchenOrder order, int index) {
    final isPending =
        order.status.toLowerCase() == 'pending' || order.status.isEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: AppDecorations.cardElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: AppRadius.smallRadius,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName.isEmpty
                              ? 'Guest'
                              : order.customerName,
                          style: AppTypography.h4,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.pickupLocation,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${order.total.toStringAsFixed(2)}',
                        style: AppTypography.price,
                      ),
                      StatusBadge(
                        status: order.status.isEmpty ? 'pending' : order.status,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // items
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Items', style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.sm),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: AppRadius.smallRadius,
                                ),
                                child: Text(
                                  '${item.qty}x',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(item.name, style: AppTypography.bodyMedium),
                            ],
                          ),
                          Text(
                            '₱${(item.price * item.qty).toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // action buttons
                  if (isPending ||
                      order.status.toLowerCase() == 'ready for pick up')
                    Row(
                      children: [
                        if (isPending) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppButtons.secondary,
                              onPressed: () =>
                                  _setStatus(order.id, 'ready for pick up'),
                              icon: const Icon(Icons.delivery_dining, size: 18),
                              label: const Text('Ready'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.smallRadius,
                              ),
                            ),
                            onPressed: () => _setStatus(order.id, 'finished'),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Done'),
                          ),
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

  // --------------------------------------------------------------------------
  // FAB
  // --------------------------------------------------------------------------
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToAddItem,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // --------------------------------------------------------------------------
  // Navigation & Actions
  // --------------------------------------------------------------------------
  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(kitchen: widget.kitchen),
      ),
    );
  }

  void _navigateToAddItem() {
    final currentTabIndex = _tabController.index;
    final category = currentTabIndex == 0 ? 'fullmeals' : 'snacks';
    final displayName = currentTabIndex == 0 ? 'Full Meals' : 'Snacks';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          kitchen: widget.kitchen,
          category: category,
          categoryDisplayName: displayName,
        ),
      ),
    );
  }

  void _editItem(KitchenItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          kitchen: widget.kitchen,
          category: item.category,
          categoryDisplayName: item.category == 'fullmeals'
              ? 'Full Meals'
              : 'Snacks',
          editingItem: item,
        ),
      ),
    );
  }

  void _deleteItem(KitchenItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Delete Item?', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Are you sure you want to delete "${item.name}"?',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: AppButtons.secondary,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smallRadius,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await _vendorService.deleteKitchenItem(
                          item.id,
                        );
                        if (mounted)
                          _showSnackBar(
                            success ? 'Item deleted' : 'Delete failed',
                            success,
                          );
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setStatus(String orderId, String status) async {
    final success = await _vendorService.updateOrderStatus(orderId, status);
    if (!mounted) return;
    _showSnackBar(
      success ? 'Order updated to ${status.toUpperCase()}' : 'Failed to update',
      success,
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Pickup Locations Dialog
  // --------------------------------------------------------------------------
  void _showPickupLocationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _PickupLocationsDialog(
        kitchenId: widget.kitchen.id,
        initialLocations: widget.kitchen.pickupLocations,
        vendorService: _vendorService,
      ),
    );
  }
}

// ============================================================================
// Pickup Locations Dialog (REDESIGNED)
// ============================================================================
class _PickupLocationsDialog extends StatefulWidget {
  final String kitchenId;
  final List<String> initialLocations;
  final VendorKitchenService vendorService;

  const _PickupLocationsDialog({
    required this.kitchenId,
    required this.initialLocations,
    required this.vendorService,
  });

  @override
  State<_PickupLocationsDialog> createState() => _PickupLocationsDialogState();
}

class _PickupLocationsDialogState extends State<_PickupLocationsDialog> {
  late List<String> _locations;
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locations = List<String>.from(widget.initialLocations);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pickup Locations', style: AppTypography.h4),
                      Text(
                        'Where customers collect orders',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: AppDecorations.inputDecoration(
                      label: 'New Location',
                      hint: 'e.g., Main Gate',
                      prefixIcon: Icons.add_location_alt,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addLocation(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _addLocation,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // locations list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _locations.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 40,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No locations yet',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.smallRadius,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  location,
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _removeLocation(location),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),

            // done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppButtons.primary,
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLocation() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_locations.any((l) => l.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location already exists'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.vendorService.addPickupLocation(
      widget.kitchenId,
      text,
    );

    if (success) {
      setState(() {
        _locations.add(text);
        _controller.clear();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _removeLocation(String location) async {
    setState(() => _isLoading = true);
    final success = await widget.vendorService.removePickupLocation(
      widget.kitchenId,
      location,
    );
    if (success) {
      setState(() => _locations.remove(location));
    }
    setState(() => _isLoading = false);
  }
}
