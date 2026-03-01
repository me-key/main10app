import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:main10app/ui/manager/manager_home.dart';
import 'package:main10app/services/report_service.dart';
import 'package:main10app/services/auth_service.dart';
import 'package:main10app/services/user_service.dart';
import 'package:main10app/models/report.dart';
import 'package:main10app/models/user_profile.dart';
import 'package:main10app/providers/theme_provider.dart';

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;
  @override
  bool get isInitialized => true;
  @override
  bool get isDarkMode => false;
  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
  @override
  void toggleTheme() {}
}

class MockReportService extends ReportService {
  final List<Report> reports;
  MockReportService(this.reports);

  @override
  Stream<List<Report>> getReports({String? status, int limit = 50}) {
    if (status == null) return Stream.value(reports.take(limit).toList());
    return Stream.value(reports.where((r) => r.status == status).take(limit).toList());
  }
}

class MockAuthService extends AuthService {
  @override
  UserProfile? get impersonatedProfile => null;
  @override
  void stopImpersonating() {}
  @override
  Future<void> signOut() async {}
}

class MockUserService extends UserService {
  final Map<String, UserProfile> userProfiles;
  MockUserService(this.userProfiles);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return userProfiles[uid];
  }

  @override
  Stream<List<UserProfile>> getMaintainers({int limit = 50}) {
    return Stream.value(userProfiles.values.where((u) => u.role == 'maintainer').toList());
  }
}

void main() {
  testWidgets('ManagerReportCard displays assignee name for assigned tasks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final report = Report(
      id: '1',
      title: 'Leaking Faucet',
      description: 'The faucet in the kitchen is leaking.',
      reporterName: 'John Doe',
      reporterPhone: '123456789',
      location: 'Kitchen',
      status: 'assigned',
      reporterId: 'reporter_1',
      assignedTo: 'maintainer_1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      reportDateTime: DateTime.now(),
    );

    final maintainer = UserProfile(
      uid: 'maintainer_1',
      email: 'm1@test.com',
      displayName: 'Bob Fixer',
      role: 'maintainer',
    );

    final mockReportService = MockReportService([report]);
    final mockUserService = MockUserService({'maintainer_1': maintainer});
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ReportService>(create: (_) => mockReportService),
          Provider<UserService>(create: (_) => mockUserService),
          Provider<AuthService>(create: (_) => mockAuthService),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => MockThemeProvider()),
        ],
        child: const MaterialApp(
          home: ManagerHome(),
        ),
      ),
    );

    // Wait for stream to load
    await tester.pump();

    // Verify report card is visible
    expect(find.text('Leaking Faucet'), findsOneWidget);
    expect(find.text('ASSIGNED'), findsOneWidget);

    // Re-pump to allow FutureBuilder to complete
    await tester.pump();
    await tester.pump();

    // Verify assignee name is visible
    expect(find.text('Assigned to: Bob Fixer'), findsOneWidget);
  });

  testWidgets('ManagerReportCard displays assignee name for in_progress tasks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final report = Report(
      id: '2',
      title: 'Broken Light',
      description: 'The light in the hallway is broken.',
      reporterName: 'Jane Smith',
      reporterPhone: '987654321',
      location: 'Hallway',
      status: 'in_progress',
      reporterId: 'reporter_2',
      assignedTo: 'maintainer_2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      reportDateTime: DateTime.now(),
    );

    final maintainer = UserProfile(
      uid: 'maintainer_2',
      email: 'm2@test.com',
      displayName: 'Alice Mender',
      role: 'maintainer',
    );

    final mockReportService = MockReportService([report]);
    final mockUserService = MockUserService({'maintainer_2': maintainer});
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ReportService>(create: (_) => mockReportService),
          Provider<UserService>(create: (_) => mockUserService),
          Provider<AuthService>(create: (_) => mockAuthService),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => MockThemeProvider()),
        ],
        child: const MaterialApp(
          home: ManagerHome(),
        ),
      ),
    );

    // Wait for stream to load
    await tester.pump();

    // Verify report card is visible
    expect(find.text('Broken Light'), findsOneWidget);
    expect(find.text('WORKING'), findsOneWidget);

    // Re-pump to allow FutureBuilder to complete
    await tester.pump();
    await tester.pump();

    // Verify assignee name is visible
    expect(find.text('Assigned to: Alice Mender'), findsOneWidget);
  });
}
