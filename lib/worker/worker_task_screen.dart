import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerTaskScreen extends StatefulWidget {
  const WorkerTaskScreen({super.key});

  @override
  State<WorkerTaskScreen> createState() => _WorkerTaskScreenState();
}

class _WorkerTaskScreenState extends State<WorkerTaskScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('alerts')
        .select()
        .eq('assigned_worker_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      tasks = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  String formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, h:mm a").format(dt.toLocal());
  }

  Color statusColor(bool processed) =>
      processed ? Colors.green : Colors.orange;

  void confirmResolve(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Resolve Task"),
        content: const Text("Mark this task as resolved?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await supabase
                  .from('alerts')
                  .update({'processed': true})
                  .eq('id', id);
              loadTasks();
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          "No assigned tasks",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];
        final processed = t['processed'] == true;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      t['status'] ?? "Task",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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
                        style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text("📍 Location: ${t['location'] ?? 'N/A'}"),
                Text("📏 Distance: ${t['distance'] ?? 'N/A'}"),
                Text("🕒 Reported: ${formatTime(t['created_at'])}"),

                const SizedBox(height: 12),

                if (!processed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Mark as Resolved"),
                      onPressed: () => confirmResolve(t['id']),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
