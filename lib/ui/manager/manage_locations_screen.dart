import 'dart:async';
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

  StreamSubscription<List<Location>>? _locationsSub;
  List<Location> _locations = [];
  bool _locationsLoading = true;
  String? _locationsError;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _locationsSub?.cancel();
    _nameController.dispose();
    super.dispose();
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
        _subscribeToLocations();
      }
    }
  }

  // Locations are kept in local state (rather than a StreamBuilder) so drag-and-drop
  // reordering can update the UI immediately, ahead of the Firestore round-trip.
  void _subscribeToLocations() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    _locationsSub = locationService.getLocations(_organizationId!).listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _locations = data;
          _locationsLoading = false;
          _locationsError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _locationsError = e.toString();
          _locationsLoading = false;
        });
      },
    );
  }

  Future<void> _addLocation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _organizationId == null) return;

    final locationService = Provider.of<LocationService>(context, listen: false);
    try {
      await locationService.addLocation(name, _organizationId!, sortOrder: _locations.length);
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

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _locations.removeAt(oldIndex);
      _locations.insert(newIndex, item);
    });
    try {
      await locationService.reorderLocations(_locations);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_reordering_location')}: $e")),
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
    if (_isLoading || _organizationId == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context);

    Widget body;
    if (_locationsError != null) {
      debugPrint("Firestore Error in ManageLocationsScreen: $_locationsError");
      body = Center(child: Text("Error: $_locationsError"));
    } else if (_locationsLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_locations.isEmpty) {
      body = Center(
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
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        itemCount: _locations.length,
        onReorder: _handleReorder,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return Card(
            key: ValueKey(location.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_rounded),
              ),
              title: Text(location.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                onPressed: () => _deleteLocation(location),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('manage_locations')),
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: body,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
