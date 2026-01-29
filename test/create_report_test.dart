import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:main10app/ui/reporter/create_report_screen.dart';
import 'package:main10app/services/report_service.dart';
import 'package:main10app/services/auth_service.dart';
import 'package:main10app/models/report.dart';

// Manual Mocks
class MockReportService extends ReportService {
  bool createReportCalled = false;

  @override
  Future<void> createReport(Report report) async {
    createReportCalled = true;
    return Future.value();
  }
}

class MockAuthService extends AuthService {
  @override
  String? get currentUserId => 'test_user_id';
}

void main() {
  testWidgets('Submitting valid report calls createReport and pops screen', (WidgetTester tester) async {
    // Setup
    final mockReportService = MockReportService();
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ReportService>(create: (_) => mockReportService),
          Provider<AuthService>(create: (_) => mockAuthService),
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
    expect(find.text("New Report"), findsNothing);

    // Navigate to Create Report
    await tester.tap(find.text("Go to Create Report"));
    await tester.pumpAndSettle();

    // Verify Create Report Screen
    expect(find.text("New Report"), findsOneWidget);

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Title'); 
    await tester.enterText(find.byType(TextFormField).at(1), 'Test Desc'); 
    await tester.enterText(find.byType(TextFormField).at(2), 'Test Location'); 
    await tester.enterText(find.byType(TextFormField).at(3), 'Test Name'); 
    await tester.enterText(find.byType(TextFormField).at(4), '123456'); 
    await tester.pump();

    // Ensure button is visible
    final buttonFinder = find.text("Submit Report");
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);

    // Tap submit
    await tester.tap(buttonFinder);
    await tester.pump(); // Start async logic
    
    // Pump frames to allow Navigator.pop animation to complete
    await tester.pumpAndSettle();

    // Verify Service Called
    expect(mockReportService.createReportCalled, true);

    // Verify Navigation (Popped back to Home)
    expect(find.text("New Report"), findsNothing);
    expect(find.text("Go to Create Report"), findsOneWidget);
  });
}
