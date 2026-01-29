import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String? photoUrl;
  final String reporterName;
  final String reporterPhone;
  final String location;
  final String status; // 'open', 'assigned', 'in_progress', 'closed', 'archived'
  final String reporterId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.title,
    required this.description,
    this.photoUrl,
    required this.reporterName,
    required this.reporterPhone,
    required this.location,
    required this.status,
    required this.reporterId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      reporterName: data['reporterName'] ?? '',
      reporterPhone: data['reporterPhone'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'open',
      reporterId: data['reporterId'] ?? '',
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'location': location,
      'status': status,
      'reporterId': reporterId,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Report copyWith({
    String? title,
    String? description,
    String? photoUrl,
    String? reporterName,
    String? reporterPhone,
    String? location,
    String? status,
    String? assignedTo,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      location: location ?? this.location,
      status: status ?? this.status,
      reporterId: reporterId, // Should not change
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt, // Should not change
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
