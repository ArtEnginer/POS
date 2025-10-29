import 'package:flutter/material.dart';
import '../../domain/entities/branch.dart';

class BranchListItem extends StatelessWidget {
  final Branch branch;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BranchListItem({
    Key? key,
    required this.branch,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: branch.isHQ ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            branch.isHQ ? Icons.corporate_fare : Icons.store,
            color: branch.isHQ ? Colors.white : Colors.grey.shade600,
          ),
        ),
        title: Text(
          branch.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Kode: ${branch.code}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              branch.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    branch.isHQ ? 'KANTOR PUSAT' : 'CABANG',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      branch.isHQ
                          ? Colors.blue.shade100
                          : Colors.amber.shade100,
                ),
                const SizedBox(width: 8),
                if (branch.isActive)
                  Chip(
                    label: const Text(
                      'AKTIF',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  )
                else
                  Chip(
                    label: const Text(
                      'TIDAK AKTIF',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: onEdit,
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: onDelete,
                ),
              ],
        ),
      ),
    );
  }
}
