import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location.dart';

class LocationService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'locations';

  LocationService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Get locations in organization (optionally scoped to a single area), ordered
  // by manager-defined sortOrder (falling back to name for locations that
  // predate manual ordering).
  Stream<List<Location>> getLocations(String organizationId, {String? areaId}) {
    if (_firestore == null) return const Stream.empty();
    Query<Map<String, dynamic>> query = _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId);
    if (areaId != null) {
      query = query.where('areaId', isEqualTo: areaId);
    }
    return query.snapshots().map((snapshot) {
      final locations = snapshot.docs.map((doc) => Location.fromSnapshot(doc)).toList();
      locations.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        return orderCompare != 0 ? orderCompare : a.name.compareTo(b.name);
      });
      return locations;
    });
  }

  // Add a new location, scoped to the given area, to organization
  Future<void> addLocation(String name, String organizationId, String areaId, {int? sortOrder}) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).add({
      'name': name,
      'organizationId': organizationId,
      'areaId': areaId,
      'createdAt': FieldValue.serverTimestamp(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
  }

  // Self-heals locations created before the Area feature shipped by assigning
  // them to the organization's default ("Unassigned") area.
  Future<void> backfillLocationsMissingArea(String organizationId, String defaultAreaId) async {
    if (_firestore == null) return;
    final snapshot = await _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .get();

    final batch = _firestore!.batch();
    var needsCommit = false;
    for (final doc in snapshot.docs) {
      final areaId = doc.data()['areaId'] as String?;
      if (areaId == null || areaId.isEmpty) {
        batch.update(doc.reference, {'areaId': defaultAreaId});
        needsCommit = true;
      }
    }
    if (needsCommit) await batch.commit();
  }

  // Delete a location
  Future<void> deleteLocation(String id) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).delete();
  }

  // Persist a manager's drag-and-drop reorder as sequential sortOrder values
  Future<void> reorderLocations(List<Location> orderedLocations) async {
    if (_firestore == null) throw Exception("Backend not available");
    final batch = _firestore!.batch();
    for (var i = 0; i < orderedLocations.length; i++) {
      batch.update(_firestore!.collection(_collection).doc(orderedLocations[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }
}
