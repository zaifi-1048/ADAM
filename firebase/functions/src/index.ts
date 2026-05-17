import * as functions from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import OpenAI from "openai";

admin.initializeApp();
const db = admin.firestore();

// ─── OpenAI client (key stored in Firebase secret) ───────────────────────────
// Set via: firebase functions:secrets:set OPENAI_API_KEY
// Supports swapping to any OpenAI-compatible API (e.g. Gemini, Groq, etc.)
function getOpenAIClient(): OpenAI {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error("OPENAI_API_KEY secret not configured.");
  return new OpenAI({ apiKey });
}

// ─── Helper: fetch last N messages for context ────────────────────────────────
async function getRecentMessages(
  uid: string,
  sessionId: string,
  limit = 10
): Promise<{ role: "user" | "assistant"; content: string }[]> {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("sessions")
    .doc(sessionId)
    .collection("messages")
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snap.docs
    .reverse() // oldest first for context
    .map((d) => {
      const data = d.data();
      return {
        role: data.role as "user" | "assistant",
        content: data.content as string,
      };
    });
}

// ─── 1. chat — main AI endpoint called by Flutter ────────────────────────────
export const chat = functions.onRequest(
  {
    secrets: ["OPENAI_API_KEY"],
    cors: true,
    timeoutSeconds: 60,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const { uid, sessionId, message } = req.body as {
      uid?: string;
      sessionId?: string;
      message?: string;
    };

    if (!uid || !sessionId || !message) {
      res.status(400).json({ error: "uid, sessionId and message are required" });
      return;
    }

    // Verify the uid maps to a real user
    try {
      await admin.auth().getUser(uid);
    } catch {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    try {
      const history = await getRecentMessages(uid, sessionId);
      const openai = getOpenAIClient();

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini", // cost-efficient; swap to gpt-4o for better quality
        messages: [
          {
            role: "system",
            content:
              "You are ADAM, a highly intelligent AI personal assistant like JARVIS. " +
              "You are helpful, concise, and friendly. " +
              "Answer questions clearly. When asked to set reminders or tasks, acknowledge them.",
          },
          ...history,
          { role: "user", content: message },
        ],
        max_tokens: 500,
        temperature: 0.7,
      });

      const reply =
        completion.choices[0]?.message?.content?.trim() ??
        "I could not generate a response.";

      logger.info(`chat: uid=${uid} session=${sessionId} tokens=${completion.usage?.total_tokens}`);
      res.status(200).json({ reply });
    } catch (err) {
      logger.error("chat function error:", err);
      res.status(500).json({ error: "AI service unavailable. Please try again." });
    }
  }
);

// ─── 2. createUserProfile — triggered on new Auth user ───────────────────────
export const createUserProfile = functions.onRequest(
  { cors: false },
  async (req, res) => {
    // This is called from a Firestore Auth trigger below.
    // Kept as HTTP for manual testing. Use the trigger in production.
    res.status(200).json({ message: "Use the Auth trigger instead." });
  }
);

// ─── 3. onUserCreated — Auth trigger: auto-create Firestore profile ───────────
import * as authTriggers from "firebase-functions/v2/identity";

export const onUserCreated = authTriggers.beforeUserCreated(async (event) => {
  const user = event.data;
  if (!user) return;

  const profile = {
    uid: user.uid,
    fullName: user.displayName ?? "ADAM User",
    email: user.email ?? "",
    photoUrl: user.photoURL ?? null,
    provider: user.providerData?.[0]?.providerId ?? "email",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    isPremium: false,
    preferences: {},
  };

  try {
    // setMerge so Google re-login doesn't overwrite existing data
    await db.collection("users").doc(user.uid).set(profile, { merge: true });
    logger.info(`Profile created for uid=${user.uid}`);
  } catch (err) {
    logger.error("onUserCreated error:", err);
  }
});

// ─── 4. syncTask — create/update a task via HTTP (callable alternative) ───────
export const syncTask = functions.onRequest(
  { cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const { uid, task } = req.body as {
      uid?: string;
      task?: Record<string, unknown>;
    };

    if (!uid || !task || !task["id"]) {
      res.status(400).json({ error: "uid and task with id are required" });
      return;
    }

    try {
      await admin.auth().getUser(uid); // verify uid
      await db
        .collection("users")
        .doc(uid)
        .collection("tasks")
        .doc(task["id"] as string)
        .set(
          { ...task, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true }
        );
      res.status(200).json({ success: true });
    } catch (err) {
      logger.error("syncTask error:", err);
      res.status(500).json({ error: "Failed to sync task" });
    }
  }
);

// ─── 5. cleanupOldSessions — scheduled: delete sessions older than 30 days ───
import * as scheduler from "firebase-functions/v2/scheduler";

export const cleanupOldSessions = scheduler.onSchedule(
  "every 24 hours",
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const sessionsSnap = await userDoc.ref
        .collection("sessions")
        .where("updatedAt", "<", cutoff)
        .get();

      const batch = db.batch();
      for (const sessionDoc of sessionsSnap.docs) {
        batch.delete(sessionDoc.ref);
      }
      await batch.commit();
    }

    logger.info("cleanupOldSessions: done");
  }
);
