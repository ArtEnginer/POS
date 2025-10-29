import db from "../config/database.js";
import { NotFoundError, ValidationError } from "../middleware/errorHandler.js";
import logger from "../utils/logger.js";
import { emitEvent } from "../utils/socket-io.js";

/**
 * Get all categories
 * GET /api/v2/categories
 */
export const getAllCategories = async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        name,
        description,
        parent_id,
        icon,
        is_active,
        created_at,
        updated_at
      FROM categories
      WHERE deleted_at IS NULL
      ORDER BY name ASC
    `;

    const result = await db.query(query);
    const categories = result.rows;

    res.json({
      success: true,
      data: categories.map((cat) => ({
        id: cat.id,
        name: cat.name,
        description: cat.description,
        parentId: cat.parent_id,
        icon: cat.icon,
        isActive: cat.is_active === 1,
        createdAt: cat.created_at,
        updatedAt: cat.updated_at,
      })),
    });
  } catch (error) {
    logger.error("Error fetching categories:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch categories",
      error: error.message,
    });
  }
};

/**
 * Get category by ID
 * GET /api/v2/categories/:id
 */
export const getCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT 
        id,
        name,
        description,
        parent_id,
        icon,
        is_active,
        created_at,
        updated_at
      FROM categories
      WHERE id = $1 AND deleted_at IS NULL
    `;

    const result = await db.query(query, [id]);

    if (result.rows.length === 0) {
      throw new NotFoundError("Category");
    }

    const cat = result.rows[0];
    res.json({
      success: true,
      data: {
        id: cat.id,
        name: cat.name,
        description: cat.description,
        parentId: cat.parent_id,
        icon: cat.icon,
        isActive: cat.is_active === 1,
        createdAt: cat.created_at,
        updatedAt: cat.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error fetching category:", error);
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to fetch category",
        error: error.message,
      });
    }
  }
};

/**
 * Create new category
 * POST /api/v2/categories
 */
export const createCategory = async (req, res) => {
  try {
    const { name, description, parent_id, icon, is_active } = req.body;

    // Validation
    if (!name || name.trim() === "") {
      throw new ValidationError("Category name is required");
    }

    const query = `
      INSERT INTO categories (
        name,
        description,
        parent_id,
        icon,
        is_active,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
      RETURNING *
    `;

    const result = await db.query(query, [
      name.trim(),
      description || null,
      parent_id || null,
      icon || null,
      is_active !== undefined ? is_active : true,
    ]);

    const cat = result.rows[0];

    // 🚀 EMIT REAL-TIME EVENT: Category Created
    emitEvent("category:created", {
      action: "created",
      category: cat,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: category:created for ${cat.id}`);

    res.status(201).json({
      success: true,
      message: "Category created successfully",
      data: {
        id: cat.id,
        name: cat.name,
        description: cat.description,
        parentId: cat.parent_id,
        icon: cat.icon,
        isActive: cat.is_active === 1,
        createdAt: cat.created_at,
        updatedAt: cat.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error creating category:", error);
    if (error instanceof ValidationError) {
      res.status(400).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to create category",
        error: error.message,
      });
    }
  }
};

/**
 * Update category
 * PUT /api/v2/categories/:id
 */
export const updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, parent_id, icon, is_active } = req.body;

    // Check if category exists
    const existingResult = await db.query(
      "SELECT id FROM categories WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingResult.rows.length === 0) {
      throw new NotFoundError("Category");
    }

    // Validation
    if (name && name.trim() === "") {
      throw new ValidationError("Category name cannot be empty");
    }

    const query = `
      UPDATE categories 
      SET 
        name = COALESCE($1, name),
        description = COALESCE($2, description),
        parent_id = COALESCE($3, parent_id),
        icon = COALESCE($4, icon),
        is_active = COALESCE($5, is_active),
        updated_at = NOW()
      WHERE id = $6
      RETURNING *
    `;

    const result = await db.query(query, [
      name ? name.trim() : null,
      description !== undefined ? description : null,
      parent_id !== undefined ? parent_id : null,
      icon !== undefined ? icon : null,
      is_active !== undefined ? is_active : null,
      id,
    ]);

    const cat = result.rows[0];

    // 🚀 EMIT REAL-TIME EVENT: Category Updated
    emitEvent("category:updated", {
      action: "updated",
      category: cat,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: category:updated for ${id}`);

    res.json({
      success: true,
      message: "Category updated successfully",
      data: {
        id: cat.id,
        name: cat.name,
        description: cat.description,
        parentId: cat.parent_id,
        icon: cat.icon,
        isActive: cat.is_active === 1,
        createdAt: cat.created_at,
        updatedAt: cat.updated_at,
      },
    });
  } catch (error) {
    logger.error("Error updating category:", error);
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
        message: "Failed to update category",
        error: error.message,
      });
    }
  }
};

/**
 * Delete category (soft delete)
 * DELETE /api/v2/categories/:id
 */
export const deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if category exists
    const existingResult = await db.query(
      "SELECT id FROM categories WHERE id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (existingResult.rows.length === 0) {
      throw new NotFoundError("Category");
    }

    // Check if category is used by products
    const productsResult = await db.query(
      "SELECT COUNT(*) as count FROM products WHERE category_id = $1 AND deleted_at IS NULL",
      [id]
    );

    if (parseInt(productsResult.rows[0].count) > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete category. It is used by ${productsResult.rows[0].count} product(s)`,
      });
    }

    // Soft delete
    await db.query("UPDATE categories SET deleted_at = NOW() WHERE id = $1", [
      id,
    ]);

    // 🚀 EMIT REAL-TIME EVENT: Category Deleted
    emitEvent("category:deleted", {
      action: "deleted",
      categoryId: id,
      timestamp: new Date().toISOString(),
    });
    logger.info(`📢 WebSocket event emitted: category:deleted for ${id}`);

    res.json({
      success: true,
      message: "Category deleted successfully",
    });
  } catch (error) {
    logger.error("Error deleting category:", error);
    if (error instanceof NotFoundError) {
      res.status(404).json({
        success: false,
        message: error.message,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to delete category",
        error: error.message,
      });
    }
  }
};
