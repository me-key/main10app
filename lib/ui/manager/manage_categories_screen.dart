import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/auth_service.dart';
import '../widgets/responsive_center.dart';
import '../../l10n/app_localizations.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _nameController = TextEditingController();
  String? _organizationId;
  bool _isLoading = true;

  StreamSubscription<List<Category>>? _categoriesSub;
  List<Category> _categories = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
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
        final categoryService = Provider.of<CategoryService>(context, listen: false);
        await categoryService.ensureDefaultCategory(_organizationId!);
        _subscribeToCategories();
      }
    }
  }

  // Categories are kept in local state (rather than a StreamBuilder) so drag-and-drop
  // reordering can update the UI immediately, ahead of the Firestore round-trip.
  void _subscribeToCategories() {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    _categoriesSub = categoryService.getCategories(_organizationId!).listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _categories = data;
          _categoriesLoading = false;
          _categoriesError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _categoriesError = e.toString();
          _categoriesLoading = false;
        });
      },
    );
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _organizationId == null) return;

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    try {
      await categoryService.addCategory(name, _organizationId!, sortOrder: _categories.length);
      _nameController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_adding_category')}: $e")),
        );
      }
    }
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    try {
      await categoryService.reorderCategories(_categories);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.get('error_reordering_category')}: $e")),
        );
      }
    }
  }

  void _showAddDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('add_new_category')),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.get('category_name_hint'),
            labelText: l10n.get('category_name_label'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: _addCategory,
            child: Text(l10n.get('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final l10n = AppLocalizations.of(context);
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('cannot_delete_default_category'))),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_category_title')),
        content: Text("${l10n.get('delete_category_confirm')} '${category.name}'?"),
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
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      try {
        await categoryService.deleteCategory(category.id);
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.get('error_deleting_category')}: $e")),
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
    if (_categoriesError != null) {
      debugPrint("Firestore Error in ManageCategoriesScreen: $_categoriesError");
      body = Center(child: Text("Error: $_categoriesError"));
    } else if (_categoriesLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_categories.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.get('no_categories_yet')),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.get('add_first_category')),
            ),
          ],
        ),
      );
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        itemCount: _categories.length,
        onReorder: _handleReorder,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Card(
            key: ValueKey(category.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_rounded),
              ),
              title: Text(category.name),
              trailing: category.isDefault
                  ? Tooltip(
                      message: l10n.get('cannot_delete_default_category'),
                      child: Icon(Icons.lock_outline_rounded, color: Colors.grey.withOpacity(0.6)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                      onPressed: () => _deleteCategory(category),
                    ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('manage_categories')),
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
