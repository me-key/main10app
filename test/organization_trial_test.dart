import 'package:flutter_test/flutter_test.dart';
import '../lib/models/organization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Organization Trial Logic Tests', () {
    final now = DateTime.now();

    test('isTrialExpired returns false when trialEndsAt is null (no trial)', () {
      final org = Organization(
        id: 'org1',
        name: 'No Trial Org',
        createdAt: now,
        trialEndsAt: null,
      );
      expect(org.isTrialExpired, false);
      expect(org.trialDaysRemaining, 0);
    });

    test('isTrialExpired returns false when trialEndsAt is in the future', () {
      final futureDate = now.add(const Duration(days: 5));
      final org = Organization(
        id: 'org1',
        name: 'Active Trial Org',
        createdAt: now,
        trialEndsAt: futureDate,
      );
      expect(org.isTrialExpired, false);
      // inDays might be 4 or 5 depending on exact ms, but should be > 0
      expect(org.trialDaysRemaining, greaterThan(0));
    });

    test('isTrialExpired returns true when trialEndsAt is in the past', () {
      final pastDate = now.subtract(const Duration(days: 1));
      final org = Organization(
        id: 'org1',
        name: 'Expired Trial Org',
        createdAt: now,
        trialEndsAt: pastDate,
      );
      expect(org.isTrialExpired, true);
      expect(org.trialDaysRemaining, 0);
    });

    test('trialDaysRemaining returns correct count for future date', () {
      final futureDate = now.add(const Duration(hours: 49)); // ~2 days 1 hour
      final org = Organization(
        id: 'org1',
        name: 'Future Org',
        createdAt: now,
        trialEndsAt: futureDate,
      );
      expect(org.trialDaysRemaining, 2);
    });
  });
}
