import 'package:flutter/material.dart';
import 'package:myapp/services/vendor_kitchen_service.dart';
import 'kitchen_menu_screen.dart';

class MealScreen extends StatelessWidget {
  MealScreen({super.key});

  final VendorKitchenService _vendorService = VendorKitchenService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Full Meals',
          style: TextStyle(color: Colors.deepOrange),
        ),
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
      ),
      body: StreamBuilder<List<Kitchen>>(
        stream: _vendorService.getAllKitchens(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading kitchens: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final kitchens = snapshot.data ?? [];

          if (kitchens.isEmpty) {
            return _emptyState('No kitchens offering meals yet.');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kitchens.length,
            itemBuilder: (context, index) {
              final kitchen = kitchens[index];
              return _KitchenMealCard(kitchen: kitchen);
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 72, color: Colors.grey),
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
}

class _KitchenMealCard extends StatelessWidget {
  const _KitchenMealCard({required this.kitchen});

  final Kitchen kitchen;

  @override
  Widget build(BuildContext context) {
    final vendorService = VendorKitchenService();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KitchenMenuScreen(
              kitchen: kitchen,
              initialCategory: 'fullmeals',
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          kitchen.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kitchen.description,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kitchen.isActive
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      kitchen.isActive ? 'OPEN' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kitchen.isActive
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<KitchenItem>>(
                stream: vendorService.getItemsByKitchenAndCategory(
                  kitchen.id,
                  'fullmeals',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator(minHeight: 2);
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Text(
                      'No full meals yet.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    );
                  }

                  final preview = items.take(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Meals',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...preview.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₱${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (items.length > preview.length)
                        Text(
                          '+ ${items.length - preview.length} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
