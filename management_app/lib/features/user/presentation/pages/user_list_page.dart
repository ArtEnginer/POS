import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../bloc/user_bloc.dart';
import '../widgets/user_widgets.dart';
import 'user_form_page.dart';
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  int _currentPage = 0;
  int _pageSize = 10;
  String? _selectedRole;
  String? _selectedStatus;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    context.read<UserBloc>().add(
      LoadAllUsersEvent(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        role: _selectedRole,
        status: _selectedStatus,
        search: _searchQuery,
      ),
    );
  }

  void _onSearchChanged(String? value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0;
    });
    _loadUsers();
  }

  void _onRoleFilterChanged(String? value) {
    setState(() {
      _selectedRole = value;
      _currentPage = 0;
    });
    _loadUsers();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatus = value;
      _currentPage = 0;
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const UserFormPage()));
          if (result == true) {
            _loadUsers();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengguna'),
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengguna berhasil ditambahkan')),
            );
            _loadUsers();
          } else if (state is UserUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengguna berhasil diperbarui')),
            );
            _loadUsers();
          } else if (state is UserDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengguna berhasil dihapus')),
            );
            _loadUsers();
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            UserSearchAndFilter(
              onSearch: _onSearchChanged,
              onRoleFilter: _onRoleFilterChanged,
              onStatusFilter: _onStatusFilterChanged,
            ),
            const SizedBox(height: 16),
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is UsersLoaded) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pengguna',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...state.users.map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UserCard(
                            user: user,
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          UserDetailPage(userId: user.id),
                                ),
                              );
                              if (result == true) {
                                _loadUsers();
                              }
                            },
                            onEditTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserFormPage(user: user),
                                ),
                              );
                              if (result == true) {
                                _loadUsers();
                              }
                            },
                            onDeleteTap: () {
                              _showDeleteDialog(user);
                            },
                          ),
                        );
                      }).toList(),
                      if ((state.total ?? 0) > state.users.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    _currentPage > 0
                                        ? () {
                                          setState(() => _currentPage--);
                                          _loadUsers();
                                        }
                                        : null,
                                child: const Text('Sebelumnya'),
                              ),
                              const SizedBox(width: 16),
                              Text('Halaman ${_currentPage + 1}'),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed:
                                    (_currentPage + 1) * _pageSize <
                                            (state.total ?? 0)
                                        ? () {
                                          setState(() => _currentPage++);
                                          _loadUsers();
                                        }
                                        : null,
                                child: const Text('Berikutnya'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                } else if (state is UserError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Pengguna?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus pengguna ${user.fullName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<UserBloc>().add(DeleteUserEvent(user.id));
                },
                child: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}
