import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart'; // notifications

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

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    fetchAlerts();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchAlerts(),
    );

    supabase
        .channel('public:alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            final alert = payload.newRecord;
            if (alert == null) return;

            _showAlertNotification(
              alert['status'] ?? 'Alert',
              alert['severity'] ?? 'unknown',
              alert['location'] ?? 'unknown',
            );

            fetchAlerts();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _showAlertNotification(String status, String severity, String location) {
    final androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "🚨 $severity Alert",
      "$status detected at $location",
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> fetchAlerts() async {
    final response = await supabase
        .from('alerts')
        .select()
        .eq('processed', false)
        .order('created_at', ascending: false);

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    final recentAlerts = List<Map<String, dynamic>>.from(response).where((a) {
      if (a['created_at'] == null) return false;
      return DateTime.parse(a['created_at']).isAfter(cutoff);
    }).toList();

    _locations
      ..clear()
      ..add("All")
      ..addAll(
        recentAlerts
            .map((a) => (a['location'] ?? "Unknown").toString())
            .toSet(),
      );

    setState(() {
      _allAlerts = recentAlerts;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredAlerts = _allAlerts.where((alert) {
      final matchesLocation =
          _selectedLocation == "All" || alert['location'] == _selectedLocation;

      final matchesSeverity = alert['severity']
          .toString()
          .toLowerCase()
          .contains(_severitySearch.toLowerCase());

      return matchesLocation && matchesSeverity;
    }).toList();
  }

  Future<void> _refresh() async => fetchAlerts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🔥 FORCED WHITE
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH + FILTER BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search severity...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) {
                        _severitySearch = v;
                        _applyFilters();
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedLocation,
                    items: _locations
                        .map(
                          (loc) =>
                              DropdownMenuItem(value: loc, child: Text(loc)),
                        )
                        .toList(),
                    onChanged: (v) {
                      _selectedLocation = v!;
                      _applyFilters();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // ALERT LIST
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.white,
                onRefresh: _refresh,
                child: _filteredAlerts.isEmpty
                    ? const Center(child: Text("No alerts in last 24 hours"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAlerts.length,
                        itemBuilder: (_, i) {
                          final alert = _filteredAlerts[i];
                          return _buildAlertCard(
                            context,
                            title: alert['status'] ?? "Unknown",
                            severity: alert['severity'] ?? "N/A",
                            location: alert['location'] ?? "Unknown",
                            distance: alert['distance']?.toString() ?? "N/A",
                            timestamp: _formatDate(alert['created_at']),
                            imagePath: alert['image_path'],
                            latitude: alert['latitude'],
                            longitude: alert['longitude'],
                            icon: _selectIcon(alert['severity']),
                            iconColor: _colorFromSeverity(alert['severity']),
                            isCritical:
                                alert['severity']?.toLowerCase() == "high",
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "Unknown time";
    return DateFormat(
      'MMM d, h:mm a',
    ).format(DateTime.parse(dateValue).toLocal());
  }

  IconData _selectIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _colorFromSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

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
    required double? latitude,
    required double? longitude,
    bool isCritical = false,
  }) {
    final imageUrl = imagePath == null
        ? null
        : supabase.storage.from('sewer-images').getPublicUrl(imagePath);

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? Colors.red : Colors.grey.shade300,
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
                color: isCritical ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            subtitle: Text(
              "Severity: $severity\n"
              "Location: $location\n"
              "Distance: $distance cm\n"
              "Lat: ${latitude?.toStringAsFixed(5) ?? 'N/A'}\n"
              "Lon: ${longitude?.toStringAsFixed(5) ?? 'N/A'}\n"
              "$timestamp",
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
