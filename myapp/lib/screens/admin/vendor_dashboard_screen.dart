import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';
import '../../services/user_service.dart';
import 'create_kitchen_screen.dart';
import 'kitchen_detail_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final VendorKitchenService _vendorService = VendorKitchenService();
  final UserService _userService = UserService();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final user = await _userService.getCurrentUserData();
    setState(() {
      currentUserId = user?.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 236, 191),
      appBar: AppBar(
        title: const Text(
          'My Vendor Dashboard',
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
      ),
      body: StreamBuilder<List<Kitchen>>(
        stream: _vendorService.getKitchensByOwner(currentUserId!),
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

          final kitchens = snapshot.data ?? [];

          if (kitchens.isEmpty) {
            return _buildEmptyState();
          }

          return _buildKitchensList(kitchens);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewKitchen,
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('new kitchen', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 120, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'staff mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'no kitchens yet on record. \n click plus buytton to create kitchen',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewKitchen,
              icon: const Icon(Icons.add_business),
              label: const Text('create my first kitchebn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchensList(List<Kitchen> kitchens) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: kitchens.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(kitchens.length);
        }

        final kitchen = kitchens[index - 1];
        return _buildKitchenCard(kitchen);
      },
    );
  }

  Widget _buildHeader(int kitchenCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Icon(Icons.restaurant_menu, size: 48, color: Colors.deepOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Kitchens',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$kitchenCount ${kitchenCount == 1 ? 'kitchen' : 'kitchens'} active',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'VENDOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenCard(Kitchen kitchen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openKitchenDetail(kitchen),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  child: kitchen.imageUrl != null
                      ? Image.network(
                          kitchen.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 40,
                            );
                          },
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Kitchen Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kitchen.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kitchen.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: kitchen.isActive ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          kitchen.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: kitchen.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Button
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
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
}
