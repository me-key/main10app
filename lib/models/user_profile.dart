
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin', 'manager', 'maintainer', 'reporter'
  final String phoneNumber;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber = '',
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'reporter',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
