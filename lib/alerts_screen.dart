import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A scrollable list is better for showing multiple alerts
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Example of a Critical Alert Card
        _buildAlertCard(
          context,
          title: 'CRITICAL: Major Blockage Detected',
          unitId: 'Unit #102 - North Street',
          timestamp: '2 mins ago',
          icon: Icons.error,
          iconColor: Colors.red.shade700,
          isCritical: true,
        ),
        const SizedBox(height: 12),
        // Example of a Warning Alert Card
        _buildAlertCard(
          context,
          title: 'Warning: High Water Level',
          unitId: 'Unit #105 - Central Park',
          timestamp: '45 mins ago',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        // Example of an Info Alert Card
        _buildAlertCard(
          context,
          title: 'Info: Routine Check Completed',
          unitId: 'Unit #102 - North Street',
          timestamp: '3 hours ago',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green.shade700,
        ),
      ],
    );
  }

  // Helper widget to build a consistent alert card
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
        subtitle: Text('$unitId\n$timestamp'),
        trailing: const Icon(Icons.arrow_forward_ios),
        isThreeLine: true,
        onTap: () {
          // Action to view alert details
        },
      ),
    );
  }
}
