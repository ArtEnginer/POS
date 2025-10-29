import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch.dart';
import '../bloc/branch_bloc.dart';
import '../widgets/branch_list_item.dart';
import '../widgets/branch_search_widget.dart';
import 'branch_form_page.dart';
import 'branch_detail_page.dart';

class BranchListPage extends StatefulWidget {
  const BranchListPage({Key? key}) : super(key: key);

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage> {
  late BranchBloc branchBloc;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    try {
      branchBloc = context.read<BranchBloc>();
      branchBloc.add(LoadBranches());
    } catch (e) {
      print('Error initializing BranchBloc: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Cabang'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Tooltip(
              message: 'Refresh',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  branchBloc.add(LoadBranches());
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Widget
          Padding(
            padding: const EdgeInsets.all(16),
            child: BranchSearchWidget(
              onSearch: (query) {
                setState(() {
                  searchQuery = query;
                });
                if (query.isEmpty) {
                  branchBloc.add(LoadBranches());
                } else {
                  branchBloc.add(SearchBranchesEvent(query));
                }
              },
            ),
          ),
          // List Content
          Expanded(
            child: BlocBuilder<BranchBloc, BranchState>(
              bloc: branchBloc,
              builder: (context, state) {
                if (state is BranchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BranchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Terjadi Kesalahan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            branchBloc.add(LoadBranches());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BranchesLoaded) {
                  if (state.branches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.store_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum Ada Cabang',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan cabang baru untuk memulai',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.branches.length,
                    itemBuilder: (context, index) {
                      final branch = state.branches[index];
                      return BranchListItem(
                        branch: branch,
                        onTap: () {
                          _showBranchDetail(context, branch);
                        },
                        onEdit: () {
                          _navigateToBranchForm(context, branch);
                        },
                        onDelete: () {
                          _showDeleteConfirmation(context, branch.id);
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _navigateToBranchForm(context, null);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Cabang'),
      ),
    );
  }

  void _navigateToBranchForm(BuildContext context, Branch? branch) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BranchFormPage(branch: branch),
          ),
        )
        .then((_) {
          // Refresh list after form closes
          branchBloc.add(LoadBranches());
        });
  }

  void _showBranchDetail(BuildContext context, Branch branch) {
    showDialog(
      context: context,
      builder: (context) => BranchDetailPage(branch: branch),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String branchId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Cabang'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus cabang ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  branchBloc.add(DeleteBranchEvent(branchId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cabang berhasil dihapus')),
                  );
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
