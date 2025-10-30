import db from "../config/database.js";
import logger from "../utils/logger.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";

/**
 * Get cashier settings for current user and branch
 */
export const getCashierSettings = async (req, res) => {
  const { userId, branchId } = req.user;

  const result = await db.query(
    `SELECT * FROM cashier_settings 
     WHERE user_id = $1 AND branch_id = $2 AND deleted_at IS NULL`,
    [userId, branchId]
  );

  if (result.rows.length === 0) {
    // Create default settings if not exists
    const defaultSettings = await db.query(
      `INSERT INTO cashier_settings (
        user_id, branch_id, device_name, cashier_location, counter_number
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [userId, branchId, "Kasir-1", "Default Location", "1"]
    );

    return res.json({
      success: true,
      data: defaultSettings.rows[0],
      message: "Default cashier settings created",
    });
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
};

/**
 * Update cashier settings
 */
export const updateCashierSettings = async (req, res) => {
  const { userId, branchId } = req.user;
  const {
    deviceName,
    deviceType,
    deviceIdentifier,
    cashierLocation,
    counterNumber,
    floorLevel,
    receiptPrinter,
    cashDrawerPort,
    displayType,
    themePreference,
    isActive,
    allowOfflineMode,
    autoPrintReceipt,
    requireCustomerDisplay,
    settings,
  } = req.body;

  // Check if settings exist
  const existing = await db.query(
    "SELECT * FROM cashier_settings WHERE user_id = $1 AND branch_id = $2",
    [userId, branchId]
  );

  let result;

  if (existing.rows.length === 0) {
    // Create new settings
    result = await db.query(
      `INSERT INTO cashier_settings (
        user_id, branch_id, device_name, device_type, device_identifier,
        cashier_location, counter_number, floor_level,
        receipt_printer, cash_drawer_port, display_type, theme_preference,
        is_active, allow_offline_mode, auto_print_receipt, require_customer_display,
        settings
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
      RETURNING *`,
      [
        userId,
        branchId,
        deviceName || "Kasir-1",
        deviceType || "windows",
        deviceIdentifier,
        cashierLocation,
        counterNumber,
        floorLevel,
        receiptPrinter,
        cashDrawerPort,
        displayType || "standard",
        themePreference || "light",
        isActive !== undefined ? isActive : true,
        allowOfflineMode !== undefined ? allowOfflineMode : true,
        autoPrintReceipt !== undefined ? autoPrintReceipt : true,
        requireCustomerDisplay !== undefined ? requireCustomerDisplay : false,
        settings ? JSON.stringify(settings) : "{}",
      ]
    );

    logger.info(
      `Cashier settings created for user ${userId} at branch ${branchId}`
    );
  } else {
    // Update existing settings
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (deviceName !== undefined) {
      updates.push(`device_name = $${paramIndex++}`);
      values.push(deviceName);
    }
    if (deviceType !== undefined) {
      updates.push(`device_type = $${paramIndex++}`);
      values.push(deviceType);
    }
    if (deviceIdentifier !== undefined) {
      updates.push(`device_identifier = $${paramIndex++}`);
      values.push(deviceIdentifier);
    }
    if (cashierLocation !== undefined) {
      updates.push(`cashier_location = $${paramIndex++}`);
      values.push(cashierLocation);
    }
    if (counterNumber !== undefined) {
      updates.push(`counter_number = $${paramIndex++}`);
      values.push(counterNumber);
    }
    if (floorLevel !== undefined) {
      updates.push(`floor_level = $${paramIndex++}`);
      values.push(floorLevel);
    }
    if (receiptPrinter !== undefined) {
      updates.push(`receipt_printer = $${paramIndex++}`);
      values.push(receiptPrinter);
    }
    if (cashDrawerPort !== undefined) {
      updates.push(`cash_drawer_port = $${paramIndex++}`);
      values.push(cashDrawerPort);
    }
    if (displayType !== undefined) {
      updates.push(`display_type = $${paramIndex++}`);
      values.push(displayType);
    }
    if (themePreference !== undefined) {
      updates.push(`theme_preference = $${paramIndex++}`);
      values.push(themePreference);
    }
    if (isActive !== undefined) {
      updates.push(`is_active = $${paramIndex++}`);
      values.push(isActive);
    }
    if (allowOfflineMode !== undefined) {
      updates.push(`allow_offline_mode = $${paramIndex++}`);
      values.push(allowOfflineMode);
    }
    if (autoPrintReceipt !== undefined) {
      updates.push(`auto_print_receipt = $${paramIndex++}`);
      values.push(autoPrintReceipt);
    }
    if (requireCustomerDisplay !== undefined) {
      updates.push(`require_customer_display = $${paramIndex++}`);
      values.push(requireCustomerDisplay);
    }
    if (settings !== undefined) {
      updates.push(`settings = $${paramIndex++}`);
      values.push(JSON.stringify(settings));
    }

    updates.push(`updated_at = NOW()`);

    values.push(userId, branchId);

    result = await db.query(
      `UPDATE cashier_settings 
       SET ${updates.join(", ")}
       WHERE user_id = $${paramIndex++} AND branch_id = $${paramIndex++}
       RETURNING *`,
      values
    );

    logger.info(
      `Cashier settings updated for user ${userId} at branch ${branchId}`
    );
  }

  res.json({
    success: true,
    data: result.rows[0],
    message: "Cashier settings saved successfully",
  });
};

/**
 * Get all cashier settings for a branch (admin only)
 */
export const getBranchCashierSettings = async (req, res) => {
  const { branchId } = req.params;

  const result = await db.query(
    `SELECT cs.*, u.username, u.full_name, u.role
     FROM cashier_settings cs
     JOIN users u ON cs.user_id = u.id
     WHERE cs.branch_id = $1
     ORDER BY u.full_name`,
    [branchId]
  );

  res.json({
    success: true,
    data: result.rows,
    count: result.rows.length,
  });
};

/**
 * Delete cashier settings
 */
export const deleteCashierSettings = async (req, res) => {
  const { userId, branchId } = req.user;

  const result = await db.query(
    "DELETE FROM cashier_settings WHERE user_id = $1 AND branch_id = $2 RETURNING *",
    [userId, branchId]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError("Cashier settings not found");
  }

  logger.info(
    `Cashier settings deleted for user ${userId} at branch ${branchId}`
  );

  res.json({
    success: true,
    message: "Cashier settings deleted successfully",
  });
};
