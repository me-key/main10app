import 'package:flutter_test/flutter_test.dart';
import 'package:main10app/services/auth_service.dart';
import 'package:main10app/models/user_profile.dart';

void main() {
  group('AuthService Impersonation Tests', () {
    late AuthService authService;
    late UserProfile testProfile;

    setUp(() {
      authService = AuthService();
      testProfile = UserProfile(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        role: 'reporter',
      );
    });

    test('loginAs sets impersonatedProfile and notifies listeners', () async {
      UserProfile? emittedProfile;
      authService.impersonationChanges.listen((profile) {
        emittedProfile = profile;
      });

      authService.loginAs(testProfile);
      
      expect(authService.impersonatedProfile, testProfile);
      // Wait for stream emission
      await Future.delayed(Duration.zero);
      expect(emittedProfile, testProfile);
    });

    test('stopImpersonating clears impersonatedProfile and notifies listeners', () async {
      authService.loginAs(testProfile);
      
      UserProfile? emittedProfile = testProfile;
      authService.impersonationChanges.listen((profile) {
        emittedProfile = profile;
      });

      authService.stopImpersonating();
      
      expect(authService.impersonatedProfile, isNull);
      await Future.delayed(Duration.zero);
      expect(emittedProfile, isNull);
    });
  });
}
