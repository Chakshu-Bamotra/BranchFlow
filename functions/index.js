const crypto = require("crypto");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineInt, defineSecret, defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const nodemailer = require("nodemailer");
const otp = require("./otp");

initializeApp();
setGlobalOptions({ maxInstances: 10 });

// SMTP settings. Non-secret values go in functions/.env, the password in Secret Manager:
//   firebase functions:secrets:set SMTP_PASS
const SMTP_HOST = defineString("SMTP_HOST");
const SMTP_PORT = defineInt("SMTP_PORT", { default: 465 });
const SMTP_USER = defineString("SMTP_USER");
const MAIL_FROM = defineString("MAIL_FROM");
const SMTP_PASS = defineSecret("SMTP_PASS");

const OTP_COLLECTION = "email_otps";

let transporter;
function getTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: SMTP_HOST.value(),
      port: SMTP_PORT.value(),
      secure: SMTP_PORT.value() === 465,
      auth: { user: SMTP_USER.value(), pass: SMTP_PASS.value() },
    });
  }
  return transporter;
}

async function sendOtpEmail(email, code, purpose) {
  const minutes = otp.OTP_TTL_MS / 60000;
  const subject = purpose === "verify"
    ? "Your BranchFlow verification code"
    : "Your BranchFlow password reset code";
  const intro = purpose === "verify"
    ? "Use this code to verify your email address for BranchFlow:"
    : "Use this code to reset your BranchFlow password:";

  await getTransporter().sendMail({
    from: MAIL_FROM.value(),
    to: email,
    subject,
    text: `${intro}\n\n${code}\n\nThe code expires in ${minutes} minutes. ` +
      "If you didn't request it, you can ignore this email.",
    html: `<p>${intro}</p>
<p style="font-size:28px;font-weight:bold;letter-spacing:6px">${code}</p>
<p>The code expires in ${minutes} minutes. If you didn't request it, you can ignore this email.</p>`,
  });
}

function requirePurpose(purpose) {
  if (!otp.PURPOSES.includes(purpose)) {
    throw new HttpsError("invalid-argument", "Unknown OTP purpose.");
  }
}

function requireEmail(raw) {
  const email = otp.normalizeEmail(raw);
  if (!otp.isValidEmail(email)) {
    throw new HttpsError("invalid-argument", "Please enter a valid email address.");
  }
  return email;
}

async function findUserByEmail(email) {
  try {
    return await getAuth().getUserByEmail(email);
  } catch (e) {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  }
}

// Creates a fresh code for (purpose, email), enforcing cooldown and hourly limits, then emails it.
async function issueCode(purpose, email, uid) {
  const db = getFirestore();
  const ref = db.collection(OTP_COLLECTION).doc(otp.otpDocId(purpose, email));
  const code = otp.generateCode();
  const salt = crypto.randomBytes(16).toString("hex");
  const now = Date.now();

  const decision = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const result = otp.checkSendAllowed(snap.exists ? snap.data() : null, now);
    if (!result.ok) return result;
    tx.set(ref, {
      uid,
      purpose,
      salt,
      codeHash: otp.hashCode(code, salt),
      attempts: 0,
      expiresAt: now + otp.OTP_TTL_MS,
      lastSentAt: now,
      windowStart: result.windowStart,
      sendCount: result.sendCount,
      // Lets a Firestore TTL policy on `ttl` clean up stale docs (optional).
      ttl: Timestamp.fromMillis(now + 60 * 60 * 1000),
    });
    return result;
  });

  if (!decision.ok) {
    const seconds = Math.ceil(decision.retryAfterMs / 1000);
    throw new HttpsError("resource-exhausted",
      `Please wait ${seconds}s before requesting another code.`, { retryAfterSeconds: seconds });
  }

  try {
    await sendOtpEmail(email, code, purpose);
  } catch (e) {
    logger.error("Failed to send OTP email", { purpose, error: e.message });
    await ref.delete();
    throw new HttpsError("unavailable", "We couldn't send the email right now. Please try again shortly.");
  }
}

// Checks a code and consumes it on success. Wrong guesses count toward the attempt limit.
async function consumeCode(purpose, email, code) {
  const db = getFirestore();
  const ref = db.collection(OTP_COLLECTION).doc(otp.otpDocId(purpose, email));

  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : null;
    const status = otp.checkCode(data, code, Date.now());
    if (status === "ok") {
      tx.delete(ref);
    } else if (status === "mismatch") {
      tx.update(ref, { attempts: data.attempts + 1 });
    }
    return { status, attemptsLeft: data ? otp.MAX_VERIFY_ATTEMPTS - data.attempts - 1 : 0 };
  });

  switch (outcome.status) {
    case "ok":
      return;
    case "missing":
      throw new HttpsError("not-found", "No active code for this email. Please request a new one.");
    case "expired":
      throw new HttpsError("deadline-exceeded", "This code has expired. Please request a new one.");
    case "locked":
      throw new HttpsError("permission-denied", "Too many incorrect attempts. Please request a new code.");
    default:
      throw new HttpsError("invalid-argument", outcome.attemptsLeft > 0
        ? `Incorrect code. ${outcome.attemptsLeft} attempt(s) left.`
        : "Incorrect code. Please request a new one.");
  }
}

// data: { purpose: "verify" } (signed in) or { purpose: "reset", email }
exports.requestEmailOtp = onCall({ secrets: [SMTP_PASS] }, async (request) => {
  const purpose = request.data?.purpose;
  requirePurpose(purpose);

  if (purpose === "verify") {
    if (!request.auth) throw new HttpsError("unauthenticated", "Please sign in first.");
    const user = await getAuth().getUser(request.auth.uid);
    if (!user.email) throw new HttpsError("failed-precondition", "This account has no email address.");
    if (user.emailVerified) return { sent: false, alreadyVerified: true };
    await issueCode("verify", otp.normalizeEmail(user.email), user.uid);
    return { sent: true };
  }

  const email = requireEmail(request.data?.email);
  const user = await findUserByEmail(email);
  // Respond the same way whether or not the account exists, so emails can't be probed.
  if (user) await issueCode("reset", email, user.uid);
  return { sent: true };
});

// data: { code }
exports.verifyEmailOtp = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Please sign in first.");
  const user = await getAuth().getUser(request.auth.uid);
  if (user.emailVerified) return { verified: true };

  await consumeCode("verify", otp.normalizeEmail(user.email), request.data?.code);
  await getAuth().updateUser(user.uid, { emailVerified: true });
  return { verified: true };
});

// data: { email, code, newPassword }
exports.resetPasswordWithOtp = onCall(async (request) => {
  const email = requireEmail(request.data?.email);
  const newPassword = String(request.data?.newPassword || "");
  if (newPassword.length < 6) {
    throw new HttpsError("invalid-argument", "New password must be at least 6 characters.");
  }

  await consumeCode("reset", email, request.data?.code);
  const user = await findUserByEmail(email);
  if (!user) throw new HttpsError("not-found", "No active code for this email. Please request a new one.");

  // Receiving the code proves ownership of the inbox, so the email is verified too.
  await getAuth().updateUser(user.uid, { password: newPassword, emailVerified: true });
  await getAuth().revokeRefreshTokens(user.uid);
  return { reset: true };
});
