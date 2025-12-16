// ============================================================================
// kitchen_menu_screen.dart - Customer Menu & Cart Screen
// ============================================================================
// this is where customers browse a kitchen's menu and add items to their cart
// has two tabs: Full Meals and Snacks. at the bottom there's a cart bar that
// shows total and lets you view cart / checkout. the cart is stored locally
// in a Map<String, _CartEntry> where the key is the item id.
//
// checkout creates a KitchenOrder and saves it to firestore with status 'pending'
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';

// consistent colors across the app
const _kAccentColor = Colors.deepOrange;

class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({
    super.key,
    required this.kitchen,
    this.initialCategory = 'snacks',
  });

  final Kitchen kitchen;
  final String initialCategory; // 'fullmeals' or 'snacks'

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen>
    with SingleTickerProviderStateMixin {
  // tab controller for Full Meals / Snacks tabs
  late final TabController _tabController;

  // firebase service for menu items
  final VendorKitchenService _vendorService = VendorKitchenService();

  // cart stored as a map: itemId -> CartEntry (item + quantity)
  // using a map makes it easy to update quantities by item id
  final Map<String, _CartEntry> _cart = {};

  // checkout form fields
  final TextEditingController _nameController = TextEditingController();
  // pickup station - will be set from kitchen's custom locations or default
  String? _pickupStation;

  @override
  void initState() {
    super.initState();
    // start on snacks tab unless told otherwise
    final startIndex = widget.initialCategory == 'fullmeals' ? 0 : 1;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: startIndex,
    );
  }

  @override
  void dispose() {
    // always clean up controllers
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kitchen.name,
          style: const TextStyle(color: _kAccentColor),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kAccentColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: _kAccentColor,
          tabs: const [
            Tab(text: 'Full Meals', icon: Icon(Icons.restaurant)),
            Tab(text: 'Snacks', icon: Icon(Icons.fastfood)),
          ],
        ),
      ),
      // cart bar at bottom (only shows if cart has items)
      bottomNavigationBar: _cart.isEmpty ? null : _buildCartBar(),
      body: Column(
        children: [
          // header with kitchen info
          _buildKitchenHeader(),
          // menu items in tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList('fullmeals', 'Full Meals'),
                _buildItemsList('snacks', 'Snacks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // sticky cart bar at bottom - shows item count, total, view cart button
  // --------------------------------------------------------------------------
  Widget _buildCartBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_cartItemCount()} item${_cartItemCount() == 1 ? '' : 's'} in cart',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ₱${_cartTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kAccentColor,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _openCartSheet,
              icon: const Icon(
                Icons.shopping_cart_checkout,
                color: Colors.white,
              ),
              label: const Text(
                'View Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // builds list of menu items for a category
  // uses StreamBuilder for real-time updates from firestore
  // --------------------------------------------------------------------------
  Widget _buildItemsList(String category, String title) {
    return StreamBuilder<List<KitchenItem>>(
      stream: _vendorService.getItemsByKitchenAndCategory(
        widget.kitchen.id,
        category,
      ),
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading items: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data ?? [];

        // empty state
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category == 'fullmeals' ? Icons.restaurant : Icons.fastfood,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No $title yet.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // list of items
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildItemCard(items[index], category),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // single menu item card with add-to-cart button
  // --------------------------------------------------------------------------
  Widget _buildItemCard(KitchenItem item, String category) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // category icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category == 'fullmeals' ? Icons.restaurant : Icons.fastfood,
              color: _kAccentColor,
            ),
          ),
          const SizedBox(width: 12),
          // item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // price
          Text(
            '₱${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kAccentColor,
            ),
          ),
          // add to cart button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _kAccentColor),
            onPressed: () => _addToCart(item),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // kitchen info header
  // --------------------------------------------------------------------------
  Widget _buildKitchenHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: _kAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kitchen.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.kitchen.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // open/closed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.kitchen.isActive
                  ? Colors.green[100]
                  : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.kitchen.isActive ? 'OPEN' : 'CLOSED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: widget.kitchen.isActive
                    ? Colors.green[700]
                    : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CART METHODS
  // --------------------------------------------------------------------------

  // add item to cart (or increment qty if already in cart)
  void _addToCart(KitchenItem item) {
    setState(() {
      _cart.update(
        item.id,
        (existing) => existing.copyWith(qty: existing.qty + 1),
        ifAbsent: () => _CartEntry(item: item, qty: 1),
      );
    });
    // quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // calculate cart total (price * qty for each item, then sum)
  double _cartTotal() =>
      _cart.values.map((e) => e.item.price * e.qty).fold(0.0, (a, b) => a + b);

  // count total items (sum of all quantities)
  int _cartItemCount() =>
      _cart.values.map((e) => e.qty).fold(0, (a, b) => a + b);

  // --------------------------------------------------------------------------
  // builds dropdown items for pickup locations
  // uses the kitchen's custom locations if set, otherwise shows default options
  // --------------------------------------------------------------------------
  List<DropdownMenuItem<String>> _buildPickupLocationItems() {
    final locations = widget.kitchen.pickupLocations;

    // if seller hasn't set custom locations, provide defaults
    if (locations.isEmpty) {
      return const [
        DropdownMenuItem(
          value: 'Activity Center',
          child: Text('Activity Center'),
        ),
        DropdownMenuItem(value: 'Canteen', child: Text('Canteen')),
      ];
    }

    // use the seller's custom pickup locations
    return locations
        .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
        .toList();
  }

  // update qty in cart (+1 or -1). removes item if qty drops to 0
  void _updateQty(String itemId, int delta) {
    setState(() {
      final current = _cart[itemId];
      if (current == null) return;

      final newQty = current.qty + delta;
      if (newQty <= 0) {
        _cart.remove(itemId); // remove if qty goes to 0
      } else {
        _cart[itemId] = current.copyWith(qty: newQty);
      }
    });
  }

  // --------------------------------------------------------------------------
  // opens the cart bottom sheet with checkout form
  // --------------------------------------------------------------------------
  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows sheet to resize with keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          // padding for keyboard
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.9,
            initialChildSize: 0.8,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Cart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // cart contents
                      if (_cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Cart is empty.'),
                        )
                      else ...[
                        // cart items with +/- buttons
                        ..._cart.values.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.item.name),
                            subtitle: Text(
                              '₱${entry.item.price.toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () =>
                                      _updateQty(entry.item.id, -1),
                                ),
                                Text('${entry.qty}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQty(entry.item.id, 1),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(),

                        // total row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '₱${_cartTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kAccentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // checkout form: name input
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // pickup station dropdown - uses kitchen's custom locations
                        // if no custom locations set, show a default option
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Pickup station',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _pickupStation,
                              hint: const Text('Select pickup location'),
                              isExpanded: true,
                              items: _buildPickupLocationItems(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _pickupStation = value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // checkout button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kAccentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleCheckout,
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // creates the order in firestore and clears cart
  // --------------------------------------------------------------------------
  void _handleCheckout() {
    if (_cart.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // validate that pickup location is selected
    if (_pickupStation == null || _pickupStation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }

    // get current user (for userId in the order)
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = _nameController.text.trim();
    final total = _cartTotal();
    final pickup = _pickupStation!; // safe to use ! after validation

    // convert cart entries to KitchenOrderItem objects
    final orderItems = _cart.values
        .map(
          (e) => KitchenOrderItem(
            itemId: e.item.id,
            name: e.item.name,
            price: e.item.price,
            qty: e.qty,
            category: e.item.category,
          ),
        )
        .toList();

    // build the order object
    final order = KitchenOrder(
      id: '', // firestore autogenerates this
      kitchenId: widget.kitchen.id,
      kitchenName: widget.kitchen.name,
      userId: userId,
      ownerId: widget.kitchen.ownerId,
      customerName: name.isEmpty ? 'Guest' : name,
      pickupLocation: pickup,
      status: 'pending', // starts as pending
      total: total,
      items: orderItems,
      createdAt: DateTime.now(),
    );

    // save to firestore
    _vendorService.createOrder(order);

    // close the sheet
    Navigator.pop(context);

    // show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order placed for ${name.isEmpty ? 'Guest' : name} at $pickup. Total ₱${total.toStringAsFixed(2)}',
        ),
      ),
    );

    // reset cart and form
    setState(() {
      _cart.clear();
      _nameController.clear();
      _pickupStation = null; // reset to null so user must select again
    });
  }
}

// ============================================================================
// _CartEntry - helper class to store item + quantity in cart
// ============================================================================
// using a class instead of just qty makes it easy to access item details
// (name, price, etc.) when displaying the cart
class _CartEntry {
  final KitchenItem item;
  final int qty;

  _CartEntry({required this.item, required this.qty});

  // copyWith lets us create a new entry with updated qty (immutable pattern)
  _CartEntry copyWith({KitchenItem? item, int? qty}) {
    return _CartEntry(item: item ?? this.item, qty: qty ?? this.qty);
  }
}
