import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/branch_stock.dart';

/// Widget to display stock information for multiple branches
class MultiBranchStockWidget extends StatelessWidget {
  final Product product;
  final bool compact;

  const MultiBranchStockWidget({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final branchStocks = product.branchStocks;

    if (branchStocks == null || branchStocks.isEmpty) {
      return _buildSingleStockView(context);
    }

    if (compact) {
      return _buildCompactView(context, branchStocks);
    }

    return _buildDetailedView(context, branchStocks);
  }

  Widget _buildSingleStockView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStockColor(product.stock).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getStockColor(product.stock).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: _getStockColor(product.stock),
          ),
          const SizedBox(width: 4),
          Text(
            '${product.stock}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getStockColor(product.stock),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, List<BranchStock> stocks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStockColor(product.stock).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getStockColor(product.stock).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.store_outlined,
            size: 14,
            color: _getStockColor(product.stock),
          ),
          const SizedBox(width: 4),
          Text(
            '${product.stock}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getStockColor(product.stock),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${product.branchesWithStock}/${product.totalBranches}',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, List<BranchStock> stocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total stock header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Stock:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '${product.stock} ${product.unit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getStockColor(product.stock),
                ),
              ),
            ],
          ),
        ),

        // Branch breakdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stocks.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return _buildBranchStockItem(context, stock);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBranchStockItem(BuildContext context, BranchStock stock) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Branch icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.store, size: 14, color: Colors.blue[700]),
          ),
          const SizedBox(width: 8),

          // Branch ID
          Expanded(
            flex: 2,
            child: Text(
              'Branch ${stock.branchId}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          // Stock details
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Total quantity
                _buildStockBadge('Total: ${stock.quantity}', Colors.blue),
                const SizedBox(width: 6),

                // Reserved (if any)
                if (stock.hasReserved)
                  _buildStockBadge(
                    'Reserved: ${stock.reservedQuantity}',
                    Colors.orange,
                  ),

                const SizedBox(width: 6),

                // Available
                _buildStockBadge(
                  'Available: ${stock.availableQuantity}',
                  stock.isAvailable ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= product.minStock) return Colors.orange;
    if (stock <= product.reorderPoint) return Colors.amber;
    return Colors.green;
  }
}
