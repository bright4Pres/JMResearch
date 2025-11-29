import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/app_user.dart';
import 'home/home_screen.dart';
import 'authenticate/authenticate.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    print(user);
    // will return either home page or authenticate page based on auth status
    return user == null ? Authenticate() : HomeScreen();
  }
}
