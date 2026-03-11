import 'package:flutter_test/flutter_test.dart';
import '../lib/models/user_profile.dart';

void main() {
  group('UserProfile Approval Tests', () {
    test('UserProfile defaults isApproved to true for backward compatibility', () {
      final profile = UserProfile(
        uid: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        role: 'reporter',
        organizationId: 'org1',
      );
      expect(profile.isApproved, true);
    });

    test('UserProfile.fromMap handles isApproved field', () {
      final data = {
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'reporter',
        'organizationId': 'org1',
        'isApproved': false,
      };
      final profile = UserProfile.fromMap('123', data);
      expect(profile.isApproved, false);
    });

    test('UserProfile.toMap includes isApproved field', () {
      final profile = UserProfile(
        uid: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        role: 'reporter',
        organizationId: 'org1',
        isApproved: false,
      );
      final map = profile.toMap();
      expect(map['isApproved'], false);
    });
  });
}
