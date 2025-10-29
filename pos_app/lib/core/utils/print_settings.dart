import 'package:shared_preferences/shared_preferences.dart';

class PrintSettings {
  static const String _autoPrintKey = 'auto_print_receipt';
  static const String _defaultPrinterKey = 'default_printer';
  static const String _printCopiesKey = 'print_copies';

  // Get auto print setting
  static Future<bool> getAutoPrint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPrintKey) ?? false;
  }

  // Set auto print setting
  static Future<void> setAutoPrint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPrintKey, value);
  }

  // Get default printer
  static Future<String?> getDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultPrinterKey);
  }

  // Set default printer
  static Future<void> setDefaultPrinter(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultPrinterKey, printerName);
  }

  // Get print copies
  static Future<int> getPrintCopies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_printCopiesKey) ?? 1;
  }

  // Set print copies
  static Future<void> setPrintCopies(int copies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_printCopiesKey, copies);
  }
}
