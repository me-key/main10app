import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages global trial configuration stored in `config/trial` Firestore document.
///
/// The config document schema:
/// {
///   "defaultTrialDays": 7,       // int — default trial length for new orgs
///   "contactEmail": "support@maintens.com"  // string — shown to expired users
/// }
class TrialService {
  static const _configCollection = 'config';
  static const _trialDocId = 'trial';

  static const int _fallbackTrialDays = 7;
  static const String _fallbackContactEmail = 'support@maintens.com';

  final FirebaseFirestore? _firestore;

  TrialService() : _firestore = _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  /// Returns the current trial configuration map.
  /// Falls back to defaults if Firestore is unavailable.
  Future<Map<String, dynamic>> getTrialConfig() async {
    if (_firestore == null) {
      return {
        'defaultTrialDays': _fallbackTrialDays,
        'contactEmail': _fallbackContactEmail,
      };
    }
    try {
      final doc = await _firestore!
          .collection(_configCollection)
          .doc(_trialDocId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'defaultTrialDays': data['defaultTrialDays'] ?? _fallbackTrialDays,
          'contactEmail': data['contactEmail'] ?? _fallbackContactEmail,
        };
      }
    } catch (e) {
      print('TrialService: Failed to fetch trial config: $e');
    }
    return {
      'defaultTrialDays': _fallbackTrialDays,
      'contactEmail': _fallbackContactEmail,
    };
  }

  /// Returns just the contact email from config.
  Future<String> getContactEmail() async {
    final config = await getTrialConfig();
    return config['contactEmail'] as String? ?? _fallbackContactEmail;
  }

  /// Returns just the default trial days from config.
  Future<int> getDefaultTrialDays() async {
    final config = await getTrialConfig();
    return config['defaultTrialDays'] as int? ?? _fallbackTrialDays;
  }

  /// Updates global trial configuration. Super admin only.
  Future<void> setTrialConfig({
    int? defaultTrialDays,
    String? contactEmail,
  }) async {
    if (_firestore == null) throw Exception('Firestore not available');
    final data = <String, dynamic>{};
    if (defaultTrialDays != null) data['defaultTrialDays'] = defaultTrialDays;
    if (contactEmail != null) data['contactEmail'] = contactEmail;
    if (data.isEmpty) return;

    await _firestore!
        .collection(_configCollection)
        .doc(_trialDocId)
        .set(data, SetOptions(merge: true));
  }

  /// Computes a trial end date from now + [days].
  DateTime computeTrialEndDate({required int days}) {
    return DateTime.now().add(Duration(days: days));
  }

  /// Stream of the trial config document for real-time updates in UI.
  Stream<Map<String, dynamic>> get trialConfigStream {
    if (_firestore == null) return Stream.value({});
    return _firestore!
        .collection(_configCollection)
        .doc(_trialDocId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'defaultTrialDays': _fallbackTrialDays,
          'contactEmail': _fallbackContactEmail,
        };
      }
      final data = doc.data()!;
      return {
        'defaultTrialDays': data['defaultTrialDays'] ?? _fallbackTrialDays,
        'contactEmail': data['contactEmail'] ?? _fallbackContactEmail,
      };
    });
  }
}
