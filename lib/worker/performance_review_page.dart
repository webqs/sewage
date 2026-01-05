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

  List<Map<String, dynamic>> reviews = [];

  double avgRating = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  Future<void> loadReviews() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1. Fetch reviews for this worker
    final res = await supabase
        .from('performance_reviews')
        .select()
        .eq('worker_id', user.id)
        .order('created_at', ascending: false);

    if (res.isEmpty) {
      setState(() {
        reviews = [];
        avgRating = 0;
        totalReviews = 0;
      });
      return;
    }

    // 2. Collect reviewer ids
    final reviewerIds =
    res.map((r) => r['reviewed_by'] as String).toSet().toList();

    // 3. Fetch reviewer names
    final reviewerProfiles = await supabase
        .from('profile')
        .select('auth_id, name')
        .inFilter('auth_id', reviewerIds);

    final reviewerMap = {
      for (var p in reviewerProfiles) p['auth_id']: p['name']
    };

    // 4. Attach names & calculate stats
    double sum = 0;
    for (var r in res) {
      sum += (r['rating'] as int);
      r['reviewer_name'] = reviewerMap[r['reviewed_by']] ?? "Client";
    }

    setState(() {
      reviews = List<Map<String, dynamic>>.from(res);
      totalReviews = res.length;
      avgRating = sum / res.length;
    });
  }

  String formatDate(String raw) {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  Widget buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          Icons.star_rounded,
          size: 20,
          color: i < rating.round() ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      appBar: AppBar(title: const Text("My Performance")),
      body: reviews.isEmpty
          ? const Center(child: Text("No reviews yet"))
          : Column(
        children: [
          // Summary
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Overall Rating",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    buildStars(avgRating),
                  ],
                ),
                Column(
                  children: [
                    const Text("Total Reviews",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(totalReviews.toString(),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),

          // Reviews
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final r = reviews[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Text(r['rating'].toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Text("Rating: ${r['rating']} / 5",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (r['comment'] != null &&
                          r['comment'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 6),
                          child: Text(r['comment']),
                        ),
                      Text("Reviewed by ${r['reviewer_name']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      Text("Reviewed on ${formatDate(r['created_at'])}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
