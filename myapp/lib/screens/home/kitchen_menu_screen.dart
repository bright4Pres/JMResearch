// ============================================================================
// kitchen_menu_screen.dart - Customer Menu & Cart Screen (REDESIGNED)
// ============================================================================
// Browse a kitchen's menu and add items to cart with beautiful modern UI
// Features: animated item cards, modern cart sheet, gradient accents
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';
import 'package:myapp/theme/app_theme.dart';

class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({
    super.key,
    required this.kitchen,
    this.initialCategory = 'snacks',
  });

  final Kitchen kitchen;
  final String initialCategory;

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final VendorKitchenService _vendorService = VendorKitchenService();
  final Map<String, _CartEntry> _cart = {};
  final TextEditingController _nameController = TextEditingController();
  String? _pickupStation;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // custom sliver app bar with kitchen info
          SliverAppBar(
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.warmGradient,
                    ),
                  ),
                  // kitchen info
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              // kitchen icon
                              Container(
                                width: 60,
                                height: 60,
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
                              // kitchen name and description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.kitchen.name,
                                            style: AppTypography.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // status indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.kitchen.isActive
                                                ? AppColors.success
                                                : AppColors.error,
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.full,
                                            ),
                                          ),
                                          child: Text(
                                            widget.kitchen.isActive
                                                ? 'Open'
                                                : 'Closed',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.kitchen.description,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                          Icon(Icons.restaurant, size: 18),
                          SizedBox(width: 8),
                          Text('Full Meals'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood, size: 18),
                          SizedBox(width: 8),
                          Text('Snacks'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildItemsList('fullmeals', 'Full Meals'),
            _buildItemsList('snacks', 'Snacks'),
          ],
        ),
      ),
      // floating cart bar
      bottomNavigationBar: _cart.isEmpty ? null : _buildCartBar(),
    );
  }

  // --------------------------------------------------------------------------
  // Cart Bar - Floating bottom bar with cart summary
  // --------------------------------------------------------------------------
  Widget _buildCartBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.warmGradient,
          borderRadius: AppRadius.largeRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // cart icon with badge
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cartItemCount()}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // total info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_cartItemCount()} item${_cartItemCount() == 1 ? '' : 's'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '₱${_cartTotal().toStringAsFixed(2)}',
                    style: AppTypography.h4.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            // view cart button
            GestureDetector(
              onTap: _openCartSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    Text(
                      'Checkout',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primary,
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
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Menu Items List with StreamBuilder
  // --------------------------------------------------------------------------
  Widget _buildItemsList(String category, String title) {
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
            title: 'Error loading menu',
            subtitle: '${snapshot.error}',
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return EmptyState(
            icon: category == 'fullmeals'
                ? Icons.restaurant_menu
                : Icons.fastfood,
            title: 'No $title yet',
            subtitle: 'This kitchen hasn\'t added any $title items',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildItemCard(items[index], category, index),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Item Card - Beautiful menu item with animation
  // --------------------------------------------------------------------------
  Widget _buildItemCard(KitchenItem item, String category, int index) {
    final isInCart = _cart.containsKey(item.id);
    final cartQty = _cart[item.id]?.qty ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
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
            borderRadius: AppRadius.largeRadius,
            onTap: () => _addToCart(item),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // category icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient.scale(0.3),
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: Icon(
                      category == 'fullmeals'
                          ? Icons.restaurant
                          : Icons.fastfood,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // item details
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
                  const SizedBox(width: AppSpacing.sm),
                  // add to cart button / qty indicator
                  if (isInCart)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _updateQty(item.id, -1),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$cartQty',
                              style: AppTypography.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _addToCart(item),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Icon(Icons.add, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Cart Methods
  // --------------------------------------------------------------------------
  void _addToCart(KitchenItem item) {
    setState(() {
      _cart.update(
        item.id,
        (existing) => existing.copyWith(qty: existing.qty + 1),
        ifAbsent: () => _CartEntry(item: item, qty: 1),
      );
    });

    // haptic-like visual feedback
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${item.name} added'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  double _cartTotal() =>
      _cart.values.map((e) => e.item.price * e.qty).fold(0.0, (a, b) => a + b);

  int _cartItemCount() =>
      _cart.values.map((e) => e.qty).fold(0, (a, b) => a + b);

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

  List<DropdownMenuItem<String>> _buildPickupLocationItems() {
    final locations = widget.kitchen.pickupLocations;
    if (locations.isEmpty) {
      return const [
        DropdownMenuItem(
          value: 'Activity Center',
          child: Text('Activity Center'),
        ),
        DropdownMenuItem(value: 'Canteen', child: Text('Canteen')),
      ];
    }
    return locations
        .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
        .toList();
  }

  // --------------------------------------------------------------------------
  // Cart Sheet - Beautiful checkout modal
  // --------------------------------------------------------------------------
  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CartSheet(
        cart: _cart,
        nameController: _nameController,
        pickupStation: _pickupStation,
        pickupLocations: _buildPickupLocationItems(),
        onPickupChanged: (value) => setState(() => _pickupStation = value),
        onUpdateQty: _updateQty,
        onCheckout: _handleCheckout,
        cartTotal: _cartTotal,
      ),
    );
  }

  void _handleCheckout() {
    if (_cart.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (_pickupStation == null || _pickupStation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select a pickup location'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = _nameController.text.trim();
    final total = _cartTotal();
    final pickup = _pickupStation!;

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
      pickupLocation: pickup,
      status: 'pending',
      total: total,
      items: orderItems,
      createdAt: DateTime.now(),
    );

    _vendorService.createOrder(order);
    Navigator.pop(context);

    // success dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Order Placed!', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your order of ₱${total.toStringAsFixed(2)} will be ready for pickup at $pickup',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppButtons.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _cart.clear();
      _nameController.clear();
      _pickupStation = null;
    });
  }
}

// ============================================================================
// Cart Sheet Widget
// ============================================================================
class _CartSheet extends StatefulWidget {
  final Map<String, _CartEntry> cart;
  final TextEditingController nameController;
  final String? pickupStation;
  final List<DropdownMenuItem<String>> pickupLocations;
  final Function(String?) onPickupChanged;
  final Function(String, int) onUpdateQty;
  final VoidCallback onCheckout;
  final double Function() cartTotal;

  const _CartSheet({
    required this.cart,
    required this.nameController,
    required this.pickupStation,
    required this.pickupLocations,
    required this.onPickupChanged,
    required this.onUpdateQty,
    required this.onCheckout,
    required this.cartTotal,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  String? _selectedPickup;

  @override
  void initState() {
    super.initState();
    _selectedPickup = widget.pickupStation;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              // header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Cart', style: AppTypography.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
                      // cart items
                      ...widget.cart.values.map(
                        (entry) => _buildCartItem(entry),
                      ),

                      if (widget.cart.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.lg),

                        // total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTypography.h4),
                            Text(
                              '₱${widget.cartTotal().toStringAsFixed(2)}',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // checkout form
                        Text('Checkout Details', style: AppTypography.h4),
                        const SizedBox(height: AppSpacing.md),

                        // name input
                        TextField(
                          controller: widget.nameController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Your Name',
                            hint: 'Enter your name',
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // pickup dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.mediumRadius,
                            border: Border.all(
                              color: AppColors.textHint.withValues(alpha: 0.2),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPickup,
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.textHint,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Select pickup location',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: widget.pickupLocations,
                              onChanged: (value) {
                                setState(() => _selectedPickup = value);
                                widget.onPickupChanged(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // checkout button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppButtons.primary,
                            onPressed: widget.onCheckout,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_checkout),
                                const SizedBox(width: 8),
                                Text(
                                  'Place Order • ₱${widget.cartTotal().toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCartItem(_CartEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Row(
        children: [
          // item icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smallRadius,
            ),
            child: const Icon(
              Icons.fastfood,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₱${entry.item.price.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // qty controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textHint.withValues(alpha: 0.2),
              ),
              borderRadius: AppRadius.smallRadius,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () {
                    widget.onUpdateQty(entry.item.id, -1);
                    setState(() {});
                  },
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                Text(
                  '${entry.qty}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    widget.onUpdateQty(entry.item.id, 1);
                    setState(() {});
                  },
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Cart Entry Helper Class
// ============================================================================
class _CartEntry {
  final KitchenItem item;
  final int qty;

  _CartEntry({required this.item, required this.qty});

  _CartEntry copyWith({KitchenItem? item, int? qty}) {
    return _CartEntry(item: item ?? this.item, qty: qty ?? this.qty);
  }
}
