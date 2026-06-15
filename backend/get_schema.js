const mysql = require('mysql2/promise');
const fs = require('fs');

async function extractSchema() {
    try {
        const connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'bantou'
        });

        const [tables] = await connection.query("SHOW TABLES");
        const schema = {};

        for (let row of tables) {
            const tableName = row['Tables_in_bantou'];
            
            // Get columns
            const [columns] = await connection.query(`SHOW COLUMNS FROM ${tableName}`);
            
            // Get foreign keys
            const [fks] = await connection.query(`
                SELECT 
                    COLUMN_NAME, 
                    REFERENCED_TABLE_NAME, 
                    REFERENCED_COLUMN_NAME 
                FROM 
                    INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                WHERE 
                    TABLE_SCHEMA = 'bantou' 
                    AND TABLE_NAME = ? 
                    AND REFERENCED_TABLE_NAME IS NOT NULL
            `, [tableName]);

            schema[tableName] = {
                columns: columns,
                foreignKeys: fks
            };
        }

        fs.writeFileSync('actual_db_schema.json', JSON.stringify(schema, null, 2));
        console.log('Schema extracted to actual_db_schema.json');
        await connection.end();
    } catch (err) {
        console.error('Error:', err);
    }
}

extractSchema();
