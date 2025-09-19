const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const { onCall } = require("firebase-functions/v2/https");


// Optional: set global options (you can rely on per-function region as well)
/// const { setGlobalOptions } = require("firebase-functions/v2");
/// setGlobalOptions({ region: "us-central1" });

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.sendPushNotification = onDocumentCreated(
  {
    region: "us-central1",
    document: "notifications/{notificationId}",
  },
  async (event) => {
    const snap = event.data;
    const data = snap.data() || {};

    // ---- Normalize required fields ----
    const title = data.title || "";
    const body = data.body || data.message || "";
    const imageUrl = data.imageUrl || "";
    const link = data.link || "";
    const badgeCount = Number.isFinite(Number(data.badge)) ? Number(data.badge) : 1;

    // Prefer `recipientUIDs` (array), but also support legacy keys.
    let recipients = [];
    if (Array.isArray(data.recipientUIDs) && data.recipientUIDs.length) {
      recipients = data.recipientUIDs;
    } else if (Array.isArray(data.recipients) && data.recipients.length) {
      recipients = data.recipients;
    } else if (Array.isArray(data.recipientUID) && data.recipientUID.length) {
      recipients = data.recipientUID;
    } else if (typeof data.recipientUID === "string" && data.recipientUID.trim()) {
      recipients = [data.recipientUID.trim()];
    }

    // Debug: log what we actually received (first few chars only for safety)
    console.log("🔎 sendPushNotification payload keys:", Object.keys(data));
    console.log("🔎 recipients:", recipients);

    if (!Array.isArray(recipients) || recipients.length === 0 || !title || !body) {
      console.error("❌ Missing required parameters in notification document", {
        hasTitle: !!title,
        hasBody: !!body,
        recipientsCount: Array.isArray(recipients) ? recipients.length : 0,
      });
      return null;
    }

    // ---- Collect tokens for all recipients ----
    const tokensToSend = [];

    for (const uid of recipients) {
      // Support both collections: 'tokens' (preferred) and legacy 'fcmTokens'
      const userDoc = admin.firestore().collection("users").doc(uid);

      const [tokensSnap, legacySnap] = await Promise.all([
        userDoc.collection("tokens").get(),
        userDoc.collection("fcmTokens").get().catch(() => ({ empty: true, forEach: () => {} })), // ignore error if collection doesn't exist
      ]);

      tokensSnap.forEach((doc) => {
        const token = doc.id;
        if (token) tokensToSend.push(token);
      });

      if (legacySnap && !legacySnap.empty) {
        legacySnap.forEach((doc) => {
          const token = doc.id;
          if (token) tokensToSend.push(token);
        });
      }
    }

    // De-duplicate tokens
    const uniqueTokens = [...new Set(tokensToSend)];
    if (uniqueTokens.length === 0) {
      console.log("ℹ️ No tokens found for recipients:", recipients);
      return null;
    }

    console.log(`📨 Will send to ${uniqueTokens.length} token(s).`);

    // ---- Build the base message parts ----
    const baseNotification = {
      title,
      body,
      ...(imageUrl && typeof imageUrl === "string" && imageUrl.startsWith("http") ? { imageUrl } : {}),
    };

    // Per-token send with result logging and pruning stale tokens
    const sendPromises = uniqueTokens.map((token) => {
      const message = {
        token,
        notification: baseNotification,
        data: {
          link,
          sound: "default",
          notificationId: String(data.notificationId || snap.id),
          type: String(data.type || ""),
          fromUID: String(data.fromUID || ""),
          relatedId: String(data.relatedId || ""),
        },
        apns: {
          payload: {
            aps: {
              badge: badgeCount,
              sound: "default",
            },
          },
        },
      };

      return admin
        .messaging()
        .send(message)
        .then((messageId) => ({ token, success: true, messageId }))
        .catch((error) => ({ token, success: false, error }));
    });

    const results = await Promise.all(sendPromises);

    let successCount = 0;
    const invalidTokens = [];

    results.forEach((r) => {
      if (r.success) {
        successCount++;
        console.log("✅ Sent", r.token.slice(0, 12) + "…", "msgId:", r.messageId);
      } else {
        const code = r.error?.code;
        console.warn("❌ Failed", r.token.slice(0, 12) + "…", code, r.error?.message);
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(r.token);
        }
      }
    });

    // Mark dead tokens under each known recipient (do NOT delete)
    if (invalidTokens.length) {
      console.log("🚩 Marking", invalidTokens.length, "invalid token(s) for recipients (keeping docs):", recipients);

      async function flagTokenForUID(uid, token, failure) {
        const userDoc = admin.firestore().collection("users").doc(uid);
        const refs = [
          userDoc.collection("tokens").doc(token),
          userDoc.collection("fcmTokens").doc(token),
        ];

        const updates = refs.map(async (ref) => {
          try {
            const snap = await ref.get();
            if (snap.exists) {
              await ref.set(
                {
                  disabled: true,                // <- soft-disable (keep token)
                  lastFailedAt: admin.firestore.FieldValue.serverTimestamp(),
                  lastFailureCode: failure?.code || "",
                  lastFailureMessage: failure?.message || "",
                  failureCount: admin.firestore.FieldValue.increment(1),
                },
                { merge: true }
              );
              console.log(`🚩 Flagged invalid token (kept) for uid=${uid} at ${ref.path}`);
            } else {
              // Create a doc to record the failure state for observability
              await ref.set(
                {
                  disabled: true,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  lastFailedAt: admin.firestore.FieldValue.serverTimestamp(),
                  lastFailureCode: failure?.code || "",
                  lastFailureMessage: failure?.message || "",
                  failureCount: 1,
                },
                { merge: true }
              );
              console.log(`🆕 Created flagged token doc for uid=${uid} at ${ref.path}`);
            }
          } catch (e) {
            console.warn(`⚠️ Failed flagging ${ref.path}:`, e.message);
          }
        });

        await Promise.all(updates);
      }

      for (const bad of invalidTokens) {
        // Find the failure object for this token from results (if present)
        const failure = results.find((r) => !r.success && r.token === bad)?.error || null;
        await Promise.all(recipients.map((uid) => flagTokenForUID(uid, bad, failure)));
      }

      // Optional: if you ever want to hard-delete instead, set an env var:
      // if (process.env.PRUNE_INVALID_TOKENS === "true") { ...delete logic here... }
    }

    console.log(`📤 Done. success=${successCount} fail=${results.length - successCount}`);
    return null;
  }
);

// --- createUserAndInvite ---
// Callable function to create (or fetch) a user by email and invite them to a team.
// Returns { email, uid, tempPassword, appDownloadURL }
exports.createUserAndInvite = onCall({ region: "us-central1" }, async (request) => {
  try {
    // Require auth
    if (!request.auth) {
      throw new Error("unauthenticated");
    }

    const body = request.data || {};
    const emailRaw = typeof body.email === "string" ? body.email : "";
    const teamId = typeof body.teamId === "string" ? body.teamId : "";
    const role = typeof body.role === "string" ? body.role : "member";

    const email = emailRaw.toLowerCase().trim();
    const allowedRoles = new Set(["owner", "admin", "member"]);

    if (!email || !teamId) {
      return { ok: false, code: "invalid-argument", message: "email and teamId are required" };
    }
    if (!allowedRoles.has(role)) {
      return { ok: false, code: "invalid-argument", message: "invalid role" };
    }

    // Optional: verify the team exists
    const teamRef = admin.firestore().collection("teams").doc(teamId);
    const teamSnap = await teamRef.get();
    if (!teamSnap.exists) {
      return { ok: false, code: "not-found", message: "team does not exist" };
    }

    // Generate a temp password (simple but sufficient for temporary use)
    const tempPassword = Math.random().toString(36).slice(-10) + "1!";

    // Create or get user
    let uid;
    try {
      const existing = await admin.auth().getUserByEmail(email);
      uid = existing.uid;
    } catch (e) {
      const created = await admin.auth().createUser({
        email,
        password: tempPassword,
        emailVerified: false,
        disabled: false,
      });
      uid = created.uid;
    }

    // Write membership docs
    const db = admin.firestore();
    const batch = db.batch();

    // Team member subcollection
    const memberRef = teamRef.collection("members").doc(uid);
    batch.set(
      memberRef,
      {
        role,
        status: "invited",
        addedAt: admin.firestore.FieldValue.serverTimestamp(),
        email,
      },
      { merge: true }
    );

    // Per-user mirror under /users/{uid}/teams/{teamId}
    const userTeamRef = db.collection("users").doc(uid).collection("teams").doc(teamId);
    batch.set(
      userTeamRef,
      {
        role,
        status: "invited",
        teamRef: teamRef,
      },
      { merge: true }
    );

    await batch.commit();

    // Skipping server-side email. Credentials returned to client for manual sharing.

    return {
      ok: true,
      email,
      uid,
      tempPassword,
      appDownloadURL: "",
    };
  } catch (err) {
    console.error("createUserAndInvite error:", err);
    // Normalize error shape
    const code = err && err.message === "unauthenticated" ? "unauthenticated" : "internal";
    return { ok: false, code, message: err?.message || String(err) };
  }
});

// --- helpers for team role checks ---
async function getMemberRole(teamId, uid) {
  const snap = await admin
    .firestore()
    .collection("teams").doc(teamId)
    .collection("members").doc(uid)
    .get();
  return snap.exists ? (snap.get("role") || "member") : null;
}

async function assertAdminOrOwner(teamId, callerUid) {
  const role = await getMemberRole(teamId, callerUid);
  if (role !== "owner" && role !== "admin") {
    const err = new Error("permission-denied");
    err.code = "permission-denied";
    throw err;
  }
}

// --- resendInvite ---
// Regenerates a temporary password for an invited/active member and returns credentials.
// Input: { teamId, email } OR { teamId, uid }
// Only owner/admin may call.
exports.resendInvite = onCall({ region: "us-central1" }, async (request) => {
  try {
    if (!request.auth) {
      throw new Error("unauthenticated");
    }

    const data = request.data || {};
    const teamId = String(data.teamId || "").trim();
    const emailInput = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";
    const uidInput = typeof data.uid === "string" ? data.uid.trim() : "";

    if (!teamId || (!emailInput && !uidInput)) {
      return { ok: false, code: "invalid-argument", message: "teamId and (email or uid) required" };
    }

    const callerUid = request.auth.uid;
    await assertAdminOrOwner(teamId, callerUid);

    // Resolve uid/email
    let uid = uidInput;
    let email = emailInput;
    if (!uid && email) {
      try {
        const u = await admin.auth().getUserByEmail(email);
        uid = u.uid; // may exist
      } catch (_) { /* user may not exist yet */ }
    }
    if (!email && uid) {
      try {
        const u = await admin.auth().getUser(uid);
        email = (u.email || "").toLowerCase();
      } catch (_) { /* ignore */ }
    }

    // If user does not exist, create as in first invite
    let createdNow = false;
    if (!uid) {
      if (!email) {
        return { ok: false, code: "not-found", message: "user not found and no email provided" };
      }
      const tempPassword = Math.random().toString(36).slice(-10) + "1!";
      const created = await admin.auth().createUser({ email, password: tempPassword, emailVerified: false, disabled: false });
      uid = created.uid;
      createdNow = true;

      // ensure membership exists as invited
      const db = admin.firestore();
      const teamRef = db.collection("teams").doc(teamId);
      const batch = db.batch();
      batch.set(teamRef.collection("members").doc(uid), { role: "member", status: "invited", email }, { merge: true });
      batch.set(db.collection("users").doc(uid).collection("teams").doc(teamId), { role: "member", status: "invited", teamRef }, { merge: true });
      await batch.commit();

      return { ok: true, email, uid, tempPassword, created: true };
    }

    // User exists: rotate temp password
    const tempPassword = Math.random().toString(36).slice(-10) + "1!";
    await admin.auth().updateUser(uid, { password: tempPassword });

    // Touch membership to ensure status is at least invited
    const db = admin.firestore();
    const teamRef = db.collection("teams").doc(teamId);
    await teamRef.collection("members").doc(uid).set({ status: "invited", email }, { merge: true });
    await db.collection("users").doc(uid).collection("teams").doc(teamId).set({ status: "invited", teamRef }, { merge: true });

    // Send re-invite email with rotated temp password (if SendGrid configured)
    // Skipping server-side email. Credentials returned to client for manual sharing.
    return { ok: true, email, uid, tempPassword, created: createdNow };
  } catch (err) {
    console.error("resendInvite error:", err);
    const code = err?.code === "permission-denied" ? "permission-denied" : (err?.message === "unauthenticated" ? "unauthenticated" : "internal");
    return { ok: false, code, message: err?.message || String(err) };
  }
});

// --- setMemberRole ---
// Promotes/demotes a member's role within a team. Input: { teamId, targetUid, role }
// Only owner/admin may call. Owner cannot demote themselves here (to prevent orphan teams).
exports.setMemberRole = onCall({ region: "us-central1" }, async (request) => {
  try {
    if (!request.auth) {
      throw new Error("unauthenticated");
    }

    const data = request.data || {};
    const teamId = String(data.teamId || "").trim();
    const targetUid = String(data.targetUid || "").trim();
    const role = String(data.role || "").trim();

    const allowed = new Set(["owner", "admin", "member"]);
    if (!teamId || !targetUid || !allowed.has(role)) {
      return { ok: false, code: "invalid-argument", message: "teamId, targetUid and valid role required" };
    }

    const callerUid = request.auth.uid;
    await assertAdminOrOwner(teamId, callerUid);

    // Prevent removing the last owner: if changing away from owner, ensure another owner exists or caller is owner
    const db = admin.firestore();
    const membersSnap = await db.collection("teams").doc(teamId).collection("members").get();

    const owners = membersSnap.docs.filter(d => (d.get("role") || "member") === "owner").map(d => d.id);

    if (targetUid === callerUid && owners.length === 1 && role !== "owner") {
      return { ok: false, code: "failed-precondition", message: "cannot demote the last owner" };
    }

    // Apply role
    const memberRef = db.collection("teams").doc(teamId).collection("members").doc(targetUid);
    await memberRef.set({ role }, { merge: true });

    // Mirror role to user doc if exists
    const userTeamRef = db.collection("users").doc(targetUid).collection("teams").doc(teamId);
    await userTeamRef.set({ role }, { merge: true });

    return { ok: true };
  } catch (err) {
    console.error("setMemberRole error:", err);
    const code = err?.code === "permission-denied" ? "permission-denied" : (err?.message === "unauthenticated" ? "unauthenticated" : "internal");
    return { ok: false, code, message: err?.message || String(err) };
  }
});