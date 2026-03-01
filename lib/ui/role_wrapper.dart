import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'auth/login_screen.dart';
import 'reporter/reporter_home.dart';
import 'maintainer/maintainer_home.dart';
import 'manager/manager_home.dart';
import 'admin/admin_home.dart';
import 'super_admin/super_admin_screen.dart';
import '../l10n/app_localizations.dart';

class RoleWrapper extends StatefulWidget {
  const RoleWrapper({super.key});

  @override
  State<RoleWrapper> createState() => _RoleWrapperState();
}

class _RoleWrapperState extends State<RoleWrapper> {
  Future<UserProfile?>? _profileFuture;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          _profileFuture = null;
          _lastUid = null;
          return const LoginScreen();
        }

        final user = snapshot.data!;
        
        // Cache the profile future to prevent re-fetching on every build
        if (_profileFuture == null || _lastUid != user.uid) {
           _lastUid = user.uid;
           _profileFuture = authService.getUserProfile(user.uid);
        }
        
        // Fetch role from Firestore
        return StreamBuilder<UserProfile?>(
          stream: authService.impersonationChanges,
          builder: (context, impersonationSnapshot) {
            final impersonatedProfile = impersonationSnapshot.data ?? authService.impersonatedProfile;
            
            if (impersonatedProfile != null) {
              return _buildHomeForRole(impersonatedProfile.role);
            }

            return FutureBuilder<UserProfile?>(
              future: _profileFuture,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                final profile = profileSnapshot.data;
                if (profile == null) {
                    // Fallback if no profile
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).get('account_issue'),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).get('account_missing_msg'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => authService.signOut(), 
                              icon: const Icon(Icons.logout),
                              label: Text(AppLocalizations.of(context).get('logout')),
                            )
                          ],
                        )
                      )
                    );
                }

                return _buildHomeForRole(profile.role);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHomeForRole(String role) {
    switch (role) {
      case 'super_admin': return const SuperAdminScreen();
      case 'admin': return const AdminHome();
      case 'manager': return const ManagerHome();
      case 'maintainer': return const MaintainerHome();
      case 'reporter': 
      default:
        return const ReporterHome();
    }
  }
}
