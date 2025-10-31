const { Pool } = require("pg");

const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "pos_db",
  password: "postgres",
  port: 5432,
});

async function activateAllUnits() {
  const client = await pool.connect();

  try {
    console.log("🔄 Mengaktifkan semua unit...");

    const result = await client.query(
      `UPDATE units SET is_active = true WHERE is_active = false`
    );

    console.log(`✅ Berhasil mengaktifkan ${result.rowCount} unit`);

    // Tampilkan semua unit yang aktif
    const units = await client.query(
      `SELECT id, name, is_active FROM units ORDER BY name`
    );

    console.log("\n📋 Daftar Unit:");
    units.rows.forEach((unit) => {
      console.log(
        `   ${unit.id}. ${unit.name} - ${
          unit.is_active ? "✅ Aktif" : "❌ Tidak Aktif"
        }`
      );
    });
  } catch (error) {
    console.error("❌ Error:", error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

activateAllUnits();
