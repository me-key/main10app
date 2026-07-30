import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String id;
  final String name;
  final DateTime createdAt;
  final String organizationId;
  final int sortOrder;

  Location({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.organizationId,
    this.sortOrder = -1,
  });

  factory Location.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Location(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      organizationId: data['organizationId'] ?? '',
      sortOrder: data['sortOrder'] ?? -1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'organizationId': organizationId,
      'sortOrder': sortOrder,
    };
  }
}
