import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'manage_user_screen.dart';
import '../widgets/responsive_center.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? _organizationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;
    if (userId != null) {
      final profile = await authService.getUserProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _organizationId = profile.organizationId;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authService.impersonatedProfile != null 
                  ? "Impersonating: ${authService.impersonatedProfile!.displayName}" 
                  : "User Management",
              style: textTheme.titleLarge,
            ),
            if (authService.impersonatedProfile == null)
              Text(
                "Manage application users and roles",
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
          ],
        ),
        actions: [
          if (authService.impersonatedProfile != null)
             Padding(
               padding: const EdgeInsets.only(right: 8.0),
               child: IconButton.filledTonal(
                 onPressed: () => authService.stopImpersonating(),
                 icon: const Icon(Icons.stop_screen_share_rounded, size: 20),
                 tooltip: "Stop Impersonating",
               ),
             ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => authService.signOut(), 
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: "Logout",
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: StreamBuilder<List<UserProfile>>(
          stream: userService.getAllUsers(_organizationId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final users = snapshot.data ?? [];
            
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _UserCard(user: user, authService: authService, userService: userService),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUserScreen()));
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("Add User"),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  final AuthService authService;
  final UserService userService;

  const _UserCard({
    required this.user, 
    required this.authService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCurrentUser = authService.currentUserId == user.uid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : "?",
                style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Text(
                         user.displayName,
                         style: textTheme.titleMedium,
                       ),
                       if (isCurrentUser) ...[
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: colorScheme.primaryContainer,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text("YOU", style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                         ),
                       ],
                     ],
                   ),
                  const SizedBox(height: 2),
                  Text(user.email, style: textTheme.bodySmall),
                  const SizedBox(height: 8),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrentUser)
                  IconButton(
                    tooltip: "Login as this user",
                    icon: const Icon(Icons.login_rounded, color: Colors.green, size: 20),
                    onPressed: () => authService.loginAs(user),
                  ),
                IconButton(
                  tooltip: "Edit user",
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUserScreen(user: user)));
                  },
                ),
                if (!isCurrentUser)
                  IconButton(
                    tooltip: "Delete user",
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(context, userService, user),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red.shade700;
      case 'manager': return Colors.blue.shade700;
      case 'maintainer': return Colors.orange.shade700;
      case 'reporter': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, UserService userService, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Are you sure you want to delete ${user.displayName}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await userService.deleteUser(user.uid);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User ${user.displayName} deleted"))
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin': color = Colors.red.shade700; break;
      case 'manager': color = Colors.blue.shade700; break;
      case 'maintainer': color = Colors.orange.shade700; break;
      case 'reporter': color = Colors.green.shade700; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
