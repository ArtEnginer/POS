import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../bloc/user_bloc.dart';
import '../../../branch/presentation/bloc/branch_bloc.dart';
import '../../../branch/domain/entities/branch.dart';

class UserFormPage extends StatefulWidget {
  final User? user;

  const UserFormPage({Key? key, this.user}) : super(key: key);

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String _selectedRole = 'cashier';
  List<int> _selectedBranches = [];
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedRole = widget.user?.role ?? 'cashier';
    _selectedBranches = widget.user?.branchIds?.toList() ?? [];

    // Load branches
    context.read<BranchBloc>().add(LoadBranches());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_validateForm()) return;

    if (widget.user == null) {
      // Create new user
      context.read<UserBloc>().add(
        CreateUserEvent(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          role: _selectedRole,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          branchIds: _selectedBranches.isEmpty ? null : _selectedBranches,
        ),
      );
    } else {
      // Update existing user
      context.read<UserBloc>().add(
        UpdateUserEvent(
          id: widget.user!.id,
          email: _emailController.text,
          fullName: _fullNameController.text,
          role: _selectedRole,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          branchIds: _selectedBranches.isEmpty ? null : _selectedBranches,
        ),
      );
    }
  }

  bool _validateForm() {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username harus diisi')));
      return false;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email harus diisi')));
      return false;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email tidak valid')));
      return false;
    }

    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama lengkap harus diisi')));
      return false;
    }

    if (widget.user == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password harus diisi')));
      return false;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return false;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna',
          ),
        ),
        body: BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserCreated || state is UserUpdated) {
              Navigator.pop(context, true);
            } else if (state is UserError) {
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
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    TextField(
                      controller: _usernameController,
                      enabled: widget.user == null,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Masukkan username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: 'Masukkan nomor telepon',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'super_admin',
                          child: Text('Super Admin'),
                        ),
                        const DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                        const DropdownMenuItem(
                          value: 'manager',
                          child: Text('Manager'),
                        ),
                        const DropdownMenuItem(
                          value: 'cashier',
                          child: Text('Kasir'),
                        ),
                        const DropdownMenuItem(
                          value: 'staff',
                          child: Text('Staff'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value ?? 'cashier');
                      },
                    ),
                    const SizedBox(height: 16),

                    // Branch Selection
                    BlocBuilder<BranchBloc, BranchState>(
                      builder: (context, branchState) {
                        if (branchState is BranchesLoaded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cabang',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      branchState.branches.map((branch) {
                                        final branchId =
                                            int.tryParse(branch.id) ?? 0;
                                        final isSelected = _selectedBranches
                                            .contains(branchId);
                                        return FilterChip(
                                          label: Text(branch.name),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedBranches.add(branchId);
                                              } else {
                                                _selectedBranches.remove(
                                                  branchId,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        } else if (branchState is BranchLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Password (only for create)
                    if (widget.user == null) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          hintText: 'Konfirmasi password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is UserLoading ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              state is UserLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    widget.user == null
                                        ? 'Tambah Pengguna'
                                        : 'Simpan Perubahan',
                                  ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
