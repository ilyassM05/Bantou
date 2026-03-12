const mysql = require('mysql2/promise');

(async () => {
    const conn = await mysql.createConnection({
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '',
        database: 'bantou',
    });

    const [res] = await conn.query("UPDATE users SET role = 'SA' WHERE role = 'adherent'");
    console.log(`✔  Rows updated: ${res.affectedRows}`);

    const [rows] = await conn.query('SELECT id, name, email, role FROM users');
    console.table(rows);

    await conn.end();
})().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});
