import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/user.dart';
import '../bloc/user_bloc.dart';
import 'user_form_page.dart';

class UserDetailPage extends StatefulWidget {
  final int userId;

  const UserDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    context.read<UserBloc>().add(LoadUserByIdEvent(widget.userId));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ubah Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password Saat Ini',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  if (_newPasswordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password tidak cocok')),
                    );
                    return;
                  }

                  context.read<UserBloc>().add(
                    ChangePasswordEvent(
                      id: widget.userId,
                      currentPassword: _currentPasswordController.text,
                      newPassword: _newPasswordController.text,
                    ),
                  );

                  Navigator.pop(context);
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                },
                child: const Text('Ubah'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengguna'), elevation: 0),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserLoaded) {
            return _buildDetailContent(state.user);
          } else if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UserBloc>().add(
                        LoadUserByIdEvent(widget.userId),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDetailContent(User user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.3),
                  child: Icon(
                    _getRoleIcon(user.role),
                    size: 40,
                    color: _getRoleColor(user.role),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '@${user.username}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', user.email),
                const SizedBox(height: 12),
                _buildInfoRow('Nomor Telepon', user.phone ?? '-'),
                const SizedBox(height: 12),
                _buildInfoRow('Role', user.roleDisplayName),
                const SizedBox(height: 12),
                _buildInfoRow('Status', user.statusDisplayName),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Terakhir Login',
                  user.lastLoginAt != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLoginAt!)
                      : 'Belum pernah',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Bergabung',
                  DateFormat('dd/MM/yyyy').format(user.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => UserFormPage(user: user)),
            );
            if (result == true && mounted) {
              context.read<UserBloc>().add(LoadUserByIdEvent(widget.userId));
            }
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _showChangePasswordDialog,
          icon: const Icon(Icons.lock),
          label: const Text('Ubah Password'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'manager':
        return Colors.blue;
      case 'cashier':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.person;
      case 'cashier':
        return Icons.point_of_sale;
      case 'staff':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }
}
