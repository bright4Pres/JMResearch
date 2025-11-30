class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isStaff; // true for staff, false for regular users

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isStaff = false,
  });

  // convenience factory from map (e.g., Firestore doc)
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      isStaff: data['isStaff'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'isStaff': isStaff,
  };
}
