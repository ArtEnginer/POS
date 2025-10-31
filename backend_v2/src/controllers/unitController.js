import db from "../config/database.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";
import { emitEvent } from "../utils/socket-io.js";

/**
 * Get all units
 * GET /api/v2/units
 */
export const getAllUnits = async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        name,
        description,
        is_active,
        created_at,
        updated_at
      FROM units
      WHERE deleted_at IS NULL
      ORDER BY name ASC
    `;

    const result = await db.query(query);
    const units = result.rows;

    res.json({
      success: true,
      data: units.map((unit) => ({
        id: unit.id,
        name: unit.name,
        description: unit.description,
        isActive: unit.is_active === 1,
        createdAt: unit.created_at,
        updatedAt: unit.updated_at,
      })),
    });
  } catch (error) {
    logger.error("Error fetching units:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch units",
      error: error.message,
    });
  }
};

/**
 * Get unit by ID
 * GET /api/v2/units/:id
 */
export const getUnitById = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT 
        id,
        name,
        description,
        is_active,
        created_at,
        updated_at
      FROM units
      WHERE id = $1 AND deleted_at IS NULL
    `;

    const result = await db.query(query, [id]);

    if (result.rows.length === 0) {
      throw new NotFoundError("Unit");
    }

    const unit = result.rows[0];
    res.json({
      success: true,
      data: {
        id: unit.id,
        name: unit.name,
        description: unit.description,
        isActive: unit.is_active === 1,
        createdAt: unit.created_at,
        updatedAt: unit.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error fetching unit:", error);
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to fetch unit",
        error: error.message,
      });
    }
  }
};

/**
 * Create new unit
 * POST /api/v2/units
 */
export const createUnit = async (req, res) => {
  try {
    const { name, description, is_active } = req.body;

    // Validation
    if (!name || name.trim() === "") {
      throw new ValidationError("Unit name is required");
    }

    // Check if unit name already exists
    const existingUnit = await db.query(
      "SELECT id FROM units WHERE UPPER(name) = UPPER($1) AND deleted_at IS NULL",
      [name.trim()]
    );

    if (existingUnit.rows.length > 0) {
      throw new ValidationError("Unit name already exists");
    }

    const query = `
      INSERT INTO units (
        name,
        description,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, NOW(), NOW())
      RETURNING *
    `;

    const result = await db.query(query, [
      name.trim().toUpperCase(),
      description || null,
      is_active !== undefined ? is_active : true,
    ]);

    const unit = result.rows[0];

    // 🚀 EMIT REAL-TIME EVENT: Unit Created
    emitEvent("unit:created", {
      action: "created",
      unit: unit,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: unit:created for ${unit.id}`);

    res.status(201).json({
      success: true,
      message: "Unit created successfully",
      data: {
        id: unit.id,
        name: unit.name,
        description: unit.description,
        isActive: unit.is_active === 1,
        createdAt: unit.created_at,
        updatedAt: unit.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error creating unit:", error);
    if (error instanceof ValidationError) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to create unit",
        error: error.message,
      });
    }
  }
};

/**
 * Update unit
 * PUT /api/v2/units/:id
 */
export const updateUnit = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, is_active } = req.body;

    // Check if unit exists
    const existingResult = await db.query(
      "SELECT id FROM units WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingResult.rows.length === 0) {
      throw new NotFoundError("Unit");
    }

    // Validation
    if (name && name.trim() === "") {
      throw new ValidationError("Unit name cannot be empty");
    }

    // Check if new name already exists (excluding current unit)
    if (name) {
      const duplicateCheck = await db.query(
        "SELECT id FROM units WHERE UPPER(name) = UPPER($1) AND id != $2 AND deleted_at IS NULL",
        [name.trim(), id]
      );

      if (duplicateCheck.rows.length > 0) {
        throw new ValidationError("Unit name already exists");
      }
    }

    const query = `
      UPDATE units 
      SET 
        name = COALESCE($1, name),
        description = COALESCE($2, description),
        is_active = COALESCE($3, is_active),
        updated_at = NOW()
      WHERE id = $4
      RETURNING *
    `;

    const result = await db.query(query, [
      name ? name.trim().toUpperCase() : null,
      description !== undefined ? description : null,
      is_active !== undefined ? is_active : null,
      id,
    ]);

    const unit = result.rows[0];

    // 🚀 EMIT REAL-TIME EVENT: Unit Updated
    emitEvent("unit:updated", {
      action: "updated",
      unit: unit,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: unit:updated for ${id}`);

    res.json({
      success: true,
      message: "Unit updated successfully",
      data: {
        id: unit.id,
        name: unit.name,
        description: unit.description,
        isActive: unit.is_active === 1,
        createdAt: unit.created_at,
        updatedAt: unit.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error updating unit:", error);
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        message: error.message,
      });
    } else if (error instanceof ValidationError) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to update unit",
        error: error.message,
      });
    }
  }
};

/**
 * Delete unit (soft delete)
 * DELETE /api/v2/units/:id
 */
export const deleteUnit = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if unit exists
    const existingResult = await db.query(
      "SELECT id, name FROM units WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingResult.rows.length === 0) {
      throw new NotFoundError("Unit");
    }

    const unitName = existingResult.rows[0].name;

    // Check if unit is used by products
    const productsResult = await db.query(
      "SELECT COUNT(*) as count FROM products WHERE UPPER(unit) = UPPER($1) AND deleted_at IS NULL",
      [unitName]
    );

    if (parseInt(productsResult.rows[0].count) > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete unit. It is used by ${productsResult.rows[0].count} product(s)`,
      });
    }

    // Soft delete
    await db.query("UPDATE units SET deleted_at = NOW() WHERE id = $1", [id]);

    // 🚀 EMIT REAL-TIME EVENT: Unit Deleted
    emitEvent("unit:deleted", {
      action: "deleted",
      unitId: id,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: unit:deleted for ${id}`);

    res.json({
      success: true,
      message: "Unit deleted successfully",
    });
  } catch (error) {
    logger.error("Error deleting unit:", error);
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to delete unit",
        error: error.message,
      });
    }
  }
};
