import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../../../core/database/hive_service.dart';
import '../../../sync/data/datasources/sync_service.dart';
import '../../../../main.dart' show cashierSettingsService;

// Events
abstract class CashierEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CashierEvent {
  final ProductModel product;
  final double quantity;

  AddToCart({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends CashierEvent {
  final String productId;

  RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateCartItemQuantity extends CashierEvent {
  final String productId;
  final double quantity;

  UpdateCartItemQuantity({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}

class ApplyDiscountToItem extends CashierEvent {
  final String productId;
  final double discount;

  ApplyDiscountToItem({required this.productId, required this.discount});

  @override
  List<Object?> get props => [productId, discount];
}

// Alias untuk UpdateCartItemDiscount (sama dengan ApplyDiscountToItem)
class UpdateCartItemDiscount extends ApplyDiscountToItem {
  UpdateCartItemDiscount({required super.productId, required super.discount});
}

class ApplyTaxToItem extends CashierEvent {
  final String productId;
  final double taxPercent;

  ApplyTaxToItem({required this.productId, required this.taxPercent});

  @override
  List<Object?> get props => [productId, taxPercent];
}

// Alias untuk UpdateCartItemTax
class UpdateCartItemTax extends ApplyTaxToItem {
  UpdateCartItemTax({required super.productId, required super.taxPercent});
}

class ApplyGlobalDiscount extends CashierEvent {
  final double discount;

  ApplyGlobalDiscount(this.discount);

  @override
  List<Object?> get props => [discount];
}

class ApplyGlobalTax extends CashierEvent {
  final double taxPercent;

  ApplyGlobalTax(this.taxPercent);

  @override
  List<Object?> get props => [taxPercent];
}

class ClearCart extends CashierEvent {}

class ProcessPayment extends CashierEvent {
  final double paidAmount;
  final String paymentMethod;
  final String? customerId;
  final String? customerName;
  final String? note;

  ProcessPayment({
    required this.paidAmount,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    this.note,
  });

  @override
  List<Object?> get props => [
    paidAmount,
    paymentMethod,
    customerId,
    customerName,
    note,
  ];
}

// States
abstract class CashierState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashierInitial extends CashierState {}

class CashierLoaded extends CashierState {
  final List<CartItemModel> cartItems;
  final double globalDiscount;
  final double globalTax;
  final double subtotal;
  final double itemDiscountAmount;
  final double globalDiscountAmount;
  final double totalDiscountAmount;
  final double itemTaxAmount;
  final double globalTaxAmount;
  final double totalTaxAmount;
  final double total;

  CashierLoaded({
    required this.cartItems,
    this.globalDiscount = 0,
    this.globalTax = 0,
    required this.subtotal,
    required this.itemDiscountAmount,
    required this.globalDiscountAmount,
    required this.totalDiscountAmount,
    required this.itemTaxAmount,
    required this.globalTaxAmount,
    required this.totalTaxAmount,
    required this.total,
  });

  @override
  List<Object?> get props => [
    cartItems,
    globalDiscount,
    globalTax,
    subtotal,
    itemDiscountAmount,
    globalDiscountAmount,
    totalDiscountAmount,
    itemTaxAmount,
    globalTaxAmount,
    totalTaxAmount,
    total,
  ];
}

class PaymentProcessing extends CashierState {}

class PaymentSuccess extends CashierState {
  final SaleModel sale;
  final double change;

  PaymentSuccess({required this.sale, required this.change});

  @override
  List<Object?> get props => [sale, change];
}

class CashierError extends CashierState {
  final String message;

  CashierError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CashierBloc extends Bloc<CashierEvent, CashierState> {
  final HiveService _hiveService;
  final SyncService _syncService;
  List<CartItemModel> _cartItems = [];
  double _globalDiscount = 0;
  double _globalTax = 0;

  CashierBloc({
    required HiveService hiveService,
    required SyncService syncService,
  }) : _hiveService = hiveService,
       _syncService = syncService,
       super(CashierInitial()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ApplyDiscountToItem>(_onApplyDiscountToItem);
    on<ApplyTaxToItem>(_onApplyTaxToItem);
    on<ApplyGlobalDiscount>(_onApplyGlobalDiscount);
    on<ApplyGlobalTax>(_onApplyGlobalTax);
    on<ClearCart>(_onClearCart);
    on<ProcessPayment>(_onProcessPayment);
  }

  void _onAddToCart(AddToCart event, Emitter<CashierState> emit) {
    try {
      // Check if product already in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (existingIndex != -1) {
        // Update quantity
        final existingItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + event.quantity,
        );
      } else {
        // Add new item
        _cartItems.add(
          CartItemModel(product: event.product, quantity: event.quantity),
        );
      }

      _emitLoadedState(emit);
    } catch (e) {
      emit(CashierError('Gagal menambahkan produk: ${e.toString()}'));
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CashierState> emit) {
    _cartItems.removeWhere((item) => item.product.id == event.productId);
    _emitLoadedState(emit);
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CashierState> emit,
  ) {
    final index = _cartItems.indexWhere(
      (item) => item.product.id == event.productId,
    );
    if (index != -1) {
      if (event.quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: event.quantity,
        );
      }
    }
    _emitLoadedState(emit);
  }

  void _onApplyDiscountToItem(
    ApplyDiscountToItem event,
    Emitter<CashierState> emit,
  ) {
    final index = _cartItems.indexWhere(
      (item) => item.product.id == event.productId,
    );
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(discount: event.discount);
    }
    _emitLoadedState(emit);
  }

  void _onApplyTaxToItem(ApplyTaxToItem event, Emitter<CashierState> emit) {
    print('🏷️ Apply Tax to Item: ${event.productId} = ${event.taxPercent}%');
    final index = _cartItems.indexWhere(
      (item) => item.product.id == event.productId,
    );
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        taxPercent: event.taxPercent,
      );
      print('✅ Tax updated for item: ${_cartItems[index].product.name}');
    }
    _emitLoadedState(emit);
  }

  void _onApplyGlobalDiscount(
    ApplyGlobalDiscount event,
    Emitter<CashierState> emit,
  ) {
    print('💸 Apply Global Discount: ${event.discount}%');
    _globalDiscount = event.discount;
    _emitLoadedState(emit);
  }

  void _onApplyGlobalTax(ApplyGlobalTax event, Emitter<CashierState> emit) {
    print('🧾 Apply Global Tax: ${event.taxPercent}%');
    _globalTax = event.taxPercent;
    _emitLoadedState(emit);
  }

  void _onClearCart(ClearCart event, Emitter<CashierState> emit) {
    _cartItems.clear();
    _globalDiscount = 0;
    _globalTax = 0;
    emit(CashierInitial());
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<CashierState> emit,
  ) async {
    emit(PaymentProcessing());

    try {
      // Calculate totals
      final calculations = _calculateTotals();

      // Check if paid amount is sufficient
      if (event.paidAmount < calculations['total']!) {
        emit(CashierError('Jumlah bayar kurang!'));
        _emitLoadedState(emit);
        return;
      }

      // Get current user (simplified - should come from auth)
      final cashierId = _hiveService.settingsBox.get(
        'cashier_id',
        defaultValue: 'cashier1',
      );
      final cashierName = _hiveService.settingsBox.get(
        'cashier_name',
        defaultValue: 'Kasir',
      );

      // Generate invoice number
      final invoiceNumber = _generateInvoiceNumber();

      // Calculate total cost and profit
      double totalCost = 0;
      for (final item in _cartItems) {
        // Get cost price from product
        try {
          final productData = _hiveService.productsBox.get(item.product.id);
          if (productData != null && productData is Map) {
            final costPrice = (productData['cost_price'] ?? 0).toDouble();
            totalCost += costPrice * item.quantity;
          }
        } catch (e) {
          print('⚠️ Error getting cost price for ${item.product.id}: $e');
        }
      }

      final grossProfit = calculations['total']! - totalCost;
      final profitMargin =
          calculations['total']! > 0
              ? ((grossProfit / calculations['total']!) * 100).toDouble()
              : 0.0;

      // Get device info from cashier settings
      final deviceInfo = cashierSettingsService.getDeviceInfoForTransaction();
      final cashierLocation =
          cashierSettingsService.getCashierLocation() ?? cashierName;

      // Create sale
      final sale = SaleModel(
        id: const Uuid().v4(),
        invoiceNumber: invoiceNumber,
        transactionDate: DateTime.now(),
        items: List.from(_cartItems),
        subtotal: calculations['subtotal']!,
        discount: calculations['totalDiscountAmount']!,
        tax: calculations['totalTaxAmount']!,
        total: calculations['total']!,
        paid: event.paidAmount,
        change: event.paidAmount - calculations['total']!,
        paymentMethod: event.paymentMethod,
        customerId: event.customerId,
        customerName: event.customerName,
        cashierId: cashierId,
        cashierName: cashierName,
        note: event.note,
        isSynced: false,
        createdAt: DateTime.now(),
        totalCost: totalCost,
        grossProfit: grossProfit,
        profitMargin: profitMargin,
        cashierLocation: cashierLocation,
        deviceInfo: deviceInfo,
      );

      // Save to local database
      await _hiveService.salesBox.put(sale.id, sale.toJson());

      // 🚀 REAL-TIME SYNC: Jika online, langsung sync ke server!
      print('💾 Sale saved locally: ${sale.invoiceNumber}');
      _syncService.syncSaleImmediately(sale.id).then((synced) {
        if (synced) {
          print('✅ INSTANT SYNC SUCCESS: ${sale.invoiceNumber}');
        } else {
          print('⚠️ Sale will be synced later when online');
        }
      });

      // Update stock locally (optimistic update)
      for (final item in _cartItems) {
        try {
          final productJson = _hiveService.productsBox.get(item.product.id);
          if (productJson != null) {
            final product =
                productJson is Map<String, dynamic>
                    ? ProductModel.fromJson(productJson)
                    : ProductModel.fromJson(
                      Map<String, dynamic>.from(productJson as Map),
                    );

            final updatedProduct = product.copyWith(
              stock: product.stock - item.quantity,
            );
            await _hiveService.productsBox.put(
              item.product.id,
              updatedProduct.toJson(),
            );
          }
        } catch (e) {
          print('⚠️ Error updating stock for ${item.product.id}: $e');
        }
      }

      // Clear cart
      _cartItems.clear();
      _globalDiscount = 0;

      emit(PaymentSuccess(sale: sale, change: sale.change));
    } catch (e) {
      emit(CashierError('Gagal memproses pembayaran: ${e.toString()}'));
    }
  }

  Map<String, double> _calculateTotals() {
    double subtotal = 0;
    double itemDiscountAmount = 0;
    double itemTaxAmount = 0;

    // Calculate item-level amounts
    for (final item in _cartItems) {
      subtotal += item.subtotal;
      itemDiscountAmount += item.discountAmount;
      itemTaxAmount += item.taxAmount;
    }

    // Apply global discount to subtotal after item discounts
    final afterItemDiscount = subtotal - itemDiscountAmount;
    final globalDiscountAmount = afterItemDiscount * (_globalDiscount / 100);
    final totalDiscountAmount = itemDiscountAmount + globalDiscountAmount;

    // Calculate global tax on amount after all discounts
    final afterAllDiscounts = subtotal - totalDiscountAmount;
    final globalTaxAmount = afterAllDiscounts * (_globalTax / 100);
    final totalTaxAmount = itemTaxAmount + globalTaxAmount;

    // Final total
    final total = afterAllDiscounts + totalTaxAmount;

    // Debug print
    print('💰 CALCULATION DEBUG:');
    print('   Subtotal: $subtotal');
    print('   Item Discount: $itemDiscountAmount');
    print('   Global Discount ($_globalDiscount%): $globalDiscountAmount');
    print('   Total Discount: $totalDiscountAmount');
    print('   Item Tax: $itemTaxAmount');
    print('   Global Tax ($_globalTax%): $globalTaxAmount');
    print('   Total Tax: $totalTaxAmount');
    print('   FINAL TOTAL: $total');

    return {
      'subtotal': subtotal,
      'itemDiscountAmount': itemDiscountAmount,
      'globalDiscountAmount': globalDiscountAmount,
      'totalDiscountAmount': totalDiscountAmount,
      'itemTaxAmount': itemTaxAmount,
      'globalTaxAmount': globalTaxAmount,
      'totalTaxAmount': totalTaxAmount,
      'total': total,
    };
  }

  void _emitLoadedState(Emitter<CashierState> emit) {
    final calculations = _calculateTotals();
    emit(
      CashierLoaded(
        cartItems: List.from(_cartItems),
        globalDiscount: _globalDiscount,
        globalTax: _globalTax,
        subtotal: calculations['subtotal'] ?? 0,
        itemDiscountAmount: calculations['itemDiscountAmount'] ?? 0,
        globalDiscountAmount: calculations['globalDiscountAmount'] ?? 0,
        totalDiscountAmount: calculations['totalDiscountAmount'] ?? 0,
        itemTaxAmount: calculations['itemTaxAmount'] ?? 0,
        globalTaxAmount: calculations['globalTaxAmount'] ?? 0,
        totalTaxAmount: calculations['totalTaxAmount'] ?? 0,
        total: calculations['total'] ?? 0,
      ),
    );
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'INV-$dateStr-$timeStr';
  }
}
