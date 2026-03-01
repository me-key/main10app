import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

class AuditService {
  final FirebaseFirestore? _firestore;

  AuditService({FirebaseFirestore? firestore}) : _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Collection reference for audit logs nested under reports
  CollectionReference? _getAuditLogsRef(String reportId) {
    if (_firestore == null) return null;
    return _firestore!.collection('reports').doc(reportId).collection('audit_logs');
  }

  // Log an action
  Future<void> logAction({
    required String reportId,
    required String userId,
    required String userName,
    required String action,
    required String details,
    required String organizationId,
  }) async {
    try {
      if (_firestore == null) return;
      
      final auditLog = AuditLog(
        id: '',
        reportId: reportId,
        userId: userId,
        userName: userName,
        action: action,
        details: details,
        timestamp: DateTime.now(),
        organizationId: organizationId,
      );

      final ref = _getAuditLogsRef(reportId);
      if (ref != null) {
        await ref.add(auditLog.toMap());
      }
    } catch (e) {
      print('Error logging audit action: $e');
    }
  }

  // Get audit logs for a report
  Stream<List<AuditLog>> getAuditLogs(String reportId) {
    final ref = _getAuditLogsRef(reportId);
    if (ref == null) return Stream.value([]);
    
    return ref
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AuditLog.fromSnapshot(doc)).toList();
    });
  }
}
