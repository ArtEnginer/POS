import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../../../core/database/hive_service.dart';
import '../../../sync/data/datasources/sync_service.dart';

// Events
abstract class CashierEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddToCart extends CashierEvent {
  final ProductModel product;
  final int quantity;

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
  final int quantity;

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

class ApplyGlobalDiscount extends CashierEvent {
  final double discount;

  ApplyGlobalDiscount(this.discount);

  @override
  List<Object?> get props => [discount];
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
  final double subtotal;
  final double discountAmount;
  final double tax;
  final double total;

  CashierLoaded({
    required this.cartItems,
    this.globalDiscount = 0,
    required this.subtotal,
    required this.discountAmount,
    required this.tax,
    required this.total,
  });

  @override
  List<Object?> get props => [
    cartItems,
    globalDiscount,
    subtotal,
    discountAmount,
    tax,
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
    on<ApplyGlobalDiscount>(_onApplyGlobalDiscount);
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

  void _onApplyGlobalDiscount(
    ApplyGlobalDiscount event,
    Emitter<CashierState> emit,
  ) {
    _globalDiscount = event.discount;
    _emitLoadedState(emit);
  }

  void _onClearCart(ClearCart event, Emitter<CashierState> emit) {
    _cartItems.clear();
    _globalDiscount = 0;
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

      // Create sale
      final sale = SaleModel(
        id: const Uuid().v4(),
        invoiceNumber: invoiceNumber,
        transactionDate: DateTime.now(),
        items: List.from(_cartItems),
        subtotal: calculations['subtotal']!,
        discount: calculations['discountAmount']!,
        tax: calculations['tax']!,
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

    for (final item in _cartItems) {
      subtotal += item.subtotal;
      itemDiscountAmount += item.discountAmount;
    }

    // Apply global discount to subtotal after item discounts
    final afterItemDiscount = subtotal - itemDiscountAmount;
    final globalDiscountAmount = afterItemDiscount * (_globalDiscount / 100);
    final totalDiscountAmount = itemDiscountAmount + globalDiscountAmount;

    // Calculate tax (assuming 10% - should be configurable)
    final taxRate = 0.0; // 0% for now, can be configured
    final afterDiscount = subtotal - totalDiscountAmount;
    final tax = afterDiscount * taxRate;

    final total = afterDiscount + tax;

    return {
      'subtotal': subtotal,
      'discountAmount': totalDiscountAmount,
      'tax': tax,
      'total': total,
    };
  }

  void _emitLoadedState(Emitter<CashierState> emit) {
    final calculations = _calculateTotals();
    emit(
      CashierLoaded(
        cartItems: List.from(_cartItems),
        globalDiscount: _globalDiscount,
        subtotal: calculations['subtotal']!,
        discountAmount: calculations['discountAmount']!,
        tax: calculations['tax']!,
        total: calculations['total']!,
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
