// ============================================================================
// orders_screen.dart - Customer Orders View
// ============================================================================
// this screen shows the logged-in user's orders split into tabs by status
// uses StreamBuilder to get real-time updates from firestore (so when the
// kitchen marks your order ready, it auto-moves to the Ready tab - pretty cool)
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';

// app-wide colors so we don't repeat ourselves (DRY principle baby)
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

// SingleTickerProviderStateMixin is required for TabController animations
// basically flutter needs a "vsync" to sync tab animations with screen refresh
class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  // our firebase service - handles all the database stuff
  final VendorKitchenService _vendorService = VendorKitchenService();

  // controller for switching between Pending/Ready/Finished tabs
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 3 tabs: pending, ready, finished
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // IMPORTANT: always dispose controllers to prevent memory leaks
    // if you forget this, your app will slowly eat up RAM like a hungry hippo
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // grab current user ID - if not logged in, userId will be empty string
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text('Orders', style: TextStyle(color: _kAccentColor)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
        // TabBar lives at the bottom of AppBar for that clean look
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kAccentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kAccentColor,
          tabs: const [
            Tab(icon: Icon(Icons.timelapse), text: 'Pending'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Ready'),
            Tab(icon: Icon(Icons.check_circle), text: 'Finished'),
          ],
        ),
      ),
      // show sign-in prompt if not logged in, otherwise show the tabs
      body: userId.isEmpty
          ? _buildSignedOutState()
          : TabBarView(
              controller: _tabController,
              children: [
                // each tab gets its own stream filtered by status
                _buildOrdersStream(userId, 'pending'),
                _buildOrdersStream(userId, 'ready for pick up'),
                _buildOrdersStream(userId, 'finished'),
              ],
            ),
    );
  }

  // --------------------------------------------------------------------------
  // shows when user isn't logged in
  // --------------------------------------------------------------------------
  Widget _buildSignedOutState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Sign in to view your orders',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // this is where the magic happens - StreamBuilder listens to firestore
  // and rebuilds the list automatically when data changes
  // --------------------------------------------------------------------------
  Widget _buildOrdersStream(String userId, String statusFilter) {
    return StreamBuilder<List<KitchenOrder>>(
      // getOrdersForUser returns a Stream that updates in real-time
      stream: _vendorService.getOrdersForUser(userId),
      builder: (context, snapshot) {
        // still loading from firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // something went wrong (probably firebase rules or network)
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading orders: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // filter orders based on which tab we're on
        final allOrders = snapshot.data ?? [];
        final orders = _filterOrdersByStatus(allOrders, statusFilter);

        // no orders? show empty state
        if (orders.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        // got orders - build the list
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildOrderTile(orders[index]),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // filters orders by status - handles the "pending" edge case where status
  // might be empty string (legacy orders or just-created ones)
  // --------------------------------------------------------------------------
  List<KitchenOrder> _filterOrdersByStatus(
    List<KitchenOrder> orders,
    String statusFilter,
  ) {
    return orders.where((order) {
      final status = order.status.toLowerCase();
      // treat empty status as pending (backwards compatibility)
      if (statusFilter == 'pending') {
        return status == 'pending' || status.isEmpty;
      }
      return status == statusFilter;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // empty state widget - shows different icons/messages per tab
  // --------------------------------------------------------------------------
  Widget _buildEmptyState(String statusFilter) {
    // pick the right icon and message based on tab
    final (icon, message) = switch (statusFilter) {
      'pending' => (Icons.timelapse, 'No pending orders'),
      'ready for pick up' => (
        Icons.local_shipping,
        'No orders ready for pickup',
      ),
      _ => (Icons.check_circle, 'No finished orders yet'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // builds a single order card - shows kitchen name, status badge, items, etc
  // tap to show order details modal
  // --------------------------------------------------------------------------
  Widget _buildOrderTile(KitchenOrder order) {
    // figure out status colors (pending = orange, others = green)
    final isPending =
        order.status.toLowerCase() == 'pending' || order.status.isEmpty;
    final status = order.status.isEmpty
        ? 'PENDING'
        : order.status.toUpperCase();
    final statusBg = isPending ? Colors.orange[200] : Colors.green[200];
    final statusFg = isPending ? Colors.orange[900] : Colors.green[900];

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row: kitchen name + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.kitchenName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // status pill/badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // order summary
            Text(
              '${order.items.length} item(s) · ₱${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              'Pickup: ${order.pickupLocation}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(order.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            // hint to tap for details
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Tap to view items',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // shows a modal with full order details including all items purchased
  // --------------------------------------------------------------------------
  void _showOrderDetails(KitchenOrder order) {
    final isPending =
        order.status.toLowerCase() == 'pending' || order.status.isEmpty;
    final status = order.status.isEmpty
        ? 'PENDING'
        : order.status.toUpperCase();
    final statusBg = isPending ? Colors.orange[100] : Colors.green[100];
    final statusFg = isPending ? Colors.orange[800] : Colors.green[800];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // header with kitchen name and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.kitchenName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // order info
                    Text(
                      'Ordered: ${_formatTimestamp(order.createdAt)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Text(
                      'Pickup: ${order.pickupLocation}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // items header
                    const Text(
                      'Items Ordered',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(),

                    // items list
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // quantity badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _kAccentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.qty}x',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _kAccentColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // item name
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            // item total price
                            Text(
                              '₱${(item.price * item.qty).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(),

                    // total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₱${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _kAccentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // formats DateTime into a nice short string like "3/15 09:30"
  // --------------------------------------------------------------------------
  String _formatTimestamp(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.month}/${date.day} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
