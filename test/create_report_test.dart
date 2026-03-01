import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:main10app/ui/reporter/create_report_screen.dart';
import 'package:main10app/services/report_service.dart';
import 'package:main10app/services/auth_service.dart';
import 'package:main10app/services/storage_service.dart';
import 'package:main10app/models/report.dart';
import 'package:main10app/models/user_profile.dart';
import 'package:main10app/models/location.dart';
import 'package:main10app/services/location_service.dart';
import 'package:main10app/services/audit_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Manual Mocks
class MockReportService extends ReportService {
  bool createReportCalled = false;

  @override
  Future<String> createReport(Report report) async {
    createReportCalled = true;
    return 'mock_report_id';
  }
}

class MockAuditService extends AuditService {
  MockAuditService() : super(firestore: null);
  
  bool logActionCalled = false;

  @override
  Future<void> logAction({
    required String reportId,
    required String userId,
    required String userName,
    required String action,
    required String details,
  }) async {
    logActionCalled = true;
  }
}

class MockAuthService extends AuthService {
  @override
  String? get currentUserId => 'test_user_id';

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return UserProfile(
      uid: uid,
      displayName: 'Test User',
      email: 'test@example.com',
      role: 'reporter',
      phoneNumber: '123456789',
    );
  }
}

class MockStorageService extends StorageService {
  @override
  Future<List<String>> uploadFiles(List<XFile> files, String folder) async {
    return files.map((f) => 'https://mock-url.com/${f.path}').toList();
  }
}

class MockLocationService extends LocationService {
  MockLocationService() : super(firestore: null);

  @override
  Stream<List<Location>> getLocations() {
    return Stream.value([
      Location(id: '1', name: 'Test Location', createdAt: DateTime.now()),
    ]);
  }
}

void main() {
  testWidgets('Submitting valid report calls createReport and pops screen', (WidgetTester tester) async {
    // Setup
    final mockReportService = MockReportService();
    final mockAuthService = MockAuthService();
    final mockAuditService = MockAuditService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ReportService>(create: (_) => mockReportService),
          Provider<AuthService>(create: (_) => mockAuthService),
          Provider<StorageService>(create: (_) => MockStorageService()),
          Provider<LocationService>(create: (_) => MockLocationService()),
          Provider<AuditService>(create: (_) => mockAuditService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateReportScreen()),
                      );
                    },
                    child: const Text("Go to Create Report"),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Initial state: Home screen
    expect(find.text("Go to Create Report"), findsOneWidget);
    expect(find.text("Create Report"), findsNothing);

    // Navigate to Create Report
    await tester.tap(find.text("Go to Create Report"));
    await tester.pumpAndSettle();

    // Verify Create Report Screen
    expect(find.text("Create Report"), findsOneWidget);

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Title'); 
    await tester.enterText(find.byType(TextFormField).at(1), 'Test Desc'); 
    
    // Select Location from Dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Location').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), 'Test Name'); 
    await tester.enterText(find.byType(TextFormField).at(3), '123456'); 
    await tester.pump();

    // Ensure button is visible
    final buttonFinder = find.text("Submit Maintenance Report");
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);

    // Tap submit
    await tester.tap(buttonFinder);
    await tester.pump(); // Start async logic
    
    // Pump frames to allow Navigator.pop animation to complete
    await tester.pumpAndSettle();

    // Verify Service Called
    expect(mockReportService.createReportCalled, true);
    expect(mockAuditService.logActionCalled, true);

    // Verify Navigation (Popped back to Home)
    expect(find.text("Create Report"), findsNothing);
    expect(find.text("Go to Create Report"), findsOneWidget);
  });
}
