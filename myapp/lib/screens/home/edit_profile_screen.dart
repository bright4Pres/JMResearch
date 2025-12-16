// ============================================================================
// edit_profile_screen.dart - User Profile Editor
// ============================================================================
// allows users to update their profile information including:
// - display name (updates Firebase Auth + Firestore)
// - email address (requires re-authentication for security)
// - password (requires re-authentication for security)
//
// uses Firebase Auth's updateDisplayName, updateEmail, updatePassword methods
// re-authentication is required for sensitive operations like email/password
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth.dart';

// consistent colors across the app
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // grab current firebase user for pre-filling fields
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  // form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // loading state for async operations
  bool _isLoading = false;

  // track if fields have changed (to enable/disable save buttons)
  bool _nameChanged = false;
  bool _emailChanged = false;

  @override
  void initState() {
    super.initState();
    // pre-fill fields with current user data
    _nameController.text = _currentUser?.displayName ?? '';
    _emailController.text = _currentUser?.email ?? '';

    // listen for changes to enable save buttons
    _nameController.addListener(_checkNameChanged);
    _emailController.addListener(_checkEmailChanged);
  }

  void _checkNameChanged() {
    final changed =
        _nameController.text.trim() != (_currentUser?.displayName ?? '');
    if (changed != _nameChanged) {
      setState(() => _nameChanged = changed);
    }
  }

  void _checkEmailChanged() {
    final changed = _emailController.text.trim() != (_currentUser?.email ?? '');
    if (changed != _emailChanged) {
      setState(() => _emailChanged = changed);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: _kAccentColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _kAccentColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // profile picture section (placeholder for now)
            _buildProfilePictureSection(),
            const SizedBox(height: 24),

            // name section
            _buildSectionCard(
              title: 'Display Name',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter your display name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _nameChanged
                            ? _kAccentColor
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _nameChanged && !_isLoading
                          ? _updateName
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Update Name',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // email section
            _buildSectionCard(
              title: 'Email Address',
              icon: Icons.email_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      hintText: 'Enter your email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Changing email requires re-authentication',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emailChanged
                            ? _kAccentColor
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _emailChanged && !_isLoading
                          ? () => _showReauthDialog('email')
                          : null,
                      child: const Text(
                        'Update Email',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // password section
            _buildSectionCard(
              title: 'Change Password',
              icon: Icons.lock_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                      hintText: 'Enter new password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                      hintText: 'Confirm your new password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Password must be at least 6 characters',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _showReauthDialog('password'),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(color: Colors.white),
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
  // profile picture section with placeholder avatar
  // --------------------------------------------------------------------------
  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/profile.jpg'),
              ),
              // edit badge (placeholder - not functional yet)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: _kAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentUser?.displayName ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentUser?.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // reusable section card with title and icon
  // --------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // section header
            Row(
              children: [
                Icon(icon, color: _kAccentColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // update display name - doesn't require re-authentication
  // --------------------------------------------------------------------------
  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Name cannot be empty', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // update in Firebase Auth
      await _currentUser?.updateDisplayName(newName);
      // also update in Firestore via AuthService
      await _authService.updateProfile(displayName: newName);
      // reload user to reflect changes
      await _currentUser?.reload();

      if (mounted) {
        _showSnackBar('Name updated successfully!', true);
        setState(() => _nameChanged = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update name: $e', false);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------------------
  // shows re-authentication dialog before any important changes
  // firebase requires re-auth for email/password changes
  // --------------------------------------------------------------------------
  void _showReauthDialog(String operation) {
    _currentPasswordController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For security, please enter your current password to $operation.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccentColor),
            onPressed: () {
              Navigator.pop(ctx);
              if (operation == 'email') {
                _updateEmail();
              } else {
                _updatePassword();
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // re-authenticate user with their current password
  // returns true if successful, false if no
  // --------------------------------------------------------------------------
  Future<bool> _reauthenticate() async {
    final password = _currentPasswordController.text;
    if (password.isEmpty) {
      _showSnackBar('Please enter your current password', false);
      return false;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: _currentUser?.email ?? '',
        password: password,
      );
      await _currentUser?.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Re-authentication failed: ${e.message}', false);
      return false;
    } catch (e) {
      _showSnackBar('Re-authentication failed: $e', false);
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // update email address ,, requires re-authentication
  // --------------------------------------------------------------------------
  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      _showSnackBar('Email cannot be empty', false);
      return;
    }

    // basic email validation
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _showSnackBar('Please enter a valid email address', false);
      return;
    }

    setState(() => _isLoading = true);

    // first re-authenticate
    final reauthSuccess = await _reauthenticate();
    if (!reauthSuccess) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // update email - this may send a verification email
      await _currentUser?.verifyBeforeUpdateEmail(newEmail);

      if (mounted) {
        _showSnackBar(
          'Verification email sent to $newEmail. Please verify to complete the change.',
          true,
        );
        // reset to current email since change isn't complete yet
        _emailController.text = _currentUser?.email ?? '';
        setState(() => _emailChanged = false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update email: ${e.message}', false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update email: $e', false);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------------------
  // update password - requires re-authentication
  // --------------------------------------------------------------------------
  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // validate passwords
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password', false);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', false);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Passwords do not match', false);
      return;
    }

    setState(() => _isLoading = true);

    // first re-authenticate
    final reauthSuccess = await _reauthenticate();
    if (!reauthSuccess) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _currentUser?.updatePassword(newPassword);

      if (mounted) {
        _showSnackBar('Password updated successfully!', true);
        // clear password fields
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _currentPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update password: ${e.message}', false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update password: $e', false);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------------------
  // helper to show feedback snackbar
  // --------------------------------------------------------------------------
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }
}
