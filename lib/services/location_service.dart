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

  // Get all locations in organization, ordered by manager-defined sortOrder
  // (falling back to name for locations that predate manual ordering).
  Stream<List<Location>> getLocations(String organizationId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
      final locations = snapshot.docs.map((doc) => Location.fromSnapshot(doc)).toList();
      locations.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        return orderCompare != 0 ? orderCompare : a.name.compareTo(b.name);
      });
      return locations;
    });
  }

  // Add a new location to organization
  Future<void> addLocation(String name, String organizationId, {int? sortOrder}) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).add({
      'name': name,
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
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
