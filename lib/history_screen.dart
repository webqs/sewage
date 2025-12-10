import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final response = await supabase
        .from("alerts")
        .select()
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(response);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Action & History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAlerts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final alerts = snapshot.data!;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No history found",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              final status = alert["status"] ?? "Unknown";
              final severity = alert["severity"] ?? "low";
              final distance = alert["distance"]?.toString() ?? "N/A";
              final location = alert["location"] ?? "N/A";
              final createdAt = alert["created_at"];
              final imagePath = alert["image_path"];
              final blockageRatio =
                  alert["metadata"]?["blockage_ratio"]?.toStringAsFixed(1) ??
                      "N/A";

              final imageUrl =
                  "${supabase.storage.from('sewer-images').getPublicUrl(imagePath)}";

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
                    "$status  (${severity.toUpperCase()})",
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
          );
        },
      ),
    );
  }
}

// ==============================
// FULL IMAGE VIEW PAGE
// ==============================
class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alert Image"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
