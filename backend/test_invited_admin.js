const http = require('http');

async function testInvitedAdmin() {
    // 1. Create a raw user directly in DB or via API
    // Wait, let's use the API directly to simulate an invitation and then signup

    console.log('--- Step 1: Create a regular user who will invite an admin ---');
    const signup1 = await fetch('http://localhost:3000/auth/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Creator User', email: 'creator@example.com', password: 'password123' })
    });
    const { token: token1 } = await signup1.json();
    console.log('Creator signed up, token:', token1 ? 'OK' : 'FAIL');

    console.log('--- Step 2: Creator creates an association and invites an admin ---');
    const assocSubmit = await fetch('http://localhost:3000/auth/association', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token1}` },
        body: JSON.stringify({
            name: 'Test Association',
            address: '123 Test St',
            adminEmails: ['invited_admin@example.com'] // This email is now "invited"
        })
    });
    const assocRes = await assocSubmit.json();
    console.log('Association created:', assocRes);

    console.log('--- Step 3: Invited admin signs up ---');
    const signup2 = await fetch('http://localhost:3000/auth/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Invited Admin', email: 'invited_admin@example.com', password: 'password123' })
    });
    const adminData = await signup2.json();
    console.log('Invited Admin signed up:', adminData);
    
    if (adminData.onboardingSeen !== true) {
        console.error('ERROR: Invited admin should have onboardingSeen = true');
    } else {
        console.log('SUCCESS: Invited admin bypassed onboarding (onboardingSeen=true)');
    }

    const token2 = adminData.token;

    console.log('--- Step 4: Validate DB state for the new user ---');
    const db = require('./config/db');
    const [users] = await db.query('SELECT role, status, onboarding_seen FROM users WHERE email = ?', ['invited_admin@example.com']);
    console.log('DB User record:', users[0]);
    if (users[0].role !== 'ADMIN') console.error('ERROR: Role is not ADMIN!');
    if (users[0].status !== 'actif') console.error('ERROR: Status is not actif!');

    const [members] = await db.query('SELECT * FROM association_members WHERE user_id = ?', [adminData.user.id]);
    console.log('DB Association link:', members[0]);
    if (!members[0]) console.error('ERROR: User not linked to association!');

    console.log('--- Step 5: Invited admin updates profile ---');
    const profileSubmit = await fetch('http://localhost:3000/auth/update-profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token2}` },
        body: JSON.stringify({
            company: 'Test Org',
            jobTitle: 'Admin',
            city: 'Test City',
            bio: 'Hello world'
        })
    });
    const profileRes = await profileSubmit.json();
    console.log('Profile update response:', profileRes);

    if (profileRes.upgraded !== true) {
        console.error('ERROR: User was not upgraded to full SA after profile update!');
    } else {
        console.log('SUCCESS: User was upgraded to full SA!');
    }

    const [usersAfter] = await db.query('SELECT role FROM users WHERE email = ?', ['invited_admin@example.com']);
    console.log('DB User role after profile update:', usersAfter[0].role);

    console.log('--- Cleaning up DB ---');
    await db.query('DELETE FROM users WHERE email IN (?, ?)', ['creator@example.com', 'invited_admin@example.com']);
    process.exit(0);
}

testInvitedAdmin().catch(console.error);
