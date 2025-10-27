import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedParentId;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Get root categories (categories without parent)
  List<Map<String, dynamic>> get _rootCategories {
    return _categories.where((cat) => cat['parentId'] == null).toList();
  }

  // Get child categories for a parent
  List<Map<String, dynamic>> _getChildren(String parentId) {
    return _categories
        .where((cat) => cat['parentId']?.toString() == parentId)
        .toList();
  }

  // Toggle expand/collapse
  void _toggleExpand(String categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? response.data as List;
        _categories = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCategory() async {
    if (_nameController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final payload = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'parent_id': _selectedParentId,
        'is_active': true,
      };
      await apiClient.post(ApiConstants.categoriesCreate, data: payload);
      _nameController.clear();
      _descController.clear();
      _selectedParentId = null;
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = sl<ApiClient>();
      final endpoint = ApiConstants.categoriesDelete.replaceAll(':id', id);
      await apiClient.delete(endpoint);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori Produk'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Column(
        children: [
          // Form tambah kategori
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Kategori Baru',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Dropdown parent category
                DropdownButtonFormField<String?>(
                  value: _selectedParentId,
                  decoration: InputDecoration(
                    labelText: 'Kategori Induk (opsional)',
                    prefixIcon: const Icon(Icons.account_tree),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Kosongkan jika kategori utama',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('-- Kategori Utama --'),
                    ),
                    ..._categories.map((cat) {
                      final id = cat['id']?.toString() ?? '';
                      final name = cat['name']?.toString() ?? '-';
                      final parentId = cat['parentId'];

                      // Tampilkan indentasi untuk sub-kategori
                      String displayName = name;
                      if (parentId != null) {
                        displayName = '   ↳ $name';
                      }

                      return DropdownMenuItem(
                        value: id,
                        child: Text(displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedParentId = value);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kategori'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Header list
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Daftar Kategori',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_categories.length} kategori',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // List kategori
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                    ? const Center(child: Text('Belum ada kategori'))
                    : ListView(children: _buildCategoryTree()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, true),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.check, color: AppColors.textWhite),
      ),
    );
  }

  // Build category tree structure
  List<Widget> _buildCategoryTree() {
    final widgets = <Widget>[];

    for (final rootCat in _rootCategories) {
      widgets.add(_buildCategoryItem(rootCat, 0));

      // Add children if expanded
      final rootId = rootCat['id']?.toString() ?? '';
      if (_expandedCategories.contains(rootId)) {
        final children = _getChildren(rootId);
        for (final childCat in children) {
          widgets.add(_buildCategoryItem(childCat, 1));
        }
      }
    }

    return widgets;
  }

  // Build single category item
  Widget _buildCategoryItem(Map<String, dynamic> cat, int level) {
    final id = cat['id']?.toString() ?? '';
    final name = cat['name']?.toString() ?? '-';
    final desc = cat['description']?.toString() ?? '';
    final hasChildren = _getChildren(id).isNotEmpty;
    final isExpanded = _expandedCategories.contains(id);

    return Container(
      margin: EdgeInsets.only(left: level * 24.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListTile(
        dense: level > 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasChildren)
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
                onPressed: () => _toggleExpand(id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else if (level > 0)
              const SizedBox(width: 36),
            Icon(
              level > 0 ? Icons.subdirectory_arrow_right : Icons.folder,
              color: level > 0 ? AppColors.textSecondary : AppColors.primary,
              size: level > 0 ? 20 : 24,
            ),
          ],
        ),
        title: Text(
          name,
          style:
              level > 0
                  ? AppTextStyles.bodyMedium
                  : AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
        ),
        subtitle: desc.isNotEmpty ? Text(desc) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasChildren)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_getChildren(id).length} sub',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () async {
                // Check if has children
                if (hasChildren) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak dapat menghapus kategori yang memiliki sub-kategori',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Hapus Kategori'),
                        content: Text('Yakin ingin menghapus "$name"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await _deleteCategory(id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
