import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/diagnostic_centre_model.dart';

class DiagnosticCentreDetailScreen extends StatefulWidget {
  final DiagnosticCentreModel centre;

  const DiagnosticCentreDetailScreen({super.key, required this.centre});

  @override
  State<DiagnosticCentreDetailScreen> createState() =>
      _DiagnosticCentreDetailScreenState();
}

class _DiagnosticCentreDetailScreenState
    extends State<DiagnosticCentreDetailScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  List<DiagnosticTest> _filteredTests = [];

  @override
  void initState() {
    super.initState();
    _filteredTests = widget.centre.tests;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTests(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredTests = widget.centre.tests;
      } else {
        _filteredTests = widget.centre.tests.where((test) {
          final matchesQuery = query.isEmpty ||
              test.testName.toLowerCase().contains(query.toLowerCase());
          final matchesCategory =
              _selectedCategory == 'All' || test.category == _selectedCategory;
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _filterTests(_searchController.text);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> get _categories {
    final cats = widget.centre.tests.map((t) => t.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.centre.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Centre Info Header
          _buildCentreInfoHeader(),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTests,
              decoration: InputDecoration(
                hintText: 'Search tests...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tests List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Available Tests & Prices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_filteredTests.length} tests',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Tests List
          Expanded(
            child: _filteredTests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTests.length,
                    itemBuilder: (context, index) {
                      final test = _filteredTests[index];
                      return _buildTestCard(test);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentreInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.centre.address}, ${widget.centre.city}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                onPressed: () => _copyToClipboard(
                  '${widget.centre.address}, ${widget.centre.city}',
                  'Address copied!',
                ),
                tooltip: 'Copy address',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Contact
          Row(
            children: [
              Icon(Icons.phone, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                widget.centre.contactNumber,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                onPressed: () => _copyToClipboard(
                  widget.centre.contactNumber.replaceAll(' ', '').replaceAll('-', ''),
                  'Phone number copied!',
                ),
                tooltip: 'Copy phone number',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  '${widget.centre.tests.length} Tests Available',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(DiagnosticTest test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Test Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getCategoryColor(test.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(test.category),
                color: _getCategoryColor(test.category),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Test Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.testName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      test.category,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '৳${test.price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tests found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'blood test':
        return Colors.red;
      case 'radiology':
        return Colors.blue;
      case 'ultrasound':
        return Colors.purple;
      case 'cardiology':
        return Colors.pink;
      case 'pathology':
        return Colors.orange;
      case 'gastroenterology':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'blood test':
        return Icons.bloodtype;
      case 'radiology':
        return Icons.camera_alt;
      case 'ultrasound':
        return Icons.waves;
      case 'cardiology':
        return Icons.favorite;
      case 'pathology':
        return Icons.science;
      case 'gastroenterology':
        return Icons.medical_services;
      default:
        return Icons.biotech;
    }
  }
}
