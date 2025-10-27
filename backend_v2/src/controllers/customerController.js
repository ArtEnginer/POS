import db from "../config/database.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";

/**
 * Get all customers with pagination and filters
 */
export const getAllCustomers = async (req, res) => {
  const { page = 1, limit = 100, search = "", isActive } = req.query;

  const offset = (page - 1) * limit;

  let query = `
    SELECT c.*
    FROM customers c
    WHERE c.deleted_at IS NULL
  `;

  const params = [];
  let paramIndex = 1;

  // Search filter
  if (search) {
    query += ` AND (
      c.name ILIKE $${paramIndex} OR 
      c.code ILIKE $${paramIndex} OR 
      c.phone ILIKE $${paramIndex} OR
      c.email ILIKE $${paramIndex}
    )`;
    params.push(`%${search}%`);
    paramIndex++;
  }

  // Active status filter
  if (isActive !== undefined) {
    query += ` AND c.is_active = $${paramIndex}`;
    params.push(isActive === "true");
    paramIndex++;
  }

  // Count total for pagination
  const countQuery = query.replace("SELECT c.*", "SELECT COUNT(*) as total");
  const countResult = await db.query(countQuery, params);
  const total = parseInt(countResult.rows[0].total);

  // Add pagination
  query += ` ORDER BY c.name ASC LIMIT $${paramIndex} OFFSET $${
    paramIndex + 1
  }`;
  params.push(limit, offset);

  const result = await db.query(query, params);

  res.json({
    success: true,
    data: result.rows,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
};

/**
 * Get customer by ID
 */
export const getCustomerById = async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT c.*
    FROM customers c
    WHERE c.id = $1 AND c.deleted_at IS NULL
  `;

  const result = await db.query(query, [id]);

  if (result.rows.length === 0) {
    throw new NotFoundError("Customer not found");
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
};

/**
 * Search customers
 */
export const searchCustomers = async (req, res) => {
  const { q: query } = req.query;

  if (!query) {
    throw new ValidationError("Search query is required");
  }

  const searchQuery = `
    SELECT c.*
    FROM customers c
    WHERE c.deleted_at IS NULL
    AND (
      c.name ILIKE $1 OR 
      c.code ILIKE $1 OR 
      c.phone ILIKE $1 OR
      c.email ILIKE $1
    )
    ORDER BY c.name ASC
    LIMIT 50
  `;

  const result = await db.query(searchQuery, [`%${query}%`]);

  res.json({
    success: true,
    data: result.rows,
  });
};

/**
 * Create new customer
 */
export const createCustomer = async (req, res) => {
  const {
    code,
    name,
    phone,
    email,
    address,
    city,
    customerType = "regular",
    taxId,
    creditLimit = 0,
    totalPoints = 0,
    isActive = true,
    notes,
  } = req.body;

  // Validation
  if (!name) {
    throw new ValidationError("Customer name is required");
  }

  // Check if code already exists
  if (code) {
    const codeCheck = await db.query(
      "SELECT id FROM customers WHERE code = $1 AND deleted_at IS NULL",
      [code]
    );
    if (codeCheck.rows.length > 0) {
      throw new ValidationError("Customer code already exists");
    }
  }

  // Check if email already exists
  if (email) {
    const emailCheck = await db.query(
      "SELECT id FROM customers WHERE email = $1 AND deleted_at IS NULL",
      [email]
    );
    if (emailCheck.rows.length > 0) {
      throw new ValidationError("Email already exists");
    }
  }

  const query = `
    INSERT INTO customers (
      code, name, phone, email, address, city, customer_type,
      tax_id, credit_limit, total_points, is_active, notes,
      created_at, updated_at
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
    RETURNING *
  `;

  const result = await db.query(query, [
    code,
    name,
    phone,
    email,
    address,
    city,
    customerType,
    taxId,
    creditLimit,
    totalPoints,
    isActive,
    notes,
  ]);

  logger.info(`Customer created: ${result.rows[0].id} - ${name}`);

  res.status(201).json({
    success: true,
    data: result.rows[0],
    message: "Customer created successfully",
  });
};

/**
 * Update customer
 */
export const updateCustomer = async (req, res) => {
  const { id } = req.params;
  const {
    code,
    name,
    phone,
    email,
    address,
    city,
    customerType,
    taxId,
    creditLimit,
    totalPoints,
    isActive,
    notes,
  } = req.body;

  // Check if customer exists
  const customerCheck = await db.query(
    "SELECT * FROM customers WHERE id = $1 AND deleted_at IS NULL",
    [id]
  );

  if (customerCheck.rows.length === 0) {
    throw new NotFoundError("Customer not found");
  }

  // Check if code already exists (excluding current customer)
  if (code && code !== customerCheck.rows[0].code) {
    const codeCheck = await db.query(
      "SELECT id FROM customers WHERE code = $1 AND id != $2 AND deleted_at IS NULL",
      [code, id]
    );
    if (codeCheck.rows.length > 0) {
      throw new ValidationError("Customer code already exists");
    }
  }

  // Check if email already exists (excluding current customer)
  if (email && email !== customerCheck.rows[0].email) {
    const emailCheck = await db.query(
      "SELECT id FROM customers WHERE email = $1 AND id != $2 AND deleted_at IS NULL",
      [email, id]
    );
    if (emailCheck.rows.length > 0) {
      throw new ValidationError("Email already exists");
    }
  }

  const query = `
    UPDATE customers
    SET code = $1, name = $2, phone = $3, email = $4, 
        address = $5, city = $6, customer_type = $7,
        tax_id = $8, credit_limit = $9, total_points = $10,
        is_active = $11, notes = $12, updated_at = NOW()
    WHERE id = $13 AND deleted_at IS NULL
    RETURNING *
  `;

  const result = await db.query(query, [
    code !== undefined ? code : customerCheck.rows[0].code,
    name !== undefined ? name : customerCheck.rows[0].name,
    phone !== undefined ? phone : customerCheck.rows[0].phone,
    email !== undefined ? email : customerCheck.rows[0].email,
    address !== undefined ? address : customerCheck.rows[0].address,
    city !== undefined ? city : customerCheck.rows[0].city,
    customerType !== undefined
      ? customerType
      : customerCheck.rows[0].customer_type,
    taxId !== undefined ? taxId : customerCheck.rows[0].tax_id,
    creditLimit !== undefined
      ? creditLimit
      : customerCheck.rows[0].credit_limit,
    totalPoints !== undefined
      ? totalPoints
      : customerCheck.rows[0].total_points,
    isActive !== undefined ? isActive : customerCheck.rows[0].is_active,
    notes !== undefined ? notes : customerCheck.rows[0].notes,
    id,
  ]);

  logger.info(`Customer updated: ${id} - ${result.rows[0].name}`);

  res.json({
    success: true,
    data: result.rows[0],
    message: "Customer updated successfully",
  });
};

/**
 * Delete customer (soft delete)
 */
export const deleteCustomer = async (req, res) => {
  const { id } = req.params;

  // Check if customer exists
  const customerCheck = await db.query(
    "SELECT * FROM customers WHERE id = $1 AND deleted_at IS NULL",
    [id]
  );

  if (customerCheck.rows.length === 0) {
    throw new NotFoundError("Customer not found");
  }

  // Soft delete with code modification to avoid unique constraint violation
  // Append timestamp to code when deleting to allow reusing the same code
  const timestamp = Date.now().toString();
  const query = `
    UPDATE customers
    SET code = code || '_deleted_' || $2,
        deleted_at = NOW(), 
        updated_at = NOW()
    WHERE id = $1
    RETURNING *
  `;

  const result = await db.query(query, [id, timestamp]);

  logger.info(`Customer deleted: ${id} - ${result.rows[0].name}`);

  res.json({
    success: true,
    message: "Customer deleted successfully",
  });
};

/**
 * Generate unique customer code
 */
export const generateCustomerCode = async (req, res) => {
  // Generate code format: CUST + year(2) + month(2) + sequential number(4)
  const now = new Date();
  const year = now.getFullYear().toString().slice(-2);
  const month = (now.getMonth() + 1).toString().padStart(2, "0");
  const prefix = `CUST${year}${month}`;

  // Get the last customer code with this prefix
  const query = `
    SELECT code FROM customers 
    WHERE code LIKE $1 AND deleted_at IS NULL
    ORDER BY code DESC 
    LIMIT 1
  `;

  const result = await db.query(query, [`${prefix}%`]);

  let sequential = 1;
  if (result.rows.length > 0) {
    const lastCode = result.rows[0].code;
    const lastSeq = parseInt(lastCode.slice(-4));
    sequential = lastSeq + 1;
  }

  const code = `${prefix}${sequential.toString().padStart(4, "0")}`;

  res.json({
    success: true,
    data: { code },
  });
};
