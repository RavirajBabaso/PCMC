import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';

class NearbyMeScreen extends StatefulWidget {
  const NearbyMeScreen({super.key});

  @override
  State<NearbyMeScreen> createState() => _NearbyMeScreenState();
}

class _NearbyMeScreenState extends State<NearbyMeScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      'label': 'Hospital',
      'key': 'hospital',
      'icon': Icons.local_hospital,
      'color': Colors.red,
    },
    {
      'label': 'School',
      'key': 'school',
      'icon': Icons.school,
      'color': Colors.blue,
    },
    {
      'label': 'Fire Station',
      'key': 'fire station',
      'icon': Icons.fire_truck,
      'color': Colors.orange,
    },
    {
      'label': 'Post Office',
      'key': 'post office',
      'icon': Icons.local_post_office,
      'color': Colors.blueGrey,
    },
    {
      'label': 'Ambulance',
      'key': 'ambulance',
      'icon': Icons.medical_services,
      'color': Colors.redAccent,
    },
    {
      'label': 'Vaccination Center',
      'key': 'vaccination center',
      'icon': Icons.medication,
      'color': Colors.green,
    },
    {
      'label': 'Voting Booth',
      'key': 'voting booth',
      'icon': Icons.how_to_vote,
      'color': Colors.purple,
    },
  ];

  List<dynamic> records = [];
  bool loading = false;
  String? selectedCategory;

  Future<void> fetchData(String category) async {
    setState(() {
      loading = true;
      selectedCategory = category;
    });

    try {
      final response = await ApiService.get('/users/nearby/$category');
      setState(() {
        records = response.data as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (_) {
      setState(() {
        loading = false;
        records = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load $category'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Nearby Me',
      currentRoute: '/citizen/nearby',
      bottomNavCurrentRoute: '/citizen/home',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      child: RefreshIndicator(
        onRefresh: () async {
          if (selectedCategory != null) {
            await fetchData(selectedCategory!);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory == cat['key'];

                  return GestureDetector(
                    onTap: () => fetchData(cat['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 90,
                      padding: const EdgeInsets.all(12),
                      decoration: dsPanelDecoration(
                        color: isSelected ? dsSurfaceAlt : dsSurface,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 32,
                            color: isSelected
                                ? cat['color'] as Color
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? cat['color'] as Color
                                  : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Results',
                    style: dsHeadingStyle(16),
                  ),
                  const Spacer(),
                  if (selectedCategory != null)
                    Text(
                      '${records.length} found',
                      style: dsSubtitleStyle(13),
                    ),
                ],
              ),
            ),
            const Divider(thickness: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: loading
                    ? _buildLoadingState()
                    : records.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text('Finding nearby places...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: dsTextSecondary),
            const SizedBox(height: 16),
            Text(
              selectedCategory == null
                  ? 'Choose a category to search nearby places.'
                  : 'No nearby ${selectedCategory!.replaceAll('_', ' ')} found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: dsTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final item = records[index];
        final category = categories.firstWhere(
          (cat) => cat['key'] == selectedCategory,
          orElse: () => categories[0],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: dsPanelDecoration(color: dsSurface),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor:
                  (category['color'] as Color).withOpacity(0.15),
              child: Icon(
                category['icon'] as IconData,
                color: category['color'] as Color,
                size: 24,
              ),
            ),
            title: Text(
              item['name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['address']?.isNotEmpty ?? false)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: dsTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['address'],
                            style: TextStyle(
                              color: dsTextSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (item['contact_no']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: dsTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['contact_no'],
                            style: TextStyle(
                              color: category['color'] as Color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
      },
    );
  }
}
