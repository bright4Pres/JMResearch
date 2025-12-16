// ============================================================================
// pickup_locations_screen.dart - Customer Pickup Locations Overview
// ============================================================================
// this screen shows customers all available pickup locations organized by
// kitchen/seller. helpful for planning where to pick up their orders.
// each kitchen can set their own custom pickup spots, and this screen
// displays them all in one place.
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/vendor_kitchen_service.dart';

// consistent colors across the app
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class PickupLocationsScreen extends StatelessWidget {
  const PickupLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorService = VendorKitchenService();

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pickup Locations',
          style: TextStyle(color: _kAccentColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
      ),
      body: StreamBuilder<List<Kitchen>>(
        // get all active kitchens
        stream: vendorService.getAllKitchens(),
        builder: (context, snapshot) {
          // loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // error state
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading kitchens: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final kitchens = snapshot.data ?? [];

          // empty state - no kitchens available
          if (kitchens.isEmpty) {
            return _buildEmptyState();
          }

          // filter to only show kitchens that have pickup locations
          final kitchensWithLocations = kitchens
              .where((k) => k.pickupLocations.isNotEmpty)
              .toList();

          if (kitchensWithLocations.isEmpty) {
            return _buildNoLocationsState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kitchensWithLocations.length,
            itemBuilder: (context, index) {
              return _buildKitchenCard(kitchensWithLocations[index]);
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // empty state when no kitchens exist
  // --------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No kitchens available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for available pickup locations',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // state when kitchens exist but none have pickup locations set
  // --------------------------------------------------------------------------
  Widget _buildNoLocationsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pickup locations set yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sellers haven\'t configured their pickup spots.\n'
              'Default locations will be shown during checkout.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // card showing a kitchen and all its pickup locations
  // --------------------------------------------------------------------------
  Widget _buildKitchenCard(Kitchen kitchen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // kitchen header row
            Row(
              children: [
                // kitchen icon
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
                // kitchen name and description
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
                      const SizedBox(height: 2),
                      Text(
                        kitchen.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // open/closed badge
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
            const Divider(),
            const SizedBox(height: 8),

            // pickup locations label
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Pickup Locations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // list of pickup locations as chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kitchen.pickupLocations.map((location) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _kAccentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, size: 16, color: _kAccentColor),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kAccentColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
