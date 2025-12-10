import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';

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
  late final TabController _tabController;
  final VendorKitchenService _vendorService = VendorKitchenService();
  final Map<String, _CartEntry> _cart = {};
  final TextEditingController _nameController = TextEditingController();
  String _pickupStation = 'Activity Center';

  @override
  void initState() {
    super.initState();
    // default to snacks tab unless told otherwise
    final startIndex = widget.initialCategory == 'fullmeals' ? 0 : 1;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: startIndex,
    );
  }

  @override
  void dispose() {
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
          style: const TextStyle(color: Colors.deepOrange),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.deepOrange,
          tabs: const [
            Tab(text: 'Full Meals', icon: Icon(Icons.restaurant)),
            Tab(text: 'Snacks', icon: Icon(Icons.fastfood)),
          ],
        ),
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
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
            ),
      body: Column(
        children: [
          // little header to remind which kitchen we're inside
          _buildKitchenHeader(),
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

  Widget _buildItemsList(String category, String title) {
    return StreamBuilder<List<KitchenItem>>(
      stream: _vendorService.getItemsByKitchenAndCategory(
        widget.kitchen.id,
        category,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading items: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data ?? [];

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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category == 'fullmeals'
                          ? Icons.restaurant
                          : Icons.fastfood,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.deepOrange,
                    ),
                    onPressed: () => _addToCart(item),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKitchenHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: const Icon(Icons.store, color: Colors.deepOrange),
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

  void _addToCart(KitchenItem item) {
    setState(() {
      _cart.update(
        item.id,
        (existing) => existing.copyWith(qty: existing.qty + 1),
        ifAbsent: () => _CartEntry(item: item, qty: 1),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  double _cartTotal() {
    return _cart.values
        .map((e) => e.item.price * e.qty)
        .fold(0.0, (a, b) => a + b);
  }

  int _cartItemCount() {
    return _cart.values.map((e) => e.qty).fold(0, (a, b) => a + b);
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
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
                      if (_cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Cart is empty.'),
                        )
                      else ...[
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
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Pickup station',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _pickupStation,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Activity Center',
                                  child: Text('Activity Center'),
                                ),
                                DropdownMenuItem(
                                  value: 'Canteen',
                                  child: Text('Canteen'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _pickupStation = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
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

  void _updateQty(String itemId, int delta) {
    setState(() {
      final current = _cart[itemId];
      if (current == null) return;
      final newQty = current.qty + delta;
      if (newQty <= 0) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = current.copyWith(qty: newQty);
      }
    });
  }

  void _handleCheckout() {
    if (_cart.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = _nameController.text.trim();
    final total = _cartTotal();

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
    final order = KitchenOrder(
      id: '',
      kitchenId: widget.kitchen.id,
      kitchenName: widget.kitchen.name,
      userId: userId,
      ownerId: widget.kitchen.ownerId,
      customerName: name.isEmpty ? 'Guest' : name,
      pickupLocation: _pickupStation,
      status: 'pending',
      total: total,
      items: orderItems,
      createdAt: DateTime.now(),
    );

    _vendorService.createOrder(order);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order placed for ${name.isEmpty ? 'Guest' : name} at $_pickupStation. Total ₱${total.toStringAsFixed(2)}',
        ),
      ),
    );

    setState(() {
      _cart.clear();
      _nameController.clear();
      _pickupStation = 'Activity Center';
    });
  }
}

class _CartEntry {
  _CartEntry({required this.item, required this.qty});

  final KitchenItem item;
  final int qty;

  _CartEntry copyWith({KitchenItem? item, int? qty}) {
    return _CartEntry(item: item ?? this.item, qty: qty ?? this.qty);
  }
}
