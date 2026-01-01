import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'alert_detail_screen.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final supabase = Supabase.instance.client;

  List alerts = [];
  List workers = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------- HELPERS ----------------

  Color severityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String formatTime(String? raw) {
    if (raw == null) return "Unknown";

    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;

    final local = dt.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? "PM" : "AM";

    return "${local.day}/${local.month}/${local.year}  "
        "$hour:$minute $period";
  }

  // ---------------- DATA ----------------

  Future<void> loadData() async {
    final alertsData = await supabase
        .from('alerts')
        .select()
        .filter('assigned_worker_id', 'is', null)
        .eq('processed', false)
        .order('created_at', ascending: false);

    final workersData = await supabase
        .from('profile')
        .select()
        .eq('role', 'worker');

    setState(() {
      alerts = alertsData;
      workers = workersData;
    });
  }

  Future<void> assignTask(String alertId, String workerId) async {
    await supabase
        .from('alerts')
        .update({
          'assigned_worker_id': workerId,
          'assigned_at': DateTime.now().toIso8601String(),
        })
        .eq('id', alertId);

    loadData();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];

          final status = alert['status'] ?? "Unknown";
          final severity = alert['severity'] ?? "low";
          final location = alert['location'] ?? "N/A";
          final time = formatTime(alert['created_at']);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlertDetailScreen(alert: alert),
                ),
              );
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor(severity),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text("📍 Location: $location"),
                    Text("🕒 Reported: $time"),

                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: "Assign Worker",
                        border: OutlineInputBorder(),
                      ),
                      items: workers.map<DropdownMenuItem>((w) {
                        return DropdownMenuItem(
                          value: w['auth_id'],
                          child: Text(w['name'] ?? w['email']),
                        );
                      }).toList(),
                      onChanged: (workerId) {
                        assignTask(alert['id'], workerId);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
