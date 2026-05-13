
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final Map<String, bool> events;

  NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.events = const {
      'new_report': true,
      'report_assigned': true,
      'report_in_progress': true,
      'report_on_hold': true,
      'report_resolved': true,
      'report_archived': true,
      'report_commented': true,
      'user_pending_approval': true,
      'user_approved': true,
    },
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      pushEnabled: data['pushEnabled'] ?? true,
      emailEnabled: data['emailEnabled'] ?? true,
      events: Map<String, bool>.from(data['events'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'events': events,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    Map<String, bool>? events,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      events: events ?? this.events,
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin', 'manager', 'maintainer', 'reporter'
  final String phoneNumber;
  final String organizationId;
  final bool isApproved;
  final String? fcmToken;
  final NotificationPreferences notificationPreferences;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber = '',
    required this.organizationId,
    this.isApproved = true,
    this.fcmToken,
    NotificationPreferences? notificationPreferences,
  }) : notificationPreferences = notificationPreferences ?? NotificationPreferences();

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'reporter',
      phoneNumber: data['phoneNumber'] ?? '',
      organizationId: data['organizationId'] ?? '',
      isApproved: data['isApproved'] ?? true,
      fcmToken: data['fcmToken'],
      notificationPreferences: data['notificationPreferences'] != null
          ? NotificationPreferences.fromMap(data['notificationPreferences'] as Map<String, dynamic>)
          : null,
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
      'fcmToken': fcmToken,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  UserProfile copyWith({
    String? displayName,
    String? phoneNumber,
    String? role,
    bool? isApproved,
    String? fcmToken,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      organizationId: organizationId,
      isApproved: isApproved ?? this.isApproved,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }
}
