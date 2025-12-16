import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/app_user.dart';
import 'package:myapp/services/auth.dart';
import 'package:myapp/theme/app_theme.dart';
import 'screens/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<AppUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        title: 'Iskaon',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Wrapper(),
      ),
    );
  }
}
