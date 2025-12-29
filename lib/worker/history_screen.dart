import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  Timer? _autoRefreshTimer;

  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    fetchAlerts();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => fetchAlerts(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAlerts() async {
    final response = await supabase
        .from("alerts")
        .select()
        .order("created_at", ascending: false);

    setState(() {
      _alerts = List<Map<String, dynamic>>.from(response);
    });
  }

  Color severityColor(String severity) {
    switch (severity) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String formatTime(String? raw) {
    if (raw == null) return "Unknown";
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, h:mm a").format(dt.toLocal());
  }

  Future<void> openInMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps?q=$lat,$lon");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: _alerts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];

                final status = alert["status"] ?? "Unknown";
                final severity = alert["severity"] ?? "low";
                final distance = alert["distance"]?.toString() ?? "N/A";
                final location = alert["location"] ?? "N/A";
                final createdAt = formatTime(alert["created_at"]);
                final imagePath = alert["image_path"];

                final meta = alert["metadata"];
                String blockageRatio = "N/A";
                if (meta is Map && meta["blockage_ratio"] is num) {
                  blockageRatio = (meta["blockage_ratio"] as num)
                      .toStringAsFixed(1);
                }

                // NEW: Coordinates
                final lat = alert["latitude"];
                final lon = alert["longitude"];

                final imageUrl = supabase.storage
                    .from('sewer-images')
                    .getPublicUrl(imagePath);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: imagePath != null
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imagePath == null
                          ? const Icon(Icons.image_not_supported)
                          : null,
                    ),

                    title: Text(
                      "$status (${severity.toUpperCase()})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor(severity),
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Blockage: $blockageRatio%"),
                        Text("Distance: $distance cm"),
                        Text("Location: $location"),
                        if (lat != null && lon != null)
                          InkWell(
                            onTap: () => openInMaps(lat, lon),
                            child: Text(
                              "Coordinates: $lat, $lon",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        Text("Time: $createdAt"),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullImageView(imageUrl: imageUrl),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ==============================
// FULL IMAGE VIEW SCREEN
// ==============================
class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Alert Image"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(child: Image.network(imageUrl)),
    );
  }
}
