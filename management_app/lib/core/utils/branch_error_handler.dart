import 'package:flutter/material.dart';

/// Common error handling untuk Branch Feature

class BranchErrorHandler {
  /// Handle error message dan tampilkan ke user
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tutup',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Handle success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle warning message
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle info message
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Parse error message dari exception
  static String parseErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
  }

  /// Check if error is network related
  static bool isNetworkError(String errorMessage) {
    return errorMessage.toLowerCase().contains('network') ||
        errorMessage.toLowerCase().contains('connection') ||
        errorMessage.toLowerCase().contains('socket') ||
        errorMessage.toLowerCase().contains('timeout');
  }

  /// Check if error is server related
  static bool isServerError(String errorMessage) {
    return errorMessage.toLowerCase().contains('500') ||
        errorMessage.toLowerCase().contains('503') ||
        errorMessage.toLowerCase().contains('server error');
  }

  /// Check if error is auth related
  static bool isAuthError(String errorMessage) {
    return errorMessage.toLowerCase().contains('unauthorized') ||
        errorMessage.toLowerCase().contains('forbidden') ||
        errorMessage.toLowerCase().contains('token') ||
        errorMessage.toLowerCase().contains('401') ||
        errorMessage.toLowerCase().contains('403');
  }
}

/// Validation helpers untuk Branch Form
class BranchValidation {
  /// Validasi kode cabang
  static String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode cabang tidak boleh kosong';
    }
    if (value.length < 2) {
      return 'Kode cabang minimal 2 karakter';
    }
    if (value.length > 10) {
      return 'Kode cabang maksimal 10 karakter';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Kode cabang hanya boleh berisi huruf besar dan angka';
    }
    return null;
  }

  /// Validasi nama cabang
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama cabang tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama cabang minimal 3 karakter';
    }
    if (value.length > 100) {
      return 'Nama cabang maksimal 100 karakter';
    }
    return null;
  }

  /// Validasi alamat
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat tidak boleh kosong';
    }
    if (value.length < 10) {
      return 'Alamat minimal 10 karakter';
    }
    if (value.length > 500) {
      return 'Alamat maksimal 500 karakter';
    }
    return null;
  }

  /// Validasi nomor telepon
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9\-\+\s\(\)]{10,15}$').hasMatch(value)) {
      return 'Nomor telepon tidak valid (10-15 digit)';
    }
    return null;
  }

  /// Validasi email (optional)
  static String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(value)) {
        return 'Email tidak valid';
      }
    }
    return null;
  }

  /// Validasi tipe cabang
  static String? validateType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tipe cabang harus dipilih';
    }
    if (value != 'HQ' && value != 'BRANCH') {
      return 'Tipe cabang tidak valid';
    }
    return null;
  }
}

/// Error display widget
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Terjadi Kesalahan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    Key? key,
    required this.message,
    required this.isLoading,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Confirmation dialog
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya',
    this.cancelLabel = 'Batal',
    required this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: isDangerous ? Colors.red : Colors.blue,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
