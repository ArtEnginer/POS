import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;

  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCustomerType = 'regular';
  bool _isActive = true;
  bool _isLoading = false;

  final List<Map<String, String>> _customerTypes = [
    {'value': 'regular', 'label': 'Regular'},
    {'value': 'vip', 'label': 'VIP'},
    {'value': 'wholesale', 'label': 'Grosir'},
    {'value': 'retail', 'label': 'Retail'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _codeController.text = widget.customer!.code ?? '';
      _phoneController.text = widget.customer!.phone ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _cityController.text = widget.customer!.city ?? '';
      _taxIdController.text = widget.customer!.taxId ?? '';
      _creditLimitController.text = widget.customer!.creditLimit.toString();
      _notesController.text = widget.customer!.notes ?? '';
      _selectedCustomerType = widget.customer!.customerType;
      _isActive = widget.customer!.isActive;
    } else {
      // Generate code after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCode();
      });
    }
  }

  void _generateCode() {
    context.read<CustomerBloc>().add(GenerateCustomerCodeEvent());
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = Customer(
      id: widget.customer?.id ?? const Uuid().v4(),
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      phone:
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
      email:
          _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
      address:
          _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
      city:
          _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
      customerType: _selectedCustomerType,
      taxId:
          _taxIdController.text.trim().isEmpty
              ? null
              : _taxIdController.text.trim(),
      creditLimit:
          _creditLimitController.text.isEmpty
              ? 0
              : double.parse(_creditLimitController.text),
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
      totalPoints: widget.customer?.totalPoints ?? 0,
      currentBalance: widget.customer?.currentBalance ?? 0,
      totalPurchases: widget.customer?.totalPurchases ?? 0,
      isActive: _isActive,
      syncStatus: 'PENDING',
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.customer != null) {
      context.read<CustomerBloc>().add(UpdateCustomerEvent(customer));
    } else {
      context.read<CustomerBloc>().add(CreateCustomerEvent(customer));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer != null ? 'Edit Customer' : 'Tambah Customer',
        ),
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerCodeGenerated) {
            _codeController.text = state.code;
          } else if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is CustomerError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Kode Customer
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Kode Customer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon:
                      widget.customer == null
                          ? IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _generateCode,
                            tooltip: 'Generate Kode',
                          )
                          : null,
                ),
                readOnly: widget.customer != null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nama Customer
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Customer *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // No. Telepon
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'No. Telepon',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alamat
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.home),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Kota
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Kota',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),

              // Tipe Customer
              DropdownButtonFormField<String>(
                value: _selectedCustomerType,
                decoration: InputDecoration(
                  labelText: 'Tipe Customer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items:
                    _customerTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCustomerType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Tax ID / NPWP
              TextFormField(
                controller: _taxIdController,
                decoration: InputDecoration(
                  labelText: 'NPWP / Tax ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),

              // Credit Limit
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: 'Limit Kredit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Status Aktif
              SwitchListTile(
                title: const Text('Status Aktif'),
                subtitle: Text(_isActive ? 'Aktif' : 'Nonaktif'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          widget.customer != null ? 'Update' : 'Simpan',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxIdController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
