/**
 * End-to-end test for the invited admin onboarding flow.
 * Tests both the token-based path (real app flow) and the email fallback.
 */
const db = require('./config/db');

async function testInvitedAdmin() {
    try {
        // ── CLEANUP before test ──────────────────────────────────────────────────
        await db.query("DELETE FROM users WHERE email IN ('creator@example.com','invited_admin@example.com')");
        await db.query("DELETE FROM associations WHERE name = 'Test Association'");

        // ── Step 1: Creator signs up ─────────────────────────────────────────────
        console.log('\n--- Step 1: Creator signs up ---');
        const signup1 = await fetch('http://localhost:3000/auth/signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: 'Creator User', email: 'creator@example.com', password: 'password123' })
        });
        const { token: token1 } = await signup1.json();
        if (!token1) { console.error('FAIL: Creator signup failed'); process.exit(1); }
        console.log('SUCCESS: Creator signed up');

        // ── Step 2: Creator creates association + invites admin ──────────────────
        console.log('\n--- Step 2: Creator creates association and invites admin ---');
        const assocRes = await fetch('http://localhost:3000/auth/association', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token1}` },
            body: JSON.stringify({
                name: 'Test Association',
                address: '123 Test St',
                adminEmails: ['invited_admin@example.com']
            })
        });
        const assocBody = await assocRes.json();
        if (assocRes.status !== 200) { console.error('FAIL: Association creation failed:', assocBody); process.exit(1); }
        console.log('SUCCESS: Association created:', assocBody.message);

        // ── Step 3: Get the real invite token from the backend response ──────────
        console.log('\n--- Step 3: Extract invite token from association response ---');
        const inviteToken = assocBody.inviteTokens?.['invited_admin@example.com'];
        if (!inviteToken) { console.error('FAIL: No inviteToken in response for invited_admin@example.com', assocBody); process.exit(1); }
        console.log('SUCCESS: Got real invite token from backend');

        // Validate via the invite endpoint (simulates deep link open on device)
        console.log('\n--- Step 4: Validate invite token via GET /auth/invite/:token ---');
        const validateRes = await fetch(`http://localhost:3000/auth/invite/${inviteToken}`);
        const validateBody = await validateRes.json();
        if (validateRes.status !== 200) { console.error('FAIL: validateInvite failed:', validateBody); process.exit(1); }
        console.log('SUCCESS: validateInvite →', { email: validateBody.email, assocId: validateBody.associationId, assocName: validateBody.associationName });

        // ── Step 4: Invited admin signs up WITH the inviteToken ──────────────────
        console.log('\n--- Step 4: Invited admin signs up (token-based path) ---');
        const signup2 = await fetch('http://localhost:3000/auth/signup', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: 'Invited Admin',
                email: 'invited_admin@example.com',
                password: 'password123',
                inviteToken   // ← the crucial token
            })
        });
        const adminData = await signup2.json();
        console.log('Signup response:', { role: adminData.role, isInvitedAdmin: adminData.isInvitedAdmin, onboardingSeen: adminData.onboardingSeen });

        if (adminData.role !== 'ADMIN')       console.error('FAIL: role should be ADMIN, got:', adminData.role);
        else                                   console.log('SUCCESS: role = ADMIN');

        if (!adminData.isInvitedAdmin)         console.error('FAIL: isInvitedAdmin should be true');
        else                                   console.log('SUCCESS: isInvitedAdmin = true');

        if (adminData.onboardingSeen !== true)  console.error('FAIL: onboardingSeen should be true');
        else                                   console.log('SUCCESS: onboardingSeen = true (will skip association form)');

        const token2 = adminData.token;

        // ── Step 5: Validate DB state ────────────────────────────────────────────
        console.log('\n--- Step 5: Validate DB state ---');
        const [users] = await db.query('SELECT role, status, onboarding_seen FROM users WHERE email = ?', ['invited_admin@example.com']);
        if (!users[0])                         console.error('FAIL: User not found in DB');
        else if (users[0].role !== 'ADMIN')    console.error('FAIL: DB role is not ADMIN, got:', users[0].role);
        else                                   console.log('SUCCESS: DB role = ADMIN ✓');

        if (users[0]?.status !== 'actif')      console.error('FAIL: status is not actif, got:', users[0]?.status);
        else                                   console.log('SUCCESS: status = actif ✓');

        const [members] = await db.query('SELECT * FROM association_members WHERE user_id = ?', [adminData.user?.id]);
        if (!members[0])                       console.error('FAIL: User not linked to association in association_members!');
        else                                   console.log('SUCCESS: User linked to association ✓  (assoc_id:', members[0].association_id, ')');

        // ── Step 6: Invited admin completes profile → upgrade to SA ───────────────
        console.log('\n--- Step 6: Invited admin updates profile (should upgrade to SA) ---');
        const profileRes = await fetch('http://localhost:3000/auth/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token2}` },
            body: JSON.stringify({ company: 'Test Org', jobTitle: 'Admin', city: 'Test City', bio: 'Hello' })
        });
        const profileBody = await profileRes.json();
        if (!profileBody.upgraded)             console.error('FAIL: Not upgraded to SA:', profileBody);
        else                                   console.log('SUCCESS: Upgraded to SA ✓');

        const [after] = await db.query('SELECT role FROM users WHERE email = ?', ['invited_admin@example.com']);
        if (after[0]?.role !== 'SA')           console.error('FAIL: DB role after upgrade is not SA, got:', after[0]?.role);
        else                                   console.log('SUCCESS: DB role after upgrade = SA ✓');

        console.log('\n✅  All checks passed — invited admin flow is working correctly!');
    } finally {
        // ── Cleanup ──────────────────────────────────────────────────────────────
        await db.query("DELETE FROM users WHERE email IN ('creator@example.com','invited_admin@example.com')");
        const [a] = await db.query("SELECT id FROM associations WHERE name = 'Test Association'");
        if (a[0]) {
            await db.query('DELETE FROM association_members WHERE association_id = ?', [a[0].id]);
            await db.query("DELETE FROM associations WHERE id = ?", [a[0].id]);
        }
        process.exit(0);
    }
}

testInvitedAdmin().catch(err => { console.error('UNHANDLED ERROR:', err); process.exit(1); });
