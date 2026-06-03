import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:main10app/ui/auth/login_screen.dart';
import 'package:main10app/services/auth_service.dart';
import 'package:main10app/providers/environment_provider.dart';
import 'package:main10app/providers/theme_provider.dart';
import 'package:main10app/providers/locale_provider.dart';
import 'package:main10app/models/user_profile.dart';
import 'package:main10app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class MockLocaleProvider extends ChangeNotifier implements LocaleProvider {
  @override
  Locale get locale => const Locale('en');
  @override
  Future<void> setLocale(Locale locale) async {}
  @override
  void toggleLocale() {}
}

class MockEnvironmentProvider extends ChangeNotifier implements EnvironmentProvider {
  AppState _currentState;
  MockEnvironmentProvider(this._currentState);

  @override
  AppState get currentState => _currentState;
  @override
  bool get isInitialized => true;
  @override
  bool get isDev => _currentState == AppState.dev;
  @override
  bool get isTest => _currentState == AppState.test;
  @override
  bool get isProd => _currentState == AppState.prod;

  @override
  Future<void> setEnvironment(AppState state) async {
    _currentState = state;
    notifyListeners();
  }
}

class MockAuthService implements AuthService {
  bool signUpReporterCalled = false;
  String? capturedEmail;

  @override
  UserProfile? get impersonatedProfile => null;

  @override
  Stream<UserProfile?> get impersonationChanges => const Stream.empty();

  @override
  Future<User?> signUpReporter({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String organizationId,
  }) async {
    signUpReporterCalled = true;
    capturedEmail = email;
    return null;
  }

  @override
  Stream<User?> get authStateChanges => const Stream.empty();
  @override
  User? get currentUser => null;
  @override
  String? get currentUserId => null;
  @override
  void loginAs(UserProfile profile) {}
  @override
  void stopImpersonating() {}
  @override
  Future<void> mockRole(String role) async {}
  @override
  Future<UserProfile?> getUserProfile(String uid) async => null;
  @override
  Future<User?> signIn(String email, String password) async => null;
  @override
  Future<void> createUser(String email, String password, String role, String name, String phoneNumber, String organizationId) async {}
  @override
  Future<User?> signUp(String email, String password) async => null;
  @override
  Future<void> approveUser(String uid) async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> updateUserProfile({required String uid, required String displayName, required String phoneNumber}) async {}
  @override
  Future<void> updateNotificationPreferences(String uid, NotificationPreferences prefs) async {}
  @override
  Future<void> updateFcmToken(String uid, String? token) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  // Ignore overflow errors in testing due to Ahem font
  final originalOnError = FlutterError.onError;
  setUpAll(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  tearDownAll(() {
    FlutterError.onError = originalOnError;
  });

  testWidgets('Bypass Sign In button is hidden in PROD environment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockAuth = MockAuthService();
    final mockEnv = MockEnvironmentProvider(AppState.prod);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => mockAuth),
          ChangeNotifierProvider<EnvironmentProvider>(create: (_) => mockEnv),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => MockThemeProvider()),
          ChangeNotifierProvider<LocaleProvider>(create: (_) => MockLocaleProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('he', ''),
          ],
          locale: Locale('en', ''),
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bypass Sign In'), findsNothing);
  });

  testWidgets('Bypass Sign In button is visible in TEST environment and signs in', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockAuth = MockAuthService();
    final mockEnv = MockEnvironmentProvider(AppState.test);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => mockAuth),
          ChangeNotifierProvider<EnvironmentProvider>(create: (_) => mockEnv),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => MockThemeProvider()),
          ChangeNotifierProvider<LocaleProvider>(create: (_) => MockLocaleProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('he', ''),
          ],
          locale: Locale('en', ''),
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify bypass button is visible
    expect(find.text('Bypass Sign In'), findsOneWidget);

    // Tap it
    await tester.tap(find.text('Bypass Sign In'));
    await tester.pump();

    // Verify signUpReporter was called
    expect(mockAuth.signUpReporterCalled, isTrue);
    expect(mockAuth.capturedEmail, contains('@testorg.com'));
  });
}
