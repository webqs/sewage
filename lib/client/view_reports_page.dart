import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewReportsPage extends StatefulWidget {
  const ViewReportsPage({super.key});

  @override
  State<ViewReportsPage> createState() => _ViewReportsPageState();
}

class _ViewReportsPageState extends State<ViewReportsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    final response = await supabase
        .from('report')
        .select()
        .order('id', ascending: false);

    setState(() {
      reports = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  String formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat("MMM d, h:mm a").format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return const Center(
        child: Text(
          "No reports submitted yet",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final r = reports[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
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
                      const Text(
                        "Worker Report",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (r['created_at'] != null)
                        Text(
                          formatTime(r['created_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    r['reports'] ?? "No content",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
