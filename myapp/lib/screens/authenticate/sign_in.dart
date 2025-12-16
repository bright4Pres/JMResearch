// ============================================================================
// sign_in.dart - User Sign In Screen
// ============================================================================
// login form with email/password fields. handles validation, shows loading
// state while auth is happening, displays errors if login fails.
// toggleView callback lets user switch to Register screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:myapp/services/auth.dart';

// keep colors consistent with the rest of the app
const _kBackgroundColor = Color.fromARGB(255, 255, 236, 191);
const _kAccentColor = Colors.deepOrange;

class SignIn extends StatefulWidget {
  // callback to switch to register screen
  final Function toggleView;

  const SignIn({super.key, required this.toggleView});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  // auth service handles firebase auth calls
  final AuthService _auth = AuthService();

  // form key for validation - you need this to call validate()
  final _formKey = GlobalKey<FormState>();

  // form state - using setState to track these
  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // app branding
              _buildHeader(),
              const SizedBox(height: 40),
              // login form card
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // app logo and tagline
  // --------------------------------------------------------------------------
  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Iskaon',
          style: TextStyle(
            color: _kAccentColor,
            fontFamily: 'Roboto',
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Order now, pick up later',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 125, 116, 38),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // white card containing the login form
  // --------------------------------------------------------------------------
  Widget _buildFormCard() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey, // required for form validation to work
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _kAccentColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // email field
            _buildEmailField(),
            const SizedBox(height: 20),

            // password field
            _buildPasswordField(),
            const SizedBox(height: 30),

            // submit button
            _buildSignInButton(),
            const SizedBox(height: 12),

            // error message (if any)
            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            // link to register
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // email text field with validation
  // --------------------------------------------------------------------------
  Widget _buildEmailField() {
    return TextFormField(
      decoration: _inputDecoration('Email', Icons.email),
      keyboardType: TextInputType.emailAddress,
      // validator runs when form.validate() is called
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter an email';
        // basic email regex - checks for something@something.something
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
          return 'Enter a valid email';
        }
        return null; // null means valid
      },
      onChanged: (val) => setState(() => email = val),
    );
  }

  // --------------------------------------------------------------------------
  // password field with validation
  // --------------------------------------------------------------------------
  Widget _buildPasswordField() {
    return TextFormField(
      decoration: _inputDecoration('Password', Icons.lock),
      obscureText: true, // hides the password
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter a password';
        if (val.length < 6) return 'Password must be 6+ characters';
        return null;
      },
      onChanged: (val) => setState(() => password = val),
    );
  }

  // --------------------------------------------------------------------------
  // reusable input decoration - keeps fields looking consistent
  // --------------------------------------------------------------------------
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kAccentColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccentColor, width: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // sign in button - shows spinner while loading
  // --------------------------------------------------------------------------
  Widget _buildSignInButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kAccentColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // disable button while loading to prevent double-taps
      onPressed: loading ? null : _handleSignIn,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  // --------------------------------------------------------------------------
  // handles the sign in logic
  // --------------------------------------------------------------------------
  Future<void> _handleSignIn() async {
    // validate returns true if all validators pass
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = '';
    });

    // try to sign in with firebase
    final result = await _auth.signInWithEmailAndPassword(email, password);

    if (result == null) {
      // sign in failed
      setState(() {
        error =
            'Could not sign in. Please verify your email or check your credentials.';
        loading = false;
      });
    }
    // if result != null, sign in succeeded and the wrapper will auto-navigate to home
  }

  // --------------------------------------------------------------------------
  // link to register screen
  // --------------------------------------------------------------------------
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey[700]),
        ),
        GestureDetector(
          onTap: () => widget.toggleView(),
          child: const Text(
            'Register',
            style: TextStyle(color: _kAccentColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
