import db from "../config/database.js";

class DashboardController {
  /**
   * Get dashboard overview statistics
   * GET /api/v2/dashboard/overview
   */
  async getOverview(req, res) {
    try {
      const branchId = req.user?.branch_id;

      // Get total products count
      const productsResult = await db.query(
        branchId
          ? "SELECT COUNT(DISTINCT p.id) as count FROM products p LEFT JOIN product_stocks ps ON p.id = ps.product_id WHERE (ps.branch_id = $1 OR ps.branch_id IS NULL) AND p.deleted_at IS NULL"
          : "SELECT COUNT(*) as count FROM products WHERE deleted_at IS NULL",
        branchId ? [branchId] : []
      );
      const totalProducts = parseInt(productsResult.rows[0].count);

      // Get low stock products count (quantity < min_stock)
      const lowStockResult = await db.query(
        branchId
          ? `SELECT COUNT(*) as count 
             FROM products p 
             INNER JOIN product_stocks ps ON p.id = ps.product_id 
             WHERE ps.branch_id = $1 
             AND ps.available_quantity < p.min_stock 
             AND p.deleted_at IS NULL`
          : `SELECT COUNT(*) as count 
             FROM products p 
             INNER JOIN product_stocks ps ON p.id = ps.product_id 
             WHERE ps.available_quantity < p.min_stock 
             AND p.deleted_at IS NULL`,
        branchId ? [branchId] : []
      );
      const lowStockProducts = parseInt(lowStockResult.rows[0].count);

      // Get total customers count (no branch filter - customers are global)
      const customersResult = await db.query(
        "SELECT COUNT(*) as count FROM customers WHERE deleted_at IS NULL"
      );
      const totalCustomers = parseInt(customersResult.rows[0].count);

      // Get total suppliers count (no branch filter - suppliers are global)
      const suppliersResult = await db.query(
        "SELECT COUNT(*) as count FROM suppliers WHERE deleted_at IS NULL"
      );
      const totalSuppliers = parseInt(suppliersResult.rows[0].count);

      // Get purchase statistics
      const purchaseStatsResult = await db.query(
        branchId
          ? `SELECT 
              COUNT(*) as total_purchases,
              COALESCE(SUM(CASE WHEN status IN ('draft', 'ordered', 'approved') THEN 1 ELSE 0 END), 0) as pending_purchases,
              COALESCE(SUM(total_amount), 0) as total_purchase_amount
            FROM purchases 
            WHERE branch_id = $1 AND deleted_at IS NULL`
          : `SELECT 
              COUNT(*) as total_purchases,
              COALESCE(SUM(CASE WHEN status IN ('draft', 'ordered', 'approved') THEN 1 ELSE 0 END), 0) as pending_purchases,
              COALESCE(SUM(total_amount), 0) as total_purchase_amount
            FROM purchases 
            WHERE deleted_at IS NULL`,
        branchId ? [branchId] : []
      );
      const purchaseStats = purchaseStatsResult.rows[0];

      // Get sales statistics
      const salesStatsResult = await db.query(
        branchId
          ? `SELECT 
              COUNT(*) as total_sales,
              COALESCE(SUM(total_amount), 0) as total_sales_amount
            FROM sales 
            WHERE branch_id = $1 AND deleted_at IS NULL`
          : `SELECT 
              COUNT(*) as total_sales,
              COALESCE(SUM(total_amount), 0) as total_sales_amount
            FROM sales 
            WHERE deleted_at IS NULL`,
        branchId ? [branchId] : []
      );
      const salesStats = salesStatsResult.rows[0];

      // Build response
      const overview = {
        total_products: totalProducts,
        low_stock_products: lowStockProducts,
        total_customers: totalCustomers,
        total_suppliers: totalSuppliers,
        total_purchases: parseInt(purchaseStats.total_purchases),
        pending_purchases: parseInt(purchaseStats.pending_purchases),
        total_purchase_amount: parseFloat(
          purchaseStats.total_purchase_amount || 0
        ),
        total_sales: parseInt(salesStats.total_sales || 0),
        total_sales_amount: parseFloat(salesStats.total_sales_amount || 0),
        last_updated: new Date().toISOString(),
      };

      res.json({
        success: true,
        message: "Dashboard overview retrieved successfully",
        data: overview,
      });
    } catch (error) {
      console.error("Error getting dashboard overview:", error);
      res.status(500).json({
        success: false,
        message: "Failed to retrieve dashboard overview",
        error: error.message,
      });
    }
  }
}

export default new DashboardController();
