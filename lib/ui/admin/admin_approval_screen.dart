import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../l10n/app_localizations.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _adminOrgId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminOrg();
  }

  Future<void> _loadAdminOrg() async {
    final uid = _authService.currentUserId;
    if (uid != null) {
      final profile = await _authService.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _adminOrgId = profile?.organizationId;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminOrgId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('user_approvals') ?? 'User Approvals')),
        body: const Center(child: Text('Error: Could not load organization info')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('user_approvals') ?? 'User Approvals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('organizationId', isEqualTo: _adminOrgId)
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.get('no_pending_approvals') ?? 'No pending approvals'),
                ],
              ),
            );
          }

          final pendingUsers = snapshot.data!.docs.map((doc) => 
            UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>)
          ).toList();

          return ListView.builder(
            itemCount: pendingUsers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _approveUser(user.uid),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: l10n.get('approve') ?? 'Approve',
                      ),
                      IconButton(
                        onPressed: () => _rejectUser(user.uid),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        tooltip: l10n.get('reject') ?? 'Reject',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveUser(String uid) async {
    try {
      await _authService.approveUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(String uid) async {
    // For now, "reject" could just mean deleting the user profile or marking as rejected.
    // Let's just delete the profile for simplicity in this flow.
    try {
      await _firestore.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
