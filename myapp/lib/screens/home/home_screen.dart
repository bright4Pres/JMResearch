// ============================================================================
// home_screen.dart - Main Home Screen
// ============================================================================
// this is the main screen users see after logging in. it does double duty:
// - for regular customers: shows list of kitchens to order from
// - for staff members: shows the VendorDashboardScreen instead
//
// uses StreamBuilder to listen for changes in real-time (when a kitchen
// updates their menu or status, it shows up instantly here)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/models/app_user.dart';
import '../../services/vendor_kitchen_service.dart';
import 'kitchen_menu_screen.dart';
import 'orders_screen.dart';
import 'pickup_locations_screen.dart';
import 'edit_profile_screen.dart';
import '../admin/vendor_dashboard_screen.dart';

// app-wide constants - keeps things consistent
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  final AuthService _auth = AuthService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // firebase user for display name/email
  User? currentUser;
  // our services
  final UserService _userService = UserService();
  final VendorKitchenService _vendorService = VendorKitchenService();

  @override
  void initState() {
    super.initState();
    // grab current user from firebase auth
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to user changes (like staff status updates)
    return StreamBuilder<AppUser?>(
      stream: _userService.currentUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;

        return Scaffold(
          backgroundColor: _kBackgroundColor,
          appBar: _buildAppBar(appUser),
          drawer: _buildDrawer(appUser),
          // staff sees VendorDashboard, customers see kitchen list
          body: appUser?.isStaff == true
              ? const VendorDashboardScreen()
              : _buildCustomerView(appUser),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // AppBar with profile pic, app name, and notification icon
  // --------------------------------------------------------------------------
  AppBar _buildAppBar(AppUser? appUser) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      // profile picture opens drawer
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile.jpg'),
              radius: 20,
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Iskaon',
            style: TextStyle(
              color: _kAccentColor,
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // show different subtitle for staff vs customers
          Text(
            appUser?.isStaff == true
                ? 'Staff Mode - Manage Kitchen'
                : 'Order now, pick up later',
            style: TextStyle(
              fontSize: 14,
              color: appUser?.isStaff == true
                  ? Colors.deepOrange[700]
                  : const Color.fromARGB(255, 125, 116, 38),
              fontWeight: appUser?.isStaff == true
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          color: Colors.blueGrey,
          onPressed: () {
            // TODO: implement notifications
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // navigation drawer - profile info at top, menu items below
  // --------------------------------------------------------------------------
  Widget _buildDrawer(AppUser? appUser) {
    return Drawer(
      child: Column(
        children: [
          // header with user info
          _buildDrawerHeader(appUser),
          // menu items
          Expanded(
            child: Container(
              color: Colors.orange[50],
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'Order History',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.location_on_outlined,
                    title: 'Pickup Locations',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PickupLocationsScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.orange[200], thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => Navigator.pop(context),
                  ),
                  Divider(color: Colors.orange[200], thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    textColor: Colors.red[700],
                    onTap: () {
                      Navigator.pop(context);
                      _showSignOutDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // drawer header with profile pic, name, email, and staff badge
  // --------------------------------------------------------------------------
  Widget _buildDrawerHeader(AppUser? appUser) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.20,
      width: double.infinity,
      color: _kAccentColor,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage('assets/images/profile.jpg'),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentUser?.email ?? 'No email',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // staff badge
                  if (appUser?.isStaff == true)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'STAFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // reusable drawer menu item
  // --------------------------------------------------------------------------
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.deepOrange[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.orange[100],
    );
  }

  // --------------------------------------------------------------------------
  // sign out confirmation dialog
  // --------------------------------------------------------------------------
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // save references before async gap (widget might unmount)
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              final didSignOut = await widget._auth.signOut();
              navigator.pop();

              if (!didSignOut) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to sign out. Please try again.'),
                  ),
                );
              }
            },
            child: Text('Sign Out', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // customer view - shows orders shortcut + list of kitchens
  // --------------------------------------------------------------------------
  Widget _buildCustomerView(AppUser? appUser) {
    return StreamBuilder<List<Kitchen>>(
      // getAllKitchens returns a stream that updates when kitchens change
      stream: _vendorService.getAllKitchens(),
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading kitchens: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final kitchens = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // orders shortcut at the top
            _buildOrdersShortcut(),
            const SizedBox(height: 16),
            // show empty state or kitchen list
            if (kitchens.isEmpty)
              _buildEmptyKitchensState()
            else
              ...kitchens.map((k) => _buildKitchenCard(k)),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // orders shortcut card - tapping goes to orders screen
  // --------------------------------------------------------------------------
  Widget _buildOrdersShortcut() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: _kAccentColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kAccentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View pending and past orders',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _kAccentColor),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // empty state when no kitchens exist
  // --------------------------------------------------------------------------
  Widget _buildEmptyKitchensState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No kitchens available yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // kitchen card - shows name, description, open/closed status
  // tapping opens KitchenMenuScreen to browse & order
  // --------------------------------------------------------------------------
  Widget _buildKitchenCard(Kitchen kitchen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => KitchenMenuScreen(
                kitchen: kitchen,
                initialCategory: 'snacks',
              ),
            ),
          );
        },
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // kitchen icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: _kAccentColor),
                    ),
                    const SizedBox(width: 12),
                    // name + description
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
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
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
                // category chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKitchenChip(
                      icon: Icons.restaurant,
                      label: 'Full Meals',
                    ),
                    _buildKitchenChip(icon: Icons.fastfood, label: 'Snacks'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // small chip showing category (Full Meals / Snacks)
  // --------------------------------------------------------------------------
  Widget _buildKitchenChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _kAccentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kAccentColor,
            ),
          ),
        ],
      ),
    );
  }
}
