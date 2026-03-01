# System Architecture - FixIt-Pro

## Overview
FixIt-Pro is a maintenance reporting application built with Flutter and Firebase. It supports multi-role access control for Reporters, Maintainers, Managers, and Admins.

## Technology Stack
- **Frontend**: Flutter (Material 3)
- **Backend/Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage (for report images)
- **State Management**: Provider

## Data Models

### User Profile (`users` collection)
- `uid`: Unique identifier from Firebase Auth
- `email`: User's email
- `displayName`: User's full name
- `role`: One of `reporter`, `maintainer`, `manager`, `admin`
- `phoneNumber`: Contact information

### Report (`reports` collection)
- `id`: Document ID
- `title`: Short summary of the issue
- `description`: Detailed explanation
- `location`: **[UPDATED]** Selection from predefined Locations
- `status`: `open`, `assigned`, `in_progress`, `closed`, `archived`
- `reporterId`: Reference to user
- `assignedTo`: Reference to maintainer (nullable)
- `imageUrls`: List of links to Firebase Storage
- `reportDateTime`: User-selected time of incident

### Location (`locations` collection)
- `id`: Document ID
- `name`: Name of the area (e.g., "Room 101", "Parking Lot")
- `createdAt`: Timestamp

## Security & Access Control
Security is enforced at the Firestore level using `firestore.rules`. Roles are retrieved from the `/users/{uid}` document.

- **Reporters**: Can create reports and view their own reports.
- **Maintainers**: Can view reports assigned to them and update status to `in_progress` or `closed`.
- **Managers**: Can view all reports, assign maintainers, and archive reports. Can manage predefined Locations.
- **Admins**: Full access to all data, including user management and impersonation.

## Key Workflows
1. **Reporting**: User selects a location from the manager-defined list, provides details and photos.
2. **Assignment**: Manager reviews open reports and assigns them to a Maintainer.
3. **Resolution**: Maintainer works on the issue and marks it as closed.
4. **Archiving**: Manager archives closed reports for record keeping.
