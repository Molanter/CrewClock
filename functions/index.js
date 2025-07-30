const functions = require("firebase-functions");
const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const serviceAccount = require("./service-account.json");

admin.initializeApp();

const sheets = google.sheets("v4");
const auth = new google.auth.JWT(
    serviceAccount.client_email,
    null,
    serviceAccount.private_key,
    ["https://www.googleapis.com/auth/spreadsheets"]
);

const getSpreadsheetId = (data) => data.spreadsheetId;

exports.addToSheet = onDocumentCreated(
    {
        region: "us-central1",
        document: "logsForSheets/{logId}"
    },
    async (event) => {
        const snap = event.data;
        const data = snap.data();

        const formattedDate = data.date?._seconds
            ? new Date(data.date._seconds * 1000).toLocaleDateString("en-US", {
                year: "numeric", month: "short", day: "numeric"
              })
            : "";

        const timeStarted = data.timeStarted?._seconds
            ? new Date(data.timeStarted._seconds * 1000).toLocaleTimeString("en-US", {
                  hour: "numeric",
                  minute: "2-digit",
                  hour12: true
              })
            : data.timeStarted || "";

        const timeFinished = data.timeFinished?._seconds
            ? new Date(data.timeFinished._seconds * 1000).toLocaleTimeString("en-US", {
                  hour: "numeric",
                  minute: "2-digit",
                  hour12: true
              })
            : data.timeFinished || "";

        const row = [
            data.projectName || "",
            data.comment || "",
            formattedDate,
            timeStarted,
            timeFinished,
            (data.crewUID || []).join(", "),
            data.expenses || 0
        ];

        await auth.authorize();

        const spreadsheetId = getSpreadsheetId(data);
        // Fetch spreadsheet metadata to get the first sheet name
        const spreadsheetMeta = await sheets.spreadsheets.get({
            spreadsheetId,
            auth
        });
        const sheetName = spreadsheetMeta.data.sheets?.[0]?.properties?.title || "Sheet1";
        console.log("➡️ Data row:", row);
        console.log("➡️ Spreadsheet ID:", spreadsheetId);
        await sheets.spreadsheets.values.append({
            spreadsheetId,
            range: `${sheetName}!A1`,
            valueInputOption: "USER_ENTERED",
            auth,
            requestBody: {
                values: [row]
            }
        });

        // Get actual number of filled rows in column A
        const res = await sheets.spreadsheets.values.get({
            spreadsheetId,
            range: `${sheetName}!A:A`,
            auth
        });
        const appendedRowCount = res.data.values ? res.data.values.length : 1;

        // Save the row number back to Firestore
        const logRef = admin.firestore().doc(`logs/${snap.id}`);
        await logRef.update({ row: appendedRowCount });

        console.log("✅ Row added to sheet");
        return null;
    }
);

exports.updateSheetRow = onDocumentUpdated(
    {
        region: "us-central1",
        document: "logsForSheets/{logId}"
    },
    async (event) => {
        const snapAfter = event.data.after;
        const data = snapAfter.data();

        const spreadsheetId = getSpreadsheetId(data);
        const rowNumber = Number(data.row);

        if (
            !spreadsheetId ||
            typeof rowNumber !== "number" ||
            rowNumber <= 0 ||
            isNaN(rowNumber)
        ) {
            console.error("❌ Missing or invalid spreadsheet ID or row number", {
                spreadsheetId,
                rowNumber
            });
            return null;
        }

        const formattedDate = data.date?._seconds
            ? new Date(data.date._seconds * 1000).toLocaleDateString("en-US", {
                  year: "numeric", month: "short", day: "numeric"
              })
            : "";

        const timeStarted = data.timeStarted?._seconds
            ? new Date(data.timeStarted._seconds * 1000).toLocaleTimeString("en-US", {
                  hour: "numeric",
                  minute: "2-digit",
                  hour12: true
              })
            : data.timeStarted || "";

        const timeFinished = data.timeFinished?._seconds
            ? new Date(data.timeFinished._seconds * 1000).toLocaleTimeString("en-US", {
                  hour: "numeric",
                  minute: "2-digit",
                  hour12: true
              })
            : data.timeFinished || "";

        const row = [
            data.projectName || "",
            data.comment || "",
            formattedDate,
            timeStarted,
            timeFinished,
            (data.crewUID || []).join(", "),
            data.expenses || 0
        ];

        await auth.authorize();

        const spreadsheetMeta = await sheets.spreadsheets.get({
            spreadsheetId,
            auth
        });
        const sheetName = spreadsheetMeta.data.sheets?.[0]?.properties?.title || "Sheet1";

        const range = `${sheetName}!A${rowNumber}:G${rowNumber}`;

        await sheets.spreadsheets.values.update({
            spreadsheetId,
            range,
            valueInputOption: "USER_ENTERED",
            auth,
            requestBody: {
                values: [row]
            }
        });

        console.log(`✅ Updated row ${rowNumber} in spreadsheet`);
        return null;
    }
);

exports.deleteSheetRow = onDocumentDeleted(
    {
        region: "us-central1",
        document: "logsForSheets/{logId}"
    },
    async (event) => {
        const data = event.data;
        const spreadsheetId = getSpreadsheetId(data);
        const rowNumber = data.row;

        if (
            !spreadsheetId ||
            typeof rowNumber !== "number" ||
            rowNumber <= 0 ||
            isNaN(rowNumber)
        ) {
            console.error("❌ Missing or invalid spreadsheet ID or row number", {
                spreadsheetId,
                rowNumber
            });
            return null;
        }

        await auth.authorize();

        const spreadsheetMeta = await sheets.spreadsheets.get({
            spreadsheetId,
            auth
        });
        const sheetName = spreadsheetMeta.data.sheets?.[0]?.properties?.title || "Sheet1";

        const deleteRequest = {
            spreadsheetId,
            auth,
            requestBody: {
                requests: [
                    {
                        deleteDimension: {
                            range: {
                                sheetId: spreadsheetMeta.data.sheets[0].properties.sheetId,
                                dimension: "ROWS",
                                startIndex: rowNumber - 1,
                                endIndex: rowNumber
                            }
                        }
                    }
                ]
            }
        };

        await sheets.spreadsheets.batchUpdate(deleteRequest);
        console.log(`🗑️ Deleted row ${rowNumber} from spreadsheet`);
        return null;
    }
);

exports.sendPushNotification = onDocumentCreated(
  {
    region: "us-central1",
    document: "notifications/{notificationId}"
  },
  async (event) => {
    const snap = event.data;
    const data = snap.data();

    const title = data.title;
    const body = data.body || data.message;
    const imageUrl = data.imageUrl || "";
    const link = data.link || "";
    const badgeCount = data.badge || 1;

    let recipients = [];
    if (Array.isArray(data.recipients)) {
      recipients = data.recipients;
    } else if (Array.isArray(data.recipientUID)) {
      recipients = data.recipientUID;
    } else if (typeof data.recipientUID === "string") {
      recipients = [data.recipientUID];
    }

    if (!Array.isArray(recipients) || recipients.length === 0 || !title || !body) {
      console.error("❌ Missing required parameters in notification document");
      return null;
    }

    const tokensToSend = [];

    for (const uid of recipients) {
      const tokensSnapshot = await admin.firestore()
        .collection("users")
        .doc(uid)
        .collection("fcmTokens")
        .get();

      tokensSnapshot.forEach(doc => {
        const token = doc.id;
        if (token) {
          tokensToSend.push(token);
        }
      });
    }

    const sendPromises = tokensToSend.map(token => {
      const notificationPayload = {
        title: title,
        body: body
      };
      if (imageUrl && typeof imageUrl === "string" && imageUrl.startsWith("http")) {
        notificationPayload.imageUrl = imageUrl;
      }
      const message = {
        token: token,
        notification: notificationPayload,
        data: {
          link: link,
          sound: "default"
        },
        apns: {
          payload: {
            aps: {
              badge: badgeCount,
              sound: "default"
            }
          }
        }
      };

      return admin.messaging().send(message);
    });

    try {
      const responses = await Promise.all(sendPromises);
      console.log("✅ Notifications sent:", responses);
    } catch (error) {
      console.error("❌ Error sending one or more notifications:", error);
    }

    return null;
  }
);