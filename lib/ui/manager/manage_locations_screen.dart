import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final _nameController = TextEditingController();
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

  Future<void> _addLocation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _organizationId == null) return;

    final locationService = Provider.of<LocationService>(context, listen: false);
    try {
      await locationService.addLocation(name, _organizationId!);
      _nameController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_adding_location')}: $e")),
        );
      }
    }
  }

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('add_new_location')),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.get('location_name_hint'),
            labelText: l10n.get('location_name_label'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: _addLocation,
            child: Text(l10n.get('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(Location location) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_location_title')),
        content: Text("${l10n.get('delete_location_confirm')} '${location.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      try {
        await locationService.deleteLocation(location.id);
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.get('error_deleting_location')}: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('manage_locations')),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: StreamBuilder<List<Location>>(
          stream: locationService.getLocations(_organizationId!),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Firestore Error in ManageLocationsScreen: ${snapshot.error}");
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final locations = snapshot.data ?? [];
            if (locations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.get('no_locations_yet')),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.get('add_first_location')),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_rounded),
                    title: Text(location.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                      onPressed: () => _deleteLocation(location),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
