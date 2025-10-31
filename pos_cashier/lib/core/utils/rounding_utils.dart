/// Utility untuk pembulatan harga di Indonesia
class RoundingUtils {
  /// Bulatkan ke Rp 100 terdekat
  /// Contoh:
  /// - 15.250 -> 15.300 (pembulatan +50)
  /// - 15.240 -> 15.200 (pembulatan -40)
  /// - 15.000 -> 15.000 (tidak ada pembulatan)
  static double roundTo100(double amount) {
    final rounded = (amount / 100).round() * 100;
    return rounded.toDouble();
  }

  /// Bulatkan ke Rp 50 terdekat
  /// Contoh:
  /// - 15.230 -> 15.250 (pembulatan +20)
  /// - 15.220 -> 15.200 (pembulatan -20)
  static double roundTo50(double amount) {
    final rounded = (amount / 50).round() * 50;
    return rounded.toDouble();
  }

  /// Hitung nilai pembulatan (difference)
  /// Return positif jika naik, negatif jika turun
  static double calculateRounding(double originalAmount, double roundedAmount) {
    return roundedAmount - originalAmount;
  }

  /// Check apakah perlu pembulatan (ada desimal yang tidak habis dibagi 100)
  static bool needsRounding(double amount) {
    return amount % 100 != 0;
  }

  /// Format pembulatan untuk tampilan
  /// Contoh: +50, -40, 0
  static String formatRounding(double rounding) {
    if (rounding == 0) return '0';
    if (rounding > 0) return '+${rounding.toStringAsFixed(0)}';
    return rounding.toStringAsFixed(0);
  }
}
