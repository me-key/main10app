import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String reportId;
  final String userId;
  final String userName;
  final String action; // e.g., 'created', 'assigned', 'status_changed', 'archived'
  final String details; // Descriptive text of what happened
  final DateTime timestamp;
  final String organizationId;

  AuditLog({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.organizationId,
  });

  factory AuditLog.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      reportId: data['reportId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      action: data['action'] ?? '',
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      organizationId: data['organizationId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'userName': userName,
      'action': action,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'organizationId': organizationId,
    };
  }
}
