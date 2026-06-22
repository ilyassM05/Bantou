const mysql = require('mysql2/promise');
(async () => {
    const conn = await mysql.createConnection({host:'localhost',port:3306,user:'root',password:'',database:'bantou'});
    await conn.execute("DELETE FROM users WHERE email IN ('testfix@test.com','testfix2@test.com')");
    console.log('Test users cleaned up');
    await conn.end();
})().catch(e=>console.error(e.message));
