import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final supabase = Supabase.instance.client;

  List alerts = [];
  List workers = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final alertsData = await supabase
        .from('alerts')
        .select()
        .filter('assigned_worker_id','is', null)
        .eq('processed', false);

    final workersData =
    await supabase.from('profile').select().eq('role', 'worker');

    setState(() {
      alerts = alertsData;
      workers = workersData;
    });
  }


  Future<void> assignTask(String alertId, String workerId) async {
    await supabase.from('alerts').update({
      'assigned_worker_id': workerId,
      'assigned_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Alert: ${alert['status']}"),
                  Text("Location: ${alert['location']}"),
                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    hint: const Text("Assign Worker"),
                    items: workers.map<DropdownMenuItem>((w) {
                      return DropdownMenuItem(
                        value: w['auth_id'],
                        child: Text(w['name'] ?? w['email']),
                      );
                    }).toList(),
                    onChanged: (workerId) {
                      assignTask(alert['id'], workerId);
                    },
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
