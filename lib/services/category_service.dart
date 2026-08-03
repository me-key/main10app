import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'categories';

  CategoryService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Get all categories in organization, ordered by manager-defined sortOrder
  // (falling back to name for categories that predate manual ordering).
  Stream<List<Category>> getCategories(String organizationId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs.map((doc) => Category.fromSnapshot(doc)).toList();
      categories.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        return orderCompare != 0 ? orderCompare : a.name.compareTo(b.name);
      });
      return categories;
    });
  }

  // Add a new category to organization
  Future<void> addCategory(String name, String organizationId, {int? sortOrder}) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).add({
      'name': name,
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
      'isDefault': false,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).delete();
  }

  // Persist a manager's drag-and-drop reorder as sequential sortOrder values
  Future<void> reorderCategories(List<Category> orderedCategories) async {
    if (_firestore == null) throw Exception("Backend not available");
    final batch = _firestore!.batch();
    for (var i = 0; i < orderedCategories.length; i++) {
      batch.update(_firestore!.collection(_collection).doc(orderedCategories[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }

  // Guarantees the protected "Other" default category exists for an organization.
  // Self-heals orgs created before this feature shipped (no-op if it already exists).
  Future<void> ensureDefaultCategory(String organizationId) async {
    if (_firestore == null) return;
    final existing = await _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _firestore!.collection(_collection).add({
      'name': 'Other',
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
      'sortOrder': -1,
      'isDefault': true,
    });
  }
}
