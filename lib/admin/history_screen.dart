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
        .select('*, profile!alerts_assigned_worker_id_fkey(name, email)')
        .order("created_at", ascending: false);

    setState(() {
      _alerts = List<Map<String, dynamic>>.from(response);
    });
  }

  // ================= HELPERS =================

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

  Widget statusBadge(bool processed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: processed ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        processed ? "RESOLVED" : "PENDING",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
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

  // ================= UI =================

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
          final processed = alert["processed"] == true;

          final worker = alert['profile'];
          final workerName =
              worker?['name'] ?? worker?['email'] ?? "Unassigned";

          final meta = alert["metadata"];
          String blockageRatio = "N/A";
          if (meta is Map && meta["blockage_ratio"] is num) {
            blockageRatio =
                (meta["blockage_ratio"] as num).toStringAsFixed(1);
          }

          final lat = alert["latitude"];
          final lon = alert["longitude"];

          final imageUrl = imagePath != null
              ? supabase.storage
              .from('sewer-images')
              .getPublicUrl(imagePath)
              : null;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$status (${severity.toUpperCase()})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: severityColor(severity),
                        ),
                      ),
                      statusBadge(processed),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text("👷 Worker: $workerName"),
                  Text("🧱 Blockage: $blockageRatio%"),
                  Text("📏 Distance: $distance cm"),
                  Text("📍 Location: $location"),

                  if (lat != null && lon != null)
                    InkWell(
                      onTap: () => openInMaps(lat, lon),
                      child: Text(
                        "🧭 Coordinates: $lat, $lon",
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                  Text("🕒 Time: $createdAt"),

                  const SizedBox(height: 10),

                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl, height: 140, fit: BoxFit.cover),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
