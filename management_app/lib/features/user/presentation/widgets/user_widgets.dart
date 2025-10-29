import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
    this.onEditTap,
    this.onDeleteTap,
  }) : super(key: key);

  Color _getRoleColor() {
    switch (user.role) {
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

  Color _getStatusColor() {
    switch (user.status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor().withOpacity(0.3),
          child: Icon(_getRoleIcon(), color: _getRoleColor()),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.username} • ${user.email}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(user.roleDisplayName),
                  backgroundColor: _getRoleColor().withOpacity(0.2),
                  labelStyle: TextStyle(color: _getRoleColor()),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(user.statusDisplayName),
                  backgroundColor: _getStatusColor().withOpacity(0.2),
                  labelStyle: TextStyle(color: _getStatusColor()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                if (onEditTap != null)
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                    onTap: onEditTap,
                  ),
                if (onDeleteTap != null)
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                    onTap: onDeleteTap,
                  ),
              ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (user.role) {
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

class UserStatsCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const UserStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserSearchAndFilter extends StatefulWidget {
  final Function(String?) onSearch;
  final Function(String?) onRoleFilter;
  final Function(String?) onStatusFilter;

  const UserSearchAndFilter({
    Key? key,
    required this.onSearch,
    required this.onRoleFilter,
    required this.onStatusFilter,
  }) : super(key: key);

  @override
  State<UserSearchAndFilter> createState() => _UserSearchAndFilterState();
}

class _UserSearchAndFilterState extends State<UserSearchAndFilter> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari pengguna...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearch(null);
                      },
                    )
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() {});
            widget.onSearch(value.isEmpty ? null : value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Role'),
                  ),
                  const DropdownMenuItem(
                    value: 'super_admin',
                    child: Text('Super Admin'),
                  ),
                  const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  const DropdownMenuItem(
                    value: 'manager',
                    child: Text('Manager'),
                  ),
                  const DropdownMenuItem(
                    value: 'cashier',
                    child: Text('Kasir'),
                  ),
                  const DropdownMenuItem(value: 'staff', child: Text('Staff')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                  widget.onRoleFilter(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Status'),
                  ),
                  const DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  const DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Tidak Aktif'),
                  ),
                  const DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Ditangguhkan'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                  widget.onStatusFilter(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
