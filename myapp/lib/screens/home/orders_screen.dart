// ============================================================================
// orders_screen.dart - Customer Orders View (REDESIGNED)
// ============================================================================
// shows the logged-in user's orders with beautiful cards and smooth animations
// uses StreamBuilder for real-time updates from firestore
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';
import 'package:myapp/theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final VendorKitchenService _vendorService = VendorKitchenService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // gradient app bar
          SliverAppBar(
            expandedHeight: 120,
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
                decoration: const BoxDecoration(
                  gradient: AppColors.warmGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'My Orders',
                          style: AppTypography.h2.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your food orders',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  labelStyle: AppTypography.button.copyWith(fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 18),
                          SizedBox(width: 6),
                          Text('Pending'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining, size: 18),
                          SizedBox(width: 6),
                          Text('Ready'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 6),
                          Text('Done'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: userId.isEmpty
            ? _buildSignedOutState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersStream(userId, 'pending'),
                  _buildOrdersStream(userId, 'ready for pick up'),
                  _buildOrdersStream(userId, 'finished'),
                ],
              ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Signed Out State
  // --------------------------------------------------------------------------
  Widget _buildSignedOutState() {
    return const EmptyState(
      icon: Icons.login_rounded,
      title: 'Sign in required',
      subtitle: 'Please sign in to view your orders',
    );
  }

  // --------------------------------------------------------------------------
  // Orders Stream Builder
  // --------------------------------------------------------------------------
  Widget _buildOrdersStream(String userId, String statusFilter) {
    return StreamBuilder<List<KitchenOrder>>(
      stream: _vendorService.getOrdersForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoader());
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            subtitle: 'Error: ${snapshot.error}',
          );
        }

        final allOrders = snapshot.data ?? [];
        final orders = _filterOrdersByStatus(allOrders, statusFilter);

        if (orders.isEmpty) {
          return _buildEmptyState(statusFilter);
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

  // --------------------------------------------------------------------------
  // Empty State
  // --------------------------------------------------------------------------
  Widget _buildEmptyState(String statusFilter) {
    final (icon, title, subtitle) = switch (statusFilter) {
      'pending' => (
        Icons.schedule_rounded,
        'No pending orders',
        'Your pending orders will appear here',
      ),
      'ready for pick up' => (
        Icons.delivery_dining_rounded,
        'Nothing ready yet',
        'Orders ready for pickup will show here',
      ),
      _ => (
        Icons.history_rounded,
        'No completed orders',
        'Your order history will appear here',
      ),
    };

    return EmptyState(icon: icon, title: title, subtitle: subtitle);
  }

  // --------------------------------------------------------------------------
  // Order Card - Modern Design
  // --------------------------------------------------------------------------
  Widget _buildOrderCard(KitchenOrder order, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _showOrderDetails(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: AppDecorations.cardElevated,
          child: Column(
            children: [
              // header with gradient
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
                    // kitchen icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.warmGradient,
                        borderRadius: AppRadius.mediumRadius,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // kitchen name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.kitchenName,
                            style: AppTypography.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(order.createdAt),
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    // status badge
                    StatusBadge(
                      status: order.status.isEmpty ? 'pending' : order.status,
                    ),
                  ],
                ),
              ),
              // order details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // items summary
                    Row(
                      children: [
                        _buildDetailRow(
                          Icons.shopping_bag_outlined,
                          '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          order.pickupLocation,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // divider
                    Container(
                      height: 1,
                      color: AppColors.textHint.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // total and action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total', style: AppTypography.caption),
                            Text(
                              '₱${order.total.toStringAsFixed(2)}',
                              style: AppTypography.price,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Order Details Modal
  // --------------------------------------------------------------------------
  void _showOrderDetails(KitchenOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}

// ============================================================================
// Order Details Sheet - Full order info in a beautiful modal
// ============================================================================
class _OrderDetailsSheet extends StatelessWidget {
  final KitchenOrder order;

  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.warmGradient,
                              borderRadius: AppRadius.mediumRadius,
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.kitchenName,
                                  style: AppTypography.h3,
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  status: order.status.isEmpty
                                      ? 'pending'
                                      : order.status,
                                  isLarge: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // order info cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today_rounded,
                              label: 'Ordered',
                              value: _formatDate(order.createdAt),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.location_on_rounded,
                              label: 'Pickup',
                              value: order.pickupLocation,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // items section
                      Text('Order Items', style: AppTypography.h4),
                      const SizedBox(height: AppSpacing.md),

                      // items list
                      ...order.items.map((item) => _buildItemRow(item)),

                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      // total row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTypography.h3),
                          Text(
                            '₱${order.total.toStringAsFixed(2)}',
                            style: AppTypography.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // close button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: AppButtons.primary,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(KitchenOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Row(
        children: [
          // quantity badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smallRadius,
            ),
            child: Center(
              child: Text(
                '${item.qty}x',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // item name
          Expanded(child: Text(item.name, style: AppTypography.bodyLarge)),
          // price
          Text(
            '₱${(item.price * item.qty).toStringAsFixed(2)}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
