import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';

/// Script logic to create a new organization and a default admin user
class OrganizationSetup {
  final OrganizationService _orgService;
  final AuthService _authService;

  OrganizationSetup({
    required OrganizationService orgService,
    required AuthService authService,
  })  : _orgService = orgService,
        _authService = authService;

  /// Registers just the organization and returns its ID
  Future<String> createOrganization({
    required String name,
    required String description,
  }) async {
    try {
      print("📦 Registering organization: $name");
      final orgRef = FirebaseFirestore.instance.collection('organizations').doc();
      
      await orgRef.set({
        'name': name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print("✅ Organization created with ID: ${orgRef.id}");
      return orgRef.id;
    } catch (e) {
      print("❌ Failed to create organization: $e");
      rethrow;
    }
  }

  /// Creates the admin user and links them to the given organization
  /// Uses a temporary Firebase app to avoid signing out the current super admin
  Future<void> createAdminForOrganization({
    required String orgId,
    required String adminEmail,
    required String adminPassword,
    required String adminName,
    required String adminPhone,
  }) async {
    try {
      print("👤 Creating admin user for org: $orgId");
      
      await _authService.createUser(
        adminEmail,
        adminPassword,
        'admin',
        adminName,
        adminPhone,
        orgId,
      );

      print("✅ Admin created successfully (via temp app)");
    } catch (e) {
      print("❌ Failed to create admin: $e");
      rethrow;
    }
  }
}
