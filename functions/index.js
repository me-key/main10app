const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Setup Nodemailer transporter (SMTP)
// For Gmail, you might need to use App Passwords
// For other providers, use their SMTP settings
// These should ideally be set via environment
// variables (firebase functions:secrets:set)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "YOUR_GMAIL@gmail.com", // Replace or use secrets
    pass: "YOUR_APP_PASSWORD", // Replace or use secrets
  },
});

/**
 * Helper to send notifications via FCM and Email.
 * @param {string} userId
 * @param {string} title
 * @param {string} body
 * @param {string} eventKey
 * @param {object} data
 */
async function sendNotification(userId, title, body, eventKey, data = {}) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  if (!userDoc.exists) return;

  const userData = userDoc.data();
  const prefs = userData.notificationPreferences || {
    pushEnabled: true,
    emailEnabled: true,
    events: {},
  };

  // Check if notification for this event is enabled
  if (prefs.events && prefs.events[eventKey] === false) {
    console.log(`Notification for ${eventKey} is disabled for user ${userId}`);
    return;
  }

  // Send Push Notification
  if (prefs.pushEnabled && userData.fcmToken) {
    const message = {
      notification: {title, body},
      data: data,
      token: userData.fcmToken,
    };
    try {
      await admin.messaging().send(message);
      console.log(`Push sent to ${userId}`);
    } catch (e) {
      console.error(`Error sending push: ${e}`);
    }
  }

  // Send Email
  if (prefs.emailEnabled && userData.email) {
    const mailOptions = {
      from: "\"Maintens\" <noreply@maintens.com>",
      to: userData.email,
      subject: title,
      text: body,
      html: `<p>${body}</p>`,
    };
    try {
      await transporter.sendMail(mailOptions);
      console.log(`Email sent to ${userData.email}`);
    } catch (e) {
      console.error(`Error sending email: ${e}`);
    }
  }
}

// Triggers
exports.onReportCreated = functions.firestore
    .document("reports/{reportId}")
    .onCreate(async (snapshot, context) => {
      const report = snapshot.data();
      const orgId = report.organizationId;

      // Find all managers and testers in this organization
      const recipients = await admin.firestore()
          .collection("users")
          .where("organizationId", "==", orgId)
          .where("role", "in", ["manager", "tester"])
          .get();

      const promises = recipients.docs.map((doc) =>
        sendNotification(
            doc.id,
            "New Report Submitted",
            `A new report "${report.title}" submitted at ${report.location}.`,
            "new_report",
            {reportId: context.params.reportId},
        ),
      );

      return Promise.all(promises);
    });

exports.onReportUpdated = functions.firestore
    .document("reports/{reportId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      const statusChanged = before.status !== after.status;
      const assignedChanged = before.assignedTo !== after.assignedTo;
      const commentsChanged = before.managerComments !== after.managerComments;

      if (!statusChanged && !assignedChanged && !commentsChanged) {
        return null;
      }

      const promises = [];
      const orgId = after.organizationId;

      // Notify Maintainer if assigned
      if (after.assignedTo) {
        if (assignedChanged || statusChanged) {
          if (after.status === "assigned") {
            promises.push(sendNotification(
                after.assignedTo,
                "New Task Assigned",
                `You have been assigned a new task: "${after.title}".`,
                "report_assigned",
                {reportId: context.params.reportId},
            ));
          }
        }

        // Notify Maintainer on new comment
        if (commentsChanged && after.managerComments) {
          promises.push(sendNotification(
              after.assignedTo,
              "New Manager Comment",
              `A new comment added to task: "${after.title}".`,
              "report_commented",
              {reportId: context.params.reportId},
          ));
        }
      }

      // Notify Reporter on status changes
      if (statusChanged) {
        let statusMsg = "";
        let eventKey = "";
        switch (after.status) {
          case "in_progress":
            statusMsg = "is now in progress";
            eventKey = "report_in_progress";
            break;
          case "on_hold":
            statusMsg = "is on hold";
            eventKey = "report_on_hold";
            break;
          case "closed":
            statusMsg = "has been resolved";
            eventKey = "report_resolved";
            break;
          case "archived":
            statusMsg = "has been archived";
            eventKey = "report_archived";
            break;
        }

        if (statusMsg) {
          promises.push(sendNotification(
              after.reporterId,
              "Report Status Updated",
              `Your report "${after.title}" ${statusMsg}.`,
              eventKey,
              {reportId: context.params.reportId},
          ));
        }
      }

      // ALWAYS notify Testers on any report update
      const testers = await admin.firestore()
          .collection("users")
          .where("organizationId", "==", orgId)
          .where("role", "==", "tester")
          .get();

      testers.docs.forEach((doc) => {
        // Avoid duplicate if tester is also reporter/maintainer
        if (doc.id !== after.reporterId && doc.id !== after.assignedTo) {
          promises.push(sendNotification(
              doc.id,
              "Report Updated (Tester Alert)",
              `Report "${after.title}" updated (Status: ${after.status}).`,
              "report_updated", // Custom event for testers
              {reportId: context.params.reportId},
          ));
        }
      });

      return Promise.all(promises);
    });

exports.onUserCreated = functions.firestore
    .document("users/{userId}")
    .onCreate(async (snapshot, context) => {
      const user = snapshot.data();
      if (user.isApproved) return null;

      // Notify Org Admins and Testers
      const recipients = await admin.firestore()
          .collection("users")
          .where("organizationId", "==", user.organizationId)
          .where("role", "in", ["admin", "tester"])
          .get();

      const promises = recipients.docs.map((doc) =>
        sendNotification(
            doc.id,
            "User Pending Approval",
            `User ${user.displayName} is pending approval.`,
            "user_pending_approval",
            {userId: context.params.userId},
        ),
      );

      return Promise.all(promises);
    });

exports.onUserUpdated = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      if (!before.isApproved && after.isApproved) {
        return sendNotification(
            context.params.userId,
            "Account Approved",
            "Your Maintens account has been approved.",
            "user_approved",
        );
      }

      return null;
    });

exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated users can delete accounts.",
    );
  }
  const uidToDelete = data.uid;
  try {
    await admin.auth().deleteUser(uidToDelete);
    await admin.firestore().collection("users").doc(uidToDelete).delete();
    return {result: `Successfully deleted user: ${uidToDelete}`};
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
