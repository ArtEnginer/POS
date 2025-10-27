import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../injection_container.dart' as di;
import '../../branch/domain/entities/branch.dart';
import '../../branch/presentation/bloc/branch_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BranchSwitcherWidget extends StatefulWidget {
  final Function(Branch)? onBranchChanged;

  const BranchSwitcherWidget({super.key, this.onBranchChanged});

  @override
  State<BranchSwitcherWidget> createState() => _BranchSwitcherWidgetState();
}

class _BranchSwitcherWidgetState extends State<BranchSwitcherWidget> {
  Branch? _currentBranch;
  List<Branch> _availableBranches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBranch();
    _loadAvailableBranches();
  }

  Future<void> _loadCurrentBranch() async {
    try {
      final authService = di.sl<AuthService>();
      final branchData = await authService.getBranchData();

      if (branchData != null && mounted) {
        setState(() {
          _currentBranch = Branch.fromJson(branchData);
        });
      }
    } catch (e) {
      debugPrint('Error loading current branch: $e');
    }
  }

  Future<void> _loadAvailableBranches() async {
    context.read<BranchBloc>().add(LoadBranches());
  }

  Future<void> _switchBranch(Branch branch) async {
    if (_currentBranch?.id == branch.id) return;

    setState(() => _isLoading = true);

    try {
      final authService = di.sl<AuthService>();
      final socketService = di.sl<SocketService>();

      // Switch branch via API
      await authService.switchBranch(branch.id);

      // Update socket connection to new branch room
      await socketService.switchBranch(branch.id);

      setState(() {
        _currentBranch = branch;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${branch.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Callback
        widget.onBranchChanged?.call(branch);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch branch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BranchBloc, BranchState>(
      listener: (context, state) {
        if (state is BranchesLoaded) {
          setState(() {
            _availableBranches =
                state.branches.where((b) => b.isActive).toList();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentBranch?.isHQ == true ? Icons.business : Icons.store,
              color: const Color(0xFF1E88E5),
              size: 20,
            ),
            const SizedBox(width: 8),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_currentBranch != null)
              PopupMenuButton<Branch>(
                initialValue: _currentBranch,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentBranch!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _currentBranch!.code,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
                itemBuilder: (context) {
                  return _availableBranches.map((branch) {
                    final isSelected = branch.id == _currentBranch?.id;
                    return PopupMenuItem<Branch>(
                      value: branch,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          branch.isHQ ? Icons.business : Icons.store,
                          color: isSelected ? const Color(0xFF1E88E5) : null,
                        ),
                        title: Text(
                          branch.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected ? const Color(0xFF1E88E5) : null,
                          ),
                        ),
                        subtitle: Text(branch.code),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF1E88E5),
                                )
                                : null,
                      ),
                    );
                  }).toList();
                },
                onSelected: _switchBranch,
              )
            else
              const Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
