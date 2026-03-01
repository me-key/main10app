import 'package:flutter_test/flutter_test.dart';
import 'package:main10app/models/report.dart';

void main() {
  group('Report Model Tests', () {
    final now = DateTime.now();
    final testReport = Report(
      id: 'test_id',
      title: 'Test Title',
      description: 'Test Description',
      reporterName: 'Test Reporter',
      reporterPhone: '123456789',
      location: 'Test Location',
      status: 'in_progress',
      reporterId: 'reporter_id',
      createdAt: now,
      updatedAt: now,
      reportDateTime: now,
      organizationId: 'org_id',
    );

    test('copyWith updates onHoldReason', () {
      final updatedReport = testReport.copyWith(
        status: 'on_hold',
        onHoldReason: 'Waiting for parts',
      );

      expect(updatedReport.status, 'on_hold');
      expect(updatedReport.onHoldReason, 'Waiting for parts');
      expect(updatedReport.title, testReport.title);
    });

    test('toMap includes onHoldReason', () {
      final reportWithHold = testReport.copyWith(
        status: 'on_hold',
        onHoldReason: 'Blocked',
      );
      final map = reportWithHold.toMap();

      expect(map['status'], 'on_hold');
      expect(map['onHoldReason'], 'Blocked');
    });
  });
}
