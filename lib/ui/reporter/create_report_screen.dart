import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/report.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/audit_service.dart';
import '../../models/location.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';

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
  String? _selectedLocation;
  DateTime _reportDateTime = DateTime.now();
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _organizationId;
  bool _isLoadingOrg = true;
  
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
            _organizationId = profile.organizationId;
            _isLoadingOrg = false;
          });
        }
      }
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reportDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reportDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _reportDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context).get('error_picking_image')}: $e"))
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).get('photo_library')),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context).get('camera')),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); 
      
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
      
      // Get user profile to access organizationId
      final profile = await authService.getUserProfile(userId);
      if (profile == null) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: User profile not found."))
            );
          }
          return;
      }
      
      final reportService = Provider.of<ReportService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      List<String> imageUrls = [];
      
      try {
        if (_selectedImages.isNotEmpty) {
          imageUrls = await storageService.uploadFiles(_selectedImages, 'reports');
        }

        final report = Report(
          id: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          imageUrls: imageUrls,
          reporterName: _nameController.text.trim(),
          reporterPhone: _phoneController.text.trim(),
          location: _selectedLocation ?? '',
          status: 'open',
          reporterId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          reportDateTime: _reportDateTime,
          organizationId: profile.organizationId, // Add organizationId
        );

        final String reportId = await reportService.createReport(report);
        
        // Log auditing action
        if (mounted) {
          final auditService = Provider.of<AuditService>(context, listen: false);
          await auditService.logAction(
            reportId: reportId,
            userId: userId,
            userName: profile.displayName,
            action: 'created',
            details: 'Report created at ${report.location}',
            organizationId: profile.organizationId, // Add organizationId
          );
        }
        
        if (mounted) {
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).get('report_success')),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              width: 400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              width: 400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
          setState(() => _isLoading = false);
        }
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingOrg || _organizationId == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('create_report')),
      ),
      body: ResponsiveCenter(
        maxWidth: 650,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, AppLocalizations.of(context).get('tell_us_happened'), AppLocalizations.of(context).get('provide_clear_details')),
                const SizedBox(height: 32),
                
                _buildFieldGroup(
                  context,
                  AppLocalizations.of(context).get('report_details_cap'),
                  [
                    _buildLabel(AppLocalizations.of(context).get('issue_title')),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).get('issue_title_hint'),
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                      ),
                      validator: (v) => v!.isEmpty ? AppLocalizations.of(context).get('required') : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(AppLocalizations.of(context).get('detailed_description')),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).get('description_hint'),
                        prefixIcon: const Icon(Icons.description_rounded, size: 20),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? AppLocalizations.of(context).get('required') : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(AppLocalizations.of(context).get('specific_location')),
                    StreamBuilder<List<Location>>(
                      stream: Provider.of<LocationService>(context, listen: false).getLocations(_organizationId!),
                      builder: (context, snapshot) {
                        final locations = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedLocation,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context).get('select_location_hint'),
                            prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                          ),
                          items: locations.map((loc) => DropdownMenuItem(
                            value: loc.name,
                            child: Text(loc.name),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedLocation = value),
                          validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context).get('required') : null,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(AppLocalizations.of(context).get('incident_date_time')),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${_reportDateTime.day}/${_reportDateTime.month}/${_reportDateTime.year} at ${TimeOfDay.fromDateTime(_reportDateTime).format(context)}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Icon(Icons.edit_calendar_rounded, size: 20, color: Theme.of(context).colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(AppLocalizations.of(context).get('attachments')),
                    _buildImageSelection(context),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                _buildFieldGroup(
                  context,
                  AppLocalizations.of(context).get('reporter_info_cap'),
                  [
                    _buildLabel(AppLocalizations.of(context).get('full_name')),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).get('name_hint'),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) => v!.isEmpty ? AppLocalizations.of(context).get('required') : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(AppLocalizations.of(context).get('phone_number')),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).get('phone_hint'),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? AppLocalizations.of(context).get('required') : null,
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                FilledButton(
                  onPressed: _isLoading ? null : _submitReport,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : Text(AppLocalizations.of(context).get('submit_maintenance_report')),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                          ? Image.network(
                              _selectedImages[index].path,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImages[index].path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showImagePickerOptions,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: Text(AppLocalizations.of(context).get('add_photo')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
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
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
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
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
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
