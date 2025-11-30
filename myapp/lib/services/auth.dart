import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Helper to read trusted role from ID token (custom claims)
  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'regular';
    final idToken = await user.getIdTokenResult(true);
    final claims = idToken.claims;
    if (claims != null && claims.containsKey('role')) {
      return claims['role'] as String;
    }
    // fallback: try reading from users collection (read-only)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) return doc.data()?['role'] as String? ?? 'regular';
    } catch (_) {}
    return 'regular';
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

      // Sign out so the user verifies email first (we'll create profile server-side via Cloud Function)
      await _auth.signOut();

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Allow user to update safe profile fields (displayName) in Firestore
  Future updateProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Update Firebase Auth displayName
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }

    // Also write a safe profile doc (clients cannot write 'role' per rules)
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      data['email'] = user.email;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print(e);
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
