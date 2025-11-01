import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/product_branch_price.dart';

class ProductPricingFormTab extends StatefulWidget {
  final String? productId;
  final List<ProductBranchPrice>? initialPrices;
  final List<Map<String, dynamic>> units;
  final Function(List<Map<String, dynamic>>) onPricesChanged;

  const ProductPricingFormTab({
    super.key,
    this.productId,
    this.initialPrices,
    required this.units,
    required this.onPricesChanged,
  });

  @override
  State<ProductPricingFormTab> createState() => _ProductPricingFormTabState();
}

class _ProductPricingFormTabState extends State<ProductPricingFormTab>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _prices = [];
  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchFilter;
  String? _selectedUnitFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    // Initialize prices after branches are loaded
    // Will be called again after branches load
    _initializePrices();
  }

  @override
  void didUpdateWidget(ProductPricingFormTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize prices if units or initialPrices changed
    if (oldWidget.units != widget.units ||
        oldWidget.initialPrices != widget.initialPrices) {
      print('ProductPricingFormTab: didUpdateWidget called');
      print(
        'Old units length: ${oldWidget.units.length}, New units length: ${widget.units.length}',
      );
      print(
        'Old prices length: ${oldWidget.initialPrices?.length ?? 0}, New prices length: ${widget.initialPrices?.length ?? 0}',
      );
      setState(() {
        _initializePrices();
      });
    }
  }

  Future<void> _loadBranches() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/branches');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            _branches =
                data
                    .map(
                      (b) => {
                        'id': b['id'].toString(),
                        'code': b['code'] as String? ?? '',
                        'name': b['name'] as String? ?? '',
                      },
                    )
                    .toList();
            print('Branches loaded: ${_branches.length}');
            // Re-initialize prices after branches are loaded to filter correctly
            _initializePrices();
          });
        }
      }
    } catch (e) {
      print('Error loading branches: $e');
      // Fallback to current branch if API fails
      if (mounted) {
        setState(() {
          _branches = [
            {'id': '1', 'code': 'MAIN', 'name': 'Cabang Pusat'},
          ];
          _initializePrices();
        });
      }
    }
  }

  void _initializePrices() {
    print('ProductPricingFormTab: _initializePrices called');
    print('initialPrices: ${widget.initialPrices?.length ?? 0}');
    print('branches: ${_branches.length}');

    if (widget.initialPrices != null && widget.initialPrices!.isNotEmpty) {
      // Get list of accessible branch IDs
      final accessibleBranchIds = _branches.map((b) => b['id']).toSet();
      print('Accessible branch IDs: $accessibleBranchIds');

      // Clear existing prices
      _prices.clear();

      for (var price in widget.initialPrices!) {
        print(
          'Checking price for branch: ${price.branchId}, unit: ${price.unitName}',
        );

        // Only add prices for branches that user has access to
        // If branches haven't loaded yet (empty), allow all prices temporarily
        if (accessibleBranchIds.isEmpty ||
            accessibleBranchIds.contains(price.branchId)) {
          print(
            '✓ Adding price: ${price.unitName} - Branch: ${price.branchId} - Cost: ${price.costPrice}, Sell: ${price.sellingPrice}',
          );
          _prices.add({
            'id': price.id,
            'branchId': price.branchId,
            'branchName': price.branchName ?? '',
            'productUnitId': price.productUnitId,
            'unitName': price.unitName ?? 'BASE',
            'costPrice': price.costPrice,
            'sellingPrice': price.sellingPrice,
            'wholesalePrice': price.wholesalePrice,
            'memberPrice': price.memberPrice,
            'marginPercentage': price.marginPercentage,
            'validFrom': price.validFrom,
            'validUntil': price.validUntil,
            'isActive': price.isActive,
          });
        } else {
          print(
            '✗ Skipping price for branch ${price.branchId} - not accessible',
          );
        }
      }

      print('Total prices loaded: ${_prices.length}');

      // Always notify parent, even if no prices (to clear old data)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onPricesChanged(_prices);
        }
      });
    }
  }

  void _addPriceForBranchUnit(
    String branchId,
    String branchName,
    String? unitId,
    String unitName,
  ) {
    // Check if already exists (use unitName for new units without ID)
    final exists = _prices.any(
      (p) => p['branchId'] == branchId && p['unitName'] == unitName,
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga untuk $branchName - $unitName sudah ada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _prices.add({
        'id': null,
        'branchId': branchId,
        'branchName': branchName,
        'productUnitId': unitId,
        'unitName': unitName,
        'costPrice': 0.0,
        'sellingPrice': 0.0,
        'wholesalePrice': null,
        'memberPrice': null,
        'marginPercentage': 0.0,
        'validFrom': null,
        'validUntil': null,
        'isActive': true,
      });
    });
    // Notify parent after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPricesChanged(_prices);
    });
  }

  void _removePrice(int index) {
    setState(() {
      _prices.removeAt(index);
      widget.onPricesChanged(_prices);
    });
  }

  void _updatePrice(int index, String field, dynamic value) {
    setState(() {
      _prices[index][field] = value;

      // Auto-calculate margin if cost or selling price changes
      if (field == 'costPrice' || field == 'sellingPrice') {
        final cost = _prices[index]['costPrice'] ?? 0.0;
        final selling = _prices[index]['sellingPrice'] ?? 0.0;
        if (cost > 0) {
          _prices[index]['marginPercentage'] = ((selling - cost) / cost) * 100;
        }
      }

      widget.onPricesChanged(_prices);
    });
  }

  void _bulkAddPrices() {
    if (widget.units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada unit. Tambahkan unit terlebih dahulu di tab Units.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _BulkAddPricesDialog(
            branches: _branches,
            units: widget.units,
            onAdd: (branchIds, unitNames) {
              for (var branchId in branchIds) {
                final branch = _branches.firstWhere((b) => b['id'] == branchId);
                for (var unitName in unitNames) {
                  final unit = widget.units.firstWhere(
                    (u) => u['unitName'] == unitName,
                    orElse: () => {'unitName': 'BASE'},
                  );
                  _addPriceForBranchUnit(
                    branchId,
                    branch['name'],
                    null, // unitId null for new units (will be set after save)
                    unit['unitName'],
                  );
                }
              }
            },
          ),
    );
  }

  List<Map<String, dynamic>> get _filteredPrices {
    var filtered =
        _prices.where((p) {
          if (_selectedBranchFilter != null &&
              p['branchId'] != _selectedBranchFilter) {
            return false;
          }
          if (_selectedUnitFilter != null &&
              p['unitName'] != _selectedUnitFilter) {
            return false;
          }
          return true;
        }).toList();
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super for AutomaticKeepAliveClientMixin
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.store, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Harga per Cabang & Unit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _bulkAddPrices,
                icon: const Icon(Icons.add_business),
                label: const Text('Tambah Bulk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Atur harga khusus untuk setiap cabang dan unit',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBranchFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter Cabang',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Cabang'),
                    ),
                    ..._branches.map(
                      (b) => DropdownMenuItem(
                        value: b['id'],
                        child: Text(b['name']),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedBranchFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnitFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Unit'),
                    ),
                    ...widget.units.map(
                      (u) => DropdownMenuItem(
                        value: u['unitName'],
                        child: Text(u['unitName']),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedUnitFilter = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prices List
          Expanded(
            child:
                _filteredPrices.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada harga',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _bulkAddPrices,
                            child: const Text('Tambah Harga'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredPrices.length,
                      itemBuilder: (context, index) {
                        final priceIndex = _prices.indexOf(
                          _filteredPrices[index],
                        );
                        return _buildPriceCard(priceIndex);
                      },
                    ),
          ),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Harga dapat berbeda untuk setiap cabang dan unit. Margin otomatis dihitung berdasarkan harga beli dan jual.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(int index) {
    final price = _prices[index];
    // Use unique key to force rebuild when data changes
    final cardKey = ValueKey(
      'price_${price['branchId']}_${price['unitName']}_${price['id'] ?? index}',
    );

    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  price['branchName'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    price['unitName'],
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removePrice(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),

            // Prices
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'cost_${price['branchId']}_${price['unitName']}_${price['id'] ?? index}',
                    ),
                    initialValue:
                        price['costPrice'] != null && price['costPrice'] != 0.0
                            ? price['costPrice'].toString()
                            : '',
                    decoration: const InputDecoration(
                      labelText: 'Harga Beli *',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final doubleValue = double.tryParse(value) ?? 0.0;
                      _updatePrice(index, 'costPrice', doubleValue);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'sell_${price['branchId']}_${price['unitName']}_${price['id'] ?? index}',
                    ),
                    initialValue:
                        price['sellingPrice'] != null &&
                                price['sellingPrice'] != 0.0
                            ? price['sellingPrice'].toString()
                            : '',
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual *',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final doubleValue = double.tryParse(value) ?? 0.0;
                      _updatePrice(index, 'sellingPrice', doubleValue);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Optional Prices
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'wholesale_${price['branchId']}_${price['unitName']}_${price['id'] ?? index}',
                    ),
                    initialValue: price['wholesalePrice']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Harga Grosir',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final doubleValue =
                          value.isEmpty ? null : double.tryParse(value);
                      _updatePrice(index, 'wholesalePrice', doubleValue);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'member_${price['branchId']}_${price['unitName']}_${price['id'] ?? index}',
                    ),
                    initialValue: price['memberPrice']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Harga Member',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final doubleValue =
                          value.isEmpty ? null : double.tryParse(value);
                      _updatePrice(index, 'memberPrice', doubleValue);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Margin & Status
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Margin', style: TextStyle(fontSize: 11)),
                        Text(
                          '${price['marginPercentage'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Aktif', style: TextStyle(fontSize: 13)),
                    value: price['isActive'] == true,
                    onChanged:
                        (value) => _updatePrice(index, 'isActive', value),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Bulk Add Dialog
class _BulkAddPricesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> units;
  final Function(List<String> branchIds, List<String> unitNames) onAdd;

  const _BulkAddPricesDialog({
    required this.branches,
    required this.units,
    required this.onAdd,
  });

  @override
  State<_BulkAddPricesDialog> createState() => _BulkAddPricesDialogState();
}

class _BulkAddPricesDialogState extends State<_BulkAddPricesDialog> {
  final Set<String> _selectedBranches = {};
  final Set<String> _selectedUnits =
      {}; // Changed from String? to String (unitName)

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Harga Bulk'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Cabang:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.branches.map((branch) {
              return CheckboxListTile(
                title: Text(branch['name']),
                value: _selectedBranches.contains(branch['id']),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedBranches.add(branch['id']);
                    } else {
                      _selectedBranches.remove(branch['id']);
                    }
                  });
                },
                dense: true,
              );
            }),
            const Divider(),
            const Text(
              'Pilih Unit:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.units.map((unit) {
              final unitName = unit['unitName'] as String;
              return CheckboxListTile(
                title: Text(
                  '$unitName (${unit['isBaseUnit'] == true ? 'Base' : 'x${unit['conversionValue']}'}',
                ),
                value: _selectedUnits.contains(unitName),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedUnits.add(unitName);
                    } else {
                      _selectedUnits.remove(unitName);
                    }
                  });
                },
                dense: true,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              _selectedBranches.isEmpty || _selectedUnits.isEmpty
                  ? null
                  : () {
                    widget.onAdd(
                      _selectedBranches.toList(),
                      _selectedUnits.toList(),
                    );
                    Navigator.pop(context);
                  },
          child: const Text('Tambahkan'),
        ),
      ],
    );
  }
}
