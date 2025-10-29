import 'package:flutter/material.dart';

class BranchSearchWidget extends StatefulWidget {
  final Function(String) onSearch;

  const BranchSearchWidget({Key? key, required this.onSearch})
    : super(key: key);

  @override
  State<BranchSearchWidget> createState() => _BranchSearchWidgetState();
}

class _BranchSearchWidgetState extends State<BranchSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari cabang...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearch('');
                    setState(() {});
                  },
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        widget.onSearch(value);
      },
    );
  }
}
