import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';
import 'add_item_screen.dart';

class KitchenDetailScreen extends StatefulWidget {
  final Kitchen kitchen;

  const KitchenDetailScreen({Key? key, required this.kitchen})
    : super(key: key);

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 236, 191),
      appBar: AppBar(
        title: Text(
          widget.kitchen.name,
          style: const TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Full Meals'),
            Tab(icon: Icon(Icons.fastfood), text: 'Snacks'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Kitchen Info Header
          _buildKitchenHeader(),
          // Items Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList('fullmeals'),
                _buildItemsList('snacks'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddItem(),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
          // Kitchen Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.kitchen.imageUrl != null
                  ? Image.network(
                      widget.kitchen.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 40,
                        );
                      },
                    )
                  : Icon(Icons.restaurant, color: Colors.grey[400], size: 40),
            ),
          ),
          const SizedBox(width: 16),
          // Kitchen Details
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.kitchen.isActive
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.kitchen.isActive ? 'ACTIVE' : 'INACTIVE',
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
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(String category) {
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
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category == 'fullmeals' ? Icons.restaurant : Icons.fastfood,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${category == 'fullmeals' ? 'full meals' : 'snacks'} available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first ${category == 'fullmeals' ? 'meal' : 'snack'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(KitchenItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          );
                        },
                      )
                    : Icon(Icons.image, color: Colors.grey[400], size: 40),
              ),
            ),
            const SizedBox(width: 12),
            // Item Details
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
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
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

  void _navigateToAddItem() {
    final currentTabIndex = _tabController.index;
    final category = currentTabIndex == 0 ? 'fullmeals' : 'snacks';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          kitchen: widget.kitchen,
          category: category,
          categoryDisplayName: currentTabIndex == 0 ? 'Full Meals' : 'Snacks',
        ),
      ),
    );
  }

  void _editItem(KitchenItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final success = await _vendorService.deleteKitchenItem(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Item deleted successfully'
                            : 'Failed to delete item',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
