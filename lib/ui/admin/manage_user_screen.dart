import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ManageUserScreen extends StatefulWidget {
  final UserProfile? user; // Null if creating new

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
           await authService.createUser(
             _emailController.text.trim(),
             _passwordController.text.trim(),
             _selectedRole,
             _nameController.text.trim(),
             _phoneController.text.trim(),
           );
         } else {
           // Update existing user role and phone
           await userService.updateUser(widget.user!.uid, {
             'displayName': _nameController.text.trim(),
             'role': _selectedRole,
             'phoneNumber': _phoneController.text.trim(),
           });
         }
         
         if (mounted) Navigator.pop(context);
       } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user == null ? "Create User" : "Edit User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Display Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                 controller: _emailController,
                 decoration: const InputDecoration(labelText: "Email"),
                 validator: (v) => v!.isEmpty ? "Required" : null,
                 enabled: widget.user == null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                 controller: _phoneController,
                 decoration: const InputDecoration(labelText: "Phone Number"),
                 validator: (v) => v!.isEmpty ? "Required" : null,
                 keyboardType: TextInputType.phone,
              ),
              if (widget.user == null) ...[
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _passwordController,
                   decoration: const InputDecoration(labelText: "Password"),
                   validator: (v) => v!.isEmpty ? "Required" : null,
                 ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['admin', 'manager', 'maintainer', 'reporter'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
                decoration: const InputDecoration(labelText: "Role"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                 child: FilledButton(
                   onPressed: _isLoading ? null : _saveUser,
                   child: _isLoading ? const CircularProgressIndicator() : const Text("Save User"),
                 ),
              ),
              if (widget.user == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("Note: Creating a user will sign you in as that user in this demo.", style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
