import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal_screen.dart';
import 'package:myapp/services/auth.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/models/app_user.dart';
import '../admin/vendor_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  final AuthService _auth = AuthService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userService.currentUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 236, 191),
          appBar: AppBar(
            toolbarHeight: 70,
            backgroundColor: Colors.white,
            leading: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                    radius: 20,
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Iskaon',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                onPressed: () {},
              ),
            ],
          ),
          drawer: _buildDrawer(appUser),
          body: appUser?.isStaff == true
              ? _buildStaffView()
              : _buildCustomerView(),
        );
      },
    );
  }

  // build drawer rows
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

  // sign out modal
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
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
        );
      },
    );
  }

  Widget _buildDrawer(AppUser? appUser) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.20,
            width: double.infinity,
            color: Colors.deepOrange,
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentUser?.email ?? 'No email',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                            child: Text(
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
          ),
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
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'Order History',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.location_on_outlined,
                    title: 'Pickup Locations',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  if (appUser?.isStaff == true) ...[
                    Divider(color: Colors.orange[200], thickness: 1),
                    _buildDrawerItem(
                      icon: Icons.store_outlined,
                      title: 'Vendor Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VendorDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  Divider(color: Colors.orange[200], thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Divider(color: Colors.orange[200], thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    textColor: Colors.red[700],
                    onTap: () {
                      Navigator.pop(context);
                      _showSignOutDialog(context);
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

  Widget _buildStaffView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.store, size: 80, color: Colors.deepOrange),
                  const SizedBox(height: 16),
                  Text(
                    'VENDOR DASHBOAORD',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'create and manage kitchen and food items.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.store),
                    label: const Text('Open Dashboard'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerView() {
    return Center(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MealScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(330, 180),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage('assets/images/Meals.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                width: 330,
                height: 180,
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 100,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 35),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Campus Canteen",
                          style: TextStyle(color: Colors.black, fontSize: 10.0),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 20,
                      child: SizedBox(
                        width: 200,
                        height: 35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Full Meals",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "Red Plate x Silver Plate x No Queue!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(),
                minimumSize: const Size(330, 180),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage('assets/images/Snacks.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                width: 330,
                height: 180,
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 100,
                        height: 25,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 35),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Campus Vendors",
                          style: TextStyle(color: Colors.black, fontSize: 10.0),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 20,
                      child: SizedBox(
                        width: 200,
                        height: 35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Snacks & Treats",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "Judy's x Lopez's x KD's Churro's!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.deepOrange),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Note: Item management is now handled through vendor dashboard
  void _navigateToVendorDashboard() {
    Navigator.pushNamed(context, '/vendor_dashboard');
  }
}
