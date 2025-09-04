const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

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