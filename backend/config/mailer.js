const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Send a 6-digit OTP to the user's email address.
 * @param {string} to   — recipient email
 * @param {string} otp  — 6-digit code
 */
async function sendOtpEmail(to, otp) {
    const mailOptions = {
        from: `"Bantou App" <${process.env.EMAIL_USER}>`,
        to,
        subject: '🔐 Your Bantou Password Reset Code',
        html: `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #fffbf0; border-radius: 16px; overflow: hidden; border: 1px solid #f0e0b0;">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #C9A84C, #8B6914); padding: 32px 24px; text-align: center;">
                <h1 style="color: #fff; margin: 0; font-size: 26px; letter-spacing: 1px;">Bantou</h1>
                <p style="color: rgba(255,255,255,0.85); margin: 6px 0 0; font-size: 13px;">Je suis parce que nous sommes</p>
            </div>
            <!-- Body -->
            <div style="padding: 32px 28px; text-align: center;">
                <h2 style="color: #3D2B00; margin-top: 0; font-size: 20px;">Password Reset Request</h2>
                <p style="color: #6B5020; font-size: 15px; line-height: 1.6;">
                    We received a request to reset your password. Use the code below to verify it's really you.
                </p>
                <!-- OTP Box -->
                <div style="background: #fff; border: 2px solid #C9A84C; border-radius: 12px; padding: 20px 0; margin: 24px 0; display: inline-block; width: 100%;">
                    <p style="color: #999; font-size: 12px; margin: 0 0 8px; text-transform: uppercase; letter-spacing: 1.5px;">Your verification code</p>
                    <p style="color: #C9A84C; font-size: 42px; font-weight: 800; margin: 0; letter-spacing: 10px;">${otp}</p>
                </div>
                <p style="color: #888; font-size: 13px; margin-top: 4px;">
                    ⏱️ This code expires in <strong>15 minutes</strong>.
                </p>
                <p style="color: #888; font-size: 13px;">
                    If you didn't request this, you can safely ignore this email.
                </p>
            </div>
            <!-- Footer -->
            <div style="background: #f5e9c8; padding: 16px; text-align: center;">
                <p style="color: #b0904a; font-size: 11px; margin: 0;">© 2026 Bantou. All rights reserved.</p>
            </div>
        </div>
        `,
    };

    await transporter.sendMail(mailOptions);
}

/**
 * Send an invitation email to a newly added association admin.
 * @param {string} to - recipient email
 * @param {string} inviterName - name of the user who invited them
 * @param {string} associationName - name of the association
 * @param {string} inviteToken - signed JWT for the deep link
 */
async function sendAdminInvitationEmail(to, inviterName, associationName, inviteToken) {
    // HTTP redirect page hosted on the backend — clickable in all email clients.
    // The page then auto-redirects to bantou:// to open the Flutter app.
    const host = process.env.SERVER_HOST || '10.0.2.2';
    const port = process.env.PORT || 3000;
    const redirectUrl = `http://${host}:${port}/auth/invite-redirect/${inviteToken}`;
    // Keep the direct deep link as reference (shown as text in the email)
    const deepLink = `bantou://invite?token=${inviteToken}`;

    const mailOptions = {
        from: `"Bantou App" <${process.env.EMAIL_USER}>`,
        to,
        subject: `You have been invited to join ${associationName} on Bantou`,
        html: `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #fffbf0; border-radius: 16px; overflow: hidden; border: 1px solid #f0e0b0;">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #C9A84C, #8B6914); padding: 32px 24px; text-align: center;">
                <h1 style="color: #fff; margin: 0; font-size: 26px; letter-spacing: 1px;">Bantou</h1>
                <p style="color: rgba(255,255,255,0.85); margin: 6px 0 0; font-size: 13px;">Je suis parce que nous sommes</p>
            </div>
            <!-- Body -->
            <div style="padding: 32px 28px; text-align: center;">
                <h2 style="color: #3D2B00; margin-top: 0; font-size: 20px;">Association Invitation</h2>
                <p style="color: #6B5020; font-size: 15px; line-height: 1.6;">
                    Hello! <strong>${inviterName}</strong> has invited you to join Bantou as an Administrator for their association: <strong>${associationName}</strong>.
                </p>
                <div style="margin: 24px 0;">
                    <a href="${redirectUrl}" style="background: #C9A84C; color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-weight: bold; font-size: 16px; display: inline-block;">
                        Accept Invitation &amp; Sign Up
                    </a>
                </div>
                <p style="color: #888; font-size: 12px; margin-top: 4px;">
                    Tap the button above on your mobile device. It will open the Bantou app directly.<br/>
                    <span style="font-size: 11px; color: #aaa;">If prompted, choose to open in Bantou.</span>
                </p>
                <p style="color: #888; font-size: 13px; margin-top: 16px;">
                    This invitation expires in <strong>7 days</strong>. If you don't know who invited you, please ignore this email.
                </p>
            </div>
            <!-- Footer -->
            <div style="background: #f5e9c8; padding: 16px; text-align: center;">
                <p style="color: #b0904a; font-size: 11px; margin: 0;">© 2026 Bantou. All rights reserved.</p>
            </div>
        </div>
        `,
    };

    await transporter.sendMail(mailOptions);
}

module.exports = { sendOtpEmail, sendAdminInvitationEmail };
