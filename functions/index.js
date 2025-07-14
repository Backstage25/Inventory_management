const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Set up Gmail transporter (replace credentials later)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});

// Trigger: Send email when invite is created
exports.sendInviteEmail = functions.firestore
  .document("pending_invitations/{inviteId}")
  .onCreate(async (snapshot, context) => {
    const email = snapshot.data().email;
    const code = snapshot.data().invite_code;

    const mailOptions = {
      from: '"Your App" <noreply@yourapp.com>',
      to: email,
      subject: "Your Verification Code",
      html: `Your verification code is: <b>${code}</b>`,
    };

    await transporter.sendMail(mailOptions);
    console.log("Email sent to:", email);
  });
