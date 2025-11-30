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

  // Helper to check if user is staff from Firestore users collection
  Future<bool> isUserStaff() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Read from users collection directly
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) return doc.data()?['isStaff'] as bool? ?? false;
    } catch (_) {}
    return false;
  } // sign in with email and password

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
      print('Attempting registration for: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? user = result.user;
      print('User created successfully: ${user?.uid}');

      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        print('Display name updated');

        // Create user document in Firestore with default role
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'isStaff': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Firestore document created');

        // Send email verification
        await user.sendEmailVerification();
        print('Verification email sent');

        // Sign out so the user verifies email first
        await _auth.signOut();
        print('User signed out for verification');
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Registration error: ${e.toString()}');
      print('Error details: ${e.runtimeType}');
      return null;
    }
  } // Allow user to update safe profile fields (displayName) in Firestore

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
