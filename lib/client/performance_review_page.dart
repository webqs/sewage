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
  final Map<String, int> ratings = {};
  final Map<String, TextEditingController> comments = {};

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final userId = supabase.auth.currentUser!.id;

    // 1️⃣ Get all alert IDs already reviewed by this client
    final reviewed = await supabase
        .from('performance_reviews')
        .select('alert_id')
        .eq('reviewed_by', userId);

    final reviewedIds = reviewed.map((e) => e['alert_id'] as String).toList();

    // 2️⃣ Load only completed tasks that are NOT reviewed
    final query = supabase
        .from('alerts')
        .select('*, profile!alerts_assigned_worker_id_fkey(name, auth_id)')
        .eq('processed', true)
        .not('assigned_worker_id', 'is', null);

    final res = reviewedIds.isEmpty
        ? await query.order('created_at', ascending: false)
        : await query
              .not('id', 'in', reviewedIds)
              .order('created_at', ascending: false);

    setState(() => tasks = res);
  }

  String formatTime(String raw) {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  Widget statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        "COMPLETED",
        style: TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Future<void> submitReview(Map task) async {
    final worker = task['profile'];
    final alertId = task['id'];
    final workerId = worker['auth_id'];
    final userId = supabase.auth.currentUser!.id;

    final rating = ratings[alertId] ?? 3;
    final comment = comments[alertId]?.text;

    await supabase.from('performance_reviews').insert({
      'alert_id': alertId,
      'worker_id': workerId,
      'rating': rating,
      'comment': comment,
      'reviewed_by': userId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted successfully")),
    );

    ratings.remove(alertId);
    comments.remove(alertId);
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      body: tasks.isEmpty
          ? const Center(child: Text("No completed tasks available"))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final worker = task['profile'];
                final alertId = task['id'];

                comments.putIfAbsent(alertId, () => TextEditingController());
                final currentRating = ratings[alertId];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            worker['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          statusBadge(),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text("Status: ${task['status']}"),
                      Text("Location: ${task['location'] ?? 'N/A'}"),
                      Text("Completed: ${formatTime(task['created_at'])}"),

                      const SizedBox(height: 14),
                      const Divider(),

                      const Text(
                        "Rate Performance",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: List.generate(5, (i) {
                          final value = i + 1;
                          return IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              Icons.star_rounded,
                              size: 28,
                              color: (currentRating ?? 0) >= value
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                            ),
                            onPressed: () =>
                                setState(() => ratings[alertId] = value),
                          );
                        }),
                      ),

                      const SizedBox(height: 6),

                      TextField(
                        controller: comments[alertId],
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Optional feedback...",
                          filled: true,
                          fillColor: const Color(0xfff1f3f6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Submit Review"),
                          onPressed: currentRating == null
                              ? null
                              : () => submitReview(task),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
