const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Create a Firestore profile doc when a new user signs up
exports.createUserDoc = functions.auth.user().onCreate(async (user) => {
  const userDoc = {
    uid: user.uid,
    email: user.email || null,
    displayName: user.displayName || null,
    role: 'regular',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await db.collection('users').doc(user.uid).set(userDoc);
  return null;
});

// When the users/{uid} doc role field changes, set a custom claim
exports.onUserRoleChange = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const uid = context.params.uid;

    if (!before || !after) return null;

    const prevRole = before.role;
    const newRole = after.role;

    if (prevRole !== newRole) {
      if (newRole === 'staff') {
        await admin.auth().setCustomUserClaims(uid, { role: 'staff' });
      } else {
        await admin.auth().setCustomUserClaims(uid, { role: 'regular' });
      }
    }
    return null;
  });
