import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceReviewPage extends StatefulWidget {
  const PerformanceReviewPage({super.key});

  @override
  State<PerformanceReviewPage> createState() => _PerformanceReviewPageState();
}

class _PerformanceReviewPageState extends State<PerformanceReviewPage> {
  final supabase = Supabase.instance.client;

  List tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // ---------------- DATA ----------------

  Future<void> loadTasks() async {
    final res = await supabase
        .from('alerts')
        .select('*, profile!alerts_assigned_worker_id_fkey(name, auth_id)')
        .eq('processed', true)
        .not('assigned_worker_id', 'is', null)
        .order('created_at', ascending: false);

    setState(() => tasks = res);
  }

  // ---------------- HELPERS ----------------

  String formatTime(String raw) {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('MMM d, yyyy  •  h:mm a').format(dt);
  }

  Widget statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "COMPLETED",
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: tasks.isEmpty
          ? const Center(child: Text("No completed tasks available"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final worker = task['profile'];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Worker: ${worker['name']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            statusBadge(),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Text("Task Status: ${task['status']}"),
                        Text("Location: ${task['location'] ?? 'N/A'}"),
                        Text("Completed: ${formatTime(task['created_at'])}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
