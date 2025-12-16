// ============================================================================
// kitchen_detail_screen.dart - Staff/Owner Kitchen Management
// ============================================================================
// this is where staff members manage their kitchen - add items, view orders,
// update order statuses, etc. has 5 tabs: Full Meals, Snacks, Pending, Ready,
// Finished. the first two tabs show menu items, the last three show orders
// filtered by status.
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';
import 'add_item_screen.dart';
import 'analytics_screen.dart';

// app-wide colors (DRY = Don't Repeat Yourself)
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class KitchenDetailScreen extends StatefulWidget {
  final Kitchen kitchen;

  const KitchenDetailScreen({Key? key, required this.kitchen})
    : super(key: key);

  @override
  State<KitchenDetailScreen> createState() => _KitchenDetailScreenState();
}

class _KitchenDetailScreenState extends State<KitchenDetailScreen>
    with SingleTickerProviderStateMixin {
  // TabController needs vsync for smooth animations
  late TabController _tabController;
  final VendorKitchenService _vendorService = VendorKitchenService();

  @override
  void initState() {
    super.initState();
    // 5 tabs total: 2 for menu items + 3 for order statuses
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    // always clean up controllers!
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.kitchen.name,
          style: const TextStyle(
            color: _kAccentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
        actions: [
          // pickup locations button
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Pickup Locations',
            onPressed: () => _showPickupLocationsDialog(),
          ),
          // analytics button in top right
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
            onPressed: () => _navigateToAnalytics(),
          ),
        ],
        // isScrollable allows tabs to scroll if they don't fit
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kAccentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kAccentColor,
          isScrollable: true, // tabs can scroll horizontally
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Full Meals'),
            Tab(icon: Icon(Icons.fastfood), text: 'Snacks'),
            Tab(icon: Icon(Icons.timelapse), text: 'Pending'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Ready'),
            Tab(icon: Icon(Icons.check_circle), text: 'Finished'),
          ],
        ),
      ),
      body: Column(
        children: [
          // kitchen header card at top
          _buildKitchenHeader(),
          // tab content takes up remaining space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // menu item tabs
                _buildItemsList('fullmeals'),
                _buildItemsList('snacks'),
                // order tabs filtered by status
                _buildOrdersList(statusFilter: 'pending'),
                _buildOrdersList(statusFilter: 'ready for pick up'),
                _buildOrdersList(statusFilter: 'finished'),
              ],
            ),
          ),
        ],
      ),
      // FAB to add new menu items
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddItem,
        backgroundColor: _kAccentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // navigation helpers - keep the build method clean
  // --------------------------------------------------------------------------
  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(kitchen: widget.kitchen),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // shows dialog to manage pickup locations for this kitchen
  // sellers can add/remove their own custom pickup spots here
  // --------------------------------------------------------------------------
  void _showPickupLocationsDialog() {
    // we need a stateful dialog, so we create a separate widget
    showDialog(
      context: context,
      builder: (ctx) => _PickupLocationsDialog(
        kitchenId: widget.kitchen.id,
        initialLocations: widget.kitchen.pickupLocations,
        vendorService: _vendorService,
      ),
    );
  }

  void _navigateToAddItem() {
    // figure out which category based on current tab
    // only makes sense for first 2 tabs (menu items)
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

  // --------------------------------------------------------------------------
  // kitchen header - shows name and description
  // --------------------------------------------------------------------------
  Widget _buildKitchenHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kitchen.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.kitchen.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // builds list of menu items for a category (fullmeals or snacks)
  // StreamBuilder means list updates automatically when firebase changes
  // --------------------------------------------------------------------------
  Widget _buildItemsList(String category) {
    return StreamBuilder<List<KitchenItem>>(
      stream: _vendorService.getItemsByKitchenAndCategory(
        widget.kitchen.id,
        category,
      ),
      builder: (context, snapshot) {
        // loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error state
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data ?? [];

        // empty state - show helpful message
        if (items.isEmpty) {
          return _buildEmptyItemsState(category);
        }

        // got items - build the list
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItemCard(items[index]),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // empty state for menu items tab
  // --------------------------------------------------------------------------
  Widget _buildEmptyItemsState(String category) {
    final isFullMeals = category == 'fullmeals';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFullMeals ? Icons.restaurant : Icons.fastfood,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isFullMeals ? 'full meals' : 'snacks'} available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first ${isFullMeals ? 'meal' : 'snack'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // single item card with edit/delete buttons
  // --------------------------------------------------------------------------
  Widget _buildItemCard(KitchenItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kAccentColor,
                    ),
                  ),
                ],
              ),
            ),
            // action buttons
            Column(
              children: [
                IconButton(
                  onPressed: () => _editItem(item),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // edit item - navigates to add item screen with the item pre-filled
  // --------------------------------------------------------------------------
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
          editingItem: item, // pass the item to edit
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // delete item with confirmation dialog
  // always confirm before deleting - users hate accidental deletes
  // --------------------------------------------------------------------------
  void _deleteItem(KitchenItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await _vendorService.deleteKitchenItem(item.id);
              if (mounted) {
                _showSnackBar(
                  success
                      ? 'Item deleted successfully'
                      : 'Failed to delete item',
                  success,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // builds order list filtered by status
  // shows customer name, order items, total, and status update buttons
  // --------------------------------------------------------------------------
  Widget _buildOrdersList({required String statusFilter}) {
    return StreamBuilder<List<KitchenOrder>>(
      stream: _vendorService.getOrdersByKitchen(widget.kitchen.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // filter orders based on which tab we're on
        final allOrders = snapshot.data ?? [];
        final orders = _filterOrdersByStatus(allOrders, statusFilter);

        if (orders.isEmpty) {
          return _buildEmptyOrdersState(statusFilter);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildOrderCard(orders[index]),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // filter orders - treat empty status as 'pending' for backwards compat
  // --------------------------------------------------------------------------
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
  // empty state for orders tab
  // --------------------------------------------------------------------------
  Widget _buildEmptyOrdersState(String statusFilter) {
    final (icon, message) = switch (statusFilter) {
      'pending' => (Icons.timelapse, 'No pending orders'),
      'ready for pick up' => (
        Icons.local_shipping,
        'No orders ready for pickup',
      ),
      _ => (Icons.check_circle, 'No finished orders yet'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // order card - shows all order details + status update buttons
  // --------------------------------------------------------------------------
  Widget _buildOrderCard(KitchenOrder order) {
    final isPending =
        order.status.toLowerCase() == 'pending' || order.status.isEmpty;
    final status = order.status.isEmpty
        ? 'PENDING'
        : order.status.toUpperCase();
    final statusBg = isPending ? Colors.orange[100] : Colors.green[100];
    final statusFg = isPending ? Colors.orange[800] : Colors.green[800];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row: customer name + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.isEmpty ? 'Guest' : order.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kAccentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pickup: ${order.pickupLocation}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            // order items list
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.qty} x ${item.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('₱${(item.price * item.qty).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Placed: ${order.createdAt}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            // status update buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setStatus(order.id, 'ready for pick up'),
                    child: const Text('Ready for Pickup'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                    ),
                    onPressed: () => _setStatus(order.id, 'finished'),
                    child: const Text(
                      'Mark Finished',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // update order status in firebase
  // --------------------------------------------------------------------------
  Future<void> _setStatus(String orderId, String status) async {
    final success = await _vendorService.updateOrderStatus(orderId, status);
    if (!mounted) return;
    _showSnackBar(
      success
          ? 'Order updated to ${status.toUpperCase()}'
          : 'Failed to update order',
      success,
    );
  }

  // --------------------------------------------------------------------------
  // helper to show feedback to user
  // --------------------------------------------------------------------------
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}

// ============================================================================
// _PickupLocationsDialog - Dialog for managing pickup locations
// ============================================================================
// this is a stateful dialog that lets sellers add/remove pickup locations
// uses a TextEditingController for the input field and maintains local state
// until the user saves changes. changes are saved immediately to firebase
// when adding/removing items for better UX (no save button needed)
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
  // local copy of locations so we can update UI immediately
  late List<String> _locations;
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // make a copy so we don't modify the original list
    _locations = List<String>.from(widget.initialLocations);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.location_on, color: _kAccentColor),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Pickup Locations', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // info text explaining what this is for
            Text(
              'Add pickup spots where customers can collect their orders',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // input row for adding new location
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Main Gate, Canteen',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addLocation(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _kAccentColor),
                  onPressed: _isLoading ? null : _addLocation,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // list of current locations (scrollable if many)
            if (_locations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No pickup locations yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place, color: _kAccentColor),
                      title: Text(location),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _removeLocation(location),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // add a new pickup location to the list and save to firebase
  // --------------------------------------------------------------------------
  Future<void> _addLocation() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // check for duplicates (case insensitive)
    if (_locations.any((l) => l.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location already exists')));
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
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add location')));
    }

    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------------------------
  // remove a pickup location from the list and save to firebase
  // --------------------------------------------------------------------------
  Future<void> _removeLocation(String location) async {
    setState(() => _isLoading = true);

    final success = await widget.vendorService.removePickupLocation(
      widget.kitchenId,
      location,
    );

    if (success) {
      setState(() => _locations.remove(location));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove location')),
      );
    }

    setState(() => _isLoading = false);
  }
}
