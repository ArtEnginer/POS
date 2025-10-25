const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'pos_user',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'pos_enterprise',
  password: process.env.DB_PASSWORD || 'pos_password_2024',
  port: process.env.DB_PORT || 5432,
});

async function fixAdminPassword() {
  try {
    console.log('🔧 Fixing admin password...\n');

    // Generate hash untuk password "admin123"
    const password = 'admin123';
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    console.log('Password:', password);
    console.log('Hash:', hash);
    console.log('');

    // Update user admin
    const result = await pool.query(
      `UPDATE users 
       SET password_hash = $1, 
           updated_at = NOW() 
       WHERE username = 'admin' 
       RETURNING id, username, email, full_name, role`,
      [hash]
    );

    if (result.rows.length > 0) {
      console.log('✅ Admin password updated successfully!');
      console.log('');
      console.log('User details:');
      console.log('  ID:', result.rows[0].id);
      console.log('  Username:', result.rows[0].username);
      console.log('  Email:', result.rows[0].email);
      console.log('  Name:', result.rows[0].full_name);
      console.log('  Role:', result.rows[0].role);
      console.log('');
      console.log('Login credentials:');
      console.log('  Username: admin');
      console.log('  Password: admin123');
      console.log('');

      // Test password verification
      const isValid = await bcrypt.compare(password, hash);
      console.log('✓ Password verification test:', isValid ? 'PASSED' : 'FAILED');
    } else {
      console.log('❌ User "admin" not found in database!');
      console.log('');
      console.log('Creating admin user...');

      const createResult = await pool.query(
        `INSERT INTO users (username, email, password_hash, full_name, role, status)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, username, email, full_name, role`,
        ['admin', 'admin@pos.com', hash, 'System Administrator', 'super_admin', 'active']
      );

      console.log('✅ Admin user created successfully!');
      console.log('');
      console.log('User details:');
      console.log('  ID:', createResult.rows[0].id);
      console.log('  Username:', createResult.rows[0].username);
      console.log('  Email:', createResult.rows[0].email);
      console.log('  Name:', createResult.rows[0].full_name);
      console.log('  Role:', createResult.rows[0].role);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('');
    console.error('Stack:', error.stack);
  } finally {
    await pool.end();
  }
}

fixAdminPassword();
