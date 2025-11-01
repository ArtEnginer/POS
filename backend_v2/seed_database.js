/**
 * ============================================
 * DATABASE SEEDER - SAMPLE DATA
 * ============================================
 *
 * Script ini akan insert data sample untuk:
 * - Users (admin, manager, cashier)
 * - Branches (Head Office + 3 cabang)
 * - Categories (hierarchical)
 * - Suppliers (3 suppliers)
 * - Customers (5 customers)
 * - Products (20 products dengan stock)
 *
 * Run dengan: node seed_database.js
 * atau: npm run db:seed
 */

import pg from "pg";
import bcrypt from "bcryptjs";
import dotenv from "dotenv";

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "admin123",
});

async function seedDatabase() {
  const client = await pool.connect();

  try {
    console.log(
      "╔══════════════════════════════════════════════════════════════════╗"
    );
    console.log(
      "║          POS ENTERPRISE - DATABASE SEEDER                        ║"
    );
    console.log(
      "║          Insert Sample Data for Testing                          ║"
    );
    console.log(
      "╚══════════════════════════════════════════════════════════════════╝"
    );
    console.log("");

    await client.query("BEGIN");

    // ============================================
    // 1. BRANCHES
    // ============================================
    console.log("🏢 Seeding Branches...");

    const branches = [
      {
        code: "HQ",
        name: "Head Office",
        address: "Jl. Sudirman No. 123",
        city: "Jakarta",
        phone: "021-12345678",
        email: "hq@pos.com",
        is_head_office: true,
      },
      {
        code: "JKT-01",
        name: "Jakarta Pusat",
        address: "Jl. Thamrin No. 45",
        city: "Jakarta",
        phone: "021-87654321",
        email: "jkt01@pos.com",
        is_head_office: false,
      },
      {
        code: "BDG-01",
        name: "Bandung",
        address: "Jl. Braga No. 67",
        city: "Bandung",
        phone: "022-11223344",
        email: "bdg01@pos.com",
        is_head_office: false,
      },
      {
        code: "SBY-01",
        name: "Surabaya",
        address: "Jl. Pemuda No. 89",
        city: "Surabaya",
        phone: "031-55667788",
        email: "sby01@pos.com",
        is_head_office: false,
      },
    ];

    for (const branch of branches) {
      const apiKey = `${branch.code}-${Date.now()}-${Math.random()
        .toString(36)
        .substring(7)}`;

      await client.query(
        `INSERT INTO branches (code, name, address, city, phone, email, is_head_office, api_key, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
         ON CONFLICT (code) DO UPDATE SET
           name = EXCLUDED.name,
           address = EXCLUDED.address,
           city = EXCLUDED.city,
           phone = EXCLUDED.phone,
           email = EXCLUDED.email`,
        [
          branch.code,
          branch.name,
          branch.address,
          branch.city,
          branch.phone,
          branch.email,
          branch.is_head_office,
          apiKey,
        ]
      );
    }

    console.log(`   ✅ ${branches.length} branches inserted`);

    // ============================================
    // 2. USERS
    // ============================================
    console.log("👤 Seeding Users...");

    const password = "admin123";
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(password, salt);

    const users = [
      {
        username: "admin",
        email: "admin@pos.com",
        full_name: "System Administrator",
        role: "super_admin",
        phone: "081234567890",
      },
      {
        username: "manager",
        email: "manager@pos.com",
        full_name: "Store Manager",
        role: "manager",
        phone: "081234567891",
      },
      {
        username: "cashier1",
        email: "cashier1@pos.com",
        full_name: "Kasir Satu",
        role: "cashier",
        phone: "081234567892",
      },
      {
        username: "cashier2",
        email: "cashier2@pos.com",
        full_name: "Kasir Dua",
        role: "cashier",
        phone: "081234567893",
      },
      {
        username: "staff1",
        email: "staff1@pos.com",
        full_name: "Staff Gudang",
        role: "staff",
        phone: "081234567894",
      },
    ];

    for (const user of users) {
      await client.query(
        `INSERT INTO users (username, email, password_hash, full_name, role, phone, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'active')
         ON CONFLICT (username) DO UPDATE SET
           email = EXCLUDED.email,
           full_name = EXCLUDED.full_name,
           phone = EXCLUDED.phone`,
        [user.username, user.email, hash, user.full_name, user.role, user.phone]
      );
    }

    console.log(`   ✅ ${users.length} users inserted (password: admin123)`);

    // ============================================
    // 3. USER BRANCHES (Assign users to branches)
    // ============================================
    console.log("🔗 Assigning Users to Branches...");

    const userBranchAssignments = [
      { username: "admin", branchCode: "HQ", isDefault: true },
      { username: "admin", branchCode: "JKT-01", isDefault: false },
      { username: "admin", branchCode: "BDG-01", isDefault: false },
      { username: "admin", branchCode: "SBY-01", isDefault: false },
      { username: "manager", branchCode: "JKT-01", isDefault: true },
      { username: "cashier1", branchCode: "JKT-01", isDefault: true },
      { username: "cashier2", branchCode: "BDG-01", isDefault: true },
      { username: "staff1", branchCode: "HQ", isDefault: true },
    ];

    for (const assignment of userBranchAssignments) {
      await client.query(
        `INSERT INTO user_branches (user_id, branch_id, is_default)
         SELECT u.id, b.id, $3
         FROM users u, branches b
         WHERE u.username = $1 AND b.code = $2
         ON CONFLICT (user_id, branch_id) DO UPDATE SET is_default = EXCLUDED.is_default`,
        [assignment.username, assignment.branchCode, assignment.isDefault]
      );
    }

    console.log(
      `   ✅ ${userBranchAssignments.length} user-branch assignments created`
    );

    // ============================================
    // 4. CATEGORIES
    // ============================================
    console.log("📁 Seeding Categories...");

    const categories = [
      {
        name: "Makanan & Minuman",
        description: "Produk makanan dan minuman",
        parent: null,
      },
      { name: "Elektronik", description: "Produk elektronik", parent: null },
      {
        name: "Pakaian",
        description: "Produk pakaian dan fashion",
        parent: null,
      },
      {
        name: "Alat Tulis",
        description: "Peralatan tulis dan kantor",
        parent: null,
      },
      {
        name: "Makanan Ringan",
        description: "Snack dan cemilan",
        parent: "Makanan & Minuman",
      },
      {
        name: "Minuman",
        description: "Minuman kemasan",
        parent: "Makanan & Minuman",
      },
      {
        name: "Handphone",
        description: "Smartphone dan accessories",
        parent: "Elektronik",
      },
      {
        name: "Komputer",
        description: "Laptop dan PC accessories",
        parent: "Elektronik",
      },
    ];

    for (const category of categories) {
      if (category.parent) {
        await client.query(
          `INSERT INTO categories (name, description, parent_id, is_active)
           SELECT $1, $2, c.id, true
           FROM categories c
           WHERE c.name = $3
           ON CONFLICT DO NOTHING`,
          [category.name, category.description, category.parent]
        );
      } else {
        await client.query(
          `INSERT INTO categories (name, description, is_active)
           VALUES ($1, $2, true)
           ON CONFLICT DO NOTHING`,
          [category.name, category.description]
        );
      }
    }

    console.log(`   ✅ ${categories.length} categories inserted`);

    // ============================================
    // 5. SUPPLIERS
    // ============================================
    console.log("🚚 Seeding Suppliers...");

    const suppliers = [
      {
        code: "SUP-001",
        name: "PT Sumber Makmur",
        email: "supplier1@example.com",
        phone: "021-99887766",
        address: "Jl. Industri No. 12, Jakarta",
        city: "Jakarta",
        payment_terms: 30, // Net 30 days
      },
      {
        code: "SUP-002",
        name: "CV Maju Jaya",
        email: "supplier2@example.com",
        phone: "022-44556677",
        address: "Jl. Raya No. 34, Bandung",
        city: "Bandung",
        payment_terms: 14, // Net 14 days
      },
      {
        code: "SUP-003",
        name: "UD Berkah Abadi",
        email: "supplier3@example.com",
        phone: "031-77889900",
        address: "Jl. Perdagangan No. 56, Surabaya",
        city: "Surabaya",
        payment_terms: 0, // Cash
      },
    ];

    for (const supplier of suppliers) {
      await client.query(
        `INSERT INTO suppliers (code, name, email, phone, address, city, payment_terms, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true)
         ON CONFLICT (code) DO UPDATE SET
           name = EXCLUDED.name,
           email = EXCLUDED.email,
           phone = EXCLUDED.phone`,
        [
          supplier.code,
          supplier.name,
          supplier.email,
          supplier.phone,
          supplier.address,
          supplier.city,
          supplier.payment_terms,
        ]
      );
    }

    console.log(`   ✅ ${suppliers.length} suppliers inserted`);

    // ============================================
    // 6. CUSTOMERS
    // ============================================
    console.log("🧑‍🤝‍🧑 Seeding Customers...");

    const customers = [
      {
        code: "CUST-001",
        name: "Budi Santoso",
        email: "budi@example.com",
        phone: "081234560001",
        address: "Jl. Merdeka No. 10",
        city: "Jakarta",
        customer_type: "regular",
      },
      {
        code: "CUST-002",
        name: "Siti Nurhaliza",
        email: "siti@example.com",
        phone: "081234560002",
        address: "Jl. Kemerdekaan No. 20",
        city: "Bandung",
        customer_type: "vip",
      },
      {
        code: "CUST-003",
        name: "PT Sentosa Jaya",
        email: "sentosa@example.com",
        phone: "081234560003",
        address: "Jl. Industri No. 30",
        city: "Surabaya",
        customer_type: "wholesale",
      },
      {
        code: "CUST-004",
        name: "Ahmad Wijaya",
        email: "ahmad@example.com",
        phone: "081234560004",
        address: "Jl. Pahlawan No. 40",
        city: "Jakarta",
        customer_type: "retail",
      },
      {
        code: "CUST-005",
        name: "Dewi Lestari",
        email: "dewi@example.com",
        phone: "081234560005",
        address: "Jl. Sudirman No. 50",
        city: "Jakarta",
        customer_type: "vip",
      },
    ];

    for (const customer of customers) {
      await client.query(
        `INSERT INTO customers (code, name, email, phone, address, city, customer_type, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true)
         ON CONFLICT (code) DO UPDATE SET
           name = EXCLUDED.name,
           email = EXCLUDED.email,
           phone = EXCLUDED.phone`,
        [
          customer.code,
          customer.name,
          customer.email,
          customer.phone,
          customer.address,
          customer.city,
          customer.customer_type,
        ]
      );
    }

    console.log(`   ✅ ${customers.length} customers inserted`);

    // ============================================
    // 7. PRODUCTS
    // ============================================
    console.log("📦 Seeding Products...");

    const products = [
      {
        sku: "PRD-001",
        barcode: "1234567890001",
        name: "Indomie Goreng",
        category: "Makanan Ringan",
        base_unit: "PCS",
        min: 50,
        max: 500,
        reorder: 100,
      },
      {
        sku: "PRD-002",
        barcode: "1234567890002",
        name: "Aqua 600ml",
        category: "Minuman",
        base_unit: "BTL",
        min: 100,
        max: 1000,
        reorder: 200,
      },
      {
        sku: "PRD-003",
        barcode: "1234567890003",
        name: "Beras Premium",
        category: "Makanan & Minuman",
        base_unit: "KG",
        min: 20,
        max: 200,
        reorder: 50,
      },
      {
        sku: "PRD-004",
        barcode: "1234567890004",
        name: "Minyak Goreng",
        category: "Makanan & Minuman",
        base_unit: "LITER",
        min: 10,
        max: 100,
        reorder: 25,
      },
      {
        sku: "PRD-005",
        barcode: "1234567890005",
        name: "Gula Pasir",
        category: "Makanan & Minuman",
        base_unit: "KG",
        min: 30,
        max: 300,
        reorder: 75,
      },
      {
        sku: "PRD-006",
        barcode: "1234567890006",
        name: "Chitato BBQ",
        category: "Makanan Ringan",
        base_unit: "PCS",
        min: 20,
        max: 200,
        reorder: 50,
      },
      {
        sku: "PRD-007",
        barcode: "1234567890007",
        name: "Coca Cola 390ml",
        category: "Minuman",
        base_unit: "BTL",
        min: 50,
        max: 500,
        reorder: 100,
      },
      {
        sku: "PRD-008",
        barcode: "1234567890008",
        name: "Pulpen Standard",
        category: "Alat Tulis",
        base_unit: "PCS",
        min: 100,
        max: 1000,
        reorder: 200,
      },
      {
        sku: "PRD-009",
        barcode: "1234567890009",
        name: "Buku Tulis 58lbr",
        category: "Alat Tulis",
        base_unit: "PCS",
        min: 50,
        max: 500,
        reorder: 100,
      },
      {
        sku: "PRD-010",
        barcode: "1234567890010",
        name: "Pensil 2B",
        category: "Alat Tulis",
        base_unit: "PCS",
        min: 100,
        max: 1000,
        reorder: 200,
      },
      {
        sku: "PRD-011",
        barcode: "1234567890011",
        name: "Kaos Polos Putih",
        category: "Pakaian",
        base_unit: "PCS",
        min: 10,
        max: 100,
        reorder: 20,
      },
      {
        sku: "PRD-012",
        barcode: "1234567890012",
        name: "Celana Jeans",
        category: "Pakaian",
        base_unit: "PCS",
        min: 5,
        max: 50,
        reorder: 10,
      },
      {
        sku: "PRD-013",
        barcode: "1234567890013",
        name: "Mouse USB",
        category: "Komputer",
        base_unit: "PCS",
        min: 10,
        max: 100,
        reorder: 20,
      },
      {
        sku: "PRD-014",
        barcode: "1234567890014",
        name: "Keyboard USB",
        category: "Komputer",
        base_unit: "PCS",
        min: 5,
        max: 50,
        reorder: 10,
      },
      {
        sku: "PRD-015",
        barcode: "1234567890015",
        name: "Kabel Data Type-C",
        category: "Handphone",
        base_unit: "PCS",
        min: 20,
        max: 200,
        reorder: 50,
      },
      {
        sku: "PRD-016",
        barcode: "1234567890016",
        name: "Tempered Glass",
        category: "Handphone",
        base_unit: "PCS",
        min: 30,
        max: 300,
        reorder: 75,
      },
      {
        sku: "PRD-017",
        barcode: "1234567890017",
        name: "Kopi Sachet",
        category: "Minuman",
        base_unit: "PCS",
        min: 200,
        max: 2000,
        reorder: 500,
      },
      {
        sku: "PRD-018",
        barcode: "1234567890018",
        name: "Teh Celup",
        category: "Minuman",
        base_unit: "PCS",
        min: 200,
        max: 2000,
        reorder: 500,
      },
      {
        sku: "PRD-019",
        barcode: "1234567890019",
        name: "Sabun Mandi",
        category: "Makanan & Minuman",
        base_unit: "PCS",
        min: 50,
        max: 500,
        reorder: 100,
      },
      {
        sku: "PRD-020",
        barcode: "1234567890020",
        name: "Shampoo Sachet",
        category: "Makanan & Minuman",
        base_unit: "PCS",
        min: 100,
        max: 1000,
        reorder: 200,
      },
    ];

    for (const product of products) {
      await client.query(
        `INSERT INTO products (sku, barcode, name, category_id, base_unit, min_stock, max_stock, reorder_point, is_active, is_trackable)
         SELECT $1, $2, $3, c.id, $4, $5, $6, $7, true, true
         FROM categories c
         WHERE c.name = $8
         ON CONFLICT (sku) DO UPDATE SET
           name = EXCLUDED.name,
           base_unit = EXCLUDED.base_unit`,
        [
          product.sku,
          product.barcode,
          product.name,
          product.base_unit,
          product.min,
          product.max,
          product.reorder,
          product.category,
        ]
      );
    }

    console.log(`   ✅ ${products.length} products inserted`);

    // ============================================
    // 8. PRODUCT STOCKS (untuk setiap branch)
    // ============================================
    console.log("📊 Seeding Product Stocks...");

    const branchCodes = ["HQ", "JKT-01", "BDG-01", "SBY-01"];
    let stockCount = 0;

    for (const branchCode of branchCodes) {
      for (const product of products) {
        // Random stock antara min dan max
        const randomStock =
          Math.floor(Math.random() * (product.max - product.min + 1)) +
          product.min;

        await client.query(
          `INSERT INTO product_stocks (product_id, branch_id, quantity, reserved_quantity)
           SELECT p.id, b.id, $3, 0
           FROM products p, branches b
           WHERE p.sku = $1 AND b.code = $2
           ON CONFLICT (product_id, branch_id) DO UPDATE SET
             quantity = EXCLUDED.quantity`,
          [product.sku, branchCode, randomStock]
        );
        stockCount++;
      }
    }

    console.log(`   ✅ ${stockCount} product stocks inserted`);

    await client.query("COMMIT");

    console.log("");
    console.log(
      "╔══════════════════════════════════════════════════════════════════╗"
    );
    console.log(
      "║                ✅ SEEDING COMPLETED!                              ║"
    );
    console.log(
      "╚══════════════════════════════════════════════════════════════════╝"
    );
    console.log("");
    console.log("📊 SUMMARY:");
    console.log(`   - Branches: ${branches.length}`);
    console.log(`   - Users: ${users.length} (password: admin123)`);
    console.log(
      `   - User-Branch Assignments: ${userBranchAssignments.length}`
    );
    console.log(`   - Categories: ${categories.length}`);
    console.log(`   - Suppliers: ${suppliers.length}`);
    console.log(`   - Customers: ${customers.length}`);
    console.log(`   - Products: ${products.length}`);
    console.log(
      `   - Product Stocks: ${stockCount} (across ${branchCodes.length} branches)`
    );
    console.log("");
    console.log("👤 TEST USERS:");
    console.log("   admin / admin123 (super_admin)");
    console.log("   manager / admin123 (manager)");
    console.log("   cashier1 / admin123 (cashier)");
    console.log("   cashier2 / admin123 (cashier)");
    console.log("   staff1 / admin123 (staff)");
    console.log("");
    console.log("🏢 BRANCHES:");
    console.log("   HQ - Head Office (Jakarta)");
    console.log("   JKT-01 - Jakarta Pusat");
    console.log("   BDG-01 - Bandung");
    console.log("   SBY-01 - Surabaya");
    console.log("");
    console.log("✅ Database ready for testing!");
    console.log("");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("");
    console.error("❌ SEEDING FAILED!");
    console.error("");
    console.error("Error:", error.message);

    if (error.stack) {
      console.error("");
      console.error("Stack trace:");
      console.error(error.stack);
    }

    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run seeder
console.log("");
seedDatabase().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
