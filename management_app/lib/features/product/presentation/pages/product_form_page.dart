import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/product.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';
import 'category_list_page.dart';
import '../widgets/product_units_form_tab.dart';
import '../widgets/product_pricing_form_tab.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _reorderPointController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _discountController = TextEditingController();

  late final ProductBloc _productBloc;
  late TabController _tabController;

  List<Map<String, String>> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingCategories = false;

  // Multi-unit and pricing data
  List<Map<String, dynamic>> _productUnits = [];
  List<Map<String, dynamic>> _productPrices = [];

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
    if (widget.product != null) {
      _initializeFormWithProduct(widget.product!);
    } else {
      // Auto-generate sku for new product
      _generatesku();
    }
  }

  // Note: _loadUnits() removed - units managed in Units tab

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoadingCategories = true);
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? response.data as List;

        // Parse categories with parent info
        final allCategories =
            data.map((e) {
              return {
                'id': e['id']?.toString() ?? '',
                'name': (e['name'] ?? '') as String,
                'parentId': e['parentId']?.toString(),
              };
            }).toList();

        // Build hierarchical list (root first, then children)
        _categories = _buildHierarchicalList(allCategories);

        // if editing product, set selected category
        if (widget.product != null && widget.product!.categoryId != null) {
          _selectedCategoryId = widget.product!.categoryId;
          _selectedCategoryName = widget.product!.categoryName;
        }
      }
    } catch (e) {
      // ignore - categories are optional, show empty list instead
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  // Build hierarchical category list with proper ordering and display names
  List<Map<String, String>> _buildHierarchicalList(
    List<Map<String, dynamic>> categories,
  ) {
    final result = <Map<String, String>>[];

    // Get root categories (no parent)
    final roots = categories.where((c) => c['parentId'] == null).toList();

    for (final root in roots) {
      // Add root category
      result.add({
        'id': root['id'] as String,
        'name': root['name'] as String,
        'displayName': root['name'] as String,
      });

      // Add its children
      final children =
          categories.where((c) => c['parentId'] == root['id']).toList();
      for (final child in children) {
        result.add({
          'id': child['id'] as String,
          'name': child['name'] as String,
          'displayName': '   ↳ ${child['name']}', // Indented display
        });
      }
    }

    return result;
  }

  void _generatesku() {
    // Generate sku based on timestamp: sku + current time in format YYMMDDHHmmss
    final now = DateTime.now();
    final sku =
        'sku${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    _skuController.text = sku;
  }

  void _initializeFormWithProduct(Product product) {
    print('ProductFormPage: _initializeFormWithProduct called');
    print('Product ID: ${product.id}');
    print('Product units: ${product.units?.length ?? 0}');
    print('Product prices: ${product.prices?.length ?? 0}');

    _barcodeController.text = product.barcode;
    _skuController.text = product.sku;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _costPriceController.text = product.costPrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _maxStockController.text = product.maxStock.toString();
    _reorderPointController.text = product.reorderPoint.toString();
    _taxRateController.text = product.taxRate.toString();
    _discountController.text = product.discountPercentage.toString();
    // Note: _selectedUnit removed - unit managed in Units tab
    _isActive = product.isActive;

    // Initialize units from product data
    if (product.units != null && product.units!.isNotEmpty) {
      _productUnits =
          product.units!.map((unit) {
            print('Mapping unit: ${unit.unitName}');
            return {
              'id': unit.id,
              'unitName': unit.unitName,
              'conversionValue': unit.conversionValue,
              'isBaseUnit': unit.isBaseUnit,
              'canPurchase': unit.isPurchasable,
              'canSell': unit.isSellable,
              'barcode': unit.barcode,
              'sortOrder': unit.sortOrder,
            };
          }).toList();
      print('_productUnits initialized with ${_productUnits.length} units');
    }

    // Initialize prices from product data
    if (product.prices != null && product.prices!.isNotEmpty) {
      _productPrices =
          product.prices!.map((price) {
            print(
              'Mapping price: ${price.unitName} - Cost: ${price.costPrice}, Sell: ${price.sellingPrice}',
            );
            return {
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
            };
          }).toList();
      print('_productPrices initialized with ${_productPrices.length} prices');
    }
  }

  @override
  void dispose() {
    _productBloc.close();
    _tabController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _reorderPointController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.info), text: 'Informasi'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Units'),
              Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
            ],
          ),
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
              // Save units and prices after product is created
              if (widget.product == null && // Only for new products
                  (_productUnits.isNotEmpty || _productPrices.isNotEmpty)) {
                // Get product ID from success state
                // Note: ProductOperationSuccess should contain the created product
                // For now, we'll extract ID from response if available
                _saveUnitsAndPricesAfterCreate(state);
              } else {
                // Show success and navigate back
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
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Basic Info
                _buildBasicInfoTab(isEdit),

                // Tab 2: Units Management
                ProductUnitsFormTab(
                  productId: widget.product?.id,
                  initialUnits: widget.product?.units,
                  onUnitsChanged: (units) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _productUnits = units);
                      }
                    });
                  },
                ),

                // Tab 3: Pricing Management
                ProductPricingFormTab(
                  productId: widget.product?.id,
                  initialPrices: widget.product?.prices,
                  units: _productUnits,
                  onPricesChanged: (prices) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _productPrices = prices);
                      }
                    });
                  },
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomBar(isEdit),
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isEdit) {
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
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 24),

                // Info: Harga diatur di tab "Pricing" untuk multi-unit support
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Harga produk diatur di tab "Pricing" untuk mendukung harga berbeda per cabang dan per unit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stock Section
                _buildSectionHeader('Stok'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildStockField()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildMinStockField()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMaxStockField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildReorderPointField()),
                  ],
                ),
                const SizedBox(height: 24),

                // Info: Unit, pajak, dan diskon dikelola di tab lain
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unit produk diatur di tab "Units". Stok dihitung dalam unit terkecil (base unit).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status Section
                _buildSectionHeader('Status'),
                const SizedBox(height: 16),
                _buildActiveSwitch(),
                const SizedBox(height: 100), // Extra space for bottom bar
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
  }

  Widget _buildBottomBar(bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Info Text
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Units: ${_productUnits.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Prices: ${_productPrices.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Buttons
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
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

  // Note: Pricing fields removed - now managed in Pricing tab for multi-unit support

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: InputDecoration(
        labelText: 'Stok Awal *',
        hintText: '0',
        prefixIcon: const Icon(Icons.inventory),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Stok harus diisi';
        }
        final stock = double.tryParse(value);
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Stok min harus diisi';
        }
        final minStock = double.tryParse(value);
        if (minStock == null || minStock < 0) {
          return 'Stok min tidak valid';
        }
        return null;
      },
    );
  }

  // Note: Unit dropdown removed - units managed in Units tab

  // Note: Unit dropdown removed - units managed in Units tab

  Widget _buildMaxStockField() {
    return TextFormField(
      controller: _maxStockController,
      decoration: InputDecoration(
        labelText: 'Stok Maksimal',
        hintText: '0',
        prefixIcon: const Icon(Icons.inventory_2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final maxStock = double.tryParse(value);
          if (maxStock == null || maxStock < 0) {
            return 'Tidak valid';
          }
        }
        return null;
      },
    );
  }

  Widget _buildReorderPointField() {
    return TextFormField(
      controller: _reorderPointController,
      decoration: InputDecoration(
        labelText: 'Reorder Point',
        hintText: '0',
        prefixIcon: const Icon(Icons.notification_important),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final reorder = double.tryParse(value);
          if (reorder == null || reorder < 0) {
            return 'Tidak valid';
          }
        }
        return null;
      },
    );
  }

  // Note: Tax and discount fields removed - can be managed in pricing logic if needed

  Widget _buildCategoryDropdown() {
    return Row(
      children: [
        Expanded(
          child:
              _categories.isEmpty
                  ? TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Loading...',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: false,
                  )
                  : Autocomplete<Map<String, String>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _categories;
                      }
                      return _categories.where((Map<String, String> category) {
                        final name = category['name'] ?? '';
                        return name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    displayStringForOption:
                        (Map<String, String> option) => option['name'] ?? '',
                    onSelected: (Map<String, String> selection) {
                      setState(() {
                        _selectedCategoryId = selection['id'];
                        _selectedCategoryName = selection['name'];
                      });
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      // Set initial value only once
                      if (textEditingController.text.isEmpty &&
                          _selectedCategoryName != null &&
                          _selectedCategoryName!.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          textEditingController.text = _selectedCategoryName!;
                        });
                      }

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          hintText: 'Ketik atau pilih kategori (opsional)',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon:
                              textEditingController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                      setState(() {
                                        _selectedCategoryId = null;
                                        _selectedCategoryName = null;
                                      });
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: (value) {
                          // Clear selection if text doesn't match
                          if (value.isEmpty) {
                            _selectedCategoryId = null;
                            _selectedCategoryName = null;
                          } else {
                            // Check if typed value matches any category
                            final match = _categories.firstWhere(
                              (cat) => cat['name'] == value,
                              orElse: () => {},
                            );
                            if (match.isNotEmpty) {
                              _selectedCategoryId = match['id'];
                              _selectedCategoryName = match['name'];
                            }
                          }
                        },
                      );
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<Map<String, String>> onSelected,
                      Iterable<Map<String, String>> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 250,
                              maxWidth: 350,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Map<String, String> option = options
                                    .elementAt(index);
                                final displayName =
                                    option['displayName'] ??
                                    option['name'] ??
                                    '-';
                                final isSelected =
                                    option['id'] == _selectedCategoryId;

                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.primary.withOpacity(
                                                0.1,
                                              )
                                              : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          const Icon(
                                            Icons.check,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        if (isSelected)
                                          const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: TextStyle(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed:
              _isLoadingCategories
                  ? null
                  : () async {
                    // Open category management
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryListPage(),
                      ),
                    );
                    // reload categories if changed
                    if (result == true) await _loadCategories();
                  },
          icon: const Icon(Icons.edit),
          tooltip: 'Kelola Kategori',
          color: AppColors.primary,
        ),
      ],
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
    // Validate basic info form
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Switch to Info tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi informasi dasar produk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate units (must have at least 1 unit)
    if (_productUnits.isEmpty) {
      _tabController.animateTo(1); // Switch to Units tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Minimal harus ada 1 unit. Sistem akan membuat unit dasar otomatis.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate base unit exists
    final hasBaseUnit = _productUnits.any((u) => u['isBaseUnit'] == true);
    if (!hasBaseUnit) {
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harus ada 1 unit dasar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isEdit = widget.product != null;

    // Get default price from first unit/price or use 0
    double defaultCostPrice = 0;
    double defaultSellingPrice = 0;

    if (_productPrices.isNotEmpty) {
      defaultCostPrice = _productPrices[0]['costPrice'] ?? 0;
      defaultSellingPrice = _productPrices[0]['sellingPrice'] ?? 0;
    }

    final product = Product(
      id:
          isEdit
              ? widget.product!.id
              : '', // Empty for new product, backend will assign ID
      barcode: _barcodeController.text.trim(),
      sku: _skuController.text.trim(),
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      categoryId: _selectedCategoryId,
      categoryName: _selectedCategoryName,
      unit:
          _productUnits.isNotEmpty
              ? _productUnits[0]['unitName'] ?? 'PCS'
              : 'PCS', // Use base unit from Units tab
      costPrice: defaultCostPrice,
      sellingPrice: defaultSellingPrice,
      stock: double.tryParse(_stockController.text) ?? 0,
      minStock: double.tryParse(_minStockController.text) ?? 0,
      maxStock:
          _maxStockController.text.isEmpty
              ? 0
              : double.tryParse(_maxStockController.text) ?? 0,
      reorderPoint:
          _reorderPointController.text.isEmpty
              ? 0
              : (double.tryParse(_reorderPointController.text) ?? 0).toInt(),
      taxRate:
          _taxRateController.text.isEmpty
              ? 0
              : double.tryParse(_taxRateController.text) ?? 0,
      discountPercentage:
          _discountController.text.isEmpty
              ? 0
              : double.tryParse(_discountController.text) ?? 0,
      isActive: _isActive,
      syncStatus: 'PENDING',
      createdAt: isEdit ? widget.product!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      // Include units and prices (will be handled by backend)
      units: null,
      prices: null,
    );

    // Save product first via Bloc
    if (isEdit) {
      _productBloc.add(event.UpdateProduct(product));
      // For edit mode, we already have the ID, save units/prices immediately
      if (_productUnits.isNotEmpty || _productPrices.isNotEmpty) {
        _saveUnitsAndPrices(product.id);
      }
    } else {
      _productBloc.add(event.CreateProduct(product));
      // For create mode, we'll save units/prices in BlocListener after getting the ID
    }
  }

  Future<void> _saveUnitsAndPricesAfterCreate(
    ProductOperationSuccess state,
  ) async {
    // Get product ID from the created product
    final productId = state.product?.id;

    if (productId == null || productId.isEmpty) {
      // If no product ID, show error and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Produk disimpan tapi tidak bisa menyimpan units/prices (ID tidak valid)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
      return;
    }

    // Save units and prices
    await _saveUnitsAndPrices(productId);

    // Show success and navigate back
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveUnitsAndPrices(String productId) async {
    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();

      // Helper to round price to 2 decimal places (match backend DECIMAL(15,2))
      double? roundPrice(dynamic price) {
        if (price == null) return null;
        final num = price is double ? price : double.tryParse(price.toString());
        if (num == null || num == 0) return null;
        // Round to 2 decimal places
        return (num * 100).round() / 100;
      }

      // 1. Save Units (Smart Update - only modify what changed)
      if (_productUnits.isNotEmpty) {
        // Get existing units from backend
        final List<dynamic> existingUnits;
        if (widget.product != null && widget.product!.units != null) {
          existingUnits =
              widget.product!.units!
                  .map(
                    (u) => {
                      'id': u.id,
                      'unitName': u.unitName,
                      'conversionValue': u.conversionValue,
                      'isBaseUnit': u.isBaseUnit,
                      'isPurchasable': u.isPurchasable,
                      'isSellable': u.isSellable,
                      'barcode': u.barcode,
                      'sortOrder': u.sortOrder,
                    },
                  )
                  .toList();
        } else {
          existingUnits = [];
        }

        // Create maps for comparison
        final existingUnitNames = {
          for (var u in existingUnits) u['unitName']: u,
        };
        final currentUnitNames = {
          for (var u in _productUnits) u['unitName']: u,
        };

        // Find units to delete (in existing but not in current)
        for (var existingUnit in existingUnits) {
          final unitName = existingUnit['unitName'] as String;
          if (!currentUnitNames.containsKey(unitName)) {
            try {
              await apiClient.delete(
                '/products/$productId/units/${existingUnit['id']}',
              );
              print('Deleted unit: $unitName');
            } catch (e) {
              print('Failed to delete unit $unitName: $e');
            }
          }
        }

        // Find units to create or update
        for (var unit in _productUnits) {
          final unitName = unit['unitName'] as String;
          final existingUnit = existingUnitNames[unitName];

          if (existingUnit == null) {
            // Create new unit
            try {
              await apiClient.post(
                '/products/$productId/units',
                data: {
                  'unitName': unit['unitName'],
                  'conversionValue': unit['conversionValue'] ?? 1.0,
                  'isBaseUnit': unit['isBaseUnit'] ?? false,
                  'isPurchasable': unit['canPurchase'] ?? true,
                  'isSellable': unit['canSell'] ?? true,
                  'barcode': unit['barcode'] ?? '',
                  'sortOrder': unit['sortOrder'] ?? 0,
                },
              );
              print('Created unit: $unitName');
            } catch (e) {
              print('Failed to create unit $unitName: $e');
            }
          } else {
            // Check if unit has changed
            final hasChanged =
                existingUnit['conversionValue'] !=
                    (unit['conversionValue'] ?? 1.0) ||
                existingUnit['isBaseUnit'] != (unit['isBaseUnit'] ?? false) ||
                existingUnit['isPurchasable'] !=
                    (unit['canPurchase'] ?? true) ||
                existingUnit['isSellable'] != (unit['canSell'] ?? true) ||
                existingUnit['barcode'] != (unit['barcode'] ?? '') ||
                existingUnit['sortOrder'] != (unit['sortOrder'] ?? 0);

            if (hasChanged) {
              // Update existing unit
              try {
                await apiClient.put(
                  '/products/$productId/units/${existingUnit['id']}',
                  data: {
                    'unitName': unit['unitName'],
                    'conversionValue': unit['conversionValue'] ?? 1.0,
                    'isBaseUnit': unit['isBaseUnit'] ?? false,
                    'isPurchasable': unit['canPurchase'] ?? true,
                    'isSellable': unit['canSell'] ?? true,
                    'barcode': unit['barcode'] ?? '',
                    'sortOrder': unit['sortOrder'] ?? 0,
                  },
                );
                print('Updated unit: $unitName');
              } catch (e) {
                print('Failed to update unit $unitName: $e');
              }
            } else {
              print('Unit unchanged: $unitName');
            }
          }
        }
      }

      // 2. Save Prices
      if (_productPrices.isNotEmpty) {
        // Get unit IDs from backend (after units are created)
        final unitsResponse = await apiClient.get('/products/$productId/units');
        final createdUnits = unitsResponse.data['data'] as List? ?? [];

        // Create map of unitName -> unitId
        final unitNameToId = <String, String>{};
        for (var unit in createdUnits) {
          unitNameToId[unit['unit_name']] = unit['id'];
        }

        // For edit mode, we'll use PUT to update prices
        // Backend will handle upsert logic
        for (var price in _productPrices) {
          final unitId = unitNameToId[price['unitName']];
          if (unitId == null) continue;

          try {
            // Use the correct endpoint with body data
            await apiClient.put(
              '/products/$productId/prices',
              data: {
                'branchId': price['branchId'],
                'unitId': unitId, // Changed from productUnitId to unitId
                'costPrice': roundPrice(price['costPrice']),
                'sellingPrice': roundPrice(price['sellingPrice']) ?? 0,
                'wholesalePrice': roundPrice(price['wholesalePrice']),
                'memberPrice': roundPrice(price['memberPrice']),
              },
            );
          } catch (e) {
            print('Failed to save price for ${price['branchName']}: $e');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk berhasil disimpan dengan ${_productUnits.length} unit dan ${_productPrices.length} harga',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving units and prices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk disimpan, tapi ada error pada units/prices: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
