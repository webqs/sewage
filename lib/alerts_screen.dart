import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final response = await supabase
        .from('alerts')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAlerts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading alerts\n${snapshot.error}",
              textAlign: TextAlign.center,
            ),
          );
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return const Center(
            child: Text("No alerts found"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];

            return _buildAlertCard(
              context,
              title: alert['status'] ?? "Unknown",
              unitId: alert['severity'] ?? "No severity",
              timestamp: alert['created_at']?.toString() ?? "",
              icon: _selectIcon(alert['severity']),
              iconColor: _selectColor(alert['severity']),
              isCritical: alert['severity'] == "critical",
            );
          },
        );
      },
    );
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

  Widget _buildAlertCard(
      BuildContext context, {
        required String title,
        required String unitId,
        required String timestamp,
        required IconData icon,
        required Color iconColor,
        bool isCritical = false,
      }) {
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
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 40),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.red.shade900 : Colors.black87,
          ),
        ),
        subtitle: Text("$unitId\n$timestamp"),
        trailing: const Icon(Icons.arrow_forward_ios),
        isThreeLine: true,
        onTap: () {},
      ),
    );
  }
}
