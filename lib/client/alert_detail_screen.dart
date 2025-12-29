import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertDetailScreen extends StatelessWidget {
  final Map alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final imagePath = alert['image_path'];

    return Scaffold(
      appBar: AppBar(title: const Text("Alert Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row("Status", alert['status']),
            _row("Severity", alert['severity']),
            _row("Location", alert['location']),
            _row("Distance", "${alert['distance']}"),
            _row("Device Name", alert['device_name']),
            _row("Device ID", alert['device_id']),
            _row("Installation Date", alert['installation_date']),
            _row("Latitude", "${alert['latitude']}"),
            _row("Longitude", "${alert['longitude']}"),
            _row("Reported At", alert['created_at']),
            const SizedBox(height: 16),

            if (imagePath != null) ...[
              const Text(
                "Captured Image",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  supabase.storage
                      .from('sewer-images')
                      .getPublicUrl(imagePath),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) =>
                  const Text("⚠️ Unable to load image"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? "—")),
        ],
      ),
    );
  }
}
