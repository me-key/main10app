// Migration script to backfill the new "category" field on existing reports
// Run this ONCE after deploying the category feature.
// Every report created before this feature shipped has no "category" field;
// this sets them all to the default "Other" category.

/*
MANUAL MIGRATION INSTRUCTIONS:

Since this is a Flutter app, the easiest way to run this migration is either:

1. Temporarily call `backfillReportCategories(FirebaseFirestore.instance)`
   from a debug/admin screen in the app and trigger it once, or
2. Run the equivalent update via the Firebase Console / Admin SDK:
   - Go to "reports" collection
   - For each report document missing a "category" field, add:
     * category: "Other"
*/

import 'package:cloud_firestore/cloud_firestore.dart';

/// This function can be called from within the Flutter app
/// (e.g. a temporary button on an admin screen) to run the migration.
/// Returns the number of report documents that were backfilled.
Future<int> backfillReportCategories(FirebaseFirestore firestore) async {
  print('🚀 Starting report category backfill...');

  try {
    print('\n📋 Scanning reports for missing "category" field...');
    final reportsSnapshot = await firestore.collection('reports').get();
    int reportCount = 0;

    final batch = firestore.batch();
    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();
      if (data['category'] == null) {
        batch.update(doc.reference, {'category': 'Other'});
        reportCount++;
      }
    }
    await batch.commit();

    print('✅ Backfilled $reportCount reports with category "Other"');
    print('\n🎉 Backfill completed successfully!');
    return reportCount;
  } catch (e) {
    print('\n❌ Backfill failed: $e');
    rethrow;
  }
}
