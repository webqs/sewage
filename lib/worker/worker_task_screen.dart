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
  Widget metricChip(IconData icon, String text, Color color) {
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
            text,
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
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Worker Tasks")),
      body: Column(
        children: [

          /// FILTER CHIPS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["All", "Pending", "Resolved"].map((filter) {
                final selected = selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          /// TASK LIST
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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

                /// FILTERING
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

                    return TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.95, end: 1.0),
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
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
                            )
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
                                      const Icon(Icons.assignment_outlined),
                                      const SizedBox(width: 6),

                                      Text(
                                        t['status'] ?? "Task",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
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

                              const SizedBox(height: 12),

                              /// LOCATION
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 18),
                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      t['location'] ?? "Unknown location",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// METRICS
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [

                                  if (t['distance'] != null)
                                    metricChip(
                                      Icons.straighten,
                                      "Distance ${t['distance']} cm",
                                      Colors.blue,
                                    ),

                                  if (t['blockage_percentage'] != null)
                                    metricChip(
                                      Icons.block,
                                      "Blockage ${t['blockage_percentage']}%",
                                      Colors.red,
                                    ),

                                  if (t['level_difference'] != null)
                                    metricChip(
                                      Icons.height,
                                      "ΔLevel ${t['level_difference']} cm",
                                      Colors.deepPurple,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              /// TIME
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 6),
                                  Text(formatTime(t['created_at'])),
                                ],
                              ),

                              const SizedBox(height: 12),

                              /// MAP BUTTON
                              if (t['latitude'] != null &&
                                  t['longitude'] != null)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.map),
                                  label: const Text("Open Location"),
                                  onPressed: () =>
                                      openMap(t['latitude'], t['longitude']),
                                ),

                              /// IMAGE
                              if (t['image_path'] != null &&
                                  t['image_path'].toString().startsWith("http"))
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
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

                              /// RESOLVE BUTTON
                              if (!processed)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label:
                                    const Text("Capture Proof & Resolve"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () =>
                                        resolveTaskWithPhoto(t['id']),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
