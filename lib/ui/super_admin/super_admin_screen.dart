import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/organization_service.dart';
import '../../scripts/organization_setup.dart';
import '../../models/organization.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../widgets/responsive_center.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgService = OrganizationService();
  final _userService = UserService();
  
  // Organization fields
  final _orgNameController = TextEditingController();
  final _orgDescController = TextEditingController();
  
  // Admin fields
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  bool _isLoadingOrg = false;
  bool _isLoadingAdmin = false;
  String? _selectedOrgId;
  String? _createdOrgId;
  bool _isAdminCreated = false;
  String? _errorMessage;

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgDescController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerOrg() async {
    if (_orgNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Organization name is required");
      return;
    }

    setState(() {
      _isLoadingOrg = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final setup = OrganizationSetup(orgService: _orgService, authService: authService);

      final orgId = await setup.createOrganization(
        name: _orgNameController.text.trim(),
        description: _orgDescController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoadingOrg = false;
          _createdOrgId = orgId;
          _selectedOrgId = orgId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Organization registered! ID: $orgId")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrg = false;
          _errorMessage = "Organization registration failed: $e";
        });
      }
    }
  }

  Future<void> _createAdmin() async {
    final orgId = _selectedOrgId ?? _createdOrgId;
    if (orgId == null) {
      setState(() => _errorMessage = "Please select or create an organization first");
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoadingAdmin = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final setup = OrganizationSetup(orgService: _orgService, authService: authService);

      await setup.createAdminForOrganization(
        orgId: orgId,
        adminName: _adminNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
        adminPhone: _adminPhoneController.text.trim(),
        adminPassword: _adminPasswordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
          _isAdminCreated = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
          _errorMessage = "Admin creation failed: $e";
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _createdOrgId = null;
      _selectedOrgId = null;
      _isAdminCreated = false;
      _errorMessage = null;
      _orgNameController.clear();
      _orgDescController.clear();
      _adminNameController.clear();
      _adminEmailController.clear();
      _adminPhoneController.clear();
      _adminPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Console"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: "Clear/New",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar with List of Organizations
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: _buildOrgList(),
            ),
          ),
          // Main Content with Forms
          Expanded(
            flex: 3,
            child: ResponsiveCenter(
              maxWidth: 700,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "ORGANIZATIONS",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Organization>>(
            stream: _orgService.getAllOrganizations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No organizations found"));
              }

              final orgs = snapshot.data!;
              return ListView.separated(
                itemCount: orgs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final org = orgs[index];
                  final isSelected = _selectedOrgId == org.id;
                  return ListTile(
                    selected: isSelected,
                    title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ID: ${org.id}", style: const TextStyle(fontSize: 10)),
                    selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedOrgId = org.id;
                        _errorMessage = null;
                        _isAdminCreated = false; // Reset if switching
                        _createdOrgId = null; // We are picking existing one
                      });
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: org.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("ID copied to clipboard"), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepSection() {
    final effectiveOrgId = _selectedOrgId ?? _createdOrgId;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader("Phase 1: Organization Creation"),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orgNameController,
            enabled: _createdOrgId == null && _selectedOrgId == null,
            decoration: const InputDecoration(
              labelText: "Organization Name",
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orgDescController,
            enabled: _createdOrgId == null && _selectedOrgId == null,
            decoration: const InputDecoration(
              labelText: "Description",
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          if (_selectedOrgId == null)
            FilledButton.icon(
              onPressed: (_isLoadingOrg || _createdOrgId != null) ? null : _registerOrg,
              icon: _isLoadingOrg 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_createdOrgId != null ? Icons.check : Icons.add_business),
              label: Text(_createdOrgId != null ? "Organization Created" : "Create New Organization"),
            )
          else
            const Card(
              color: Colors.blueGrey,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You are adding an admin to an existing organization.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          _buildSectionHeader("Phase 2: Root Admin Assignment"),
          if (effectiveOrgId != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 16.0),
               child: Text("Assigning to ID: $effectiveOrgId", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
             ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminNameController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: const InputDecoration(
              labelText: "Admin Full Name",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminEmailController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: const InputDecoration(
              labelText: "Admin Login Email",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminPhoneController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminPasswordController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: const InputDecoration(
              labelText: "Root Password",
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (_isLoadingAdmin || effectiveOrgId == null || _isAdminCreated) ? null : _createAdmin,
            icon: _isLoadingAdmin 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add),
            label: const Text("Deploy Admin Account"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          if (effectiveOrgId != null) ...[
            const SizedBox(height: 32),
            _buildAdminsList(effectiveOrgId),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminsList(String orgId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Current Administrators"),
        const SizedBox(height: 16),
        StreamBuilder<List<UserProfile>>(
          stream: _userService.getAdmins(orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LinearProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Text("No administrators found for this organization.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final admins = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(admin.displayName),
                    subtitle: Text(admin.email),
                    trailing: const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(),
      ],
    );
  }
}
