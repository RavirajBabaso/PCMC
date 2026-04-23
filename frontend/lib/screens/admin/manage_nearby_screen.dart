import 'package:flutter/material.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';

class ManageNearbyScreen extends StatefulWidget {
  const ManageNearbyScreen({super.key});

  @override
  State<ManageNearbyScreen> createState() => _ManageNearbyScreenState();
}

class _ManageNearbyScreenState extends State<ManageNearbyScreen> {
  List<dynamic> nearbyList = [];
  bool loading = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();
  String selectedCategory = "Hospital";

  final List<Map<String, dynamic>> categories = [
    {"label": "Hospital", "icon": Icons.local_hospital, "color": const Color(0xFFEF4444)},
    {"label": "School", "icon": Icons.school, "color": const Color(0xFF3B82F6)},
    {"label": "Fire Station", "icon": Icons.fire_truck, "color": const Color(0xFFF59E0B)},
    {"label": "Post Office", "icon": Icons.local_post_office, "color": const Color(0xFF6B7280)},
    {"label": "Ambulance", "icon": Icons.medical_services, "color": const Color(0xFFDC2626)},
    {"label": "Vaccination Center", "icon": Icons.medication, "color": const Color(0xFF10B981)},
    {"label": "Voting Booth", "icon": Icons.how_to_vote, "color": const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    fetchNearbyPlaces();
  }

  Future<void> fetchNearbyPlaces() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.get('/admins/nearby');
      setState(() {
        nearbyList = response.data as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (error) {
      setState(() => loading = false);
      _showSnackBar('Failed to load nearby places');
    }
  }

  Future<void> addOrUpdateNearby({int? id}) async {
    if (!_validateForm()) return;

    final payload = {
      "category": selectedCategory.toLowerCase(),
      "name": nameCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "description": descriptionCtrl.text.trim(),
      "contact_no": contactCtrl.text.trim(),
    };

    try {
      if (id == null) {
        await ApiService.post('/admins/nearby', payload);
        _showSnackBar('Place added successfully');
      } else {
        await ApiService.put('/admins/nearby/$id', payload);
        _showSnackBar('Place updated successfully');
      }
      Navigator.pop(context);
      await fetchNearbyPlaces();
    } catch (error) {
      _showSnackBar('Failed to save place');
    }
  }

  bool _validateForm() {
    if (nameCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter a name');
      return false;
    }
    if (addressCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter an address');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: dsSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> deleteNearby(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dsSurface,
        title: const Text('Delete Place', style: TextStyle(color: dsTextPrimary)),
        content: const Text(
          'Are you sure you want to delete this place? This action cannot be undone.',
          style: TextStyle(color: dsTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: dsTextSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/admins/nearby/$id');
        _showSnackBar('Place deleted successfully');
        await fetchNearbyPlaces();
      } catch (error) {
        _showSnackBar('Failed to delete place');
      }
    }
  }

  void showNearbyDialog({Map<String, dynamic>? data}) {
    if (data != null) {
      String categoryFromApi = data['category'].toString();
      selectedCategory = categories.firstWhere(
        (c) => c["label"].toString().toLowerCase() == categoryFromApi.toLowerCase(),
        orElse: () => categories.first,
      )["label"] as String;
      nameCtrl.text = data['name'] ?? '';
      addressCtrl.text = data['address'] ?? '';
      descriptionCtrl.text = data['description'] ?? '';
      contactCtrl.text = data['contact_no'] ?? '';
    } else {
      selectedCategory = "Hospital";
      nameCtrl.clear();
      addressCtrl.clear();
      descriptionCtrl.clear();
      contactCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: dsSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: dsBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      data == null ? Icons.add_location : Icons.edit_location,
                      color: dsAccent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data == null ? 'Add Nearby Place' : 'Edit Nearby Place',
                      style: const TextStyle(
                        color: dsTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: dsTextSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Category Dropdown
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      // Name Field
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: dsTextPrimary),
                        decoration: _buildInputDecoration(
                          labelText: 'Name *',
                          prefixIcon: Icons.place,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      TextField(
                        controller: addressCtrl,
                        style: const TextStyle(color: dsTextPrimary),
                        decoration: _buildInputDecoration(
                          labelText: 'Address *',
                          prefixIcon: Icons.location_on,
                        ),
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Contact Field
                      TextField(
                        controller: contactCtrl,
                        style: const TextStyle(color: dsTextPrimary),
                        decoration: _buildInputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextField(
                        controller: descriptionCtrl,
                        style: const TextStyle(color: dsTextPrimary),
                        decoration: _buildInputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icons.description,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: dsBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dsTextSecondary,
                          side: BorderSide(color: dsBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => addOrUpdateNearby(id: data?['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dsAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(data == null ? 'Add Place' : 'Update Place'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: dsTextSecondary),
      prefixIcon: Icon(prefixIcon, color: dsAccent),
      filled: true,
      fillColor: dsSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dsBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dsAccent, width: 2),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final selectedCategoryData = categories.firstWhere(
      (c) => c["label"] == selectedCategory,
      orElse: () => categories.first,
    );

    return DropdownButtonFormField<String>(
      value: selectedCategory,
      dropdownColor: dsSurface,
      style: const TextStyle(color: dsTextPrimary),
      decoration: _buildInputDecoration(
        labelText: 'Category',
        prefixIcon: Icons.category,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category["label"] as String,
          child: Row(
            children: [
              Icon(
                category["icon"] as IconData,
                color: category["color"] as Color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                category["label"] as String,
                style: const TextStyle(color: dsTextPrimary),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedCategory = value!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dsBackground,
      appBar: AppBar(
        title: const Text('Manage Nearby Places', style: TextStyle(color: dsTextPrimary)),
        backgroundColor: dsSurface,
        foregroundColor: dsAccent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dsBorder),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNearbyDialog(),
        backgroundColor: dsAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_location_alt),
      ),
      body: loading
          ? _buildLoadingState()
          : nearbyList.isEmpty
              ? _buildEmptyState()
              : _buildNearbyList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: dsAccent),
          SizedBox(height: 16),
          Text('Loading nearby places...', style: TextStyle(color: dsTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: dsTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Nearby Places',
            style: const TextStyle(
              color: dsTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first nearby place by tapping the + button',
            style: TextStyle(
              color: dsTextSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Nearby Places (${nearbyList.length})',
                style: const TextStyle(
                  color: dsTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.swap_vert,
                color: dsTextSecondary,
                size: 20,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearbyList.length,
            itemBuilder: (context, index) {
              final place = nearbyList[index];
              final category = categories.firstWhere(
                (c) => c["label"].toString().toLowerCase() == place['category'].toString().toLowerCase(),
                orElse: () => categories.first,
              );
              final categoryColor = category["color"] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: dsSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dsBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          category["icon"],
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: dsTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place['category']?.toString().toUpperCase() ?? '',
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (place['address'] != null && place['address'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                place['address'],
                                style: const TextStyle(
                                  color: dsTextSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: dsAccent),
                            onPressed: () => showNearbyDialog(data: place),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: _danger),
                            onPressed: () => deleteNearby(place['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Status colors matching theme
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);