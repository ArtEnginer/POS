import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/supplier.dart';
import '../bloc/supplier_bloc.dart';
import '../bloc/supplier_event.dart';
import '../bloc/supplier_state.dart';

class SupplierFormPage extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _currentBalanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _loadSupplierData();
    } else {
      _generateSupplierCode();
    }
  }

  void _loadSupplierData() {
    final supplier = widget.supplier!;
    _codeController.text = supplier.code;
    _nameController.text = supplier.name;
    _phoneController.text = supplier.phone ?? '';
    _emailController.text = supplier.email ?? '';
    _addressController.text = supplier.address ?? '';
    _cityController.text = supplier.city ?? '';
    _taxIdController.text = supplier.taxId ?? '';
    _paymentTermsController.text = supplier.paymentTerms ?? '';
    _creditLimitController.text = supplier.creditLimit.toString();
    _currentBalanceController.text = supplier.currentBalance.toString();
    _notesController.text = supplier.notes ?? '';
  }

  void _generateSupplierCode() {
    // Generate code in format SUPPYYMM0001
    final timestamp = DateTime.now();
    final year = timestamp.year.toString().substring(2); // Last 2 digits
    final month = timestamp.month.toString().padLeft(2, '0');
    final random = timestamp.millisecond.toString().padLeft(4, '0');
    final code = 'SUPP$year$month$random';
    _codeController.text = code;
  }

  void _saveSupplier() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final supplier = Supplier(
        id: widget.supplier?.id ?? const Uuid().v4(),
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text,
        paymentTerms:
            _paymentTermsController.text.isEmpty
                ? null
                : _paymentTermsController.text,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
        currentBalance: double.tryParse(_currentBalanceController.text) ?? 0.0,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isActive: true,
        syncStatus: 'PENDING',
        createdAt: widget.supplier?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.supplier == null) {
        context.read<SupplierBloc>().add(CreateSupplierEvent(supplier));
      } else {
        context.read<SupplierBloc>().add(UpdateSupplierEvent(supplier));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.supplier == null ? 'Tambah Supplier' : 'Edit Supplier',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSupplier,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: BlocListener<SupplierBloc, SupplierState>(
        listener: (context, state) {
          if (state is SupplierOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.pop(context, true);
          } else if (state is SupplierError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Dasar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Supplier *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode supplier tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Supplier *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama supplier tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                Text('Alamat', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Kota',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Informasi Lainnya',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdController,
                  decoration: const InputDecoration(
                    labelText: 'NPWP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentTermsController,
                  decoration: const InputDecoration(
                    labelText: 'Termin Pembayaran (contoh: Net 30)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Limit Kredit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentBalanceController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo Saat Ini',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveSupplier,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Supplier'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxIdController.dispose();
    _paymentTermsController.dispose();
    _creditLimitController.dispose();
    _currentBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
