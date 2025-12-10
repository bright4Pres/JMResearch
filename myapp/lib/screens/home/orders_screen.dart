import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';

class OrdersScreen extends StatelessWidget {
  OrdersScreen({super.key});

  final VendorKitchenService _vendorService = VendorKitchenService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 236, 191),
      appBar: AppBar(
        title: const Text('Orders', style: TextStyle(color: Colors.deepOrange)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
      ),
      body: userId.isEmpty
          ? _buildSignedOutState(context)
          : _buildOrdersStream(userId),
    );
  }

  Widget _buildSignedOutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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

  Widget _buildOrdersStream(String userId) {
    return StreamBuilder<List<KitchenOrder>>(
      stream: _vendorService.getOrdersForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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

        final orders = snapshot.data ?? [];
        final pending = orders
            .where((o) => (o.status).toLowerCase() == 'pending')
            .toList();
        final history = orders
            .where((o) => (o.status).toLowerCase() != 'pending')
            .toList();

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No orders yet. Place something to see it here.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Pending', pending, empty: 'No pending orders.'),
            const SizedBox(height: 16),
            _buildSection('History', history, empty: 'No past orders yet.'),
          ],
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<KitchenOrder> items, {
    required String empty,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  title == 'Pending' ? Icons.timelapse : Icons.history,
                  color: Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                empty,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              ...items.map(_buildOrderTile),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(KitchenOrder order) {
    final status = order.status.isEmpty
        ? 'PENDING'
        : order.status.toUpperCase();
    final statusBg = order.status.toLowerCase() == 'pending'
        ? Colors.orange[200]
        : Colors.green[200];
    final statusFg = order.status.toLowerCase() == 'pending'
        ? Colors.orange[900]
        : Colors.green[900];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    return '${date.month}/${date.day} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
