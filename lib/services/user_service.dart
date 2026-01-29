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

  // Get all users (Admin) - Limited
  Stream<List<UserProfile>> getAllUsers({int limit = 50}) {
    if (_firestore == null) return Stream.value([]);
    return _firestore!.collection(_collection).limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Get Maintainers (Manager) - Limited
  Stream<List<UserProfile>> getMaintainers({int limit = 50}) {
     if (_firestore == null) return Stream.value([]);
     return _firestore!.collection(_collection)
         .where('role', isEqualTo: 'maintainer')
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

  // Update User Profile (Admin)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collection).doc(uid).update(data);
  }

  // Delete User Profile (Admin)
  Future<void> deleteUser(String uid) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collection).doc(uid).delete();
  }
}
