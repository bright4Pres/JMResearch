// ============================================================================
// wrapper.dart - Auth State Router
// ============================================================================
// this is the top-level widget that decides what screen to show based on
// whether the user is logged in or not. it uses Provider to listen for
// auth state changes - when user logs in/out, this automatically rebuilds
// and shows the appropriate screen. pretty neat!
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/app_user.dart';
import 'home/home_screen.dart';
import 'authenticate/authenticate.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Provider.of listens to auth state changes from main.dart
    // when user is null = not logged in, when user exists = logged in
    final user = Provider.of<AppUser?>(context);

    // simple conditional: no user? show auth screen. has user? show home.
    // this is how flutter handles "protected routes" basically
    return user == null ? Authenticate() : HomeScreen();
  }
}
