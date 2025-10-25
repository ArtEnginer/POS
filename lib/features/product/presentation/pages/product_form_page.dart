import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
// import hybrid_sync_manager; // DELETED
// import online_only_guard; // DELETED
// import connection_status_indicator; // DELETED
import '../../../../injection_container.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _pluController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();

  late final ProductBloc _productBloc;
  String _selectedUnit = 'pcs';
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _units = [
    'pcs',
    'kg',
    'gram',
    'liter',
    'ml',
    'box',
    'pack',
    'dus',
    'lusin',
    'meter',
  ];

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>();
    if (widget.product != null) {
      _initializeFormWithProduct(widget.product!);
    } else {
      // Auto-generate PLU for new product
      _generatePLU();
    }
  }

  void _generatePLU() {
    // Generate PLU based on timestamp: PLU + current time in format YYMMDDHHmmss
    final now = DateTime.now();
    final plu =
        'PLU${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    _pluController.text = plu;
  }

  void _initializeFormWithProduct(Product product) {
    _barcodeController.text = product.barcode;
    _pluController.text = product.plu;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _purchasePriceController.text = product.purchasePrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _selectedUnit = product.unit;
    _isActive = product.isActive;
  }

  @override
  void dispose() {
    _productBloc.close();
    _barcodeController.dispose();
    _pluController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    //     final hybridSyncManager = sl<HybridSyncManager>();

    return BlocProvider.value(
      value: _productBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          actions: [
            // Status koneksi online/offline
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
    //               child: StreamConnectionStatusIndicator(
    //                 syncManager: hybridSyncManager,
    //                 showLabel: true,
    //                 iconSize: 18,
    //                 fontSize: 11,
    //               ),
            ),
          ],
        ),
        body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductLoading) {
              setState(() {
                _isLoading = true;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
            }

            if (state is ProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context, true);
            }

            if (state is ProductError) {
              // Check jika error karena offline
              if (state.message.toLowerCase().contains('koneksi') ||
                  state.message.toLowerCase().contains('online')) {
    //                 OnlineOnlyGuard.showOfflineDialog(context, 'Manajemen Produk');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        _buildSectionHeader('Informasi Dasar'),
                        const SizedBox(height: 16),
                        _buildBarcodeField(),
                        const SizedBox(height: 16),
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),

                        // Pricing Section
                        _buildSectionHeader('Harga'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildPurchasePriceField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSellingPriceField()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProfitInfo(),
                        const SizedBox(height: 24),

                        // Stock Section
                        _buildSectionHeader('Stok'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(flex: 2, child: _buildStockField()),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildMinStockField()),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: _buildUnitDropdown()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Status Section
                        _buildSectionHeader('Status'),
                        const SizedBox(height: 16),
                        _buildActiveSwitch(),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Update Produk' : 'Simpan Produk',
                              style: AppTextStyles.buttonLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.h5.copyWith(color: AppColors.primary),
    );
  }

  Widget _buildBarcodeField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: 'Barcode *',
              hintText: 'Masukkan barcode produk',
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Barcode harus diisi';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            // TODO: Implement barcode scanner
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur scan barcode akan segera hadir'),
              ),
            );
          },
          icon: const Icon(Icons.qr_code_scanner),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            padding: const EdgeInsets.all(16),
          ),
          tooltip: 'Scan Barcode',
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nama Produk *',
        hintText: 'Masukkan nama produk',
        prefixIcon: const Icon(Icons.shopping_bag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama produk harus diisi';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Deskripsi',
        hintText: 'Masukkan deskripsi produk (opsional)',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPurchasePriceField() {
    return TextFormField(
      controller: _purchasePriceController,
      decoration: InputDecoration(
        labelText: 'Harga Beli *',
        hintText: '0',
        prefixText: 'Rp ',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Harga beli harus diisi';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Harga beli tidak valid';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {}); // Update profit calculation
      },
    );
  }

  Widget _buildSellingPriceField() {
    return TextFormField(
      controller: _sellingPriceController,
      decoration: InputDecoration(
        labelText: 'Harga Jual *',
        hintText: '0',
        prefixText: 'Rp ',
        prefixIcon: const Icon(Icons.sell),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Harga jual harus diisi';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Harga jual tidak valid';
        }
        final purchasePrice = double.tryParse(_purchasePriceController.text);
        if (purchasePrice != null && price < purchasePrice) {
          return 'Harga jual < harga beli';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {}); // Update profit calculation
      },
    );
  }

  Widget _buildProfitInfo() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final profit = sellingPrice - purchasePrice;
    final margin = purchasePrice > 0 ? (profit / purchasePrice * 100) : 0;

    if (purchasePrice == 0 || sellingPrice == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            profit >= 0
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: profit >= 0 ? AppColors.success : AppColors.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            profit >= 0 ? Icons.trending_up : Icons.trending_down,
            color: profit >= 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keuntungan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: profit >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'Rp ${profit.toStringAsFixed(0)} (${margin.toStringAsFixed(1)}%)',
                  style: AppTextStyles.h6.copyWith(
                    color: profit >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: InputDecoration(
        labelText: 'Stok Awal *',
        hintText: '0',
        prefixIcon: const Icon(Icons.inventory),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Stok harus diisi';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Stok tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildMinStockField() {
    return TextFormField(
      controller: _minStockController,
      decoration: InputDecoration(
        labelText: 'Stok Minimum *',
        hintText: '0',
        prefixIcon: const Icon(Icons.warning),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Stok min harus diisi';
        }
        final minStock = int.tryParse(value);
        if (minStock == null || minStock < 0) {
          return 'Stok min tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      decoration: InputDecoration(
        labelText: 'Satuan *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          _units.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit.toUpperCase()),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedUnit = value;
          });
        }
      },
    );
  }

  Widget _buildActiveSwitch() {
    return Card(
      child: SwitchListTile(
        title: Text('Status Produk', style: AppTextStyles.bodyLarge),
        subtitle: Text(
          _isActive ? 'Produk aktif dan dapat dijual' : 'Produk tidak aktif',
          style: AppTextStyles.bodySmall,
        ),
        value: _isActive,
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        activeColor: AppColors.success,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.product != null;

      final product = Product(
        id: isEdit ? widget.product!.id : const Uuid().v4(),
        barcode: _barcodeController.text.trim(),
        plu: _pluController.text.trim(),
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        unit: _selectedUnit,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        isActive: _isActive,
        syncStatus: 'PENDING',
        createdAt: isEdit ? widget.product!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEdit) {
        _productBloc.add(event.UpdateProduct(product));
      } else {
        _productBloc.add(event.CreateProduct(product));
      }
    }
  }
}
