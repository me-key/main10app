import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final String? emailDomain;

  Organization({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isActive = true,
    this.emailDomain,
  });

  factory Organization.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isActive: data['isActive'] ?? true,
      emailDomain: data['emailDomain'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'emailDomain': emailDomain,
    };
  }

  Organization copyWith({
    String? name,
    String? description,
    DateTime? createdAt,
    bool? isActive,
    String? emailDomain,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      emailDomain: emailDomain ?? this.emailDomain,
    );
  }
}
