import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';

class ManageUserScreen extends StatefulWidget {
  final UserProfile? user;

  const ManageUserScreen({super.key, this.user});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String _selectedRole = 'reporter';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.displayName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? 'reporter';
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       final authService = Provider.of<AuthService>(context, listen: false);
       final userService = Provider.of<UserService>(context, listen: false);
       
       try {
         if (widget.user == null) {
           // Get current admin's organizationId
           final currentUserId = authService.currentUserId;
           if (currentUserId == null) throw Exception("Not authenticated");
           
           final currentUserProfile = await authService.getUserProfile(currentUserId);
           if (currentUserProfile == null) throw Exception("User profile not found");
           
           await authService.createUser(
             _emailController.text.trim(),
             _passwordController.text.trim(),
             _selectedRole,
             _nameController.text.trim(),
             _phoneController.text.trim(),
             currentUserProfile.organizationId, // Pass organizationId
           );
         } else {
           await userService.updateUser(widget.user!.uid, {
             'displayName': _nameController.text.trim(),
             'role': _selectedRole,
             'phoneNumber': _phoneController.text.trim(),
           });
         }
         
         if (mounted) Navigator.pop(context);
       } catch (e) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? l10n.get('create_new_user') : l10n.get('edit_user_profile')),
      ),
      body: ResponsiveCenter(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, 
                  widget.user == null ? l10n.get('add_new_member') : l10n.get('update_member_info'), 
                  l10n.get('fill_details_member')
                ),
                const SizedBox(height: 32),
                
                _buildFieldGroup(context, l10n.get('personal_info'), [
                  _buildLabel(l10n.get('display_name')),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: l10n.get('full_name_hint'),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(l10n.get('phone_number')),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: l10n.get('primary_contact_hint'),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                  ),
                ]),
                
                const SizedBox(height: 40),
                
                _buildFieldGroup(context, l10n.get('account_credentials'), [
                  _buildLabel(l10n.get('email_address')),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "identity@fixitpro.com",
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                      enabled: widget.user == null,
                    ),
                    validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                    style: widget.user != null ? TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)) : null,
                  ),
                  if (widget.user == null) ...[
                    const SizedBox(height: 24),
                    _buildLabel(l10n.get('initial_password')),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: l10n.get('choose_password_hint'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      ),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? l10n.get('required') : null,
                    ),
                  ],
                ]),
                
                const SizedBox(height: 40),
                
                _buildFieldGroup(context, l10n.get('access_control'), [
                  _buildLabel(l10n.get('system_role')),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: ['admin', 'manager', 'maintainer', 'reporter'].map((role) {
                      String roleLabel = role;
                      if (role == 'admin') roleLabel = l10n.get('admins');
                      else if (role == 'manager') roleLabel = l10n.get('managers');
                      else if (role == 'maintainer') roleLabel = l10n.get('maintainers');
                      else if (role == 'reporter') roleLabel = l10n.get('reporters');
                      
                      return DropdownMenuItem(
                        value: role, 
                        child: Text(roleLabel.toUpperCase(), style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                    ),
                  ),
                ]),
                
                const SizedBox(height: 48),
                
                FilledButton(
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : Text(widget.user == null ? l10n.get('create_user_account') : l10n.get('save_changes')),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2),
      ),
    );
  }

  Widget _buildFieldGroup(BuildContext context, String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
