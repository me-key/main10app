import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'users';

  UserService() : _firestore = _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Get all users in organization (Admin) - Limited
  Stream<List<UserProfile>> getAllUsers(String organizationId, {int limit = 50}) {
    if (_firestore == null) return Stream.value([]);
    return _firestore!
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Get Maintainers in organization (Manager) - Limited
  Stream<List<UserProfile>> getMaintainers(String organizationId, {int limit = 50}) {
     if (_firestore == null) return Stream.value([]);
     return _firestore!.collection(_collection)
         .where('organizationId', isEqualTo: organizationId)
         .where('role', isEqualTo: 'maintainer')
         .limit(limit)
         .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Get Reporters in organization (Manager) - Limited
  Stream<List<UserProfile>> getReporters(String organizationId, {int limit = 50}) {
     if (_firestore == null) return Stream.value([]);
     return _firestore!.collection(_collection)
         .where('organizationId', isEqualTo: organizationId)
         .where('role', isEqualTo: 'reporter')
         .limit(limit)
         .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();
    });
  }
  
  // Create/Update User Role (Admin)
  Future<void> updateUserRole(String uid, String newRole) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collection).doc(uid).update({'role': newRole});
  }

  // Update User Profile (Admin) - Prevents changing organizationId
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (_firestore == null) return;
    // Remove organizationId from data to prevent changes
    data.remove('organizationId');
    await _firestore!.collection(_collection).doc(uid).update(data);
  }

  // Get User Profile
  Future<UserProfile?> getUserProfile(String uid) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
  
  // Delete User Profile (Admin)
  Future<void> deleteUser(String uid) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collection).doc(uid).delete();
  }
}
