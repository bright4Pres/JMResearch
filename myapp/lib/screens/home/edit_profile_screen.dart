// ============================================================================
// edit_profile_screen.dart - User Profile Editor (REDESIGNED)
// ============================================================================
// Beautiful profile editor with modern cards, animations, and consistent theming
// Features: avatar section, name/email/password update sections
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _nameChanged = false;
  bool _emailChanged = false;
  bool _showPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController.text = _currentUser?.displayName ?? '';
    _emailController.text = _currentUser?.email ?? '';

    _nameController.addListener(_checkNameChanged);
    _emailController.addListener(_checkEmailChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _checkNameChanged() {
    final changed =
        _nameController.text.trim() != (_currentUser?.displayName ?? '');
    if (changed != _nameChanged) setState(() => _nameChanged = changed);
  }

  void _checkEmailChanged() {
    final changed = _emailController.text.trim() != (_currentUser?.email ?? '');
    if (changed != _emailChanged) setState(() => _emailChanged = changed);
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // gradient header
          SliverAppBar(
            expandedHeight: 220,
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.warmGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // avatar with edit button
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.large,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/profile.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.small,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _currentUser?.displayName ?? 'User',
                        style: AppTypography.h3.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // name section
                      _buildSection(
                        icon: Icons.person_outline,
                        title: 'Display Name',
                        description: 'This is how you\'ll appear to others',
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: AppDecorations.inputDecoration(
                                label: 'Name',
                                hint: 'Enter your display name',
                                prefixIcon: Icons.badge_outlined,
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildActionButton(
                              label: 'Update Name',
                              icon: Icons.save_outlined,
                              isEnabled: _nameChanged && !_isLoading,
                              onPressed: _updateName,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // email section
                      _buildSection(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        description:
                            'Changing email requires re-authentication',
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: AppDecorations.inputDecoration(
                                label: 'Email',
                                hint: 'Enter your email address',
                                prefixIcon: Icons.alternate_email,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildActionButton(
                              label: 'Update Email',
                              icon: Icons.mail_outline,
                              isEnabled: _emailChanged && !_isLoading,
                              onPressed: () => _showReauthDialog('email'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // password section
                      _buildSection(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        description: 'Password must be at least 6 characters',
                        child: Column(
                          children: [
                            TextField(
                              controller: _newPasswordController,
                              decoration:
                                  AppDecorations.inputDecoration(
                                    label: 'New Password',
                                    hint: 'Enter new password',
                                    prefixIcon: Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showNewPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.textHint,
                                      ),
                                      onPressed: () => setState(
                                        () => _showNewPassword =
                                            !_showNewPassword,
                                      ),
                                    ),
                                  ),
                              obscureText: !_showNewPassword,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _confirmPasswordController,
                              decoration:
                                  AppDecorations.inputDecoration(
                                    label: 'Confirm Password',
                                    hint: 'Confirm your new password',
                                    prefixIcon: Icons.lock_reset,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.textHint,
                                      ),
                                      onPressed: () => setState(
                                        () => _showConfirmPassword =
                                            !_showConfirmPassword,
                                      ),
                                    ),
                                  ),
                              obscureText: !_showConfirmPassword,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildActionButton(
                              label: 'Change Password',
                              icon: Icons.key,
                              isEnabled: !_isLoading,
                              onPressed: () => _showReauthDialog('password'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Section Card
  // --------------------------------------------------------------------------
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      decoration: AppDecorations.cardElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: AppRadius.mediumRadius,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.h4),
                      Text(description, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // content
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Action Button
  // --------------------------------------------------------------------------
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          style: isEnabled
              ? AppButtons.primary
              : AppButtons.secondary.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    AppColors.surfaceVariant,
                  ),
                ),
          onPressed: isEnabled ? onPressed : null,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Update Name
  // --------------------------------------------------------------------------
  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Name cannot be empty', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _currentUser?.updateDisplayName(newName);
      await _authService.updateProfile(displayName: newName);
      await _currentUser?.reload();

      if (mounted) {
        _showSnackBar('Name updated successfully!', true);
        setState(() => _nameChanged = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to update name: $e', false);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --------------------------------------------------------------------------
  // Re-authentication Dialog
  // --------------------------------------------------------------------------
  void _showReauthDialog(String operation) {
    _currentPasswordController.clear();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Re-authenticate', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'For security, please enter your current password to ${operation == 'email' ? 'change email' : 'change password'}.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _currentPasswordController,
                decoration:
                    AppDecorations.inputDecoration(
                      label: 'Current Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textHint,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                obscureText: !_showPassword,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: AppButtons.secondary,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      style: AppButtons.primary,
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (operation == 'email') {
                          _updateEmail();
                        } else {
                          _updatePassword();
                        }
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Re-authenticate User
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
  // Update Email
  // --------------------------------------------------------------------------
  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      _showSnackBar('Email cannot be empty', false);
      return;
    }

    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _showSnackBar('Please enter a valid email address', false);
      return;
    }

    setState(() => _isLoading = true);

    final reauthSuccess = await _reauthenticate();
    if (!reauthSuccess) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _currentUser?.verifyBeforeUpdateEmail(newEmail);

      if (mounted) {
        _showSnackBar(
          'Verification email sent to $newEmail. Please verify to complete the change.',
          true,
        );
        _emailController.text = _currentUser?.email ?? '';
        setState(() => _emailChanged = false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnackBar('Failed to update email: ${e.message}', false);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to update email: $e', false);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --------------------------------------------------------------------------
  // Update Password
  // --------------------------------------------------------------------------
  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

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

    final reauthSuccess = await _reauthenticate();
    if (!reauthSuccess) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _currentUser?.updatePassword(newPassword);

      if (mounted) {
        _showSnackBar('Password updated successfully!', true);
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _currentPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted)
        _showSnackBar('Failed to update password: ${e.message}', false);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to update password: $e', false);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --------------------------------------------------------------------------
  // Show Snackbar
  // --------------------------------------------------------------------------
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }
}
