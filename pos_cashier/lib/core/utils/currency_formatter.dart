import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: AppConstants.currency,
    decimalDigits: 0,
  );

  /// Format number to currency string
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format number to currency string without symbol
  static String formatWithoutSymbol(num amount) {
    return NumberFormat.decimalPattern('id_ID').format(amount);
  }

  /// Parse currency string to number
  static double parse(String amountString) {
    final cleaned = amountString.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
