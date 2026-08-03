import 'package:cloud_firestore/cloud_firestore.dart';

class Area {
  final String id;
  final String name;
  final DateTime createdAt;
  final String organizationId;
  final int sortOrder;
  final bool isDefault;

  Area({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.organizationId,
    this.sortOrder = -1,
    this.isDefault = false,
  });

  factory Area.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Area(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      organizationId: data['organizationId'] ?? '',
      sortOrder: data['sortOrder'] ?? -1,
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'organizationId': organizationId,
      'sortOrder': sortOrder,
      'isDefault': isDefault,
    };
  }
}
