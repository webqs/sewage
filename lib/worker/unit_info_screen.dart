import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitInfoScreen extends StatefulWidget {
  const UnitInfoScreen({super.key});

  @override
  State<UnitInfoScreen> createState() => _UnitInfoScreenState();
}

class _UnitInfoScreenState extends State<UnitInfoScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _units = [];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    fetchDeviceStatus();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchDeviceStatus(),
    );

    supabase
        .channel('public:device_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'device_status',
          callback: (_) => fetchDeviceStatus(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDeviceStatus() async {
    final response = await supabase
        .from('device_status')
        .select()
        .order('id', ascending: true);

    setState(() {
      _units = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // 🔥 FORCE WHITE BACKGROUND
      child: _units.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _units.length,
              itemBuilder: (context, index) {
                return _buildUnitCard(_units[index]);
              },
            ),
    );
  }

  // ============================
  // UNIT CARD UI
  // ============================
  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final bool isActive = unit['is_active'] == true;

    final String status = (unit['status'] ?? "Unknown").toString();
    final String location = (unit['location'] ?? "Unknown").toString();
    final String deviceName = (unit['device_name'] ?? "Unknown Device")
        .toString();
    final String deviceId = (unit['device_id'] ?? "Unknown ID").toString();
    final String installDate = (unit['installation_date'] ?? "-").toString();

    final double? latitude = unit['latitude'] is num
        ? unit['latitude'].toDouble()
        : null;
    final double? longitude = unit['longitude'] is num
        ? unit['longitude'].toDouble()
        : null;

    final DateTime? lastSeen = unit['last_seen'] is String
        ? DateTime.tryParse(unit['last_seen'])?.toLocal()
        : null;

    final String? distanceText = unit['current_distance'] is num
        ? "${unit['current_distance'].toStringAsFixed(1)} cm"
        : null;

    final int battery = unit['battery_level'] is num
        ? unit['battery_level']
        : 0;

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  battery == 0 ? "--" : "$battery%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: battery > 20 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text("Device ID: $deviceId"),
            Text("Location: $location"),
            Text("Installed on: $installDate"),

            if (latitude != null && longitude != null)
              Text(
                "Lat: ${latitude.toStringAsFixed(5)}, "
                "Lon: ${longitude.toStringAsFixed(5)}",
              ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
                Text(
                  isActive ? "Device: Active" : "Device: Offline",
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (distanceText != null) Text("Distance: $distanceText"),

            if (lastSeen != null)
              Text(
                "Last seen: ${_timeAgo(lastSeen)}",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
          ],
        ),
      ),
    );
  }

  // ============================
  // HELPERS
  // ============================
  Color _getStatusColor(String status) {
    if (status == "online") return Colors.green;
    if (status == "offline") return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (status == "online") return Icons.wifi;
    if (status == "offline") return Icons.wifi_off;
    return Icons.help_outline;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 5) return "Just now";
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";

    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
