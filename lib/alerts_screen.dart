import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allAlerts = [];
  List<Map<String, dynamic>> _filteredAlerts = [];

  String _selectedLocation = "All";
  String _severitySearch = "";

  final List<String> _locations = ["All"];

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  // ✅ FETCH ALERTS
  Future<void> fetchAlerts() async {
    final response = await supabase
        .from('alerts')
        .select()
        .order('created_at', ascending: false);

    final data = List<Map<String, dynamic>>.from(response);

    // build unique location list
    _locations
      ..clear()
      ..add("All")
      ..addAll(
        data
            .map((a) => (a['location'] ?? "Unknown").toString())
            .toSet(),
      );

    setState(() {
      _allAlerts = data;
      _applyFilters();
    });
  }

  // ✅ APPLY FILTER + SEARCH
  void _applyFilters() {
    setState(() {
      _filteredAlerts = _allAlerts.where((alert) {
        final matchesLocation = _selectedLocation == "All" ||
            alert['location'] == _selectedLocation;

        final matchesSeverity = alert['severity']
            .toString()
            .toLowerCase()
            .contains(_severitySearch.toLowerCase());

        return matchesLocation && matchesSeverity;
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ SEARCH + FILTER BAR
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Severity Search
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search severity...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _severitySearch = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Location Filter
              DropdownButton<String>(
                value: _selectedLocation,
                borderRadius: BorderRadius.circular(12),
                items: _locations
                    .map(
                      (loc) => DropdownMenuItem(
                    value: loc,
                    child: Text(loc),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ),

        // ✅ ALERT LIST
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _filteredAlerts.isEmpty
                ? const Center(child: Text("No matching alerts"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = _filteredAlerts[index];

                return _buildAlertCard(
                  context,
                  title: alert['status'] ?? "Unknown",
                  severity: alert['severity'] ?? "No severity",
                  location: alert['location'] ?? "Unknown",
                  distance: alert['distance']?.toString() ?? "N/A",
                  timestamp: _formatDate(alert['created_at']),
                  imagePath: alert['image_path'],
                  icon: _selectIcon(alert['severity']),
                  iconColor: _selectColor(alert['severity']),
                  isCritical: alert['severity'] == "high",
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ DATE FORMAT
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "Unknown time";
    final dt = DateTime.parse(dateValue);
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  IconData _selectIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _selectColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'warning':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  // ✅ IMAGE + DETAILS CARD
  Widget _buildAlertCard(
      BuildContext context, {
        required String title,
        required String severity,
        required String location,
        required String distance,
        required String timestamp,
        required IconData icon,
        required Color iconColor,
        required String? imagePath,
        bool isCritical = false,
      }) {
    final imageUrl = imagePath == null
        ? null
        : supabase.storage.from('sewer-images').getPublicUrl(imagePath);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCritical ? Colors.red.shade700 : Colors.grey.shade300,
          width: isCritical ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            leading: Icon(icon, color: iconColor, size: 40),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCritical ? Colors.red.shade900 : Colors.black87,
              ),
            ),
            subtitle: Text(
              "Severity: $severity\n"
                  "Location: $location\n"
                  "Distance: $distance cm\n"
                  "$timestamp",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }
}
