import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerReviewScreen extends StatefulWidget {
  const WorkerReviewScreen({super.key});

  @override
  State<WorkerReviewScreen> createState() => _WorkerReviewScreenState();
}

class _WorkerReviewScreenState extends State<WorkerReviewScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('performance_reviews')
        .select()
        .eq('worker_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      reviews = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  String formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, yyyy  •  h:mm a").format(dt.toLocal());
  }

  Color ratingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          "No reviews yet",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final r = reviews[index];
        final rating = r['rating'] ?? 0;
        final comment = r['comment'] ?? "No comment provided";
        final createdAt = formatTime(r['created_at']);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rating: $rating / 5",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ratingColor(rating),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      createdAt,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stars
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // Comment
                Text(
                  comment,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
