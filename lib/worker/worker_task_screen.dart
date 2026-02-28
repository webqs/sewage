import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerTaskScreen extends StatefulWidget {
  const WorkerTaskScreen({super.key});

  @override
  State<WorkerTaskScreen> createState() => _WorkerTaskScreenState();
}

class _WorkerTaskScreenState extends State<WorkerTaskScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  String selectedFilter = "All";

  String formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d • h:mm a").format(dt.toLocal());
  }

  Color statusColor(bool processed) => processed ? Colors.green : Colors.orange;

  Future<void> openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps?q=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<String> uploadProofImage(File file, String taskId) async {
    final fileExt = file.path.split('.').last;
    final fileName =
        "${taskId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt";

    // Upload
    await supabase.storage.from('proof-images').upload(fileName, file);

    // Get PUBLIC URL
    final imageUrl = supabase.storage
        .from('proof-images')
        .getPublicUrl(fileName);

    return imageUrl;
  }

  Future<void> resolveTaskWithPhoto(String taskId) async {
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final file = File(image.path);

    final imageUrl = await uploadProofImage(file, taskId);

    await supabase
        .from('alerts')
        .update({
          'processed': true,
          'image_path': imageUrl, // ✅ store PUBLIC URL
        })
        .eq('id', taskId);
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Worker Tasks")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('alerts')
            .stream(primaryKey: ['id'])
            .eq('assigned_worker_id', user.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var tasks = snapshot.data!;

          if (selectedFilter == "Pending") {
            tasks = tasks.where((t) => t['processed'] != true).toList();
          } else if (selectedFilter == "Resolved") {
            tasks = tasks.where((t) => t['processed'] == true).toList();
          }

          if (tasks.isEmpty) {
            return const Center(child: Text("No tasks found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];
              final processed = t['processed'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t['status'] ?? "Task",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor(processed),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              processed ? "RESOLVED" : "PENDING",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("📍 ${t['location'] ?? 'N/A'}"),
                      Text("📏 Distance: ${t['distance'] ?? 'N/A'}"),
                      Text("🕒 ${formatTime(t['created_at'])}"),

                      const SizedBox(height: 8),

                      // Show Map Button
                      if (t['latitude'] != null && t['longitude'] != null)
                        TextButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text("Open Location"),
                          onPressed: () =>
                              openMap(t['latitude'], t['longitude']),
                        ),

                      // Show Proof Image if exists
                      if (t['image_path'] != null &&
                          t['image_path'].toString().startsWith("http"))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              t['image_path'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      if (!processed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text("Capture & Resolve"),
                            onPressed: () => resolveTaskWithPhoto(t['id']),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
