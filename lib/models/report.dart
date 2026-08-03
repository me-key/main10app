import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String category;
  final String title;
  final String description;
  final String? photoUrl;
  final List<String> imageUrls;
  final String reporterName;
  final String reporterPhone;
  final String reporterEmail;
  final String area;
  final String location;
  final bool authorizeEntryWithoutPresence;
  final String status; // 'open', 'assigned', 'in_progress', 'closed', 'archived'
  final String reporterId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime reportDateTime;
  final String? managerComments;
  final String? onHoldReason;
  final String organizationId;

  Report({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.photoUrl,
    this.imageUrls = const [],
    required this.reporterName,
    required this.reporterPhone,
    this.reporterEmail = '',
    required this.area,
    required this.location,
    required this.authorizeEntryWithoutPresence,
    required this.status,
    required this.reporterId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.reportDateTime,
    this.managerComments,
    this.onHoldReason,
    required this.organizationId,
  });

  factory Report.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      category: data['category'] ?? 'Other',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      reporterName: data['reporterName'] ?? '',
      reporterPhone: data['reporterPhone'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      area: data['area'] ?? '',
      location: data['location'] ?? '',
      authorizeEntryWithoutPresence: data['authorizeEntryWithoutPresence'] ?? false,
      status: data['status'] ?? 'open',
      reporterId: data['reporterId'] ?? '',
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      reportDateTime: (data['reportDateTime'] as Timestamp? ?? data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      managerComments: data['managerComments'],
      onHoldReason: data['onHoldReason'],
      organizationId: data['organizationId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'imageUrls': imageUrls,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'reporterEmail': reporterEmail,
      'area': area,
      'location': location,
      'authorizeEntryWithoutPresence': authorizeEntryWithoutPresence,
      'status': status,
      'reporterId': reporterId,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reportDateTime': Timestamp.fromDate(reportDateTime),
      'managerComments': managerComments,
      'onHoldReason': onHoldReason,
      'organizationId': organizationId,
    };
  }

  Report copyWith({
    String? category,
    String? title,
    String? description,
    String? photoUrl,
    List<String>? imageUrls,
    String? reporterName,
    String? reporterPhone,
    String? reporterEmail,
    String? area,
    String? location,
    bool? authorizeEntryWithoutPresence,
    String? status,
    String? assignedTo,
    DateTime? updatedAt,
    DateTime? reportDateTime,
    String? managerComments,
    String? onHoldReason,
  }) {
    return Report(
      id: id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      area: area ?? this.area,
      location: location ?? this.location,
      authorizeEntryWithoutPresence: authorizeEntryWithoutPresence ?? this.authorizeEntryWithoutPresence,
      status: status ?? this.status,
      reporterId: reporterId, // Should not change
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt, // Should not change
      updatedAt: updatedAt ?? this.updatedAt,
      reportDateTime: reportDateTime ?? this.reportDateTime,
      managerComments: managerComments ?? this.managerComments,
      onHoldReason: onHoldReason ?? this.onHoldReason,
      organizationId: organizationId, // Should not change
    );
  }
}
