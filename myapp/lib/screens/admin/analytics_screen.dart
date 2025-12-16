// ============================================================================
// analytics_screen.dart - Kitchen Analytics Dashboard
// ============================================================================
// this screen gives kitchen owners/staff a bird's eye view of their business
// shows revenue, order counts, top selling items, and status breakdowns
// uses nested StreamBuilders to listen to both orders AND items in real-time
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';

// app colors - keeping it consistent across the app
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class AnalyticsScreen extends StatelessWidget {
  final Kitchen kitchen;
  final VendorKitchenService _vendorService = VendorKitchenService();

  AnalyticsScreen({super.key, required this.kitchen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${kitchen.name} Analytics',
          style: const TextStyle(
            color: _kAccentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
      ),
      // nested StreamBuilders - first one gets orders, second gets menu items
      // we need both to calculate all our stats
      body: StreamBuilder<List<KitchenOrder>>(
        stream: _vendorService.getOrdersByKitchen(kitchen.id),
        builder: (context, orderSnapshot) {
          return StreamBuilder<List<KitchenItem>>(
            stream: _vendorService.getItemsByKitchen(kitchen.id),
            builder: (context, itemSnapshot) {
              // still loading? show spinner
              if (orderSnapshot.connectionState == ConnectionState.waiting ||
                  itemSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = orderSnapshot.data ?? [];
              final items = itemSnapshot.data ?? [];

              // calculate metrics
              final stats = _calculateStats(orders, items);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // revenue section
                  _buildStatCard(
                    title: 'Revenue',
                    icon: Icons.attach_money,
                    children: [
                      _buildStatRow(
                        'Total Revenue',
                        '₱${stats.totalRevenue.toStringAsFixed(2)}',
                        _kAccentColor,
                      ),
                      _buildStatRow(
                        'Completed Revenue',
                        '₱${stats.finishedRevenue.toStringAsFixed(2)}',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // orders breakdown
                  _buildStatCard(
                    title: 'Orders Overview',
                    icon: Icons.receipt_long,
                    children: [
                      _buildStatRow(
                        'Total Orders',
                        '${stats.totalOrders}',
                        _kAccentColor,
                      ),
                      _buildStatRow(
                        'Pending',
                        '${stats.pendingOrders}',
                        Colors.orange,
                      ),
                      _buildStatRow(
                        'Ready for Pickup',
                        '${stats.readyOrders}',
                        Colors.blue,
                      ),
                      _buildStatRow(
                        'Finished',
                        '${stats.finishedOrders}',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // menu items count
                  _buildStatCard(
                    title: 'Menu Items',
                    icon: Icons.restaurant_menu,
                    children: [
                      _buildStatRow(
                        'Total Items',
                        '${items.length}',
                        _kAccentColor,
                      ),
                      _buildStatRow(
                        'Full Meals',
                        '${stats.fullMealsCount}',
                        Colors.purple,
                      ),
                      _buildStatRow(
                        'Snacks',
                        '${stats.snacksCount}',
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // top sellers
                  _buildStatCard(
                    title: 'Top Sellers',
                    icon: Icons.trending_up,
                    children: stats.topItems.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No sales data yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                        : stats.topItems
                              .take(5) // only show top 5
                              .map(
                                (entry) => _buildStatRow(
                                  entry.key,
                                  '${entry.value} sold',
                                  const Color.fromARGB(255, 44, 44, 44),
                                ),
                              )
                              .toList(),
                  ),
                  const SizedBox(height: 16),

                  // progress bars showing order distribution
                  if (stats.totalOrders > 0) _buildStatusDistribution(stats),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // calculates all the analytics in one place - cleaner than doing it inline
  // returns a record (new Dart 3 feature - like a mini object)
  // --------------------------------------------------------------------------
  _AnalyticsStats _calculateStats(
    List<KitchenOrder> orders,
    List<KitchenItem> items,
  ) {
    final totalOrders = orders.length;

    // count orders by status
    final pendingOrders = orders
        .where((o) => o.status.toLowerCase() == 'pending')
        .length;
    final readyOrders = orders
        .where((o) => o.status.toLowerCase() == 'ready for pick up')
        .length;
    final finishedOrders = orders
        .where((o) => o.status.toLowerCase() == 'finished')
        .length;

    // revenue calculations
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final finishedRevenue = orders
        .where((o) => o.status.toLowerCase() == 'finished')
        .fold<double>(0, (sum, order) => sum + order.total);

    // count menu items by category
    final fullMealsCount = items.where((i) => i.category == 'fullmeals').length;
    final snacksCount = items.where((i) => i.category == 'snacks').length;

    // figure out which items are selling the most
    // loop through all orders and count how many of each item sold
    final itemSales = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        itemSales[item.name] = (itemSales[item.name] ?? 0) + item.qty;
      }
    }
    // sort by sales count (highest first)
    final topItems = itemSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _AnalyticsStats(
      totalOrders: totalOrders,
      pendingOrders: pendingOrders,
      readyOrders: readyOrders,
      finishedOrders: finishedOrders,
      totalRevenue: totalRevenue,
      finishedRevenue: finishedRevenue,
      fullMealsCount: fullMealsCount,
      snacksCount: snacksCount,
      topItems: topItems,
    );
  }

  // --------------------------------------------------------------------------
  // reusable card widget for each stats section
  // --------------------------------------------------------------------------
  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kAccentColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // single row inside a stat card (label on left, value on right)
  // --------------------------------------------------------------------------
  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // visual breakdown of order statuses with progress bars
  // shows what percentage of orders are in each state
  // --------------------------------------------------------------------------
  Widget _buildStatusDistribution(_AnalyticsStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: _kAccentColor),
                SizedBox(width: 10),
                Text(
                  'Order Statuses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildProgressBar(
              'Pending',
              stats.pendingOrders,
              stats.totalOrders,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Ready for Pick Up',
              stats.readyOrders,
              stats.totalOrders,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Finished',
              stats.finishedOrders,
              stats.totalOrders,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // progress bar with label and percentage
  // --------------------------------------------------------------------------
  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[700])),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // LinearProgressIndicator is a built-in widget for progress bars
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// helper class to hold all our calculated stats
// using a class instead of individual variables makes the code cleaner
// --------------------------------------------------------------------------
class _AnalyticsStats {
  final int totalOrders;
  final int pendingOrders;
  final int readyOrders;
  final int finishedOrders;
  final double totalRevenue;
  final double finishedRevenue;
  final int fullMealsCount;
  final int snacksCount;
  final List<MapEntry<String, int>> topItems;

  _AnalyticsStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.readyOrders,
    required this.finishedOrders,
    required this.totalRevenue,
    required this.finishedRevenue,
    required this.fullMealsCount,
    required this.snacksCount,
    required this.topItems,
  });
}
