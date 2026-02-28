import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceMapScreen extends StatefulWidget {
  const DeviceMapScreen({super.key});

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> devices = [];
  StreamSubscription? _deviceStream;

  @override
  void initState() {
    super.initState();
    _listenToDevices();
  }

  @override
  void dispose() {
    _deviceStream?.cancel();
    super.dispose();
  }

  // ✅ LISTEN FROM CORRECT TABLE
  void _listenToDevices() {
    _deviceStream = supabase
        .from('alerts') // ✅ FIXED TABLE NAME
        .stream(primaryKey: ['id'])
        .listen((data) {
          setState(() {
            devices = List<Map<String, dynamic>>.from(data);
          });

          _fitMapToDevices();
        });
  }

  void _fitMapToDevices() {
    final points = devices
        .where((d) => d['latitude'] != null && d['longitude'] != null)
        .map((d) => LatLng(d['latitude'] as double, d['longitude'] as double))
        .toList();

    if (points.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  // ✅ SEVERITY COLOR
  Color _getSeverityColor(String? severity) {
    final sev = severity?.toLowerCase();

    switch (sev) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // ✅ COUNTS FROM SEVERITY
  int get highCount => devices.where((d) => d['severity'] == 'high').length;

  int get mediumCount => devices.where((d) => d['severity'] == 'medium').length;

  int get lowCount => devices.where((d) => d['severity'] == 'low').length;

  Future<void> _openNavigation(double lat, double lon) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showDeviceDetails(Map<String, dynamic> device) {
    final lat = device['latitude'];
    final lon = device['longitude'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device['device_name'] ?? "Unknown Device",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text("📍 Location: ${device['location']}"),
              Text("🚦 Status: ${device['status']}"),
              Text("⚠ Severity: ${device['severity']}"),
              const SizedBox(height: 15),
              if (lat != null && lon != null)
                ElevatedButton.icon(
                  onPressed: () => _openNavigation(lat, lon),
                  icon: const Icon(Icons.navigation),
                  label: const Text("Navigate"),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Monitoring Map"),
        backgroundColor: Colors.blue,
      ),
      body: devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(9.71472, 76.68694),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.sewage',
                    ),
                    MarkerLayer(
                      markers: devices
                          .where(
                            (d) =>
                                d['latitude'] != null && d['longitude'] != null,
                          )
                          .map((device) {
                            return Marker(
                              point: LatLng(
                                device['latitude'],
                                device['longitude'],
                              ),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () => _showDeviceDetails(device),
                                child: Icon(
                                  Icons.location_on,
                                  size: 40,
                                  color: _getSeverityColor(device['severity']),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),

                // ✅ TOP SUMMARY
                Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatusItem("High", highCount, Colors.red),
                          _buildStatusItem(
                            "Medium",
                            mediumCount,
                            Colors.orange,
                          ),
                          _buildStatusItem("Low", lowCount, Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title),
      ],
    );
  }
}
