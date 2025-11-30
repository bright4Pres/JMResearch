# Firebase Configuration

This directory contains Firebase configuration files for the project.

## Files

- `firestore.rules` - Security rules for Firestore database
- `firestore.indexes.json` - Composite index definitions for Firestore queries

## Deployment

Deploy these files using:

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy both
firebase deploy --only firestore
```

## Security Rules Summary

The Firestore rules prevent clients from writing to the `role` field and allow:
- Users to read/write their own profile documents
- Staff users to read all user documents
- Only staff users to delete user documents

## Indexes

Composite indexes are defined for efficient queries. The indexes will be created automatically when deployed.