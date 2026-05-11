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
import '../../l10n/app_localizations.dart';
import '../widgets/password_field.dart';
import '../../services/trial_service.dart';
import 'package:intl/intl.dart';

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
  final _orgDomainController = TextEditingController();
  
  // Admin fields
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  // Trial fields (Global)
  final _trialService = TrialService();
  final _defaultTrialDaysController = TextEditingController();
  final _contactEmailController = TextEditingController();
  bool _isSavingConfig = false;

  // Trial fields (Selected Org)
  final _orgTrialEndsAtController = TextEditingController();
  final _orgTrialDurationController = TextEditingController();
  bool _isUpdatingOrgTrial = false;

  bool _isLoadingOrg = false;
  bool _isLoadingAdmin = false;
  String? _selectedOrgId;
  String? _createdOrgId;
  bool _isAdminCreated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGlobalTrialConfig();
  }

  Future<void> _loadGlobalTrialConfig() async {
    final config = await _trialService.getTrialConfig();
    setState(() {
      _defaultTrialDaysController.text = config['defaultTrialDays'].toString();
      _contactEmailController.text = config['contactEmail'];
    });
  }

  Future<void> _saveGlobalTrialConfig() async {
    setState(() => _isSavingConfig = true);
    try {
      await _trialService.setTrialConfig(
        defaultTrialDays: int.tryParse(_defaultTrialDaysController.text),
        contactEmail: _contactEmailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('config_saved')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  void _loadOrgTrialData(Organization org) {
    _orgTrialDurationController.text = (org.trialDurationDays ?? 7).toString();
    if (org.trialEndsAt != null) {
      _orgTrialEndsAtController.text = DateFormat('yyyy-MM-dd').format(org.trialEndsAt!);
    } else {
      _orgTrialEndsAtController.text = '';
    }
  }

  Future<void> _updateOrgTrial() async {
    if (_selectedOrgId == null) return;
    setState(() => _isUpdatingOrgTrial = true);
    try {
      final endsAtText = _orgTrialEndsAtController.text.trim();
      DateTime? endsAt;
      if (endsAtText.isNotEmpty) {
        endsAt = DateFormat('yyyy-MM-dd').parse(endsAtText);
      }
      
      await _orgService.updateOrgTrial(
        _selectedOrgId!,
        trialEndsAt: endsAt,
        trialDurationDays: int.tryParse(_orgTrialDurationController.text),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('trial_updated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingOrgTrial = false);
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgDescController.dispose();
    _orgDomainController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    _defaultTrialDaysController.dispose();
    _contactEmailController.dispose();
    _orgTrialEndsAtController.dispose();
    _orgTrialDurationController.dispose();
    super.dispose();
  }

  Future<void> _registerOrg() async {
    if (_orgNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context).get('required'));
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
        emailDomain: _orgDomainController.text.trim().toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _isLoadingOrg = false;
          _createdOrgId = orgId;
          _selectedOrgId = orgId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context).get('org_registered_notification')} ID: $orgId")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrg = false;
          _errorMessage = "${AppLocalizations.of(context).get('org_reg_failed')}: $e";
        });
      }
    }
  }

  Future<void> _createAdmin() async {
    final orgId = _selectedOrgId ?? _createdOrgId;
    if (orgId == null) {
      setState(() => _errorMessage = AppLocalizations.of(context).get('select_org_first'));
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
          SnackBar(
            content: Text(AppLocalizations.of(context).get('admin_created_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAdmin = false;
          _errorMessage = "${AppLocalizations.of(context).get('admin_creation_failed')}: $e";
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
      _orgDomainController.clear();
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
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/main10applogo.png', height: 32, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).get('super_admin_console')),
          ],
        ),
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).get('organizations_label'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                return Center(child: Text(AppLocalizations.of(context).get('no_organizations_found')));
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ID: ${org.id}", style: const TextStyle(fontSize: 10)),
                        const SizedBox(height: 4),
                        _buildTrialChip(org),
                      ],
                    ),
                    selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedOrgId = org.id;
                        _errorMessage = null;
                        _isAdminCreated = false; // Reset if switching
                        _createdOrgId = null; // We are picking existing one
                        _loadOrgTrialData(org);
                      });
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: org.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).get('id_copied')), duration: const Duration(seconds: 1)),
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
          _buildGlobalTrialConfigSection(),
          const SizedBox(height: 48),
          _buildSectionHeader(AppLocalizations.of(context).get('phase_1_org_creation')),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orgNameController,
            enabled: _createdOrgId == null && _selectedOrgId == null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('org_name_label'),
              prefixIcon: const Icon(Icons.business),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orgDescController,
            enabled: _createdOrgId == null && _selectedOrgId == null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('org_desc_label'),
              prefixIcon: const Icon(Icons.description),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _orgDomainController,
            enabled: _createdOrgId == null && _selectedOrgId == null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('email_domain_label'),
              hintText: AppLocalizations.of(context).get('email_domain_hint'),
              prefixIcon: const Icon(Icons.alternate_email),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedOrgId == null)
            FilledButton.icon(
              onPressed: (_isLoadingOrg || _createdOrgId != null) ? null : _registerOrg,
              icon: _isLoadingOrg 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_createdOrgId != null ? Icons.check : Icons.add_business),
              label: Text(_createdOrgId != null ? AppLocalizations.of(context).get('org_created_msg') : AppLocalizations.of(context).get('create_new_org')),
            )
          else
            Card(
              color: Colors.blueGrey,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).get('existing_org_info'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (effectiveOrgId != null) ...[
            const SizedBox(height: 32),
            _buildOrgTrialManagementSection(),
          ],

          const SizedBox(height: 32),
          _buildSectionHeader(AppLocalizations.of(context).get('phase_2_admin_assignment')),
          if (effectiveOrgId != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 16.0),
               child: Text("${AppLocalizations.of(context).get('assigning_to_id')}: $effectiveOrgId", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
             ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminNameController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('admin_full_name'),
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context).get('required') : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminEmailController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('admin_login_email'),
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adminPhoneController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('phone_number'),
              prefixIcon: const Icon(Icons.phone),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _adminPasswordController,
            enabled: effectiveOrgId != null && !_isAdminCreated,
            labelText: AppLocalizations.of(context).get('root_password'),
            prefixIcon: Icons.lock,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (_isLoadingAdmin || effectiveOrgId == null || _isAdminCreated) ? null : _createAdmin,
            icon: _isLoadingAdmin 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add),
            label: Text(AppLocalizations.of(context).get('deploy_admin_account')),
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
        _buildSectionHeader(AppLocalizations.of(context).get('current_administrators')),
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
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context).get('no_admins_found'), style: const TextStyle(color: Colors.grey)),
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

  Widget _buildTrialChip(Organization org) {
    final l10n = AppLocalizations.of(context);
    String label;
    Color color;

    if (org.trialEndsAt == null) {
      label = l10n.get('trial_status_no_trial');
      color = Colors.grey;
    } else if (org.isTrialExpired) {
      label = l10n.get('trial_status_expired');
      color = Colors.red;
    } else {
      final days = org.trialDaysRemaining;
      label = "${l10n.get('trial_prefix')}$days${l10n.get('days_left')}";
      color = days <= 2 ? Colors.orange : Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGlobalTrialConfigSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(l10n.get('trial_config_title')),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _defaultTrialDaysController,
                decoration: InputDecoration(
                  labelText: l10n.get('default_trial_days'),
                  prefixIcon: const Icon(Icons.timer),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _contactEmailController,
                decoration: InputDecoration(
                  labelText: l10n.get('contact_email'),
                  prefixIcon: const Icon(Icons.contact_mail),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSavingConfig ? null : _saveGlobalTrialConfig,
                icon: _isSavingConfig
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(l10n.get('save_config')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrgTrialManagementSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(l10n.get('manage_trial')),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _orgTrialEndsAtController,
                decoration: InputDecoration(
                  labelText: l10n.get('trial_ends_at'),
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final current = _orgTrialEndsAtController.text.isNotEmpty
                          ? DateFormat('yyyy-MM-dd').parse(_orgTrialEndsAtController.text)
                          : DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: current,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _orgTrialEndsAtController.text = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _orgTrialDurationController,
                decoration: InputDecoration(
                  labelText: l10n.get('default_trial_days'),
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isUpdatingOrgTrial ? null : _updateOrgTrial,
                icon: _isUpdatingOrgTrial
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.update),
                label: Text(l10n.get('update_trial')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
