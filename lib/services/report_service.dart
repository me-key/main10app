import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'package:flutter/foundation.dart';


class ReportService {
  final FirebaseFirestore? _firestore;
  final String _collection = 'reports';

  ReportService() : _firestore = _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // Create
  Future<void> createReport(Report report) async {
    if (_firestore == null) throw Exception("Backend not available");
    String id = report.id.isEmpty ? _firestore!.collection(_collection).doc().id : report.id;
    
    await _firestore!.collection(_collection).doc(id).set(
      report.toMap()..addAll({'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()})
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Report submission timed out. Please check your connection.'),
    );
  }

  // Read (All reports for Manager/Admin - Filtered & Limited)
  Stream<List<Report>> getReports({String? status, int limit = 50}) {
    debugPrint('📊 getReports called (status=$status, limit=$limit)');
    if (_firestore == null) return Stream.value([]);
    
    Query query = _firestore!.collection(_collection);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    
    // Temporarily removing orderBy when status is filtered to bypass index requirement
    if (status == null || status == 'all') {
      query = query.orderBy('createdAt', descending: true);
    }

    return query
        .limit(limit)
        .snapshots()
        .handleError((error) {
          debugPrint('🔴 Stream error in getReports: $error');
          if (error is FirebaseException) {
            debugPrint('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
          }
        })
        .map((snapshot) {
          debugPrint('📦 Manager Snapshot received: ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList();
        });
  }

  // // Read (Reporter's reports)
  // Stream<List<Report>> getReportsForReporter(String uid, {int limit = 50}) {
  //   if (_firestore == null) return Stream.value([]);
  //   return _firestore!
  //       .collection(_collection)
  //       .where('reporterId', isEqualTo: uid)
  //       .orderBy('createdAt', descending: true)
  //       .limit(limit)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList());
  // }

    // Read (Reporter's reports)
  Stream<List<Report>> getReportsForReporter(
    String uid, {
    int limit = 50,
  }) {
    if (_firestore == null) return const Stream.empty();

    return _firestore!
        .collection(_collection)
        .where('reporterId', isEqualTo: uid)
        .where('status', isNotEqualTo: 'archived')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          if (error is FirebaseException) {
            debugPrint('🔥 FIRESTORE ERROR: ${error.message}');
          } else {
            debugPrint('🔥 ERROR: $error');
          }
        })
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList(),
        );
  }



// Read (Assigned reports for Maintainer)
Stream<List<Report>> getReportsForMaintainer(
  String uid, {
  int limit = 50,
}) {
  debugPrint('🟢 getReportsForMaintainer called (uid=$uid, limit=$limit)');

  if (_firestore == null) {
    debugPrint('⚠️ Firestore is null, returning empty stream');
    return const Stream.empty();
  }

  return _firestore!
      .collection(_collection)
      .where('assignedTo', isEqualTo: uid)
      .limit(limit)
      .snapshots()
      .handleError((error) {
        debugPrint('🔴 Stream error in getReportsForMaintainer: $error');
        if (error is FirebaseException) {
          debugPrint('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
        }
      })
      .map((snapshot) {
        debugPrint(
          '📦 Snapshot received: ${snapshot.docs.length} documents',
        );

        final reports = snapshot.docs
            .map((doc) => Report.fromSnapshot(doc))
            .toList();

        debugPrint('✅ Mapped to ${reports.length} Report objects');

        return reports;
      });
}
  
  // Read (Filtered by status)
  Stream<List<Report>> getReportsByStatus(String status) {
     if (_firestore == null) return Stream.value([]);
     return _firestore!
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Report.fromSnapshot(doc)).toList());
  }

  // Update
  Future<void> updateReport(String id, Map<String, dynamic> data) async {
    if (_firestore == null) throw Exception("Backend not available");
    await _firestore!.collection(_collection).doc(id).update(
      data..addAll({'updatedAt': FieldValue.serverTimestamp()})
    );
  }
}
