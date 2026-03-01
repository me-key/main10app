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

  // Get all locations in organization
  Stream<List<Location>> getLocations(String organizationId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Location.fromSnapshot(doc)).toList());
  }

  // Add a new location to organization
  Future<void> addLocation(String name, String organizationId) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).add({
      'name': name,
      'organizationId': organizationId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a location
  Future<void> deleteLocation(String id) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).delete();
  }
}
