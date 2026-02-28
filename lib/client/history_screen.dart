import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
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
  Map<String, int> dailyFrequency = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlerts();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchAlerts(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ================= FETCH ALERTS =================

  Future<void> fetchAlerts() async {
    final response = await supabase
        .from("alerts")
        .select('*, profile!alerts_assigned_worker_id_fkey(name, email)')
        .order("created_at", ascending: false);

    if (!mounted) return;

    final alertsList = List<Map<String, dynamic>>.from(response);

    // 🔥 Last 7 Days Frequency Map
    Map<String, int> freq = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formatted = DateFormat("MMM d").format(date);
      freq[formatted] = 0;
    }

    for (var alert in alertsList) {
      final created = alert["created_at"];
      if (created != null) {
        final date = DateTime.parse(created).toLocal();
        final formatted = DateFormat("MMM d").format(date);

        if (freq.containsKey(formatted)) {
          freq[formatted] = freq[formatted]! + 1;
        }
      }
    }

    setState(() {
      _alerts = alertsList;
      dailyFrequency = freq;
      _loading = false;
    });
  }

  // ================= BAR CHART =================

  Widget _buildBarChart() {
    if (dailyFrequency.isEmpty) return const SizedBox();

    final keys = dailyFrequency.keys.toList();
    final values = dailyFrequency.values.toList();

    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Alerts - Last 7 Days",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < keys.length) {
                          return Text(
                            keys[index],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: List.generate(keys.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index].toDouble(),
                        color: Colors.blue,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
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
    final Uri googleMapsApp = Uri.parse("geo:$lat,$lon?q=$lat,$lon");
    final Uri browserUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lon",
    );

    if (await canLaunchUrl(googleMapsApp)) {
      await launchUrl(googleMapsApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget dataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text("$label: ${value ?? 'N/A'}"),
    );
  }

  String combinedDistance(Map<String, dynamic> alert) {
    final d1 = alert["distance"];
    final d2 = alert["distance_2"];

    if (d1 != null && d2 != null) {
      return "$d1 cm / $d2 cm";
    } else if (d1 != null) {
      return "$d1 cm";
    } else if (d2 != null) {
      return "$d2 cm";
    } else {
      return "N/A";
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Alert History"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
          ? const Center(child: Text("No alerts available"))
          : Column(
              children: [
                _buildBarChart(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];

                      final status = alert["status"] ?? "Unknown";
                      final severity = alert["severity"] ?? "low";
                      final processed = alert["processed"] == true;

                      final worker = alert['profile'];
                      final workerName =
                          worker?['name'] ?? worker?['email'] ?? "Unassigned";

                      final lat = alert["latitude"]?.toDouble();
                      final lon = alert["longitude"]?.toDouble();

                      final imagePath = alert["image_path"];
                      final imageUrl = imagePath != null
                          ? supabase.storage
                                .from('sewer-images')
                                .getPublicUrl(imagePath)
                          : null;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "$status (${severity.toUpperCase()})",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: severityColor(severity),
                                      ),
                                    ),
                                  ),
                                  statusBadge(processed),
                                ],
                              ),
                              const SizedBox(height: 10),
                              dataRow("👷 Worker", workerName),
                              dataRow("📏 Distance", combinedDistance(alert)),
                              dataRow("📍 Location", alert["location"]),
                              dataRow(
                                "🕒 Created",
                                formatTime(alert["created_at"]),
                              ),
                              const SizedBox(height: 10),
                              if (lat != null && lon != null)
                                InkWell(
                                  onTap: () => openInMaps(lat, lon),
                                  child: const Text(
                                    "🧭 View on Map",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
