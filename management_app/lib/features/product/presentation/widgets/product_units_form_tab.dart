import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product_unit.dart';

class ProductUnitsFormTab extends StatefulWidget {
  final String? productId;
  final List<ProductUnit>? initialUnits;
  final Function(List<Map<String, dynamic>>) onUnitsChanged;

  const ProductUnitsFormTab({
    super.key,
    this.productId,
    this.initialUnits,
    required this.onUnitsChanged,
  });

  @override
  State<ProductUnitsFormTab> createState() => _ProductUnitsFormTabState();
}

class _ProductUnitsFormTabState extends State<ProductUnitsFormTab>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _units = [];
  int? _baseUnitIndex;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeUnits();
  }

  @override
  void didUpdateWidget(ProductUnitsFormTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize units if initialUnits changed
    if (oldWidget.initialUnits != widget.initialUnits) {
      print('ProductUnitsFormTab: didUpdateWidget called');
      print(
        'Old units length: ${oldWidget.initialUnits?.length ?? 0}, New units length: ${widget.initialUnits?.length ?? 0}',
      );
      setState(() {
        _initializeUnits();
      });
    }
  }

  void _initializeUnits() {
    print('ProductUnitsFormTab: _initializeUnits called');
    print('initialUnits: ${widget.initialUnits?.length ?? 0}');

    if (widget.initialUnits != null && widget.initialUnits!.isNotEmpty) {
      _units.clear();
      for (var i = 0; i < widget.initialUnits!.length; i++) {
        final unit = widget.initialUnits![i];
        print('Adding unit: ${unit.unitName} - Conv: ${unit.conversionValue}');
        _units.add({
          'id': unit.id,
          'unitName': unit.unitName,
          'conversionValue': unit.conversionValue,
          'isBaseUnit': unit.isBaseUnit,
          'canSell': unit.isSellable,
          'canPurchase': unit.isPurchasable,
          'barcode': unit.barcode ?? '',
          'sortOrder': unit.sortOrder,
        });
        if (unit.isBaseUnit) {
          _baseUnitIndex = i;
        }
      }

      print('Total units loaded: ${_units.length}');

      // Notify parent about loaded units
      if (_units.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onUnitsChanged(_units);
          }
        });
      }
    } else {
      // Add default base unit
      _addDefaultBaseUnit();
    }
  }

  void _addDefaultBaseUnit() {
    setState(() {
      _units.add({
        'id': null,
        'unitName': 'PCS',
        'conversionValue': 1.0,
        'isBaseUnit': true,
        'canSell': true,
        'canPurchase': true,
        'barcode': '',
        'sortOrder': 0,
      });
      _baseUnitIndex = 0;
    });
    // Call callback after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnitsChanged(_units);
    });
  }

  void _addNewUnit() {
    setState(() {
      _units.add({
        'id': null,
        'unitName': '',
        'conversionValue': 1.0,
        'isBaseUnit': false,
        'canSell': true,
        'canPurchase': true,
        'barcode': '',
        'sortOrder': _units.length,
      });
    });
    // Notify parent after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnitsChanged(_units);
    });
  }

  void _removeUnit(int index) {
    if (_units[index]['isBaseUnit'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unit dasar tidak dapat dihapus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _units.removeAt(index);
      if (_baseUnitIndex != null && _baseUnitIndex! > index) {
        _baseUnitIndex = _baseUnitIndex! - 1;
      }
    });
    // Notify parent after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnitsChanged(_units);
    });
  }

  void _setBaseUnit(int index) {
    setState(() {
      // Reset previous base unit
      if (_baseUnitIndex != null) {
        _units[_baseUnitIndex!]['isBaseUnit'] = false;
        _units[_baseUnitIndex!]['conversionValue'] = 1.0;
      }
      // Set new base unit
      _units[index]['isBaseUnit'] = true;
      _units[index]['conversionValue'] = 1.0;
      _baseUnitIndex = index;
    });
    // Notify parent after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnitsChanged(_units);
    });
  }

  void _updateUnit(int index, String field, dynamic value) {
    setState(() {
      _units[index][field] = value;
    });
    // Notify parent after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnitsChanged(_units);
    });
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
              const Icon(Icons.inventory_2, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Unit Konversi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addNewUnit,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Unit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Atur konversi unit untuk produk. Contoh: 1 BOX = 10 PCS',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Units List
          Expanded(
            child:
                _units.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada unit',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _addDefaultBaseUnit,
                            child: const Text('Tambah Unit Dasar'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _units.length,
                      itemBuilder: (context, index) {
                        return _buildUnitCard(index);
                      },
                    ),
          ),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unit dasar adalah unit terkecil yang digunakan untuk perhitungan stok. Nilai konversi unit lain dihitung berdasarkan unit dasar.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(int index) {
    final unit = _units[index];
    final isBaseUnit = unit['isBaseUnit'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Base Unit Indicator
                if (isBaseUnit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'UNIT DASAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                if (!isBaseUnit)
                  TextButton.icon(
                    onPressed: () => _setBaseUnit(index),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Set sebagai dasar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                const Spacer(),
                // Sort Order
                Text(
                  '#${index + 1}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                // Delete Button
                if (!isBaseUnit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeUnit(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(),

            // Unit Name
            TextFormField(
              initialValue: unit['unitName'],
              decoration: const InputDecoration(
                labelText: 'Nama Unit *',
                hintText: 'Contoh: PCS, BOX, DUS, KG',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => _updateUnit(index, 'unitName', value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama unit harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Conversion Value
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: unit['conversionValue'].toString(),
                    decoration: InputDecoration(
                      labelText: 'Nilai Konversi *',
                      hintText: '1',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      enabled: !isBaseUnit,
                      helperText:
                          isBaseUnit
                              ? 'Unit dasar selalu 1'
                              : '1 ${unit['unitName']} = X unit dasar',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final doubleValue = double.tryParse(value) ?? 1.0;
                      _updateUnit(index, 'conversionValue', doubleValue);
                    },
                    validator: (value) {
                      if (!isBaseUnit) {
                        final val = double.tryParse(value ?? '');
                        if (val == null || val <= 0) {
                          return 'Nilai harus > 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: unit['barcode'],
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => _updateUnit(index, 'barcode', value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Permissions
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text(
                      'Dapat Dijual',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: unit['canSell'] == true,
                    onChanged:
                        (value) => _updateUnit(index, 'canSell', value ?? true),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text(
                      'Dapat Dibeli',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: unit['canPurchase'] == true,
                    onChanged:
                        (value) =>
                            _updateUnit(index, 'canPurchase', value ?? true),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
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
