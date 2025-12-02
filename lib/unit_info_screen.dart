import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class UnitInfoScreen extends StatelessWidget {
  const UnitInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('device_status')
          .stream(primaryKey: ['id'])
          .execute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final units = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: units.length,
          itemBuilder: (context, index) {
            final unit = units[index];
            return _buildUnitCard(context, unit);
          },
        );
      },
    );
  }

  Widget _buildUnitCard(BuildContext context, Map<String, dynamic> unit) {
    final isActive = unit['is_active'] == true;

    final status = (unit['status'] ?? "Unknown").toString();
    final location = (unit['location'] ?? "Unknown Location").toString();

    // Handle heartbeat safely
    final hb = unit['last_heartbeat'];
    final DateTime? lastHeartbeat =
    hb is String ? DateTime.tryParse(hb) :
    hb is DateTime ? hb :
    null;

    // Handle distance safely
    final rawDistance = unit['distance'];
    final String? distanceText = (rawDistance is num)
        ? rawDistance.toDouble().toStringAsFixed(1)
        : rawDistance?.toString();

    final int battery = unit['battery_level'] is num
        ? unit['battery_level']
        : 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                    (unit['id'] ?? "Unknown ID").toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),

                Text(
                  "$battery%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: battery > 20 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(location, style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 10),

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
                  isActive ? "Arduino: Active" : "Arduino: Offline",
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (distanceText != null)
              Text("Distance: $distanceText cm"),

            if (lastHeartbeat != null)
              Text(
                "Last update: ${_timeAgo(lastHeartbeat)}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }


  // Status color logic --------------------------------------------------------
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical Alert':
        return Colors.red;
      case 'Alert':
        return Colors.orange;
      case 'Active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Critical Alert':
        return Icons.error;
      case 'Alert':
        return Icons.warning;
      case 'Active':
        return Icons.check_circle;
      default:
        return Icons.power_off;
    }
  }

  // TimeAgo formatter ---------------------------------------------------------
  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inSeconds;

    if (diff < 60) return "$diff sec ago";
    if (diff < 3600) return "${diff ~/ 60} min ago";
    if (diff < 86400) return "${diff ~/ 3600} hrs ago";
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }
}
