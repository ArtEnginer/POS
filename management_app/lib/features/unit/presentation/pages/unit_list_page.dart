import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/unit_remote_data_source.dart';
import '../../data/models/unit_model.dart';

class UnitListPage extends StatefulWidget {
  const UnitListPage({Key? key}) : super(key: key);

  @override
  State<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends State<UnitListPage> {
  late final UnitRemoteDataSource _dataSource;
  List<UnitModel> _units = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataSource = UnitRemoteDataSourceImpl(apiClient: sl<ApiClient>());
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final units = await _dataSource.getAllUnits();
      setState(() => _units = units);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Satuan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUnitDialog(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _units.length,
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  return ListTile(
                    title: Text(unit.name),
                    subtitle:
                        unit.description != null
                            ? Text(unit.description!)
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUnitDialog(unit: unit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUnit(unit),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _showUnitDialog({UnitModel? unit}) async {
    final nameController = TextEditingController(text: unit?.name ?? '');
    final descController = TextEditingController(text: unit?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(unit == null ? 'Tambah Satuan' : 'Edit Satuan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Satuan *'),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama satuan harus diisi')),
                    );
                    return;
                  }

                  try {
                    final model = UnitModel(
                      id: unit?.id ?? '',
                      name: nameController.text.trim(),
                      description:
                          descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                      isActive: true,
                      createdAt: unit?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (unit == null) {
                      await _dataSource.createUnit(model);
                    } else {
                      await _dataSource.updateUnit(unit.id, model);
                    }

                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _loadUnits();
      // Notify parent that data has changed
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text('Hapus satuan "${unit.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _dataSource.deleteUnit(unit.id);
        await _loadUnits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satuan berhasil dihapus')),
          );
          // Notify parent that data has changed
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
