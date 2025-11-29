import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // creates new user OBJECT from firebase
  AppUser? _userFromFirebaseUser(User? user) {
    if (user != null && !user.emailVerified) {
      return null;
    }
    return user != null ? AppUser(uid: user.uid) : null;
  }

  // on auth change
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? user = result.user;

      // checks if email is verified in firebase
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before signing in');
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email and password
  Future registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? user = result.user;

      // updates display name in home screen drawer
      await user?.updateDisplayName(name);

      // email verifier sender
      await user?.sendEmailVerification();

      // idk what this is for
      await _auth.signOut();

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
