import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization.dart';
import 'trial_service.dart';

class OrganizationService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'organizations';

  OrganizationService() : _firestore = _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Get all organizations (Admin only)
  Stream<List<Organization>> getAllOrganizations({int limit = 50}) {
    if (_firestore == null) return Stream.value([]);
    return _firestore!
        .collection(_collection)
        .orderBy('name')
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Organization.fromSnapshot(doc)).toList());
  }

  // Get specific organization
  Future<Organization?> getOrganization(String id) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Organization.fromSnapshot(doc);
  }

  // Get organization by email domain
  Future<Organization?> getOrganizationByDomain(String domain) async {
    if (_firestore == null) return null;
    final snapshot = await _firestore!
        .collection(_collection)
        .where('emailDomain', isEqualTo: domain)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Organization.fromSnapshot(snapshot.docs.first);
  }

  // Create new organization — automatically sets trialEndsAt from global config
  Future<String> createOrganization(Organization org) async {
    if (_firestore == null) throw Exception("Backend not available");

    // Fetch trial config to determine the trial end date
    final trialService = TrialService();
    final trialConfig = await trialService.getTrialConfig();
    final trialDays = org.trialDurationDays ?? (trialConfig['defaultTrialDays'] as int? ?? 7);
    final trialEndsAt = DateTime.now().add(Duration(days: trialDays));

    final orgMap = org.toMap()
      ..addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'trialEndsAt': Timestamp.fromDate(trialEndsAt),
        'trialDurationDays': trialDays,
      });

    final docRef = await _firestore!.collection(_collection).add(orgMap);
    return docRef.id;
  }

  // Update organization
  Future<void> updateOrganization(String id, Map<String, dynamic> data) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).update(data);
  }

  // Update trial settings for a specific org (super admin)
  Future<void> updateOrgTrial(String id, {
    DateTime? trialEndsAt,
    int? trialDurationDays,
  }) async {
    if (_firestore == null) throw Exception("Backend not available");
    final data = <String, dynamic>{};
    if (trialEndsAt != null) {
      data['trialEndsAt'] = Timestamp.fromDate(trialEndsAt);
    }
    if (trialDurationDays != null) {
      data['trialDurationDays'] = trialDurationDays;
    }
    if (data.isEmpty) return;
    await _firestore!.collection(_collection).doc(id).update(data);
  }

  // Delete organization (with validation)
  Future<void> deleteOrganization(String id) async {
    if (_firestore == null) throw Exception("Backend not available");
    
    // Check if organization has users
    final usersSnapshot = await _firestore!
        .collection('users')
        .where('organizationId', isEqualTo: id)
        .limit(1)
        .get();
    
    if (usersSnapshot.docs.isNotEmpty) {
      throw Exception(
          "Cannot delete organization with existing users. Please reassign or delete users first.");
    }
    
    // Check if organization has reports
    final reportsSnapshot = await _firestore!
        .collection('reports')
        .where('organizationId', isEqualTo: id)
        .limit(1)
        .get();
    
    if (reportsSnapshot.docs.isNotEmpty) {
      throw Exception(
          "Cannot delete organization with existing reports. Please archive or delete reports first.");
    }
    
    await _firestore!.collection(_collection).doc(id).delete();
  }
}
