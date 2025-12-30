import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceMapScreen extends StatefulWidget {
  const DeviceMapScreen({super.key});

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> devices = [];
  LatLng? mapCenter;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    final response = await supabase.from('device_status').select();

    devices = List<Map<String, dynamic>>.from(response);

    // Set center to first valid device
    for (var device in devices) {
      final lat = double.tryParse(device['latitude'].toString());
      final lon = double.tryParse(device['longitude'].toString());

      if (lat != null && lon != null) {
        mapCenter = LatLng(lat, lon);
        break;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: devices.isEmpty || mapCenter == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: mapCenter!,
          initialZoom: 13,
        ),

        children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.yourapp',
                ),

                // Markers
                MarkerLayer(
                  markers: devices
                      .where((device) {
                        final lat = double.tryParse(
                          device['latitude'].toString(),
                        );
                        final lon = double.tryParse(
                          device['longitude'].toString(),
                        );
                        return lat != null && lon != null;
                      })
                      .map((device) {
                        final lat = double.parse(device['latitude'].toString());
                        final lon = double.parse(
                          device['longitude'].toString(),
                        );

                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: fetchDevices,
      ),
    );
  }
}
