// ============================================================================
// authenticate.dart - Auth Screen Switcher
// ============================================================================
// this widget toggles between SignIn and Register screens
// uses a simple bool (showSignIn) to swap which screen is displayed
// the toggleView function is passed down to child screens so they can
// trigger the switch (like when you tap "Don't have an account? Register")
// ============================================================================

import 'package:flutter/material.dart';
import 'package:myapp/screens/authenticate/sign_in.dart';
import 'package:myapp/screens/authenticate/register.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  // controls which screen to show
  bool showSignIn = true;

  // this gets passed to SignIn/Register so they can swap screens
  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    // simple conditional - show sign in or register based on bool
    return showSignIn
        ? SignIn(toggleView: toggleView)
        : Register(toggleView: toggleView);
  }
}
