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
  String generateAlertSentence(Map<String, dynamic> alert) {
    final levelDiff = alert["level_difference"];
    final blockage = alert["blockage_percentage"];
    final flow = alert["flow_rate"];
    final location = alert["location"] ?? "this location";

    if (blockage != null) {
      final b = double.tryParse(blockage.toString()) ?? 0;

      if (b > 70) {
        return "🚨 Severe blockage detected in the sewer near $location. Immediate maintenance recommended.";
      }

      if (b > 40) {
        return "⚠️ Significant obstruction likely forming near $location.";
      }

      if (b > 15) {
        return "ℹ️ Early blockage signs detected near $location.";
      }
    }

    if (levelDiff != null) {
      final diff = double.tryParse(levelDiff.toString()) ?? 0;

      if (diff > 2) {
        return "⚠️ Water level imbalance detected near $location, indicating possible blockage.";
      }
    }

    if (flow != null) {
      final f = double.tryParse(flow.toString()) ?? 0;

      if (f < 0.2) {
        return "⚠️ Very low sewer flow detected near $location.";
      }
    }

    return "Sewer flow irregularity detected near $location.";
  }

  String formatNum(dynamic value, {String unit = ""}) {
    if (value == null) return "N/A";

    final v = double.tryParse(value.toString());
    if (v == null) return "N/A";

    return "${v.toStringAsFixed(2)} $unit";
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

                return TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.95, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.blue.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: severityColor(severity),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    severity.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: severityColor(severity),
                                    ),
                                  ),
                                ],
                              ),
                              statusBadge(processed),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// ALERT MESSAGE
                          Text(
                            generateAlertSentence(alert),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// METRICS
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [

                              metricChip(
                                Icons.straighten,
                                "Dist:",
                                "${formatNum(alert["distance"], unit: "cm")} / ${formatNum(alert["distance_2"], unit: "cm")}",
                                Colors.blue,
                              ),

                              metricChip(
                                Icons.height,
                                "ΔLevel:",
                                formatNum(alert["level_difference"], unit: "cm"),
                                Colors.deepPurple,
                              ),

                              metricChip(
                                Icons.water_drop,
                                "Flow:",
                                formatNum(alert["flow_rate"], unit: "L/s"),
                                Colors.teal,
                              ),

                              metricChip(
                                Icons.block,
                                "Block:",
                                formatNum(alert["blockage_percentage"], unit: "%"),
                                Colors.red,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          /// BLOCKAGE BAR
                          if (alert["blockage_percentage"] != null)
                            blockageBar(
                              double.tryParse(
                                alert["blockage_percentage"].toString(),
                              ) ??
                                  0,
                            ),

                          const SizedBox(height: 14),

                          /// INFO
                          Text("📍 ${alert["location"] ?? "Unknown"}"),
                          Text("🕒 ${formatTime(alert["created_at"])}"),
                          Text("👷 Worker: $workerName"),

                          const SizedBox(height: 10),

                          /// MAP BUTTON
                          if (lat != null && lon != null)
                            ElevatedButton.icon(
                              onPressed: () => openInMaps(lat, lon),
                              icon: const Icon(Icons.map),
                              label: const Text("View on Map"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          /// IMAGE
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // ================= UI WIDGETS =================

  Widget metricChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            "$label $value",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget blockageBar(double percent) {
    Color color;

    if (percent > 70) {
      color = Colors.red;
    } else if (percent > 40) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Blockage Level (${percent.toStringAsFixed(1)}%)",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            color: color,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
