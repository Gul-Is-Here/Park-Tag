const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ maxInstances: 10 });

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * FR-05/FR-06: pushes a notification to a vehicle's owner the moment a
 * scanner sends them a message from the public Scan Contact Page (FR-04).
 * Owner replies aren't pushed anywhere — the scanner is an anonymous web
 * visitor with no app install and no registered device.
 */
exports.onNewChatMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message || message.sender !== "scanner") return;

    const { conversationId } = event.params;
    const conversationSnap = await db.collection("conversations").doc(conversationId).get();
    const conversation = conversationSnap.data();
    if (!conversation) return;

    const ownerUid = conversation.ownerUid;
    if (!ownerUid) return;

    const ownerSnap = await db.collection("users").doc(ownerUid).get();
    const tokens = ownerSnap.data()?.fcmTokens;
    if (!Array.isArray(tokens) || tokens.length === 0) {
      logger.info(`No FCM tokens for owner ${ownerUid}; skipping push for ${conversationId}.`);
      return;
    }

    const scannerName = conversation.scannerName || "Anonymous";
    const plateNumber = conversation.plateNumber || "your vehicle";
    const text = typeof message.text === "string" ? message.text : "";

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: `${scannerName} messaged you about ${plateNumber}`,
        body: text,
      },
      data: {
        type: "chat_message",
        conversationId,
        plateNumber,
        scannerName,
        colorName: conversation.colorName || "",
      },
      android: {
        priority: "high",
        notification: {
          // Must match MainActivity.MESSAGES_CHANNEL_ID and the manifest's
          // default_notification_channel_id. Naming it explicitly means the
          // push does not depend on the client's default being configured.
          channelId: "parktag_messages",
          sound: "default",
        },
      },
      apns: { payload: { aps: { sound: "default" } } },
    });

    // A token stops being valid when the app is uninstalled or its
    // notification permission is revoked — drop those so this list doesn't
    // grow forever and keep retrying dead tokens.
    const staleTokens = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code;
      if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token") {
        staleTokens.push(tokens[index]);
      }
    });
    if (staleTokens.length > 0) {
      await db.collection("users").doc(ownerUid).update({
        fcmTokens: FieldValue.arrayRemove(...staleTokens),
      });
    }

    logger.info(
      `Push for ${conversationId}: ${response.successCount} sent, ${response.failureCount} failed, ` +
        `${staleTokens.length} stale tokens removed.`,
    );
  },
);

/**
 * FR-09: called once, right after a resident signs in, with the anonymous
 * `scannerId` browser/device token pulled off a tapped scan link (see
 * DeepLinkService — the public Scan Contact Page's own URL, registered as
 * an App Link/Universal Link). Every conversation that identity took part
 * in (as a scanner messaging some other car's owner) gets stamped with
 * this resident's uid, so it surfaces in their app inbox's "Sent" section
 * from then on.
 *
 * Runs server-side (not a client Firestore write) because the scanner side
 * of a conversation has no auth token to satisfy a security rule with —
 * this callable is the trusted, auth-gated door for that one write.
 */
exports.linkScannerIdentity = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be signed in to link a scanner identity.");
  }

  const scannerId = request.data?.scannerId;
  if (!scannerId || typeof scannerId !== "string") {
    throw new HttpsError("invalid-argument", "scannerId is required.");
  }

  const matches = await db.collection("conversations").where("scannerId", "==", scannerId).get();
  if (matches.empty) {
    return { linkedCount: 0 };
  }

  const batch = db.batch();
  let linkedCount = 0;
  matches.forEach((doc) => {
    // Idempotent: skip anything already linked (possibly to a different
    // uid, e.g. a shared/reset device — never overwrite an existing link).
    if (doc.data().scannerUid) return;
    batch.update(doc.ref, { scannerUid: uid });
    linkedCount += 1;
  });
  await batch.commit();

  logger.info(`Linked ${linkedCount} conversation(s) for scannerId ${scannerId} to uid ${uid}.`);
  return { linkedCount };
});

/**
 * The authoritative door for an *authenticated* app user (native QR scan
 * inside the app, or an App Link/Universal Link opened into a signed-in
 * app) to start a chat with a vehicle's owner.
 *
 * The client never supplies (or is trusted for) the owner's identity —
 * only a `vehicleId`. Everything else — who owns it, whether it still
 * exists, the plate/colour shown in the chat header — is resolved here
 * from Firestore via the Admin SDK, which bypasses client security rules
 * entirely. This is deliberately NOT a client-side Firestore write: a
 * signed-in scanner has no rule that would let them safely claim
 * `scannerUid` for themselves and validate the vehicle in one atomic step
 * from the client, so that responsibility lives here instead.
 *
 * Conversation id is deterministic — `{vehicleId}_{scannerUid}` — so two
 * scans (or a scan followed by a deep-link open) by the same signed-in
 * resident against the same vehicle always resolve to the same chat room
 * rather than creating a duplicate one. A Firestore transaction guards the
 * create-if-absent step against a race between two near-simultaneous calls.
 */
exports.resolveVehicleAndOpenChat = onCall(async (request) => {
  const scannerUid = request.auth?.uid;
  if (!scannerUid) {
    throw new HttpsError("unauthenticated", "Sign in to start a chat.");
  }

  const vehicleId = request.data?.vehicleId;
  if (!vehicleId || typeof vehicleId !== "string") {
    throw new HttpsError("invalid-argument", "vehicleId is required.");
  }

  const vehicleSnap = await db.collection("vehicles").doc(vehicleId).get();
  const vehicle = vehicleSnap.data();
  if (!vehicle) {
    throw new HttpsError("not-found", "This QR code doesn't match a ParkTag vehicle.");
  }

  const ownerUid = vehicle.ownerUid;
  if (!ownerUid || typeof ownerUid !== "string") {
    throw new HttpsError("failed-precondition", "This vehicle has no registered owner.");
  }
  if (ownerUid === scannerUid) {
    throw new HttpsError("failed-precondition", "This is your own vehicle — nothing to message.");
  }

  const scannerSnap = await db.collection("users").doc(scannerUid).get();
  const scannerName = scannerSnap.data()?.name || "A ParkTag resident";

  // FR-09: this scan may be a continuation of a conversation this person
  // already started anonymously from the public web page, before they had
  // an account. That conversation is keyed by the browser's random
  // scannerId, so when the deep link carries one, adopt that document
  // instead of creating a parallel empty chat under the new uid — that is
  // what "restores" the web conversation in the app, with its history.
  //
  // Only an UNCLAIMED conversation (or one already claimed by this same
  // uid) may be adopted. A scannerId belonging to someone else's browser
  // must never let this caller take over their chat.
  const anonymousScannerId = request.data?.scannerId;
  let conversationId = `${vehicleId}_${scannerUid}`;

  if (anonymousScannerId && typeof anonymousScannerId === "string") {
    const anonymousId = `${vehicleId}_${anonymousScannerId}`;
    const anonymousSnap = await db.collection("conversations").doc(anonymousId).get();
    const anonymous = anonymousSnap.data();
    const claimedBySomeoneElse =
      anonymous?.scannerUid && anonymous.scannerUid !== scannerUid;

    if (anonymous && anonymous.vehicleId === vehicleId && !claimedBySomeoneElse) {
      conversationId = anonymousId;
      logger.info(
        `Adopting anonymous conversation ${anonymousId} for uid ${scannerUid}.`,
      );
    }
  }

  const conversationRef = db.collection("conversations").doc(conversationId);

  // All reads before any writes — required for a Firestore transaction.
  const conversation = await db.runTransaction(async (tx) => {
    const existing = await tx.get(conversationRef);
    if (existing.exists) {
      const data = existing.data();
      // Claim an adopted anonymous conversation for this account, which is
      // what makes it appear under "Sent" and lets them reply as
      // themselves rather than as an anonymous web visitor.
      if (!data.scannerUid) {
        tx.update(conversationRef, { scannerUid, scannerName });
        return { ...data, scannerUid, scannerName };
      }
      return data;
    }

    const data = {
      vehicleId,
      ownerUid,
      ownerName: vehicle.ownerName || "A ParkTag resident",
      scannerId: scannerUid,
      scannerUid,
      scannerName,
      plateNumber: vehicle.plateNumber || "",
      colorName: vehicle.colorName || "",
      resolved: false,
      unreadForOwner: false,
      unreadForScanner: false,
      unreadCountForOwner: 0,
      unreadCountForScanner: 0,
      lastMessagePreview: "",
      lastMessageAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    };
    tx.set(conversationRef, data);
    return data;
  });

  logger.info(`resolveVehicleAndOpenChat: ${scannerUid} -> ${conversationId} (vehicle ${vehicleId}).`);

  return {
    conversationId,
    ownerName: conversation.ownerName || "A ParkTag resident",
    plateNumber: conversation.plateNumber || "",
    colorName: conversation.colorName || "",
    resolved: conversation.resolved || false,
  };
});
