import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseResetPage extends StatelessWidget {
  const DatabaseResetPage({Key? key}) : super(key: key);

  Future<void> _resetDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Database?'),
            content: const Text(
              'Ini akan menghapus semua data dan membuat database baru dengan struktur terbaru.\n\n'
              'PERINGATAN: Semua data akan hilang!\n\n'
              'Gunakan hanya untuk development/testing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reset Database'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        // Reset database
        await DatabaseHelper.instance.resetDatabase();

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database berhasil direset!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Reset',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan fitur ini jika:\n'
              '• Ada error "no such table"\n'
              '• Database schema berubah\n'
              '• Perlu clean install untuk testing\n\n'
              'PERINGATAN: Semua data akan hilang!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _resetDatabase(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Database'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Database version: 5'),
                  Text('• Tabel baru: receivings & receiving_items'),
                  Text('• PO dan Receiving sudah terpisah'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
