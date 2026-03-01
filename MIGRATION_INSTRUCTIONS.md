# Migration Instructions

## Problem
The migration script is failing because the current security rules require `organizationId` to be present on all documents, but the existing data doesn't have this field yet. This creates a chicken-and-egg problem.

## Solution: Temporary Permissive Rules

Follow these steps to successfully run the migration:

### Step 1: Deploy Temporary Permissive Rules

```bash
# Backup current rules (already done - they're in firestore.rules)
# Deploy temporary permissive rules
cp firestore.rules.migration firestore.rules
firebase deploy --only firestore:rules
```

The temporary rules allow admins to read/write all collections without organizationId checks.

### Step 2: Run the Migration

1. Log in to the app as an admin
2. Click the 🔄 (sync) button in the admin home screen
3. Click "Run Migration"
4. Wait for completion

### Step 3: Restore Strict Security Rules

After the migration completes successfully:

```bash
# Restore the strict rules
cp firestore.rules.strict firestore.rules
firebase deploy --only firestore:rules
```

### Step 4: Verify

Test the app to ensure:
- Data is properly scoped by organization
- Users can only see data from their organization
- Security rules are enforced

## Files

- `firestore.rules.migration` - Temporary permissive rules for migration
- `firestore.rules.strict` - Final strict rules with full organization isolation
- `firestore.rules` - Currently active rules (will be overwritten during this process)
