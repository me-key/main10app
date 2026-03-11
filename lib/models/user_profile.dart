
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin', 'manager', 'maintainer', 'reporter'
  final String phoneNumber;
  final String organizationId;
  final bool isApproved;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber = '',
    required this.organizationId,
    this.isApproved = true,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'reporter',
      phoneNumber: data['phoneNumber'] ?? '',
      organizationId: data['organizationId'] ?? '',
      isApproved: data['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'phoneNumber': phoneNumber,
      'organizationId': organizationId,
      'isApproved': isApproved,
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
