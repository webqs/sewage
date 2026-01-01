import 'package:flutter/material.dart';
import 'package:sewage/worker/send_report_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Profie.dart';
import 'alerts_screen.dart';
import 'device_map_screen.dart';
import 'history_screen.dart';
import 'performance_review_page.dart';
import 'unit_info_screen.dart';
import 'worker_task_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<WorkerHomeScreen> {
  String? name;
  String? avatarUrl;
  bool loadingProfile = true;

  // 🔹 DASHBOARD DATA (WORKER ONLY)
  int totalAlerts = 0;
  int pendingAlerts = 0;
  int resolvedAlerts = 0;
  double avgRating = 0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadAnalytics(); // worker-specific analytics
  }

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() => loadingProfile = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profile')
          .select('name, avatar_url')
          .eq('auth_id', user.id)
          .maybeSingle();

      setState(() {
        name = response?['name'];
        avatarUrl = response?['avatar_url'];
        loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        name = null;
        avatarUrl = null;
        loadingProfile = false;
      });
    }
  }

  // 🔹 WORKER-SPECIFIC DASHBOARD ANALYTICS
  Future<void> loadAnalytics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 🔹 ONLY alerts assigned to this worker
    final alertsRes = await Supabase.instance.client
        .from('alerts')
        .select()
        .eq('assigned_worker_id', user.id);

    // 🔹 ONLY reviews for this worker
    final reviewsRes = await Supabase.instance.client
        .from('performance_reviews')
        .select()
        .eq('worker_id', user.id);

    final total = alertsRes.length;
    final pending = alertsRes.where((a) => a['processed'] == false).length;
    final resolved = alertsRes.where((a) => a['processed'] == true).length;

    double avg = 0;
    if (reviewsRes.isNotEmpty) {
      avg =
          reviewsRes.map((r) => r['rating'] as int).reduce((a, b) => a + b) /
          reviewsRes.length;
    }

    setState(() {
      totalAlerts = total;
      pendingAlerts = pending;
      resolvedAlerts = resolved;
      avgRating = avg;
    });
  }

  void _navigateToPage(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.blue.shade700,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.blue.shade800,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'User';

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: loadingProfile
            ? const Text('Loading...')
            : Text(
                'Hello, $displayName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: Colors.blue.shade800,
        elevation: 1,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => fetchProfile());
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 WORKER DASHBOARD
              _buildDashboard(),
              const SizedBox(height: 14),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildNavButton(
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerts',
                      onTap: () => _navigateToPage(
                        context,
                        const AlertsScreen(),
                        'Alerts',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.info_outline,
                      label: 'Unit Info',
                      onTap: () => _navigateToPage(
                        context,
                        const UnitInfoScreen(),
                        'Unit Info',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.description,
                      label: 'Send Report',
                      onTap: () => _navigateToPage(
                        context,
                        const SendReportScreen(),
                        'Send Report',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.history,
                      label: 'Action & History',
                      onTap: () => _navigateToPage(
                        context,
                        const HistoryScreen(),
                        'Action & History',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.map,
                      label: 'Map',
                      onTap: () => _navigateToPage(
                        context,
                        const DeviceMapScreen(),
                        'Map',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.task,
                      label: 'Task',
                      onTap: () => _navigateToPage(
                        context,
                        const WorkerTaskScreen(),
                        'Task',
                      ),
                    ),
                    _buildNavButton(
                      icon: Icons.bar_chart,
                      label: 'Performance',
                      onTap: () => _navigateToPage(
                        context,
                        const PerformanceReviewPage(),
                        'Performance',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 DASHBOARD UI (UNCHANGED)
  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat("Total", totalAlerts),
              _stat("Pending", pendingAlerts),
              _stat("Resolved", resolvedAlerts),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text("Avg Rating: ${avgRating.toStringAsFixed(1)} / 5"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue.shade900, size: 34),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
