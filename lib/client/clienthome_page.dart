import 'package:flutter/material.dart';
import 'package:sewage/client/addaccount.dart';
import 'package:sewage/client/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Profie.dart';
import 'alerts_screen.dart';
import 'device_map_screen.dart';
import 'history_screen.dart';
import 'unit_info_screen.dart';
import 'assign_task_screen.dart';
import 'performance_review_page.dart';
import 'view_reports_page.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ClientHomeScreen> {
  String? name;
  String? avatarUrl;
  bool loadingProfile = true;

  int totalAlerts = 0;
  int pendingAlerts = 0;
  int resolvedAlerts = 0;
  int totalWorkers = 0;
  double avgRating = 0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadAnalytics();
  }

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

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
  }

  Future<void> loadAnalytics() async {
    final alertsRes = await Supabase.instance.client.from('alerts').select();
    final workersRes = await Supabase.instance.client
        .from('profile')
        .select()
        .eq('role', 'worker');
    final reviewsRes =
    await Supabase.instance.client.from('performance_reviews').select();

    final total = alertsRes.length;
    final pending = alertsRes.where((a) => a['processed'] == false).length;
    final resolved = alertsRes.where((a) => a['processed'] == true).length;

    double avg = 0;
    if (reviewsRes.isNotEmpty) {
      avg = reviewsRes
          .map((r) => r['rating'] as int)
          .reduce((a, b) => a + b) /
          reviewsRes.length;
    }

    setState(() {
      totalAlerts = total;
      pendingAlerts = pending;
      resolvedAlerts = resolved;
      totalWorkers = workersRes.length;
      avgRating = avg;
    });
  }

  void _navigateToPage(BuildContext context, Widget page, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
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
        backgroundColor: Colors.blue.shade800,
        elevation: 1,
        foregroundColor: Colors.white,
        title: loadingProfile
            ? const Text("Loading...")
            : Text(
          "Hello, $displayName",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDashboard(),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildNavButton(Icons.warning, "Alerts",
                          () => _navigateToPage(context, const AlertsScreen(), "Alerts")),
                  _buildNavButton(Icons.info, "Unit Info",
                          () => _navigateToPage(context, const UnitInfoScreen(), "Unit Info")),
                  _buildNavButton(Icons.history, "History",
                          () => _navigateToPage(context, const HistoryScreen(), "History")),
                  _buildNavButton(Icons.person_add, "Add Account",
                          () => _navigateToPage(context, const AddAccount(), "Add Account")),
                  _buildNavButton(Icons.assignment, "Assign Task",
                          () => _navigateToPage(context, const AssignTaskScreen(), "Assign Task")),
                  _buildNavButton(Icons.bar_chart, "Worker Performance",
                          () => _navigateToPage(context, const PerformanceReviewPage(), "Performance")),
                  _buildNavButton(Icons.description, "Reports",
                          () => _navigateToPage(context, const ViewReportsPage(), "Reports")),
                  _buildNavButton(Icons.people, "Users",
                          () => _navigateToPage(context, const ProfilePage(), "Users")),
                  _buildNavButton(Icons.map, "Map",
                          () => _navigateToPage(context, const DeviceMapScreen(), "Map")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat("Total", totalAlerts),
              _stat("Pending", pendingAlerts),
              _stat("Resolved", resolvedAlerts),
              _stat("Workers", totalWorkers),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text("Avg Rating: ${avgRating.toStringAsFixed(1)} / 5"),
            ],
          )
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: Colors.blue.shade900),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
