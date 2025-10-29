import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch.dart';
import '../bloc/branch_bloc.dart';

class BranchFormPage extends StatefulWidget {
  final Branch? branch;

  const BranchFormPage({Key? key, this.branch}) : super(key: key);

  @override
  State<BranchFormPage> createState() => _BranchFormPageState();
}

class _BranchFormPageState extends State<BranchFormPage> {
  late final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String _selectedType = 'BRANCH';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.branch?.code ?? '');
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController = TextEditingController(
      text: widget.branch?.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.branch?.phone ?? '');
    _emailController = TextEditingController(text: widget.branch?.email ?? '');
    _selectedType = widget.branch?.type ?? 'BRANCH';
    _isActive = widget.branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch == null ? 'Tambah Cabang' : 'Edit Cabang'),
      ),
      body: BlocListener<BranchBloc, BranchState>(
        listener: (context, state) {
          if (state is BranchCreated || state is BranchUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.branch == null
                      ? 'Cabang berhasil ditambahkan'
                      : 'Cabang berhasil diperbarui',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is BranchError) {
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
                // Kode Cabang
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Kode Cabang',
                    hintText: 'Contoh: BR001',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.code),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode cabang tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nama Cabang
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Cabang',
                    hintText: 'Contoh: Cabang Jakarta Pusat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.store),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama cabang tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipe Cabang
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipe Cabang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'HQ', child: Text('Kantor Pusat')),
                    DropdownMenuItem(value: 'BRANCH', child: Text('Cabang')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? 'BRANCH';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Alamat
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat',
                    hintText: 'Jalan, No., Kota',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telepon
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    hintText: '0812-3456-7890',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'cabang@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Status Aktif
                CheckboxListTile(
                  title: const Text('Cabang Aktif'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<BranchBloc, BranchState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed:
                                state is BranchLoading
                                    ? null
                                    : () => _submitForm(context),
                            child:
                                state is BranchLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      widget.branch == null
                                          ? 'Tambah'
                                          : 'Perbarui',
                                    ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final branch = Branch(
        id: widget.branch?.id ?? '',
        code: _codeController.text,
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        type: _selectedType,
        isActive: _isActive,
        createdAt: widget.branch?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.branch == null) {
        context.read<BranchBloc>().add(CreateBranchEvent(branch));
      } else {
        context.read<BranchBloc>().add(UpdateBranchEvent(branch));
      }
    }
  }
}
