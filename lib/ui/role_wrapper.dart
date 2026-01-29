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
                        const Text("Error: User profile not found"),
                        TextButton(
                          onPressed: () => authService.signOut(), 
                          child: const Text("Logout")
                        )
                      ],
                    )
                  )
                );
             }

             switch (profile.role) {
               case 'admin': return const AdminHome();
               case 'manager': return const ManagerHome();
               case 'maintainer': return const MaintainerHome();
               case 'reporter': 
               default:
                 return const ReporterHome();
             }
          },
        );
      },
    );
  }
}
