// Migration script to add organizationId to all existing data
// Run this ONCE after deploying the multi-tenancy changes
// This script will create a "test" organization and assign all existing data to it

// IMPORTANT: This script should be run from the Firebase Console or using Firebase Admin SDK
// For now, we'll provide instructions to run it manually via Firestore Console

/*
MANUAL MIGRATION INSTRUCTIONS:

Since this is a Flutter app, the easiest way to migrate data is through the Firebase Console:

1. Go to Firebase Console > Firestore Database
2. Create the "test" organization:
   - Click on "organizations" collection (create if doesn't exist)
   - Add document with ID: "test-org"
   - Fields:
     * name: "test"
     * description: "Default organization for existing data"
     * createdAt: (current timestamp)
     * isActive: true

3. Update all users:
   - Go to "users" collection
   - For each user document, add field:
     * organizationId: "test-org"

4. Update all reports:
   - Go to "reports" collection
   - For each report document, add field:
     * organizationId: "test-org"
   - For each report, go into its "audit_logs" subcollection
   - For each audit log, add field:
     * organizationId: "test-org"

5. Update all locations:
   - Go to "locations" collection
   - For each location document, add field:
     * organizationId: "test-org"

ALTERNATIVE: Use the Flutter app itself to run migration
You can also create a temporary admin screen in the app that runs this migration.
See the code below for the migration logic.
*/

import 'package:cloud_firestore/cloud_firestore.dart';

const String TEST_ORG_ID = 'test-org';
const String TEST_ORG_NAME = 'test';

/// This function can be called from within the Flutter app
/// Add a button in an admin screen to trigger this migration
Future<void> migrateToMultiTenancy(FirebaseFirestore firestore) async {
  print('🚀 Starting multi-tenancy migration...');
  
  try {
    // Step 1: Create the "test" organization
    print('\n📦 Step 1: Creating "test" organization...');
    await firestore.collection('organizations').doc(TEST_ORG_ID).set({
      'name': TEST_ORG_NAME,
      'description': 'Default organization for existing data',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    print('✅ Organization created successfully');

    // Step 2: Update all users
    print('\n👥 Step 2: Migrating users...');
    final usersSnapshot = await firestore.collection('users').get();
    int userCount = 0;
    
    final userBatch = firestore.batch();
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data['organizationId'] == null) {
        userBatch.update(doc.reference, {'organizationId': TEST_ORG_ID});
        userCount++;
      }
    }
    await userBatch.commit();
    print('✅ Migrated $userCount users');

    // Step 3: Update all reports and their audit logs
    print('\n📋 Step 3: Migrating reports...');
    final reportsSnapshot = await firestore.collection('reports').get();
    int reportCount = 0;
    
    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();
      if (data['organizationId'] == null) {
        await doc.reference.update({'organizationId': TEST_ORG_ID});
        reportCount++;
        
        // Also update audit logs for this report
        final auditLogsSnapshot = await doc.reference
            .collection('audit_logs')
            .get();
        
        final auditBatch = firestore.batch();
        for (var auditDoc in auditLogsSnapshot.docs) {
          final auditData = auditDoc.data();
          if (auditData['organizationId'] == null) {
            auditBatch.update(auditDoc.reference, {'organizationId': TEST_ORG_ID});
          }
        }
        await auditBatch.commit();
      }
    }
    print('✅ Migrated $reportCount reports and their audit logs');

    // Step 4: Update all locations
    print('\n📍 Step 4: Migrating locations...');
    final locationsSnapshot = await firestore.collection('locations').get();
    int locationCount = 0;
    
    final locationBatch = firestore.batch();
    for (var doc in locationsSnapshot.docs) {
      final data = doc.data();
      if (data['organizationId'] == null) {
        locationBatch.update(doc.reference, {'organizationId': TEST_ORG_ID});
        locationCount++;
      }
    }
    await locationBatch.commit();
    print('✅ Migrated $locationCount locations');

    print('\n🎉 Migration completed successfully!');
    print('📊 Summary:');
    print('   - Organization: 1 created');
    print('   - Users: $userCount migrated');
    print('   - Reports: $reportCount migrated');
    print('   - Locations: $locationCount migrated');
    
  } catch (e) {
    print('\n❌ Migration failed: $e');
    rethrow;
  }
}
