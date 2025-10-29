import 'package:flutter/material.dart';
import '../../domain/entities/branch.dart';

class BranchDetailPage extends StatelessWidget {
  final Branch branch;

  const BranchDetailPage({Key? key, required this.branch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: branch.isHQ ? Colors.blue : Colors.grey.shade300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        branch.isHQ ? Icons.corporate_fare : Icons.store,
                        color:
                            branch.isHQ ? Colors.white : Colors.grey.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    branch.isHQ
                                        ? Colors.white
                                        : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode: ${branch.code}',
                              style: TextStyle(
                                color:
                                    branch.isHQ
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
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
                      Chip(
                        label: Text(
                          branch.isActive ? 'AKTIF' : 'TIDAK AKTIF',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor:
                            branch.isActive ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Detail Items
                  _DetailItem(
                    icon: Icons.location_on,
                    label: 'Alamat',
                    value: branch.address,
                  ),
                  const SizedBox(height: 12),
                  _DetailItem(
                    icon: Icons.phone,
                    label: 'Telepon',
                    value: branch.phone,
                  ),
                  if (branch.email != null && branch.email!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: branch.email!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailItem(
                    icon: Icons.calendar_today,
                    label: 'Dibuat',
                    value:
                        '${branch.createdAt.day}/${branch.createdAt.month}/${branch.createdAt.year}',
                  ),
                  const SizedBox(height: 12),
                  _DetailItem(
                    icon: Icons.update,
                    label: 'Diperbarui',
                    value:
                        '${branch.updatedAt.day}/${branch.updatedAt.month}/${branch.updatedAt.year}',
                  ),
                  if (branch.apiKey != null) ...[
                    const SizedBox(height: 12),
                    _DetailItem(
                      icon: Icons.vpn_key,
                      label: 'API Key',
                      value: '${branch.apiKey!.substring(0, 10)}...',
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Close Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
