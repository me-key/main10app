import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/area.dart';
import '../../services/area_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({super.key});

  @override
  State<ManageAreasScreen> createState() => _ManageAreasScreenState();
}

class _ManageAreasScreenState extends State<ManageAreasScreen> {
  final _nameController = TextEditingController();
  String? _organizationId;
  bool _isLoading = true;

  StreamSubscription<List<Area>>? _areasSub;
  List<Area> _areas = [];
  bool _areasLoading = true;
  String? _areasError;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _areasSub?.cancel();
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
        final areaService = Provider.of<AreaService>(context, listen: false);
        await areaService.ensureDefaultArea(_organizationId!);
        _subscribeToAreas();
      }
    }
  }

  // Areas are kept in local state (rather than a StreamBuilder) so drag-and-drop
  // reordering can update the UI immediately, ahead of the Firestore round-trip.
  void _subscribeToAreas() {
    final areaService = Provider.of<AreaService>(context, listen: false);
    _areasSub = areaService.getAreas(_organizationId!).listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _areas = data;
          _areasLoading = false;
          _areasError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _areasError = e.toString();
          _areasLoading = false;
        });
      },
    );
  }

  Future<void> _addArea() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _organizationId == null) return;

    final areaService = Provider.of<AreaService>(context, listen: false);
    try {
      await areaService.addArea(name, _organizationId!, sortOrder: _areas.length);
      _nameController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_adding_area')}: $e")),
        );
      }
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final areaService = Provider.of<AreaService>(context, listen: false);
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _areas.removeAt(oldIndex);
      _areas.insert(newIndex, item);
    });
    try {
      await areaService.reorderAreas(_areas);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_reordering_area')}: $e")),
        );
      }
    }
  }

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('add_new_area')),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.get('area_name_hint'),
            labelText: l10n.get('area_name_label'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: _addArea,
            child: Text(l10n.get('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArea(Area area) async {
    final l10n = AppLocalizations.of(context);
    if (area.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('cannot_delete_default_area'))),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_area_title')),
        content: Text("${l10n.get('delete_area_confirm')} '${area.name}'?"),
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
      final areaService = Provider.of<AreaService>(context, listen: false);
      try {
        await areaService.deleteArea(area.id);
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.get('error_deleting_area')}: $e")),
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
    if (_areasError != null) {
      debugPrint("Firestore Error in ManageAreasScreen: $_areasError");
      body = Center(child: Text("Error: $_areasError"));
    } else if (_areasLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_areas.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.get('no_areas_yet')),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.get('add_first_area')),
            ),
          ],
        ),
      );
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        itemCount: _areas.length,
        onReorder: _handleReorder,
        itemBuilder: (context, index) {
          final area = _areas[index];
          return Card(
            key: ValueKey(area.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_rounded),
              ),
              title: Text(area.name),
              trailing: area.isDefault
                  ? Tooltip(
                      message: l10n.get('cannot_delete_default_area'),
                      child: Icon(Icons.lock_outline_rounded, color: Colors.grey.withOpacity(0.6)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                      onPressed: () => _deleteArea(area),
                    ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('manage_areas')),
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
