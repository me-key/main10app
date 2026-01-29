import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../widgets/responsive_center.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  Future<void> _prefillUserInfo() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUserId;
    if (uid != null) {
      final profile = await authService.getUserProfile(uid);
      if (profile != null) {
        if (mounted) {
          setState(() {
            _nameController.text = profile.displayName;
            _phoneController.text = profile.phoneNumber;
          });
        }
      }
    }
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Dismiss keyboard to prevent focus issue on web/mobile
      
      setState(() => _isLoading = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;
      
      if (userId == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: User not identified. Please login again."))
            );
          }
          return;
      }
      
      final reportService = Provider.of<ReportService>(context, listen: false);
      
      final report = Report(
        id: '', // Service will generate ID
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        reporterName: _nameController.text.trim(),
        reporterPhone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        status: 'open',
        reporterId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await reportService.createReport(report);
        
        if (mounted) {
          // Pop first to prevent "rendering disposed view"
          Navigator.of(context).pop(); 
          
          // Then show snackbar (root scaffold messenger usually handles this safely)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Report created successfully!"),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              width: 400, // Constrain width on web
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = "Error creating report";
          Color backgroundColor = Colors.red;
          
          if (e is TimeoutException) {
            errorMessage = "Submission timed out. Please check your internet connection and try again.";
          } else if (e.toString().contains('unavailable')) {
            errorMessage = "Service unavailable. Please try again later.";
          } else if (e.toString().contains('permission-denied')) {
            errorMessage = "Permission denied. Please check your account permissions.";
          } else {
            errorMessage = "Error: $e";
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              width: 400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
          setState(() => _isLoading = false);
        }
      } 
      // Removed finally block to prevent setState after pop on success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Report")),
      body: ResponsiveCenter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Incident Details"),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            hintText: "Brief summary of the issue",
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            hintText: "Detailed explanation...",
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: "Location",
                            hintText: "Building, Floor, Room...",
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle("Contact Information"),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Your Name",
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                         const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _submitReport,
                    icon: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.send),
                    label: Text(_isLoading ? "Submitting..." : "Submit Report"),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
