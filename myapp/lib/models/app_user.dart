class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String role; // chooses between regular or staff

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.role = 'regular',
  });

  // convenience factory from map (e.g., Firestore doc)
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: data['role'] as String? ?? 'regular',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role,
  };
}
