Deployment

1. Install dependencies and setup Firebase CLI:

   npm install

2. Log in and select project:

   firebase login
   firebase use --add

3. Deploy functions:

   firebase deploy --only functions

Notes
- This folder is a standard Cloud Functions for Firebase project (Node.js 18).
- The function `createUserDoc` will create a `users/{uid}` doc with default role `regular` on account creation.
- The function `onUserRoleChange` will set custom claims when an admin updates the `role` field in Firestore.
