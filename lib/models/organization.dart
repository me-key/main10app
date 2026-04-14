import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final String? emailDomain;
  /// When non-null, the date/time at which this org's trial expires.
  /// null means no trial is enforced (existing orgs default to this).
  final DateTime? trialEndsAt;
  /// Per-org override of the global default trial duration in days.
  final int? trialDurationDays;

  Organization({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isActive = true,
    this.emailDomain,
    this.trialEndsAt,
    this.trialDurationDays,
  });

  /// Returns true when a trial end date is set and it is in the past.
  bool get isTrialExpired =>
      trialEndsAt != null && DateTime.now().isAfter(trialEndsAt!);

  /// Returns the number of days remaining in the trial, or 0 if expired/no trial.
  int get trialDaysRemaining {
    if (trialEndsAt == null) return 0;
    final remaining = trialEndsAt!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  factory Organization.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isActive: data['isActive'] ?? true,
      emailDomain: data['emailDomain'],
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      trialDurationDays: data['trialDurationDays'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'emailDomain': emailDomain,
      'trialEndsAt': trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
      'trialDurationDays': trialDurationDays,
    };
  }

  Organization copyWith({
    String? name,
    String? description,
    DateTime? createdAt,
    bool? isActive,
    String? emailDomain,
    Object? trialEndsAt = _sentinel,
    int? trialDurationDays,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      emailDomain: emailDomain ?? this.emailDomain,
      trialEndsAt: trialEndsAt == _sentinel
          ? this.trialEndsAt
          : trialEndsAt as DateTime?,
      trialDurationDays: trialDurationDays ?? this.trialDurationDays,
    );
  }
}

// Sentinel value to allow explicit null in copyWith for trialEndsAt
const _sentinel = Object();
