import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/area.dart';

class AreaService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'areas';

  AreaService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Get all areas in organization, ordered by manager-defined sortOrder
  // (falling back to name for areas that predate manual ordering).
  Stream<List<Area>> getAreas(String organizationId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
      final areas = snapshot.docs.map((doc) => Area.fromSnapshot(doc)).toList();
      areas.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        return orderCompare != 0 ? orderCompare : a.name.compareTo(b.name);
      });
      return areas;
    });
  }

  // Add a new area to organization
  Future<void> addArea(String name, String organizationId, {int? sortOrder}) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).add({
      'name': name,
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
      'isDefault': false,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
  }

  // Delete an area
  Future<void> deleteArea(String id) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).delete();
  }

  // Persist a manager's drag-and-drop reorder as sequential sortOrder values
  Future<void> reorderAreas(List<Area> orderedAreas) async {
    if (_firestore == null) throw Exception("Backend not available");
    final batch = _firestore!.batch();
    for (var i = 0; i < orderedAreas.length; i++) {
      batch.update(_firestore!.collection(_collection).doc(orderedAreas[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }

  // Guarantees the protected "Unassigned" default area exists for an organization,
  // and returns its id. Self-heals orgs created before this feature shipped.
  Future<String> ensureDefaultArea(String organizationId) async {
    if (_firestore == null) return '';
    final existing = await _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final docRef = await _firestore!.collection(_collection).add({
      'name': 'Unassigned',
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
      'sortOrder': -1,
      'isDefault': true,
    });
    return docRef.id;
  }
}
