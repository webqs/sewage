import 'package:flutter/material.dart';

// A simple data class to represent a sewer monitoring unit.
class SewerUnit {
  final String id;
  final String location;
  final String status;
  final int batteryLevel;

  const SewerUnit({
    required this.id,
    required this.location,
    required this.status,
    required this.batteryLevel,
  });
}

class UnitInfoScreen extends StatelessWidget {
  const UnitInfoScreen({super.key});

  // --- MOCK DATA: In a real app, this would come from a database or API ---
  final List<SewerUnit> sewerUnits = const [
    SewerUnit(
      id: 'SM-102',
      location: 'North Street & 5th Ave',
      status: 'Critical Alert',
      batteryLevel: 87,
    ),
    SewerUnit(
      id: 'SM-105',
      location: 'Central Park, Sector 3',
      status: 'Active',
      batteryLevel: 95,
    ),
    SewerUnit(
      id: 'SM-108',
      location: 'South Bridge Crossing',
      status: 'Maintenance Required',
      batteryLevel: 45,
    ),
    SewerUnit(
      id: 'SM-112',
      location: 'Industrial Area, Phase 2',
      status: 'Offline',
      batteryLevel: 0,
    ),
    SewerUnit(
      id: 'SM-115',
      location: 'Market Square',
      status: 'Active',
      batteryLevel: 78,
    ),
  ];
  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ListView.builder is the best way to create a list from data.
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sewerUnits.length,
      itemBuilder: (context, index) {
        final unit = sewerUnits[index];
        return _buildUnitCard(context, unit);
      },
    );
  }

  // A helper widget to create a consistent card for each unit.
  Widget _buildUnitCard(BuildContext context, SewerUnit unit) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _getStatusIcon(unit.status),
          color: _getStatusColor(unit.status),
          size: 40,
        ),
        title: Text(
          unit.id,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${unit.location}\nStatus: ${unit.status}'),
        trailing: Text(
          '${unit.batteryLevel}%',
          style: TextStyle(
            color: unit.batteryLevel > 20 ? Colors.green.shade800 : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        isThreeLine: true,
        onTap: () {
          // You can add navigation here to a detailed page for this unit.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tapped on unit ${unit.id}')));
        },
      ),
    );
  }

  // Helper functions to get color and icon based on unit status.
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical Alert':
        return Colors.red.shade700;
      case 'Maintenance Required':
        return Colors.orange.shade700;
      case 'Active':
        return Colors.green.shade700;
      default: // Offline
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Critical Alert':
        return Icons.error;
      case 'Maintenance Required':
        return Icons.build;
      case 'Active':
        return Icons.check_circle;
      default: // Offline
        return Icons.power_off;
    }
  }
}
