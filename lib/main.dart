import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; 
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'services/user_service.dart';
import 'services/storage_service.dart';
import 'services/location_service.dart';
import 'services/audit_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/role_wrapper.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/auth/signup_screen.dart';
import 'ui/auth/approval_pending_screen.dart';
import 'ui/admin/admin_approval_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
  } catch (e) {
    print("Warning: Firebase initialization failed. Error: $e");
    // On Web, we cannot call initializeApp() without options.
    // We will proceed without Firebase, which means Auth/Firestore calls will fail.
    // This allows the UI to at least render for verification.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ReportService>(create: (_) => ReportService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<AuditService>(create: (_) => AuditService()),
      ],
      child: const FixItProApp(),
    ),
  );
}

class FixItProApp extends StatelessWidget {
  const FixItProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).get('app_title'),
          theme: appTheme,
          darkTheme: appDarkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('he', ''),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RoleWrapper(),
          routes: {
            '/login': (context) => const RoleWrapper(), // RoleWrapper handles login state
            '/signup': (context) => const SignUpScreen(),
            '/approval-pending': (context) => const ApprovalPendingScreen(),
            '/admin-approvals': (context) => const AdminApprovalScreen(),
          },
        );
      },
    );
  }
}


