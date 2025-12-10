import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user data including staff status
  Future<AppUser?> getCurrentUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return AppUser.fromMap({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'isStaff': data['isStaff'] ?? false,
        });
      } else {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'isStaff': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return AppUser(
          uid: currentUser.uid,
          email: currentUser.email,
          displayName: currentUser.displayName,
          isStaff: false,
        );
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Stream of current user data
  Stream<AppUser?> get currentUserStream {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return AppUser.fromMap({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'isStaff': data['isStaff'] ?? false,
        });
      }
      return null;
    });
  }

  // Update staff status (for admin use)
  Future<bool> updateStaffStatus(String uid, bool isStaff) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isStaff': isStaff,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating staff status: $e');
      return false;
    }
  }
}
