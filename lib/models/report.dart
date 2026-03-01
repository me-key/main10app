import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String? photoUrl;
  final List<String> imageUrls;
  final String reporterName;
  final String reporterPhone;
  final String location;
  final String status; // 'open', 'assigned', 'in_progress', 'closed', 'archived'
  final String reporterId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime reportDateTime;
  final String? managerComments;
  final String organizationId;

  Report({
    required this.id,
    required this.title,
    required this.description,
    this.photoUrl,
    this.imageUrls = const [],
    required this.reporterName,
    required this.reporterPhone,
    required this.location,
    required this.status,
    required this.reporterId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.reportDateTime,
    this.managerComments,
    required this.organizationId,
  });

  factory Report.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      reporterName: data['reporterName'] ?? '',
      reporterPhone: data['reporterPhone'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'open',
      reporterId: data['reporterId'] ?? '',
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      reportDateTime: (data['reportDateTime'] as Timestamp? ?? data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      managerComments: data['managerComments'],
      organizationId: data['organizationId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'imageUrls': imageUrls,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'location': location,
      'status': status,
      'reporterId': reporterId,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reportDateTime': Timestamp.fromDate(reportDateTime),
      'managerComments': managerComments,
      'organizationId': organizationId,
    };
  }

  Report copyWith({
    String? title,
    String? description,
    String? photoUrl,
    List<String>? imageUrls,
    String? reporterName,
    String? reporterPhone,
    String? location,
    String? status,
    String? assignedTo,
    DateTime? updatedAt,
    DateTime? reportDateTime,
    String? managerComments,
  }) {
    return Report(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      location: location ?? this.location,
      status: status ?? this.status,
      reporterId: reporterId, // Should not change
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt, // Should not change
      updatedAt: updatedAt ?? this.updatedAt,
      reportDateTime: reportDateTime ?? this.reportDateTime,
      managerComments: managerComments ?? this.managerComments,
      organizationId: organizationId, // Should not change
    );
  }
}
