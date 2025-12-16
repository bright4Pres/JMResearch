import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  void _log(String message) => debugPrint('AuthService: $message');

  // wrap helper to turn Firebase's user into our AppUser once they verify
  AppUser? _userFromFirebaseUser(User? user) {
    if (user != null && !user.emailVerified) {
      return null;
    }
    return user != null ? AppUser(uid: user.uid) : null;
  }

  // stream out auth changes so the rest of the app has access to data
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // quick trip to Firestore to see if this user is flagged as staff
  Future<bool> isUserStaff() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // poke the users doc and read the bool
    try {
      final doc = await _userDoc(user.uid).get();
      if (doc.exists) return doc.data()?['isStaff'] as bool? ?? false;
    } catch (e) {
      _log('isUserStaff error: $e');
    }
    return false;
  }

  // plain email+password login with verification
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = result.user;

      // error handling for unverified emails
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before signing in');
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      _log('signInWithEmailAndPassword error: $e');
      return null;
    }
  }

  // spin up a new user with email/pass plus the usual starter metadata
  Future<AppUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    final trimmedEmail = email.trim();
    try {
      _log('Attempting registration for: $trimmedEmail');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      User? user = result.user;
      _log('User created successfully: ${user?.uid}');

      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        _log('Display name updated');

        // Create user document in Firestore with default role
        await _userDoc(user.uid).set({
          'uid': user.uid,
          'email': trimmedEmail,
          'displayName': name,
          'isStaff': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _log('Firestore document created');

        // sends email verification
        await user.sendEmailVerification();
        _log('Verification email sent');

        // signs out so the user verifies email first
        await _auth.signOut();
        _log('User signed out for verification');

        // Return a non-null AppUser to indicate successful registration
        // (even though email is unverified - that's expected for registration)
        return AppUser(uid: user.uid);
      }

      return null;
    } catch (e) {
      _log('Registration error: $e');
      _log('Error details: ${e.runtimeType}');
      return null;
    }
  }

  // let users edit safe profile bits (displayName + email mirror)
  Future<bool?> updateProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // update display name in Firebase Auths
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }

    // Also write a safe profile doc (clients cannot write 'role' per rules)
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      data['email'] = user.email;
      await _userDoc(user.uid).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      _log('updateProfile error: $e');
      return null;
    }
  }

  // sign out
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      _log('signOut error: $e');
      return false;
    }
  }
}
